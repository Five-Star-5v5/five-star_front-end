import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/teams_service.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _hBg     = Color(0xFF0A0C10);
const _hCard   = Color(0xFF181A21);
const _hBorder = Color(0x21FFFFFF);
const _hAmber  = Color(0xFFFF7F2A);
const _hSage   = Color(0xFF4CAF82);
const _hRose   = Color(0xFFD4607A);
const _hWhite  = Color(0xFFF0F2F5);
const _hMuted  = Color(0x9EF0F2F5);

class MatchHistoryPage extends StatelessWidget {
  final List<MatchChallenge> matches;
  final Set<int> myTeamIds;

  const MatchHistoryPage({
    super.key,
    required this.matches,
    required this.myTeamIds,
  });

  @override
  Widget build(BuildContext context) {
    // Stats rapides
    int wins = 0, losses = 0, draws = 0;
    for (final m in matches) {
      final iChallenger = myTeamIds.contains(m.challengerTeamId);
      final myScore  = iChallenger ? m.challengerScore : m.challengedScore;
      final oppScore = iChallenger ? m.challengedScore : m.challengerScore;
      if (myScore != null && oppScore != null) {
        if (myScore > oppScore) wins++;
        else if (myScore < oppScore) losses++;
        else draws++;
      }
    }

    return Scaffold(
      backgroundColor: _hBg,
      appBar: AppBar(
        backgroundColor: _hCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _hWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Historique des matchs',
          style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: _hWhite),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _hBorder),
        ),
      ),
      body: Column(
        children: [
          // Barre de stats
          Container(
            color: _hCard,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statChip('${matches.length}', 'Matchs', _hMuted),
                _divider(),
                _statChip('$wins', 'Victoires', _hSage),
                _divider(),
                _statChip('$draws', 'Nuls', _hAmber),
                _divider(),
                _statChip('$losses', 'Défaites', _hRose),
              ],
            ),
          ),
          const SizedBox(height: 1),
          // Liste
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: matches.length,
              itemBuilder: (_, i) => _MatchCard(match: matches[i], myTeamIds: myTeamIds),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: _hMuted)),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: _hBorder);
}

class _MatchCard extends StatelessWidget {
  final MatchChallenge match;
  final Set<int> myTeamIds;

  const _MatchCard({required this.match, required this.myTeamIds});

  @override
  Widget build(BuildContext context) {
    final m = match;
    final iChallenger = myTeamIds.contains(m.challengerTeamId);
    final myTeamName  = iChallenger ? m.challengerTeamName  : m.challengedTeamName;
    final oppName     = iChallenger ? m.challengedTeamName  : m.challengerTeamName;
    final myScore     = iChallenger ? m.challengerScore     : m.challengedScore;
    final oppScore    = iChallenger ? m.challengedScore     : m.challengerScore;

    String resultLabel = '';
    Color  resultColor = _hMuted;
    if (myScore != null && oppScore != null) {
      if (myScore > oppScore)      { resultLabel = 'Victoire'; resultColor = _hSage; }
      else if (myScore < oppScore) { resultLabel = 'Défaite';  resultColor = _hRose; }
      else                         { resultLabel = 'Nul';      resultColor = _hAmber; }
    }

    final date    = m.matchPlayedAt ?? m.proposedDate ?? m.createdAt;
    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _hCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: resultLabel.isEmpty ? _hBorder : resultColor.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne principale : équipes + score
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(myTeamName, style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: _hWhite), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('vs $oppName', style: GoogleFonts.dmSans(fontSize: 12, color: _hMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (myScore != null && oppScore != null)
                      Text(
                        '$myScore – $oppScore',
                        style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w800, color: _hWhite),
                      )
                    else
                      Text('– – –', style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w600, color: _hMuted)),
                    if (resultLabel.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: resultColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(resultLabel, style: GoogleFonts.syne(fontSize: 11, fontWeight: FontWeight.w700, color: resultColor)),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Méta : date + lieu
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 12, color: _hMuted),
                const SizedBox(width: 4),
                Text(dateStr, style: GoogleFonts.dmSans(fontSize: 11, color: _hMuted)),
                if (m.proposedLocation != null) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.location_on_outlined, size: 12, color: _hMuted),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(m.proposedLocation!, style: GoogleFonts.dmSans(fontSize: 11, color: _hMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
