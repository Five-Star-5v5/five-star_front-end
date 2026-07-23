import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/teams_service.dart';

/// État du provider
enum TeamsLoadingState { idle, loading, loaded, error }

/// Provider pour gérer l'état des équipes
class TeamsProvider with ChangeNotifier {
  final TeamsService _teamsService = TeamsService.instance;

  // État
  TeamsLoadingState _state = TeamsLoadingState.idle;
  String? _errorMessage;
  bool _isLoadingInitial = true; // Chargement initial des équipes

  // Données
  List<TeamPreview> _teams = [];
  TeamDetail? _myTeam;
  TeamDetail? _selectedTeam;

  // Équipes où je suis membre (mais pas propriétaire)
  List<TeamDetail> _teamsMemberOf = [];

  // Index du terrain actuellement affiché (0 = mon équipe, 1+ = équipes où je suis membre)
  int _currentTeamIndex = 0;

  // Postes ouverts de mon équipe (en mode recherche)
  List<OpenSlot> _myOpenSlots = [];

  // Candidatures reçues pour mon équipe
  List<SlotApplication> _receivedApplications = [];
  int _pendingApplicationsCount = 0;
  int _lastUpdateTimestamp = 0; // Pour forcer les rebuilds

  // Tous les postes ouverts disponibles (pour chercher une équipe)
  List<OpenSlot> _allOpenSlots = [];

  // Mes candidatures envoyées
  List<SlotApplicationDetail> _myApplications = [];

  // Toutes les équipes (pour découverte)
  List<TeamPreview> _allTeamsForDiscover = [];

  // Mes demandes de rejoindre une équipe
  List<TeamJoinRequest> _myJoinRequests = [];

  // Défis de match reçus en attente
  List<MatchChallenge> _pendingChallenges = [];

  // Invitations à rejoindre une équipe
  List<TeamInvitation> _pendingInvitations = [];

  // Candidatures de joueurs pour rejoindre mes équipes sur des matchs publics
  List<MatchApplication> _receivedMatchApplications = [];

  // Demandes de joueurs pour rejoindre mes équipes (approbation requise)
  List<ReceivedJoinRequest> _receivedJoinRequests = [];

  // Invitations envoyées par mon équipe (vue propriétaire)
  List<SentInvitation> _sentInvitations = [];

  // Chat d'équipe
  final Map<int, List<TeamChatMessage>> _teamMessages =
      {}; // teamId -> messages
  List<TeamChatInfo> _myTeamChats = [];
  bool _isLoadingMessages = false;
  bool _isSendingMessage = false;
  bool _isTeamChatConnected = false;
  int? _activeTeamChatId;

