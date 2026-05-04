import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/teams_provider.dart';
import '../providers/auth_provider.dart';
import '../services/teams_service.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _dtBg = Color(0xFF0A0C10);
const _dtCard = Color(0xFF181A21);
const _dtCard2 = Color(0xFF1E2029);
const _dtBorder2 = Color(0x21FFFFFF);
const _dtAmber = Color(0xFFFF7F2A);
const _dtAmberSoft = Color(0xFFFF9A55);
const _dtAmberD = Color(0xFFD96820);
const _dtAmberDim = Color(0x1CFF7F2A);
const _dtSage = Color(0xFF4CAF82);
const _dtSageDim = Color(0x1C4CAF82);
const _dtRose = Color(0xFFD4607A);
const _dtRoseDim = Color(0x1CD4607A);
const _dtWhite = Color(0xFFF0F2F5);
const _dtMuted2 = Color(0x9EF0F2F5);

// ─── Top-level helpers ────────────────────────────────────────────────────────

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inDays > 0) {
    return 'il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
  } else if (diff.inHours > 0) {
    return 'il y a ${diff.inHours} heure${diff.inHours > 1 ? 's' : ''}';
  } else if (diff.inMinutes > 0) {
    return 'il y a ${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''}';
  } else {
    return 'à l\'instant';
  }
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class DiscoverTeamsPage extends StatefulWidget {
  const DiscoverTeamsPage({super.key});

  @override
  State<DiscoverTeamsPage> createState() => _DiscoverTeamsPageState();
}

