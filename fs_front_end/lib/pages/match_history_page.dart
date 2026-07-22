import 'package:flutter/material.dart';
import 'package:five_star_5v5/theme/app_typography.dart';
import '../services/teams_service.dart';
import '../theme/app_colors.dart';

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
      final myScore = iChallenger ? m.challengerScore : m.challengedScore;
      final oppScore = iChallenger ? m.challengedScore : m.challengerScore;
      if (myScore != null && oppScore != null) {
        if (myScore > oppScore) {
          wins++;
        } else if (myScore < oppScore) {
          losses++;
        } else {
          draws++;
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Historique des matchs',
          style: AppTypography.display(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border2),
        ),
      ),
      body: Column(
        children: [
          // Barre de stats
          Container(
            color: AppColors.card,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statChip('${matches.length}', 'Matchs', AppColors.muted2),
                _divider(),
                _statChip('$wins', 'Victoires', AppColors.sage),
                _divider(),
                _statChip('$draws', 'Nuls', AppColors.amber),
                _divider(),
                _statChip('$losses', 'Défaites', AppColors.rose),
              ],
            ),
          ),
          const SizedBox(height: 1),
          // Liste
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: matches.length,
              itemBuilder: (_, i) =>
                  _MatchCard(match: matches[i], myTeamIds: myTeamIds),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.display(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.body(fontSize: 11, color: AppColors.muted2)),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: AppColors.border2);
}

class _MatchCard extends StatelessWidget {
  final MatchChallenge match;
  final Set<int> myTeamIds;

  const _MatchCard({required this.match, required this.myTeamIds});

  @override
  Widget build(BuildContext context) {
    final m = match;
    final iChallenger = myTeamIds.contains(m.challengerTeamId);
    final myTeamName = iChallenger
        ? m.challengerTeamName
        : m.challengedTeamName;
    final oppName = iChallenger ? m.challengedTeamName : m.challengerTeamName;
    final myScore = iChallenger ? m.challengerScore : m.challengedScore;
    final oppScore = iChallenger ? m.challengedScore : m.challengerScore;

    String resultLabel = '';
    Color resultColor = AppColors.muted2;
    if (myScore != null && oppScore != null) {
      if (myScore > oppScore) {
        resultLabel = 'Victoire';
        resultColor = AppColors.sage;
      } else if (myScore < oppScore) {
        resultLabel = 'Défaite';
        resultColor = AppColors.rose;
      } else {
        resultLabel = 'Nul';
        resultColor = AppColors.amber;
      }
    }

    final date = m.matchPlayedAt ?? m.proposedDate ?? m.createdAt;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: resultLabel.isEmpty
              ? AppColors.border2
              : resultColor.withValues(alpha: 0.25),
        ),
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
                      Text(
                        myTeamName,
                        style: AppTypography.display(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'vs $oppName',
                        style: AppTypography.body(fontSize: 12, color: AppColors.muted2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                        style: AppTypography.display(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      )
                    else
                      Text(
                        '– – –',
                        style: AppTypography.display(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted2,
                        ),
                      ),
                    if (resultLabel.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: resultColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          resultLabel,
                          style: AppTypography.display(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: resultColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Méta : date + lieu
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: AppColors.muted2,
                ),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: AppTypography.body(fontSize: 11, color: AppColors.muted2),
                ),
                if (m.proposedLocation != null) ...[
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: AppColors.muted2,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      m.proposedLocation!,
                      style: AppTypography.body(fontSize: 11, color: AppColors.muted2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
