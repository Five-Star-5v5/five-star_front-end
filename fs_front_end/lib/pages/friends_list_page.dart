import 'package:flutter/material.dart';
import 'package:five_star_5v5/theme/app_typography.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../providers/messages_provider.dart';
import '../services/friends_service.dart';
import 'chat_page.dart';
import 'user_profile_page.dart';

import '../theme/app_colors.dart';
import '../widgets/kobeta_logo.dart';

class FriendsListPage extends StatefulWidget {
  const FriendsListPage({super.key});

  @override
  State<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends State<FriendsListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _filterText = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() => _filterText = _searchController.text.toLowerCase());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendsProvider>().loadFriends();
      context.read<MessagesProvider>().loadConversations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAddFriendSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<FriendsProvider>(),
        child: const _AddFriendSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAmisTab(),
                _buildRecuesTab(),
                _buildEnvoyeesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1,
              ),
              children: [
                TextSpan(
                  text: 'Ko',
                  style: TextStyle(color: AppColors.white),
                ),
                TextSpan(
                  text: 'beta',
                  style: TextStyle(color: AppColors.amber),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: _openAddFriendSheet,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.amberSoft, AppColors.amberD]),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '+ AJOUTER',
              style: AppTypography.display(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.5,
                color: AppColors.night,
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border2),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.card2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border2),
        ),
        child: TextField(
          controller: _searchController,
          style: AppTypography.body(color: AppColors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Rechercher un ami...',
            hintStyle: AppTypography.body(color: AppColors.muted2, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: AppColors.muted2, size: 16),
            suffixIcon: _filterText.isNotEmpty
                ? GestureDetector(
                    onTap: () => _searchController.clear(),
                    child: const Icon(Icons.close, color: AppColors.muted2, size: 16),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Consumer<FriendsProvider>(
        builder: (context, provider, _) {
          return TabBar(
            controller: _tabController,
            indicatorColor: Colors.transparent,
            dividerColor: Colors.transparent,
            padding: EdgeInsets.zero,
            labelPadding: EdgeInsets.zero,
            tabs: [
              _buildTab('AMIS', provider.friendsCount, 0),
              _buildTab(
                'REÇUES',
                provider.pendingReceived.length,
                1,
                isAlert: true,
              ),
              _buildTab('ENVOYÉES', provider.pendingSent.length, 2),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab(String label, int count, int index, {bool isAlert = false}) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final selected = _tabController.index == index;
        return GestureDetector(
          onTap: () => _tabController.animateTo(index),
          child: Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.amber : AppColors.card2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? AppColors.amber : AppColors.border2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.display(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: selected ? AppColors.night : AppColors.muted2,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.night.withValues(alpha: 0.25)
                          : (isAlert ? AppColors.amberDim : AppColors.border2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$count',
                      style: AppTypography.display(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? AppColors.night
                            : (isAlert ? AppColors.amber : AppColors.muted2),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Tab AMIS ──────────────────────────────────────────────────────────────

  Widget _buildAmisTab() {
    return Consumer<FriendsProvider>(
      builder: (context, provider, _) {
        if (provider.state == FriendsLoadingState.loading &&
            provider.friends.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.amber));
        }

        if (provider.state == FriendsLoadingState.error) {
          return _buildError(
            provider.errorMessage,
            () => provider.loadFriends(),
          );
        }

        final filtered = _filterText.isEmpty
            ? provider.friends
            : provider.friends
                  .where(
                    (f) => f.user.username.toLowerCase().contains(_filterText),
                  )
                  .toList();

        if (provider.friends.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline,
            message: 'Aucun ami pour le moment',
            subtitle: 'Appuie sur + AJOUTER pour trouver des joueurs',
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadFriends(),
          color: AppColors.amber,
          backgroundColor: AppColors.card,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              if (filtered.isEmpty && _filterText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Aucun ami correspondant',
                      style: AppTypography.body(color: AppColors.muted2, fontSize: 13),
                    ),
                  ),
                )
              else
                ...filtered.map((friend) => _buildFriendCard(friend)),
              // Requests preview at bottom of Amis tab
              if (provider.pendingReceived.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildRequestsPreview(provider),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFriendCard(FriendWithInfo friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border2),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.amberDim,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: friend.user.avatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          friend.user.avatarUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          friend.user.username.isNotEmpty
                              ? friend.user.username[0].toUpperCase()
                              : '?',
                          style: AppTypography.display(
                            color: AppColors.amber,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
              ),
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.sage,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.card, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 11),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.user.username,
                  style: AppTypography.display(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      friend.user.preferredPosition ?? 'Joueur',
                      style: AppTypography.body(fontSize: 11, color: AppColors.muted2),
                    ),
                    if (friend.user.rating != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppColors.muted2,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${friend.user.rating!.toStringAsFixed(1)} ★',
                        style: AppTypography.body(
                          fontSize: 11,
                          color: AppColors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<MessagesProvider>(
                builder: (context, messagesProvider, _) {
                  final unread = messagesProvider.getUnreadCountForUser(
                    friend.user.id,
                  );
                  return GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ChatPage(
                            friendId: friend.user.id,
                            friendName: friend.user.username,
                            friendAvatarUrl: friend.user.avatarUrl,
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.card2,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: AppColors.border2),
                          ),
                          child: Text(
                            'Message',
                            style: AppTypography.display(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        if (unread > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.amber,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.bg, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  unread > 9 ? '9+' : '$unread',
                                  style: const TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.night,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              _buildFriendMenu(friend),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendMenu(FriendWithInfo friend) {
    return GestureDetector(
      onTap: () => _showFriendOptions(friend),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.card2,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.border2),
        ),
        child: const Icon(Icons.more_horiz, color: AppColors.muted2, size: 16),
      ),
    );
  }

  void _showFriendOptions(FriendWithInfo friend) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline, color: AppColors.amber),
              title: Text(
                'Voir le profil',
                style: AppTypography.display(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfilePage(
                      userBasicInfo: friend.user,
                      showAddFriendButton: false,
                    ),
                  ),
                );
              },
            ),
            const Divider(color: AppColors.border2, height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_remove_outlined, color: AppColors.rose),
              title: Text(
                'Supprimer cet ami',
                style: AppTypography.display(
                  color: AppColors.rose,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => Dialog(
                    backgroundColor: AppColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: AppColors.border2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Supprimer ${friend.user.username} ?',
                            style: AppTypography.display(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Cette action retirera ${friend.user.username} de ta liste d\'amis.',
                            style: AppTypography.body(
                              color: AppColors.muted2,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(dialogCtx, false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.card2,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.border2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Annuler',
                                        style: AppTypography.display(
                                          color: AppColors.muted2,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(dialogCtx, true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.roseDim,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.rose.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Supprimer',
                                        style: AppTypography.display(
                                          color: AppColors.rose,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
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
                if (confirm == true && mounted) {
                  await context.read<FriendsProvider>().removeFriend(
                    friend.friendshipId,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsPreview(FriendsProvider provider) {
    final requests = provider.pendingReceived.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amberDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mail_outline, color: AppColors.amber, size: 14),
              const SizedBox(width: 6),
              Text(
                'Demandes reçues',
                style: AppTypography.display(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _tabController.animateTo(1),
                child: Text(
                  'Voir tout →',
                  style: AppTypography.body(
                    color: AppColors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...requests.map((req) => _buildRequestPreviewRow(req, provider)),
        ],
      ),
    );
  }

  Widget _buildRequestPreviewRow(PendingRequest req, FriendsProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.card2,
              borderRadius: BorderRadius.circular(9),
            ),
            child: req.fromUser.avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      req.fromUser.avatarUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      req.fromUser.username[0].toUpperCase(),
                      style: AppTypography.display(
                        color: AppColors.amber,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              req.fromUser.username,
              style: AppTypography.display(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              await context.read<FriendsProvider>().acceptFriendRequest(
                req.friendshipId,
              );
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.sageDim,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.sage.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.check, color: AppColors.sage, size: 14),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () async {
              await context.read<FriendsProvider>().rejectFriendRequest(
                req.friendshipId,
              );
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.roseDim,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.rose.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.close, color: AppColors.rose, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab REÇUES ─────────────────────────────────────────────────────────────

  Widget _buildRecuesTab() {
    return Consumer<FriendsProvider>(
      builder: (context, provider, _) {
        if (provider.pendingReceived.isEmpty) {
          return _buildEmptyState(
            icon: Icons.mail_outline,
            message: 'Aucune demande reçue',
            subtitle: 'Les demandes d\'amitié apparaîtront ici',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          itemCount: provider.pendingReceived.length,
          itemBuilder: (context, i) =>
              _buildReceivedRequestCard(provider.pendingReceived[i]),
        );
      },
    );
  }

  Widget _buildReceivedRequestCard(PendingRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border2),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfilePage(
                  userBasicInfo: request.fromUser,
                  showAddFriendButton: false,
                ),
              ),
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.amberDim,
                borderRadius: BorderRadius.circular(13),
              ),
              child: request.fromUser.avatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        request.fromUser.avatarUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        request.fromUser.username.isNotEmpty
                            ? request.fromUser.username[0].toUpperCase()
                            : '?',
                        style: AppTypography.display(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.fromUser.username,
                  style: AppTypography.display(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  request.fromUser.preferredPosition ?? 'Joueur',
                  style: AppTypography.body(fontSize: 11, color: AppColors.muted2),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  await context.read<FriendsProvider>().rejectFriendRequest(
                    request.friendshipId,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.rose),
                  ),
                  child: Text(
                    'REFUSER',
                    style: AppTypography.display(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.rose,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              GestureDetector(
                onTap: () async {
                  await context.read<FriendsProvider>().acceptFriendRequest(
                    request.friendshipId,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.amberSoft, AppColors.amberD],
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    'ACCEPTER',
                    style: AppTypography.display(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.night,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab ENVOYÉES ──────────────────────────────────────────────────────────

  Widget _buildEnvoyeesTab() {
    return Consumer<FriendsProvider>(
      builder: (context, provider, _) {
        if (provider.pendingSent.isEmpty) {
          return _buildEmptyState(
            icon: Icons.send_outlined,
            message: 'Aucune demande envoyée',
            subtitle: 'Tes demandes en attente de réponse apparaîtront ici',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          itemCount: provider.pendingSent.length,
          itemBuilder: (context, i) =>
              _buildSentRequestCard(provider.pendingSent[i]),
        );
      },
    );
  }

  Widget _buildSentRequestCard(FriendWithInfo request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border2),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfilePage(
                  userBasicInfo: request.user,
                  showAddFriendButton: false,
                ),
              ),
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.card2,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.border2),
              ),
              child: request.user.avatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        request.user.avatarUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        request.user.username.isNotEmpty
                            ? request.user.username[0].toUpperCase()
                            : '?',
                        style: AppTypography.display(
                          color: AppColors.muted2,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.user.username,
                  style: AppTypography.display(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'En attente',
                      style: AppTypography.body(fontSize: 11, color: AppColors.amber),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              await context.read<FriendsProvider>().removeFriend(
                request.friendshipId,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.border2),
              ),
              child: Text(
                'ANNULER',
                style: AppTypography.display(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.muted2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border2),
            ),
            child: Icon(icon, color: AppColors.muted2, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: AppTypography.display(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.body(color: AppColors.muted2, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String? message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message ?? 'Une erreur est survenue',
            style: AppTypography.body(color: AppColors.muted2),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.amberDim,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Réessayer',
                style: AppTypography.display(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Friend Sheet ──────────────────────────────────────────────────────────

class _AddFriendSheet extends StatefulWidget {
  const _AddFriendSheet();

  @override
  State<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<_AddFriendSheet> {
  final TextEditingController _controller = TextEditingController();
  final Set<int> _sendingIds = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FriendsProvider>();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          // Header
          Text(
            'Ajouter un ami',
            style: AppTypography.display(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 14),
          // Search field
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.card2,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.border2),
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: AppTypography.body(color: AppColors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher un joueur...',
                hintStyle: AppTypography.body(color: AppColors.muted2, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.muted2, size: 17),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                provider.searchUsers(value);
              },
            ),
          ),
          const SizedBox(height: 12),
          // Results
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: _buildResults(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(FriendsProvider provider) {
    if (provider.isSearching) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: AppColors.amber)),
      );
    }

    if (_controller.text.length < 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Entrez au moins 2 caractères',
            style: AppTypography.body(color: AppColors.muted2, fontSize: 13),
          ),
        ),
      );
    }

    if (provider.searchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Aucun résultat trouvé',
            style: AppTypography.body(color: AppColors.muted2, fontSize: 13),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: provider.searchResults.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) =>
          _buildSearchResult(provider.searchResults[i], provider),
    );
  }

  Widget _buildSearchResult(SearchUserResult result, FriendsProvider provider) {
    final isSending = _sendingIds.contains(result.user.id);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border2),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfilePage(
                    userBasicInfo: result.user,
                    showAddFriendButton: result.friendshipStatus != 'accepted',
                  ),
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.amberDim,
                borderRadius: BorderRadius.circular(12),
              ),
              child: result.user.avatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.network(
                        result.user.avatarUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        result.user.username.isNotEmpty
                            ? result.user.username[0].toUpperCase()
                            : '?',
                        style: AppTypography.display(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.user.username,
                  style: AppTypography.display(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (result.user.preferredPosition != null)
                  Text(
                    result.user.preferredPosition!,
                    style: AppTypography.body(color: AppColors.muted2, fontSize: 11),
                  ),
              ],
            ),
          ),
          _buildAddButton(result, provider, isSending),
        ],
      ),
    );
  }

  Widget _buildAddButton(
    SearchUserResult result,
    FriendsProvider provider,
    bool isSending,
  ) {
    final status = result.friendshipStatus;

    if (status == 'accepted') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.sageDim,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
        ),
        child: Text(
          'Ami',
          style: AppTypography.display(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.sage,
          ),
        ),
      );
    }

    if (status == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.amberDim,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
        ),
        child: Text(
          'En attente',
          style: AppTypography.display(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.amber,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: isSending
          ? null
          : () async {
              setState(() => _sendingIds.add(result.user.id));
              final res = await provider.sendFriendRequest(result.user.id);
              if (!mounted) return;
              setState(() => _sendingIds.remove(result.user.id));
              if (!res['ok']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Erreur'),
                    backgroundColor: AppColors.rose,
                  ),
                );
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSending
              ? null
              : const LinearGradient(colors: [AppColors.amberSoft, AppColors.amberD]),
          color: isSending ? AppColors.card : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: isSending
            ? const SizedBox(
                width: 40,
                height: 14,
                child: Center(
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.amber,
                    ),
                  ),
                ),
              )
            : Text(
                '+ AJOUTER',
                style: AppTypography.display(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.night,
                ),
              ),
      ),
    );
  }
}
