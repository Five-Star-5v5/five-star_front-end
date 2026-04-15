import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/friends_provider.dart';
import '../providers/messages_provider.dart';
import '../services/friends_service.dart';
import 'chat_page.dart';
import 'user_profile_page.dart';

// ── Design tokens (dark amber system) ──────────────────────────────────────
const _fBg = Color(0xFF0A0C10);
const _fNight = Color(0xFF0B0D11);
const _fCard = Color(0xFF181A21);
const _fCard2 = Color(0xFF1E2029);
const _fBorder2 = Color(0x21FFFFFF);
const _fAmber = Color(0xFFFF7F2A);
const _fAmberSoft = Color(0xFFFF9A55);
const _fAmberD = Color(0xFFD96820);
const _fAmberDim = Color(0x1CFF7F2A);
const _fSage = Color(0xFF4CAF82);
const _fSageDim = Color(0x1C4CAF82);
const _fRose = Color(0xFFD4607A);
const _fRoseDim = Color(0x1CD4607A);
const _fWhite = Color(0xFFF0F2F5);
const _fMuted2 = Color(0x9EF0F2F5);

// ── Kobeta hex logo SVG paths ────────────────────────────────────────────────
const _fLogoOrange =
    'M 522.96275,807.1246 467.5,775.34587 437,758.06023 406.5,740.77459 '
    '402.75,738.37311 399,735.97162 v -58.0928 -58.0928 l 1.46246,0.5612 '
    '1.46245,0.5612 35.78755,20.38534 35.78754,20.38535 20,11.3484 '
    '20,11.34839 32,18.43475 32,18.43475 1.0164,0.044 1.01639,0.044 '
    '46.48361,-26.84474 46.4836,-26.84475 43.5,-25.1139 43.5,-25.1139 '
    '28.72048,-16.45802 L 816.94096,584.5 816.97048,445.80022 817,307.10045 '
    '840.75,293.64758 864.5,280.19471 891.34671,265.09735 918.19342,250 '
    'H 918.59671 919 v 196.31586 196.31586 l -4.25,2.36809 -4.25,2.36809 '
    '-64,36.95372 -64,36.95372 -16,9.27188 -16,9.27187 -80.5,46.40015 '
    '-80.5,46.40014 -5.53725,3.14198 -5.53725,3.14198 z '
    'M 291.9098,673.44632 245.5,646.89264 241.7475,644.43048 '
    '237.995,641.96832 238.2475,445.90639 238.5,249.84446 256,239.58695 '
    '273.5,229.32943 305.58644,210.66472 337.67289,192 H 338.83644 340 '
    'v 94.5 94.5 h 0.51121 0.51121 l 22.23879,-12.6427 22.23879,-12.64271 '
    '18,-10.21699 18,-10.217 72,-40.78463 72,-40.78462 10,-5.71608 '
    '10,-5.71607 18.5,-10.51984 18.5,-10.51984 49,-27.73683 49,-27.73683 '
    '13.8412,-7.88293 L 748.18239,150 h 0.77491 0.7749 l 50.38168,29.25 '
    '50.38167,29.25 0.002,0.86895 0.002,0.86896 -7.5,4.19949 -7.5,4.1995 '
    '-33,18.55543 -33,18.55543 -44,24.75584 -44,24.75583 -53.5,30.02161 '
    '-53.5,30.02161 -15,8.41924 -15,8.41924 -21.713,12.16644 '
    '-21.71299,12.16644 0.71299,0.6838 0.713,0.68381 51.5,29.18185 '
    '51.5,29.18185 41.5,23.48412 41.5,23.48411 37.24413,21.16322 '
    '37.24412,21.16323 -0.004,0.5 -0.004,0.5 -23.73968,13.14967 '
    'L 715.5,582.79933 687.31534,598.40918 659.13069,614.01903 '
    '648.81534,608.13201 638.5,602.24499 620,591.76417 601.5,581.28334 '
    '557,556.27313 512.5,531.26292 473,509.0197 433.5,486.77649 '
    '415.34425,476.38824 397.18849,466 h -0.97973 -0.97974 '
    'L 374.86451,477.66965 354.5,489.33929 347.25046,493.41965 '
    '340.00092,497.5 340.00046,598.75 340,700 h -0.8402 -0.84021 z '
    'M 419.5,232.41812 393.5,218.86137 367.26759,205.36365 '
    '341.03518,191.86594 340.6156,191.18297 340.19602,190.5 '
    '378.34801,168.56168 416.5,146.62336 l 63,-36.41539 63,-36.415382 '
    '18.17924,-10.473858 18.17925,-10.473858 43.82075,25.227159 '
    '43.82076,25.227159 6.31661,3.72768 6.31661,3.72768 -3.31661,2.0091 '
    '-3.31661,2.0091 -26.5,15.46261 -26.5,15.4626 -39,22.76345 '
    '-39,22.76344 -33,19.25601 -33,19.256 -13.97096,8.13157 '
    'L 447.55807,246 446.52904,245.9874 445.5,245.9748 Z';

