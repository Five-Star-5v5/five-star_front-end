import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';

import 'package:provider/provider.dart';
import '../theme_config/colors_config.dart';
import '../providers/teams_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/auth_provider.dart';
import '../services/teams_service.dart';
import 'discover_teams_page.dart';
import 'team_chat_page.dart';
import 'find_opponents_page.dart';
import 'match_chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  /// Boutons d'action premium avec effet glass
  Widget _buildPremiumActionButtons(bool isDarkMode) {
    return Column(
      children: <Widget>[
        _buildGlassActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<DiscoverTeamsPage>(
              builder: (_) => const DiscoverTeamsPage(),
            ),
          ),
          icon: Icons.person_search,
          label: 'Trouve ton équipe',
          gradient: LinearGradient(
            colors: <Color>[
              Colors.orange.withOpacity(0.8),
              Colors.orange.withOpacity(0.6),
            ],
          ),
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 16),
        _buildGlassActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<FindOpponentsPage>(
              builder: (_) => const FindOpponentsPage(),
            ),
          ),
          icon: Icons.sports_soccer,
          label: 'Trouver des adversaires',
          gradient: LinearGradient(
            colors: <Color>[
              myAccentVibrantBlue.withOpacity(0.8),
              myAccentVibrantBlue.withOpacity(0.6),
            ],
          ),
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }

  Widget _buildGlassActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Gradient gradient,
    required bool isDarkMode,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const double _playerAvatarRadius = 28;

  bool _isLookingForOpponent = false;
  bool _isLoadingSearchPrefs = false;
  TeamSearchPreference? _searchPreference;
  int? _lastLoadedTeamId;
  List<MatchChallenge> _upcomingMatches = [];
  Map<int, int> _unreadMatchMessages = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TeamsProvider>();
      provider.loadMyTeam();
      provider.startChatPolling();
      provider.addListener(_onTeamChanged);
      _loadSearchPreferences();
    });
  }

  void _onTeamChanged() {
    final provider = context.read<TeamsProvider>();
    final currentTeam = provider.currentDisplayedTeam;
    if (currentTeam != null && currentTeam.id != _lastLoadedTeamId) {
      _loadSearchPreferences();
    }
  }

  Future<void> _loadSearchPreferences() async {
    final provider = context.read<TeamsProvider>();
    final team = provider.currentDisplayedTeam;

    if (team == null || !provider.isPartOfCurrentTeam) {
      setState(() {
        _isLookingForOpponent = false;
        _searchPreference = null;
        _lastLoadedTeamId = team?.id;
        _upcomingMatches = [];
      });
      return;
    }

    _lastLoadedTeamId = team.id;
    setState(() => _isLoadingSearchPrefs = true);

    try {
      final matchesFuture = TeamsService.instance.getTeamMatches(
        team.id,
        status: 'accepted',
      );

      if (provider.isCurrentTeamMine) {
        final results = await Future.wait([
          TeamsService.instance.getSearchPreferences(team.id),
          matchesFuture,
          TeamsService.instance.getAllUnreadCounts(),
        ]);

        if (mounted) {
          setState(() {
            _searchPreference = results[0] as TeamSearchPreference?;
            _isLookingForOpponent =
                _searchPreference?.isLookingForOpponent ?? false;
            _upcomingMatches = results[1] as List<MatchChallenge>;
            _unreadMatchMessages = results[2] as Map<int, int>;
            _isLoadingSearchPrefs = false;
          });
        }
      } else {
        final results = await Future.wait([
          matchesFuture,
          TeamsService.instance.getAllUnreadCounts(),
        ]);

        if (mounted) {
          setState(() {
            _searchPreference = null;
            _isLookingForOpponent = false;
            _upcomingMatches = results[0] as List<MatchChallenge>;
            _unreadMatchMessages = results[1] as Map<int, int>;
            _isLoadingSearchPrefs = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSearchPrefs = false);
    }
  }

  Future<void> _loadUpcomingMatches() async {
    final provider = context.read<TeamsProvider>();
    final team = provider.currentDisplayedTeam;
    if (team == null) return;
    // Suppression du setState inutilisé
    try {
      final matches = await TeamsService.instance.getTeamMatches(
        team.id,
        status: 'accepted',
      );
      if (mounted) {
        setState(() {
          _upcomingMatches = matches;
          // Suppression de l'affectation inutile
        });
      }
    } catch (e) {
      // Suppression du setState inutile
    }
  }

  Future<void> _toggleSearchMode(bool value) async {
    final provider = context.read<TeamsProvider>();
    final team = provider.currentDisplayedTeam;
    if (team == null) return;
    
    // Si on active le mode recherche, afficher le dialogue de configuration
    if (value) {
      _showSearchPreferencesDialog(context);
      return;  // Le dialogue gérera l'activation
    }
    
    // Si on désactive, faire la requête directement
    setState(() => _isLookingForOpponent = false);
    try {
      final result = await TeamsService.instance.updateSearchPreferences(
        team.id,
        isLookingForOpponent: false,
        preferredDays: _searchPreference?.preferredDays,
        preferredTimeSlots: _searchPreference?.preferredTimeSlots,
        preferredLocations: _searchPreference?.preferredLocations,
        skillLevel: _searchPreference?.skillLevel,
        description: _searchPreference?.description,
      );
      if (result != null && mounted) {
        setState(() => _searchPreference = result);
        _showSnackBar('Mode recherche désactivé', isSuccess: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLookingForOpponent = true);
        _showSnackBar('Erreur lors de la désactivation', isSuccess: false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Widget pour activer/désactiver le mode recherche d'adversaire
  Widget _buildSearchModeToggle(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      decoration: BoxDecoration(
        gradient: _isLookingForOpponent
            ? LinearGradient(
                colors: [
                  myAccentVibrantBlue.withOpacity(0.15),
                  myAccentVibrantBlue.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: _isLookingForOpponent
            ? null
            : (isDarkMode ? Colors.grey[850] : Colors.grey[50]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isLookingForOpponent
              ? myAccentVibrantBlue.withOpacity(0.5)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          if (_isLookingForOpponent)
            BoxShadow(
              color: myAccentVibrantBlue.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isLookingForOpponent
                        ? myAccentVibrantBlue.withOpacity(0.2)
                        : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _isLookingForOpponent
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: _isLookingForOpponent
                        ? myAccentVibrantBlue
                        : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mode recherche d\'adversaire',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          letterSpacing: -0.5,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLookingForOpponent
                            ? 'Visible par les autres équipes'
                            : 'Soyez découvert',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoadingSearchPrefs)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Transform.scale(
                    scale: 0.9,
                    child: Switch.adaptive(
                      value: _isLookingForOpponent,
                      onChanged: _toggleSearchMode,
                      activeColor: myAccentVibrantBlue,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Section des matchs à venir
  Widget _buildUpcomingMatchesSection(
    int myTeamId,
    bool isDarkMode,
    Color titleColor,
    bool isOwner,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.sports_soccer, color: myAccentVibrantBlue, size: 20),
            const SizedBox(width: 8),
            Text(
              'Matchs à venir',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: myAccentVibrantBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_upcomingMatches.length}',
                style: const TextStyle(
                  color: myAccentVibrantBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._upcomingMatches.map(
          (match) => _buildMatchCard(match, myTeamId, isDarkMode, isOwner),
        ),
      ],
    );
  }

  /// Carte pour afficher un match
  Widget _buildMatchCard(
    MatchChallenge match,
    int myTeamId,
    bool isDarkMode,
    bool isOwner,
  ) {
    final isChallenger = match.challengerTeamId == myTeamId;
    final opponentName = match.getOpponentName(myTeamId);
    final opponentLogo = match.getOpponentLogoUrl(myTeamId);
    final hasSubmitted = match.hasSubmittedScore(myTeamId);
    final opponentSubmittedScore = match.getOpponentSubmittedScore(myTeamId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: myAccentVibrantBlue.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec adversaire
          Row(
            children: [
              // Logo adversaire
              CircleAvatar(
                radius: 24,
                backgroundColor: myAccentVibrantBlue.withOpacity(0.2),
                backgroundImage: opponentLogo != null
                    ? NetworkImage(opponentLogo)
                    : null,
                child: opponentLogo == null
                    ? Text(
                        opponentName[0].toUpperCase(),
                        style: const TextStyle(
                          color: myAccentVibrantBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'vs $opponentName',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : MyprimaryDark,
                      ),
                    ),
                    Text(
                      isChallenger ? 'Défi envoyé' : 'Défi reçu',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Bouton chat avec badge de messages non lus
              _buildMatchChatButton(match, myTeamId, isDarkMode),
              const SizedBox(width: 8),
              // Statut
              _buildMatchStatusBadge(match, hasSubmitted, isDarkMode),
            ],
          ),
          const SizedBox(height: 12),
          // Infos du match
          if (match.proposedDate != null || match.proposedLocation != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (match.proposedDate != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatMatchDate(match.proposedDate!),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white : MyprimaryDark,
                          ),
                        ),
                      ],
                    ),
                  if (match.proposedDate != null &&
                      match.proposedLocation != null)
                    const SizedBox(height: 8),
                  if (match.proposedLocation != null)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            match.proposedLocation!,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white : MyprimaryDark,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Afficher le score de l'adversaire s'il a soumis et que je n'ai pas soumis
          if (opponentSubmittedScore != null && !hasSubmitted) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'L\'adversaire a soumis le score suivant :',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode
                                ? Colors.orange[200]
                                : Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Affichage du score avec noms d'équipes
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Équipe challenger
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                match.challengerTeamName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${opponentSubmittedScore['challengerScore']}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.blue[300]
                                        : Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Séparateur
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '-',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                        // Équipe challengée
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                match.challengedTeamName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${opponentSubmittedScore['challengedScore']}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.red[300]
                                        : Colors.red[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Boutons Valider / Contester - seulement pour l'owner
                  if (isOwner) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _contestMatchScore(match),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Contester'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _validateMatchScore(match),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Valider'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '⚠️ Si vous contestez → Match nul (0-0)',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    // Message pour les membres non-owner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'En attente de la validation du score par le capitaine',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.orange[300]
                                    : Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ]
          // Si j'ai déjà soumis, attente de validation
          else if (hasSubmitted) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.hourglass_empty,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Score soumis ! En attente de validation par l\'adversaire.',
                      style: TextStyle(color: Colors.green[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ]
          // Personne n'a soumis - seul l'owner peut soumettre
          else if (isOwner) ...[
            ElevatedButton.icon(
              onPressed: () => _showSubmitScoreDialog(match, myTeamId),
              icon: const Icon(Icons.scoreboard, size: 18),
              label: const Text('Enregistrer le résultat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: myAccentVibrantBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ]
          // Membre mais pas owner - afficher un message
          else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'En attente que le capitaine enregistre le résultat.',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Bouton d'annulation du match (visible pour tout le monde)
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: isOwner ? () => _cancelMatch(match) : null,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Annuler le match'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Badge de statut du match
  Widget _buildMatchStatusBadge(
    MatchChallenge match,
    bool hasSubmitted,
    bool isDarkMode,
  ) {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;

    if (match.scoreConflict) {
      bgColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red;
      text = 'Conflit';
      icon = Icons.warning;
    } else if (hasSubmitted) {
      bgColor = Colors.orange.withOpacity(0.1);
      textColor = Colors.orange;
      text = 'En attente';
      icon = Icons.hourglass_empty;
    } else {
      bgColor = myAccentVibrantBlue.withOpacity(0.1);
      textColor = myAccentVibrantBlue;
      text = 'À jouer';
      icon = Icons.sports_soccer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Bouton de chat pour un match avec badge de messages non lus
  Widget _buildMatchChatButton(
    MatchChallenge match,
    int myTeamId,
    bool isDarkMode,
  ) {
    final unreadCount = _unreadMatchMessages[match.id] ?? 0;
    final isChallenger = match.challengerTeamId == myTeamId;
    final myTeamName = isChallenger
        ? match.challengerTeamName
        : match.challengedTeamName;
    final opponentName = match.getOpponentName(myTeamId);
    final opponentLogo = match.getOpponentLogoUrl(myTeamId);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchChatPage(
              challengeId: match.id,
              myTeamName: myTeamName,
              opponentTeamName: opponentName,
              opponentTeamLogoUrl: opponentLogo,
              myTeamId: myTeamId,
            ),
          ),
        );
        // Recharger les messages non lus après retour du chat
        _loadUnreadCounts();
      },
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: myAccentVibrantBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              color: myAccentVibrantBlue,
              size: 20,
            ),
          ),
          // Badge de messages non lus
          if (unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Recharge les compteurs de messages non lus
  Future<void> _loadUnreadCounts() async {
    final counts = await TeamsService.instance.getAllUnreadCounts();
    if (mounted) {
      setState(() {
        _unreadMatchMessages = counts;
      });
    }
  }

  /// Formater la date du match
  String _formatMatchDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final matchDay = DateTime(date.year, date.month, date.day);

    String dayText;
    if (matchDay == today) {
      dayText = "Aujourd'hui";
    } else if (matchDay == tomorrow) {
      dayText = 'Demain';
    } else {
      final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      final months = [
        'jan',
        'fév',
        'mar',
        'avr',
        'mai',
        'juin',
        'juil',
        'août',
        'sep',
        'oct',
        'nov',
        'déc',
      ];
      dayText =
          '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
    }

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$dayText à ${hour}h$minute';
  }

  /// Dialog pour soumettre le score
  Future<void> _showSubmitScoreDialog(
    MatchChallenge match,
    int myTeamId,
  ) async {
    final myScoreController = TextEditingController();
    final opponentScoreController = TextEditingController();
    final opponentName = match.getOpponentName(myTeamId);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enregistrer le résultat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Entrez le score du match contre $opponentName',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Votre équipe',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: myScoreController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '-',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          opponentName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: opponentScoreController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '0',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'L\'adversaire devra confirmer ce score pour qu\'il soit validé.',
                        style: TextStyle(color: Colors.blue[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final myScore = int.tryParse(myScoreController.text);
                final opponentScore = int.tryParse(
                  opponentScoreController.text,
                );
                if (myScore != null && opponentScore != null) {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: myAccentVibrantBlue,
              ),
              child: const Text(
                'Valider',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final myScore = int.parse(myScoreController.text);
      final opponentScore = int.parse(opponentScoreController.text);

      final updated = await TeamsService.instance.submitMatchScore(
        match.id,
        myScore: myScore,
        opponentScore: opponentScore,
      );

      if (mounted) {
        if (updated != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                updated.scoreValidated
                    ? '✅ Score validé ! Les deux équipes ont confirmé le résultat.'
                    : '⏳ Score enregistré. En attente de confirmation de l\'adversaire.',
              ),
              backgroundColor: updated.scoreValidated
                  ? Colors.green
                  : Colors.orange,
            ),
          );
          _loadUpcomingMatches();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'enregistrement du score'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Valider le score soumis par l'adversaire
  Future<void> _validateMatchScore(MatchChallenge match) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valider le score'),
        content: const Text('Confirmez-vous que ce score est correct ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Valider', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await TeamsService.instance.validateMatchScore(
        match.id,
        validate: true,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Score validé !'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUpcomingMatches();
      }
    }
  }

  /// Contester le score - résulte en match nul
  Future<void> _contestMatchScore(MatchChallenge match) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contester le score'),
        content: const Text(
          'Si vous contestez ce score, le match sera déclaré nul (0-0).\n\n'
          'Êtes-vous sûr de vouloir contester ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Contester',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await TeamsService.instance.validateMatchScore(
        match.id,
        validate: false,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Score contesté - Match nul déclaré (0-0)'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadUpcomingMatches();
      }
    }
  }

  /// Annule un match (même accepté)
  Future<void> _cancelMatch(MatchChallenge match) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le match'),
        content: Text(
          'Êtes-vous sûr de vouloir annuler le match contre ${match.getOpponentName(_getMyTeamIdFromMatch(match))} ?\n\n'
          'Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Oui, annuler le match'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await TeamsService.instance.cancelChallenge(match.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match annulé'),
            backgroundColor: Colors.red,
          ),
        );
        _loadUpcomingMatches();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'annulation du match'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Helper pour obtenir l'ID de mon équipe à partir d'un match
  int _getMyTeamIdFromMatch(MatchChallenge match) {
    final provider = context.read<TeamsProvider>();
    return provider.currentDisplayedTeam?.id ?? match.challengerTeamId;
  }

  @override
  void dispose() {
    // Retirer le listener
    try {
      context.read<TeamsProvider>().removeListener(_onTeamChanged);
    } catch (_) {}
    super.dispose();
  }

  /// Affiche une boîte de dialogue pour confirmer la sortie de l'équipe
  void _showLeaveTeamDialog(
    BuildContext context,
    TeamDetail team,
    TeamsProvider teamsProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Quitter l\'équipe'),
          content: Text(
            'Êtes-vous sûr de vouloir quitter "${team.name}" ?\n\n'
            'Vous ne recevrez plus les messages de cette équipe et ne pourrez plus participer aux matchs.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(
                  dialogContext,
                ).pop(); // Fermer la boîte de dialogue

                // Afficher un indicateur de chargement
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext loadingContext) {
                    return const Center(child: CircularProgressIndicator());
                  },
                );

                // Quitter l'équipe
                final success = await teamsProvider.leaveTeam(team.id);

                // Fermer l'indicateur de chargement
                if (context.mounted) {
                  Navigator.of(context).pop();

                  if (success) {
                    // Recharger les équipes
                    await teamsProvider.loadMyTeam();

                    // Afficher un message de succès
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Vous avez quitté l\'équipe "${team.name}"',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    // Afficher un message d'erreur
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erreur lors de la sortie de l\'équipe'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Quitter'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color titleColor = isDarkMode ? myLightBackground : MyprimaryDark;

    return Scaffold(
      appBar: AppBar(title: null),
      body: Consumer<TeamsProvider>(
        builder: (context, teamsProvider, _) {
          if (teamsProvider.state == TeamsLoadingState.loading &&
              teamsProvider.allTeams.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTeams = teamsProvider.allTeams;
          final currentIndex = teamsProvider.currentTeamIndex;

          return RefreshIndicator(
            onRefresh: () => teamsProvider.loadMyTeam(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildTeamHeader(
                      context: context,
                      teamsProvider: teamsProvider,
                      titleColor: titleColor,
                      isDarkMode: isDarkMode,
                    ),
                    // Widget pour activer le mode recherche d'adversaire
                    if (teamsProvider.isCurrentTeamMine &&
                        teamsProvider.currentDisplayedTeam != null)
                      _buildSearchModeToggle(isDarkMode),
                    const SizedBox(height: 20),
                    if (allTeams.isEmpty)
                      _buildEmptyTeamPlaceholder(isDarkMode)
                    else
                      _buildTeamPitch(
                        context,
                        team: teamsProvider.currentDisplayedTeam!,
                        isMyTeam: teamsProvider.isCurrentTeamMine,
                        isDarkMode: isDarkMode,
                      ),
                    const SizedBox(height: 10),
                    if (allTeams.length > 1)
                      _buildPageIndicators(
                        allTeams.length,
                        currentIndex,
                        isDarkMode,
                      ),
                    const SizedBox(height: 20),
                    if (teamsProvider.isCurrentTeamMine)
                      _buildSubstitutesSection(
                        context,
                        teamsProvider: teamsProvider,
                        titleColor: titleColor,
                        isDarkMode: isDarkMode,
                      )
                    else if (teamsProvider.currentDisplayedTeam != null)
                      _buildOtherTeamSubstitutes(
                        teamsProvider.currentDisplayedTeam!,
                        titleColor: titleColor,
                        isDarkMode: isDarkMode,
                      ),
                    const SizedBox(height: 20),
                    // Indicateur de candidatures en attente
                    if (teamsProvider.isCurrentTeamMine)
                      Visibility(
                        visible: teamsProvider.pendingApplicationsCount > 0,
                        child: Container(
                          key: ValueKey(
                            'pending_apps_${teamsProvider.pendingApplicationsCount}_${teamsProvider.lastUpdateTimestamp}',
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.notifications_active,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${teamsProvider.pendingApplicationsCount} candidature(s) en attente',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _showAllApplicationsDialog(context),
                                child: const Text('Voir'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Section des matchs à venir (visible pour tous les membres)
                    if (teamsProvider.isPartOfCurrentTeam &&
                        _upcomingMatches.isNotEmpty)
                      _buildUpcomingMatchesSection(
                        teamsProvider.currentDisplayedTeam!.id,
                        isDarkMode,
                        titleColor,
                        teamsProvider.isCurrentTeamMine,
                      ),
                    const SizedBox(height: 10),
                    // Boutons premium glass
                    _buildPremiumActionButtons(isDarkMode),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Widget pour le bouton de chat avec badge de messages non lus
  Widget _buildChatButton({
    required BuildContext context,
    required TeamDetail team,
    required int unreadCount,
    required bool isDarkMode,
    double iconSize = 20,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            Icons.chat_bubble_outline,
            size: iconSize,
            color: isDarkMode ? myAccentVibrantBlue : MyprimaryDark,
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeamChatPage(
                  teamId: team.id,
                  teamName: team.name,
                  teamLogoUrl: team.logoUrl,
                  ownerId: team.ownerId,
                ),
              ),
            );
            // Recharger les chats pour mettre à jour le compteur
            if (context.mounted) {
              context.read<TeamsProvider>().loadMyTeamChats();
            }
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Chat d\'équipe',
        ),
        // Badge rouge pour les messages non lus
        if (unreadCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTeamHeader({
    required BuildContext context,
    required TeamsProvider teamsProvider,
    required Color titleColor,
    required bool isDarkMode,
  }) {
    final currentTeam = teamsProvider.currentDisplayedTeam;
    final isMyTeam = teamsProvider.isCurrentTeamMine;
    final allTeams = teamsProvider.allTeams;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [
                  Colors.grey[850]!.withOpacity(0.6),
                  Colors.grey[900]!.withOpacity(0.4),
                ]
              : [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Stack(
                children: [
                  if (currentTeam != null)
                    Positioned(
                      top: 0,
                      right: 12,
                      child: _buildChatButton(
                        context: context,
                        team: currentTeam,
                        unreadCount: teamsProvider.getUnreadCountForTeam(
                          currentTeam.id,
                        ),
                        isDarkMode: isDarkMode,
                        iconSize: 28,
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 74),
                        child: IconButton(
                          icon: Icon(
                            Icons.chevron_left,
                            color: teamsProvider.canGoPrevious
                                ? (isDarkMode
                                      ? myAccentVibrantBlue
                                      : MyprimaryDark)
                                : Colors.grey.withOpacity(0.3),
                            size: 32,
                          ),
                          onPressed: teamsProvider.canGoPrevious
                              ? () => teamsProvider.goToPreviousTeam()
                              : null,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            // Badge "Mon équipe" ou "Membre" avec bouton "Quitter" si membre
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isMyTeam
                                          ? [
                                              myAccentVibrantBlue.withOpacity(
                                                0.3,
                                              ),
                                              myAccentVibrantBlue.withOpacity(
                                                0.2,
                                              ),
                                            ]
                                          : [
                                              Colors.orange.withOpacity(0.3),
                                              Colors.orange.withOpacity(0.2),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isMyTeam ? '👑 Mon équipe' : '👤 Membre',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isMyTeam
                                          ? myAccentVibrantBlue
                                          : Colors.orange,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                // Bouton "Quitter l'équipe" si l'utilisateur est membre (non propriétaire)
                                if (!isMyTeam && currentTeam != null) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _showLeaveTeamDialog(
                                      context,
                                      currentTeam,
                                      teamsProvider,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.exit_to_app,
                                            size: 14,
                                            color: Colors.red[700],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Quitter',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.red[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    currentTeam?.name ?? 'Mon Équipe',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.5,
                                      color: titleColor,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isMyTeam)
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      size: 24,
                                      color: isDarkMode
                                          ? myAccentVibrantBlue
                                          : MyprimaryDark,
                                    ),
                                    onPressed: () =>
                                        _showEditTeamNameDialog(context),
                                    padding: const EdgeInsets.only(left: 4),
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                            if (allTeams.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${teamsProvider.currentTeamIndex + 1} / ${allTeams.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 74),
                        child: IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: teamsProvider.canGoNext
                                ? (isDarkMode
                                      ? myAccentVibrantBlue
                                      : MyprimaryDark)
                                : Colors.grey.withOpacity(0.3),
                            size: 32,
                          ),
                          onPressed: teamsProvider.canGoNext
                              ? () => teamsProvider.goToNextTeam()
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicators(int count, int currentIndex, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 12 : 8,
          height: isActive ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? myAccentVibrantBlue
                : (isDarkMode ? Colors.grey[600] : Colors.grey[400]),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyTeamPlaceholder(bool isDarkMode) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.green[800]! : Colors.green[600]!,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDarkMode ? Colors.white70 : Colors.white,
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups, size: 48, color: Colors.white.withOpacity(0.7)),
            const SizedBox(height: 12),
            Text(
              'Aucune équipe',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ajoutez des amis pour créer votre équipe',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamPitch(
    BuildContext context, {
    required TeamDetail team,
    required bool isMyTeam,
    required bool isDarkMode,
  }) {
    final starters = team.starters;

    return Container(
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2D5016).withOpacity(isDarkMode ? 0.8 : 1.0),
            const Color(0xFF1A3D0F).withOpacity(isDarkMode ? 0.6 : 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double width = constraints.maxWidth;
              final double height = constraints.maxHeight;
              final double avatarRadius = (width / 13).clamp(18.0, 32.0);
              final double avatarDiameter = avatarRadius * 2;

              // Placement horizontal : gardien à gauche, défenseurs au centre, attaquants à droite
              final List<List<int>> columns = [
                [0], // Gardien (à gauche)
                [1, 2], // Défenseurs (au centre)
                [3, 4], // Attaquants (à droite)
              ];

              TeamMember? getMember(int slotIndex) {
                try {
                  return starters.firstWhere((m) => m.slotIndex == slotIndex);
                } catch (_) {
                  return null;
                }
              }

              final double horizontalSpacing =
                  (width - avatarDiameter * columns.length) /
                  (columns.length + 1);
              List<Widget> playerWidgets = [];
              for (int i = 0; i < columns.length; i++) {
                final column = columns[i];
                final x =
                    horizontalSpacing * (i + 1) +
                    avatarRadius +
                    avatarDiameter * i;
                final count = column.length;
                final verticalSpacing =
                    (height - (count * avatarDiameter)) / (count + 1);
                for (int j = 0; j < count; j++) {
                  final y =
                      verticalSpacing * (j + 1) +
                      avatarRadius +
                      avatarDiameter * j;
                  final slotIndex = column[j];
                  final member = getMember(slotIndex);
                  playerWidgets.add(
                    Positioned(
                      left: x - avatarRadius,
                      top: y - avatarRadius,
                      child: _buildPlayerSlot(
                        context,
                        slotIndex: slotIndex,
                        position: PlayerPosition.values[slotIndex],
                        member: member,
                        isDarkMode: isDarkMode,
                        isEditable: isMyTeam,
                      ),
                    ),
                  );
                }
              }

              return Stack(
                children: [
                  // Terrain
                  CustomPaint(
                    size: Size(width, height),
                    painter: _ModernPitchPainter(Colors.white.withOpacity(0.5)),
                  ),
                  ...playerWidgets,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSubstitutesSection(
    BuildContext context, {
    required TeamsProvider teamsProvider,
    required Color titleColor,
    required bool isDarkMode,
  }) {
    final myTeam = teamsProvider.myTeam;
    final substitutes = myTeam?.substitutes ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Remplaçants',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: myAccentVibrantBlue),
              onPressed: () => _showAddPlayerDialog(
                context,
                slotIndex: 5 + substitutes.length,
                position: PlayerPosition.substitute,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (substitutes.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? MyprimaryDark.withOpacity(0.5)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child: Center(
              child: Text(
                'Aucun remplaçant\nAppuyez sur + pour ajouter',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: substitutes
                .map<Widget>(
                  (member) => _buildSubstitutePlayer(
                    member,
                    isDarkMode,
                    isEditable: true,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildOtherTeamSubstitutes(
    TeamDetail team, {
    required Color titleColor,
    required bool isDarkMode,
  }) {
    final substitutes = team.substitutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Remplaçants',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 10),
        if (substitutes.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? MyprimaryDark.withOpacity(0.5)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child: Center(
              child: Text(
                'Aucun remplaçant',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: substitutes
                .map<Widget>(
                  (member) => _buildSubstitutePlayer(
                    member,
                    isDarkMode,
                    isEditable: false,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildPlayerSlot(
    BuildContext context, {
    required int slotIndex,
    required PlayerPosition position,
    TeamMember? member,
    required bool isDarkMode,
    required bool isEditable,
  }) {
    final teamsProvider = context.read<TeamsProvider>();
    final isSlotOpen = isEditable && teamsProvider.isSlotOpen(slotIndex);
    final openSlot = isEditable
        ? teamsProvider.getOpenSlotForIndex(slotIndex)
        : null;

    if (member != null) {
      return GestureDetector(
        onTap: isEditable ? () => _showPlayerOptions(context, member) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircleAvatar(
              radius: _playerAvatarRadius,
              backgroundColor: myAccentVibrantBlue,
              backgroundImage: member.user.avatarUrl != null
                  ? NetworkImage(member.user.avatarUrl!)
                  : null,
              child: member.user.avatarUrl == null
                  ? Text(
                      member.user.username.isNotEmpty
                          ? member.user.username[0].toUpperCase()
                          : position.shortName,
                      style: const TextStyle(
                        color: MyprimaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              member.user.username.length > 8
                  ? '${member.user.username.substring(0, 8)}...'
                  : member.user.username,
              style: TextStyle(
                color: isDarkMode ? myLightBackground : MyprimaryDark,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Si le slot est en mode recherche
    if (isSlotOpen && openSlot != null) {
      return GestureDetector(
        onTap: () => _showOpenSlotOptions(context, openSlot, position),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Stack(
              children: [
                CircleAvatar(
                  radius: _playerAvatarRadius,
                  backgroundColor: Colors.orange.withOpacity(0.8),
                  child: const Icon(
                    Icons.person_search,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                if (openSlot.applicationsCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${openSlot.applicationsCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Recherche',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Slot vide
    return GestureDetector(
      onTap: isEditable
          ? () => _showAddPlayerDialog(
              context,
              slotIndex: slotIndex,
              position: position,
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircleAvatar(
            radius: _playerAvatarRadius,
            backgroundColor: Colors.white.withOpacity(0.3),
            child: Icon(
              isEditable ? Icons.add : Icons.person_outline,
              color: Colors.white.withOpacity(0.8),
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            position.shortName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubstitutePlayer(
    TeamMember member,
    bool isDarkMode, {
    required bool isEditable,
  }) {
    return GestureDetector(
      onTap: isEditable ? () => _showPlayerOptions(context, member) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? MyprimaryDark.withOpacity(0.7) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode
                ? myAccentVibrantBlue.withOpacity(0.3)
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircleAvatar(
              radius: 12,
              backgroundColor: myAccentVibrantBlue.withOpacity(0.7),
              backgroundImage: member.user.avatarUrl != null
                  ? NetworkImage(member.user.avatarUrl!)
                  : null,
              child: member.user.avatarUrl == null
                  ? Text(
                      member.user.username.isNotEmpty
                          ? member.user.username[0].toUpperCase()
                          : 'R',
                      style: const TextStyle(
                        color: MyprimaryDark,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              member.user.username,
              style: TextStyle(
                color: isDarkMode ? myLightBackground : MyprimaryDark,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            if (member.user.rating != null)
              Text(
                '⭐${member.user.rating!.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  void _showPlayerOptions(BuildContext context, TeamMember member) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    final isOwner = member.user.id == currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? MyprimaryDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: myAccentVibrantBlue,
              backgroundImage: member.user.avatarUrl != null
                  ? NetworkImage(member.user.avatarUrl!)
                  : null,
              child: member.user.avatarUrl == null
                  ? Text(
                      member.user.username[0].toUpperCase(),
                      style: const TextStyle(
                        color: MyprimaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  member.user.username,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? myLightBackground : MyprimaryDark,
                  ),
                ),
                if (isOwner) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: myAccentVibrantBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Vous',
                      style: TextStyle(
                        fontSize: 12,
                        color: myAccentVibrantBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              member.position.displayName,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: myAccentVibrantBlue),
              title: const Text('Changer de position'),
              onTap: () {
                Navigator.pop(ctx);
                _showChangePositionDialog(context, member);
              },
            ),
            // Le propriétaire ne peut pas se retirer de l'équipe
            if (!isOwner)
              ListTile(
                leading: const Icon(Icons.remove_circle, color: Colors.red),
                title: const Text('Retirer de l\'équipe'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      title: const Text('Retirer ce joueur ?'),
                      content: Text(
                        'Voulez-vous retirer ${member.user.username} de l\'équipe ?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx, false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx, true),
                          child: const Text(
                            'Retirer',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await context.read<TeamsProvider>().removeMemberFromMyTeam(
                      member.user.id,
                    );
                  }
                },
              )
            else
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'En tant que propriétaire, vous ne pouvez pas quitter l\'équipe.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddPlayerDialog(
    BuildContext context, {
    required int slotIndex,
    required PlayerPosition position,
  }) async {
    await context.read<FriendsProvider>().loadFriends();
    if (!context.mounted) return;
    final friends = context.read<FriendsProvider>().friends;
    final teamsProvider = context.read<TeamsProvider>();
    final currentUser = context.read<AuthProvider>().currentUser;
    final availableFriends = friends
        .where((f) => !teamsProvider.isUserInTeam(f.user.id))
        .toList();

    // Vérifier si le propriétaire peut s'ajouter lui-même
    final canAddSelf =
        currentUser != null && !teamsProvider.isUserInTeam(currentUser.id);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? MyprimaryDark : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (sheetCtx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Ajouter un ${position.displayName}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? myLightBackground : MyprimaryDark,
                ),
              ),
            ),
            // Option pour s'ajouter soi-même
            if (canAddSelf)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: myAccentVibrantBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: myAccentVibrantBlue.withOpacity(0.3),
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: myAccentVibrantBlue,
                    backgroundImage: currentUser.avatarUrl != null
                        ? NetworkImage(currentUser.avatarUrl!)
                        : null,
                    child: currentUser.avatarUrl == null
                        ? Text(
                            currentUser.username[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  title: Text(
                    'Me placer ici',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? myLightBackground : MyprimaryDark,
                    ),
                  ),
                  subtitle: Text(
                    '@${currentUser.username}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.person_add,
                    color: myAccentVibrantBlue,
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await teamsProvider.addMemberToMyTeam(
                      userId: currentUser.id,
                      position: position,
                      slotIndex: slotIndex,
                    );
                  },
                ),
              ),
            // Option pour mettre en mode recherche
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.person_search, color: Colors.white),
                ),
                title: const Text(
                  'Mettre en mode recherche',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Les joueurs de l\'app pourront postuler',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(ctx);
                  _showOpenSlotDialog(context, slotIndex, position);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[400])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'ou choisir un ami',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[400])),
                ],
              ),
            ),
            if (availableFriends.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Tous vos amis sont déjà dans l\'équipe !',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: availableFriends.length,
                  itemBuilder: (listCtx, index) {
                    final friend = availableFriends[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: MyprimaryDark,
                        backgroundImage: friend.user.avatarUrl != null
                            ? NetworkImage(friend.user.avatarUrl!)
                            : null,
                        child: friend.user.avatarUrl == null
                            ? Text(
                                friend.user.username[0].toUpperCase(),
                                style: const TextStyle(
                                  color: myAccentVibrantBlue,
                                ),
                              )
                            : null,
                      ),
                      title: Text(friend.user.username),
                      subtitle: Text(
                        friend.user.preferredPosition ?? 'Position non définie',
                      ),
                      trailing: friend.user.rating != null
                          ? Text('⭐ ${friend.user.rating!.toStringAsFixed(1)}')
                          : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        await teamsProvider.addMemberToMyTeam(
                          userId: friend.user.id,
                          position: position,
                          slotIndex: slotIndex,
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showOpenSlotDialog(
    BuildContext context,
    int slotIndex,
    PlayerPosition position,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDarkMode ? MyprimaryDark : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.person_search, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Rechercher un ${position.displayName}',
              style: TextStyle(
                color: isDarkMode ? myLightBackground : MyprimaryDark,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Les joueurs de l\'application pourront voir ce poste et postuler pour rejoindre votre équipe.',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (optionnel)',
                hintText: 'Ex: Recherche défenseur expérimenté...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await context
                  .read<TeamsProvider>()
                  .openSlotForSearch(
                    position: position,
                    slotIndex: slotIndex,
                    description: descriptionController.text.trim().isNotEmpty
                        ? descriptionController.text.trim()
                        : null,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Poste ouvert à la recherche !'
                          : 'Erreur lors de l\'ouverture du poste',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.person_search, color: Colors.white),
            label: const Text('Ouvrir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showOpenSlotOptions(
    BuildContext context,
    OpenSlot openSlot,
    PlayerPosition position,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final teamsProvider = context.read<TeamsProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? MyprimaryDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.orange,
              child: Icon(Icons.person_search, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              'Poste ${position.displayName} en recherche',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? myLightBackground : MyprimaryDark,
              ),
            ),
            if (openSlot.description != null) ...[
              const SizedBox(height: 8),
              Text(
                openSlot.description!,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${openSlot.applicationsCount} candidature(s)',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (openSlot.applicationsCount > 0)
              ListTile(
                leading: const Icon(Icons.people, color: myAccentVibrantBlue),
                title: const Text('Voir les candidatures'),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${openSlot.applicationsCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showApplicationsDialog(context, openSlot);
                },
              ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.red),
              title: const Text('Fermer la recherche'),
              subtitle: const Text('Annuler la recherche pour ce poste'),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('Fermer la recherche ?'),
                    content: const Text(
                      'Les candidatures en attente seront annulées.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        child: const Text(
                          'Fermer',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await teamsProvider.closeOpenSlot(openSlot.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showApplicationsDialog(BuildContext context, OpenSlot openSlot) async {
    final teamsProvider = context.read<TeamsProvider>();
    await teamsProvider.loadReceivedApplications();

    if (!context.mounted) return;

    final applications = teamsProvider.receivedApplications
        .where((a) => a.openSlotId == openSlot.id)
        .toList();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? MyprimaryDark : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (sheetCtx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Candidatures (${applications.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? myLightBackground : MyprimaryDark,
                ),
              ),
            ),
            if (applications.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune candidature pour le moment',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: applications.length,
                  itemBuilder: (listCtx, index) {
                    final app = applications[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: myAccentVibrantBlue,
                                  backgroundImage:
                                      app.applicant.avatarUrl != null
                                      ? NetworkImage(app.applicant.avatarUrl!)
                                      : null,
                                  child: app.applicant.avatarUrl == null
                                      ? Text(
                                          app.applicant.username[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: MyprimaryDark,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        app.applicant.username,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (app.applicant.rating != null)
                                        Text(
                                          '⭐ ${app.applicant.rating!.toStringAsFixed(1)}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (app.message != null &&
                                app.message!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '"${app.message}"',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await teamsProvider.rejectApplication(
                                      app.id,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Candidature refusée'),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'Refuser',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await teamsProvider.acceptApplication(
                                      app.id,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Joueur ajouté à l\'équipe !',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                  ),
                                  label: const Text('Accepter'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAllApplicationsDialog(BuildContext context) async {
    final teamsProvider = context.read<TeamsProvider>();
    await teamsProvider.loadReceivedApplications();

    if (!context.mounted) return;

    final applications = teamsProvider.receivedApplications;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? MyprimaryDark : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (sheetCtx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.inbox, color: myAccentVibrantBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Toutes les candidatures (${applications.length})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? myLightBackground : MyprimaryDark,
                    ),
                  ),
                ],
              ),
            ),
            if (applications.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune candidature en attente',
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: applications.length,
                  itemBuilder: (listCtx, index) {
                    final app = applications[index];
                    // Trouver le slot correspondant
                    final openSlot = teamsProvider.myOpenSlots
                        .where((s) => s.id == app.openSlotId)
                        .firstOrNull;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: myAccentVibrantBlue,
                                  backgroundImage:
                                      app.applicant.avatarUrl != null
                                      ? NetworkImage(app.applicant.avatarUrl!)
                                      : null,
                                  child: app.applicant.avatarUrl == null
                                      ? Text(
                                          app.applicant.username[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: MyprimaryDark,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        app.applicant.username,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (openSlot != null)
                                        Text(
                                          'Pour : ${openSlot.position.displayName}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (app.applicant.rating != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '⭐ ${app.applicant.rating!.toStringAsFixed(1)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                            if (app.message != null &&
                                app.message!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '"${app.message}"',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await teamsProvider.rejectApplication(
                                      app.id,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Candidature refusée'),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Refuser',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await teamsProvider.acceptApplication(
                                      app.id,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Joueur ajouté à l\'équipe !',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Accepter',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showChangePositionDialog(BuildContext context, TeamMember member) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? MyprimaryDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Changer la position de ${member.user.username}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? myLightBackground : MyprimaryDark,
              ),
            ),
            const SizedBox(height: 16),
            ...PlayerPosition.values.map(
              (position) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: member.position == position
                      ? myAccentVibrantBlue
                      : Colors.grey,
                  child: Text(
                    position.shortName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(position.displayName),
                trailing: member.position == position
                    ? const Icon(Icons.check, color: myAccentVibrantBlue)
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  int newSlotIndex = member.slotIndex;
                  if (position == PlayerPosition.substitute &&
                      member.slotIndex < 5) {
                    newSlotIndex = 5;
                  } else if (position != PlayerPosition.substitute &&
                      member.slotIndex >= 5) {
                    switch (position) {
                      case PlayerPosition.goalkeeper:
                        newSlotIndex = 0;
                        break;
                      case PlayerPosition.defender:
                        newSlotIndex = 1;
                        break;
                      case PlayerPosition.midfielder:
                        newSlotIndex = 3;
                        break;
                      case PlayerPosition.forward:
                        newSlotIndex = 4;
                        break;
                      default:
                        break;
                    }
                  }
                  await context.read<TeamsProvider>().updateMemberPosition(
                    userId: member.user.id,
                    position: position,
                    slotIndex: newSlotIndex,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTeamNameDialog(BuildContext context) {
    final teamsProvider = context.read<TeamsProvider>();
    final controller = TextEditingController(
      text: teamsProvider.myTeam?.name ?? 'Mon Équipe',
    );
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Nom de l\'équipe'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nom',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              if (controller.text.trim().isNotEmpty) {
                final currentMembers = teamsProvider.myTeam?.members ?? [];
                await teamsProvider.saveMyTeamComposition(
                  name: controller.text.trim(),
                  members: currentMembers
                      .map(
                        (m) => MyTeamMemberInput(
                          userId: m.user.id,
                          position: m.position,
                          slotIndex: m.slotIndex,
                        ),
                      )
                      .toList(),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  /// Affiche un sélecteur d'heure avec des roulettes verticales
  Future<TimeOfDay?> _showTimePickerWithWheels(
    BuildContext context,
    TimeOfDay? initialTime,
    bool isDarkMode,
  ) async {
    int selectedHour = initialTime?.hour ?? 8;
    int selectedMinute = initialTime?.minute ?? 0;

    return showDialog<TimeOfDay>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? MyprimaryDark : Colors.white,
        title: Text(
          'Sélectionner l\'heure',
          style: TextStyle(
            color: isDarkMode ? myLightBackground : MyprimaryDark,
          ),
        ),
        content: SizedBox(
          height: 200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Roulette des heures
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: selectedHour,
                  ),
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    selectedHour = index;
                  },
                  children: List.generate(
                    24,
                    (index) => Center(
                      child: Text(
                        index.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 24,
                          color: isDarkMode ? myLightBackground : MyprimaryDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                ':',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? myLightBackground : MyprimaryDark,
                ),
              ),
              // Roulette des minutes
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: selectedMinute ~/ 5,
                  ),
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    selectedMinute = index * 5;
                  },
                  children: List.generate(
                    12, // 0, 5, 10, 15... 55
                    (index) => Center(
                      child: Text(
                        (index * 5).toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 24,
                          color: isDarkMode ? myLightBackground : MyprimaryDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                TimeOfDay(hour: selectedHour, minute: selectedMinute),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: myAccentVibrantBlue,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Affiche le dialogue pour configurer les préférences de recherche d'adversaire
  void _showSearchPreferencesDialog(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // États locaux pour les sélections
    final selectedDays = <String>{};
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    final selectedCities = <String>[];
    final cityController = TextEditingController();
    
    // Pré-remplir avec les valeurs existantes si disponibles
    if (_searchPreference != null) {
      if (_searchPreference!.preferredDays != null) {
        selectedDays.addAll(_searchPreference!.preferredDays!);
      }
      if (_searchPreference!.preferredTimeSlots != null && 
          _searchPreference!.preferredTimeSlots!.isNotEmpty) {
        // Parser le format "HH:mm-HH:mm"
        final timeSlot = _searchPreference!.preferredTimeSlots!.first;
        final parts = timeSlot.split('-');
        if (parts.length == 2) {
          final start = parts[0].split(':');
          final end = parts[1].split(':');
          if (start.length == 2 && end.length == 2) {
            startTime = TimeOfDay(
              hour: int.tryParse(start[0]) ?? 8,
              minute: int.tryParse(start[1]) ?? 0,
            );
            endTime = TimeOfDay(
              hour: int.tryParse(end[0]) ?? 20,
              minute: int.tryParse(end[1]) ?? 0,
            );
          }
        }
      }
      if (_searchPreference!.preferredLocations != null) {
        selectedCities.addAll(_searchPreference!.preferredLocations!);
      }
    }
    
    final jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDarkMode ? MyprimaryDark : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.search, color: myAccentVibrantBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Préférences de recherche',
                  style: TextStyle(
                    color: isDarkMode ? myLightBackground : MyprimaryDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Jours disponibles
                  Text(
                    'Jours disponibles *',
                    style: TextStyle(
                      color: isDarkMode ? myLightBackground : MyprimaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: jours.map((jour) {
                      final isSelected = selectedDays.contains(jour);
                      return FilterChip(
                        label: Text(jour),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedDays.add(jour);
                            } else {
                              selectedDays.remove(jour);
                            }
                          });
                        },
                        selectedColor: myAccentVibrantBlue.withOpacity(0.3),
                        checkmarkColor: myAccentVibrantBlue,
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Plage horaire
                  Text(
                    'Plage horaire *',
                    style: TextStyle(
                      color: isDarkMode ? myLightBackground : MyprimaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Heure de début
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await _showTimePickerWithWheels(
                              context,
                              startTime ?? const TimeOfDay(hour: 8, minute: 0),
                              isDarkMode,
                            );
                            if (picked != null) {
                              setState(() {
                                startTime = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  startTime != null
                                      ? '${startTime!.hour.toString().padLeft(2, '0')}h${startTime!.minute.toString().padLeft(2, '0')}'
                                      : 'Début',
                                  style: TextStyle(
                                    color: startTime != null
                                        ? (isDarkMode ? myLightBackground : MyprimaryDark)
                                        : Colors.grey[600],
                                  ),
                                ),
                                const Icon(Icons.access_time, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.arrow_forward, color: myAccentVibrantBlue),
                      const SizedBox(width: 16),
                      // Heure de fin
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await _showTimePickerWithWheels(
                              context,
                              endTime ?? const TimeOfDay(hour: 20, minute: 0),
                              isDarkMode,
                            );
                            if (picked != null) {
                              setState(() {
                                endTime = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  endTime != null
                                      ? '${endTime!.hour.toString().padLeft(2, '0')}h${endTime!.minute.toString().padLeft(2, '0')}'
                                      : 'Fin',
                                  style: TextStyle(
                                    color: endTime != null
                                        ? (isDarkMode ? myLightBackground : MyprimaryDark)
                                        : Colors.grey[600],
                                  ),
                                ),
                                const Icon(Icons.access_time, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Villes
                  Text(
                    'Villes de déplacement *',
                    style: TextStyle(
                      color: isDarkMode ? myLightBackground : MyprimaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Liste des villes ajoutées
                  if (selectedCities.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedCities.map((city) {
                        return Chip(
                          label: Text(city),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() {
                              selectedCities.remove(city);
                            });
                          },
                          backgroundColor: myAccentVibrantBlue.withOpacity(0.2),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Champ pour ajouter une ville
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cityController,
                          decoration: InputDecoration(
                            hintText: 'Ajouter une ville',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              setState(() {
                                selectedCities.add(value.trim());
                                cityController.clear();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add, color: myAccentVibrantBlue),
                        onPressed: () {
                          final value = cityController.text.trim();
                          if (value.isNotEmpty) {
                            setState(() {
                              selectedCities.add(value);
                              cityController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  Text(
                    '* Champs obligatoires',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validation
                if (selectedDays.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez sélectionner au moins un jour'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (startTime == null || endTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez sélectionner une plage horaire'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                // Vérifier que l'heure de fin est après l'heure de début
                final startMinutes = startTime!.hour * 60 + startTime!.minute;
                final endMinutes = endTime!.hour * 60 + endTime!.minute;
                if (endMinutes <= startMinutes) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('L\'heure de fin doit être après l\'heure de début'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (selectedCities.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez ajouter au moins une ville'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Formater la plage horaire
                final timeSlot = '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}-${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';
                
                // Retourner les données
                Navigator.pop(context, {
                  'days': selectedDays.toList(),
                  'timeSlots': [timeSlot],
                  'cities': selectedCities,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: myAccentVibrantBlue,
              ),
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
    
    // Si l'utilisateur a validé, activer le mode recherche
    if (result != null && mounted) {
      final provider = context.read<TeamsProvider>();
      final team = provider.currentDisplayedTeam;
      if (team == null) return;
      
      setState(() => _isLookingForOpponent = true);
      
      try {
        final searchPref = await TeamsService.instance.updateSearchPreferences(
          team.id,
          isLookingForOpponent: true,
          preferredDays: result['days'] as List<String>,
          preferredTimeSlots: result['timeSlots'] as List<String>,
          preferredLocations: result['cities'] as List<String>,
          skillLevel: _searchPreference?.skillLevel,
          description: _searchPreference?.description,
        );
        
        if (searchPref != null && mounted) {
          setState(() => _searchPreference = searchPref);
          _showSnackBar('🔍 Mode recherche activé', isSuccess: true);
        } else if (mounted) {
          setState(() => _isLookingForOpponent = false);
          _showSnackBar('Erreur lors de l\'activation', isSuccess: false);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLookingForOpponent = false);
          _showSnackBar('Erreur: $e', isSuccess: false);
        }
      }
    }
  }
}

class _ModernPitchPainter extends CustomPainter {
  final Color lineColor;
  _ModernPitchPainter(this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Bordure du terrain
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Ligne médiane
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Cercle central
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height * 0.12,
      paint,
    );

    // Point central
    final centerPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 2, centerPaint);

    // Zones de but
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height * 0.25,
        size.width * 0.12,
        size.height * 0.5,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.88,
        size.height * 0.25,
        size.width * 0.12,
        size.height * 0.5,
      ),
      paint,
    );

    // Petites zones
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height * 0.35,
        size.width * 0.06,
        size.height * 0.3,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.94,
        size.height * 0.35,
        size.width * 0.06,
        size.height * 0.3,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
