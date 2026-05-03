import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/teams_service.dart';

const _kBg = Color(0xFF0A0C10);
const _kCard = Color(0xFF181A21);
const _kCard2 = Color(0xFF1E2029);
const _kBorder = Color(0x12FFFFFF);
const _kBorder2 = Color(0x21FFFFFF);
const _kAmber = Color(0xFFFF7F2A);
const _kAmberDim = Color(0x1CFF7F2A);
const _kSage = Color(0xFF4CAF82);
const _kSageDim = Color(0x1C4CAF82);
const _kWhite = Color(0xFFF0F2F5);
const _kMuted2 = Color(0x9EF0F2F5);

class PublicMatchesPage extends StatefulWidget {
  const PublicMatchesPage({super.key});

  @override
  State<PublicMatchesPage> createState() => _PublicMatchesPageState();
}

class _PublicMatchesPageState extends State<PublicMatchesPage> {
  List<PublicMatch> _matches = [];
  bool _isLoading = true;

  // Tracks my pending applications: key = "$matchId-$teamId-$slotIndex"
  final Set<String> _pendingApplicationKeys = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final matches = await TeamsService.instance.getPublicMatches();
      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _appKey(int matchId, int teamId, int slotIndex) =>
      '$matchId-$teamId-$slotIndex';