class _DiscoverTeamsPageState extends State<DiscoverTeamsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PlayerPosition? _selectedPositionFilter;

  // Recherche dans l'onglet ÉQUIPES
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Tracks optimistic join-request state: teamId → true while sending
  final Set<int> _pendingJoinTeams = {};

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
    _searchController.dispose();
    super.dispose();
  }

  // ── Business logic ──────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final teamsProvider = context.read<TeamsProvider>();
    await Future.wait([
      teamsProvider.loadAllTeamsForDiscover(),
      teamsProvider.loadAllOpenSlots(position: _selectedPositionFilter),
      teamsProvider.loadMyJoinRequests(),
    ]);
  }

  void _applyFilter(PlayerPosition? position) {
    setState(() {
      _selectedPositionFilter = position;
    });
    context.read<TeamsProvider>().loadAllOpenSlots(position: position);
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dtBg,
      appBar: AppBar(
        backgroundColor: _dtCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                color: _dtCard2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _dtBorder2),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: _dtMuted2,
                size: 16,
              ),
            ),
          ),
        ),
        title: Text(
          'Trouve ton équipe',
          style: GoogleFonts.syne(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: _dtWhite,
          ),
        ),
        centerTitle: true,
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
      ),
      body: Column(
        children: [
          _buildAvailabilityBanner(context),
          _buildCustomTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllTeamsTab(),
                _buildOpenSlotsTab(),
                _buildMyJoinRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Availability banner ─────────────────────────────────────────────────────

  Widget _buildAvailabilityBanner(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isAvailable = auth.currentUser?.isAvailable ?? false;
        return GestureDetector(
          onTap: () {
            if (!isAvailable) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _AvailabilitySheet(auth: auth),
              );
            } else {
              auth.setAvailability(false);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isAvailable ? const Color(0x1AFF7F2A) : _dtCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isAvailable
                    ? _dtAmber.withValues(alpha: 0.40)
                    : _dtBorder2,
                width: isAvailable ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? _dtAmberDim
                        : const Color(0x0FFFFFFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isAvailable
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: isAvailable ? _dtAmber : _dtMuted2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAvailable
                                ? 'PROFIL VISIBLE'
                                : 'ÊTRE TROUVÉ PAR LES ÉQUIPES',
                            style: GoogleFonts.syne(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isAvailable ? _dtAmber : _dtMuted2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAvailable
                                ? 'Les équipes peuvent t\'inviter'
                                : 'Active pour recevoir des invitations',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: isAvailable ? _dtWhite : _dtMuted2,
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _showInfoModal(
                            'Rendez-vous visible auprès des équipes',
                            [
                              'Activez ce mode pour apparaître auprès des équipes incomplètes à la recherche d\'un joueur.',
                              '👉 Les équipes peuvent consulter votre profil et vous envoyer une demande pour rejoindre leur match.',
                              '👉 Vous pouvez accepter ou refuser chaque demande librement.',
                            ],
                          ),
                          child: Icon(
                            Icons.info_outline,
                            size: 14,
                            color: isAvailable
                                ? _dtAmber.withValues(alpha: 0.65)
                                : _dtMuted2.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 42,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? _dtAmber
                        : const Color(0xFF2A2D38),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 220),
                    alignment: isAvailable
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Custom tab bar ──────────────────────────────────────────────────────────

  Widget _buildCustomTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _buildTabPill(0, 'ÉQUIPES'),
          const SizedBox(width: 8),
          _buildTabPill(1, 'POSTES OUVERTS'),
          const SizedBox(width: 8),
          _buildTabPill(2, 'CANDIDATURES'),
        ],
      ),
    );
  }

  Widget _buildTabPill(int index, String label) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final isSelected = _tabController.index == index;
        return GestureDetector(
          onTap: () => _tabController.animateTo(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? _dtAmber : _dtCard2,
              borderRadius: BorderRadius.circular(8),
              border: isSelected ? null : Border.all(color: _dtBorder2),
            ),
            child: Text(
              label,
              style: GoogleFonts.syne(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isSelected
                    ? const Color(0xFF0B0D11)
                    : _dtMuted2,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Tab: ÉQUIPES (toutes les équipes) ───────────────────────────────────────

  Widget _buildAllTeamsTab() {
    return Consumer<TeamsProvider>(
      builder: (context, teamsProvider, _) {
        final myTeamIds = teamsProvider.allTeams.map((t) => t.id).toSet();
        final allTeams = teamsProvider.allTeamsForDiscover;

        final q = _searchQuery.toLowerCase().trim();
        final teams = q.isEmpty
            ? allTeams
            : allTeams.where((t) {
                final nameMatch = t.name.toLowerCase().contains(q);
                final ownerMatch =
                    t.ownerUsername?.toLowerCase().contains(q) ?? false;
                final codeMatch =
                    t.ownerCodeId?.toLowerCase().contains(q) ?? false;
                return nameMatch || ownerMatch || codeMatch;
              }).toList();

        return Column(
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: _dtCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x21FFFFFF)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: GoogleFonts.dmSans(
                    color: _dtWhite,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une équipe ou un capitaine...',
                    hintStyle: GoogleFonts.dmSans(
                      color: _dtMuted2,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: _dtMuted2,
                      size: 18,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(
                              Icons.close,
                              color: _dtMuted2,
                              size: 16,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            // Liste des équipes
            Expanded(
              child: RefreshIndicator(
                color: _dtAmber,
                onRefresh: () async {
                  await Future.wait([
                    teamsProvider.loadAllTeamsForDiscover(),
                    teamsProvider.loadMyJoinRequests(),
                  ]);
                },
                child: allTeams.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.groups_outlined,
                        message: 'Aucune équipe disponible pour le moment',
                        onRefresh: () => teamsProvider.loadAllTeamsForDiscover(),
                      )
                    : teams.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                'Aucune équipe pour "$_searchQuery"',
                                style: GoogleFonts.dmSans(
                                  color: _dtMuted2,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: teams.length,
                            itemBuilder: (context, index) {
                              final team = teams[index];
                              final isMember = myTeamIds.contains(team.id);
                              final pendingRequest = teamsProvider.myJoinRequests
                                  .where(
                                    (r) =>
                                        r.teamId == team.id &&
                                        r.status == ApplicationStatus.pending,
                                  )
                                  .firstOrNull;
                              return _buildTeamDiscoverCard(
                                team,
                                teamsProvider,
                                isMember: isMember,
                                pendingRequest: pendingRequest,
                              );
                            },
                          ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTeamDiscoverCard(
    TeamPreview team,
    TeamsProvider teamsProvider, {
    bool isMember = false,
    TeamJoinRequest? pendingRequest,
  }) {
    final isSending = _pendingJoinTeams.contains(team.id);
    final hasPendingRequest = pendingRequest != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: _dtCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _dtBorder2),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Logo
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _dtAmberDim,
                borderRadius: BorderRadius.circular(10),
                image: team.logoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(team.logoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: team.logoUrl == null
                  ? Center(
                      child: Text(
                        team.name[0].toUpperCase(),
                        style: GoogleFonts.syne(
                          color: _dtAmber,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: GoogleFonts.syne(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _dtWhite,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 12,
                        color: _dtMuted2,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${team.membersCount} joueur${team.membersCount > 1 ? 's' : ''}',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: _dtMuted2,
                        ),
                      ),
                      if (team.ownerUsername != null) ...[
                        const SizedBox(width: 8),
                        const Text(
                          '·',
                          style: TextStyle(color: _dtMuted2, fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '@${team.ownerUsername}',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: _dtAmber,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (team.description != null &&
                      team.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      team.description!,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: _dtMuted2,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Bouton
            if (isMember)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _dtSageDim,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _dtSage.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 12, color: _dtSage),
                    const SizedBox(width: 4),
                    Text(
                      'Membre',
                      style: GoogleFonts.syne(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _dtSage,
                      ),
                    ),
                  ],
                ),
              )
            else if (hasPendingRequest)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _dtAmberDim,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _dtAmber.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Envoyée',
                  style: GoogleFonts.syne(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _dtAmber,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: isSending
                    ? null
                    : () => _sendJoinRequest(team, teamsProvider),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSending
                        ? null
                        : const LinearGradient(
                            colors: [_dtAmberSoft, _dtAmberD],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: isSending ? _dtCard2 : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _dtAmber,
                          ),
                        )
                      : Text(
                          'Rejoindre',
                          style: GoogleFonts.syne(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0B0D11),
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendJoinRequest(
    TeamPreview team,
    TeamsProvider teamsProvider,
  ) async {
    setState(() => _pendingJoinTeams.add(team.id));
    final messenger = ScaffoldMessenger.of(context);
    final success = await teamsProvider.sendJoinRequest(team.id, source: 'discover');
    if (!mounted) return;
    setState(() => _pendingJoinTeams.remove(team.id));
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Demande envoyée à ${team.name} !'
              : 'Erreur lors de l\'envoi de la demande',
        ),
        backgroundColor: success ? _dtSage : _dtRose,
      ),
    );
  }

  // ── Tab: POSTES OUVERTS ─────────────────────────────────────────────────────

  Widget _buildOpenSlotsTab() {
    return Consumer<TeamsProvider>(
      builder: (context, teamsProvider, _) {
        return Column(
          children: [
            _buildPositionFilter(),
            Expanded(
              child: RefreshIndicator(
                color: _dtAmber,
                onRefresh: () => teamsProvider.loadAllOpenSlots(
                  position: _selectedPositionFilter,
                ),
                child: teamsProvider.allOpenSlots.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.sports_soccer,
                        message:
                            'Aucun poste ouvert disponible pour le moment',
                        onRefresh: () => teamsProvider.loadAllOpenSlots(
                          position: _selectedPositionFilter,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: teamsProvider.allOpenSlots.length,
                        itemBuilder: (context, index) {
                          final slot = teamsProvider.allOpenSlots[index];
                          return _buildOpenSlotCard(slot, teamsProvider);
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Tab: CANDIDATURES (demandes de rejoindre) ───────────────────────────────

  Widget _buildMyJoinRequestsTab() {
    return Consumer<TeamsProvider>(
      builder: (context, teamsProvider, _) {
        final requests = teamsProvider.myJoinRequests;
        return RefreshIndicator(
          color: _dtAmber,
          onRefresh: () => teamsProvider.loadMyJoinRequests(),
          child: requests.isEmpty
              ? _buildEmptyState(
                  icon: Icons.inbox_outlined,
                  message: 'Vous n\'avez pas encore envoyé de demande',
                  onRefresh: () => teamsProvider.loadMyJoinRequests(),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _buildJoinRequestCard(request, teamsProvider);
                  },
                ),
        );
      },
    );
  }

  Widget _buildJoinRequestCard(
    TeamJoinRequest request,
    TeamsProvider teamsProvider,
  ) {
    Color statusColor;
    Color statusDimColor;
    String statusText;
    IconData statusIcon;

    switch (request.status) {
      case ApplicationStatus.pending:
        statusColor = _dtAmber;
        statusDimColor = _dtAmberDim;
        statusText = 'En attente';
        statusIcon = Icons.hourglass_empty;
        break;
      case ApplicationStatus.accepted:
        statusColor = _dtSage;
        statusDimColor = _dtSageDim;
        statusText = 'Acceptée';
        statusIcon = Icons.check_circle;
        break;
      case ApplicationStatus.rejected:
        statusColor = _dtRose;
        statusDimColor = _dtRoseDim;
        statusText = 'Refusée';
        statusIcon = Icons.cancel;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: _dtCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _dtBorder2),
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
                    color: _dtAmberDim,
                    borderRadius: BorderRadius.circular(10),
                    image: request.teamLogoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(request.teamLogoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: request.teamLogoUrl == null
                      ? Center(
                          child: Text(
                            request.teamName[0].toUpperCase(),
                            style: GoogleFonts.syne(
                              color: _dtAmber,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    request.teamName,
                    style: GoogleFonts.syne(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: _dtWhite,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusDimColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: GoogleFonts.syne(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Envoyée ${_formatDate(request.createdAt)}',
              style: GoogleFonts.dmSans(color: _dtMuted2, fontSize: 11),
            ),
            if (request.status == ApplicationStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => _showCancelJoinRequestConfirmation(
                      request,
                      teamsProvider,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: _dtRose),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cancel_outlined,
                            size: 14,
                            color: _dtRose,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Annuler',
                            style: GoogleFonts.syne(
                              color: _dtRose,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Position filter ─────────────────────────────────────────────────────────

  Widget _buildPositionFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Tous',
            isSelected: _selectedPositionFilter == null,
            onTap: () => _applyFilter(null),
          ),
          const SizedBox(width: 8),
          ...PlayerPosition.values
              .where((p) => p != PlayerPosition.substitute)
              .map(
                (position) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(
                    label: position.displayName,
                    isSelected: _selectedPositionFilter == position,
                    onTap: () => _applyFilter(position),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _dtAmber : _dtCard2,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: _dtBorder2),
        ),
        child: Text(
          label,
          style: GoogleFonts.syne(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF0B0D11) : _dtMuted2,
          ),
        ),
      ),
    );
  }

  // ── Open slot card ──────────────────────────────────────────────────────────

  Widget _buildOpenSlotCard(OpenSlot slot, TeamsProvider teamsProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: _dtCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _dtBorder2),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _dtAmberDim,
                    borderRadius: BorderRadius.circular(10),
                    image: slot.teamLogoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(slot.teamLogoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: slot.teamLogoUrl == null
                      ? Center(
                          child: Text(
                            slot.teamName[0].toUpperCase(),
                            style: GoogleFonts.syne(
                              color: _dtAmber,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
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
                        slot.teamName,
                        style: GoogleFonts.syne(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _dtWhite,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'par @${slot.ownerUsername}',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: _dtMuted2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _dtAmberDim,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    slot.position.displayName,
                    style: GoogleFonts.syne(
                      color: _dtAmber,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            if (slot.description != null && slot.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _dtCard2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.format_quote,
                      color: _dtMuted2,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        slot.description!,
                        style: GoogleFonts.dmSans(
                          color: _dtMuted2,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.access_time, size: 13, color: _dtMuted2),
                const SizedBox(width: 4),
                Text(
                  _formatDate(slot.createdAt),
                  style: GoogleFonts.dmSans(color: _dtMuted2, fontSize: 11),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _joinSlot(slot, teamsProvider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_dtAmberSoft, _dtAmberD],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.login,
                          size: 12,
                          color: Color(0xFF0B0D11),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Rejoindre',
                          style: GoogleFonts.syne(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.6,
                            color: const Color(0xFF0B0D11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinSlot(OpenSlot slot, TeamsProvider teamsProvider) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await teamsProvider.joinSlotDirectly(slot.id);
    if (!mounted) return;

    if (result.success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tu as rejoint l\'équipe !'),
          backgroundColor: _dtSage,
        ),
      );
      Navigator.of(context).pop();
    } else if (result.alreadyTaken) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cette place a déjà été prise par un autre joueur.'),
          backgroundColor: _dtRose,
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Une erreur est survenue, réessaie plus tard.'),
          backgroundColor: _dtRose,
        ),
      );
    }
  }

  // ── Empty state ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required VoidCallback onRefresh,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: _dtMuted2),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.dmSans(color: _dtMuted2, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onRefresh,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_dtAmberSoft, _dtAmberD],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.refresh,
                    size: 16,
                    color: Color(0xFF0B0D11),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rafraîchir',
                    style: GoogleFonts.syne(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: const Color(0xFF0B0D11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Info modal ───────────────────────────────────────────────────────────────

  void _showInfoModal(String title, List<String> lines) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: _dtCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: _dtBorder2, width: 1),
            left: BorderSide(color: _dtBorder2, width: 1),
            right: BorderSide(color: _dtBorder2, width: 1),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _dtBorder2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.info_outline, color: _dtAmber, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.syne(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _dtWhite,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  line,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: _dtMuted2,
                    height: 1.55,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────────

  void _showCancelJoinRequestConfirmation(
    TeamJoinRequest request,
    TeamsProvider teamsProvider,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: _dtCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _dtBorder2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Annuler la demande',
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _dtWhite,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Annuler la demande pour rejoindre "${request.teamName}" ?',
                style: GoogleFonts.dmSans(color: _dtMuted2, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(dialogCtx).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _dtCard2,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Non',
                            style: GoogleFonts.syne(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _dtMuted2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.of(dialogCtx).pop();
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await teamsProvider.cancelJoinRequest(
                          request.id,
                        );
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Demande annulée'
                                  : 'Erreur lors de l\'annulation',
                            ),
                            backgroundColor: success ? _dtSage : _dtRose,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _dtRoseDim,
                          border: Border.all(color: _dtRose),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Oui, annuler',
                            style: GoogleFonts.syne(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _dtRose,
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
}

// ─── Availability Setup Sheet ────────────────────────────────────────────────

class _AvailabilitySheet extends StatefulWidget {
  final AuthProvider auth;
  const _AvailabilitySheet({required this.auth});

  @override
  State<_AvailabilitySheet> createState() => _AvailabilitySheetState();
}

class _AvailabilitySheetState extends State<_AvailabilitySheet> {
  late final List<DateTime> _dates = List.generate(
    7,
    (i) => DateTime.now().add(Duration(days: i)),
  );

  final Set<int> _selectedDays = {};
  final List<TextEditingController> _cityControllers = [
    TextEditingController(),
  ];
  int _radiusKm = 10;
  bool _loading = false;

  bool get _allSelected => _selectedDays.length == 7;

  @override
  void dispose() {
    for (final c in _cityControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _selectedDays.clear();
      } else {
        _selectedDays.addAll({0, 1, 2, 3, 4, 5, 6});
      }
    });
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    setState(() => _loading = true);
    final sortedIndices = _selectedDays.toList()..sort();
    final days = sortedIndices.map((i) => _fmt(_dates[i])).toList();
    final cities = _cityControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final expiry = DateTime.now().add(const Duration(days: 7));
    final endDate =
        '${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}';
    await widget.auth.setAvailability(
      true,
      days: days.isEmpty ? null : days,
      endDate: endDate,
      cities: cities.isEmpty ? null : cities,
      radiusKm: _radiusKm,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _dtCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _dtBorder2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'DISPONIBILITÉ',
              style: GoogleFonts.syne(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _dtWhite,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Renseigne tes créneaux pour être contacté par les bonnes équipes',
              style: GoogleFonts.dmSans(fontSize: 12, color: _dtMuted2),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Jours disponibles',
                    style: GoogleFonts.syne(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _dtWhite,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _allSelected
                          ? _dtAmberDim
                          : const Color(0x0EFFFFFF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _allSelected
                            ? _dtAmber.withValues(alpha: 0.4)
                            : _dtBorder2,
                      ),
                    ),
                    child: Text(
                      'Tous',
                      style: GoogleFonts.syne(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _allSelected ? _dtAmber : _dtMuted2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final sel = _selectedDays.contains(i);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (sel) {
                      _selectedDays.remove(i);
                    } else {
                      _selectedDays.add(i);
                    }
                  }),
                  child: Container(
                    width: 40,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _dtAmberDim : const Color(0x08FFFFFF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sel
                            ? _dtAmber.withValues(alpha: 0.4)
                            : _dtBorder2,
                      ),
                    ),
                    child: Text(
                      _fmt(_dates[i]),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.syne(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: sel ? _dtAmber : _dtMuted2,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Text(
              'Zone géographique',
              style: GoogleFonts.syne(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _dtWhite,
              ),
            ),
            const SizedBox(height: 10),
            ..._cityControllers.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: e.value,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: _dtWhite,
                        ),
                        cursorColor: _dtAmber,
                        decoration: InputDecoration(
                          hintText: 'Ville (ex: Paris)',
                          hintStyle: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: _dtMuted2,
                          ),
                          filled: true,
                          fillColor: const Color(0x08FFFFFF),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _dtBorder2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _dtBorder2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _dtAmber.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (e.key > 0) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(
                          () => _cityControllers.removeAt(e.key),
                        ),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _dtRoseDim,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.remove,
                            size: 18,
                            color: _dtRose,
                          ),
                        ),
                      ),
                    ],
                    if (e.key == _cityControllers.length - 1 &&
                        _cityControllers.length < 3) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(
                          () => _cityControllers.add(TextEditingController()),
                        ),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _dtAmberDim,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _dtAmber.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 18,
                            color: _dtAmber,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Rayon',
              style: GoogleFonts.syne(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _dtWhite,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [5, 10, 20, 50].map((km) {
                final sel = _radiusKm == km;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _radiusKm = km),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: sel ? _dtAmberDim : const Color(0x08FFFFFF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sel
                              ? _dtAmber.withValues(alpha: 0.4)
                              : _dtBorder2,
                        ),
                      ),
                      child: Text(
                        '$km km',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.syne(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: sel ? _dtAmber : _dtMuted2,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _loading ? null : _submit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _dtAmber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'ACTIVER MA DISPO',
                            style: GoogleFonts.syne(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
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
}