const _fLogoGray =
    'M 522.96275,807.1246 467.5,775.34587 437,758.06023 406.5,740.77459 '
    '402.75,738.37311 399,735.97162 v -58.0928 -58.0928 l 1.46246,0.5612 '
    '1.46245,0.5612 35.78755,20.38534 35.78754,20.38535 20,11.3484 '
    '20,11.34839 32,18.43475 32,18.43475 1.0164,0.044 1.01639,0.044 '
    '46.48361,-26.84474 46.4836,-26.84475 43.5,-25.1139 43.5,-25.1139 '
    '28.72048,-16.45802 L 816.94096,584.5 816.97048,445.80022 817,307.10045 '
    '840.75,293.64758 864.5,280.19471 891.34671,265.09735 918.19342,250 '
    'H 918.59671 919 v 196.31586 196.31586 l -4.25,2.36809 -4.25,2.36809 '
    '-64,36.95372 -64,36.95372 -16,9.27188 -16,9.27187 -80.5,46.40015 '
    '-80.5,46.40014 -5.53725,3.14198 -5.53725,3.14198 z '
    'M 419.5,232.41812 393.5,218.86137 367.26759,205.36365 '
    '341.03518,191.86594 340.6156,191.18297 340.19602,190.5 '
    '378.34801,168.56168 416.5,146.62336 l 63,-36.41539 63,-36.415382 '
    '18.17924,-10.473858 18.17925,-10.473858 43.82075,25.227159 '
    '43.82076,25.227159 6.31661,3.72768 6.31661,3.72768 -3.31661,2.0091 '
    '-3.31661,2.0091 -26.5,15.46261 -26.5,15.4626 -39,22.76345 '
    '-39,22.76344 -33,19.25601 -33,19.256 -13.97096,8.13157 '
    'L 447.55807,246 446.52904,245.9874 445.5,245.9748 Z';

