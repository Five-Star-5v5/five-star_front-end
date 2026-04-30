import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import '../theme_config/colors_config.dart';
import '../providers/teams_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/auth_provider.dart';
import '../services/teams_service.dart';
import 'team_chat_page.dart';
import 'match_chat_page.dart';
import 'discover_teams_page.dart';
import 'find_opponents_page.dart';
import 'user_profile_page.dart';
import '../main_screen.dart';
import '../services/friends_service.dart' show UserBasicInfo;

// ── Design tokens (dark amber system) ──────────────────────────────────────
const _kBg = Color(0xFF0A0C10);
const _kNight = Color(0xFF0B0D11);
const _kCard = Color(0xFF181A21);
const _kCard2 = Color(0xFF1E2029);
const _kBorder = Color(0x12FFFFFF);
const _kBorder2 = Color(0x21FFFFFF);
const _kAmber = Color(0xFFFF7F2A);
const _kAmberSoft = Color(0xFFFF9A55);
const _kAmberD = Color(0xFFD96820);
const _kAmberDim = Color(0x1CFF7F2A);
const _kSage = Color(0xFF4CAF82);
const _kSageDim = Color(0x1C4CAF82);
const _kRose = Color(0xFFD4607A);
const _kRoseDim = Color(0x1CD4607A);
const _kWhite = Color(0xFFF0F2F5);
const _kMuted2 = Color(0x9EF0F2F5);

// ── Kobeta hex logo SVG paths ────────────────────────────────────────────────
const _kLogoOrange =
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

const _kLogoGray =
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

String _logoHexSvg(String d, String fill, String id) =>
    '''
<svg width="28" height="28" viewBox="0 0 130 130" xmlns="http://www.w3.org/2000/svg">
  <defs><clipPath id="$id"><polygon points="65,6 112,32 112,84 65,110 18,84 18,32"/></clipPath></defs>
  <g clip-path="url(#\$$id)"><g transform="translate(-6,4) scale(0.1234)"><path fill="$fill" d="$d"/></g></g>
</svg>
''';

