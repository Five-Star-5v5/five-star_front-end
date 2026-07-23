import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:five_star_5v5/theme/app_typography.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import '../theme_config/colors_config.dart';
import '../theme/app_colors.dart';
import '../widgets/kobeta_logo.dart';
import '../widgets/city_autocomplete_field.dart';
import '../widgets/coach_mark.dart';
import '../services/onboarding_prefs.dart';
import '../providers/teams_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/auth_provider.dart';
import '../services/teams_service.dart';
import 'team_chat_page.dart';
import 'match_chat_page.dart';
import 'discover_teams_page.dart';
import 'find_opponents_page.dart';
// import 'public_matches_page.dart'; // SECTION MATCHS OUVERTS
import 'user_profile_page.dart';
import '../main_screen.dart';
import '../services/friends_service.dart' show UserBasicInfo;

Widget _buildAvailChip(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.amberDim,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 9, color: AppColors.amber),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: AppColors.amber,
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

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const double _playerAvatarRadius = 28;

  bool _isLookingForOpponent = false;
  bool _isLoadingSearchPrefs = false;
  TeamSearchPreference? _searchPreference;
  int? _lastLoadedTeamId;
  List<MatchChallenge> _upcomingMatches = [];
  Map<int, int> _unreadMatchMessages = {};
  // SECTION MATCHS OUVERTS — désactivée, décommenter pour réactiver
  // List<PublicMatch> _publicMatches = [];
  late AnimationController _loadingAnimationController;
  Timer? _matchPollingTimer;

  // ── Tuto guidé (première visite de l'onglet Équipe) ──────────────────────
  final _tourTeamCardsKey = GlobalKey();
  final _tourSearchToggleKey = GlobalKey();
  final _tourPitchKey = GlobalKey();
  final _tourSubsKey = GlobalKey();
  final _tourMatchesKey = GlobalKey();
  bool _tourStarted = false;

  /// Garde-fou de réentrance : le timer peut refirer pendant que la lecture
  /// asynchrone de la préférence est encore en cours.
  bool _tourChecking = false;
  Timer? _tourRetryTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

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
      // _loadPublicMatches(); // SECTION MATCHS OUVERTS

      // Le tuto ne peut démarrer qu'une fois les cibles réellement rendues.
      // On sonde à intervalle court plutôt que d'attendre une notification du
      // provider, qui peut n'arriver que plusieurs secondes plus tard.
      _maybeStartTeamTour();
      _tourRetryTimer = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => _maybeStartTeamTour(),
      );
    });

    _matchPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadUpcomingMatches();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUpcomingMatches();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _matchPollingTimer?.cancel();
    _tourRetryTimer?.cancel();
    _loadingAnimationController.dispose();
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
    _maybeStartTeamTour();
  }

  /// Lance le tuto guidé à la première visite de l'onglet Équipe.
  ///
  /// Appelé à chaque mise à jour du provider : tant que les cibles ne sont pas
  /// rendues (équipe encore en chargement), on repart sans rien marquer, et
  /// une prochaine mise à jour retentera.
  Future<void> _maybeStartTeamTour() async {
    if (_tourStarted || _tourChecking) return;
    if (_tourTeamCardsKey.currentContext == null) return;

    _tourChecking = true;
    try {
      if (await OnboardingPrefs.hasSeenTeamTour()) {
        _tourStarted = true; // inutile de relire la préférence ensuite
        _tourRetryTimer?.cancel();
        return;
      }
      if (!mounted) return;
      _tourStarted = true;
      _tourRetryTimer?.cancel();

      await showCoachMarks(context, [
        CoachMarkStep(
          key: _tourTeamCardsKey,
          title: 'Tes équipes',
          body:
              'Fais défiler pour passer d\'une équipe à l\'autre. '
              'La dernière carte te permet d\'en rejoindre une nouvelle.',
        ),
        CoachMarkStep(
          key: _tourSearchToggleKey,
          title: 'Disponible pour un match',
          body:
              'Active ce bouton pour que ton équipe soit visible '
              'par celles qui cherchent un adversaire.',
        ),
        CoachMarkStep(
          key: _tourPitchKey,
          title: 'Ta composition',
          body:
              'Place tes joueurs sur le terrain. Touche un emplacement '
              'libre pour y installer un membre de l\'équipe.',
        ),
        CoachMarkStep(
          key: _tourSubsKey,
          title: 'Les remplaçants',
          body:
              'Les membres qui ne sont pas encore sur le terrain '
              'attendent ici.',
        ),
        CoachMarkStep(
          key: _tourMatchesKey,
          title: 'Tes matchs à venir',
          body:
              'Tes prochaines rencontres s\'affichent ici. '
              'Utilise « Trouver » pour défier une autre équipe.',
        ),
      ]);

      await OnboardingPrefs.markTeamTourSeen();
    } finally {
      _tourChecking = false;
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

  // SECTION MATCHS OUVERTS — désactivée, décommenter pour réactiver
  // Future<void> _loadPublicMatches() async {
  //   try {
  //     final matches = await TeamsService.instance.getPublicMatches();
  //     if (mounted) setState(() => _publicMatches = matches);
  //   } catch (_) {}
  // }

  Future<void> _loadUpcomingMatches() async {
    final provider = context.read<TeamsProvider>();
    final team = provider.currentDisplayedTeam;
    if (team == null || !provider.isPartOfCurrentTeam) return;
    try {
      final results = await Future.wait([
        TeamsService.instance.getTeamMatches(team.id, status: 'accepted'),
        TeamsService.instance.getAllUnreadCounts(),
      ]);
      if (mounted) {
        setState(() {
          _upcomingMatches = results[0] as List<MatchChallenge>;
          _unreadMatchMessages = results[1] as Map<int, int>;
        });
      }
    } catch (_) {}
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
                  colors: [AppColors.amberSoft, AppColors.amberD],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.amber.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: SvgPicture.string(
                buildKobetaLogoSvg(
                  kLogoOrangePaths,
                  '#0B0D11',
                  28,
                  'loadingHex',
                ),
                width: 50,
                height: 50,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Kobeta',
            style: AppTypography.display(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Préparation en cours...',
            style: AppTypography.body(
              fontSize: 13,
              color: AppColors.muted2,
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
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
            left: BorderSide(color: AppColors.border, width: 1),
            right: BorderSide(color: AppColors.border, width: 1),
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
                  color: AppColors.border2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.amber,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.display(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
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
                  style: AppTypography.body(
                    fontSize: 13,
                    color: AppColors.muted2,
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
        color: _isLookingForOpponent
            ? AppColors.amber.withValues(alpha: 0.08)
            : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isLookingForOpponent
              ? AppColors.amber.withValues(alpha: 0.35)
              : AppColors.border2,
          width: 1.5,
        ),
        boxShadow: _isLookingForOpponent
            ? [
                BoxShadow(
                  color: AppColors.amber.withValues(alpha: 0.14),
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
                    color: _isLookingForOpponent
                        ? AppColors.amberDim
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isLookingForOpponent
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: _isLookingForOpponent
                        ? AppColors.amber
                        : AppColors.muted2,
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
                        style: AppTypography.display(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.04 * 13,
                          color: _isLookingForOpponent
                              ? AppColors.amber
                              : AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _isLookingForOpponent
                            ? 'Votre équipe est visible par les équipes qui cherchent un adversaire'
                            : 'Activez pour apparaître dans les recherches',
                        style: AppTypography.body(
                          fontSize: 11,
                          color: AppColors.muted2,
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
                      color: AppColors.amber,
                    ),
                  )
                else
                  Switch.adaptive(
                    value: _isLookingForOpponent,
                    onChanged: _toggleSearchMode,
                    activeThumbColor: AppColors.night,
                    activeTrackColor: AppColors.amber,
                  ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _showInfoModal('Publiez un match', [
                'Publiez un match et laissez une autre équipe le rejoindre. Vous créez l\'offre, une équipe adverse peut donc vous défier.',
                'Seul le capitaine de l\'équipe peut créer un match. Nous vous conseillons d\'indiquer une plage horaire large afin d\'augmenter vos chances de trouver un adversaire.',
                'Une fois que la demande de défi sera envoyée par l\'adversaire, vous serez libre de l\'accepter ou de la décliner. Une fois le défi accepté, il s\'affichera ici dans « Matchs à venir » et vous aurez accès à un chat pour vous organiser avec l\'équipe adverse.',
                '--> Recommandation : trouvez d\'abord un adversaire et fixez l\'horaire avant de réserver et payer un terrain, afin d\'éviter toute dépense inutile.',
              ]),
              child: Icon(
                Icons.info_outline,
                size: 14,
                color: _isLookingForOpponent
                    ? AppColors.amber.withValues(alpha: 0.65)
                    : AppColors.muted2.withValues(alpha: 0.6),
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
                  style: AppTypography.display(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.04 * 13,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amberDim,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: AppColors.amber.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_upcomingMatches.length}',
                    style: const TextStyle(
                      color: AppColors.amber,
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
                      '--> Par exemple, si une équipe a créé un match, vous pouvez répondre à son annonce et proposer de jouer contre elle.',
                      '--> Une fois la demande acceptée, une conversation s’ouvre pour organiser les détails de la rencontre (horaire, lieu, etc.).',
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppColors.amber.withValues(alpha: 0.55),
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
                    style: AppTypography.display(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.amber,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_upcomingMatches.isEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/logos/pitchball.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.65),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_soccer_outlined,
                            size: 28,
                            color: AppColors.muted2,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aucun match à venir',
                            style: AppTypography.display(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Défiez une équipe pour planifier un match',
                            style: AppTypography.body(
                              fontSize: 11,
                              color: AppColors.muted2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._upcomingMatches.map(
            (match) => _buildMatchCard(match, myTeamId, isDarkMode, isOwner),
          ),
      ],
    );
  }

  // ─── SECTION MATCHS OUVERTS — désactivée ────────────────────────────────────
  // Pour réactiver : décommenter ce bloc + la variable _publicMatches,
  // _loadPublicMatches() et son appel dans initState, et _buildOpenMatchesSection()
  // dans le build.
  //
  // Widget _buildOpenMatchesSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const SizedBox(height: 20),
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Row(
  //             children: [
  //               Text(
  //                 'MATCHS OUVERTS',
  //                 style: AppTypography.display(
  //                   fontSize: 13,
  //                   fontWeight: FontWeight.w700,
  //                   letterSpacing: 0.04 * 13,
  //                   color: AppColors.white,
  //                 ),
  //               ),
  //               if (_publicMatches.isNotEmpty) ...[
  //                 const SizedBox(width: 8),
  //                 Container(
  //                   padding: const EdgeInsets.symmetric(
  //                     horizontal: 8,
  //                     vertical: 3,
  //                   ),
  //                   decoration: BoxDecoration(
  //                     color: const Color(0x1C4CAF82),
  //                     borderRadius: BorderRadius.circular(100),
  //                     border: Border.all(
  //                       color: const Color(0xFF4CAF82).withValues(alpha: 0.25),
  //                       width: 1,
  //                     ),
  //                   ),
  //                   child: Text(
  //                     '${_publicMatches.length}',
  //                     style: const TextStyle(
  //                       color: Color(0xFF4CAF82),
  //                       fontWeight: FontWeight.w700,
  //                       fontSize: 10,
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ],
  //           ),
  //           GestureDetector(
  //             onTap: () => Navigator.push(
  //               context,
  //               MaterialPageRoute(builder: (_) => const PublicMatchesPage()),
  //             ),
  //             child: Text(
  //               'Voir tout →',
  //               style: AppTypography.display(
  //                 fontSize: 12,
  //                 fontWeight: FontWeight.w600,
  //                 color: AppColors.amber,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 10),
  //       if (_publicMatches.isEmpty)
  //         Container(
  //           width: double.infinity,
  //           padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
  //           decoration: BoxDecoration(
  //             color: AppColors.card,
  //             borderRadius: BorderRadius.circular(14),
  //             border: Border.all(color: AppColors.border, width: 1),
  //           ),
  //           child: Column(
  //             children: [
  //               Icon(Icons.people_outline, size: 24, color: AppColors.muted2),
  //               const SizedBox(height: 6),
  //               Text(
  //                 'Aucun match ouvert pour le moment',
  //                 style: AppTypography.body(fontSize: 12, color: AppColors.muted2),
  //               ),
  //             ],
  //           ),
  //         )
  //       else
  //         SizedBox(
  //           height: 160,
  //           child: ListView.separated(
  //             scrollDirection: Axis.horizontal,
  //             itemCount: _publicMatches.length,
  //             separatorBuilder: (context, i) => const SizedBox(width: 10),
  //             itemBuilder: (_, i) =>
  //                 _buildPublicMatchPreviewCard(_publicMatches[i]),
  //           ),
  //         ),
  //     ],
  //   );
  // }
  //
  // Widget _buildPublicMatchPreviewCard(PublicMatch match) {
  //   final openSlots = match.totalOpenSlots;
  //   final sageColor = const Color(0xFF4CAF82);
  //   return GestureDetector(
  //     onTap: () => Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (_) => const PublicMatchesPage()),
  //     ),
  //     child: Container(
  //       width: 210,
  //       padding: const EdgeInsets.all(12),
  //       decoration: BoxDecoration(
  //         color: AppColors.card,
  //         borderRadius: BorderRadius.circular(14),
  //         border: Border.all(color: AppColors.border, width: 1),
  //       ),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               _buildMiniTeamLogo(match.challengerTeam),
  //               const Spacer(),
  //               Text(
  //                 'VS',
  //                 style: AppTypography.display(
  //                   fontSize: 10,
  //                   fontWeight: FontWeight.w800,
  //                   letterSpacing: 1.5,
  //                   color: AppColors.muted2,
  //                 ),
  //               ),
  //               const Spacer(),
  //               _buildMiniTeamLogo(match.challengedTeam),
  //             ],
  //           ),
  //           const SizedBox(height: 8),
  //           Text(
  //             '${match.challengerTeam.name.split(' ').first} — ${match.challengedTeam.name.split(' ').first}',
  //             style: AppTypography.display(
  //               fontSize: 11,
  //               fontWeight: FontWeight.w700,
  //               color: AppColors.white,
  //             ),
  //             maxLines: 1,
  //             overflow: TextOverflow.ellipsis,
  //           ),
  //           const SizedBox(height: 6),
  //           if (match.proposedDate != null)
  //             Row(
  //               children: [
  //                 const Icon(Icons.calendar_today, size: 10, color: AppColors.muted2),
  //                 const SizedBox(width: 4),
  //                 Text(
  //                   DateFormat('d MMM • HH:mm', 'fr_FR').format(match.proposedDate!),
  //                   style: AppTypography.body(fontSize: 10, color: AppColors.muted2),
  //                 ),
  //               ],
  //             ),
  //           const Spacer(),
  //           Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //             decoration: BoxDecoration(
  //               color: sageColor.withValues(alpha: 0.12),
  //               borderRadius: BorderRadius.circular(8),
  //               border: Border.all(color: sageColor.withValues(alpha: 0.3), width: 1),
  //             ),
  //             child: Row(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Icon(Icons.person_add_outlined, size: 10, color: sageColor),
  //                 const SizedBox(width: 4),
  //                 Text(
  //                   '$openSlots poste${openSlots > 1 ? 's' : ''} libre${openSlots > 1 ? 's' : ''}',
  //                   style: AppTypography.display(
  //                     fontSize: 9,
  //                     fontWeight: FontWeight.w700,
  //                     color: sageColor,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  //
  // Widget _buildMiniTeamLogo(PublicMatchTeamInfo team) {
  //   return Container(
  //     width: 34,
  //     height: 34,
  //     decoration: BoxDecoration(
  //       color: AppColors.amberDim,
  //       borderRadius: BorderRadius.circular(10),
  //       border: Border.all(color: AppColors.amber.withValues(alpha: 0.2), width: 1),
  //     ),
  //     child: team.logoUrl != null
  //         ? ClipRRect(
  //             borderRadius: BorderRadius.circular(9),
  //             child: Image.network(team.logoUrl!, fit: BoxFit.cover),
  //           )
  //         : Center(
  //             child: Text(
  //               team.name[0].toUpperCase(),
  //               style: const TextStyle(
  //                 color: AppColors.amber,
  //                 fontWeight: FontWeight.w800,
  //                 fontSize: 14,
  //               ),
  //             ),
  //           ),
  //   );
  // }
  // ─────────────────────────────────────────────────────────────────────────────

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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.amber.withValues(alpha: 0.06),
            blurRadius: 26,
            spreadRadius: -6,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A2C37), Color(0xFF16181E)],
              stops: [0.0, 0.8],
            ),
            border: Border.all(color: AppColors.border2, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 11, 11, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Barre haute : statut + chat ──
                    Row(
                      children: [
                        _buildMatchStatusBadge(match, hasSubmitted, isDarkMode),
                        const Spacer(),
                        _buildMatchChatButton(match, myTeamId, isDarkMode),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // ── Affiche du match : équipe vs équipe ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildMatchTeamSide(
                            name: isChallenger
                                ? match.challengerTeamName
                                : match.challengedTeamName,
                            logoUrl: isChallenger
                                ? match.challengerTeamLogoUrl
                                : match.challengedTeamLogoUrl,
                            isMine: true,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: AppColors.border2,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'VS',
                              style: AppTypography.display(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.08 * 11,
                                color: AppColors.muted2,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _buildMatchTeamSide(
                            name: opponentName,
                            logoUrl: opponentLogo,
                            isMine: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        isChallenger ? 'Défi envoyé' : 'Défi reçu',
                        style: AppTypography.body(
                          fontSize: 10,
                          letterSpacing: 0.04 * 10,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: AppColors.border,
                    ),
                    const SizedBox(height: 12),
                    // Infos du match
                    if (match.proposedDate != null ||
                        match.proposedLocation != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (match.proposedDate != null)
                            _buildMatchInfoChip(
                              Icons.calendar_today,
                              _formatMatchDate(match.proposedDate!),
                            ),
                          if (match.proposedDate != null &&
                              match.proposedLocation != null)
                            const SizedBox(height: 6),
                          if (match.proposedLocation != null)
                            _buildMatchInfoChip(
                              Icons.location_on,
                              match.proposedLocation!,
                              maxLines: 2,
                            ),
                        ],
                      ),
                    const SizedBox(height: 12),

                    // Afficher le score de l'adversaire s'il a soumis et que je n'ai pas soumis
                    if (opponentSubmittedScore != null && !hasSubmitted) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
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
                                color: isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.white,
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
                                            color: Colors.blue.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
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
                                            color: Colors.red.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
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
                                        style: AppTypography.display(
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
                                        style: AppTypography.display(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                          letterSpacing: 0.06 * 10,
                                          color: AppColors.white,
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
                                  style: AppTypography.body(
                                    fontSize: 10,
                                    color: AppColors.muted2,
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
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                    // Owner — score pas encore soumis (match à jouer)
                    else if (isOwner) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card2,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                isChallenger
                                    ? match.challengerTeamName
                                    : match.challengedTeamName,
                                style: AppTypography.display(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: AppColors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Text(
                                '? – ?',
                                style: AppTypography.display(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: AppColors.muted2,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                opponentName,
                                style: AppTypography.display(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: AppColors.white,
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
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'En attente que le capitaine enregistre le résultat.',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
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
                          if (!hasSubmitted &&
                              opponentSubmittedScore == null) ...[
                            GestureDetector(
                              onTap: () =>
                                  _showSubmitScoreDialog(match, myTeamId),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.amberSoft,
                                      AppColors.amberD,
                                    ],
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
                                  style: AppTypography.display(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                    letterSpacing: 0.06 * 10,
                                    color: AppColors.night,
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
                                border: Border.all(
                                  color: AppColors.border2,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                'ANNULER',
                                style: AppTypography.display(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                  letterSpacing: 0.06 * 10,
                                  color: AppColors.muted2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Barre d'accent amber (bord gauche)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.amber, AppColors.amberD],
                    ),
                  ),
                ),
              ),
              // Liseré lumineux sur le bord haut (« éclairé du dessus »)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.16),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Un côté de l'affiche de match : blason + nom d'équipe.
  /// [isMine] met en avant l'équipe du user (anneau + halo amber).
  Widget _buildMatchTeamSide({
    required String name,
    required String? logoUrl,
    required bool isMine,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isMine
                  ? [
                      AppColors.amber.withValues(alpha: 0.24),
                      AppColors.amberD.withValues(alpha: 0.06),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.10),
                      Colors.white.withValues(alpha: 0.02),
                    ],
            ),
            border: Border.all(
              color: isMine
                  ? AppColors.amber.withValues(alpha: 0.45)
                  : AppColors.border2,
              width: 1.5,
            ),
            boxShadow: isMine
                ? [
                    BoxShadow(
                      color: AppColors.amber.withValues(alpha: 0.18),
                      blurRadius: 14,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: logoUrl != null
              ? ClipOval(child: Image.network(logoUrl, fit: BoxFit.cover))
              : Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: AppTypography.display(
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                      color: isMine ? AppColors.amber : AppColors.white,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          name.toUpperCase(),
          style: AppTypography.display(
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.06 * 10,
            color: isMine ? AppColors.white : AppColors.muted2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Petite pill (date, lieu) — style premium pour la card de match.
  Widget _buildMatchInfoChip(IconData icon, String label, {int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: AppColors.amber.withValues(alpha: 0.16),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.amber),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: AppTypography.body(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
      bgColor = AppColors.rose.withValues(alpha: 0.12);
      textColor = AppColors.rose;
      text = 'Conflit';
      icon = Icons.warning;
    } else if (hasSubmitted) {
      bgColor = AppColors.amberDim;
      textColor = AppColors.amber;
      text = 'En attente';
      icon = Icons.hourglass_empty;
    } else {
      bgColor = AppColors.sage.withValues(alpha: 0.12);
      textColor = AppColors.sage;
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
              color: AppColors.amberDim,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: AppColors.amber.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.amber,
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
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enregistrer le résultat',
                  style: AppTypography.display(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Entrez le score du match contre $opponentName',
                  style: AppTypography.body(
                    fontSize: 13,
                    color: AppColors.muted2,
                  ),
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
                            style: AppTypography.body(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.muted2,
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
                              color: AppColors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: const TextStyle(
                                color: AppColors.muted2,
                              ),
                              filled: true,
                              fillColor: AppColors.card2,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.amber,
                                ),
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
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            opponentName,
                            style: AppTypography.body(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.muted2,
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
                              color: AppColors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: const TextStyle(
                                color: AppColors.muted2,
                              ),
                              filled: true,
                              fillColor: AppColors.card2,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.border2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.amber,
                                ),
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
                    color: AppColors.amberDim,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'L\'adversaire devra confirmer ce score pour qu\'il soit validé.',
                          style: AppTypography.body(
                            color: AppColors.amberSoft,
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
                            color: AppColors.card2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Annuler',
                            style: AppTypography.display(
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted2,
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
                              colors: [AppColors.amber, AppColors.amberD],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Valider',
                            style: AppTypography.display(
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
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Valider le score',
                style: AppTypography.display(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Confirmez-vous que ce score est correct ?',
                style: AppTypography.body(
                  fontSize: 13,
                  color: AppColors.muted2,
                ),
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
                          color: AppColors.card2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Annuler',
                          style: AppTypography.display(
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted2,
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
                            colors: [AppColors.amber, AppColors.amberD],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Valider',
                          style: AppTypography.display(
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
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Contester le score',
                style: AppTypography.display(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Si vous contestez ce score, le match sera déclaré nul (0-0).\n\n'
                'Êtes-vous sûr de vouloir contester ?',
                style: AppTypography.body(
                  fontSize: 13,
                  color: AppColors.muted2,
                ),
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
                          color: AppColors.card2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Annuler',
                          style: AppTypography.display(
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted2,
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
                          color: AppColors.rose,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Contester',
                          style: AppTypography.display(
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
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Annuler le match',
                style: AppTypography.display(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Êtes-vous sûr de vouloir annuler le match contre ${match.getOpponentName(_getMyTeamIdFromMatch(match))} ?\n\n'
                'Cette action ne peut pas être annulée.',
                style: AppTypography.body(
                  fontSize: 13,
                  color: AppColors.muted2,
                ),
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
                          color: AppColors.card2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Non',
                          style: AppTypography.display(
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted2,
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
                          color: AppColors.rose,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Oui, annuler',
                          style: AppTypography.display(
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
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quitter l\'équipe',
                  style: AppTypography.display(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Êtes-vous sûr de vouloir quitter "${team.name}" ?\n\n'
                  'Vous ne recevrez plus les messages de cette équipe et ne pourrez plus participer aux matchs.',
                  style: AppTypography.body(
                    fontSize: 13,
                    color: AppColors.muted2,
                  ),
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
                            color: AppColors.card2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Annuler',
                            style: AppTypography.display(
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted2,
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
                            color: AppColors.rose,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Quitter',
                            style: AppTypography.display(
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
      backgroundColor: AppColors.bg,
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
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border2),
                    ),
                    child: const Icon(
                      Icons.notifications_none_outlined,
                      color: AppColors.muted2,
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
                          color: AppColors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.night,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            teamsProvider.totalNotificationsCount > 9
                                ? '9+'
                                : '${teamsProvider.totalNotificationsCount}',
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
                    backgroundColor: AppColors.amber,
                    backgroundImage: user?.avatarUrl != null
                        ? NetworkImage(user!.avatarUrl!)
                        : null,
                    child: user?.avatarUrl == null
                        ? Text(
                            initial,
                            style: const TextStyle(
                              color: AppColors.night,
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
                  color: AppColors.amber,
                  onRefresh: () => teamsProvider.loadMyTeam(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // ── Team cards (scrollable) ─────────────────────
                          KeyedSubtree(
                            key: _tourTeamCardsKey,
                            child: _buildTeamHeader(
                              context: context,
                              teamsProvider: teamsProvider,
                              titleColor: titleColor,
                              isDarkMode: isDarkMode,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Widget pour activer le mode recherche d'adversaire
                          if (teamsProvider.isCurrentTeamMine &&
                              teamsProvider.currentDisplayedTeam != null)
                            KeyedSubtree(
                              key: _tourSearchToggleKey,
                              child: _buildSearchModeToggle(isDarkMode),
                            ),
                          const SizedBox(height: 12),
                          if (allTeams.isEmpty)
                            _buildEmptyTeamPlaceholder(isDarkMode)
                          else
                            KeyedSubtree(
                              key: _tourPitchKey,
                              child: _buildTeamPitch(
                                context,
                                team: teamsProvider.currentDisplayedTeam!,
                                isMyTeam: teamsProvider.isCurrentTeamMine,
                                isDarkMode: isDarkMode,
                              ),
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
                            KeyedSubtree(
                              key: _tourSubsKey,
                              child: _buildSubstitutesSection(
                                context,
                                teamsProvider: teamsProvider,
                                titleColor: titleColor,
                                isDarkMode: isDarkMode,
                              ),
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
                                  color: AppColors.amberDim,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.amber.withValues(
                                      alpha: 0.30,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.notifications_active,
                                      color: AppColors.amber,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${teamsProvider.pendingApplicationsCount} candidature(s) en attente',
                                        style: const TextStyle(
                                          color: AppColors.amber,
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
                                          color: AppColors.amber,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'VOIR',
                                          style: TextStyle(
                                            color: AppColors.night,
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
                            KeyedSubtree(
                              key: _tourMatchesKey,
                              child: _buildUpcomingMatchesSection(
                                teamsProvider.currentDisplayedTeam!.id,
                                isDarkMode,
                                titleColor,
                                teamsProvider.isCurrentTeamMine,
                              ),
                            ),
                          // Section matchs publics ouverts aux candidatures — désactivée
                          // _buildOpenMatchesSection(), // SECTION MATCHS OUVERTS
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
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.group_add_outlined,
                        color: AppColors.muted2,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PAS D\'ÉQUIPE',
                        style: AppTypography.display(
                          color: AppColors.muted2,
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
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.amber.withValues(alpha: 0.20),
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
                                      color: AppColors.amberDim,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      size: 18,
                                      color: AppColors.amber,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'REJOINDRE',
                                    style: AppTypography.display(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.amber,
                                      letterSpacing: 0.06 * 8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'une équipe',
                                    style: AppTypography.body(
                                      fontSize: 9,
                                      color: AppColors.muted2,
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
                                      'Recherchez une équipe ou rejoignez la vôtre.',
                                      'Recherchez une équipe à l\'aide de son nom ou du code ID du capitaine et envoyez une demande pour les rejoindre, ou consultez les équipes incomplètes et rejoignez les directement.',
                                      '--> Vous pouvez postuler à plusieurs équipes pour maximiser vos chances de jouer rapidement.',
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    size: 13,
                                    color: AppColors.amber.withValues(
                                      alpha: 0.65,
                                    ),
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
                                    AppColors.amber.withValues(alpha: 0.12),
                                    AppColors.amberD.withValues(alpha: 0.06),
                                  ],
                                )
                              : null,
                          color: isActive ? null : AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive
                                ? AppColors.amber.withValues(alpha: 0.35)
                                : AppColors.border,
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
                                    color: AppColors.amber,
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
                                        ? AppColors.amberDim
                                        : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: isOwner
                                          ? AppColors.amber.withValues(
                                              alpha: 0.25,
                                            )
                                          : AppColors.border2,
                                    ),
                                  ),
                                  child: Text(
                                    isOwner ? 'MON ÉQUIPE' : 'MEMBRE',
                                    style: AppTypography.display(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: isOwner
                                          ? AppColors.amber
                                          : AppColors.muted2,
                                      letterSpacing: 0.06 * 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Team name
                                Text(
                                  team.name.toUpperCase(),
                                  style: AppTypography.display(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white,
                                    letterSpacing: 0.04 * 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                // Meta
                                Text(
                                  '${team.members.length} membre${team.members.length > 1 ? 's' : ''}',
                                  style: AppTypography.body(
                                    fontSize: 10,
                                    color: AppColors.muted2,
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
                                              color: AppColors.amber,
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
                                            color: AppColors.muted2,
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
                                            color: AppColors.rose,
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
                color: AppColors.amber,
                border: Border.all(color: AppColors.card, width: 2),
              ),
              child: Center(
                child: Text(
                  m.user.username.isNotEmpty
                      ? m.user.username[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: AppColors.night,
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
                color: AppColors.card2,
                border: Border.all(color: AppColors.card, width: 2),
              ),
              child: Center(
                child: Text(
                  '+$extra',
                  style: const TextStyle(
                    fontSize: 6,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted2,
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
            color: isActive ? AppColors.amber : AppColors.border2,
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border2, width: 1.5),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 44, color: AppColors.muted2),
            const SizedBox(height: 12),
            const Text(
              'AUCUNE ÉQUIPE',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.06 * 13,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ajoutez des amis pour créer votre équipe',
              style: TextStyle(color: AppColors.muted2, fontSize: 11),
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

            // Formation 1-2-1-1 : gardien | 2 défenseurs | milieu | attaquant
            final List<List<int>> columns = [
              [0], // Gardien (à gauche)
              [1, 4], // Défenseurs (centre-gauche)
              [2], // Milieu (centre-droit)
              [3], // Attaquant (à droite)
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
                color: AppColors.white,
              ),
            ),
            GestureDetector(
              onTap: () => _showSubstituteOptions(
                context,
                currentSubstituteCount: substitutes.length,
              ),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.amberDim,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.amber.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: const Icon(Icons.add, color: AppColors.amber, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (substitutes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border2),
            ),
            child: const Center(
              child: Text(
                'Aucun remplaçant — appuyez sur + pour ajouter',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted2, fontSize: 12),
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
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 10),
        if (substitutes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border2),
            ),
            child: const Center(
              child: Text(
                'Aucun remplaçant',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted2, fontSize: 12),
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
              backgroundColor: AppColors.amber,
              backgroundImage: member.user.avatarUrl != null
                  ? NetworkImage(member.user.avatarUrl!)
                  : null,
              child: member.user.avatarUrl == null
                  ? Text(
                      member.user.username.isNotEmpty
                          ? member.user.username[0].toUpperCase()
                          : position.shortName,
                      style: const TextStyle(
                        color: AppColors.night,
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
                  color: AppColors.white,
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
                  backgroundColor: AppColors.amber.withValues(alpha: 0.85),
                  child: const Icon(
                    Icons.person_search,
                    color: AppColors.night,
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
                  color: AppColors.amber,
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
                    backgroundColor: AppColors.amber.withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.mail_outline,
                      color: AppColors.amber,
                      size: 20,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.amber,
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
                  color: AppColors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'En attente',
                  style: TextStyle(
                    color: AppColors.amber,
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
          Container(
            width: _playerAvatarRadius * 2,
            height: _playerAvatarRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: Icon(
              isEditable ? Icons.add : Icons.person_outline,
              color: Colors.white.withValues(alpha: 0.75),
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            position.shortName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.80),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
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
          color: AppColors.card,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.border2, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircleAvatar(
              radius: 11,
              backgroundColor: AppColors.amberDim,
              backgroundImage: member.user.avatarUrl != null
                  ? NetworkImage(member.user.avatarUrl!)
                  : null,
              child: member.user.avatarUrl == null
                  ? Text(
                      member.user.username.isNotEmpty
                          ? member.user.username[0].toUpperCase()
                          : 'R',
                      style: const TextStyle(
                        color: AppColors.amber,
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
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (member.user.rating != null) ...[
              const SizedBox(width: 5),
              Text(
                '⭐${member.user.rating!.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 10, color: AppColors.muted2),
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
          color: AppColors.card,
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
                color: AppColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.amberDim,
              backgroundImage: member.user.avatarUrl != null
                  ? NetworkImage(member.user.avatarUrl!)
                  : null,
              child: member.user.avatarUrl == null
                  ? Text(
                      member.user.username[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.amber,
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
                  style: AppTypography.display(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
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
                      color: AppColors.amberDim,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Vous',
                      style: AppTypography.display(
                        fontSize: 12,
                        color: AppColors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              member.position.displayName,
              style: AppTypography.body(color: AppColors.muted2, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Divider(color: AppColors.border2),
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
                    color: AppColors.card2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border2),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: AppColors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Voir le profil',
                        style: AppTypography.display(
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
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
                  color: AppColors.card2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border2),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz,
                      color: AppColors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Changer de position',
                      style: AppTypography.display(
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
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
                      backgroundColor: AppColors.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: AppColors.border2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Retirer ce joueur ?',
                              style: AppTypography.display(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Voulez-vous retirer ${member.user.username} de l\'équipe ?',
                              style: AppTypography.body(
                                fontSize: 13,
                                color: AppColors.muted2,
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
                                        color: AppColors.card2,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.border2,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Annuler',
                                        style: AppTypography.display(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.muted2,
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
                                        color: AppColors.rose,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Retirer',
                                        style: AppTypography.display(
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
                    color: AppColors.roseDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.rose.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.remove_circle,
                        color: AppColors.rose,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Retirer de l\'équipe',
                        style: AppTypography.display(
                          fontWeight: FontWeight.w600,
                          color: AppColors.rose,
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
                  style: AppTypography.body(
                    fontSize: 12,
                    color: AppColors.muted2,
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
              color: AppColors.card,
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
                          color: AppColors.border2,
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
                                  style: AppTypography.display(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                                Text(
                                  'Poste : ${position.displayName}',
                                  style: AppTypography.body(
                                    fontSize: 12,
                                    color: AppColors.muted2,
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
                              color: AppColors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.amber.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              '${pending.length} en attente',
                              style: AppTypography.display(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(color: AppColors.border2, height: 1),
                // Liste des invitations en attente
                if (pending.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Aucune invitation en attente',
                      style: AppTypography.body(color: AppColors.muted2),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: pending.length,
                      separatorBuilder: (_, _) =>
                          Divider(color: AppColors.border2, height: 1),
                      itemBuilder: (listCtx, index) {
                        final inv = pending[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.card2,
                            backgroundImage: inv.invitedAvatarUrl != null
                                ? NetworkImage(inv.invitedAvatarUrl!)
                                : null,
                            child: inv.invitedAvatarUrl == null
                                ? Text(
                                    inv.invitedUsername.isNotEmpty
                                        ? inv.invitedUsername[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: AppColors.amber,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            inv.invitedUsername,
                            style: AppTypography.display(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Envoyée le ${_formatInvitationDate(inv.createdAt)}',
                            style: AppTypography.body(
                              color: AppColors.muted2,
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
                                      backgroundColor: AppColors.amber,
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
                                      backgroundColor: AppColors.rose,
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
                                color: AppColors.rose.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.rose.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                'Annuler',
                                style: AppTypography.display(
                                  color: AppColors.rose,
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
                        color: AppColors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Inviter une autre personne',
                        style: AppTypography.display(
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
            color: AppColors.card,
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
                        color: AppColors.border2,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ajouter un ${position.displayName}',
                      style: AppTypography.display(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
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
                    color: AppColors.amberDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.amberDim,
                      backgroundImage: currentUser.avatarUrl != null
                          ? NetworkImage(currentUser.avatarUrl!)
                          : null,
                      child: currentUser.avatarUrl == null
                          ? Text(
                              currentUser.username[0].toUpperCase(),
                              style: const TextStyle(color: AppColors.amber),
                            )
                          : null,
                    ),
                    title: Text(
                      'Me placer ici',
                      style: AppTypography.display(
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                    subtitle: Text(
                      '@${currentUser.username}',
                      style: AppTypography.body(
                        fontSize: 12,
                        color: AppColors.muted2,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.person_add,
                      color: AppColors.amber,
                    ),
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
                    'Recherchez des joueurs pour compléter votre équipe.\nPubliez une annonce pour signaler que votre équipe recrute. Les joueurs disponibles pourront voir votre besoin et rejoindre votre equipe. \n--> Précisez la localisation, la date et le niveau recherché pour recevoir des profils adaptés.\n',
                preferBelow: false,
                verticalOffset: 8,
                decoration: BoxDecoration(
                  color: AppColors.night,
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amberDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.amberDim,
                      child: Icon(Icons.person_search, color: AppColors.amber),
                    ),
                    title: Text(
                      'Ouvrir le poste',
                      style: AppTypography.display(
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                    subtitle: Text(
                      'Les joueurs de l\'app pourront postuler pour rejoindre l\'équipe',
                      style: AppTypography.body(
                        fontSize: 12,
                        color: AppColors.muted2,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _showInfoModal('Ouvrir le poste', [
                            'Recherchez des joueurs pour compléter votre équipe.',
                            'Publiez une annonce pour signaler que votre équipe recrute. Les joueurs disponibles pourront voir votre besoin et rejoindre l\'équipe directement.',
                            '--> Précisez la localisation, la date et le niveau recherché pour recevoir des profils adaptés.',
                          ]),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.amber,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.muted2,
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
                  color: AppColors.night,
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border2),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF1A1D26),
                      child: Icon(
                        Icons.storefront_outlined,
                        color: AppColors.muted2,
                      ),
                    ),
                    title: Text(
                      'Recruter sur le store',
                      style: AppTypography.display(
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                    subtitle: Text(
                      'Parcourir les joueurs disponibles et les inviter',
                      style: AppTypography.body(
                        fontSize: 12,
                        color: AppColors.muted2,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _showInfoModal('Recruter sur le store', [
                            'Invitez des joueurs pour compléter votre équipe.',
                            'Consultez les joueurs disponibles et envoyez une invitation à ceux qui correspondent à vos besoins.',
                            '--> Le joueur peut accepter ou refuser votre invitation librement.',
                          ]),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.muted2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.muted2,
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
                    Expanded(child: Divider(color: AppColors.border2)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'ou choisir un ami',
                        style: AppTypography.body(
                          color: AppColors.muted2,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.border2)),
                  ],
                ),
              ),
              if (availableFriends.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Tous vos amis sont déjà dans l\'équipe !',
                    style: AppTypography.body(color: AppColors.muted2),
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
                          backgroundColor: AppColors.card2,
                          backgroundImage: friend.user.avatarUrl != null
                              ? NetworkImage(friend.user.avatarUrl!)
                              : null,
                          child: friend.user.avatarUrl == null
                              ? Text(
                                  friend.user.username[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.amber,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          friend.user.username,
                          style: AppTypography.display(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          friend.user.preferredPosition ??
                              'Position non définie',
                          style: AppTypography.body(
                            color: AppColors.muted2,
                            fontSize: 12,
                          ),
                        ),
                        trailing: friend.user.rating != null
                            ? Text(
                                '⭐ ${friend.user.rating!.toStringAsFixed(1)}',
                                style: AppTypography.body(
                                  color: AppColors.muted2,
                                ),
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
    bool openAll = false;
    PlayerPosition? preferredPosition = position;
    bool hasMatch = false;
    DateTime? matchDate;
    TimeOfDay? matchTime;
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (sbCtx, setState) => Dialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border2),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Row(
                  children: [
                    const Icon(Icons.person_search, color: AppColors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ouvrir le poste de ${position.displayName}',
                        style: AppTypography.display(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Les joueurs de l\'application pourront voir ce poste et postuler pour rejoindre votre équipe.',
                  style: AppTypography.body(
                    color: AppColors.muted2,
                    fontSize: 12,
                  ),
                ),

                // ── PORTÉE ──
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'NOMBRE DE POSTES',
                      style: AppTypography.display(
                        color: AppColors.muted2,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message:
                          'Un poste uniquement : Tu choisis manuellement le profil recherché (gardien, défenseur, milieu, attaquant ou remplaçant) et une seule annonce est diffusée pour ce poste précis.\n\nTous les postes disponibles : La fonctionnalité détecte automatiquement les postes vacants dans ton équipe et diffuse une annonce pour chacun d\'eux. Par exemple, s\'il te manque un défenseur et un attaquant, deux annonces seront automatiquement créées et diffusées. Dans ce cas, le choix du profil n\'est pas disponible car les annonces sont générées directement depuis la composition de ton équipe.',
                      textStyle: AppTypography.body(
                        color: AppColors.white,
                        fontSize: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF23263A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(12),
                      preferBelow: false,
                      triggerMode: TooltipTriggerMode.tap,
                      showDuration: const Duration(seconds: 8),
                      child: Icon(
                        Icons.info_outline,
                        size: 14,
                        color: AppColors.muted2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => openAll = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: !openAll
                                ? AppColors.amberDim
                                : AppColors.card2,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !openAll
                                  ? AppColors.amber
                                  : AppColors.border2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_pin,
                                color: !openAll
                                    ? AppColors.amber
                                    : AppColors.muted2,
                                size: 18,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Un poste uniquement',
                                textAlign: TextAlign.center,
                                style: AppTypography.display(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: !openAll
                                      ? AppColors.amber
                                      : AppColors.muted2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => openAll = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: openAll
                                ? AppColors.amberDim
                                : AppColors.card2,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: openAll
                                  ? AppColors.amber
                                  : AppColors.border2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.groups,
                                color: openAll
                                    ? AppColors.amber
                                    : AppColors.muted2,
                                size: 18,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tous les postes disponibles',
                                textAlign: TextAlign.center,
                                style: AppTypography.display(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: openAll
                                      ? AppColors.amber
                                      : AppColors.muted2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── PROFIL RECHERCHÉ ──
                const SizedBox(height: 20),
                IgnorePointer(
                  ignoring: openAll,
                  child: Opacity(
                    opacity: openAll ? 0.35 : 1.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROFIL RECHERCHÉ',
                          style: AppTypography.display(
                            color: AppColors.muted2,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (ctx) {
                            final tp = context.read<TeamsProvider>();
                            final occupied = (tp.myTeam?.members ?? [])
                                .map((m) => m.slotIndex)
                                .toSet();
                            bool isAvailable(PlayerPosition p) {
                              if (p == PlayerPosition.substitute) {
                                final occupiedSubs = occupied
                                    .where((idx) => idx >= 5)
                                    .length;
                                final openSubs = tp.myOpenSlots
                                    .where(
                                      (s) => s.isActive && s.slotIndex >= 5,
                                    )
                                    .length;
                                return (occupiedSubs + openSubs) < 3;
                              }
                              if (p == PlayerPosition.defender) {
                                return (!occupied.contains(1) &&
                                        !tp.isSlotOpen(1)) ||
                                    (!occupied.contains(4) &&
                                        !tp.isSlotOpen(4));
                              }
                              final idx = p.index;
                              return !occupied.contains(idx) &&
                                  !tp.isSlotOpen(idx);
                            }

                            return Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                ...PlayerPosition.values.map(
                                  (p) => _buildPositionChip(
                                    label: p.displayName,
                                    selected: preferredPosition == p,
                                    disabled: !isAvailable(p),
                                    onTap: () {
                                      if (preferredPosition == p) return;
                                      setState(() => preferredPosition = p);
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ── DESCRIPTION ──
                const SizedBox(height: 20),
                Text(
                  'DESCRIPTION (OPTIONNEL)',
                  style: AppTypography.display(
                    color: AppColors.muted2,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Ex: Bon niveau requis, ambiance sympa...',
                    hintStyle: const TextStyle(
                      color: AppColors.muted2,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.card2,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.amber),
                    ),
                  ),
                ),

                // ── MATCH PRÉVU ──
                const SizedBox(height: 20),
                Text(
                  'MATCH PRÉVU',
                  style: AppTypography.display(
                    color: AppColors.muted2,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border2),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 15,
                              color: hasMatch
                                  ? AppColors.amber
                                  : AppColors.muted2,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Avez-vous un match prévu ?',
                                style: AppTypography.body(
                                  color: AppColors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Switch(
                              value: hasMatch,
                              activeThumbColor: AppColors.amber,
                              activeTrackColor: AppColors.amberDim,
                              onChanged: (v) => setState(() {
                                hasMatch = v;
                                if (!v) {
                                  matchDate = null;
                                  matchTime = null;
                                  locationController.clear();
                                }
                              }),
                            ),
                          ],
                        ),
                      ),
                      if (hasMatch) ...[
                        Divider(
                          height: 1,
                          color: AppColors.border2,
                          indent: 14,
                          endIndent: 14,
                        ),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: dialogCtx,
                              initialDate:
                                  matchDate ??
                                  DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              builder: (ctx, child) => Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: AppColors.amber,
                                    onPrimary: Colors.black,
                                    surface: AppColors.card,
                                    onSurface: AppColors.white,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              setState(() => matchDate = picked);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.event,
                                  size: 15,
                                  color: AppColors.amber,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  matchDate != null
                                      ? '${matchDate!.day.toString().padLeft(2, '0')}/${matchDate!.month.toString().padLeft(2, '0')}/${matchDate!.year}'
                                      : 'Choisir la date du match',
                                  style: AppTypography.body(
                                    color: matchDate != null
                                        ? AppColors.amber
                                        : AppColors.muted2,
                                    fontSize: 13,
                                    fontWeight: matchDate != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: AppColors.muted2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: AppColors.border2,
                          indent: 14,
                          endIndent: 14,
                        ),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: dialogCtx,
                              initialTime: matchTime ?? TimeOfDay.now(),
                              builder: (ctx, child) => Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: AppColors.amber,
                                    onPrimary: Colors.black,
                                    surface: AppColors.card,
                                    onSurface: AppColors.white,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              setState(() => matchTime = picked);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 15,
                                  color: matchTime != null
                                      ? AppColors.amber
                                      : AppColors.muted2,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  matchTime != null
                                      ? '${matchTime!.hour.toString().padLeft(2, '0')}h${matchTime!.minute.toString().padLeft(2, '0')}'
                                      : 'Choisir l\'heure du match',
                                  style: AppTypography.body(
                                    color: matchTime != null
                                        ? AppColors.amber
                                        : AppColors.muted2,
                                    fontSize: 13,
                                    fontWeight: matchTime != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: AppColors.muted2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: AppColors.border2,
                          indent: 14,
                          endIndent: 14,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 15,
                                color: AppColors.amber,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CityAutocompleteField(
                                  controller: locationController,
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 13,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Lieu du match (ex: Stade Jean-Bouin)',
                                    hintStyle: TextStyle(
                                      color: AppColors.muted2,
                                      fontSize: 12,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
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

                // ── BOUTONS ──
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(dialogCtx),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.card2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Annuler',
                            style: AppTypography.display(
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted2,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Builder(
                      builder: (context) {
                        final canSubmit =
                            !hasMatch ||
                            (matchDate != null &&
                                matchTime != null &&
                                locationController.text.trim().isNotEmpty);
                        return Expanded(
                          child: GestureDetector(
                            onTap: canSubmit
                                ? () async {
                                    Navigator.pop(dialogCtx);
                                    final success = await context
                                        .read<TeamsProvider>()
                                        .openSlotForSearch(
                                          position: openAll
                                              ? position
                                              : (preferredPosition ?? position),
                                          slotIndex:
                                              (!openAll &&
                                                  preferredPosition != null)
                                              ? preferredPosition!.index
                                              : slotIndex,
                                          description:
                                              descriptionController.text
                                                  .trim()
                                                  .isNotEmpty
                                              ? descriptionController.text
                                                    .trim()
                                              : null,
                                          openAllSlots: openAll,
                                          preferredPosition: preferredPosition,
                                          matchLocation:
                                              locationController.text
                                                  .trim()
                                                  .isNotEmpty
                                              ? locationController.text.trim()
                                              : null,
                                          matchDate: matchDate != null
                                              ? DateTime(
                                                  matchDate!.year,
                                                  matchDate!.month,
                                                  matchDate!.day,
                                                  matchTime?.hour ?? 0,
                                                  matchTime?.minute ?? 0,
                                                )
                                              : null,
                                        );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? openAll
                                                      ? 'Tous les postes ouverts aux candidatures !'
                                                      : 'Poste ouvert aux candidatures !'
                                                : 'Erreur lors de l\'ouverture du poste',
                                          ),
                                          backgroundColor: success
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: canSubmit
                                    ? const LinearGradient(
                                        colors: [
                                          AppColors.amber,
                                          AppColors.amberD,
                                        ],
                                      )
                                    : null,
                                color: canSubmit ? null : AppColors.card2,
                                borderRadius: BorderRadius.circular(12),
                                border: canSubmit
                                    ? null
                                    : Border.all(color: AppColors.border2),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_search,
                                    color: canSubmit
                                        ? Colors.white
                                        : AppColors.muted2,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Ouvrir',
                                    style: AppTypography.display(
                                      fontWeight: FontWeight.w600,
                                      color: canSubmit
                                          ? Colors.white
                                          : AppColors.muted2,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPositionChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.35 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.amberDim : AppColors.card2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.amber : AppColors.border2,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.display(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.amber : AppColors.muted2,
            ),
          ),
        ),
      ),
    );
  }

  void _showSubstituteOptions(
    BuildContext context, {
    required int currentSubstituteCount,
  }) {
    final teamsProvider = context.read<TeamsProvider>();
    final openSubSlots = teamsProvider.myOpenSlots
        .where((s) => s.isActive && s.slotIndex >= 5)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
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
                color: AppColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Slots remplaçants ouverts
            if (openSubSlots.isNotEmpty) ...[
              Text(
                'POSTES EN RECHERCHE',
                style: AppTypography.display(
                  color: AppColors.muted2,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              ...openSubSlots.map(
                (slot) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showOpenSlotOptions(
                        context,
                        slot,
                        PlayerPosition.substitute,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.amber.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_search,
                            color: AppColors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Remplaçant · ${slot.applicationsCount} candidature(s)',
                              style: AppTypography.display(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppColors.muted2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: AppColors.border2, height: 1),
              const SizedBox(height: 16),
            ],
            // Ajouter un joueur
            if (currentSubstituteCount + openSubSlots.length < 3)
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddPlayerDialog(
                    context,
                    slotIndex: 5 + currentSubstituteCount + openSubSlots.length,
                    position: PlayerPosition.substitute,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border2),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_add,
                        color: AppColors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ajouter un remplaçant',
                        style: AppTypography.display(
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                          fontSize: 14,
                        ),
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
          color: AppColors.card,
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
                color: AppColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.amberDim,
              child: Icon(
                Icons.person_search,
                color: AppColors.amber,
                size: 30,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Poste ${position.displayName} — candidatures ouvertes',
              style: AppTypography.display(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            if (openSlot.description != null) ...[
              const SizedBox(height: 8),
              Text(
                openSlot.description!,
                style: AppTypography.body(color: AppColors.muted2),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.amberDim,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${openSlot.applicationsCount} candidature(s)',
                style: AppTypography.display(
                  color: AppColors.amber,
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
                    color: AppColors.card2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border2),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people,
                        color: AppColors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Voir les candidatures',
                        style: AppTypography.display(
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.rose,
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
                    backgroundColor: AppColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: AppColors.border2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Clôturer les candidatures ?',
                            style: AppTypography.display(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Les candidatures en attente seront annulées.',
                            style: AppTypography.body(
                              fontSize: 13,
                              color: AppColors.muted2,
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
                                      color: AppColors.card2,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.border2,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Annuler',
                                      style: AppTypography.display(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.muted2,
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
                                      color: AppColors.rose,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Fermer',
                                      style: AppTypography.display(
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
                  color: AppColors.roseDim,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.rose.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.close, color: AppColors.rose, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clôturer les candidatures',
                          style: AppTypography.display(
                            fontWeight: FontWeight.w600,
                            color: AppColors.rose,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Mettre fin aux candidatures pour ce poste',
                          style: AppTypography.body(
                            color: AppColors.muted2,
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
                color: AppColors.card,
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
                      color: AppColors.border2,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          color: AppColors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Joueurs disponibles',
                          style: AppTypography.display(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amberDim,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            position.displayName,
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
                  const Divider(color: AppColors.border2, height: 1),
                  Expanded(
                    child: FutureBuilder<List<AvailablePlayer>>(
                      future: TeamsService.instance.getAvailablePlayers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.amber,
                            ),
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
                                  color: AppColors.muted2,
                                  size: 40,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Aucun joueur disponible',
                                  style: AppTypography.display(
                                    color: AppColors.muted2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Les joueurs peuvent activer leur disponibilité\ndans "Trouve ton équipe"',
                                  style: AppTypography.body(
                                    color: AppColors.muted2,
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
                                      ? AppColors.amber.withValues(alpha: 0.25)
                                      : AppColors.border2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.amberDim,
                                    backgroundImage: player.avatarUrl != null
                                        ? NetworkImage(player.avatarUrl!)
                                        : null,
                                    child: player.avatarUrl == null
                                        ? Text(
                                            player.username[0].toUpperCase(),
                                            style: AppTypography.display(
                                              color: AppColors.amber,
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
                                              style: AppTypography.display(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.white,
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
                                                  color: AppColors.amberDim,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  'Poste correspondant',
                                                  style: AppTypography.display(
                                                    fontSize: 9,
                                                    color: AppColors.amber,
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
                                          style: AppTypography.body(
                                            color: AppColors.muted2,
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
                                          style: AppTypography.display(
                                            color: AppColors.amber,
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
                                            color: AppColors.card,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: AppColors.border2,
                                            ),
                                          ),
                                          child: Text(
                                            'Déjà membre',
                                            style: AppTypography.display(
                                              color: AppColors.muted2,
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
                                                    ? AppColors.amber
                                                    : AppColors.rose,
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.rose.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: AppColors.rose
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                            child: Text(
                                              'Annuler',
                                              style: AppTypography.display(
                                                color: AppColors.rose,
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
                                                    ? AppColors.amber
                                                    : AppColors.rose,
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.amber,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'Inviter',
                                              style: AppTypography.display(
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
            color: AppColors.card,
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
                        color: AppColors.border2,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Candidatures (${applications.length})',
                      style: AppTypography.display(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
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
                        color: AppColors.muted2,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune candidature pour le moment',
                        style: AppTypography.body(color: AppColors.muted2),
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
                          color: AppColors.card2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.amberDim,
                                  backgroundImage:
                                      app.applicant.avatarUrl != null
                                      ? NetworkImage(app.applicant.avatarUrl!)
                                      : null,
                                  child: app.applicant.avatarUrl == null
                                      ? Text(
                                          app.applicant.username[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: AppColors.amber,
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
                                        style: AppTypography.display(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppColors.white,
                                        ),
                                      ),
                                      if (app.applicant.rating != null)
                                        Text(
                                          '⭐ ${app.applicant.rating!.toStringAsFixed(1)}',
                                          style: AppTypography.body(
                                            color: AppColors.muted2,
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
                                  color: AppColors.border.withValues(
                                    alpha: 0.5,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border2),
                                ),
                                child: Text(
                                  '"${app.message}"',
                                  style: AppTypography.body(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.muted2,
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
                                      color: AppColors.roseDim,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.rose.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.close,
                                          color: AppColors.rose,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Refuser',
                                          style: AppTypography.display(
                                            color: AppColors.rose,
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
                                      color: AppColors.sageDim,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.sage.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check,
                                          color: AppColors.sage,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Accepter',
                                          style: AppTypography.display(
                                            color: AppColors.sage,
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
            color: AppColors.card,
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
                        color: AppColors.border2,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.inbox, color: AppColors.amber),
                        const SizedBox(width: 8),
                        Text(
                          'Toutes les candidatures (${applications.length})',
                          style: AppTypography.display(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
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
                          color: AppColors.muted2,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune candidature en attente',
                          style: AppTypography.body(color: AppColors.muted2),
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
                          color: AppColors.card2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.amberDim,
                                  backgroundImage:
                                      app.applicant.avatarUrl != null
                                      ? NetworkImage(app.applicant.avatarUrl!)
                                      : null,
                                  child: app.applicant.avatarUrl == null
                                      ? Text(
                                          app.applicant.username[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: AppColors.amber,
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
                                        style: AppTypography.display(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppColors.white,
                                        ),
                                      ),
                                      if (openSlot != null)
                                        Text(
                                          'Pour : ${openSlot.position.displayName}',
                                          style: AppTypography.body(
                                            color: AppColors.muted2,
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
                                      color: AppColors.amberDim,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '⭐ ${app.applicant.rating!.toStringAsFixed(1)}',
                                      style: AppTypography.body(
                                        color: AppColors.amberSoft,
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
                                  color: AppColors.border.withValues(
                                    alpha: 0.5,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border2),
                                ),
                                child: Text(
                                  '"${app.message}"',
                                  style: AppTypography.body(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.muted2,
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
                                      color: AppColors.roseDim,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.rose.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.close,
                                          color: AppColors.rose,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Refuser',
                                          style: AppTypography.display(
                                            color: AppColors.rose,
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
                                      color: AppColors.sageDim,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.sage.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check,
                                          color: AppColors.sage,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Accepter',
                                          style: AppTypography.display(
                                            color: AppColors.sage,
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
          color: AppColors.card,
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
                color: AppColors.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Changer la position de ${member.user.username}',
              style: AppTypography.display(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...PlayerPosition.values.map(
              (position) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: member.position == position
                      ? AppColors.amberDim
                      : AppColors.card2,
                  child: Text(
                    position.shortName,
                    style: TextStyle(
                      color: member.position == position
                          ? AppColors.amber
                          : AppColors.muted2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  position.displayName,
                  style: AppTypography.display(
                    color: AppColors.white,
                    fontWeight: member.position == position
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                trailing: member.position == position
                    ? const Icon(Icons.check, color: AppColors.amber)
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await context.read<TeamsProvider>().updateMemberPosition(
                    userId: member.user.id,
                    position: position,
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
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nom de l\'équipe',
                style: AppTypography.display(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  labelText: 'Nom',
                  labelStyle: const TextStyle(color: AppColors.muted2),
                  filled: true,
                  fillColor: AppColors.card2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.amber),
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
                          color: AppColors.card2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Annuler',
                          style: AppTypography.display(
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted2,
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
                            colors: [AppColors.amber, AppColors.amberD],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Enregistrer',
                          style: AppTypography.display(
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
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sélectionner l\'heure',
                style: AppTypography.display(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.white,
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
                          color: AppColors.card2,
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
                                  color: AppColors.white,
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
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    // Roulette des minutes
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.card2,
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
                                  color: AppColors.white,
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
                          color: AppColors.card2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Annuler',
                          style: AppTypography.display(
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted2,
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
                            colors: [AppColors.amber, AppColors.amberD],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'OK',
                          style: AppTypography.display(
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
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border2),
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
                      const Icon(Icons.search, color: AppColors.amber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Préférences de recherche',
                          style: AppTypography.display(
                            color: AppColors.white,
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
                    style: AppTypography.display(
                      color: AppColors.white,
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
                          style: AppTypography.display(
                            fontSize: 12,
                            color: isSelected
                                ? AppColors.amber
                                : AppColors.muted2,
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
                        selectedColor: AppColors.amberDim,
                        checkmarkColor: AppColors.amber,
                        backgroundColor: AppColors.card2,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.amber.withValues(alpha: 0.5)
                              : AppColors.border2,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Plage horaire
                  Text(
                    'Plage horaire *',
                    style: AppTypography.display(
                      color: AppColors.white,
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
                              color: AppColors.card2,
                              border: Border.all(color: AppColors.border2),
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
                                        ? AppColors.white
                                        : AppColors.muted2,
                                  ),
                                ),
                                const Icon(
                                  Icons.access_time,
                                  size: 20,
                                  color: AppColors.muted2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.arrow_forward, color: AppColors.amber),
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
                              color: AppColors.card2,
                              border: Border.all(color: AppColors.border2),
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
                                    color: endTime != null
                                        ? AppColors.white
                                        : AppColors.muted2,
                                  ),
                                ),
                                const Icon(
                                  Icons.access_time,
                                  size: 20,
                                  color: AppColors.muted2,
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
                    style: AppTypography.display(
                      color: AppColors.white,
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
                          style: AppTypography.display(
                            fontSize: 12,
                            color: isSelected
                                ? AppColors.amber
                                : AppColors.muted2,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            selectedSkillLevel = selected ? niveau : null;
                          });
                        },
                        selectedColor: AppColors.amberDim,
                        checkmarkColor: AppColors.amber,
                        backgroundColor: AppColors.card2,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.amber.withValues(alpha: 0.5)
                              : AppColors.border2,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Villes
                  Text(
                    'Villes de déplacement *',
                    style: AppTypography.display(
                      color: AppColors.white,
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
                            style: AppTypography.body(
                              color: AppColors.white,
                              fontSize: 12,
                            ),
                          ),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.muted2,
                          ),
                          onDeleted: () {
                            setState(() {
                              selectedCities.remove(city);
                            });
                          },
                          backgroundColor: AppColors.amberDim,
                          side: BorderSide(
                            color: AppColors.amber.withValues(alpha: 0.3),
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
                        child: CityAutocompleteField(
                          controller: cityController,
                          style: const TextStyle(color: AppColors.white),
                          decoration: InputDecoration(
                            hintText: 'Ajouter une ville',
                            hintStyle: const TextStyle(color: AppColors.muted2),
                            filled: true,
                            fillColor: AppColors.card2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.border2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.border2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.amber,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onSelected: (city) {
                            setState(() {
                              if (!selectedCities.contains(city)) {
                                selectedCities.add(city);
                              }
                              cityController.clear();
                            });
                          },
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
                        icon: const Icon(Icons.add, color: AppColors.amber),
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
                    style: AppTypography.body(
                      color: AppColors.muted2,
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
                              color: AppColors.card2,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Annuler',
                              style: AppTypography.display(
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted2,
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
                                colors: [AppColors.amber, AppColors.amberD],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Valider',
                              style: AppTypography.display(
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
    final double w = size.width;
    final double h = size.height;

    // 1. Bandes de gazon alternées — contraste marqué pour effet "tondu"
    final Paint stripePaint = Paint()..style = PaintingStyle.fill;
    const int stripeCount = 10;
    final double stripeWidth = w / stripeCount;
    for (int i = 0; i < stripeCount; i++) {
      stripePaint.color = i.isEven
          ? const Color(0xFF1F5429) // vert clair (bande tondue)
          : const Color(0xFF153519); // vert foncé
      canvas.drawRect(
        Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, h),
        stripePaint,
      );
    }

    // 2. Overlay radial gradient — bords légèrement plus sombres pour la profondeur
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.20)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 3. Peintures réutilisables
    final Paint lp = Paint()
      ..color = Colors.white.withValues(alpha: 0.78)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.78)
      ..style = PaintingStyle.fill;

    const double m = 5.0; // marge intérieure

    // Bordure du terrain (coins arrondis subtils)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(m, m, w - m * 2, h - m * 2),
        const Radius.circular(2),
      ),
      lp,
    );

    // Ligne médiane
    canvas.drawLine(Offset(w / 2, m), Offset(w / 2, h - m), lp);

    // Cercle central
    canvas.drawCircle(Offset(w / 2, h / 2), h * 0.16, lp);

    // Point central
    canvas.drawCircle(Offset(w / 2, h / 2), 3, dotPaint);

    // Grandes surfaces (zones de réparation)
    final double bigBoxW = w * 0.14;
    final double bigBoxH = h * 0.56;
    final double bigBoxY = (h - bigBoxH) / 2;
    canvas.drawRect(Rect.fromLTWH(m, bigBoxY, bigBoxW, bigBoxH), lp);
    canvas.drawRect(
      Rect.fromLTWH(w - m - bigBoxW, bigBoxY, bigBoxW, bigBoxH),
      lp,
    );

    // Petites surfaces (6-yard box)
    final double smallBoxW = w * 0.065;
    final double smallBoxH = h * 0.30;
    final double smallBoxY = (h - smallBoxH) / 2;
    canvas.drawRect(Rect.fromLTWH(m, smallBoxY, smallBoxW, smallBoxH), lp);
    canvas.drawRect(
      Rect.fromLTWH(w - m - smallBoxW, smallBoxY, smallBoxW, smallBoxH),
      lp,
    );

    // Points de penalty
    final double penX = w * 0.155;
    canvas.drawCircle(Offset(penX, h / 2), 3, dotPaint);
    canvas.drawCircle(Offset(w - penX, h / 2), 3, dotPaint);

    // Arcs de penalty (D) — seulement la partie visible en dehors de la grande surface
    final double arcR = h * 0.13;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(m + bigBoxW, 0, w, h));
    canvas.drawCircle(Offset(penX, h / 2), arcR, lp);
    canvas.restore();

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w - m - bigBoxW, h));
    canvas.drawCircle(Offset(w - penX, h / 2), arcR, lp);
    canvas.restore();

    // Arcs de coin
    final double cr = h * 0.07;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(m, m), radius: cr),
      0,
      math.pi / 2,
      false,
      lp,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(m, h - m), radius: cr),
      -math.pi / 2,
      math.pi / 2,
      false,
      lp,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w - m, m), radius: cr),
      math.pi / 2,
      math.pi / 2,
      false,
      lp,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w - m, h - m), radius: cr),
      math.pi,
      math.pi / 2,
      false,
      lp,
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
    final matchApps = teamsProvider.receivedMatchApplications;
    final joinRequests = teamsProvider.receivedJoinRequests;
    final totalCount =
        challenges.length +
        invitations.length +
        matchApps.length +
        joinRequests.length;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
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
              color: AppColors.border2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          // Header
          Row(
            children: [
              Text(
                'Notifications',
                style: AppTypography.display(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
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
                    color: AppColors.amberDim,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Color(0x40FF7F2A), width: 1),
                  ),
                  child: Text(
                    '$totalCount',
                    style: const TextStyle(
                      color: AppColors.amber,
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
                style: AppTypography.body(
                  color: AppColors.muted2,
                  fontSize: 13,
                ),
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
                  if (joinRequests.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'DEMANDES D\'ÉQUIPE',
                        style: AppTypography.display(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted2,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    ...joinRequests.asMap().entries.map(
                      (e) => Padding(
                        padding: EdgeInsets.only(
                          bottom: e.key < joinRequests.length - 1 ? 10 : 0,
                        ),
                        child: _buildJoinRequestItem(
                          context,
                          e.value,
                          teamsProvider,
                        ),
                      ),
                    ),
                    if (matchApps.isNotEmpty ||
                        invitations.isNotEmpty ||
                        challenges.isNotEmpty)
                      const SizedBox(height: 12),
                  ],
                  if (matchApps.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'CANDIDATURES MATCH PUBLIC',
                        style: AppTypography.display(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted2,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    ...matchApps.asMap().entries.map(
                      (e) => Padding(
                        padding: EdgeInsets.only(
                          bottom: e.key < matchApps.length - 1 ? 10 : 0,
                        ),
                        child: _buildMatchApplicationItem(
                          context,
                          e.value,
                          teamsProvider,
                        ),
                      ),
                    ),
                    if (invitations.isNotEmpty || challenges.isNotEmpty)
                      const SizedBox(height: 12),
                  ],
                  if (invitations.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'INVITATIONS D\'ÉQUIPE',
                        style: AppTypography.display(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted2,
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
                        style: AppTypography.display(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted2,
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
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
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
                      style: AppTypography.display(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Invitation · ${invitation.invitingUsername}',
                      style: AppTypography.body(
                        fontSize: 10,
                        color: AppColors.muted2,
                      ),
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
                        style: AppTypography.display(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.rose,
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
                      color: AppColors.amberDim,
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
                                color: AppColors.amber,
                              ),
                            )
                          : Text(
                              'Accepter',
                              style: AppTypography.display(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.amber,
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
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
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
                  color: AppColors.amberDim,
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
                            color: AppColors.amber,
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
                      style: AppTypography.display(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Défi reçu',
                      style: AppTypography.body(
                        fontSize: 10,
                        color: AppColors.muted2,
                      ),
                    ),
                  ],
                ),
              ),
              if (challenge.proposedDate != null)
                Text(
                  DateFormat('d MMM', 'fr_FR').format(challenge.proposedDate!),
                  style: AppTypography.body(
                    fontSize: 10,
                    color: AppColors.muted2,
                  ),
                ),
            ],
          ),
          // Message
          if (challenge.message != null && challenge.message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.bg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                challenge.message!,
                style: AppTypography.body(
                  fontSize: 12,
                  color: AppColors.muted2,
                ),
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
                const Icon(
                  Icons.location_on,
                  size: 12,
                  color: AppColors.muted2,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    challenge.proposedLocation!,
                    style: AppTypography.body(
                      fontSize: 11,
                      color: AppColors.muted2,
                    ),
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
                    border: Border.all(color: AppColors.rose, width: 1.5),
                  ),
                  child: Text(
                    'REFUSER',
                    style: AppTypography.display(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      letterSpacing: 0.6,
                      color: AppColors.rose,
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
                      colors: [AppColors.amberSoft, AppColors.amberD],
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
                                color: AppColors.night,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          'ACCEPTER',
                          style: AppTypography.display(
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.6,
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

  Widget _buildMatchApplicationItem(
    BuildContext context,
    MatchApplication app,
    TeamsProvider teamsProvider,
  ) {
    final isLoading = _loadingIds.contains(app.id);
    final posLabel = app.position.displayName;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
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
                  color: const Color(0x1A22C55E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x3322C55E), width: 1),
                ),
                child: app.applicantAvatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.network(
                          app.applicantAvatarUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          app.applicantUsername.isNotEmpty
                              ? app.applicantUsername[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Color(0xFF22C55E),
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
                      app.applicantUsername,
                      style: AppTypography.display(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Veut rejoindre · ${app.teamName}',
                      style: AppTypography.body(
                        fontSize: 10,
                        color: AppColors.muted2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x1A22C55E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  posLabel,
                  style: const TextStyle(
                    color: Color(0xFF22C55E),
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
                          setState(() => _loadingIds.add(app.id));
                          await teamsProvider.rejectReceivedMatchApplication(
                            app.id,
                          );
                          if (mounted)
                            setState(() => _loadingIds.remove(app.id));
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
                        style: AppTypography.display(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.rose,
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
                          setState(() => _loadingIds.add(app.id));
                          final result = await teamsProvider
                              .acceptReceivedMatchApplication(app.id);
                          if (mounted) {
                            setState(() => _loadingIds.remove(app.id));
                            if (!result.success &&
                                result.errorMessage != null &&
                                context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result.errorMessage!,
                                    style: AppTypography.body(
                                      color: AppColors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                  backgroundColor: AppColors.rose,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: const EdgeInsets.all(12),
                                ),
                              );
                            }
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.amberDim,
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
                                color: AppColors.amber,
                              ),
                            )
                          : Text(
                              'Accepter',
                              style: AppTypography.display(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.amber,
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

  Widget _buildJoinRequestItem(
    BuildContext context,
    ReceivedJoinRequest request,
    TeamsProvider teamsProvider,
  ) {
    final isLoading = _loadingIds.contains(request.id * 1000);

    // Badge source
    final sourceLabel = request.source == 'match'
        ? 'Match en cours'
        : 'Recherche d\'équipe';
    final sourceColor = request.source == 'match'
        ? const Color(0xFF3B82F6)
        : AppColors.amber;
    final sourceBg = request.source == 'match'
        ? const Color(0x1A3B82F6)
        : AppColors.amberDim;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar du demandeur
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.amberDim,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x33FF7F2A), width: 1),
                ),
                child: request.requesterAvatarUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.network(
                          request.requesterAvatarUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          request.requesterUsername[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.amber,
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
                      request.requesterUsername,
                      style: AppTypography.display(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Veut rejoindre · ${request.teamName}',
                      style: AppTypography.body(
                        fontSize: 10,
                        color: AppColors.muted2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Badge source
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: sourceBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  sourceLabel,
                  style: TextStyle(
                    color: sourceColor,
                    fontSize: 9,
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
                          setState(() => _loadingIds.add(request.id * 1000));
                          await teamsProvider.respondToJoinRequest(
                            request.id,
                            accept: false,
                          );
                          if (mounted)
                            setState(
                              () => _loadingIds.remove(request.id * 1000),
                            );
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.roseDim,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x33D4607A)),
                    ),
                    child: Center(
                      child: Text(
                        'Refuser',
                        style: AppTypography.display(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.rose,
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
                          setState(() => _loadingIds.add(request.id * 1000));
                          final success = await teamsProvider
                              .respondToJoinRequest(request.id, accept: true);
                          if (mounted) {
                            setState(
                              () => _loadingIds.remove(request.id * 1000),
                            );
                            if (success && context.mounted)
                              Navigator.pop(context);
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.amberDim,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x40FF7F2A)),
                    ),
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.amber,
                              ),
                            )
                          : Text(
                              'Accepter',
                              style: AppTypography.display(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.amber,
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

  // controllers, absences & ratings : indexed by userId
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, bool> _absences = {};
  final Map<int, int?> _ratings = {};

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
        'rating': _ratings[m.user.id],
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
          color: AppColors.card,
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
                color: AppColors.border2,
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
                      color: AppColors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_step + 1}/2',
                      style: AppTypography.display(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber,
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
                          style: AppTypography.display(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: AppTypography.body(
                            fontSize: 11,
                            color: AppColors.muted2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border2),
            // Liste joueurs
            Expanded(
              child: (!isMyTeamStep && _loadingOpponent)
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.amber),
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
                    color: _loading ? AppColors.border2 : AppColors.amber,
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
                          style: AppTypography.display(
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
                color: AppColors.card2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border2),
              ),
              child: Text(
                s,
                style: AppTypography.body(
                  fontSize: 11,
                  color: AppColors.muted2,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRatingPicker(int userId) {
    final selected = _ratings[userId];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOTE (optionnel)',
          style: AppTypography.display(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.muted2,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(10, (i) {
            final note = i + 1;
            final isSelected = selected == note;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _ratings[userId] = isSelected ? null : note;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.amber : AppColors.card,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? AppColors.amber : AppColors.border2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$note',
                    style: AppTypography.display(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.muted2,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(TeamMember member) {
    final isAbsent = _absences[member.user.id] ?? false;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAbsent
              ? AppColors.rose.withValues(alpha: 0.4)
              : AppColors.border2,
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
                        color: AppColors.border2,
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
                              color: AppColors.muted2,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.user.username,
                          style: AppTypography.display(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                        Text(
                          member.position.displayName,
                          style: AppTypography.body(
                            fontSize: 11,
                            color: AppColors.muted2,
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
                    color: isAbsent
                        ? AppColors.rose.withValues(alpha: 0.2)
                        : AppColors.border2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAbsent ? AppColors.rose : Colors.transparent,
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
                        color: isAbsent ? AppColors.rose : AppColors.muted2,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAbsent ? 'Absent' : 'Présent',
                        style: AppTypography.display(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isAbsent ? AppColors.rose : AppColors.muted2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildRatingPicker(member.user.id),
          const SizedBox(height: 10),
          TextField(
            controller: _controllers[member.user.id],
            style: AppTypography.body(fontSize: 12, color: AppColors.white),
            maxLines: 2,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'Commentaire (optionnel)…',
              hintStyle: AppTypography.body(
                fontSize: 12,
                color: AppColors.muted2,
              ),
              counterStyle: AppTypography.body(
                fontSize: 10,
                color: AppColors.muted2,
              ),
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.amber),
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