  bool _hasPending(int matchId, int teamId, int slotIndex) =>
      _pendingApplicationKeys.contains(_appKey(matchId, teamId, slotIndex));

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff == 0) return "Aujourd'hui ${DateFormat('HH:mm').format(date)}";
    if (diff == 1) return "Demain ${DateFormat('HH:mm').format(date)}";
    return DateFormat('EEE d MMM • HH:mm', 'fr_FR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, color: _kWhite, size: 18),
        ),
        title: Text(
          'MATCHS OUVERTS',
          style: GoogleFonts.syne(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.06 * 15,
            color: _kWhite,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _kAmber, strokeWidth: 2))
          : _matches.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: _kAmber,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: _matches.length,
                    itemBuilder: (_, i) => _buildMatchCard(_matches[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer_outlined, size: 48, color: _kMuted2),
          const SizedBox(height: 16),
          Text(
            'Aucun match ouvert',
            style: GoogleFonts.syne(
                fontSize: 15, fontWeight: FontWeight.w700, color: _kMuted2),
          ),
          const SizedBox(height: 6),
          Text(
            'Les matchs avec des places libres apparaîtront ici',
            style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted2),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(PublicMatch match) {
    final openSlots = match.totalOpenSlots;
    return GestureDetector(
      onTap: () => _showMatchDetail(match),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: teams vs
            Row(
              children: [
                _buildTeamLogo(match.challengerTeam),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'VS',
                        style: GoogleFonts.syne(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: _kMuted2,
                        ),
                      ),
                      if (openSlots > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kSageDim,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                                color: _kSage.withValues(alpha: 0.3), width: 1),
                          ),
                          child: Text(
                            '$openSlots poste${openSlots > 1 ? 's' : ''} libre${openSlots > 1 ? 's' : ''}',
                            style: GoogleFonts.syne(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _kSage,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _buildTeamLogo(match.challengedTeam),
              ],
            ),
            const SizedBox(height: 10),
            // Team names
            Row(
              children: [
                Expanded(
                  child: Text(
                    match.challengerTeam.name,
                    style: GoogleFonts.syne(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kWhite,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                  ),
                ),
                Expanded(
                  child: Text(
                    match.challengedTeam.name,
                    style: GoogleFonts.syne(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kWhite,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Date & lieu
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kCard2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  if (match.proposedDate != null) ...[
                    const Icon(Icons.calendar_today, size: 12, color: _kMuted2),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(match.proposedDate!),
                      style:
                          GoogleFonts.dmSans(fontSize: 11, color: _kWhite),
                    ),
                  ],
                  if (match.proposedDate != null &&
                      match.proposedLocation != null)
                    Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 1,
                        height: 12,
                        color: _kBorder2),
                  if (match.proposedLocation != null) ...[
                    const Icon(Icons.location_on, size: 12, color: _kMuted2),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        match.proposedLocation!,
                        style:
                            GoogleFonts.dmSans(fontSize: 11, color: _kWhite),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (match.proposedDate == null &&
                      match.proposedLocation == null)
                    Text('Date et lieu à définir',
                        style:
                            GoogleFonts.dmSans(fontSize: 11, color: _kMuted2)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Open slots mini-preview per team
            Row(
              children: [
                _buildOpenSlotsMini(match.challengerTeam, match.id),
                const SizedBox(width: 8),
                _buildOpenSlotsMini(match.challengedTeam, match.id),
              ],
            ),
            const SizedBox(height: 10),
            // CTA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _kAmberDim,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: _kAmber.withValues(alpha: 0.25), width: 1),
              ),
              child: Text(
                'Voir les postes disponibles →',
                textAlign: TextAlign.center,
                style: GoogleFonts.syne(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _kAmber,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamLogo(PublicMatchTeamInfo team) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _kAmberDim,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAmber.withValues(alpha: 0.2), width: 1),
      ),
      child: team.logoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.network(team.logoUrl!, fit: BoxFit.cover),
            )
          : Center(
              child: Text(
                team.name[0].toUpperCase(),
                style: const TextStyle(
                  color: _kAmber,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
    );
  }

  Widget _buildOpenSlotsMini(PublicMatchTeamInfo team, int matchId) {
    final open = team.openSlots;
    if (open.isEmpty) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: _kCard2,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${team.name.split(' ').first} — complet',
            style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: _kSageDim,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kSage.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              team.name.split(' ').first,
              style: GoogleFonts.syne(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: _kSage,
              ),
            ),
            const SizedBox(height: 3),
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: open
                  .map((slot) => _hasPending(matchId, team.id, slot.slotIndex)
                      ? _chip('✓ ${slot.position.shortDisplayName}',
                          _kAmber.withValues(alpha: 0.8))
                      : _chip(slot.position.shortDisplayName, _kSage))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 8, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  // ── Match detail bottom sheet ──────────────────────────────────────────────

  void _showMatchDetail(PublicMatch match) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MatchDetailSheet(
        match: match,
        pendingApplicationKeys: _pendingApplicationKeys,
        onApply: (teamId, slotIndex) =>
            _applyToSlot(match, teamId, slotIndex),
      ),
    );
  }

  Future<void> _applyToSlot(
      PublicMatch match, int teamId, int slotIndex) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id;
    final username = auth.currentUser?.username ?? '';
    final avatarUrl = auth.currentUser?.avatarUrl;

    if (userId == null) return;

    final teamInfo = match.challengerTeam.id == teamId
        ? match.challengerTeam
        : match.challengedTeam;
    final slot =
        teamInfo.slots.firstWhere((s) => s.slotIndex == slotIndex);

    final key = _appKey(match.id, teamId, slotIndex);

    setState(() => _pendingApplicationKeys.add(key));

    try {
      final result = await TeamsService.instance.applyToPublicMatch(
        matchId: match.id,
        teamId: teamId,
        teamName: teamInfo.name,
        position: slot.position,
        slotIndex: slotIndex,
        applicantUserId: userId,
        applicantUsername: username,
        applicantAvatarUrl: avatarUrl,
      );

      if (!mounted) return;

      if (result.application != null) {
        _showSnack(
            'Candidature envoyée pour ${slot.position.displayName} — ${teamInfo.name}',
            isSuccess: true);
      } else {
        setState(() => _pendingApplicationKeys.remove(key));
        _showSnack(result.errorMessage ?? 'Erreur lors de la candidature',
            isSuccess: false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _pendingApplicationKeys.remove(key));
        _showSnack('Erreur lors de la candidature', isSuccess: false);
      }
    }
  }

  void _showSnack(String msg, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.dmSans(color: _kWhite, fontSize: 13)),
        backgroundColor: isSuccess ? _kSage : const Color(0xFFD4607A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }
}

// ── Match detail bottom sheet widget ──────────────────────────────────────────

class _MatchDetailSheet extends StatefulWidget {
  final PublicMatch match;
  final Set<String> pendingApplicationKeys;
  final Future<void> Function(int teamId, int slotIndex) onApply;

  const _MatchDetailSheet({
    required this.match,
    required this.pendingApplicationKeys,
    required this.onApply,
  });

  @override
  State<_MatchDetailSheet> createState() => _MatchDetailSheetState();
}

class _MatchDetailSheetState extends State<_MatchDetailSheet> {
  bool _isApplying = false;

  String _appKey(int matchId, int teamId, int slotIndex) =>
      '$matchId-$teamId-$slotIndex';

  bool _hasPending(int teamId, int slotIndex) =>
      widget.pendingApplicationKeys
          .contains(_appKey(widget.match.id, teamId, slotIndex));

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff == 0) return "Aujourd'hui ${DateFormat('HH:mm').format(date)}";
    if (diff == 1) return "Demain ${DateFormat('HH:mm').format(date)}";
    return DateFormat('EEEE d MMMM • HH:mm', 'fr_FR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            // Handle + header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _kBorder2,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Teams header
                  Row(
                    children: [
                      _teamHeader(match.challengerTeam),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'VS',
                          style: GoogleFonts.syne(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: _kMuted2,
                          ),
                        ),
                      ),
                      _teamHeader(match.challengedTeam),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Date & lieu
                  if (match.proposedDate != null ||
                      match.proposedLocation != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kCard2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          if (match.proposedDate != null) ...[
                            const Icon(Icons.calendar_today,
                                size: 13, color: _kMuted2),
                            const SizedBox(width: 6),
                            Text(_formatDate(match.proposedDate!),
                                style: GoogleFonts.dmSans(
                                    fontSize: 12, color: _kWhite)),
                          ],
                          if (match.proposedDate != null &&
                              match.proposedLocation != null)
                            Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                width: 1,
                                height: 12,
                                color: _kBorder2),
                          if (match.proposedLocation != null) ...[
                            const Icon(Icons.location_on,
                                size: 13, color: _kMuted2),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(match.proposedLocation!,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12, color: _kWhite),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  Container(height: 1, color: _kBorder),
                ],
              ),
            ),
            // Teams slots
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTeamSlots(match.challengerTeam)),
                    const SizedBox(width: 10),
                    Container(width: 1, height: 300, color: _kBorder),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTeamSlots(match.challengedTeam)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamHeader(PublicMatchTeamInfo team) {
    final openCount = team.openSlotsCount;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kAmberDim,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: _kAmber.withValues(alpha: 0.2), width: 1),
            ),
            child: team.logoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.network(team.logoUrl!, fit: BoxFit.cover),
                  )
                : Center(
                    child: Text(
                      team.name[0].toUpperCase(),
                      style: const TextStyle(
                          color: _kAmber,
                          fontWeight: FontWeight.w800,
                          fontSize: 20),
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            team.name,
            style: GoogleFonts.syne(
                fontSize: 12, fontWeight: FontWeight.w700, color: _kWhite),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (openCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kSageDim,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$openCount libre${openCount > 1 ? 's' : ''}',
                style: GoogleFonts.syne(
                    fontSize: 9, fontWeight: FontWeight.w700, color: _kSage),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamSlots(PublicMatchTeamInfo team) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...team.slots.map((slot) => _buildSlotRow(team, slot)),
      ],
    );
  }

  Widget _buildSlotRow(PublicMatchTeamInfo team, PublicMatchTeamSlot slot) {
    final hasPending = _hasPending(team.id, slot.slotIndex);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: slot.isOpen
            ? (hasPending
                ? _kAmberDim
                : _kSageDim.withValues(alpha: 0.5))
            : _kCard2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: slot.isOpen
              ? (hasPending
                  ? _kAmber.withValues(alpha: 0.4)
                  : _kSage.withValues(alpha: 0.3))
              : _kBorder,
          width: 1,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: slot.isOpen
          ? _buildOpenSlot(team, slot, hasPending)
          : _buildFilledSlot(slot),
    );
  }

  Widget _buildFilledSlot(PublicMatchTeamSlot slot) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _kBorder2,
            shape: BoxShape.circle,
            image: slot.avatarUrl != null
                ? DecorationImage(
                    image: NetworkImage(slot.avatarUrl!), fit: BoxFit.cover)
                : null,
          ),
          child: slot.avatarUrl == null
              ? Center(
                  child: Text(
                    (slot.username ?? '?')[0].toUpperCase(),
                    style: const TextStyle(
                        color: _kMuted2,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slot.username ?? '—',
                style: GoogleFonts.syne(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kWhite),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                slot.position.displayName,
                style: GoogleFonts.dmSans(fontSize: 9, color: _kMuted2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOpenSlot(
      PublicMatchTeamInfo team, PublicMatchTeamSlot slot, bool hasPending) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: hasPending
                    ? _kAmber.withValues(alpha: 0.15)
                    : _kSage.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasPending
                      ? _kAmber.withValues(alpha: 0.4)
                      : _kSage.withValues(alpha: 0.4),
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Icon(
                hasPending ? Icons.hourglass_top_rounded : Icons.add_rounded,
                size: 14,
                color: hasPending ? _kAmber : _kSage,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.position.displayName,
                    style: GoogleFonts.syne(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: hasPending ? _kAmber : _kSage,
                    ),
                  ),
                  Text(
                    hasPending ? 'Candidature envoyée' : 'Poste libre',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      color: hasPending
                          ? _kAmber.withValues(alpha: 0.7)
                          : _kSage.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!hasPending) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _isApplying
                ? null
                : () => _confirmApply(team, slot),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: _kSage.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _kSage.withValues(alpha: 0.4), width: 1),
              ),
              child: Text(
                'Postuler',
                textAlign: TextAlign.center,
                style: GoogleFonts.syne(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _kSage,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _confirmApply(PublicMatchTeamInfo team, PublicMatchTeamSlot slot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        decoration: const BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: _kBorder2,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _kSageDim,
                shape: BoxShape.circle,
                border: Border.all(
                    color: _kSage.withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Icon(Icons.sports_soccer, color: _kSage, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              'Postuler pour ce match ?',
              style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kWhite),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu vas postuler pour le poste de ${slot.position.displayName}\ndans l\'équipe ${team.name}.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted2),
            ),
            const SizedBox(height: 6),
            Text(
              'Le capitaine devra accepter ta candidature.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: _kMuted2.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: _kCard2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kBorder2),
                      ),
                      child: Text(
                        'Annuler',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.syne(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kMuted2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      setState(() => _isApplying = true);
                      await widget.onApply(team.id, slot.slotIndex);
                      if (mounted) setState(() => _isApplying = false);
                      if (mounted) Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: _kSage,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Confirmer',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.syne(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
  }
}

extension _PositionExt on PlayerPosition {
  String get shortDisplayName {
    switch (this) {
      case PlayerPosition.goalkeeper:
        return 'Gard.';
      case PlayerPosition.defender:
        return 'Déf.';
      case PlayerPosition.midfielder:
        return 'Mil.';
      case PlayerPosition.forward:
        return 'Att.';
      case PlayerPosition.substitute:
        return 'Rem.';
    }
  }
}
