import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/teams_provider.dart';
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

/// Page pour découvrir les équipes en recherche de joueurs
class DiscoverTeamsPage extends StatefulWidget {
  const DiscoverTeamsPage({super.key});

  @override
  State<DiscoverTeamsPage> createState() => _DiscoverTeamsPageState();
}

class _DiscoverTeamsPageState extends State<DiscoverTeamsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PlayerPosition? _selectedPositionFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Business logic ──────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    final teamsProvider = context.read<TeamsProvider>();
    await Future.wait([
      teamsProvider.loadAllOpenSlots(position: _selectedPositionFilter),
      teamsProvider.loadMyApplications(),
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
          _buildCustomTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildOpenSlotsTab(), _buildMyApplicationsTab()],
            ),
          ),
        ],
      ),
    );
  }

  // ── Custom tab bar ──────────────────────────────────────────────────────────

  Widget _buildCustomTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _buildTabPill(0, 'ÉQUIPES'),
          const SizedBox(width: 8),
          _buildTabPill(1, 'CANDIDATURES'),
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
                color: isSelected ? const Color(0xFF0B0D11) : _dtMuted2,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Tabs ────────────────────────────────────────────────────────────────────

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
                        message: 'Aucune équipe en recherche pour le moment',
                        onRefresh: () => teamsProvider.loadAllOpenSlots(
                          position: _selectedPositionFilter,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: teamsProvider.allOpenSlots.length,
                        itemBuilder: (context, index) {
                          final slot = teamsProvider.allOpenSlots[index];
                          return _buildOpenSlotCard(slot);
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMyApplicationsTab() {
    return Consumer<TeamsProvider>(
      builder: (context, teamsProvider, _) {
        final applications = teamsProvider.myApplications;
        return RefreshIndicator(
          color: _dtAmber,
          onRefresh: () => teamsProvider.loadMyApplications(),
          child: applications.isEmpty
              ? _buildEmptyState(
                  icon: Icons.inbox_outlined,
                  message: 'Vous n\'avez pas encore postulé',
                  onRefresh: () => teamsProvider.loadMyApplications(),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    final app = applications[index];
                    return _buildApplicationCard(app);
                  },
                ),
        );
      },
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

  // ── Cards ───────────────────────────────────────────────────────────────────

  Widget _buildOpenSlotCard(OpenSlot slot) {
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
                // Logo
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
                    const Icon(Icons.format_quote, color: _dtMuted2, size: 18),
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
                  onTap: () => _showApplyDialog(slot),
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
                          Icons.send,
                          size: 12,
                          color: Color(0xFF0B0D11),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Postuler',
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

  Widget _buildApplicationCard(SlotApplicationDetail app) {
    final slot = app.openSlot;

    Color statusColor;
    Color statusDimColor;
    String statusText;
    IconData statusIcon;

    switch (app.status) {
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
                  ),
                  child: Center(
                    child: Text(
                      slot.teamName[0].toUpperCase(),
                      style: GoogleFonts.syne(
                        color: _dtAmber,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
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
                        slot.teamName,
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _dtWhite,
                        ),
                      ),
                      Text(
                        'Poste : ${slot.position.displayName}',
                        style: GoogleFonts.dmSans(
                          color: _dtMuted2,
                          fontSize: 12,
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
            if (app.message != null && app.message!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Votre message : "${app.message}"',
                style: GoogleFonts.dmSans(
                  color: _dtMuted2,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Envoyée ${_formatDate(app.appliedAt)}',
              style: GoogleFonts.dmSans(color: _dtMuted2, fontSize: 11),
            ),
            if (app.status == ApplicationStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => _showCancelConfirmation(app),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_dtAmberSoft, _dtAmberD],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh, size: 16, color: Color(0xFF0B0D11)),
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

  // ── Dialogs ─────────────────────────────────────────────────────────────────

  void _showApplyDialog(OpenSlot slot) {
    final messageController = TextEditingController();
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
                'Postuler chez ${slot.teamName}',
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _dtWhite,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.sports_soccer, color: _dtAmber, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Poste : ${slot.position.displayName}',
                    style: GoogleFonts.dmSans(color: _dtMuted2, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 3,
                style: GoogleFonts.dmSans(color: _dtWhite, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Message (optionnel)',
                  labelStyle: GoogleFonts.dmSans(
                    color: _dtMuted2,
                    fontSize: 12,
                  ),
                  hintText: 'Présentez-vous en quelques mots...',
                  hintStyle: GoogleFonts.dmSans(color: _dtMuted2, fontSize: 12),
                  filled: true,
                  fillColor: _dtCard2,
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
                    borderSide: const BorderSide(color: _dtAmber),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(dialogCtx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _dtCard2,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Annuler',
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
                        Navigator.pop(dialogCtx);
                        final teamsProvider = context.read<TeamsProvider>();
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await teamsProvider.applyToSlot(
                          slot.id,
                          message: messageController.text.trim().isNotEmpty
                              ? messageController.text.trim()
                              : null,
                        );
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Candidature envoyée !'
                                  : 'Vous avez déjà postulé ou une erreur est survenue',
                            ),
                            backgroundColor: success ? _dtSage : _dtRose,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_dtAmberSoft, _dtAmberD],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.send,
                                size: 14,
                                color: Color(0xFF0B0D11),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Envoyer',
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

  void _showCancelConfirmation(SlotApplicationDetail app) {
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
                'Annuler la candidature',
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _dtWhite,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Êtes-vous sûr de vouloir annuler votre candidature pour l\'équipe "${app.openSlot.teamName}" ?',
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
                        final teamsProvider = Provider.of<TeamsProvider>(
                          context,
                          listen: false,
                        );
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await teamsProvider.cancelApplication(
                          app.id,
                        );
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Candidature annulée avec succès'
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
