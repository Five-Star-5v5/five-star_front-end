import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/friends_provider.dart';
import '../models/user_model.dart';
import '../auth/login.dart';
import 'settings_page.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const _pBg      = Color(0xFF0A0C10);
const _pNight   = Color(0xFF0B0D11);
const _pCard    = Color(0xFF181A21);
const _pCard2   = Color(0xFF1E2029);
const _pBorder2 = Color(0x21FFFFFF);
const _pAmber     = Color(0xFFFF7F2A);
const _pAmberSoft = Color(0xFFFF9A55);
const _pAmberD    = Color(0xFFD96820);
const _pAmberDim  = Color(0x1CFF7F2A);
const _pSage    = Color(0xFF4CAF82);
const _pSageDim = Color(0x1C4CAF82);
const _pWhite   = Color(0xFFF0F2F5);
const _pMuted2  = Color(0x9EF0F2F5);

// ── Kobeta hex logo SVG paths ────────────────────────────────────────────────
const _pLogoOrange =
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

const _pLogoGray =
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

String _pLogoHexSvg(String d, String fill, String id) => '''
<svg width="28" height="28" viewBox="0 0 130 130" xmlns="http://www.w3.org/2000/svg">
  <defs><clipPath id="$id"><polygon points="65,6 112,32 112,84 65,110 18,84 18,32"/></clipPath></defs>
  <g clip-path="url(#\$$id)"><g transform="translate(-6,4) scale(0.1234)"><path fill="$fill" d="$d"/></g></g>
</svg>
''';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final UserModel? user = authProvider.currentUser;

        if (user == null) {
          return const Scaffold(
            backgroundColor: _pBg,
            body: Center(child: CircularProgressIndicator(color: _pAmber)),
          );
        }

        return Scaffold(
          backgroundColor: _pBg,
          appBar: _buildAppBar(context, authProvider),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(user, context),
                const SizedBox(height: 14),
                _buildStatsBar(user),
                const SizedBox(height: 20),
                _buildBadges(user),
                const SizedBox(height: 20),
                _buildHistory(),
                const SizedBox(height: 20),
                _buildComments(),
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
      backgroundColor: _pCard,
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
                SvgPicture.string(_pLogoHexSvg(_pLogoOrange, '#FF7F2A', 'ppHexO'), width: 28, height: 28),
                SvgPicture.string(_pLogoHexSvg(_pLogoGray, '#e6e6e6', 'ppHexG'), width: 28, height: 28),
              ],
            ),
          ),
          const SizedBox(width: 9),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1),
              children: [
                TextSpan(text: 'Ko', style: TextStyle(color: _pWhite)),
                TextSpan(text: 'beta', style: TextStyle(color: _pAmber)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Logout
        GestureDetector(
          onTap: () async {
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
              color: _pCard2,
              shape: BoxShape.circle,
              border: Border.all(color: _pBorder2),
            ),
            child: const Icon(Icons.logout, color: _pMuted2, size: 16),
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
              color: _pCard2,
              shape: BoxShape.circle,
              border: Border.all(color: _pBorder2),
            ),
            child: const Icon(Icons.settings_outlined, color: _pMuted2, size: 16),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _pBorder2),
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
                  colors: [_pAmberSoft, _pAmberD],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: _pAmber.withValues(alpha: 0.15), blurRadius: 100, spreadRadius: 30),
                  BoxShadow(color: _pAmber.withValues(alpha: 0.07), blurRadius: 220, spreadRadius: 70),
                ],
              ),
              child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                  ? ClipOval(child: Image.network(user.avatarUrl!, fit: BoxFit.cover))
                  : Center(
                      child: Text(
                        initial,
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          color: _pNight,
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
              style: GoogleFonts.syne(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: 0.6,
                color: _pWhite,
              ),
            ),
          ),
          const SizedBox(height: 3),
          // Handle / sub-info
          Center(
            child: Text(
              '@${user.username.toLowerCase()}${user.preferredPosition != null ? ' · ${user.preferredPosition}' : ''}',
              style: GoogleFonts.dmSans(fontSize: 11, color: _pMuted2),
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
                    color: _pCard2,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: _pBorder2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#${user.codeId}',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: _pMuted2,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy_outlined, size: 10, color: _pMuted2),
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
              ],
            ),
          ),
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                user.bio!,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 12, color: _pMuted2, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(String label, {bool amber = false, bool sage = false}) {
    final color = amber ? _pAmber : sage ? _pSage : _pMuted2;
    final bg = amber ? _pAmberDim : sage ? _pSageDim : const Color(0x0DFFFFFF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.syne(
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
          _StatItem('NOTE', user.rating != null ? '${user.rating!.toStringAsFixed(1)}★' : '—'),
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
                  color: _pCard,
                  border: Border(
                    top: const BorderSide(color: _pBorder2),
                    bottom: const BorderSide(color: _pBorder2),
                    left: const BorderSide(color: _pBorder2),
                    right: isLast ? const BorderSide(color: _pBorder2) : BorderSide.none,
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
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: _pAmber,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stats[i].label,
                      style: GoogleFonts.syne(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: _pMuted2,
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
    if (user.matchesPlayed >= 10) list.add(_Badge('Régulier ⚡', _pAmber, _pAmberDim));
    if (user.matchesWon >= 5)     list.add(_Badge('Série 🔥', const Color(0xFFFFD06E), const Color(0x1AFFD06E)));
    if (user.matchesPlayed >= 5)  list.add(_Badge('Actif', _pAmber, _pAmberDim));
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
        style: GoogleFonts.syne(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: b.color,
        ),
      ),
    );
  }

  // ── History ───────────────────────────────────────────────────────────────

  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionLabel('HISTORIQUE')),
            Text(
              'Voir tout →',
              style: GoogleFonts.syne(fontSize: 10, fontWeight: FontWeight.w700, color: _pAmber),
            ),
          ],
        ),
        _emptyState(Icons.sports_soccer_outlined, 'Aucun match joué', 'Ton historique apparaîtra ici'),
      ],
    );
  }

  // ── Comments ──────────────────────────────────────────────────────────────

  Widget _buildComments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('COMMENTAIRES REÇUS'),
        _emptyState(Icons.chat_bubble_outline, 'Aucun commentaire', 'Les avis laissés par d\'autres joueurs apparaîtront ici'),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.syne(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: _pMuted2,
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: _pCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _pBorder2),
      ),
      child: Column(
        children: [
          Icon(icon, color: _pMuted2, size: 26),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.syne(color: _pWhite, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(subtitle, style: GoogleFonts.dmSans(color: _pMuted2, fontSize: 11), textAlign: TextAlign.center),
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