Widget _buildAvailChip(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: _kAmberDim,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9, color: _kAmber),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: _kAmber,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  static const double _playerAvatarRadius = 28;

  bool _isLookingForOpponent = false;
  bool _isLoadingSearchPrefs = false;
  TeamSearchPreference? _searchPreference;
  int? _lastLoadedTeamId;
  List<MatchChallenge> _upcomingMatches = [];
  Map<int, int> _unreadMatchMessages = {};
  late AnimationController _loadingAnimationController;

  @override
  void initState() {
    super.initState();

    _loadingAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TeamsProvider>();
      provider.loadMyTeam();
      provider.startChatPolling();
      provider.addListener(_onTeamChanged);
      _loadSearchPreferences();
    });
  }

  @override
  void dispose() {
    _loadingAnimationController.dispose();
    // Retirer le listener
    try {
      context.read<TeamsProvider>().removeListener(_onTeamChanged);
    } catch (_) {}
    super.dispose();
  }

  void _onTeamChanged() {
    if (!mounted) return;
    final provider = context.read<TeamsProvider>();
    final currentTeam = provider.currentDisplayedTeam;
    if (currentTeam != null && currentTeam.id != _lastLoadedTeamId) {
      _loadSearchPreferences();
    }
  }

  Future<void> _loadSearchPreferences() async {
    if (!mounted) return;
    final provider = context.read<TeamsProvider>();
    final team = provider.currentDisplayedTeam;

    if (team == null || !provider.isPartOfCurrentTeam) {
      setState(() {
        _isLookingForOpponent = false;
        _searchPreference = null;
        _lastLoadedTeamId = team?.id;
        _upcomingMatches = [];
      });
      return;
    }

    _lastLoadedTeamId = team.id;
    setState(() => _isLoadingSearchPrefs = true);

    try {
      final matchesFuture = TeamsService.instance.getTeamMatches(
        team.id,
        status: 'accepted',
      );

      if (provider.isCurrentTeamMine) {
        final results = await Future.wait([
          TeamsService.instance.getSearchPreferences(team.id),
          matchesFuture,
          TeamsService.instance.getAllUnreadCounts(),
        ]);

        if (mounted) {
          setState(() {
            _searchPreference = results[0] as TeamSearchPreference?;
            _isLookingForOpponent =
                _searchPreference?.isLookingForOpponent ?? false;
            _upcomingMatches = results[1] as List<MatchChallenge>;
            _unreadMatchMessages = results[2] as Map<int, int>;
            _isLoadingSearchPrefs = false;
          });
        }
      } else {
        final results = await Future.wait([
          matchesFuture,
          TeamsService.instance.getAllUnreadCounts(),
        ]);

        if (mounted) {
          setState(() {
            _searchPreference = null;
            _isLookingForOpponent = false;
            _upcomingMatches = results[0] as List<MatchChallenge>;
            _unreadMatchMessages = results[1] as Map<int, int>;
            _isLoadingSearchPrefs = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSearchPrefs = false);
    }
  }

  Future<void> _loadUpcomingMatches() async {
    final provider = context.read<TeamsProvider>();
    final team = provider.currentDisplayedTeam;
    if (team == null) return;
    // Suppression du setState inutilisé
    try {
      final matches = await TeamsService.instance.getTeamMatches(
        team.id,
        status: 'accepted',
      );
      if (mounted) {
        setState(() {
          _upcomingMatches = matches;
          // Suppression de l'affectation inutile
        });
      }
    } catch (e) {
      // Suppression du setState inutile
    }
  }

  Future<void> _toggleSearchMode(bool value) async {
    final provider = context.read<TeamsProvider>();
    final team = provider.currentDisplayedTeam;
    if (team == null) return;

    // Si on active le mode recherche, afficher le dialogue de configuration
    if (value) {
      _showSearchPreferencesDialog(context);
      return; // Le dialogue gérera l'activation
    }

    // Si on désactive, faire la requête directement
    setState(() => _isLookingForOpponent = false);
    try {
      final result = await TeamsService.instance.updateSearchPreferences(
        team.id,
        isLookingForOpponent: false,
        preferredDays: _searchPreference?.preferredDays,
        preferredTimeSlots: _searchPreference?.preferredTimeSlots,
        preferredLocations: _searchPreference?.preferredLocations,
        skillLevel: _searchPreference?.skillLevel,
        description: _searchPreference?.description,
      );
      if (result != null && mounted) {
        setState(() => _searchPreference = result);
        _showSnackBar('Équipe indisponible pour les matchs', isSuccess: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLookingForOpponent = true);
        _showSnackBar('Erreur lors de la désactivation', isSuccess: false);
      }
    }
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo avec rotation
          RotationTransition(
            turns: _loadingAnimationController,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_kAmberSoft, _kAmberD],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kAmber.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: SvgPicture.string(
                _logoHexSvg(_kLogoOrange, '#0B0D11', 'loadingHex'),
                width: 50,
                height: 50,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Kobeta',
            style: GoogleFonts.syne(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _kWhite,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Préparation en cours...',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: _kMuted2,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showInfoModal(String title, List<String> lines) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: _kBorder, width: 1),
            left: BorderSide(color: _kBorder, width: 1),
            right: BorderSide(color: _kBorder, width: 1),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _kBorder2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.info_outline, color: _kAmber, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.syne(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kWhite,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  line,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: _kMuted2,
                    height: 1.55,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget pour activer/désactiver le mode recherche d'adversaire
  Widget _buildSearchModeToggle(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      decoration: BoxDecoration(
        color: _isLookingForOpponent ? _kAmber.withValues(alpha: 0.08) : _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isLookingForOpponent
              ? _kAmber.withValues(alpha: 0.35)
              : _kBorder2,
          width: 1.5,
        ),
        boxShadow: _isLookingForOpponent
            ? [
                BoxShadow(
                  color: _kAmber.withValues(alpha: 0.14),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isLookingForOpponent ? _kAmberDim : _kBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isLookingForOpponent
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: _isLookingForOpponent ? _kAmber : _kMuted2,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Disponible pour un match',
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.04 * 13,
                          color: _isLookingForOpponent ? _kAmber : _kWhite,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _isLookingForOpponent
                            ? 'Votre équipe est visible par les équipes qui cherchent un adversaire'
                            : 'Activez pour apparaître dans les recherches',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: _kMuted2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoadingSearchPrefs)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _kAmber,
                    ),
                  )
                else
                  Switch.adaptive(
                    value: _isLookingForOpponent,
                    onChanged: _toggleSearchMode,
                    activeThumbColor: _kNight,
                    activeTrackColor: _kAmber,
                  ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _showInfoModal('Publiez un match', [
                'Publiez un match et laissez une autre équipe le rejoindre. Vous créez l\'offre, une équipe adverse peut donc vous defier.',
                'Seul le capitaine de l\'équipe peut créer un match. Nous vous conseillons d\'indiquer une plage horaire large afin d\'augmenter vos chances de trouver un adversaire.',
                'Une fois que la demande de defie sera envoyer par l\'adversaire, tu seras libre de l\'accepter ou de la decliner. Une fois le defie accepter il s\'affichera ici dans « Matchs à venir » et vous aurez accès à un chat pour vous organiser avec l\'équipe adverse.',
                '👉 Recommandation : trouvez d\'abord un adversaire et fixez l\'horaire avant de réserver et payer un terrain, afin d\'éviter toute dépense inutile.',
              ]),
              child: Icon(
                Icons.info_outline,
                size: 14,
                color: _isLookingForOpponent
                    ? _kAmber.withValues(alpha: 0.65)
                    : _kMuted2.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section des matchs à venir
  Widget _buildUpcomingMatchesSection(
    int myTeamId,
    bool isDarkMode,
    Color titleColor,
    bool isOwner,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'MATCHS À VENIR',
                  style: GoogleFonts.syne(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.04 * 13,
                    color: _kWhite,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kAmberDim,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: _kAmber.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_upcomingMatches.length}',
                    style: const TextStyle(
                      color: _kAmber,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _showInfoModal(
                    'Trouvez un match et affrontez une équipe',
                    [
                      'Consultez les matchs publiés par d’autres équipes et envoyez une demande pour les affronter.',
                      '👉 Par exemple, si une équipe a créé un match, vous pouvez répondre à son annonce et proposer de jouer contre elle.',
                      '👉 Une fois la demande acceptée, une conversation s’ouvre pour organiser les détails de la rencontre (horaire, lieu, etc.).',
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.info_outline,
                      size: 14,
                      color: _kAmber.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FindOpponentsPage(),
                    ),
                  ),
                  child: Text(
                    'Trouver →',
                    style: GoogleFonts.syne(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kAmber,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_upcomingMatches.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder, width: 1),
            ),
            child: Column(
              children: [
                Icon(Icons.sports_soccer_outlined, size: 28, color: _kMuted2),
                const SizedBox(height: 8),
                Text(
                  'Aucun match à venir',
                  style: GoogleFonts.syne(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kMuted2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Défiez une équipe pour planifier un match',
                  style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted2),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._upcomingMatches.map(
            (match) => _buildMatchCard(match, myTeamId, isDarkMode, isOwner),
          ),
      ],
    );
  }

  /// Carte pour afficher un match
  Widget _buildMatchCard(
    MatchChallenge match,
    int myTeamId,
    bool isDarkMode,
    bool isOwner,
  ) {
    final isChallenger = match.challengerTeamId == myTeamId;
    final opponentName = match.getOpponentName(myTeamId);
    final opponentLogo = match.getOpponentLogoUrl(myTeamId);
    final hasSubmitted = match.hasSubmittedScore(myTeamId);
    final opponentSubmittedScore = match.getOpponentSubmittedScore(myTeamId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec adversaire
          Row(
            children: [
              // Icône match
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kAmberDim,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: _kAmber.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: opponentLogo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(opponentLogo, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Text(
                          opponentName[0].toUpperCase(),
                          style: const TextStyle(
                            color: _kAmber,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
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
                      'VS $opponentName',
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.03 * 13,
                        color: _kWhite,
                      ),
                    ),
                    Text(
                      isChallenger ? 'Défi envoyé' : 'Défi reçu',
                      style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted2),
                    ),
                  ],
                ),
              ),
              // Bouton chat avec badge de messages non lus
              _buildMatchChatButton(match, myTeamId, isDarkMode),
              const SizedBox(width: 8),
              // Statut
              _buildMatchStatusBadge(match, hasSubmitted, isDarkMode),
            ],
          ),
          const SizedBox(height: 10),
          // Infos du match
          if (match.proposedDate != null || match.proposedLocation != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kCard2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  if (match.proposedDate != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: _kMuted2,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatMatchDate(match.proposedDate!),
                          style: const TextStyle(fontSize: 12, color: _kWhite),
                        ),
                      ],
                    ),
                  if (match.proposedDate != null &&
                      match.proposedLocation != null)
                    const SizedBox(height: 6),
                  if (match.proposedLocation != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: _kMuted2,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            match.proposedLocation!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _kWhite,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Afficher le score de l'adversaire s'il a soumis et que je n'ai pas soumis
          if (opponentSubmittedScore != null && !hasSubmitted) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'L\'adversaire a soumis le score suivant :',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode
                                ? Colors.orange[200]
                                : Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Affichage du score avec noms d'équipes
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Équipe challenger
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                match.challengerTeamName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${opponentSubmittedScore['challengerScore']}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.blue[300]
                                        : Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Séparateur
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '-',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                        // Équipe challengée
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                match.challengedTeamName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${opponentSubmittedScore['challengedScore']}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.red[300]
                                        : Colors.red[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Boutons Valider / Contester - seulement pour l'owner
                  if (isOwner) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => _contestMatchScore(match),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: const Color(0xFFD4607A),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'CONTESTER',
                              style: GoogleFonts.syne(
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                letterSpacing: 0.06 * 10,
                                color: const Color(0xFFD4607A),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _validateMatchScore(match),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A7A4B),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              'VALIDER',
                              style: GoogleFonts.syne(
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                letterSpacing: 0.06 * 10,
                                color: _kWhite,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Contester = match nul (0-0)',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: _kMuted2,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Message pour les membres non-owner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'En attente de la validation du score par le capitaine',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.orange[300]
                                    : Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ]
          // Si j'ai déjà soumis, attente de validation
          else if (hasSubmitted) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.hourglass_empty,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Score soumis ! En attente de validation par l\'adversaire.',
                      style: TextStyle(color: Colors.green[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ]
          // Owner — score pas encore soumis (match à jouer)
          else if (isOwner) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: _kCard2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isChallenger
                          ? match.challengerTeamName
                          : match.challengedTeamName,
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: _kWhite,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      '? – ?',
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: _kMuted2,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      opponentName,
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: _kWhite,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ]
          // Membre mais pas owner - afficher un message
          else if (!isOwner) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'En attente que le capitaine enregistre le résultat.',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Boutons d'action compacts (droite)
          if (isOwner) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!hasSubmitted && opponentSubmittedScore == null) ...[
                  GestureDetector(
                    onTap: () => _showSubmitScoreDialog(match, myTeamId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_kAmberSoft, _kAmberD],
                        ),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x47FF7F2A),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        'RÉSULTAT',
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.06 * 10,
                          color: _kNight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                GestureDetector(
                  onTap: () => _cancelMatch(match),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: _kBorder2, width: 1.5),
                    ),
                    child: Text(
                      'ANNULER',
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        letterSpacing: 0.06 * 10,
                        color: _kMuted2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Badge de statut du match
  Widget _buildMatchStatusBadge(
    MatchChallenge match,
    bool hasSubmitted,
    bool isDarkMode,
  ) {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;

    if (match.scoreConflict) {
      bgColor = _kRose.withValues(alpha: 0.12);
      textColor = _kRose;
      text = 'Conflit';
      icon = Icons.warning;
    } else if (hasSubmitted) {
      bgColor = _kAmberDim;
      textColor = _kAmber;
      text = 'En attente';
      icon = Icons.hourglass_empty;
    } else {
      bgColor = _kSage.withValues(alpha: 0.12);
      textColor = _kSage;
      text = 'À jouer';
      icon = Icons.sports_soccer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: textColor.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 9,
              letterSpacing: 0.06 * 9,
            ),
          ),
        ],
      ),
    );
  }

  /// Bouton de chat pour un match avec badge de messages non lus
  Widget _buildMatchChatButton(
    MatchChallenge match,
    int myTeamId,
    bool isDarkMode,
  ) {
    final unreadCount = _unreadMatchMessages[match.id] ?? 0;
    final isChallenger = match.challengerTeamId == myTeamId;
    final myTeamName = isChallenger
        ? match.challengerTeamName
        : match.challengedTeamName;
    final opponentName = match.getOpponentName(myTeamId);
    final opponentLogo = match.getOpponentLogoUrl(myTeamId);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchChatPage(
              challengeId: match.id,
              myTeamName: myTeamName,
              opponentTeamName: opponentName,
              opponentTeamLogoUrl: opponentLogo,
              myTeamId: myTeamId,
            ),
          ),
        );
        // Recharger les messages non lus après retour du chat
        _loadUnreadCounts();
      },
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _kAmberDim,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: _kAmber.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: _kAmber,
              size: 17,
            ),
          ),
          // Badge de messages non lus
          if (unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Recharge les compteurs de messages non lus
  Future<void> _loadUnreadCounts() async {
    final counts = await TeamsService.instance.getAllUnreadCounts();
    if (mounted) {
      setState(() {
        _unreadMatchMessages = counts;
      });
    }
  }

  /// Formater la date du match
  String _formatMatchDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final matchDay = DateTime(date.year, date.month, date.day);

    String dayText;
    if (matchDay == today) {
      dayText = "Aujourd'hui";
    } else if (matchDay == tomorrow) {
      dayText = 'Demain';
    } else {
      final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      final months = [
        'jan',
        'fév',
        'mar',
        'avr',
        'mai',
        'juin',
        'juil',
        'août',
        'sep',
        'oct',
        'nov',
        'déc',
      ];
      dayText =
          '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
    }

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$dayText à ${hour}h$minute';
  }

  /// Dialog pour soumettre le score
  Future<void> _showSubmitScoreDialog(
    MatchChallenge match,
    int myTeamId,
  ) async {
    final myScoreController = TextEditingController();
    final opponentScoreController = TextEditingController();
    final opponentName = match.getOpponentName(myTeamId);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: _kCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _kBorder2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enregistrer le résultat',
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _kWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Entrez le score du match contre $opponentName',
                  style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted2),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Votre équipe',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: _kMuted2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: myScoreController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _kWhite,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: const TextStyle(color: _kMuted2),
                              filled: true,
                              fillColor: _kCard2,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _kBorder2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _kBorder2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _kAmber),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '-',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _kWhite,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            opponentName,
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: _kMuted2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: opponentScoreController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _kWhite,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: const TextStyle(color: _kMuted2),
                              filled: true,
                              fillColor: _kCard2,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _kBorder2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _kBorder2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: _kAmber),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kAmberDim,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: _kAmber, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'L\'adversaire devra confirmer ce score pour qu\'il soit validé.',
                          style: GoogleFonts.dmSans(
                            color: _kAmberSoft,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: _kCard2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kBorder2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Annuler',
                            style: GoogleFonts.syne(
                              fontWeight: FontWeight.w600,
                              color: _kMuted2,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final myScore = int.tryParse(myScoreController.text);
                          final opponentScore = int.tryParse(
                            opponentScoreController.text,
                          );
                          if (myScore != null && opponentScore != null) {
                            Navigator.pop(context, true);
                          }
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_kAmber, _kAmberD],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Valider',
                            style: GoogleFonts.syne(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 13,
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
      },
    );

    if (result == true) {
      final myScore = int.parse(myScoreController.text);
      final opponentScore = int.parse(opponentScoreController.text);

      final updated = await TeamsService.instance.submitMatchScore(
        match.id,
        myScore: myScore,
        opponentScore: opponentScore,
      );

      if (mounted) {
        if (updated != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                updated.scoreValidated
                    ? '✅ Score validé ! Les deux équipes ont confirmé le résultat.'
                    : '⏳ Score enregistré. En attente de confirmation de l\'adversaire.',
              ),
              backgroundColor: updated.scoreValidated
                  ? Colors.green
                  : Colors.orange,
            ),
          );
          _showPostMatchCommentSheet(match);
          _loadUpcomingMatches();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'enregistrement du score'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Valider le score soumis par l'adversaire
  Future<void> _validateMatchScore(MatchChallenge match) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _kBorder2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Valider le score',
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _kWhite,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Confirmez-vous que ce score est correct ?',
                style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: _kCard2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kBorder2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Annuler',
                          style: GoogleFonts.syne(
                            fontWeight: FontWeight.w600,
                            color: _kMuted2,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kAmber, _kAmberD],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Valider',
                          style: GoogleFonts.syne(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 13,
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

    if (confirmed == true) {
      final result = await TeamsService.instance.validateMatchScore(
        match.id,
        validate: true,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Score validé !'),
            backgroundColor: Colors.green,
          ),
        );
        _showPostMatchCommentSheet(match);
        _loadUpcomingMatches();
      }
    }
  }

  /// Contester le score - résulte en match nul
  Future<void> _contestMatchScore(MatchChallenge match) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _kBorder2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Contester le score',
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _kWhite,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Si vous contestez ce score, le match sera déclaré nul (0-0).\n\n'
                'Êtes-vous sûr de vouloir contester ?',
                style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: _kCard2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kBorder2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Annuler',
                          style: GoogleFonts.syne(
                            fontWeight: FontWeight.w600,
                            color: _kMuted2,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: _kRose,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Contester',
                          style: GoogleFonts.syne(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 13,
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

    if (confirmed == true) {
      final result = await TeamsService.instance.validateMatchScore(
        match.id,
        validate: false,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Score contesté - Match nul déclaré (0-0)'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadUpcomingMatches();
      }
    }
  }

  /// Annule un match (même accepté)
  Future<void> _cancelMatch(MatchChallenge match) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _kBorder2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Annuler le match',
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _kWhite,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Êtes-vous sûr de vouloir annuler le match contre ${match.getOpponentName(_getMyTeamIdFromMatch(match))} ?\n\n'
                'Cette action ne peut pas être annulée.',
                style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: _kCard2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kBorder2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Non',
                          style: GoogleFonts.syne(
                            fontWeight: FontWeight.w600,
                            color: _kMuted2,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: _kRose,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Oui, annuler',
                          style: GoogleFonts.syne(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 13,
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

    if (confirm == true) {
      final success = await TeamsService.instance.cancelChallenge(match.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Match annulé'),
            backgroundColor: Colors.red,
          ),
        );
        _loadUpcomingMatches();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'annulation du match'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Helper pour obtenir l'ID de mon équipe à partir d'un match
  int _getMyTeamIdFromMatch(MatchChallenge match) {
    final provider = context.read<TeamsProvider>();
    return provider.currentDisplayedTeam?.id ?? match.challengerTeamId;
  }

  /// Affiche une boîte de dialogue pour confirmer la sortie de l'équipe
  void _showLeaveTeamDialog(
    BuildContext context,
    TeamDetail team,
    TeamsProvider teamsProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: _kCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _kBorder2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quitter l\'équipe',
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _kWhite,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Êtes-vous sûr de vouloir quitter "${team.name}" ?\n\n'
                  'Vous ne recevrez plus les messages de cette équipe et ne pourrez plus participer aux matchs.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted2),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: _kCard2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kBorder2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Annuler',
                            style: GoogleFonts.syne(
                              fontWeight: FontWeight.w600,
                              color: _kMuted2,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.of(
                            dialogContext,
                          ).pop(); // Fermer la boîte de dialogue

                          // Afficher un indicateur de chargement
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext loadingContext) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          );

                          // Quitter l'équipe
                          final success = await teamsProvider.leaveTeam(
                            team.id,
                          );

                          // Fermer l'indicateur de chargement
                          if (context.mounted) {
                            Navigator.of(context).pop();

                            if (success) {
                              // Recharger les équipes
                              await teamsProvider.loadMyTeam();

                              // Afficher un message de succès
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Vous avez quitté l\'équipe "${team.name}"',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              // Afficher un message d'erreur
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Erreur lors de la sortie de l\'équipe',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: _kRose,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Quitter',
                            style: GoogleFonts.syne(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 13,
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
      },
    );
  }

  void _showNotificationsSheet(
    BuildContext context,
    TeamsProvider teamsProvider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: teamsProvider,
        child: const _NotificationsSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color titleColor = isDarkMode ? myLightBackground : MyprimaryDark;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: IgnorePointer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.4),
                radius: 1.6,
                colors: [Color(0x28FF7F2A), Colors.transparent],
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
                    _logoHexSvg(_kLogoOrange, '#FF7F2A', 'hmHexO'),
                    width: 28,
                    height: 28,
                  ),
                  SvgPicture.string(
                    _logoHexSvg(_kLogoGray, '#e6e6e6', 'hmHexG'),
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
                    style: TextStyle(color: _kWhite),
                  ),
                  TextSpan(
                    text: 'beta',
                    style: TextStyle(color: _kAmber),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Consumer<TeamsProvider>(
            builder: (context, teamsProvider, _) => GestureDetector(
              onTap: () => _showNotificationsSheet(context, teamsProvider),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _kCard,
                      shape: BoxShape.circle,
                      border: Border.all(color: _kBorder2),
                    ),
                    child: const Icon(
                      Icons.notifications_none_outlined,
                      color: _kMuted2,
                      size: 17,
                    ),
                  ),
                  if (teamsProvider.totalNotificationsCount > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _kAmber,
                          shape: BoxShape.circle,
                          border: Border.all(color: _kNight, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            teamsProvider.totalNotificationsCount > 9
                                ? '9+'
                                : '${teamsProvider.totalNotificationsCount}',
                            style: const TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                              color: _kNight,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Consumer<AuthProvider>(
            builder: (_, auth, _) {
              final user = auth.currentUser;
              final initial = user?.username.isNotEmpty == true
                  ? user!.username[0].toUpperCase()
                  : 'U';
              return GestureDetector(
                onTap: () => MainScreen.of(context).goToTab(3),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: _kAmber,
                    backgroundImage: user?.avatarUrl != null
                        ? NetworkImage(user!.avatarUrl!)
                        : null,
                    child: user?.avatarUrl == null
                        ? Text(
                            initial,
                            style: const TextStyle(
                              color: _kNight,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<TeamsProvider>(
        builder: (context, teamsProvider, _) {
          if (teamsProvider.isLoadingInitial) {
            return _buildLoadingScreen();
          }

          if (teamsProvider.state == TeamsLoadingState.loading &&
              teamsProvider.allTeams.isEmpty) {
            return _buildLoadingScreen();
          }

          final allTeams = teamsProvider.allTeams;
          final currentIndex = teamsProvider.currentTeamIndex;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Scrollable content ──────────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  color: _kAmber,
                  onRefresh: () => teamsProvider.loadMyTeam(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // ── Team cards (scrollable) ─────────────────────
                          _buildTeamHeader(
                            context: context,
                            teamsProvider: teamsProvider,
                            titleColor: titleColor,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 12),
                          // Widget pour activer le mode recherche d'adversaire
                          if (teamsProvider.isCurrentTeamMine &&
                              teamsProvider.currentDisplayedTeam != null)
                            _buildSearchModeToggle(isDarkMode),
                          const SizedBox(height: 12),
                          if (allTeams.isEmpty)
                            _buildEmptyTeamPlaceholder(isDarkMode)
                          else
                            _buildTeamPitch(
                              context,
                              team: teamsProvider.currentDisplayedTeam!,
                              isMyTeam: teamsProvider.isCurrentTeamMine,
                              isDarkMode: isDarkMode,
                            ),
                          const SizedBox(height: 10),
                          if (allTeams.length > 1)
                            _buildPageIndicators(
                              allTeams.length,
                              currentIndex,
                              isDarkMode,
                            ),
                          const SizedBox(height: 20),
                          if (teamsProvider.isCurrentTeamMine)
                            _buildSubstitutesSection(
                              context,
                              teamsProvider: teamsProvider,
                              titleColor: titleColor,
                              isDarkMode: isDarkMode,
                            )
                          else if (teamsProvider.currentDisplayedTeam != null)
                            _buildOtherTeamSubstitutes(
                              teamsProvider.currentDisplayedTeam!,
                              titleColor: titleColor,
                              isDarkMode: isDarkMode,
                            ),
                          const SizedBox(height: 20),
                          // Indicateur de candidatures en attente
                          if (teamsProvider.isCurrentTeamMine)
                            Visibility(
                              visible:
                                  teamsProvider.pendingApplicationsCount > 0,
                              child: Container(
                                key: ValueKey(
                                  'pending_apps_${teamsProvider.pendingApplicationsCount}_${teamsProvider.lastUpdateTimestamp}',
                                ),
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _kAmberDim,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _kAmber.withValues(alpha: 0.30),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.notifications_active,
                                      color: _kAmber,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${teamsProvider.pendingApplicationsCount} candidature(s) en attente',
                                        style: const TextStyle(
                                          color: _kAmber,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          _showAllApplicationsDialog(context),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _kAmber,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'VOIR',
                                          style: TextStyle(
                                            color: _kNight,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 10,
                                            letterSpacing: 0.06 * 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Section des matchs à venir (visible pour tous les membres)
                          if (teamsProvider.isPartOfCurrentTeam)
                            _buildUpcomingMatchesSection(
                              teamsProvider.currentDisplayedTeam!.id,
                              isDarkMode,
                              titleColor,
                              teamsProvider.isCurrentTeamMine,
                            ),
                          const SizedBox(height: 20),
                        ],
                      ), // inner Column
                    ), // Padding
                  ), // SingleChildScrollView
                ), // RefreshIndicator
              ), // Expanded
            ],
          ); // outer Column (return)
        },
      ),
    );
  }

  Widget _buildTeamHeader({
    required BuildContext context,
    required TeamsProvider teamsProvider,
    required Color titleColor,
    required bool isDarkMode,
  }) {
    final allTeams = teamsProvider.allTeams;
    final currentIndex = teamsProvider.currentTeamIndex;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: SizedBox(
              height: 260,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.0,
                    colors: [Color(0x55FF7F2A), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Horizontal team cards scroll ───────────────────────────
            if (allTeams.isEmpty)
              Container(
                width: double.infinity,
                height: 116,
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kBorder),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.group_add_outlined,
                        color: _kMuted2,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PAS D\'ÉQUIPE',
                        style: GoogleFonts.syne(
                          color: _kMuted2,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.06 * 11,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 116,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: allTeams.length + 1,
                  padding: EdgeInsets.zero,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    // "Rejoindre une équipe" card
                    if (index == allTeams.length) {
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DiscoverTeamsPage(),
                          ),
                        ),
                        child: Container(
                          width: 116,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _kCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _kAmber.withValues(alpha: 0.20),
                              width: 1,
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: _kAmberDim,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      size: 18,
                                      color: _kAmber,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'REJOINDRE',
                                    style: GoogleFonts.syne(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: _kAmber,
                                      letterSpacing: 0.06 * 8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'une équipe',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 9,
                                      color: _kMuted2,
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _showInfoModal(
                                    'Rejoindre une équipe',
                                    [
                                      'Trouvez une équipe ou rejoignez la vôtre.',
                                      'Recherchez une équipe à l\'aide de son nom ou de son code, ou consultez les équipes incomplètes et envoyez une demande pour les rejoindre lors de leur prochain match.',
                                      '👉 Vous pouvez postuler à plusieurs équipes pour maximiser vos chances de jouer rapidement.',
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    size: 13,
                                    color: _kAmber.withValues(alpha: 0.65),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final team = allTeams[index];
                    final isActive = index == currentIndex;
                    final isOwner = team.id == teamsProvider.myTeam?.id;
                    return GestureDetector(
                      onTap: () => teamsProvider.setCurrentTeamIndex(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 152,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: isActive
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _kAmber.withValues(alpha: 0.12),
                                    _kAmberD.withValues(alpha: 0.06),
                                  ],
                                )
                              : null,
                          color: isActive ? null : _kCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive
                                ? _kAmber.withValues(alpha: 0.35)
                                : _kBorder,
                            width: isActive ? 1.5 : 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            if (isActive)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: _kAmber,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Role badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOwner
                                        ? _kAmberDim
                                        : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: isOwner
                                          ? _kAmber.withValues(alpha: 0.25)
                                          : _kBorder2,
                                    ),
                                  ),
                                  child: Text(
                                    isOwner ? 'MON ÉQUIPE' : 'MEMBRE',
                                    style: GoogleFonts.syne(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: isOwner ? _kAmber : _kMuted2,
                                      letterSpacing: 0.06 * 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Team name
                                Text(
                                  team.name.toUpperCase(),
                                  style: GoogleFonts.syne(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: _kWhite,
                                    letterSpacing: 0.04 * 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                // Meta
                                Text(
                                  '${team.members.length} membre${team.members.length > 1 ? 's' : ''}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    color: _kMuted2,
                                  ),
                                ),
                                const Spacer(),
                                // Avatars + action buttons row
                                Row(
                                  children: [
                                    _buildStackedAvatars(team),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TeamChatPage(
                                              teamId: team.id,
                                              teamName: team.name,
                                              teamLogoUrl: team.logoUrl,
                                              ownerId: team.ownerId,
                                            ),
                                          ),
                                        );
                                        if (context.mounted) {
                                          context
                                              .read<TeamsProvider>()
                                              .loadMyTeamChats();
                                        }
                                      },
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.all(2),
                                            child: Icon(
                                              Icons.chat_bubble_outline,
                                              size: 18,
                                              color: _kAmber,
                                            ),
                                          ),
                                          if (teamsProvider
                                                  .getUnreadCountForTeam(
                                                    team.id,
                                                  ) >
                                              0)
                                            Positioned(
                                              right: -1,
                                              top: -1,
                                              child: Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isOwner) ...[
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () =>
                                            _showEditTeamNameDialog(context),
                                        child: const Padding(
                                          padding: EdgeInsets.all(2),
                                          child: Icon(
                                            Icons.edit_outlined,
                                            size: 17,
                                            color: _kMuted2,
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (!isOwner) ...[
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () => _showLeaveTeamDialog(
                                          context,
                                          team,
                                          teamsProvider,
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(2),
                                          child: Icon(
                                            Icons.exit_to_app,
                                            size: 18,
                                            color: _kRose,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStackedAvatars(TeamDetail team) {
    final starters = team.starters.take(3).toList();
    final extra = team.members.length > 3 ? team.members.length - 3 : 0;
    return Row(
      children: [
        ...starters.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          return Transform.translate(
            offset: Offset(i * -5.0, 0),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kAmber,
                border: Border.all(color: _kCard, width: 2),
              ),
              child: Center(
                child: Text(
                  m.user.username.isNotEmpty
                      ? m.user.username[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: _kNight,
                  ),
                ),
              ),
            ),
          );
        }),
        if (extra > 0)
          Transform.translate(
            offset: Offset(starters.length * -5.0, 0),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kCard2,
                border: Border.all(color: _kCard, width: 2),
              ),
              child: Center(
                child: Text(
                  '+$extra',
                  style: const TextStyle(
                    fontSize: 6,
                    fontWeight: FontWeight.w600,
                    color: _kMuted2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPageIndicators(int count, int currentIndex, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 14 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: isActive ? _kAmber : _kBorder2,
          ),
        );
      }),
    );
  }

  Widget _buildEmptyTeamPlaceholder(bool isDarkMode) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder2, width: 1.5),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 44, color: _kMuted2),
            const SizedBox(height: 12),
            const Text(
              'AUCUNE ÉQUIPE',
              style: TextStyle(
                color: _kWhite,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.06 * 13,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ajoutez des amis pour créer votre équipe',
              style: TextStyle(color: _kMuted2, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamPitch(
    BuildContext context, {
    required TeamDetail team,
    required bool isMyTeam,
    required bool isDarkMode,
  }) {
    final starters = team.starters;

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A1F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            final double height = constraints.maxHeight;
            final double avatarRadius = (width / 13).clamp(18.0, 32.0);
            final double avatarDiameter = avatarRadius * 2;

            // Placement horizontal : gardien à gauche, défenseurs au centre, attaquants à droite
            final List<List<int>> columns = [
              [0], // Gardien (à gauche)
              [1, 2], // Défenseurs (au centre)
              [3, 4], // Attaquants (à droite)
            ];

            TeamMember? getMember(int slotIndex) {
              final matches = starters.where((m) => m.slotIndex == slotIndex);
              return matches.isEmpty ? null : matches.first;
            }

            final double horizontalSpacing =
                (width - avatarDiameter * columns.length) /
                (columns.length + 1);
            List<Widget> playerWidgets = [];
            for (int i = 0; i < columns.length; i++) {
              final column = columns[i];
              final x =
                  horizontalSpacing * (i + 1) +
                  avatarRadius +
                  avatarDiameter * i;
              final count = column.length;
              final verticalSpacing =
                  (height - (count * avatarDiameter)) / (count + 1);
              for (int j = 0; j < count; j++) {
                final y =
                    verticalSpacing * (j + 1) +
                    avatarRadius +
                    avatarDiameter * j;
                final slotIndex = column[j];
                final member = getMember(slotIndex);
                playerWidgets.add(
                  Positioned(
                    left: x - avatarRadius,
                    top: y - avatarRadius,
                    child: _buildPlayerSlot(
                      context,
                      slotIndex: slotIndex,
                      position: PlayerPosition.values[slotIndex],
                      member: member,
                      isDarkMode: isDarkMode,
                      isEditable: isMyTeam,
                    ),
                  ),
                );
              }
            }

            return Stack(
              children: [
                // Terrain
                CustomPaint(
                  size: Size(width, height),
                  painter: _ModernPitchPainter(
                    Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                ...playerWidgets,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubstitutesSection(
    BuildContext context, {
    required TeamsProvider teamsProvider,
    required Color titleColor,
    required bool isDarkMode,
  }) {
    final myTeam = teamsProvider.myTeam;
    final substitutes = myTeam?.substitutes ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'REMPLAÇANTS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.04 * 13,
                color: _kWhite,
              ),
            ),
            GestureDetector(
              onTap: () => _showAddPlayerDialog(
                context,
                slotIndex: 5 + substitutes.length,
                position: PlayerPosition.substitute,
              ),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _kAmberDim,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _kAmber.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: const Icon(Icons.add, color: _kAmber, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (substitutes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder2),
            ),
            child: const Center(
              child: Text(
                'Aucun remplaçant — appuyez sur + pour ajouter',
                textAlign: TextAlign.center,
                style: TextStyle(color: _kMuted2, fontSize: 12),
              ),
            ),
          )
        else
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: substitutes
                .map<Widget>(
                  (member) => _buildSubstitutePlayer(
                    member,
                    isDarkMode,
                    isEditable: true,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildOtherTeamSubstitutes(
    TeamDetail team, {
    required Color titleColor,
    required bool isDarkMode,
  }) {
    final substitutes = team.substitutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'REMPLAÇANTS',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.04 * 13,
            color: _kWhite,
          ),
        ),
        const SizedBox(height: 10),
        if (substitutes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder2),
            ),
            child: const Center(
              child: Text(
                'Aucun remplaçant',
                textAlign: TextAlign.center,
                style: TextStyle(color: _kMuted2, fontSize: 12),
              ),
            ),
          )
        else
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: substitutes
                .map<Widget>(
                  (member) => _buildSubstitutePlayer(
                    member,
                    isDarkMode,
                    isEditable: false,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildPlayerSlot(
    BuildContext context, {
    required int slotIndex,
    required PlayerPosition position,
    TeamMember? member,
    required bool isDarkMode,
    required bool isEditable,
  }) {
    final teamsProvider = context.read<TeamsProvider>();
    final isSlotOpen = isEditable && teamsProvider.isSlotOpen(slotIndex);
    final openSlot = isEditable
        ? teamsProvider.getOpenSlotForIndex(slotIndex)
        : null;

    if (member != null) {
      return GestureDetector(
        onTap: isEditable ? () => _showPlayerOptions(context, member) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircleAvatar(
              radius: _playerAvatarRadius,
              backgroundColor: _kAmber,
              backgroundImage: member.user.avatarUrl != null
                  ? NetworkImage(member.user.avatarUrl!)
                  : null,
              child: member.user.avatarUrl == null
                  ? Text(
                      member.user.username.isNotEmpty
                          ? member.user.username[0].toUpperCase()
                          : position.shortName,
                      style: const TextStyle(
                        color: _kNight,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                member.user.username.length > 8
                    ? '${member.user.username.substring(0, 8)}…'
                    : member.user.username,
                style: const TextStyle(
                  color: _kWhite,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Si le slot est en mode recherche
    if (isSlotOpen && openSlot != null) {
      return GestureDetector(
        onTap: () => _showOpenSlotOptions(context, openSlot, position),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Stack(
              children: [
                CircleAvatar(
                  radius: _playerAvatarRadius,
                  backgroundColor: _kAmber.withValues(alpha: 0.85),
                  child: const Icon(
                    Icons.person_search,
                    color: _kNight,
                    size: 22,
                  ),
                ),
                if (openSlot.applicationsCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${openSlot.applicationsCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Candidatures',
                style: TextStyle(
                  color: _kAmber,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Slot vide — vérifier s'il y a des invitations en attente pour ce slot
    if (isEditable) {
      final pendingSent = teamsProvider.sentInvitationsForSlot(slotIndex);
      if (pendingSent.isNotEmpty) {
        return GestureDetector(
          onTap: () => _showSlotInvitationsDialog(
            context,
            slotIndex: slotIndex,
            position: position,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Stack(
                children: [
                  CircleAvatar(
                    radius: _playerAvatarRadius,
                    backgroundColor: _kAmber.withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.mail_outline,
                      color: _kAmber,
                      size: 20,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: _kAmber,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${pendingSent.length}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _kAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'En attente',
                  style: TextStyle(
                    color: _kAmber,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    // Slot vide sans invitation
    return GestureDetector(
      onTap: isEditable
          ? () => _showAddPlayerDialog(
              context,
              slotIndex: slotIndex,
              position: position,
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircleAvatar(
            radius: _playerAvatarRadius,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            child: Icon(
              isEditable ? Icons.add : Icons.person_outline,
              color: Colors.white.withValues(alpha: 0.5),
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            position.shortName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubstitutePlayer(
    TeamMember member,
    bool isDarkMode, {
    required bool isEditable,
  }) {
    return GestureDetector(
      onTap: isEditable ? () => _showPlayerOptions(context, member) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: _kBorder2, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircleAvatar(
              radius: 11,
              backgroundColor: _kAmberDim,
              backgroundImage: member.user.avatarUrl != null
                  ? NetworkImage(member.user.avatarUrl!)
                  : null,
              child: member.user.avatarUrl == null
                  ? Text(
                      member.user.username.isNotEmpty
                          ? member.user.username[0].toUpperCase()
                          : 'R',
                      style: const TextStyle(
                        color: _kAmber,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 7),
            Text(
              member.user.username,
              style: const TextStyle(
                color: _kWhite,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (member.user.rating != null) ...[
              const SizedBox(width: 5),
              Text(
                '⭐${member.user.rating!.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 10, color: _kMuted2),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPlayerOptions(BuildContext context, TeamMember member) {
    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    final isOwner = member.user.id == currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            CircleAvatar(
              radius: 30,
              backgroundColor: _kAmberDim,
              backgroundImage: member.user.avatarUrl != null
                  ? NetworkImage(member.user.avatarUrl!)
                  : null,
              child: member.user.avatarUrl == null
                  ? Text(
                      member.user.username[0].toUpperCase(),
                      style: const TextStyle(
                        color: _kAmber,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  member.user.username,
                  style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kWhite,
                  ),
                ),
                if (isOwner) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _kAmberDim,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Vous',
                      style: GoogleFonts.syne(
                        fontSize: 12,
                        color: _kAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              member.position.displayName,
              style: GoogleFonts.dmSans(color: _kMuted2, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Divider(color: _kBorder2),
            if (!isOwner) ...[
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfilePage(
                        userBasicInfo: UserBasicInfo(
                          id: member.user.id,
                          username: member.user.username,
                          avatarUrl: member.user.avatarUrl,
                          preferredPosition: member.user.preferredPosition,
                          rating: member.user.rating,
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _kCard2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorder2),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: _kAmber,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Voir le profil',
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w600,
                          color: _kWhite,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                _showChangePositionDialog(context, member);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: _kCard2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz, color: _kAmber, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Changer de position',
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w600,
                        color: _kWhite,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Le propriétaire ne peut pas se retirer de l'équipe
            if (!isOwner)
              GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogCtx) => Dialog(
                      backgroundColor: _kCard,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: _kBorder2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Retirer ce joueur ?',
                              style: GoogleFonts.syne(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: _kWhite,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Voulez-vous retirer ${member.user.username} de l\'équipe ?',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: _kMuted2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        Navigator.pop(dialogCtx, false),
                                    child: Container(
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: _kCard2,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _kBorder2),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Annuler',
                                        style: GoogleFonts.syne(
                                          fontWeight: FontWeight.w600,
                                          color: _kMuted2,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(dialogCtx, true),
                                    child: Container(
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: _kRose,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Retirer',
                                        style: GoogleFonts.syne(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          fontSize: 13,
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
                  if (confirm == true && context.mounted) {
                    await context.read<TeamsProvider>().removeMemberFromMyTeam(
                      member.user.id,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _kRoseDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kRose.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.remove_circle, color: _kRose, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Retirer de l\'équipe',
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w600,
                          color: _kRose,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'En tant que propriétaire, vous ne pouvez pas quitter l\'équipe.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: _kMuted2,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Dialog de gestion des invitations en attente pour un slot
  void _showSlotInvitationsDialog(
    BuildContext context, {
    required int slotIndex,
    required PlayerPosition position,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final teamsProvider = context.read<TeamsProvider>();
          final pending = teamsProvider.sentInvitationsForSlot(slotIndex);

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            decoration: const BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle + titre
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invitations envoyées',
                                  style: GoogleFonts.syne(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _kWhite,
                                  ),
                                ),
                                Text(
                                  'Poste : ${position.displayName}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: _kMuted2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Badge count
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _kAmber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _kAmber.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              '${pending.length} en attente',
                              style: GoogleFonts.syne(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _kAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(color: _kBorder2, height: 1),
                // Liste des invitations en attente
                if (pending.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Aucune invitation en attente',
                      style: GoogleFonts.dmSans(color: _kMuted2),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: pending.length,
                      separatorBuilder: (_, _) =>
                          Divider(color: _kBorder2, height: 1),
                      itemBuilder: (listCtx, index) {
                        final inv = pending[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _kCard2,
                            backgroundImage: inv.invitedAvatarUrl != null
                                ? NetworkImage(inv.invitedAvatarUrl!)
                                : null,
                            child: inv.invitedAvatarUrl == null
                                ? Text(
                                    inv.invitedUsername.isNotEmpty
                                        ? inv.invitedUsername[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(color: _kAmber),
                                  )
                                : null,
                          ),
                          title: Text(
                            inv.invitedUsername,
                            style: GoogleFonts.syne(
                              color: _kWhite,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Envoyée le ${_formatInvitationDate(inv.createdAt)}',
                            style: GoogleFonts.dmSans(
                              color: _kMuted2,
                              fontSize: 12,
                            ),
                          ),
                          trailing: GestureDetector(
                            onTap: () async {
                              final success = await context
                                  .read<TeamsProvider>()
                                  .cancelInvitation(inv.id);
                              if (context.mounted) {
                                if (success) {
                                  setState(() {}); // Rafraîchir la liste
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Invitation annulée pour ${inv.invitedUsername}',
                                      ),
                                      backgroundColor: _kAmber,
                                    ),
                                  );
                                  // Fermer si plus d'invitations
                                  if (teamsProvider
                                      .sentInvitationsForSlot(slotIndex)
                                      .isEmpty) {
                                    Navigator.pop(ctx);
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Erreur lors de l\'annulation',
                                      ),
                                      backgroundColor: _kRose,
                                    ),
                                  );
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _kRose.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _kRose.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                'Annuler',
                                style: GoogleFonts.syne(
                                  color: _kRose,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                // Bouton envoyer une autre invitation
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAddPlayerDialog(
                        context,
                        slotIndex: slotIndex,
                        position: position,
                      );
                    },
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: _kAmber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Inviter une autre personne',
                        style: GoogleFonts.syne(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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
    );
  }

  String _formatInvitationDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }

  void _showAddPlayerDialog(
    BuildContext context, {
    required int slotIndex,
    required PlayerPosition position,
  }) async {
    await context.read<FriendsProvider>().loadFriends();
    if (!context.mounted) return;
    final friends = context.read<FriendsProvider>().friends;
    final teamsProvider = context.read<TeamsProvider>();
    final currentUser = context.read<AuthProvider>().currentUser;
    final availableFriends = friends
        .where((f) => !teamsProvider.isUserInTeam(f.user.id))
        .toList();

    // Vérifier si le propriétaire peut s'ajouter lui-même
    final canAddSelf =
        currentUser != null && !teamsProvider.isUserInTeam(currentUser.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (sheetCtx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    const SizedBox(height: 12),
                    Text(
                      'Ajouter un ${position.displayName}',
                      style: GoogleFonts.syne(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kWhite,
                      ),
                    ),
                  ],
                ),
              ),
              // Option pour s'ajouter soi-même
              if (canAddSelf)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _kAmberDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kAmber.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _kAmberDim,
                      backgroundImage: currentUser.avatarUrl != null
                          ? NetworkImage(currentUser.avatarUrl!)
                          : null,
                      child: currentUser.avatarUrl == null
                          ? Text(
                              currentUser.username[0].toUpperCase(),
                              style: const TextStyle(color: _kAmber),
                            )
                          : null,
                    ),
                    title: Text(
                      'Me placer ici',
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w600,
                        color: _kWhite,
                      ),
                    ),
                    subtitle: Text(
                      '@${currentUser.username}',
                      style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted2),
                    ),
                    trailing: const Icon(Icons.person_add, color: _kAmber),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await teamsProvider.addMemberToMyTeam(
                        userId: currentUser.id,
                        position: position,
                        slotIndex: slotIndex,
                      );
                    },
                  ),
                ),
              // Option pour mettre en mode recherche
              Tooltip(
                message:
                    'Recherchez des joueurs pour compléter votre équipe.\nPubliez une annonce pour signaler que votre équipe recrute. Les joueurs disponibles pourront voir votre besoin et vous envoyer une demande.\n👉 Précisez la localisation, la date et le niveau recherché pour recevoir des profils adaptés.\n👉 Vous pouvez accepter ou refuser les demandes librement.',
                preferBelow: false,
                verticalOffset: 8,
                decoration: BoxDecoration(
                  color: _kNight,
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _kAmberDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kAmber.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: _kAmberDim,
                      child: Icon(Icons.person_search, color: _kAmber),
                    ),
                    title: Text(
                      'Ouvrir aux candidatures',
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w600,
                        color: _kWhite,
                      ),
                    ),
                    subtitle: Text(
                      'Les joueurs de l\'app pourront postuler pour rejoindre l\'équipe',
                      style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted2),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _showInfoModal('Ouvrir aux candidatures', [
                            'Recherchez des joueurs pour compléter votre équipe.',
                            'Publiez une annonce pour signaler que votre équipe recrute. Les joueurs disponibles pourront voir votre besoin et vous envoyer une demande.',
                            '👉 Précisez la localisation, la date et le niveau recherché pour recevoir des profils adaptés.',
                            '👉 Vous pouvez accepter ou refuser les demandes librement.',
                          ]),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: _kAmber,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: _kMuted2,
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showOpenSlotDialog(context, slotIndex, position);
                    },
                  ),
                ),
              ),
              // Recruter sur le store
              Tooltip(
                message: 'Invitez des joueurs pour compléter votre équipe.',
                preferBelow: false,
                verticalOffset: 8,
                decoration: BoxDecoration(
                  color: _kNight,
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorder2),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF1A1D26),
                      child: Icon(Icons.storefront_outlined, color: _kMuted2),
                    ),
                    title: Text(
                      'Recruter sur le store',
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w600,
                        color: _kWhite,
                      ),
                    ),
                    subtitle: Text(
                      'Parcourir les joueurs disponibles et les inviter',
                      style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted2),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _showInfoModal('Recruter sur le store', [
                            'Invitez des joueurs pour compléter votre équipe.',
                            'Consultez les joueurs disponibles et envoyez une invitation à ceux qui correspondent à vos besoins.',
                            '👉 Le joueur peut accepter ou refuser votre invitation librement.',
                          ]),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: _kMuted2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: _kMuted2,
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAvailablePlayersSheet(context, slotIndex, position);
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: _kBorder2)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'ou choisir un ami',
                        style: GoogleFonts.dmSans(
                          color: _kMuted2,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: _kBorder2)),
                  ],
                ),
              ),
              if (availableFriends.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Tous vos amis sont déjà dans l\'équipe !',
                    style: GoogleFonts.dmSans(color: _kMuted2),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: availableFriends.length,
                    itemBuilder: (listCtx, index) {
                      final friend = availableFriends[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _kCard2,
                          backgroundImage: friend.user.avatarUrl != null
                              ? NetworkImage(friend.user.avatarUrl!)
                              : null,
                          child: friend.user.avatarUrl == null
                              ? Text(
                                  friend.user.username[0].toUpperCase(),
                                  style: const TextStyle(color: _kAmber),
                                )
                              : null,
                        ),
                        title: Text(
                          friend.user.username,
                          style: GoogleFonts.syne(
                            color: _kWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          friend.user.preferredPosition ??
                              'Position non définie',
                          style: GoogleFonts.dmSans(
                            color: _kMuted2,
                            fontSize: 12,
                          ),
                        ),
                        trailing: friend.user.rating != null
                            ? Text(
                                '⭐ ${friend.user.rating!.toStringAsFixed(1)}',
                                style: GoogleFonts.dmSans(color: _kMuted2),
                              )
                            : null,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await teamsProvider.addMemberToMyTeam(
                            userId: friend.user.id,
                            position: position,
                            slotIndex: slotIndex,
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOpenSlotDialog(
    BuildContext context,
    int slotIndex,
    PlayerPosition position,
  ) {
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _kBorder2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_search, color: _kAmber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ouvrir le poste de ${position.displayName}',
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _kWhite,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Les joueurs de l\'application pourront voir ce poste et postuler pour rejoindre votre équipe.',
                style: GoogleFonts.dmSans(color: _kMuted2, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                style: const TextStyle(color: _kWhite),
                decoration: InputDecoration(
                  labelText: 'Description (optionnel)',
                  labelStyle: const TextStyle(color: _kMuted2),
                  hintText: 'Ex: Recherche défenseur expérimenté...',
                  hintStyle: const TextStyle(color: _kMuted2),
                  filled: true,
                  fillColor: _kCard2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBorder2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBorder2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kAmber),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(dialogCtx),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: _kCard2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kBorder2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Annuler',
                          style: GoogleFonts.syne(
                            fontWeight: FontWeight.w600,
                            color: _kMuted2,
                            fontSize: 13,
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
                        final success = await context
                            .read<TeamsProvider>()
                            .openSlotForSearch(
                              position: position,
                              slotIndex: slotIndex,
                              description:
                                  descriptionController.text.trim().isNotEmpty
                                  ? descriptionController.text.trim()
                                  : null,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Poste ouvert aux candidatures !'
                                    : 'Erreur lors de l\'ouverture du poste',
                              ),
                              backgroundColor: success
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          );
                        }
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kAmber, _kAmberD],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.person_search,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ouvrir le poste',
                              style: GoogleFonts.syne(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
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

  void _showOpenSlotOptions(
    BuildContext context,
    OpenSlot openSlot,
    PlayerPosition position,
  ) {
    final teamsProvider = context.read<TeamsProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const CircleAvatar(
              radius: 30,
              backgroundColor: _kAmberDim,
              child: Icon(Icons.person_search, color: _kAmber, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              'Poste ${position.displayName} — candidatures ouvertes',
              style: GoogleFonts.syne(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kWhite,
              ),
            ),
            if (openSlot.description != null) ...[
              const SizedBox(height: 8),
              Text(
                openSlot.description!,
                style: GoogleFonts.dmSans(color: _kMuted2),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _kAmberDim,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${openSlot.applicationsCount} candidature(s)',
                style: GoogleFonts.syne(
                  color: _kAmber,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (openSlot.applicationsCount > 0) ...[
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _showApplicationsDialog(context, openSlot);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _kCard2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorder2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: _kAmber, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Voir les candidatures',
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w600,
                          color: _kWhite,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: _kRose,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${openSlot.applicationsCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            GestureDetector(
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => Dialog(
                    backgroundColor: _kCard,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: _kBorder2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Clôturer les candidatures ?',
                            style: GoogleFonts.syne(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: _kWhite,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Les candidatures en attente seront annulées.',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: _kMuted2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(dialogCtx, false),
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: _kCard2,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _kBorder2),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Annuler',
                                      style: GoogleFonts.syne(
                                        fontWeight: FontWeight.w600,
                                        color: _kMuted2,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(dialogCtx, true),
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: _kRose,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Fermer',
                                      style: GoogleFonts.syne(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontSize: 13,
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
                if (confirm == true && context.mounted) {
                  await teamsProvider.closeOpenSlot(openSlot.id);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: _kRoseDim,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kRose.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.close, color: _kRose, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clôturer les candidatures',
                          style: GoogleFonts.syne(
                            fontWeight: FontWeight.w600,
                            color: _kRose,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Mettre fin aux candidatures pour ce poste',
                          style: GoogleFonts.dmSans(
                            color: _kMuted2,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAvailablePlayersSheet(
    BuildContext context,
    int slotIndex,
    PlayerPosition position,
  ) async {
    final teamsProvider = context.read<TeamsProvider>();
    final teamId = teamsProvider.currentDisplayedTeam?.id;
    if (teamId == null) return;
    final memberIds =
        teamsProvider.currentDisplayedTeam?.members
            .map((m) => m.user.id)
            .toSet() ??
        {};

    // Recharger les invitations envoyées depuis le backend avant d'ouvrir la sheet
    await teamsProvider.loadSentInvitations();

    // Map local userId→SentInvitation — persiste entre les rebuilds du StatefulBuilder
    final localInvitations = <int, SentInvitation>{
      for (final inv in teamsProvider.sentInvitationsForSlot(slotIndex))
        inv.invitedUserId: inv,
    };

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final invitedIds = localInvitations.keys.toSet();

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollController) => Container(
              decoration: const BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _kBorder2,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          color: _kAmber,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Joueurs disponibles',
                          style: GoogleFonts.syne(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kWhite,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _kAmberDim,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            position.displayName,
                            style: GoogleFonts.syne(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _kAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: _kBorder2, height: 1),
                  Expanded(
                    child: FutureBuilder<List<AvailablePlayer>>(
                      future: TeamsService.instance.getAvailablePlayers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: _kAmber),
                          );
                        }
                        final players = snapshot.data ?? [];
                        if (players.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.person_off_outlined,
                                  color: _kMuted2,
                                  size: 40,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Aucun joueur disponible',
                                  style: GoogleFonts.syne(
                                    color: _kMuted2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Les joueurs peuvent activer leur disponibilité\ndans "Trouve ton équipe"',
                                  style: GoogleFonts.dmSans(
                                    color: _kMuted2,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }
                        // Tri : position correspondante en premier
                        final sorted = [...players]
                          ..sort((a, b) {
                            final aMatch = a.preferredPosition == position.value
                                ? 0
                                : 1;
                            final bMatch = b.preferredPosition == position.value
                                ? 0
                                : 1;
                            return aMatch.compareTo(bMatch);
                          });
                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: sorted.length,
                          itemBuilder: (_, i) {
                            final player = sorted[i];
                            final posMatch =
                                player.preferredPosition == position.value;
                            final isMember = memberIds.contains(player.id);
                            final isInvited = invitedIds.contains(player.id);

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 5,
                              ),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: posMatch
                                    ? const Color(0xFF1A1D26)
                                    : const Color(0xFF13151C),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: posMatch
                                      ? _kAmber.withValues(alpha: 0.25)
                                      : _kBorder2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: _kAmberDim,
                                    backgroundImage: player.avatarUrl != null
                                        ? NetworkImage(player.avatarUrl!)
                                        : null,
                                    child: player.avatarUrl == null
                                        ? Text(
                                            player.username[0].toUpperCase(),
                                            style: GoogleFonts.syne(
                                              color: _kAmber,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              player.username,
                                              style: GoogleFonts.syne(
                                                fontWeight: FontWeight.w700,
                                                color: _kWhite,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (posMatch) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 1,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _kAmberDim,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  'Poste correspondant',
                                                  style: GoogleFonts.syne(
                                                    fontSize: 9,
                                                    color: _kAmber,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          player.preferredPosition ??
                                              'Aucune position',
                                          style: GoogleFonts.dmSans(
                                            color: _kMuted2,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (player.availabilityCities != null ||
                                            player.availabilityDays != null ||
                                            player.availabilityRadiusKm !=
                                                null) ...[
                                          const SizedBox(height: 5),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: [
                                              if (player.availabilityCities !=
                                                      null &&
                                                  player
                                                      .availabilityCities!
                                                      .isNotEmpty)
                                                _buildAvailChip(
                                                  Icons.location_on_outlined,
                                                  player.availabilityCities!
                                                      .take(2)
                                                      .join(', '),
                                                ),
                                              if (player.availabilityRadiusKm !=
                                                  null)
                                                _buildAvailChip(
                                                  Icons.radar,
                                                  '${player.availabilityRadiusKm} km',
                                                ),
                                              if (player.availabilityDays !=
                                                      null &&
                                                  player
                                                      .availabilityDays!
                                                      .isNotEmpty)
                                                _buildAvailChip(
                                                  Icons.calendar_today_outlined,
                                                  player
                                                              .availabilityDays!
                                                              .length ==
                                                          1
                                                      ? player
                                                            .availabilityDays!
                                                            .first
                                                      : '${player.availabilityDays!.first} → ${player.availabilityDays!.last}',
                                                ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (player.rating != null)
                                        Text(
                                          '★ ${player.rating!.toStringAsFixed(1)}',
                                          style: GoogleFonts.syne(
                                            color: _kAmber,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      if (isMember)
                                        // Déjà dans l'équipe
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _kCard,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: _kBorder2,
                                            ),
                                          ),
                                          child: Text(
                                            'Déjà membre',
                                            style: GoogleFonts.syne(
                                              color: _kMuted2,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        )
                                      else if (isInvited)
                                        // Invitation déjà envoyée → bouton Annuler
                                        GestureDetector(
                                          onTap: () async {
                                            final provider = context
                                                .read<TeamsProvider>();
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            final inv =
                                                localInvitations[player.id]!;
                                            final success = await provider
                                                .cancelInvitation(inv.id);
                                            if (success) {
                                              localInvitations.remove(
                                                player.id,
                                              );
                                            }
                                            setSheetState(() {});
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  success
                                                      ? 'Invitation annulée pour ${player.username}'
                                                      : 'Erreur lors de l\'annulation',
                                                ),
                                                backgroundColor: success
                                                    ? _kAmber
                                                    : _kRose,
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _kRose.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: _kRose.withValues(
                                                  alpha: 0.5,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              'Annuler',
                                              style: GoogleFonts.syne(
                                                color: _kRose,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        // Pas encore invité → bouton Inviter
                                        GestureDetector(
                                          onTap: () async {
                                            final provider = context
                                                .read<TeamsProvider>();
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            final created = await TeamsService
                                                .instance
                                                .sendInvitation(
                                                  teamId: teamId,
                                                  invitedUserId: player.id,
                                                  position: position.name,
                                                  slotIndex: slotIndex,
                                                );
                                            if (created != null) {
                                              localInvitations[player.id] =
                                                  created;
                                              provider.addSentInvitation(
                                                created,
                                              );
                                            }
                                            setSheetState(() {});
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  created != null
                                                      ? 'Invitation envoyée à ${player.username}'
                                                      : 'Erreur lors de l\'envoi',
                                                ),
                                                backgroundColor: created != null
                                                    ? _kAmber
                                                    : _kRose,
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _kAmber,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'Inviter',
                                              style: GoogleFonts.syne(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showApplicationsDialog(BuildContext context, OpenSlot openSlot) async {
    final teamsProvider = context.read<TeamsProvider>();
    await teamsProvider.loadReceivedApplications();

    if (!context.mounted) return;

    final applications = teamsProvider.receivedApplications
        .where((a) => a.openSlotId == openSlot.id)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (sheetCtx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    const SizedBox(height: 12),
                    Text(
                      'Candidatures (${applications.length})',
                      style: GoogleFonts.syne(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kWhite,
                      ),
                    ),
                  ],
                ),
              ),
              if (applications.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: _kMuted2,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune candidature pour le moment',
                        style: GoogleFonts.dmSans(color: _kMuted2),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: applications.length,
                    itemBuilder: (listCtx, index) {
                      final app = applications[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _kCard2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kBorder2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: _kAmberDim,
                                  backgroundImage:
                                      app.applicant.avatarUrl != null
                                      ? NetworkImage(app.applicant.avatarUrl!)
                                      : null,
                                  child: app.applicant.avatarUrl == null
                                      ? Text(
                                          app.applicant.username[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: _kAmber,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        app.applicant.username,
                                        style: GoogleFonts.syne(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: _kWhite,
                                        ),
                                      ),
                                      if (app.applicant.rating != null)
                                        Text(
                                          '⭐ ${app.applicant.rating!.toStringAsFixed(1)}',
                                          style: GoogleFonts.dmSans(
                                            color: _kMuted2,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (app.message != null &&
                                app.message!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _kBorder.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _kBorder2),
                                ),
                                child: Text(
                                  '"${app.message}"',
                                  style: GoogleFonts.dmSans(
                                    fontStyle: FontStyle.italic,
                                    color: _kMuted2,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    await teamsProvider.rejectApplication(
                                      app.id,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Candidature refusée'),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _kRoseDim,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _kRose.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.close,
                                          color: _kRose,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Refuser',
                                          style: GoogleFonts.syne(
                                            color: _kRose,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () async {
                                    await teamsProvider.acceptApplication(
                                      app.id,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Joueur ajouté à l\'équipe !',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _kSageDim,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _kSage.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check,
                                          color: _kSage,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Accepter',
                                          style: GoogleFonts.syne(
                                            color: _kSage,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
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
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllApplicationsDialog(BuildContext context) async {
    final teamsProvider = context.read<TeamsProvider>();
    await teamsProvider.loadReceivedApplications();

    if (!context.mounted) return;

    final applications = teamsProvider.receivedApplications;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (sheetCtx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.inbox, color: _kAmber),
                        const SizedBox(width: 8),
                        Text(
                          'Toutes les candidatures (${applications.length})',
                          style: GoogleFonts.syne(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _kWhite,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (applications.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: _kMuted2,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune candidature en attente',
                          style: GoogleFonts.dmSans(color: _kMuted2),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: applications.length,
                    itemBuilder: (listCtx, index) {
                      final app = applications[index];
                      // Trouver le slot correspondant
                      final openSlot = teamsProvider.myOpenSlots
                          .where((s) => s.id == app.openSlotId)
                          .firstOrNull;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _kCard2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kBorder2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: _kAmberDim,
                                  backgroundImage:
                                      app.applicant.avatarUrl != null
                                      ? NetworkImage(app.applicant.avatarUrl!)
                                      : null,
                                  child: app.applicant.avatarUrl == null
                                      ? Text(
                                          app.applicant.username[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: _kAmber,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        app.applicant.username,
                                        style: GoogleFonts.syne(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: _kWhite,
                                        ),
                                      ),
                                      if (openSlot != null)
                                        Text(
                                          'Pour : ${openSlot.position.displayName}',
                                          style: GoogleFonts.dmSans(
                                            color: _kMuted2,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (app.applicant.rating != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _kAmberDim,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '⭐ ${app.applicant.rating!.toStringAsFixed(1)}',
                                      style: GoogleFonts.dmSans(
                                        color: _kAmberSoft,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (app.message != null &&
                                app.message!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _kBorder.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _kBorder2),
                                ),
                                child: Text(
                                  '"${app.message}"',
                                  style: GoogleFonts.dmSans(
                                    fontStyle: FontStyle.italic,
                                    color: _kMuted2,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    await teamsProvider.rejectApplication(
                                      app.id,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Candidature refusée'),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _kRoseDim,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _kRose.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.close,
                                          color: _kRose,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Refuser',
                                          style: GoogleFonts.syne(
                                            color: _kRose,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () async {
                                    await teamsProvider.acceptApplication(
                                      app.id,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Joueur ajouté à l\'équipe !',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _kSageDim,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _kSage.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check,
                                          color: _kSage,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Accepter',
                                          style: GoogleFonts.syne(
                                            color: _kSage,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
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
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePositionDialog(BuildContext context, TeamMember member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _kBorder2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Changer la position de ${member.user.username}',
              style: GoogleFonts.syne(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kWhite,
              ),
            ),
            const SizedBox(height: 16),
            ...PlayerPosition.values.map(
              (position) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: member.position == position
                      ? _kAmberDim
                      : _kCard2,
                  child: Text(
                    position.shortName,
                    style: TextStyle(
                      color: member.position == position ? _kAmber : _kMuted2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  position.displayName,
                  style: GoogleFonts.syne(
                    color: _kWhite,
                    fontWeight: member.position == position
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                trailing: member.position == position
                    ? const Icon(Icons.check, color: _kAmber)
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  int newSlotIndex = member.slotIndex;
                  if (position == PlayerPosition.substitute &&
                      member.slotIndex < 5) {
                    newSlotIndex = 5;
                  } else if (position != PlayerPosition.substitute &&
                      member.slotIndex >= 5) {
                    switch (position) {
                      case PlayerPosition.goalkeeper:
                        newSlotIndex = 0;
                        break;
                      case PlayerPosition.defender:
                        newSlotIndex = 1;
                        break;
                      case PlayerPosition.midfielder:
                        newSlotIndex = 3;
                        break;
                      case PlayerPosition.forward:
                        newSlotIndex = 4;
                        break;
                      default:
                        break;
                    }
                  }
                  await context.read<TeamsProvider>().updateMemberPosition(
                    userId: member.user.id,
                    position: position,
                    slotIndex: newSlotIndex,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTeamNameDialog(BuildContext context) {
    final teamsProvider = context.read<TeamsProvider>();
    final controller = TextEditingController(
      text: teamsProvider.myTeam?.name ?? 'Mon Équipe',
    );
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _kBorder2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nom de l\'équipe',
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _kWhite,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: _kWhite),
                decoration: InputDecoration(
                  labelText: 'Nom',
                  labelStyle: const TextStyle(color: _kMuted2),
                  filled: true,
                  fillColor: _kCard2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBorder2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBorder2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kAmber),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(dialogCtx),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: _kCard2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kBorder2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Annuler',
                          style: GoogleFonts.syne(
                            fontWeight: FontWeight.w600,
                            color: _kMuted2,
                            fontSize: 13,
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
                        if (controller.text.trim().isNotEmpty) {
                          final currentMembers =
                              teamsProvider.myTeam?.members ?? [];
                          await teamsProvider.saveMyTeamComposition(
                            name: controller.text.trim(),
                            members: currentMembers
                                .map(
                                  (m) => MyTeamMemberInput(
                                    userId: m.user.id,
                                    position: m.position,
                                    slotIndex: m.slotIndex,
                                  ),
                                )
                                .toList(),
                          );
                        }
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kAmber, _kAmberD],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Enregistrer',
                          style: GoogleFonts.syne(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 13,
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

  /// Affiche un sélecteur d'heure avec des roulettes verticales
  Future<TimeOfDay?> _showTimePickerWithWheels(
    BuildContext context,
    TimeOfDay? initialTime,
  ) async {
    int selectedHour = initialTime?.hour ?? 8;
    int selectedMinute = initialTime?.minute ?? 0;

    return showDialog<TimeOfDay>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _kBorder2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sélectionner l\'heure',
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _kWhite,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Roulette des heures
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _kCard2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                            initialItem: selectedHour,
                          ),
                          itemExtent: 40,
                          onSelectedItemChanged: (index) {
                            selectedHour = index;
                          },
                          children: List.generate(
                            24,
                            (index) => Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: _kWhite,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        ':',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _kWhite,
                        ),
                      ),
                    ),
                    // Roulette des minutes
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _kCard2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                            initialItem: selectedMinute ~/ 5,
                          ),
                          itemExtent: 40,
                          onSelectedItemChanged: (index) {
                            selectedMinute = index * 5;
                          },
                          children: List.generate(
                            12, // 0, 5, 10, 15... 55
                            (index) => Center(
                              child: Text(
                                (index * 5).toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: _kWhite,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: _kCard2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kBorder2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Annuler',
                          style: GoogleFonts.syne(
                            fontWeight: FontWeight.w600,
                            color: _kMuted2,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(
                          context,
                          TimeOfDay(hour: selectedHour, minute: selectedMinute),
                        );
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kAmber, _kAmberD],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'OK',
                          style: GoogleFonts.syne(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 13,
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

  /// Affiche le dialogue pour configurer les préférences de recherche d'adversaire
  void _showSearchPreferencesDialog(BuildContext context) async {
    // États locaux pour les sélections
    final selectedDays = <String>{};
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    final selectedCities = <String>[];
    final cityController = TextEditingController();
    String? selectedSkillLevel;

    // Pré-remplir avec les valeurs existantes si disponibles
    if (_searchPreference != null) {
      if (_searchPreference!.preferredDays != null) {
        selectedDays.addAll(_searchPreference!.preferredDays!);
      }
      if (_searchPreference!.preferredTimeSlots != null &&
          _searchPreference!.preferredTimeSlots!.isNotEmpty) {
        // Parser le format "HH:mm-HH:mm"
        final timeSlot = _searchPreference!.preferredTimeSlots!.first;
        final parts = timeSlot.split('-');
        if (parts.length == 2) {
          final start = parts[0].split(':');
          final end = parts[1].split(':');
          if (start.length == 2 && end.length == 2) {
            startTime = TimeOfDay(
              hour: int.tryParse(start[0]) ?? 8,
              minute: int.tryParse(start[1]) ?? 0,
            );
            endTime = TimeOfDay(
              hour: int.tryParse(end[0]) ?? 20,
              minute: int.tryParse(end[1]) ?? 0,
            );
          }
        }
      }
      if (_searchPreference!.preferredLocations != null) {
        selectedCities.addAll(_searchPreference!.preferredLocations!);
      }
      // Capitaliser la première lettre du niveau pour correspondre aux options
      if (_searchPreference!.skillLevel != null &&
          _searchPreference!.skillLevel!.isNotEmpty) {
        selectedSkillLevel =
            _searchPreference!.skillLevel![0].toUpperCase() +
            _searchPreference!.skillLevel!.substring(1);
      }
    }

    final jours = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    final niveaux = ['Débutant', 'Intermédiaire', 'Confirmé', 'Expert'];

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: _kCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _kBorder2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.search, color: _kAmber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Préférences de recherche',
                          style: GoogleFonts.syne(
                            color: _kWhite,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Jours disponibles
                  Text(
                    'Jours disponibles *',
                    style: GoogleFonts.syne(
                      color: _kWhite,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: jours.map((jour) {
                      final isSelected = selectedDays.contains(jour);
                      return FilterChip(
                        label: Text(
                          jour,
                          style: GoogleFonts.syne(
                            fontSize: 12,
                            color: isSelected ? _kAmber : _kMuted2,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedDays.add(jour);
                            } else {
                              selectedDays.remove(jour);
                            }
                          });
                        },
                        selectedColor: _kAmberDim,
                        checkmarkColor: _kAmber,
                        backgroundColor: _kCard2,
                        side: BorderSide(
                          color: isSelected
                              ? _kAmber.withValues(alpha: 0.5)
                              : _kBorder2,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Plage horaire
                  Text(
                    'Plage horaire *',
                    style: GoogleFonts.syne(
                      color: _kWhite,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Heure de début
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await _showTimePickerWithWheels(
                              context,
                              startTime ?? const TimeOfDay(hour: 8, minute: 0),
                            );
                            if (picked != null) {
                              setState(() {
                                startTime = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _kCard2,
                              border: Border.all(color: _kBorder2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  startTime != null
                                      ? '${startTime!.hour.toString().padLeft(2, '0')}h${startTime!.minute.toString().padLeft(2, '0')}'
                                      : 'Début',
                                  style: TextStyle(
                                    color: startTime != null
                                        ? _kWhite
                                        : _kMuted2,
                                  ),
                                ),
                                const Icon(
                                  Icons.access_time,
                                  size: 20,
                                  color: _kMuted2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.arrow_forward, color: _kAmber),
                      const SizedBox(width: 16),
                      // Heure de fin
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await _showTimePickerWithWheels(
                              context,
                              endTime ?? const TimeOfDay(hour: 20, minute: 0),
                            );
                            if (picked != null) {
                              setState(() {
                                endTime = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _kCard2,
                              border: Border.all(color: _kBorder2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  endTime != null
                                      ? '${endTime!.hour.toString().padLeft(2, '0')}h${endTime!.minute.toString().padLeft(2, '0')}'
                                      : 'Fin',
                                  style: TextStyle(
                                    color: endTime != null ? _kWhite : _kMuted2,
                                  ),
                                ),
                                const Icon(
                                  Icons.access_time,
                                  size: 20,
                                  color: _kMuted2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Niveau de l'équipe
                  Text(
                    'Niveau de l\'équipe *',
                    style: GoogleFonts.syne(
                      color: _kWhite,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: niveaux.map((niveau) {
                      final isSelected = selectedSkillLevel == niveau;
                      return ChoiceChip(
                        label: Text(
                          niveau,
                          style: GoogleFonts.syne(
                            fontSize: 12,
                            color: isSelected ? _kAmber : _kMuted2,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            selectedSkillLevel = selected ? niveau : null;
                          });
                        },
                        selectedColor: _kAmberDim,
                        checkmarkColor: _kAmber,
                        backgroundColor: _kCard2,
                        side: BorderSide(
                          color: isSelected
                              ? _kAmber.withValues(alpha: 0.5)
                              : _kBorder2,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Villes
                  Text(
                    'Villes de déplacement *',
                    style: GoogleFonts.syne(
                      color: _kWhite,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Liste des villes ajoutées
                  if (selectedCities.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedCities.map((city) {
                        return Chip(
                          label: Text(
                            city,
                            style: GoogleFonts.dmSans(
                              color: _kWhite,
                              fontSize: 12,
                            ),
                          ),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 18,
                            color: _kMuted2,
                          ),
                          onDeleted: () {
                            setState(() {
                              selectedCities.remove(city);
                            });
                          },
                          backgroundColor: _kAmberDim,
                          side: BorderSide(
                            color: _kAmber.withValues(alpha: 0.3),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Champ pour ajouter une ville
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cityController,
                          style: const TextStyle(color: _kWhite),
                          decoration: InputDecoration(
                            hintText: 'Ajouter une ville',
                            hintStyle: const TextStyle(color: _kMuted2),
                            filled: true,
                            fillColor: _kCard2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: _kBorder2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: _kBorder2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: _kAmber),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              setState(() {
                                selectedCities.add(value.trim());
                                cityController.clear();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add, color: _kAmber),
                        onPressed: () {
                          final value = cityController.text.trim();
                          if (value.isNotEmpty) {
                            setState(() {
                              selectedCities.add(value);
                              cityController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Text(
                    '* Champs obligatoires',
                    style: GoogleFonts.dmSans(
                      color: _kMuted2,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: _kCard2,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _kBorder2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Annuler',
                              style: GoogleFonts.syne(
                                fontWeight: FontWeight.w600,
                                color: _kMuted2,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Validation
                            if (selectedDays.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Veuillez sélectionner au moins un jour',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            if (startTime == null || endTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Veuillez sélectionner une plage horaire',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            // Vérifier que l'heure de fin est après l'heure de début
                            final startMinutes =
                                startTime!.hour * 60 + startTime!.minute;
                            final endMinutes =
                                endTime!.hour * 60 + endTime!.minute;
                            if (endMinutes <= startMinutes) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'L\'heure de fin doit être après l\'heure de début',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            if (selectedSkillLevel == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Veuillez sélectionner le niveau de votre équipe',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            if (selectedCities.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Veuillez ajouter au moins une ville',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Formater la plage horaire
                            final timeSlot =
                                '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}-${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';

                            // Retourner les données
                            Navigator.pop(context, {
                              'days': selectedDays.toList(),
                              'timeSlots': [timeSlot],
                              'cities': selectedCities,
                              'skillLevel': selectedSkillLevel!.toLowerCase(),
                            });
                          },
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_kAmber, _kAmberD],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Valider',
                              style: GoogleFonts.syne(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 13,
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
        ),
      ),
    );

    // Si l'utilisateur a validé, activer le mode recherche
    if (result != null && mounted) {
      final provider = context.read<TeamsProvider>();
      final team = provider.currentDisplayedTeam;
      if (team == null) return;

      setState(() => _isLookingForOpponent = true);

      try {
        final searchPref = await TeamsService.instance.updateSearchPreferences(
          team.id,
          isLookingForOpponent: true,
          preferredDays: result['days'] as List<String>,
          preferredTimeSlots: result['timeSlots'] as List<String>,
          preferredLocations: result['cities'] as List<String>,
          skillLevel: result['skillLevel'] as String,
          description: _searchPreference?.description,
        );

        if (searchPref != null && mounted) {
          setState(() => _searchPreference = searchPref);
          _showSnackBar('✅ Équipe disponible pour un match', isSuccess: true);
        } else if (mounted) {
          setState(() => _isLookingForOpponent = false);
          _showSnackBar('Erreur lors de l\'activation', isSuccess: false);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLookingForOpponent = false);
          _showSnackBar('Erreur: $e', isSuccess: false);
        }
      }
    }
  }

  void _showPostMatchCommentSheet(MatchChallenge match) {
    if (!mounted) return;
    final teams = context.read<TeamsProvider>();
    final myTeam = teams.allTeams.firstWhere(
      (t) => t.id == match.challengerTeamId || t.id == match.challengedTeamId,
      orElse: () => teams.allTeams.first,
    );
    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostMatchCommentSheet(
        match: match,
        myTeam: myTeam,
        currentUserId: currentUserId,
      ),
    );
  }
}

class _ModernPitchPainter extends CustomPainter {
  final Color lineColor;
  _ModernPitchPainter(this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    // Bandes de gazon alternées
    final Paint stripePaint = Paint()..style = PaintingStyle.fill;
    const int stripeCount = 8;
    final double stripeWidth = size.width / stripeCount;
    for (int i = 0; i < stripeCount; i++) {
      stripePaint.color = i.isEven
          ? const Color(0xFF1E4A23)
          : const Color(0xFF194020);
      canvas.drawRect(
        Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, size.height),
        stripePaint,
      );
    }

    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Bordure du terrain
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Ligne médiane
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Cercle central
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height * 0.12,
      paint,
    );

    // Point central
    final centerPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 2, centerPaint);

    // Zones de but
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height * 0.25,
        size.width * 0.12,
        size.height * 0.5,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.88,
        size.height * 0.25,
        size.width * 0.12,
        size.height * 0.5,
      ),
      paint,
    );

    // Petites zones
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height * 0.35,
        size.width * 0.06,
        size.height * 0.3,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.94,
        size.height * 0.35,
        size.width * 0.06,
        size.height * 0.3,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ──────────────────────────────────────────────────────────────────────────────
// Notification Sheet — demandes de match en attente
// ──────────────────────────────────────────────────────────────────────────────

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  final Set<int> _loadingIds = {};

  @override
  Widget build(BuildContext context) {
    final teamsProvider = context.watch<TeamsProvider>();
    final challenges = teamsProvider.pendingChallenges;
    final invitations = teamsProvider.pendingInvitations;
    final totalCount = challenges.length + invitations.length;

    return Container(
      decoration: const BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _kBorder2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          // Header
          Row(
            children: [
              Text(
                'Notifications',
                style: GoogleFonts.syne(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kWhite,
                ),
              ),
              const Spacer(),
              if (totalCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kAmberDim,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Color(0x40FF7F2A), width: 1),
                  ),
                  child: Text(
                    '$totalCount',
                    style: const TextStyle(
                      color: _kAmber,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (totalCount == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'Aucune notification en attente',
                style: GoogleFonts.dmSans(color: _kMuted2, fontSize: 13),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (invitations.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'INVITATIONS D\'ÉQUIPE',
                        style: GoogleFonts.syne(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _kMuted2,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    ...invitations.map(
                      (inv) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildInvitationItem(
                          context,
                          inv,
                          teamsProvider,
                        ),
                      ),
                    ),
                  ],
                  if (challenges.isNotEmpty) ...[
                    if (invitations.isNotEmpty) const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'DÉFIS DE MATCH',
                        style: GoogleFonts.syne(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _kMuted2,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    ...challenges.asMap().entries.map(
                      (e) => Padding(
                        padding: EdgeInsets.only(
                          bottom: e.key < challenges.length - 1 ? 10 : 0,
                        ),
                        child: _buildChallengeItem(
                          context,
                          e.value,
                          teamsProvider,
                        ),
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

  Widget _buildInvitationItem(
    BuildContext context,
    TeamInvitation invitation,
    TeamsProvider teamsProvider,
  ) {
    final isLoading = _loadingIds.contains(-invitation.id);
    final positionLabels = {
      'goalkeeper': 'Gardien',
      'defender': 'Défenseur',
      'midfielder': 'Milieu',
      'forward': 'Attaquant',
      'substitute': 'Remplaçant',
    };
    final posLabel = positionLabels[invitation.position] ?? invitation.position;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0x1A3B82F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x333B82F6), width: 1),
                ),
                child: invitation.teamLogoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.network(
                          invitation.teamLogoUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          invitation.teamName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
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
                      invitation.teamName,
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _kWhite,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Invitation · ${invitation.invitingUsername}',
                      style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted2),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x1A3B82F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  posLabel,
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isLoading
                      ? null
                      : () async {
                          setState(() => _loadingIds.add(-invitation.id));
                          await teamsProvider.respondToInvitation(
                            invitationId: invitation.id,
                            accept: false,
                          );
                          if (mounted)
                            setState(() => _loadingIds.remove(-invitation.id));
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0x1AD4607A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x33D4607A)),
                    ),
                    child: Center(
                      child: Text(
                        'Refuser',
                        style: GoogleFonts.syne(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kRose,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: isLoading
                      ? null
                      : () async {
                          setState(() => _loadingIds.add(-invitation.id));
                          final success = await teamsProvider
                              .respondToInvitation(
                                invitationId: invitation.id,
                                accept: true,
                              );
                          if (mounted) {
                            setState(() => _loadingIds.remove(-invitation.id));
                            if (success && context.mounted)
                              Navigator.pop(context);
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _kAmberDim,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x33FF7F2A)),
                    ),
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _kAmber,
                              ),
                            )
                          : Text(
                              'Accepter',
                              style: GoogleFonts.syne(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kAmber,
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
    );
  }

  Widget _buildChallengeItem(
    BuildContext context,
    MatchChallenge challenge,
    TeamsProvider teamsProvider,
  ) {
    final isLoading = _loadingIds.contains(challenge.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + nom équipe + date
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kAmberDim,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0x33FF7F2A), width: 1),
                ),
                child: challenge.challengerTeamLogoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.network(
                          challenge.challengerTeamLogoUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          challenge.challengerTeamName[0].toUpperCase(),
                          style: const TextStyle(
                            color: _kAmber,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
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
                      challenge.challengerTeamName,
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _kWhite,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Défi reçu',
                      style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted2),
                    ),
                  ],
                ),
              ),
              if (challenge.proposedDate != null)
                Text(
                  DateFormat('d MMM', 'fr_FR').format(challenge.proposedDate!),
                  style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted2),
                ),
            ],
          ),
          // Message
          if (challenge.message != null && challenge.message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _kBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                challenge.message!,
                style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          // Lieu
          if (challenge.proposedLocation != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 12, color: _kMuted2),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    challenge.proposedLocation!,
                    style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Boutons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: isLoading
                    ? null
                    : () => _respond(context, challenge, false, teamsProvider),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _kRose, width: 1.5),
                  ),
                  child: Text(
                    'REFUSER',
                    style: GoogleFonts.syne(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      letterSpacing: 0.6,
                      color: _kRose,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isLoading
                    ? null
                    : () => _respond(context, challenge, true, teamsProvider),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kAmberSoft, _kAmberD],
                    ),
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33FF7F2A),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 50,
                          height: 14,
                          child: Center(
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _kNight,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          'ACCEPTER',
                          style: GoogleFonts.syne(
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.6,
                            color: _kNight,
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

  Future<void> _respond(
    BuildContext context,
    MatchChallenge challenge,
    bool accept,
    TeamsProvider teamsProvider,
  ) async {
    setState(() => _loadingIds.add(challenge.id));
    final result = await TeamsService.instance.respondToChallenge(
      challenge.id,
      accept: accept,
    );
    if (!mounted) return;
    setState(() => _loadingIds.remove(challenge.id));
    if (result != null) {
      teamsProvider.loadPendingChallenges();
      if (accept) teamsProvider.loadMyTeam();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Défi accepté !' : 'Défi refusé'),
          backgroundColor: accept ? Colors.green : Colors.grey[700],
        ),
      );
    }
  }
}

// ── Post-match comment sheet ───────────────────────────────────────────────────

class _PostMatchCommentSheet extends StatefulWidget {
  final MatchChallenge match;
  final TeamDetail myTeam;
  final int? currentUserId;

  const _PostMatchCommentSheet({
    required this.match,
    required this.myTeam,
    this.currentUserId,
  });

  @override
  State<_PostMatchCommentSheet> createState() => _PostMatchCommentSheetState();
}

class _PostMatchCommentSheetState extends State<_PostMatchCommentSheet> {
  int _step = 0; // 0 = ma team, 1 = équipe adverse
  bool _loading = false;
  List<TeamMember> _opponentMembers = [];
  bool _loadingOpponent = true;

  // controllers & absences : indexed by userId
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, bool> _absences = {};

  @override
  void initState() {
    super.initState();
    final filtered = widget.myTeam.members
        .where((m) => m.user.id != widget.currentUserId)
        .toList();
    _initControllers(filtered);
    _loadOpponentMembers();
  }

  void _initControllers(List<TeamMember> members) {
    for (final m in members) {
      if (!_controllers.containsKey(m.user.id)) {
        _controllers[m.user.id] = TextEditingController(text: '👍 Bon match !');
      }
      _absences[m.user.id] ??= false;
    }
  }

  Future<void> _loadOpponentMembers() async {
    final match = widget.match;
    final myTeamId = widget.myTeam.id;
    final opponentId = match.challengerTeamId == myTeamId
        ? match.challengedTeamId
        : match.challengerTeamId;

    final members = await TeamsService.instance.fetchPublicTeamMembers(
      opponentId,
    );
    if (mounted) {
      final filtered = members
          .where((m) => m.user.id != widget.currentUserId)
          .toList();
      setState(() {
        _opponentMembers = filtered;
        _loadingOpponent = false;
        _initControllers(filtered);
      });
    }
  }

  Future<void> _submitStep() async {
    setState(() => _loading = true);
    final members = _step == 0
        ? widget.myTeam.members
              .where((m) => m.user.id != widget.currentUserId)
              .toList()
        : _opponentMembers;
    final comments = members.map((m) {
      return {
        'target_user_id': m.user.id,
        'content': _controllers[m.user.id]?.text.trim().isEmpty == true
            ? null
            : _controllers[m.user.id]?.text.trim(),
        'is_absent': _absences[m.user.id] ?? false,
      };
    }).toList();

    final ok = await TeamsService.instance.submitMatchComments(
      widget.match.id,
      comments.cast<Map<String, dynamic>>(),
    );

    setState(() => _loading = false);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'envoi des commentaires'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (_step == 0) {
      setState(() => _step = 1);
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMyTeamStep = _step == 0;
    final members = isMyTeamStep
        ? widget.myTeam.members
              .where((m) => m.user.id != widget.currentUserId)
              .toList()
        : _opponentMembers;
    final title = isMyTeamStep ? 'Mon équipe' : 'Équipe adverse';
    final subtitle = isMyTeamStep
        ? 'Laisse un commentaire sur tes coéquipiers'
        : 'Laisse un commentaire sur les joueurs adverses';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _kBorder2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _kAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_step + 1}/2',
                      style: GoogleFonts.syne(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kAmber,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.syne(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kWhite,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: _kMuted2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder2),
            // Liste joueurs
            Expanded(
              child: (!isMyTeamStep && _loadingOpponent)
                  ? const Center(
                      child: CircularProgressIndicator(color: _kAmber),
                    )
                  : ListView.separated(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: members.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _buildPlayerCard(members[i]),
                    ),
            ),
            // Bouton suivant / terminer
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              child: GestureDetector(
                onTap: _loading ? null : _submitStep,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: _loading ? _kBorder2 : _kAmber,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _step == 0 ? 'Équipe adverse →' : 'Terminer',
                          style: GoogleFonts.syne(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _suggestions = [
    '👍 Bon match !',
    '🔥 Très bonne perf',
    '💪 Solidaire',
    '🎯 Précis',
    '⬆️ En progrès',
  ];

  Widget _buildSuggestions(int userId) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _suggestions.map((s) {
          return GestureDetector(
            onTap: () {
              final ctrl = _controllers[userId];
              if (ctrl != null) {
                ctrl.text = s;
                ctrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: s.length),
                );
              }
              setState(() {});
            },
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _kCard2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kBorder2),
              ),
              child: Text(
                s,
                style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted2),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlayerCard(TeamMember member) {
    final isAbsent = _absences[member.user.id] ?? false;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAbsent ? _kRose.withValues(alpha: 0.4) : _kBorder2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfilePage(
                      userBasicInfo: UserBasicInfo(
                        id: member.user.id,
                        username: member.user.username,
                        avatarUrl: member.user.avatarUrl,
                        preferredPosition: member.user.preferredPosition,
                        rating: member.user.rating,
                      ),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _kBorder2,
                        shape: BoxShape.circle,
                        image: member.user.avatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(member.user.avatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: member.user.avatarUrl == null
                          ? const Icon(
                              Icons.person_outline,
                              size: 20,
                              color: _kMuted2,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.user.username,
                          style: GoogleFonts.syne(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kWhite,
                          ),
                        ),
                        Text(
                          member.position.displayName,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: _kMuted2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Toggle absent
              GestureDetector(
                onTap: () =>
                    setState(() => _absences[member.user.id] = !isAbsent),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isAbsent ? _kRose.withValues(alpha: 0.2) : _kBorder2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAbsent ? _kRose : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAbsent
                            ? Icons.warning_rounded
                            : Icons.check_circle_outline,
                        size: 12,
                        color: isAbsent ? _kRose : _kMuted2,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAbsent ? 'Absent' : 'Présent',
                        style: GoogleFonts.syne(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isAbsent ? _kRose : _kMuted2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controllers[member.user.id],
            style: GoogleFonts.dmSans(fontSize: 12, color: _kWhite),
            maxLines: 2,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'Commentaire (optionnel)…',
              hintStyle: GoogleFonts.dmSans(fontSize: 12, color: _kMuted2),
              counterStyle: GoogleFonts.dmSans(fontSize: 10, color: _kMuted2),
              filled: true,
              fillColor: _kCard,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _kBorder2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _kBorder2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _kAmber),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildSuggestions(member.user.id),
        ],
      ),
    );
  }
}