  // Polling pour les messages non lus (fallback si WebSocket non connecté)
  Timer? _chatPollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 10);

  // Polling pour les notifications (défis + invitations)
  Timer? _notificationsPollingTimer;
  bool _isNotificationsRefreshRunning = false;

  // Getters
  TeamsLoadingState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoadingInitial => _isLoadingInitial;
  List<TeamPreview> get teams => _teams;
  TeamDetail? get myTeam => _myTeam;
  TeamDetail? get selectedTeam => _selectedTeam;
  List<TeamDetail> get teamsMemberOf => _teamsMemberOf;
  int get currentTeamIndex => _currentTeamIndex;
  List<OpenSlot> get myOpenSlots => _myOpenSlots;
  List<SlotApplication> get receivedApplications => _receivedApplications;
  List<OpenSlot> get allOpenSlots => _allOpenSlots;
  List<SlotApplicationDetail> get myApplications => _myApplications;
  List<TeamPreview> get allTeamsForDiscover => _allTeamsForDiscover;
  List<TeamJoinRequest> get myJoinRequests => _myJoinRequests;
  List<MatchChallenge> get pendingChallenges =>
      List.unmodifiable(_pendingChallenges);
  int get pendingChallengesCount => _pendingChallenges.length;
  List<TeamInvitation> get pendingInvitations =>
      List.unmodifiable(_pendingInvitations);
  int get pendingInvitationsCount => _pendingInvitations.length;
  List<MatchApplication> get receivedMatchApplications =>
      List.unmodifiable(_receivedMatchApplications);
  int get receivedMatchApplicationsCount => _receivedMatchApplications.length;
  List<ReceivedJoinRequest> get receivedJoinRequests =>
      List.unmodifiable(_receivedJoinRequests);
  int get receivedJoinRequestsCount => _receivedJoinRequests.length;
  int get totalNotificationsCount =>
      pendingChallengesCount +
      pendingInvitationsCount +
      receivedMatchApplicationsCount +
      receivedJoinRequestsCount;

  List<SentInvitation> get sentInvitations =>
      List.unmodifiable(_sentInvitations);

  /// Invitations envoyées en attente pour un slot précis
  List<SentInvitation> sentInvitationsForSlot(int slotIndex) => _sentInvitations
      .where((inv) => inv.slotIndex == slotIndex && inv.status == 'pending')
      .toList();

  // Getters chat
  List<TeamChatInfo> get myTeamChats => _myTeamChats;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSendingMessage => _isSendingMessage;
  bool get isTeamChatConnected => _isTeamChatConnected;
  int? get activeTeamChatId => _activeTeamChatId;

  /// Retourne les messages d'une équipe spécifique
  List<TeamChatMessage> getMessagesForTeam(int teamId) =>
      _teamMessages[teamId] ?? [];

  /// Retourne le nombre de messages non lus pour une équipe
  int getUnreadCountForTeam(int teamId) {
    final chatInfo = _myTeamChats.where((c) => c.teamId == teamId).firstOrNull;
    return chatInfo?.unreadCount ?? 0;
  }

  /// Retourne le nombre total de messages non lus (toutes équipes)
  int get totalUnreadCount =>
      _myTeamChats.fold(0, (sum, chat) => sum + chat.unreadCount);

  /// Démarre le polling périodique des notifications d'équipe (défis + invitations)
  void startPollingNotifications({
    Duration interval = const Duration(seconds: 12),
  }) {
    _notificationsPollingTimer?.cancel();
    _silentRefreshNotifications();
    _notificationsPollingTimer = Timer.periodic(interval, (_) {
      _silentRefreshNotifications();
    });
  }

  /// Arrête le polling périodique des notifications
  void stopPollingNotifications() {
    _notificationsPollingTimer?.cancel();
    _notificationsPollingTimer = null;
  }

  /// Rafraîchit silencieusement les notifications sans changer l'état de chargement
  Future<void> _silentRefreshNotifications() async {
    if (_isNotificationsRefreshRunning) return;
    _isNotificationsRefreshRunning = true;
    try {
      await Future.wait([
        loadPendingChallenges(),
        loadPendingInvitations(),
        loadSentInvitations(),
        _silentRefreshTeamMembers(),
        _loadReceivedMatchApplications(),
        _loadReceivedJoinRequests(),
      ]);
    } catch (_) {
    } finally {
      _isNotificationsRefreshRunning = false;
    }
  }

  /// Rafraîchit silencieusement les membres de l'équipe (terrain) sans changer l'état de chargement
  Future<void> _silentRefreshTeamMembers() async {
    try {
      final results = await Future.wait([
        _teamsService.getMyTeam(),
        _teamsService.getTeamsMemberOf(),
      ]);
      final newMyTeam = results[0] as TeamDetail?;
      final newTeamsMemberOf = results[1] as List<TeamDetail>;

      bool changed = false;

      if (newMyTeam?.members.length != _myTeam?.members.length) {
        changed = true;
      } else if (newTeamsMemberOf.any((updated) {
        final current = _teamsMemberOf.firstWhere(
          (t) => t.id == updated.id,
          orElse: () => updated,
        );
        return updated.members.length != current.members.length;
      })) {
        changed = true;
      }

      if (changed) {
        _myTeam = newMyTeam;
        _teamsMemberOf = newTeamsMemberOf;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Retourne le nombre total de candidatures en attente
  int get pendingApplicationsCount {
    // Toujours recalculer pour éviter les problèmes de cache
    _updatePendingApplicationsCount();
    return _pendingApplicationsCount;
  }

  /// Timestamp de la dernière mise à jour (pour forcer les rebuilds)
  int get lastUpdateTimestamp => _lastUpdateTimestamp;

  /// Met à jour le compteur de candidatures en attente
  void _updatePendingApplicationsCount() {
    if (_receivedApplications.isEmpty) {
      _pendingApplicationsCount = 0;
      return;
    }

    final pendingApps = _receivedApplications
        .where((a) => a.status == ApplicationStatus.pending)
        .toList();

    _pendingApplicationsCount = pendingApps.length;
  }

  /// Retourne toutes les équipes (mon équipe + celles où je suis membre)
  List<TeamDetail> get allTeams {
    final List<TeamDetail> all = [];
    if (_myTeam != null) {
      all.add(_myTeam!);
    }
    all.addAll(_teamsMemberOf);
    return all;
  }

  /// Retourne l'équipe actuellement affichée
  TeamDetail? get currentDisplayedTeam {
    final all = allTeams;
    if (all.isEmpty) return null;
    if (_currentTeamIndex >= all.length) return all.first;
    return all[_currentTeamIndex];
  }

  /// Indique si on peut aller à l'équipe précédente
  bool get canGoPrevious => _currentTeamIndex > 0;

  /// Indique si on peut aller à l'équipe suivante
  bool get canGoNext => _currentTeamIndex < allTeams.length - 1;

  /// Indique si l'équipe affichée est "mon équipe" (celle que je possède)
  bool get isCurrentTeamMine {
    if (_myTeam == null) return false;
    final current = currentDisplayedTeam;
    return current != null && current.id == _myTeam!.id;
  }

  /// Indique si je fais partie de l'équipe affichée (owner OU membre)
  bool get isPartOfCurrentTeam {
    final current = currentDisplayedTeam;
    if (current == null) return false;
    // Soit c'est mon équipe (owner), soit je suis membre
    return allTeams.any((t) => t.id == current.id);
  }

  /// Change l'index du terrain affiché
  void setCurrentTeamIndex(int index) {
    if (index >= 0 && index < allTeams.length) {
      _currentTeamIndex = index;
      notifyListeners();
    }
  }

  /// Va au terrain précédent
  void goToPreviousTeam() {
    if (canGoPrevious) {
      _currentTeamIndex--;
      notifyListeners();
    }
  }

  /// Va au terrain suivant
  void goToNextTeam() {
    if (canGoNext) {
      _currentTeamIndex++;
      notifyListeners();
    }
  }

  /// Charge la liste des équipes
  Future<void> loadTeams() async {
    _state = TeamsLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _teams = await _teamsService.getTeams();
      _state = TeamsLoadingState.loaded;
    } catch (e) {
      _state = TeamsLoadingState.error;
      _errorMessage = 'Erreur: $e';
    }

    notifyListeners();
  }

  /// Charge "Mon Équipe" (équipe par défaut) ET les équipes où je suis membre
  Future<void> loadMyTeam() async {
    _isLoadingInitial = true;
    _state = TeamsLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Charger en parallèle mon équipe, les équipes où je suis membre, les défis et invitations
      final results = await Future.wait([
        _teamsService.getMyTeam(),
        _teamsService.getTeamsMemberOf(),
        _teamsService.getReceivedChallenges(),
        _teamsService.getPendingInvitations(),
      ]);

      _myTeam = results[0] as TeamDetail?;
      _teamsMemberOf = results[1] as List<TeamDetail>;
      final allChallenges = results[2] as List<MatchChallenge>;
      _pendingChallenges = allChallenges
          .where((c) => c.status == ChallengeStatus.pending)
          .toList();
      _pendingInvitations = results[3] as List<TeamInvitation>;

      // Charger les invitations envoyées si j'ai une équipe
      if (_myTeam != null) {
        _sentInvitations = await _teamsService.getSentInvitations(_myTeam!.id);
      }

      // Charger les postes ouverts et candidatures si j'ai une équipe
      if (_myTeam != null) {
        final additionalResults = await Future.wait([
          _teamsService.getTeamOpenSlots(_myTeam!.id),
          _teamsService.getTeamApplications(_myTeam!.id),
        ]);
        _myOpenSlots = additionalResults[0] as List<OpenSlot>;
        _receivedApplications = additionalResults[1] as List<SlotApplication>;
        _updatePendingApplicationsCount();
      }

      // Charger les infos de chat (pour les notifications de messages non lus)
      await loadMyTeamChats();

      // Réinitialiser l'index si nécessaire
      if (_currentTeamIndex >= allTeams.length && allTeams.isNotEmpty) {
        _currentTeamIndex = 0;
      }

      _state = TeamsLoadingState.loaded;
    } catch (e) {
      _state = TeamsLoadingState.error;
      _errorMessage = 'Erreur: $e';
    }

    _isLoadingInitial = false;
    notifyListeners();
  }

  /// Charge uniquement les équipes où je suis membre
  Future<void> loadTeamsMemberOf() async {
    try {
      _teamsMemberOf = await _teamsService.getTeamsMemberOf();
      notifyListeners();
    } catch (e) {
      // Error silently handled
    }
  }

  /// Recharge les défis de match reçus en attente
  Future<void> loadPendingChallenges() async {
    try {
      final all = await _teamsService.getReceivedChallenges();
      _pendingChallenges = all
          .where((c) => c.status == ChallengeStatus.pending)
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  /// Recharge les candidatures de matchs publics reçues (vue capitaine)
  Future<void> _loadReceivedMatchApplications() async {
    try {
      _receivedMatchApplications = await _teamsService
          .getReceivedMatchApplications();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadReceivedJoinRequests() async {
    try {
      _receivedJoinRequests = await _teamsService.getReceivedJoinRequests();
      notifyListeners();
    } catch (_) {}
  }

  /// Le capitaine répond à une demande de rejoindre
  Future<bool> respondToJoinRequest(
    int requestId, {
    required bool accept,
  }) async {
    try {
      final success = await _teamsService.respondToJoinRequest(
        requestId,
        accept: accept,
      );
      if (success) {
        _receivedJoinRequests.removeWhere((r) => r.id == requestId);
        notifyListeners();
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  /// Accepte une candidature de match public et retire-la de la liste locale
  Future<({bool success, String? errorMessage})> acceptReceivedMatchApplication(
    int applicationId,
  ) async {
    final result = await _teamsService.acceptMatchApplication(applicationId);
    if (result.success) {
      _receivedMatchApplications.removeWhere((a) => a.id == applicationId);
      notifyListeners();
    }
    return result;
  }

  /// Refuse une candidature de match public et retire-la de la liste locale
  Future<bool> rejectReceivedMatchApplication(int applicationId) async {
    final ok = await _teamsService.rejectMatchApplication(applicationId);
    if (ok) {
      _receivedMatchApplications.removeWhere((a) => a.id == applicationId);
      notifyListeners();
    }
    return ok;
  }

  /// Recharge les invitations d'équipe en attente
  Future<void> loadPendingInvitations() async {
    try {
      _pendingInvitations = await _teamsService.getPendingInvitations();
      notifyListeners();
    } catch (_) {}
  }

  /// Répondre à une invitation (accepter ou refuser)
  Future<bool> respondToInvitation({
    required int invitationId,
    required bool accept,
  }) async {
    try {
      final success = await _teamsService.respondToInvitation(
        invitationId: invitationId,
        accept: accept,
      );
      if (success) {
        _pendingInvitations.removeWhere((inv) => inv.id == invitationId);
        if (accept) {
          await loadMyTeam();
        }
        notifyListeners();
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  /// Charge les invitations envoyées par mon équipe
  Future<void> loadSentInvitations() async {
    if (_myTeam == null) return;
    try {
      _sentInvitations = await _teamsService.getSentInvitations(_myTeam!.id);
      notifyListeners();
    } catch (_) {}
  }

  /// Ajoute une invitation envoyée à l'état local (après envoi réussi)
  void addSentInvitation(SentInvitation inv) {
    _sentInvitations.removeWhere((e) => e.id == inv.id);
    _sentInvitations.add(inv);
    notifyListeners();
  }

  /// Annule une invitation envoyée (propriétaire uniquement)
  Future<bool> cancelInvitation(int invitationId) async {
    try {
      final success = await _teamsService.cancelInvitation(invitationId);
      if (success) {
        _sentInvitations.removeWhere((inv) => inv.id == invitationId);
        notifyListeners();
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  /// Charge les détails d'une équipe
  Future<void> loadTeam(int teamId) async {
    _state = TeamsLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedTeam = await _teamsService.getTeam(teamId);
      _state = TeamsLoadingState.loaded;
    } catch (e) {
      _state = TeamsLoadingState.error;
      _errorMessage = 'Erreur: $e';
    }

    notifyListeners();
  }

  /// Crée une nouvelle équipe
  Future<TeamPreview?> createTeam({
    required String name,
    String? description,
    String? logoUrl,
    bool isDefault = false,
  }) async {
    try {
      final team = await _teamsService.createTeam(
        name: name,
        description: description,
        logoUrl: logoUrl,
        isDefault: isDefault,
      );

      if (team != null) {
        _teams.add(team);
        notifyListeners();
      }

      return team;
    } catch (e) {
      return null;
    }
  }

  /// Supprime une équipe
  Future<bool> deleteTeam(int teamId) async {
    final success = await _teamsService.deleteTeam(teamId);

    if (success) {
      _teams.removeWhere((t) => t.id == teamId);
      notifyListeners();
    }

    return success;
  }

  /// Ajoute un membre à "Mon Équipe"
  Future<bool> addMemberToMyTeam({
    required int userId,
    required PlayerPosition position,
    required int slotIndex,
  }) async {
    if (_myTeam == null) return false;

    final member = await _teamsService.addMember(
      _myTeam!.id,
      userId: userId,
      position: position,
      slotIndex: slotIndex,
    );

    if (member != null) {
      await loadMyTeam(); // Recharger pour avoir la liste à jour
      return true;
    }

    return false;
  }

  /// Ajoute un membre à une équipe quelconque (par teamId)
  Future<bool> addMember({
    required int teamId,
    required int userId,
    required PlayerPosition position,
    required int slotIndex,
  }) async {
    final member = await _teamsService.addMember(
      teamId,
      userId: userId,
      position: position,
      slotIndex: slotIndex,
    );
    if (member != null) {
      await loadMyTeam();
      return true;
    }
    return false;
  }

  /// Retire un membre de "Mon Équipe"
  Future<bool> removeMemberFromMyTeam(int userId) async {
    if (_myTeam == null) return false;

    final success = await _teamsService.removeMember(_myTeam!.id, userId);

    if (success) {
      await loadMyTeam(); // Recharger pour avoir la liste à jour
    }

    return success;
  }

  /// Permet à l'utilisateur de quitter une équipe (si non propriétaire)
  Future<bool> leaveTeam(int teamId) async {
    final success = await _teamsService.leaveTeam(teamId);

    if (success) {
      // Retirer l'équipe de la liste des équipes dont je suis membre
      _teamsMemberOf.removeWhere((t) => t.id == teamId);
      // Retirer aussi du chat
      _myTeamChats.removeWhere((c) => c.teamId == teamId);
      _teamMessages.remove(teamId);
      notifyListeners();
    }

    return success;
  }

  /// Met à jour la position d'un membre dans "Mon Équipe"
  Future<bool> updateMemberPosition({
    required int userId,
    required PlayerPosition position,
  }) async {
    if (_myTeam == null) return false;

    // Indices occupés par les autres membres (pas le membre qu'on déplace)
    final othersOccupied = _myTeam!.members
        .where((m) => m.user.id != userId)
        .map((m) => m.slotIndex)
        .toSet();

    int effectiveSlotIndex;
    if (position == PlayerPosition.substitute) {
      effectiveSlotIndex = 5;
      for (final idx in [5, 6, 7]) {
        if (!othersOccupied.contains(idx)) {
          effectiveSlotIndex = idx;
          break;
        }
      }
    } else if (position == PlayerPosition.defender) {
      effectiveSlotIndex = 1;
      for (final idx in [1, 4]) {
        if (!othersOccupied.contains(idx)) {
          effectiveSlotIndex = idx;
          break;
        }
      }
    } else {
      // goalkeeper=0, midfielder=2, forward=3
      effectiveSlotIndex = position.index;
    }

    final member = await _teamsService.updateMemberPosition(
      _myTeam!.id,
      userId,
      position: position,
      slotIndex: effectiveSlotIndex,
    );

    if (member != null) {
      // Fermer le slot ouvert à la destination s'il y en avait un
      final openSlot = getOpenSlotForIndex(effectiveSlotIndex);
      if (openSlot != null) {
        await closeOpenSlot(openSlot.id);
      }
      await loadMyTeam();
      return true;
    }

    return false;
  }

  /// Sauvegarde toute la composition de "Mon Équipe" d'un coup
  Future<bool> saveMyTeamComposition({
    String? name,
    required List<MyTeamMemberInput> members,
  }) async {
    try {
      final team = await _teamsService.updateMyTeam(
        name: name,
        members: members,
      );

      if (team != null) {
        _myTeam = team;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Retourne un membre par son slot index
  TeamMember? getMemberBySlot(int slotIndex) {
    if (_myTeam == null) return null;
    try {
      return _myTeam!.members.firstWhere((m) => m.slotIndex == slotIndex);
    } catch (_) {
      return null;
    }
  }

  /// Vérifie si un utilisateur est déjà dans l'équipe
  bool isUserInTeam(int userId) {
    if (_myTeam == null) return false;
    return _myTeam!.members.any((m) => m.user.id == userId);
  }

  /// Réinitialise l'état
  void reset() {
    _state = TeamsLoadingState.idle;
    _errorMessage = null;
    _teams = [];
    _myTeam = null;
    _selectedTeam = null;
    _teamsMemberOf = [];
    _currentTeamIndex = 0;
    _myOpenSlots = [];
    _receivedApplications = [];
    _updatePendingApplicationsCount();
    _allOpenSlots = [];
    _myApplications = [];
    _allTeamsForDiscover = [];
    _myJoinRequests = [];
    notifyListeners();
  }

  // ============================================================
  // Postes Ouverts (Recherche de joueurs)
  // ============================================================

  /// Vérifie si un slot est en mode recherche
  bool isSlotOpen(int slotIndex) {
    return _myOpenSlots.any(
      (slot) => slot.slotIndex == slotIndex && slot.isActive,
    );
  }

  /// Retourne le poste ouvert pour un slot donné
  OpenSlot? getOpenSlotForIndex(int slotIndex) {
    for (final slot in _myOpenSlots) {
      if (slot.slotIndex == slotIndex && slot.isActive) return slot;
    }
    return null;
  }

  /// Charge les postes ouverts de mon équipe
  Future<void> loadMyOpenSlots() async {
    if (_myTeam == null) return;

    try {
      _myOpenSlots = await _teamsService.getTeamOpenSlots(_myTeam!.id);
      notifyListeners();
    } catch (e) {
      // Error silently handled
    }
  }

  /// Ouvre un poste à la recherche
  Future<bool> openSlotForSearch({
    required PlayerPosition position,
    required int slotIndex,
    String? description,
    bool openAllSlots = false,
    PlayerPosition? preferredPosition,
    DateTime? matchDate,
    String? matchLocation,
  }) async {
    if (_myTeam == null) return false;

    try {
      if (openAllSlots) {
        final occupiedIndices = _myTeam!.members
            .map((m) => m.slotIndex)
            .toSet();
        final alreadyOpenIndices = _myOpenSlots
            .where((s) => s.isActive)
            .map((s) => s.slotIndex)
            .toSet();
        final emptySlots = List.generate(5, (i) => i)
            .where(
              (i) =>
                  !occupiedIndices.contains(i) &&
                  !alreadyOpenIndices.contains(i),
            )
            .toList();

        bool anySuccess = false;
        for (final emptyIdx in emptySlots) {
          final slotPosition = PlayerPosition.values[emptyIdx];
          final slot = await _teamsService.createOpenSlot(
            _myTeam!.id,
            position: slotPosition,
            slotIndex: emptyIdx,
            description: description,
            preferredPosition: preferredPosition,
            matchDate: matchDate,
            matchLocation: matchLocation,
          );
          if (slot != null) {
            _myOpenSlots.add(slot);
            anySuccess = true;
          }
        }
        notifyListeners();
        return anySuccess;
      } else {
        final occupiedIndices = _myTeam!.members
            .map((m) => m.slotIndex)
            .toSet();
        final alreadyOpenIndices = _myOpenSlots
            .where((s) => s.isActive)
            .map((s) => s.slotIndex)
            .toSet();

        int effectiveSlotIndex = slotIndex;
        if (position == PlayerPosition.defender) {
          // Les deux slots défenseurs sont 1 et 4 — choisir le premier disponible
          const defenderSlots = [1, 4];
          for (final idx in [
            slotIndex,
            ...defenderSlots.where((i) => i != slotIndex),
          ]) {
            if (!occupiedIndices.contains(idx) &&
                !alreadyOpenIndices.contains(idx)) {
              effectiveSlotIndex = idx;
              break;
            }
          }
        } else if (position == PlayerPosition.substitute) {
          // Les slots remplaçants sont 5, 6, 7 — prendre le premier libre
          for (final idx in [5, 6, 7]) {
            if (!occupiedIndices.contains(idx) &&
                !alreadyOpenIndices.contains(idx)) {
              effectiveSlotIndex = idx;
              break;
            }
          }
        }

        final slot = await _teamsService.createOpenSlot(
          _myTeam!.id,
          position: position,
          slotIndex: effectiveSlotIndex,
          description: description,
          preferredPosition: preferredPosition,
          matchDate: matchDate,
          matchLocation: matchLocation,
        );
        if (slot != null) {
          _myOpenSlots.add(slot);
          notifyListeners();
          return true;
        }
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Ferme un poste ouvert (annule la recherche)
  Future<bool> closeOpenSlot(int slotId) async {
    try {
      final success = await _teamsService.closeOpenSlot(slotId);
      if (success) {
        _myOpenSlots.removeWhere((s) => s.id == slotId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Charge tous les postes ouverts disponibles
  Future<void> loadAllOpenSlots({PlayerPosition? position}) async {
    try {
      _allOpenSlots = await _teamsService.getAllOpenSlots(position: position);
      notifyListeners();
    } catch (e) {
      // Error silently handled
    }
  }

  // ============================================================
  // Candidatures
  // ============================================================

  /// Charge les candidatures reçues pour mon équipe
  Future<void> loadReceivedApplications() async {
    if (_myTeam == null) return;

    try {
      _receivedApplications = await _teamsService.getTeamApplications(
        _myTeam!.id,
      );
      for (var app in _receivedApplications) {}
      _updatePendingApplicationsCount();
      notifyListeners();
    } catch (e) {}
  }

  /// Charge mes candidatures envoyées
  Future<void> loadMyApplications() async {
    try {
      _myApplications = await _teamsService.getMyApplications();
      notifyListeners();
    } catch (e) {
      // Error silently handled
    }
  }

  /// Postuler à un poste ouvert
  Future<bool> applyToSlot(int slotId, {String? message}) async {
    try {
      final application = await _teamsService.applyToSlot(
        slotId,
        message: message,
      );
      if (application != null) {
        await loadMyApplications();
        // Mettre à jour les slots pour refléter qu'on a postulé
        await loadAllOpenSlots();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Accepter une candidature
  Future<bool> acceptApplication(int applicationId) async {
    try {
      final result = await _teamsService.respondToApplication(
        applicationId,
        accept: true,
      );

      if (result != null) {
        // Recharger tout car le joueur a été ajouté
        await loadMyTeam();
        await loadMyOpenSlots();
        await loadReceivedApplications();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Refuser une candidature
  Future<bool> rejectApplication(int applicationId) async {
    try {
      final result = await _teamsService.respondToApplication(
        applicationId,
        accept: false,
      );

      if (result != null) {
        // Supprimer immédiatement de la liste locale
        _receivedApplications.removeWhere((a) => a.id == applicationId);

        // Recalculer le compteur
        _updatePendingApplicationsCount();

        // Forcer un timestamp pour garantir le rebuild
        _lastUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;

        // Notifier immédiatement les listeners
        notifyListeners();

        // Attendre un peu pour laisser l'UI se mettre à jour
        await Future.delayed(const Duration(milliseconds: 100));

        // Recharger depuis le serveur pour s'assurer de la cohérence
        await loadReceivedApplications();

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Annuler ma propre candidature
  Future<bool> cancelApplication(int applicationId) async {
    try {
      final success = await _teamsService.cancelApplication(applicationId);

      if (success) {
        // Retirer la candidature de la liste
        _myApplications.removeWhere((a) => a.id == applicationId);
        notifyListeners();

        // Recharger les postes ouverts car celui-ci pourrait redevenir disponible
        await loadAllOpenSlots();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // Rejoindre directement un poste ouvert
  // ============================================================

  /// Rejoindre directement un poste ouvert (sans validation)
  Future<({bool success, bool alreadyTaken})> joinSlotDirectly(
    int slotId,
  ) async {
    try {
      final result = await _teamsService.joinOpenSlotDirectly(slotId);
      if (result.success) {
        await Future.wait([loadMyTeam(), loadAllOpenSlots()]);
      } else if (result.alreadyTaken) {
        await loadAllOpenSlots();
      }
      return result;
    } catch (e) {
      return (success: false, alreadyTaken: false);
    }
  }

  // ============================================================
  // Demandes de rejoindre une équipe
  // ============================================================

  /// Charge toutes les équipes pour la découverte
  Future<void> loadAllTeamsForDiscover() async {
    try {
      _allTeamsForDiscover = await _teamsService.getAllTeamsForDiscover();
      notifyListeners();
    } catch (_) {}
  }

  /// Charge les demandes de rejoindre envoyées
  Future<void> loadMyJoinRequests() async {
    try {
      _myJoinRequests = await _teamsService.getMyJoinRequests();
      notifyListeners();
    } catch (_) {}
  }

  /// Envoie une demande pour rejoindre une équipe
  Future<bool> sendJoinRequest(int teamId, {String? source}) async {
    try {
      final request = await _teamsService.sendJoinRequest(
        teamId,
        source: source,
      );
      if (request != null) {
        _myJoinRequests.add(request);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Annule une demande de rejoindre
  Future<bool> cancelJoinRequest(int requestId) async {
    try {
      final success = await _teamsService.cancelJoinRequest(requestId);
      if (success) {
        _myJoinRequests.removeWhere((r) => r.id == requestId);
        notifyListeners();
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  // =====================
  // CHAT D'ÉQUIPE
  // =====================

  /// Initialise les callbacks WebSocket et se connecte au chat d'une équipe
  Future<void> connectToTeamChat(int teamId) async {
    // Configurer les callbacks
    _teamsService.onNewTeamMessage = _handleNewTeamMessage;
    _teamsService.onTeamMessagesRead = _handleTeamMessagesRead;
    _teamsService.onTeamChatConnected = () {
      _isTeamChatConnected = true;
      _activeTeamChatId = teamId;
      notifyListeners();
    };
    _teamsService.onTeamChatDisconnected = () {
      _isTeamChatConnected = false;
      _activeTeamChatId = null;
      notifyListeners();
    };

    // Se connecter
    await _teamsService.connectToTeamChat(teamId);
  }

  /// Déconnecte du chat d'équipe
  void disconnectFromTeamChat() {
    _teamsService.disconnectFromTeamChat();
    _isTeamChatConnected = false;
    _activeTeamChatId = null;
    notifyListeners();
  }

  /// Gère un nouveau message reçu via WebSocket
  void _handleNewTeamMessage(TeamChatMessage message) {
    // Ajouter le message à la fin de la liste (ordre chronologique: plus ancien -> plus récent)
    // L'API renvoie les messages en ordre chronologique, donc on doit garder cet ordre
    if (_teamMessages.containsKey(message.teamId)) {
      // Vérifier si le message n'existe pas déjà
      if (!_teamMessages[message.teamId]!.any((m) => m.id == message.id)) {
        _teamMessages[message.teamId] = [
          ..._teamMessages[message.teamId]!,
          message,
        ];
      }
    } else {
      _teamMessages[message.teamId] = [message];
    }

    // Mettre à jour le dernier message et le compteur dans les chats
    final chatIndex = _myTeamChats.indexWhere(
      (c) => c.teamId == message.teamId,
    );
    if (chatIndex != -1) {
      final oldChat = _myTeamChats[chatIndex];
      // Ne pas incrémenter si c'est notre propre message ou si on est dans le chat
      final shouldIncrementUnread = _activeTeamChatId != message.teamId;
      _myTeamChats[chatIndex] = TeamChatInfo(
        teamId: oldChat.teamId,
        teamName: oldChat.teamName,
        teamLogoUrl: oldChat.teamLogoUrl,
        membersCount: oldChat.membersCount,
        lastMessage: message,
        unreadCount: shouldIncrementUnread ? oldChat.unreadCount + 1 : 0,
      );
    } else {
      // Le chat n'existe pas encore, on le crée avec le message
      // Trouver l'équipe pour avoir le nom
      final team = allTeams.where((t) => t.id == message.teamId).firstOrNull;
      if (team != null) {
        _myTeamChats.add(
          TeamChatInfo(
            teamId: message.teamId,
            teamName: team.name,
            teamLogoUrl: team.logoUrl,
            membersCount: team.members.length,
            lastMessage: message,
            unreadCount: _activeTeamChatId == message.teamId ? 0 : 1,
          ),
        );
      }
    }

    notifyListeners();
  }

  /// Gère la notification de messages lus
  void _handleTeamMessagesRead(int teamId) {
    final chatIndex = _myTeamChats.indexWhere((c) => c.teamId == teamId);
    if (chatIndex != -1) {
      final oldChat = _myTeamChats[chatIndex];
      _myTeamChats[chatIndex] = TeamChatInfo(
        teamId: oldChat.teamId,
        teamName: oldChat.teamName,
        teamLogoUrl: oldChat.teamLogoUrl,
        membersCount: oldChat.membersCount,
        lastMessage: oldChat.lastMessage,
        unreadCount: 0,
      );
      notifyListeners();
    }
  }

  /// Envoie un message via WebSocket (temps réel)
  void sendMessageRealtime(String content) {
    if (content.trim().isEmpty) return;
    _teamsService.sendTeamMessageRealtime(content);
  }

  /// Marque les messages comme lus via WebSocket
  void markMessagesAsReadRealtime() {
    _teamsService.markTeamMessagesAsReadRealtime();
  }

  /// Charger la liste des chats d'équipe de l'utilisateur
  Future<void> loadMyTeamChats() async {
    try {
      final chats = await _teamsService.getMyTeamChats();

      // Fusionner avec les données existantes pour éviter le "flash"
      // Si on a déjà des données locales avec un unreadCount plus élevé,
      // on garde la valeur locale (mise à jour par WebSocket)
      for (int i = 0; i < chats.length; i++) {
        final newChat = chats[i];
        final existingIndex = _myTeamChats.indexWhere(
          (c) => c.teamId == newChat.teamId,
        );

        if (existingIndex != -1) {
          final existing = _myTeamChats[existingIndex];
          // Si le compteur local est plus élevé, on le garde (WebSocket a ajouté un message)
          if (existing.unreadCount > newChat.unreadCount) {
            chats[i] = TeamChatInfo(
              teamId: newChat.teamId,
              teamName: newChat.teamName,
              teamLogoUrl: newChat.teamLogoUrl,
              membersCount: newChat.membersCount,
              lastMessage: existing.lastMessage ?? newChat.lastMessage,
              unreadCount: existing.unreadCount,
            );
          }
        }
      }

      _myTeamChats = chats;
      notifyListeners();
    } catch (e) {}
  }

  /// Charger les messages d'une équipe spécifique
  Future<void> loadTeamMessages(
    int teamId, {
    int limit = 50,
    int? beforeId,
  }) async {
    _isLoadingMessages = true;
    notifyListeners();

    try {
      final messages = await _teamsService.getTeamMessages(
        teamId,
        limit: limit,
        beforeId: beforeId,
      );

      if (beforeId != null && _teamMessages.containsKey(teamId)) {
        // Charger les messages plus anciens (pagination) - les ajouter au début
        // car messages est en ordre chronologique (ancien -> récent)
        _teamMessages[teamId] = [...messages, ..._teamMessages[teamId]!];
      } else {
        // Premier chargement
        _teamMessages[teamId] = messages;
      }

      _isLoadingMessages = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Envoyer un message dans une équipe
  Future<bool> sendMessage(int teamId, String content) async {
    if (content.trim().isEmpty) return false;

    _isSendingMessage = true;
    notifyListeners();

    try {
      final message = await _teamsService.sendTeamMessage(teamId, content);

      if (message != null) {
        // Ajouter le message à la fin (ordre chronologique: plus ancien -> plus récent)
        if (_teamMessages.containsKey(teamId)) {
          _teamMessages[teamId] = [..._teamMessages[teamId]!, message];
        } else {
          _teamMessages[teamId] = [message];
        }

        _isSendingMessage = false;
        notifyListeners();
        return true;
      }

      _isSendingMessage = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isSendingMessage = false;
      notifyListeners();
      return false;
    }
  }

  /// Vider les messages d'une équipe (pour libérer la mémoire)
  void clearTeamMessages(int teamId) {
    _teamMessages.remove(teamId);
    notifyListeners();
  }

  /// Marquer les messages d'une équipe comme lus
  Future<void> markMessagesAsRead(int teamId) async {
    try {
      final success = await _teamsService.markMessagesAsRead(teamId);
      if (success) {
        // Mettre à jour le compteur local
        final chatIndex = _myTeamChats.indexWhere((c) => c.teamId == teamId);
        if (chatIndex != -1) {
          // Créer une nouvelle instance avec unreadCount à 0
          final oldChat = _myTeamChats[chatIndex];
          _myTeamChats[chatIndex] = TeamChatInfo(
            teamId: oldChat.teamId,
            teamName: oldChat.teamName,
            teamLogoUrl: oldChat.teamLogoUrl,
            membersCount: oldChat.membersCount,
            lastMessage: oldChat.lastMessage,
            unreadCount: 0,
          );
          notifyListeners();
        }
      }
    } catch (e) {}
  }

  // =====================
  // POLLING TEMPS RÉEL
  // =====================

  /// Démarre le polling pour rafraîchir les compteurs de messages non lus
  /// Le polling est un fallback - quand le WebSocket est connecté,
  /// les mises à jour sont instantanées
  void startChatPolling() {
    // Arrêter le timer existant s'il y en a un
    stopChatPolling();

    // Charger immédiatement
    loadMyTeamChats();

    // Démarrer le polling périodique (moins fréquent car WebSocket gère le temps réel)
    _chatPollingTimer = Timer.periodic(_pollingInterval, (_) {
      // Ne pas recharger si le WebSocket est connecté pour éviter le "flash"
      // Le WebSocket gère déjà les mises à jour en temps réel
      if (!_isTeamChatConnected) {
        loadMyTeamChats();
      }
    });
  }

  /// Arrête le polling
  void stopChatPolling() {
    _chatPollingTimer?.cancel();
    _chatPollingTimer = null;
  }

  @override
  void dispose() {
    stopPollingNotifications();
    stopChatPolling();
    _teamsService.disconnectFromTeamChat();
    super.dispose();
  }
}
