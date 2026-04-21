import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'theme_config/colors_config.dart';
import 'pages/map_page.dart';
import 'pages/home_page.dart';
import 'pages/friends_list_page.dart';
import 'pages/profile_page.dart';
import 'providers/messages_provider.dart';
import 'providers/friends_provider.dart';
import 'providers/teams_provider.dart';

class FootApp extends StatefulWidget {
  const FootApp({super.key});

  @override
  State<FootApp> createState() => _FootAppState();

  // Pour récupérer l'état depuis n'importe quel widget (toggle du thème)
  // ignore: library_private_types_in_public_api
  static _FootAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_FootAppState>()!;
}

class _FootAppState extends State<FootApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  // Thème clair
  final ThemeData _lightTheme = ThemeData(
    primaryColor: MyprimaryDark,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.green,
      accentColor: myAccentVibrantBlue,
    ),
    scaffoldBackgroundColor: myLightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: myLightBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: MyprimaryDark),
      titleTextStyle: TextStyle(
        color: MyprimaryDark,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 8,
      shadowColor: Colors.grey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: myLightBackground,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: MyprimaryDark),
      bodyMedium: TextStyle(color: MyprimaryDark),
      titleMedium: TextStyle(color: MyprimaryDark),
    ),
    useMaterial3: true,
  );

  // Thème sombre
  final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: myAccentVibrantBlue,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.green,
      accentColor: myAccentVibrantBlue,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: myDarkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: myDarkBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: myAccentVibrantBlue),
      titleTextStyle: TextStyle(
        color: myLightBackground,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 8,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: MyprimaryDark,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: myLightBackground),
      bodyMedium: TextStyle(color: myLightBackground),
      titleMedium: TextStyle(color: myLightBackground),
    ),
    listTileTheme: const ListTileThemeData(tileColor: Colors.transparent),
    useMaterial3: true,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Foot 5 Réservation',
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: _themeMode,
      home: const MainScreen(),
    );
  }
}

// ======================
// Écran principal + NavBar
// ======================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();

  // ignore: library_private_types_in_public_api
  static _MainScreenState of(BuildContext context) =>
      context.findAncestorStateOfType<_MainScreenState>()!;
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialiser le WebSocket et charger les conversations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messagesProvider = context.read<MessagesProvider>();
      messagesProvider.initWebSocket();
      messagesProvider.loadConversations();
      context.read<FriendsProvider>().loadFriends();
      context.read<FriendsProvider>().startPolling();
      context.read<TeamsProvider>().loadPendingChallenges();
      context.read<TeamsProvider>().loadPendingInvitations();
      context.read<TeamsProvider>().startPollingNotifications();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    final friendsProvider = context.read<FriendsProvider>();
    final teamsProvider = context.read<TeamsProvider>();
    if (state == AppLifecycleState.resumed) {
      friendsProvider.startPolling();
      friendsProvider.loadFriends();
      context.read<MessagesProvider>().loadConversations();
      teamsProvider.startPollingNotifications();
      teamsProvider.loadPendingChallenges();
      teamsProvider.loadPendingInvitations();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      friendsProvider.stopPolling();
      teamsProvider.stopPollingNotifications();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<FriendsProvider>().stopPolling();
    context.read<TeamsProvider>().stopPollingNotifications();
    super.dispose();
  }

  static const List<Widget> _widgetOptions = <Widget>[
    MapPage(),
    HomePage(),
    FriendsListPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void goToTab(int index) => _onItemTapped(index);

  Widget _buildCustomBottomNavBar() {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final unreadMessages = context.watch<MessagesProvider>().unreadCount;
    final pendingRequests = context.watch<FriendsProvider>().totalPendingCount;
    final teamNotifications = context
        .watch<TeamsProvider>()
        .totalNotificationsCount;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF16181E),
        border: Border(top: BorderSide(color: Color(0x12FFFFFF), width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(8, 9, 8, 9 + bottomPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.map_outlined, Icons.map, 'Terrains'),
          _buildNavItem(
            1,
            Icons.people_outline,
            Icons.people,
            'Équipe',
            badge: teamNotifications,
          ),
          _buildNavItem(
            2,
            Icons.group_outlined,
            Icons.group,
            'Amis',
            badge: unreadMessages + pendingRequests,
          ),
          _buildNavItem(3, Icons.person_outline, Icons.person, 'Profil'),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlineIcon,
    IconData filledIcon,
    String label, {
    int badge = 0,
  }) {
    final bool isSelected = _selectedIndex == index;
    const Color amber = Color(0xFFFF7F2A);
    const Color muted = Color(0x62F0F2F5);

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? filledIcon : outlineIcon,
                  color: isSelected ? amber : muted,
                  size: 22,
                ),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: badge > 9
                          ? const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            )
                          : const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4607A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          color: Color(0xFFF0F2F5),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.syne(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.06 * 9,
                color: isSelected ? amber : muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }
}
