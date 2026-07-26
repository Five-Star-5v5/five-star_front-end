import 'package:flutter/material.dart';
import 'package:five_star_5v5/theme/app_typography.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/friends_provider.dart';
import '../services/auth_service.dart';
import '../services/friends_service.dart';
import '../services/teams_service.dart';
import 'all_comments_page.dart';

import '../theme/app_colors.dart';

/// Page pour afficher le profil d'un autre utilisateur
class UserProfilePage extends StatefulWidget {
  final UserModel? user;
  final UserBasicInfo? userBasicInfo;
  final bool showAddFriendButton;

  const UserProfilePage({
    super.key,
    this.user,
    this.userBasicInfo,
    this.showAddFriendButton = false,
  }) : assert(user != null || userBasicInfo != null);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  UserModel? _fullUser;
  bool _isLoading = true;
  late Future<List<PlayerCommentData>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    final userId = widget.user?.id ?? widget.userBasicInfo!.id;
    _commentsFuture = TeamsService.instance.getPlayerComments(userId);
    _loadFullUserProfile();
  }

  Future<void> _loadFullUserProfile() async {
    if (widget.user != null) {
      setState(() {
        _fullUser = widget.user;
        _isLoading = false;
      });
      return;
    }

    if (widget.userBasicInfo != null) {
      try {
        final userData = await AuthService.instance.getUserProfile(
          widget.userBasicInfo!.id,
        );
        if (userData != null && mounted) {
          setState(() {
            _fullUser = UserModel.fromJson(userData);
            _isLoading = false;
          });
        } else if (mounted) {
          setState(() {
            _fullUser = UserModel(
              id: widget.userBasicInfo!.id,
              username: widget.userBasicInfo!.username,
              codeId: '',
              avatarUrl: widget.userBasicInfo!.avatarUrl,
              preferredPosition: widget.userBasicInfo!.preferredPosition,
              rating: widget.userBasicInfo!.rating,
            );
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _fullUser = UserModel(
              id: widget.userBasicInfo!.id,
              username: widget.userBasicInfo!.username,
              codeId: '',
              avatarUrl: widget.userBasicInfo!.avatarUrl,
              preferredPosition: widget.userBasicInfo!.preferredPosition,
              rating: widget.userBasicInfo!.rating,
            );
            _isLoading = false;
          });
        }
      }
    }
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(String title) {
    return AppBar(
      backgroundColor: AppColors.card,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: AppColors.muted2),
      title: Text(
        title,
        style: AppTypography.display(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
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
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border2),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: _buildAppBar('Profil'),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.amber),
        ),
      );
    }

    final user = _fullUser!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(user.username),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(user),
            const SizedBox(height: 14),
            _buildStatsBar(user),
            const SizedBox(height: 20),
            _buildBadges(user),
            const SizedBox(height: 20),
            _buildHistory(),
            const SizedBox(height: 20),
            _buildComments(),
            if (widget.showAddFriendButton) ...[
              const SizedBox(height: 28),
              Center(child: _buildFriendActionButton(user)),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────────────

  Widget _buildHero(UserModel user) {
    final initial = user.username.isNotEmpty
        ? user.username[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          // Avatar
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.amberSoft, AppColors.amberD],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.amber.withValues(alpha: 0.12),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        user.avatarUrl!,
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                      ),
                    )
                  : Center(
                      child: Text(
                        initial,
                        style: AppTypography.display(
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
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
          // Handle sub-info
          Center(
            child: Text(
              '@${user.username.toLowerCase()}${user.preferredPosition != null ? ' · ${user.preferredPosition}' : ''}',
              style: AppTypography.body(fontSize: 11, color: AppColors.muted2),
            ),
          ),
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
                style: AppTypography.body(
                  fontSize: 12,
                  color: AppColors.muted2,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(String label, {bool amber = false, bool sage = false}) {
    final color = amber
        ? AppColors.amber
        : sage
        ? AppColors.sage
        : AppColors.muted2;
    final bg = amber
        ? AppColors.amberDim
        : sage
        ? AppColors.sageDim
        : const Color(0x0DFFFFFF);
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

  // ── Stats bar ──────────────────────────────────────────────────────────────

  Widget _buildStatsBar(UserModel user) {
    final stats = [
      _StatItem('MATCHS', '${user.matchesPlayed}'),
      _StatItem('VICTOIRES', '${user.matchesWon}'),
      _StatItem('WIN RATE', '${user.winRate.toStringAsFixed(0)}%'),
      _StatItem(
        'NOTE',
        user.rating != null ? '${user.rating!.toStringAsFixed(1)}★' : '—',
      ),
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
                right: isLast
                    ? const BorderSide(color: AppColors.border2)
                    : BorderSide.none,
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
  }

  // ── Badges ─────────────────────────────────────────────────────────────────

  Widget _buildBadges(UserModel user) {
    final badges = _computeBadges(user);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('BADGES'),
        if (badges.isEmpty)
          _emptyState(
            Icons.military_tech_outlined,
            'Pas encore de badges',
            'Ce joueur a besoin de plus de matchs pour en gagner',
          )
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
    if (user.matchesPlayed >= 20)
      list.add(_Badge('MVP', const Color(0xFFFFD06E), const Color(0x1AFFD06E)));
    if (user.matchesPlayed >= 10)
      list.add(_Badge('Régulier ⚡', AppColors.amber, AppColors.amberDim));
    if (user.matchesWon >= 5)
      list.add(
        _Badge('Série 🔥', const Color(0xFFFFD06E), const Color(0x1AFFD06E)),
      );
    if (user.matchesPlayed >= 5)
      list.add(_Badge('Actif', AppColors.amber, AppColors.amberDim));
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

  // ── History ────────────────────────────────────────────────────────────────

  Widget _buildHistory() {
    // Réutiliser les commentaires pour afficher les matchs
    return FutureBuilder<List<PlayerCommentData>>(
      future: _commentsFuture,
      builder: (ctx, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final comments = snap.data ?? [];

        // Grouper par challenge_id pour avoir un match unique par match joué
        final matchesMap = <int, PlayerCommentData>{};
        for (final comment in comments) {
          if (!matchesMap.containsKey(comment.challengeId)) {
            matchesMap[comment.challengeId] = comment;
          }
        }

        final uniqueMatches = matchesMap.values.toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('HISTORIQUE'),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: AppColors.amber,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (uniqueMatches.isEmpty)
              _emptyState(
                Icons.sports_soccer_outlined,
                'Aucun match joué',
                'L\'historique apparaîtra ici',
              )
            else
              Column(
                children: uniqueMatches
                    .map((c) => _buildHistoryCard(c))
                    .toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryCard(PlayerCommentData comment) {
    final dateStr =
        '${comment.createdAt.day.toString().padLeft(2, '0')}/${comment.createdAt.month.toString().padLeft(2, '0')}/${comment.createdAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Match #${comment.challengeId}',
                  style: AppTypography.display(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
              Text(
                dateStr,
                style: AppTypography.body(
                  fontSize: 10,
                  color: AppColors.muted2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                comment.isAbsent ? Icons.close_rounded : Icons.check_rounded,
                size: 14,
                color: comment.isAbsent ? AppColors.rose : AppColors.sage,
              ),
              const SizedBox(width: 6),
              Text(
                comment.isAbsent ? 'Absent' : 'Présent',
                style: AppTypography.display(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: comment.isAbsent ? AppColors.rose : AppColors.sage,
                ),
              ),
            ],
          ),
          if (comment.content != null && comment.content!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment.content!,
              style: AppTypography.body(fontSize: 10, color: AppColors.muted2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ── Comments ───────────────────────────────────────────────────────────────

  Widget _buildComments() {
    final username = _fullUser?.username ?? '';
    return FutureBuilder<List<PlayerCommentData>>(
      future: _commentsFuture,
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
                  Expanded(child: _sectionLabel('COMMENTAIRES REÇUS')),
                  if (!loading && comments.isNotEmpty)
                    GestureDetector(
                      onTap: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => AllCommentsPage(
                            username: username,
                            comments: comments,
                          ),
                        ),
                      ),
                      child: Text(
                        'Voir tout →',
                        style: AppTypography.display(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amber,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: AppColors.amber,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (comments.isEmpty)
              _emptyState(
                Icons.chat_bubble_outline,
                'Aucun commentaire',
                'Les avis laissés après les matchs apparaîtront ici',
              )
            else
              Column(
                children: comments
                    .take(3)
                    .map((c) => _buildCommentCard(c))
                    .toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCommentCard(PlayerCommentData c) {
    final dateStr =
        '${c.createdAt.day.toString().padLeft(2, '0')}/${c.createdAt.month.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: c.isAbsent
              ? AppColors.rose.withValues(alpha: 0.3)
              : AppColors.border2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.border2,
              shape: BoxShape.circle,
              image: c.authorAvatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(c.authorAvatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: c.authorAvatarUrl == null
                ? const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.muted2,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      c.authorUsername ?? 'Joueur',
                      style: AppTypography.display(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const Spacer(),
                    if (c.isAbsent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.rose.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Absent',
                          style: AppTypography.display(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.rose,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: AppTypography.body(
                        fontSize: 10,
                        color: AppColors.muted2,
                      ),
                    ),
                  ],
                ),
                if (c.content != null && c.content!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    c.content!,
                    style: AppTypography.body(
                      fontSize: 11,
                      color: AppColors.muted2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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
          Text(
            title,
            style: AppTypography.display(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: AppTypography.body(color: AppColors.muted2, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Friend action ──────────────────────────────────────────────────────────

  Widget _buildFriendActionButton(UserModel user) {
    return Consumer<FriendsProvider>(
      builder: (context, friendsProvider, _) {
        final isAlreadyFriend = friendsProvider.friends.any(
          (f) => f.user.id == user.id,
        );
        final hasPendingSent = friendsProvider.pendingSent.any(
          (r) => r.user.id == user.id,
        );
        final hasPendingReceived = friendsProvider.pendingReceived.any(
          (r) => r.fromUser.id == user.id,
        );

        if (isAlreadyFriend) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.sageDim,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.sage.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, color: AppColors.sage, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Déjà ami',
                  style: AppTypography.display(
                    color: AppColors.sage,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }

        if (hasPendingSent) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.amberDim,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.hourglass_empty,
                  color: AppColors.amber,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Demande envoyée',
                  style: AppTypography.display(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }

        if (hasPendingReceived) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () async {
                  final request = friendsProvider.pendingReceived.firstWhere(
                    (r) => r.fromUser.id == user.id,
                  );
                  await friendsProvider.rejectFriendRequest(
                    request.friendshipId,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.roseDim,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.rose),
                  ),
                  child: Text(
                    'Refuser',
                    style: AppTypography.display(
                      color: AppColors.rose,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  final request = friendsProvider.pendingReceived.firstWhere(
                    (r) => r.fromUser.id == user.id,
                  );
                  final messenger = ScaffoldMessenger.of(context);
                  await friendsProvider.acceptFriendRequest(
                    request.friendshipId,
                  );
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Demande acceptée !'),
                      backgroundColor: AppColors.sage,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [AppColors.amberSoft, AppColors.amberD],
                    ),
                  ),
                  child: Text(
                    'Accepter',
                    style: AppTypography.display(
                      color: AppColors.night,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return GestureDetector(
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            await friendsProvider.sendFriendRequest(user.id);
            messenger.showSnackBar(
              SnackBar(
                content: Text('Demande envoyée à ${user.username}'),
                backgroundColor: AppColors.sage,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [AppColors.amberSoft, AppColors.amberD],
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_add, color: AppColors.night, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Ajouter en ami',
                  style: AppTypography.display(
                    color: AppColors.night,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Data helpers ───────────────────────────────────────────────────────────────

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
