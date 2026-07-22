import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:five_star_5v5/theme/app_typography.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/teams_provider.dart';
import '../models/user_model.dart';
import '../services/teams_service.dart';
import '../auth/login.dart';
import 'settings_page.dart';
import 'match_history_page.dart';
import 'all_comments_page.dart';

import '../theme/app_colors.dart';
import '../widgets/kobeta_logo.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) context.read<AuthProvider>().refreshCurrentUser();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<AuthProvider>().refreshCurrentUser();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final UserModel? user = authProvider.currentUser;

        if (user == null) {
          return const Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(child: CircularProgressIndicator(color: AppColors.amber)),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: _buildAppBar(context, authProvider),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(user, context),
                const SizedBox(height: 14),
                _buildStatsBar(user),
                const SizedBox(height: 20),
                _buildBadges(user),
                const SizedBox(height: 20),
                _buildHistory(context),
                const SizedBox(height: 20),
                _buildComments(user.id, user.username),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context, AuthProvider authProvider) {
    return AppBar(
      backgroundColor: AppColors.card,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
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
      title: Row(
        children: [
          const KobetaLogo(size: 28),
          const SizedBox(width: 9),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1),
              children: [
                TextSpan(text: 'Ko', style: TextStyle(color: AppColors.white)),
                TextSpan(text: 'beta', style: TextStyle(color: AppColors.amber)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Logout
        GestureDetector(
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.border2),
                ),
                title: Text(
                  'Déconnexion',
                  style: AppTypography.display(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: Text(
                  'Tu veux vraiment te déconnecter ?',
                  style: AppTypography.body(color: AppColors.muted2),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(
                      'Annuler',
                      style: AppTypography.body(color: AppColors.muted2),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      'Déconnecter',
                      style: AppTypography.body(
                        color: AppColors.rose,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
            if (confirmed != true) return;
            if (!context.mounted) return;
            final navigator = Navigator.of(context);
            await authProvider.logout();
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          },
          child: Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.card2,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border2),
            ),
            child: const Icon(Icons.logout, color: AppColors.muted2, size: 16),
          ),
        ),
        // Settings
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SettingsPage(authProvider: authProvider)),
          ),
          child: Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.card2,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border2),
            ),
            child: const Icon(Icons.settings_outlined, color: AppColors.muted2, size: 16),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border2),
      ),
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────────────

  Widget _buildHero(UserModel user, BuildContext context) {
    final initial = user.username.isNotEmpty ? user.username[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          // Avatar
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.amberSoft, AppColors.amberD],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.amber.withValues(alpha: 0.15), blurRadius: 100, spreadRadius: 30),
                  BoxShadow(color: AppColors.amber.withValues(alpha: 0.07), blurRadius: 220, spreadRadius: 70),
                ],
              ),
              child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                  ? ClipOval(child: Image.network(user.avatarUrl!, fit: BoxFit.cover))
                  : Center(
                      child: Text(
                        initial,
                        style: AppTypography.display(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          color: AppColors.night,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Username
          Center(
            child: Text(
              user.username.toUpperCase(),
              style: AppTypography.display(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: 0.6,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(height: 3),
          // Handle / sub-info
          Center(
            child: Text(
              '@${user.username.toLowerCase()}${user.preferredPosition != null ? ' · ${user.preferredPosition}' : ''}',
              style: AppTypography.body(fontSize: 11, color: AppColors.muted2),
            ),
          ),
          if (user.codeId.isNotEmpty) ...[
            const SizedBox(height: 4),
            Center(
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: user.codeId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Code copié'),
                      duration: Duration(seconds: 1),
                      backgroundColor: Color(0xFF1E2029),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.card2,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppColors.border2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#${user.codeId}',
                        style: AppTypography.body(
                          fontSize: 10,
                          color: AppColors.muted2,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy_outlined, size: 10, color: AppColors.muted2),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          // Pills
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user.preferredPosition != null)
                  _pill(user.preferredPosition!, amber: true),
                if (user.preferredPosition != null) const SizedBox(width: 6),
                if (user.rating != null)
                  _pill('${user.rating!.toStringAsFixed(1)} ★', sage: true),
                if (user.rating != null) ...[
                  const SizedBox(width: 6),
                  _levelPill(user.rating!),
                ],
              ],
            ),
          ),
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                user.bio!,
                textAlign: TextAlign.center,
                style: AppTypography.body(fontSize: 12, color: AppColors.muted2, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(String label, {bool amber = false, bool sage = false}) {
    final color = amber ? AppColors.amber : sage ? AppColors.sage : AppColors.muted2;
    final bg = amber ? AppColors.amberDim : sage ? AppColors.sageDim : const Color(0x0DFFFFFF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppTypography.display(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }

  Widget _levelPill(double rating) {
    final String label;
    final Color color;
    if (rating >= 8.0) {
      label = 'EXPERT';
      color = AppColors.amber;
    } else if (rating >= 6.0) {
      label = 'CONFIRMÉ';
      color = AppColors.sage;
    } else if (rating >= 4.0) {
      label = 'INTERMÉDIAIRE';
      color = const Color(0xFF7B6CF6);
    } else {
      label = 'DÉBUTANT';
      color = const Color(0xFF4A9EFF);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppTypography.display(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }

  // ── Stats bar ─────────────────────────────────────────────────────────────

  Widget _buildStatsBar(UserModel user) {
    return Consumer<FriendsProvider>(
      builder: (context, friends, _) {
        final stats = [
          _StatItem('MATCHS', '${user.matchesPlayed}'),
          _StatItem('VICTOIRES', '${user.matchesWon}'),
          _StatItem('NOTE /10', user.rating != null ? user.rating!.toStringAsFixed(1) : '--'),
          _StatItem('AMIS', '${friends.friendsCount}'),
        ];

        return Row(
          children: List.generate(stats.length, (i) {
            final isFirst = i == 0;
            final isLast = i == stats.length - 1;
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border(
                    top: const BorderSide(color: AppColors.border2),
                    bottom: const BorderSide(color: AppColors.border2),
                    left: const BorderSide(color: AppColors.border2),
                    right: isLast ? const BorderSide(color: AppColors.border2) : BorderSide.none,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: isFirst ? const Radius.circular(12) : Radius.zero,
                    bottomLeft: isFirst ? const Radius.circular(12) : Radius.zero,
                    topRight: isLast ? const Radius.circular(12) : Radius.zero,
                    bottomRight: isLast ? const Radius.circular(12) : Radius.zero,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      stats[i].value,
                      style: AppTypography.display(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.amber,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stats[i].label,
                      style: AppTypography.display(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: AppColors.muted2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  // ── Badges ────────────────────────────────────────────────────────────────

  Widget _buildBadges(UserModel user) {
    final badges = _computeBadges(user);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('BADGES'),
        if (badges.isEmpty)
          _emptyState(Icons.military_tech_outlined, 'Pas encore de badges', 'Joue plus de matchs pour en gagner')
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: badges.map((b) => _badgeChip(b)).toList(),
          ),
      ],
    );
  }

  List<_Badge> _computeBadges(UserModel user) {
    final list = <_Badge>[];
    if (user.matchesPlayed >= 20) list.add(_Badge('MVP', const Color(0xFFFFD06E), const Color(0x1AFFD06E)));
    if (user.matchesPlayed >= 10) list.add(_Badge('Régulier ⚡', AppColors.amber, AppColors.amberDim));
    if (user.matchesWon >= 5)     list.add(_Badge('Série 🔥', const Color(0xFFFFD06E), const Color(0x1AFFD06E)));
    if (user.matchesPlayed >= 5)  list.add(_Badge('Actif', AppColors.amber, AppColors.amberDim));
    return list;
  }

  Widget _badgeChip(_Badge b) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: b.bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: b.color.withValues(alpha: 0.25)),
      ),
      child: Text(
        b.label,
        style: AppTypography.display(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: b.color,
        ),
      ),
    );
  }

  // ── History ───────────────────────────────────────────────────────────────

  Widget _buildHistory(BuildContext context) => const _MatchHistorySection();

  // ── Comments ──────────────────────────────────────────────────────────────

  Widget _buildComments(int userId, String username) {
    return _CommentsSection(userId: userId, username: username);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: AppTypography.display(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: AppColors.muted2,
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border2),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.muted2, size: 26),
          const SizedBox(height: 8),
          Text(title, style: AppTypography.display(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(subtitle, style: AppTypography.body(color: AppColors.muted2, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Data helpers ──────────────────────────────────────────────────────────────

class _StatItem {
  final String label;
  final String value;
  const _StatItem(this.label, this.value);
}

class _Badge {
  final String label;
  final Color color;
  final Color bg;
  const _Badge(this.label, this.color, this.bg);
}

// ── Match history section ─────────────────────────────────────────────────

class _MatchHistorySection extends StatefulWidget {
  const _MatchHistorySection();
  @override
  State<_MatchHistorySection> createState() => _MatchHistorySectionState();
}

class _MatchHistorySectionState extends State<_MatchHistorySection> {
  late Future<List<MatchChallenge>> _future;
  List<int> _loadedTeamIds = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final teams = context.read<TeamsProvider>().allTeams;
    final teamIds = (teams.map((t) => t.id).toList()..sort());
    // Ne recharge que si la liste d'équipes a réellement changé
    if (_listEquals(teamIds, _loadedTeamIds)) return;
    _loadedTeamIds = teamIds;
    _future = Future.wait(
      teams.map((t) => TeamsService.instance.getTeamMatches(t.id, status: 'completed')),
    ).then((lists) {
      final seen = <int>{};
      final result = <MatchChallenge>[];
      for (final list in lists) {
        for (final m in list) {
          if (seen.add(m.id)) result.add(m);
        }
      }
      result.sort((a, b) => (b.matchPlayedAt ?? b.createdAt).compareTo(a.matchPlayedAt ?? a.createdAt));
      return result;
    });
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final teams = context.watch<TeamsProvider>().allTeams;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<List<MatchChallenge>>(
          future: _future,
          builder: (ctx, snap) {
            final matches = snap.data ?? [];
            final loading = snap.connectionState == ConnectionState.waiting;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'HISTORIQUE',
                          style: AppTypography.display(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted2, letterSpacing: 1.1),
                        ),
                      ),
                      if (!loading && matches.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            final myTeamIds = teams.map((t) => t.id).toSet();
                            Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) => MatchHistoryPage(matches: matches, myTeamIds: myTeamIds),
                              ),
                            );
                          },
                          child: Text(
                            'Voir tout →',
                            style: AppTypography.display(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.amber),
                          ),
                        ),
                    ],
                  ),
                ),
                // Content
                if (loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2),
                    ),
                  )
                else if (matches.isEmpty)
                  Column(
                    children: [
                      const SizedBox(height: 8),
                      Icon(Icons.sports_soccer_outlined, size: 32, color: AppColors.muted2.withValues(alpha: 0.4)),
                      const SizedBox(height: 8),
                      Text('Aucun match joué', style: AppTypography.display(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted2)),
                      const SizedBox(height: 4),
                      Text("Ton historique apparaîtra ici", style: AppTypography.body(fontSize: 11, color: AppColors.muted2.withValues(alpha: 0.5))),
                      const SizedBox(height: 16),
                    ],
                  )
                else
                  Column(
                    children: matches.take(3).map((m) {
                      final myTeamIds = teams.map((t) => t.id).toSet();
                      return _buildCard(m, myTeamIds);
                    }).toList(),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCard(MatchChallenge m, Set<int> myTeamIds) {
    final iChallenger = myTeamIds.contains(m.challengerTeamId);
    final myTeamName  = iChallenger ? m.challengerTeamName : m.challengedTeamName;
    final oppName     = iChallenger ? m.challengedTeamName : m.challengerTeamName;
    final myScore     = iChallenger ? m.challengerScore : m.challengedScore;
    final oppScore    = iChallenger ? m.challengedScore : m.challengerScore;

    String resultLabel = '';
    Color resultColor  = AppColors.muted2;
    if (myScore != null && oppScore != null) {
      if (myScore > oppScore)      { resultLabel = 'Victoire'; resultColor = AppColors.sage; }
      else if (myScore < oppScore) { resultLabel = 'Défaite';  resultColor = const Color(0xFFD4607A); }
      else                         { resultLabel = 'Nul';      resultColor = AppColors.amber; }
    }

    final date = m.matchPlayedAt ?? m.proposedDate ?? m.createdAt;
    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$myTeamName vs $oppName',
                  style: AppTypography.display(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(dateStr, style: AppTypography.body(fontSize: 11, color: AppColors.muted2)),
                    if (m.proposedLocation != null) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.location_on_outlined, size: 11, color: Color(0x9EF0F2F5)),
                      Flexible(
                        child: Text(m.proposedLocation!, style: AppTypography.body(fontSize: 11, color: AppColors.muted2), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
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
                  style: AppTypography.display(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.white),
                ),
              if (resultLabel.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: resultColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(resultLabel, style: AppTypography.display(fontSize: 10, fontWeight: FontWeight.w700, color: resultColor)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section commentaires reçus ────────────────────────────────────────────────

class _CommentsSection extends StatefulWidget {
  final int userId;
  final String username;
  const _CommentsSection({required this.userId, required this.username});

  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  late Future<List<PlayerCommentData>> _future;

  @override
  void initState() {
    super.initState();
    _future = TeamsService.instance.getPlayerComments(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<List<PlayerCommentData>>(
          future: _future,
          builder: (ctx, snap) {
            final loading = snap.connectionState == ConnectionState.waiting;
            final comments = snap.data ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'COMMENTAIRES REÇUS',
                          style: AppTypography.display(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: AppColors.muted2),
                        ),
                      ),
                      if (!loading && comments.isNotEmpty)
                        GestureDetector(
                          onTap: () => Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => AllCommentsPage(username: widget.username, comments: comments),
                            ),
                          ),
                          child: Text(
                            'Voir tout →',
                            style: AppTypography.display(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.amber),
                          ),
                        ),
                    ],
                  ),
                ),
                if (loading)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2)))
                else if (comments.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 28, color: AppColors.muted2.withValues(alpha: 0.4)),
                        const SizedBox(height: 8),
                        Text('Aucun commentaire', style: AppTypography.display(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted2)),
                        const SizedBox(height: 4),
                        Text('Les avis laissés après vos matchs apparaîtront ici', style: AppTypography.body(fontSize: 11, color: AppColors.muted2.withValues(alpha: 0.6)), textAlign: TextAlign.center),
                      ],
                    ),
                  )
                else
                  Column(
                    children: comments.take(3).map((c) => _buildCommentCard(c)).toList(),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommentCard(PlayerCommentData c) {
    final dateStr = '${c.createdAt.day.toString().padLeft(2, '0')}/${c.createdAt.month.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.isAbsent ? const Color(0xFFD4607A).withValues(alpha: 0.3) : const Color(0x21FFFFFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0x21FFFFFF),
              shape: BoxShape.circle,
              image: c.authorAvatarUrl != null
                  ? DecorationImage(image: NetworkImage(c.authorAvatarUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: c.authorAvatarUrl == null ? const Icon(Icons.person_outline, size: 16, color: AppColors.muted2) : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(c.authorUsername ?? 'Joueur', style: AppTypography.display(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFF0F2F5))),
                    const Spacer(),
                    if (c.isAbsent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4607A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Absent', style: AppTypography.display(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFFD4607A))),
                      ),
                    const SizedBox(width: 6),
                    Text(dateStr, style: AppTypography.body(fontSize: 10, color: AppColors.muted2)),
                  ],
                ),
                if (c.content != null && c.content!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(c.content!, style: AppTypography.body(fontSize: 11, color: AppColors.muted2)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
