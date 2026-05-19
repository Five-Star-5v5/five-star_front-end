import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/teams_service.dart';
import '../providers/teams_provider.dart';

import '../theme/app_colors.dart';

/// Page pour trouver des adversaires et gérer les défis
class FindOpponentsPage extends StatefulWidget {
  const FindOpponentsPage({super.key});

  @override
  State<FindOpponentsPage> createState() => _FindOpponentsPageState();
}

class _FindOpponentsPageState extends State<FindOpponentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedSkillLevel;
  bool _isLoading = false;

  List<TeamSearchResult> _opponents = [];
  List<MatchChallenge> _sentChallenges = [];
  List<MatchChallenge> _receivedChallenges = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final service = TeamsService.instance;
      final (opponents, sent, received) = await (
        service.searchOpponents(skillLevel: _selectedSkillLevel),
        service.getSentChallenges(),
        service.getReceivedChallenges(),
      ).wait;

      if (mounted) {
        setState(() {
          _opponents = opponents;
          _sentChallenges = sent;
          _receivedChallenges = received;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sentPending = _sentChallenges
        .where((c) => c.status == ChallengeStatus.pending)
        .length;
    final receivedPending = _receivedChallenges
        .where((c) => c.status == ChallengeStatus.pending)
        .length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border2),
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.muted2, size: 16),
            ),
          ),
        ),
        title: Text(
          'TROUVER DES ADVERSAIRES',
          style: GoogleFonts.syne(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.white,
          ),
        ),
        flexibleSpace: IgnorePointer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.4),
                radius: 2.4,
                colors: [Color(0x38FF7F2A), Colors.transparent],
              ),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.card2,
                  border: Border(bottom: BorderSide(color: AppColors.border2)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _buildCustomTab(0, 'RECHERCHE', null),
                    const SizedBox(width: 8),
                    _buildCustomTab(1, 'ENVOYÉS', sentPending),
                    const SizedBox(width: 8),
                    _buildCustomTab(2, 'REÇUS', receivedPending),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.amber))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSearchTab(),
                _buildSentChallengesTab(),
                _buildReceivedChallengesTab(),
              ],
            ),
    );
  }

  Widget _buildCustomTab(int index, String label, int? badgeCount) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() {});
        },
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.amber : AppColors.card2,
            borderRadius: BorderRadius.circular(6),
            border: isSelected ? null : Border.all(color: AppColors.border2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.syne(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isSelected ? AppColors.night : AppColors.muted2,
                ),
              ),
              if (badgeCount != null && badgeCount > 0) ...[
                const SizedBox(width: 4),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.night : AppColors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$badgeCount',
                      style: GoogleFonts.syne(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? AppColors.amber : AppColors.night,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        _buildSkillFilter(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.amber,
            child: _opponents.isEmpty
                ? _buildEmptyState(
                    icon: Icons.groups,
                    message: 'Aucune équipe en recherche d\'adversaire',
                    subtitle: 'Revenez plus tard ou modifiez vos filtres',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _opponents.length,
                    itemBuilder: (context, index) {
                      return _buildOpponentCard(_opponents[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillFilter() {
    final levels = ['Tous', 'débutant', 'intermédiaire', 'confirmé', 'expert'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: levels.map((level) {
          final isSelected = level == 'Tous'
              ? _selectedSkillLevel == null
              : _selectedSkillLevel == level;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSkillLevel = level == 'Tous' ? null : level;
                });
                _loadData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.amber : AppColors.card2,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? null : Border.all(color: AppColors.border2),
                ),
                child: Text(
                  level == 'Tous' ? level : _capitalizeFirst(level),
                  style: GoogleFonts.syne(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 11,
                    color: isSelected ? AppColors.night : AppColors.muted2,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOpponentCard(TeamSearchResult team) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border2),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Logo équipe
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.amberDim,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: team.teamLogoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            team.teamLogoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Text(
                                team.teamName[0].toUpperCase(),
                                style: GoogleFonts.syne(
                                  color: AppColors.amber,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            team.teamName[0].toUpperCase(),
                            style: GoogleFonts.syne(
                              color: AppColors.amber,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.teamName,
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.white,
                        ),
                      ),
                      Text(
                        'par @${team.ownerUsername}',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.muted2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (team.skillLevel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amberDim,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _capitalizeFirst(team.skillLevel!),
                      style: GoogleFonts.syne(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.people, size: 13, color: AppColors.muted2),
                const SizedBox(width: 4),
                Text(
                  '${team.membersCount} membres',
                  style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted2),
                ),
                if (team.preferredDays != null &&
                    team.preferredDays!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.calendar_today, size: 13, color: AppColors.muted2),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      team.preferredDays!.join(', '),
                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted2),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),

            if (team.preferredLocations != null &&
                team.preferredLocations!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 13, color: AppColors.muted2),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      team.preferredLocations!.join(', '),
                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted2),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            if (team.preferredTimeSlots != null &&
                team.preferredTimeSlots!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 13, color: AppColors.muted2),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatTimeSlot(team.preferredTimeSlots!.first),
                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted2),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            if (team.description != null && team.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.card2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.format_quote, color: AppColors.muted2, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        team.description!,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.muted2,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => _showChallengeDialog(context, team),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.amber, AppColors.amberD],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Défier',
                    style: GoogleFonts.syne(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.6,
                      color: AppColors.night,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentChallengesTab() {
    final activeSentChallenges = _sentChallenges
        .where(
          (challenge) =>
              challenge.status == ChallengeStatus.pending ||
              challenge.status == ChallengeStatus.accepted,
        )
        .toList();

    if (activeSentChallenges.isEmpty) {
      return _buildEmptyState(
        icon: Icons.send,
        message: 'Aucun défi envoyé',
        subtitle: 'Recherchez des adversaires et défiez-les !',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.amber,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeSentChallenges.length,
        itemBuilder: (context, index) {
          return _buildChallengeCard(activeSentChallenges[index], isSent: true);
        },
      ),
    );
  }

  Widget _buildReceivedChallengesTab() {
    final activeReceivedChallenges = _receivedChallenges
        .where(
          (challenge) =>
              challenge.status == ChallengeStatus.pending ||
              challenge.status == ChallengeStatus.accepted,
        )
        .toList();

    if (activeReceivedChallenges.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox,
        message: 'Aucun défi reçu',
        subtitle: 'Les équipes qui vous défient apparaîtront ici',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.amber,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeReceivedChallenges.length,
        itemBuilder: (context, index) {
          return _buildChallengeCard(
            activeReceivedChallenges[index],
            isSent: false,
          );
        },
      ),
    );
  }

  Widget _buildChallengeCard(MatchChallenge challenge, {required bool isSent}) {
    final opponentTeamName = isSent
        ? challenge.challengedTeamName
        : challenge.challengerTeamName;
    final opponentLogoUrl = isSent
        ? challenge.challengedTeamLogoUrl
        : challenge.challengerTeamLogoUrl;
    final opponentUsername = isSent
        ? challenge.challengedOwnerUsername
        : challenge.challengerOwnerUsername;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border2),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.amberDim,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: opponentLogoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            opponentLogoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Text(
                                opponentTeamName[0].toUpperCase(),
                                style: GoogleFonts.syne(
                                  color: AppColors.amber,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            opponentTeamName[0].toUpperCase(),
                            style: GoogleFonts.syne(
                              color: AppColors.amber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSent ? 'Défi envoyé à' : 'Défi de',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: AppColors.muted2,
                        ),
                      ),
                      Text(
                        opponentTeamName,
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.white,
                        ),
                      ),
                      Text(
                        '@$opponentUsername',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.muted2,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(challenge.status),
              ],
            ),

            if (challenge.proposedDate != null ||
                challenge.proposedLocation != null) ...[
              const SizedBox(height: 12),
              Container(height: 1, color: AppColors.border2),
              const SizedBox(height: 8),
              if (challenge.proposedDate != null)
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: AppColors.muted2,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat(
                        'EEEE d MMMM à HH:mm',
                        'fr_FR',
                      ).format(challenge.proposedDate!),
                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted2),
                    ),
                  ],
                ),
              if (challenge.proposedLocation != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: AppColors.muted2),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        challenge.proposedLocation!,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.muted2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],

            if (challenge.message != null && challenge.message!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.card2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.message, color: AppColors.muted2, size: 13),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        challenge.message!,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.muted2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (challenge.status == ChallengeStatus.completed &&
                challenge.challengerScore != null &&
                challenge.challengedScore != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.amberDim,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        challenge.challengerTeamName,
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${challenge.challengerScore} - ${challenge.challengedScore}',
                        style: GoogleFonts.syne(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amber,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        challenge.challengedTeamName,
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (challenge.status == ChallengeStatus.pending) ...[
              const SizedBox(height: 14),
              if (isSent)
                GestureDetector(
                  onTap: () => _cancelChallenge(challenge.id),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.card2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border2),
                    ),
                    child: Center(
                      child: Text(
                        'Annuler le défi',
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: AppColors.muted2,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _respondToChallenge(challenge.id, false),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.roseDim,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.rose),
                          ),
                          child: Center(
                            child: Text(
                              'Refuser',
                              style: GoogleFonts.syne(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: AppColors.rose,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _handleAcceptChallenge(challenge),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.amber, AppColors.amberD],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Accepter',
                              style: GoogleFonts.syne(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: AppColors.night,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],

            if (challenge.status == ChallengeStatus.accepted ||
                challenge.status == ChallengeStatus.completed) ...[
              const SizedBox(height: 14),
              _buildScoreSection(challenge, isSent),
            ],

            const SizedBox(height: 8),
            Text(
              'Défi du ${DateFormat('d MMM yyyy', 'fr_FR').format(challenge.createdAt)}',
              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreSection(MatchChallenge challenge, bool isChallenger) {
    final myTeamId = isChallenger
        ? challenge.challengerTeamId
        : challenge.challengedTeamId;
    final hasSubmitted = challenge.hasSubmittedScore(myTeamId);
    final opponentSubmittedScore = challenge.getOpponentSubmittedScore(
      myTeamId,
    );

    if (challenge.scoreValidated || challenge.scoreConflict) {
      return _buildFinalScoreDisplay(challenge, isChallenger);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (opponentSubmittedScore != null && !hasSubmitted) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amberDim,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.amber),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.amberSoft,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'L\'adversaire a soumis le score suivant :',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.amberSoft,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              challenge.challengerTeamName,
                              style: GoogleFonts.syne(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.amberDim,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${opponentSubmittedScore['challengerScore']}',
                                style: GoogleFonts.syne(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '-',
                          style: GoogleFonts.syne(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted2,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              challenge.challengedTeamName,
                              style: GoogleFonts.syne(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.roseDim,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${opponentSubmittedScore['challengedScore']}',
                                style: GoogleFonts.syne(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.rose,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _contestScore(challenge),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.roseDim,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.rose),
                          ),
                          child: Center(
                            child: Text(
                              'Contester',
                              style: GoogleFonts.syne(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: AppColors.rose,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _validateScore(challenge),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.sageDim,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.sage),
                          ),
                          child: Center(
                            child: Text(
                              'Valider',
                              style: GoogleFonts.syne(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: AppColors.sage,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Si vous contestez, le match sera déclaré nul (0-0)',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.muted2,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else if (hasSubmitted) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sageDim,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.sage),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.hourglass_empty,
                  color: AppColors.amberSoft,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Score soumis ! En attente de validation par l\'adversaire.',
                    style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.sage),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          GestureDetector(
            onTap: () => _showScoreDialog(
              context,
              challenge,
              isChallenger: isChallenger,
            ),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.amber, AppColors.amberD]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'Enregistrer le score',
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.6,
                    color: AppColors.night,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _validateScore(MatchChallenge challenge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Valider le score',
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Confirmez-vous que ce score est correct ?',
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.card2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border2),
                        ),
                        child: Center(
                          child: Text(
                            'Annuler',
                            style: GoogleFonts.syne(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.muted2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.sageDim,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.sage),
                        ),
                        child: Center(
                          child: Text(
                            'Valider',
                            style: GoogleFonts.syne(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppColors.sage,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final result = await TeamsService.instance.validateMatchScore(
        challenge.id,
        validate: true,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Score validé !'),
            backgroundColor: AppColors.sage,
          ),
        );
        _loadData();
      }
    }
  }

  Future<void> _contestScore(MatchChallenge challenge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Contester le score',
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Si vous contestez ce score, le match sera déclaré nul (0-0).\n\nÊtes-vous sûr de vouloir contester ?',
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.card2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border2),
                        ),
                        child: Center(
                          child: Text(
                            'Annuler',
                            style: GoogleFonts.syne(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.muted2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.roseDim,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.rose),
                        ),
                        child: Center(
                          child: Text(
                            'Contester',
                            style: GoogleFonts.syne(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppColors.rose,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final result = await TeamsService.instance.validateMatchScore(
        challenge.id,
        validate: false,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Score contesté - Match nul déclaré'),
            backgroundColor: AppColors.amber,
          ),
        );
        _loadData();
      }
    }
  }

  Widget _buildFinalScoreDisplay(MatchChallenge challenge, bool isChallenger) {
    final isConflict = challenge.scoreConflict;
    final myTeamName = isChallenger
        ? challenge.challengerTeamName
        : challenge.challengedTeamName;
    final opponentTeamName = isChallenger
        ? challenge.challengedTeamName
        : challenge.challengerTeamName;
    final myScore = isChallenger
        ? challenge.challengerScore
        : challenge.challengedScore;
    final opponentScore = isChallenger
        ? challenge.challengedScore
        : challenge.challengerScore;

    String resultText;
    Color resultColor;
    IconData resultIcon;

    if (myScore != null && opponentScore != null) {
      if (myScore > opponentScore) {
        resultText = 'Victoire !';
        resultColor = AppColors.sage;
        resultIcon = Icons.emoji_events;
      } else if (myScore < opponentScore) {
        resultText = 'Défaite';
        resultColor = AppColors.rose;
        resultIcon = Icons.sentiment_dissatisfied;
      } else {
        resultText = 'Match nul';
        resultColor = AppColors.amber;
        resultIcon = Icons.handshake;
      }
    } else {
      resultText = 'Score en attente';
      resultColor = AppColors.muted2;
      resultIcon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border2),
      ),
      child: Column(
        children: [
          Icon(resultIcon, size: 28, color: resultColor),
          const SizedBox(height: 6),
          Text(
            resultText,
            style: GoogleFonts.syne(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: resultColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        myTeamName,
                        style: GoogleFonts.syne(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amberDim,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${myScore ?? 0}',
                          style: GoogleFonts.syne(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '-',
                    style: GoogleFonts.syne(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted2,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        opponentTeamName,
                        style: GoogleFonts.syne(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.roseDim,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${opponentScore ?? 0}',
                          style: GoogleFonts.syne(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.rose,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isConflict) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.amberDim,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber, size: 14, color: AppColors.amber),
                  const SizedBox(width: 6),
                  Text(
                    'Scores contradictoires → Match nul déclaré',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.amberSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ChallengeStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case ChallengeStatus.pending:
        bg = AppColors.amberDim;
        fg = AppColors.amber;
        break;
      case ChallengeStatus.accepted:
        bg = AppColors.sageDim;
        fg = AppColors.sage;
        break;
      case ChallengeStatus.rejected:
        bg = AppColors.roseDim;
        fg = AppColors.rose;
        break;
      case ChallengeStatus.cancelled:
        bg = AppColors.card2;
        fg = AppColors.muted2;
        break;
      case ChallengeStatus.expired:
        bg = AppColors.card2;
        fg = AppColors.muted2;
        break;
      case ChallengeStatus.completed:
        bg = AppColors.amberDim;
        fg = AppColors.amber;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.displayName,
        style: GoogleFonts.syne(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.muted2),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.syne(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.muted2,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted2),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loadData,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.amber, AppColors.amberD]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Actualiser',
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.night,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChallengeDialog(BuildContext context, TeamSearchResult team) {
    final messageController = TextEditingController();
    final locationController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border2),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.amberDim,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              team.teamName[0].toUpperCase(),
                              style: GoogleFonts.syne(
                                color: AppColors.amber,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Défier ${team.teamName}',
                            style: GoogleFonts.syne(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Date picker
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 1),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 90),
                          ),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 20, minute: 0),
                          );
                          if (time != null) {
                            setDialogState(() {
                              selectedDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border2),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppColors.muted2,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              selectedDate != null
                                  ? DateFormat(
                                      'EEEE d MMMM à HH:mm',
                                      'fr_FR',
                                    ).format(selectedDate!)
                                  : 'Proposer une date (optionnel)',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: selectedDate != null
                                    ? AppColors.white
                                    : AppColors.muted2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Lieu
                    TextField(
                      controller: locationController,
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.white),
                      decoration: InputDecoration(
                        hintText: 'Lieu proposé (optionnel)',
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.muted2,
                        ),
                        prefixIcon: const Icon(
                          Icons.location_on,
                          color: AppColors.muted2,
                          size: 18,
                        ),
                        filled: true,
                        fillColor: AppColors.card2,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.amber),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Message
                    TextField(
                      controller: messageController,
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Message (optionnel)',
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.muted2,
                        ),
                        prefixIcon: const Icon(
                          Icons.message,
                          color: AppColors.muted2,
                          size: 18,
                        ),
                        filled: true,
                        fillColor: AppColors.card2,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.amber),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.card2,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border2),
                              ),
                              child: Center(
                                child: Text(
                                  'Annuler',
                                  style: GoogleFonts.syne(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: AppColors.muted2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              await _sendChallenge(
                                team.teamId,
                                proposedDate: selectedDate,
                                proposedLocation:
                                    locationController.text.isEmpty
                                    ? null
                                    : locationController.text,
                                message: messageController.text.isEmpty
                                    ? null
                                    : messageController.text,
                              );
                              if (mounted) {
                                Navigator.pop(context);
                              }
                            },
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.amber, AppColors.amberD],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Envoyer',
                                  style: GoogleFonts.syne(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: AppColors.night,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      messageController.dispose();
      locationController.dispose();
    });
  }

  void _showScoreDialog(
    BuildContext context,
    MatchChallenge challenge, {
    required bool isChallenger,
  }) {
    int myScore = 0;
    int opponentScore = 0;

    final myTeamName = isChallenger
        ? challenge.challengerTeamName
        : challenge.challengedTeamName;
    final opponentTeamName = isChallenger
        ? challenge.challengedTeamName
        : challenge.challengerTeamName;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border2),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Enregistrer le score',
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info validation mutuelle
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.amberDim,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.amberSoft,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'L\'adversaire devra confirmer ce score',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.amberSoft,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                myTeamName,
                                style: GoogleFonts.syne(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '(Vous)',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: AppColors.muted2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: myScore > 0
                                        ? () => setDialogState(() => myScore--)
                                        : null,
                                    child: Icon(
                                      Icons.remove_circle,
                                      color: myScore > 0 ? AppColors.amber : AppColors.muted2,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$myScore',
                                    style: GoogleFonts.syne(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () =>
                                        setDialogState(() => myScore++),
                                    child: const Icon(
                                      Icons.add_circle,
                                      color: AppColors.amber,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '-',
                          style: GoogleFonts.syne(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted2,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                opponentTeamName,
                                style: GoogleFonts.syne(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '(Adversaire)',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: AppColors.muted2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: opponentScore > 0
                                        ? () => setDialogState(
                                            () => opponentScore--,
                                          )
                                        : null,
                                    child: Icon(
                                      Icons.remove_circle,
                                      color: opponentScore > 0
                                          ? AppColors.amber
                                          : AppColors.muted2,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$opponentScore',
                                    style: GoogleFonts.syne(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () =>
                                        setDialogState(() => opponentScore++),
                                    child: const Icon(
                                      Icons.add_circle,
                                      color: AppColors.amber,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.card2,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border2),
                              ),
                              child: Center(
                                child: Text(
                                  'Annuler',
                                  style: GoogleFonts.syne(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: AppColors.muted2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              Navigator.pop(context);
                              await _updateScore(
                                challenge.id,
                                myScore,
                                opponentScore,
                              );
                            },
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.amber, AppColors.amberD],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Valider',
                                  style: GoogleFonts.syne(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: AppColors.night,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<String>> _getCommonPlayers(int opponentTeamId) async {
    try {
      final teamsProvider = context.read<TeamsProvider>();
      final myTeam = teamsProvider.currentDisplayedTeam;

      if (myTeam == null) {
        return [];
      }

      final commonPlayers = await TeamsService.instance.getCommonPlayers(
        myTeam.id,
        opponentTeamId,
      );

      return commonPlayers;
    } catch (e) {
      return [];
    }
  }

  Future<bool?> _showCommonPlayersAlert(
    String opponentTeamName,
    List<String> commonPlayers,
    String actionText,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border2),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning, color: AppColors.amber, size: 32),
              const SizedBox(height: 12),
              Text(
                'Attention !',
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.amber,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'L\'équipe "$opponentTeamName" partage ${commonPlayers.length} joueur(s) avec votre équipe :',
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.white),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.amberDim,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.amber),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: commonPlayers.map((player) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: AppColors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              player,
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Voulez-vous tout de même continuer ?',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.muted2,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.card2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border2),
                        ),
                        child: Center(
                          child: Text(
                            'Annuler',
                            style: GoogleFonts.syne(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.muted2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.amber, AppColors.amberD],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            actionText,
                            style: GoogleFonts.syne(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppColors.night,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendChallenge(
    int teamId, {
    DateTime? proposedDate,
    String? proposedLocation,
    String? message,
  }) async {
    final commonPlayers = await _getCommonPlayers(teamId);

    if (commonPlayers.isNotEmpty && mounted) {
      final opponentTeamName = _opponents
          .firstWhere(
            (t) => t.teamId == teamId,
            orElse: () => TeamSearchResult(
              teamId: teamId,
              teamName: 'Équipe adverse',
              ownerUsername: '',
              membersCount: 0,
            ),
          )
          .teamName;

      final confirmed = await _showCommonPlayersAlert(
        opponentTeamName,
        commonPlayers,
        'Envoyer le défi',
      );

      if (confirmed != true) {
        return;
      }
    }

    try {
      final result = await TeamsService.instance.createChallenge(
        challengedTeamId: teamId,
        proposedDate: proposedDate,
        proposedLocation: proposedLocation,
        message: message,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Défi envoyé !'),
            backgroundColor: AppColors.sage,
          ),
        );
        _loadData();
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.rose,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _cancelChallenge(int challengeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Annuler le défi',
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Voulez-vous vraiment annuler ce défi ?',
                style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.card2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border2),
                        ),
                        child: Center(
                          child: Text(
                            'Non',
                            style: GoogleFonts.syne(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.muted2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.roseDim,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.rose),
                        ),
                        child: Center(
                          child: Text(
                            'Oui, annuler',
                            style: GoogleFonts.syne(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppColors.rose,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      final success = await TeamsService.instance.cancelChallenge(challengeId);
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Défi annulé')));
        _loadData();
      }
    }
  }

  Future<void> _handleAcceptChallenge(MatchChallenge challenge) async {
    final opponentTeamId =
        challenge.challengerTeamId ==
            context.read<TeamsProvider>().currentDisplayedTeam?.id
        ? challenge.challengedTeamId
        : challenge.challengerTeamId;

    final opponentTeamName =
        challenge.challengerTeamId ==
            context.read<TeamsProvider>().currentDisplayedTeam?.id
        ? challenge.challengedTeamName
        : challenge.challengerTeamName;

    final commonPlayers = await _getCommonPlayers(opponentTeamId);

    if (commonPlayers.isNotEmpty && mounted) {
      final confirmed = await _showCommonPlayersAlert(
        opponentTeamName,
        commonPlayers,
        'Accepter le défi',
      );

      if (confirmed != true) return;
    }

    await _respondToChallenge(challenge.id, true);
  }

  Future<void> _respondToChallenge(int challengeId, bool accept) async {
    final result = await TeamsService.instance.respondToChallenge(
      challengeId,
      accept: accept,
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Défi accepté !' : 'Défi refusé'),
          backgroundColor: accept ? AppColors.sage : AppColors.muted2,
        ),
      );
      _loadData();
    }
  }

  Future<void> _updateScore(
    int challengeId,
    int myScore,
    int opponentScore,
  ) async {
    final result = await TeamsService.instance.submitMatchScore(
      challengeId,
      myScore: myScore,
      opponentScore: opponentScore,
    );

    if (result != null && mounted) {
      String message;
      Color bgColor;

      if (result.scoreValidated) {
        message = 'Score validé ! Les deux équipes ont confirmé le résultat.';
        bgColor = AppColors.sage;
      } else if (result.scoreConflict) {
        message =
            'Conflit de score ! Le score soumis ne correspond pas à celui de l\'adversaire.';
        bgColor = AppColors.amber;
      } else {
        message =
            'Score enregistré. En attente de confirmation de l\'adversaire.';
        bgColor = AppColors.amberD;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: bgColor),
      );
      _loadData();
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _formatTimeSlot(String timeSlot) {
    final parts = timeSlot.split('-');
    if (parts.length != 2) return timeSlot;

    final start = parts[0].replaceAll(':', 'h');
    final end = parts[1].replaceAll(':', 'h');

    return '$start - $end';
  }
}