String _fLogoHexSvg(String d, String fill, String id) =>
    '''
<svg width="28" height="28" viewBox="0 0 130 130" xmlns="http://www.w3.org/2000/svg">
  <defs><clipPath id="$id"><polygon points="65,6 112,32 112,84 65,110 18,84 18,32"/></clipPath></defs>
  <g clip-path="url(#\$$id)"><g transform="translate(-6,4) scale(0.1234)"><path fill="$fill" d="$d"/></g></g>
</svg>
''';

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
      backgroundColor: _fBg,
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
      backgroundColor: _fCard,
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
          SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              children: [
                SvgPicture.string(
                  _fLogoHexSvg(_fLogoOrange, '#FF7F2A', 'flHexO'),
                  width: 28,
                  height: 28,
                ),
                SvgPicture.string(
                  _fLogoHexSvg(_fLogoGray, '#e6e6e6', 'flHexG'),
                  width: 28,
                  height: 28,
                ),
              ],
            ),
          ),
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
                  style: TextStyle(color: _fWhite),
                ),
                TextSpan(
                  text: 'beta',
                  style: TextStyle(color: _fAmber),
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
              gradient: const LinearGradient(colors: [_fAmberSoft, _fAmberD]),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '+ AJOUTER',
              style: GoogleFonts.syne(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.5,
                color: _fNight,
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _fBorder2),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: _fCard,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: _fCard2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _fBorder2),
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.dmSans(color: _fWhite, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Rechercher un ami...',
            hintStyle: GoogleFonts.dmSans(color: _fMuted2, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: _fMuted2, size: 16),
            suffixIcon: _filterText.isNotEmpty
                ? GestureDetector(
                    onTap: () => _searchController.clear(),
                    child: const Icon(Icons.close, color: _fMuted2, size: 16),
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
      color: _fCard,
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
              color: selected ? _fAmber : _fCard2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? _fAmber : _fBorder2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.syne(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: selected ? _fNight : _fMuted2,
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
                          ? _fNight.withValues(alpha: 0.25)
                          : (isAlert ? _fAmberDim : _fBorder2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.syne(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? _fNight
                            : (isAlert ? _fAmber : _fMuted2),
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
          return const Center(child: CircularProgressIndicator(color: _fAmber));
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
          color: _fAmber,
          backgroundColor: _fCard,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
            children: [
              if (filtered.isEmpty && _filterText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Aucun ami correspondant',
                      style: GoogleFonts.dmSans(color: _fMuted2, fontSize: 13),
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
        color: _fCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _fBorder2),
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
                  color: _fAmberDim,
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
                          style: GoogleFonts.syne(
                            color: _fAmber,
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
                    color: _fSage,
                    shape: BoxShape.circle,
                    border: Border.all(color: _fCard, width: 1.5),
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
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _fWhite,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      friend.user.preferredPosition ?? 'Joueur',
                      style: GoogleFonts.dmSans(fontSize: 11, color: _fMuted2),
                    ),
                    if (friend.user.rating != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: _fMuted2,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${friend.user.rating!.toStringAsFixed(1)} ★',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: _fAmber,
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
                            color: _fCard2,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: _fBorder2),
                          ),
                          child: Text(
                            'Message',
                            style: GoogleFonts.syne(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: _fWhite,
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
                                color: _fAmber,
                                shape: BoxShape.circle,
                                border: Border.all(color: _fBg, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  unread > 9 ? '9+' : '$unread',
                                  style: const TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.w800,
                                    color: _fNight,
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
          color: _fCard2,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _fBorder2),
        ),
        child: const Icon(Icons.more_horiz, color: _fMuted2, size: 16),
      ),
    );
  }

  void _showFriendOptions(FriendWithInfo friend) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _fCard,
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
                color: _fBorder2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline, color: _fAmber),
              title: Text(
                'Voir le profil',
                style: GoogleFonts.syne(
                  color: _fWhite,
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
            const Divider(color: _fBorder2, height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_remove_outlined, color: _fRose),
              title: Text(
                'Supprimer cet ami',
                style: GoogleFonts.syne(
                  color: _fRose,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => Dialog(
                    backgroundColor: _fCard,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: _fBorder2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Supprimer ${friend.user.username} ?',
                            style: GoogleFonts.syne(
                              color: _fWhite,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Cette action retirera ${friend.user.username} de ta liste d\'amis.',
                            style: GoogleFonts.dmSans(
                              color: _fMuted2,
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
                                      color: _fCard2,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: _fBorder2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Annuler',
                                        style: GoogleFonts.syne(
                                          color: _fMuted2,
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
                                      color: _fRoseDim,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _fRose.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Supprimer',
                                        style: GoogleFonts.syne(
                                          color: _fRose,
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
        color: _fAmberDim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _fAmber.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mail_outline, color: _fAmber, size: 14),
              const SizedBox(width: 6),
              Text(
                'Demandes reçues',
                style: GoogleFonts.syne(
                  color: _fAmber,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _tabController.animateTo(1),
                child: Text(
                  'Voir tout →',
                  style: GoogleFonts.dmSans(
                    color: _fAmber,
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
              color: _fCard2,
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
                      style: GoogleFonts.syne(
                        color: _fAmber,
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
              style: GoogleFonts.syne(
                color: _fWhite,
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
                color: _fSageDim,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _fSage.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.check, color: _fSage, size: 14),
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
                color: _fRoseDim,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _fRose.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.close, color: _fRose, size: 14),
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
        color: _fCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _fBorder2),
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
                color: _fAmberDim,
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
                        style: GoogleFonts.syne(
                          color: _fAmber,
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
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _fWhite,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  request.fromUser.preferredPosition ?? 'Joueur',
                  style: GoogleFonts.dmSans(fontSize: 11, color: _fMuted2),
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
                    border: Border.all(color: _fRose),
                  ),
                  child: Text(
                    'REFUSER',
                    style: GoogleFonts.syne(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: _fRose,
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
                      colors: [_fAmberSoft, _fAmberD],
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    'ACCEPTER',
                    style: GoogleFonts.syne(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: _fNight,
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
        color: _fCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _fBorder2),
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
                color: _fCard2,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _fBorder2),
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
                        style: GoogleFonts.syne(
                          color: _fMuted2,
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
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _fWhite,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _fAmber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'En attente',
                      style: GoogleFonts.dmSans(fontSize: 11, color: _fAmber),
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
                border: Border.all(color: _fBorder2),
              ),
              child: Text(
                'ANNULER',
                style: GoogleFonts.syne(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: _fMuted2,
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
              color: _fCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _fBorder2),
            ),
            child: Icon(icon, color: _fMuted2, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: GoogleFonts.syne(
              color: _fWhite,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(color: _fMuted2, fontSize: 12),
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
            style: GoogleFonts.dmSans(color: _fMuted2),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _fAmberDim,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: _fAmber.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Réessayer',
                style: GoogleFonts.syne(
                  color: _fAmber,
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
        color: _fCard,
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
              color: _fBorder2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          // Header
          Text(
            'Ajouter un ami',
            style: GoogleFonts.syne(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _fWhite,
            ),
          ),
          const SizedBox(height: 14),
          // Search field
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: _fCard2,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: _fBorder2),
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: GoogleFonts.dmSans(color: _fWhite, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher un joueur...',
                hintStyle: GoogleFonts.dmSans(color: _fMuted2, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: _fMuted2, size: 17),
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
        child: Center(child: CircularProgressIndicator(color: _fAmber)),
      );
    }

    if (_controller.text.length < 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Entrez au moins 2 caractères',
            style: GoogleFonts.dmSans(color: _fMuted2, fontSize: 13),
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
            style: GoogleFonts.dmSans(color: _fMuted2, fontSize: 13),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: provider.searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) =>
          _buildSearchResult(provider.searchResults[i], provider),
    );
  }

  Widget _buildSearchResult(SearchUserResult result, FriendsProvider provider) {
    final isSending = _sendingIds.contains(result.user.id);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _fCard2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _fBorder2),
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
                color: _fAmberDim,
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
                        style: GoogleFonts.syne(
                          color: _fAmber,
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
                  style: GoogleFonts.syne(
                    color: _fWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (result.user.preferredPosition != null)
                  Text(
                    result.user.preferredPosition!,
                    style: GoogleFonts.dmSans(color: _fMuted2, fontSize: 11),
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
          color: _fSageDim,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _fSage.withValues(alpha: 0.3)),
        ),
        child: Text(
          'Ami',
          style: GoogleFonts.syne(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _fSage,
          ),
        ),
      );
    }

    if (status == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _fAmberDim,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _fAmber.withValues(alpha: 0.3)),
        ),
        child: Text(
          'En attente',
          style: GoogleFonts.syne(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _fAmber,
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
                    backgroundColor: _fRose,
                  ),
                );
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSending
              ? null
              : const LinearGradient(colors: [_fAmberSoft, _fAmberD]),
          color: isSending ? _fCard : null,
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
                      color: _fAmber,
                    ),
                  ),
                ),
              )
            : Text(
                '+ AJOUTER',
                style: GoogleFonts.syne(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: _fNight,
                ),
              ),
      ),
    );
  }
}
