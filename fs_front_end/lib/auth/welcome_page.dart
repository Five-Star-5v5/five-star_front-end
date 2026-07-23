import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'login.dart';
import 'signup.dart';
import '../theme/app_colors.dart';
import '../widgets/kobeta_backdrop.dart';
import '../widgets/kobeta_logo.dart';

// ── Widget ─────────────────────────────────────────────────────────────────
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  // Controllers
  late final AnimationController _logoCtrl;
  late final AnimationController _brandCtrl;
  late final AnimationController _taglineCtrl;
  late final AnimationController _cardCtrl;
  late final AnimationController _floatCtrl;

  // Animations – logo
  late final Animation<Offset> _orangeSlide;
  late final Animation<double> _orangeFade;
  late final Animation<Offset> _graySlide;
  late final Animation<double> _grayFade;

  // Animations – brand / tagline / card
  late final Animation<Offset> _brandSlide;
  late final Animation<double> _brandFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;

  // Float
  late final Animation<double> _float;

  // ── Carrousel ──
  final _pageCtrl = PageController();
  int _page = 0;

  static const _slides = <_SlideData>[
    _SlideData(
      image: 'assets/logos/trouve_ton_terrain.png',
      title: 'Trouve ton terrain',
      body:
          'Repère les terrains autour de toi sur la carte, '
          'consulte leurs infos et choisis où jouer.',
    ),
    _SlideData(
      image: 'assets/logos/monte_ton_equipe.png',
      title: 'Monte ton équipe',
      body:
          'Crée ton équipe, choisis tes joueurs et place-les '
          'sur le terrain pour bâtir ta composition.',
    ),
    _SlideData(
      image: 'assets/logos/defie_autre_equipes.png',
      title: 'Défie d\'autres équipes',
      body:
          'Envoie un défi, cale la date et le lieu dans le chat, '
          'puis enregistre le score après le match.',
    ),
  ];

  @override
  void initState() {
    super.initState();

    // ── Logo ──
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    final logoCurve = CurvedAnimation(
      parent: _logoCtrl,
      curve: const Cubic(0.22, 1, 0.36, 1),
    );
    _orangeSlide = Tween<Offset>(
      begin: const Offset(-0.15, 0),
      end: Offset.zero,
    ).animate(logoCurve);
    _orangeFade = Tween<double>(begin: 0, end: 1).animate(logoCurve);
    _graySlide = Tween<Offset>(
      begin: const Offset(0.15, 0),
      end: Offset.zero,
    ).animate(logoCurve);
    _grayFade = _orangeFade;

    // ── Brand ──
    _brandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    final brandCurve = CurvedAnimation(
      parent: _brandCtrl,
      curve: Curves.easeOut,
    );
    _brandSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(brandCurve);
    _brandFade = Tween<double>(begin: 0, end: 1).animate(brandCurve);

    // ── Tagline ──
    _taglineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    final taglineCurve = CurvedAnimation(
      parent: _taglineCtrl,
      curve: Curves.easeOut,
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(taglineCurve);
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(taglineCurve);

    // ── Card ──
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    final cardCurve = CurvedAnimation(
      parent: _cardCtrl,
      curve: const Cubic(0.4, 0, 0.2, 1),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(cardCurve);
    _cardFade = Tween<double>(begin: 0, end: 1).animate(cardCurve);

    // ── Float loop ──
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _float = Tween<double>(
      begin: 0,
      end: -5,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    // ── Staggered starts ──
    Future.delayed(const Duration(milliseconds: 1250), () {
      if (mounted) _logoCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _brandCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) _taglineCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) _cardCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) _floatCtrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _brandCtrl.dispose();
    _taglineCtrl.dispose();
    _cardCtrl.dispose();
    _floatCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Background mesh + grid
          const KobetaBackdrop(),
          SafeArea(
            child: Column(
              children: [
                // Carrousel : révélation de la marque, puis les 3 slides
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      _buildLogoArea(),
                      ..._slides.map((s) => _FeatureSlide(slide: s)),
                    ],
                  ),
                ),
                // Dots
                _buildDots(),
                const SizedBox(height: 24),
                // Bottom card slides up from bottom
                FadeTransition(
                  opacity: _cardFade,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: _buildBottomCard(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo area ──────────────────────────────────────────────────────────
  Widget _buildLogoArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Floating hex logo
        AnimatedBuilder(
          animation: _float,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _float.value),
            child: child,
          ),
          child: SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              children: [
                // Orange layer (slides from left)
                FadeTransition(
                  opacity: _orangeFade,
                  child: SlideTransition(
                    position: _orangeSlide,
                    child: SvgPicture.string(
                      buildKobetaLogoSvg(
                        kLogoOrangePaths,
                        '#FF7F2A',
                        130,
                        'hexClipO',
                      ),
                      width: 130,
                      height: 130,
                    ),
                  ),
                ),
                // Gray layer (slides from right, on top)
                FadeTransition(
                  opacity: _grayFade,
                  child: SlideTransition(
                    position: _graySlide,
                    child: SvgPicture.string(
                      buildKobetaLogoSvg(
                        kLogoGrayPaths,
                        '#e6e6e6',
                        130,
                        'hexClipG',
                      ),
                      width: 130,
                      height: 130,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Brand wordmark "Ko" white + "beta" amber
        FadeTransition(
          opacity: _brandFade,
          child: SlideTransition(
            position: _brandSlide,
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
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
          ),
        ),
        const SizedBox(height: 8),
        // Tagline
        FadeTransition(
          opacity: _taglineFade,
          child: SlideTransition(
            position: _taglineSlide,
            child: const Text(
              'JOUER ENSEMBLE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: AppColors.muted2,
                letterSpacing: 3.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Dots ───────────────────────────────────────────────────────────────
  // Une pastille par page : la marque + les 3 slides.
  Widget _buildDots() {
    final count = _slides.length + 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? AppColors.amber
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  // ── Bottom card ────────────────────────────────────────────────────────
  Widget _buildBottomCard() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card2,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Prêt à jouer ?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Rejoins la communauté\net réserve ton prochain match.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w300,
              color: AppColors.muted2,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 22),
          // Primary gradient button → SignUp
          _GradientButton(
            label: 'Créer un compte',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignUpPage()),
            ),
          ),
          const SizedBox(height: 10),
          // Ghost button → Login
          _GhostButton(
            label: 'Se connecter',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ),
          ),
          // TODO: réactiver Google/Apple sign-in
          // const SizedBox(height: 16),
          // Row(children: [
          //   Expanded(child: Container(height: 1, color: AppColors.border)),
          //   const Padding(
          //     padding: EdgeInsets.symmetric(horizontal: 10),
          //     child: Text('OU CONTINUER AVEC',
          //         style: TextStyle(fontSize: 10, color: AppColors.muted,
          //             fontWeight: FontWeight.w600, letterSpacing: 1)),
          //   ),
          //   Expanded(child: Container(height: 1, color: AppColors.border)),
          // ]),
          // const SizedBox(height: 16),
          // Row(children: [
          //   Expanded(child: _SocialButton(label: 'Google',
          //       icon: Image.asset('assets/logos/google_logo_icon.png', height: 18),
          //       onTap: () {})),
          //   const SizedBox(width: 10),
          //   Expanded(child: _SocialButton(label: 'Apple',
          //       icon: Image.asset('assets/logos/apple_logo_icon.png', height: 18),
          //       onTap: () {})),
          // ]),
        ],
      ),
    );
  }
}

// ── Slides du carrousel ────────────────────────────────────────────────────

class _SlideData {
  final String image;
  final String title;
  final String body;

  const _SlideData({
    required this.image,
    required this.title,
    required this.body,
  });
}

class _FeatureSlide extends StatelessWidget {
  const _FeatureSlide({required this.slide});

  final _SlideData slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: AppColors.amber.withValues(alpha: 0.08),
                  blurRadius: 32,
                  spreadRadius: -8,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 3 / 2,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // L'illustration porte déjà son texte et ses icônes : pas
                    // de voile. Le léger zoom écarte le cadre incrusté au PNG.
                    Transform.scale(
                      scale: 1.06,
                      child: Image.asset(slide.image, fit: BoxFit.cover),
                    ),
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
                              Colors.white.withValues(alpha: 0.18),
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
          ),
          const SizedBox(height: 26),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w300,
              height: 1.6,
              color: AppColors.muted2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Buttons ────────────────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.amber, AppColors.amberD],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.amber.withValues(alpha: 0.32),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B0D11),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.border2, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size(double.infinity, 0),
        foregroundColor: AppColors.muted2,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.muted2,
        ),
      ),
    );
  }
}

// TODO: réactiver Google/Apple sign-in
// class _SocialButton extends StatelessWidget {
//   const _SocialButton({required this.label, required this.icon, required this.onTap});
//   final String label;
//   final Widget icon;
//   final VoidCallback onTap;
//   @override
//   Widget build(BuildContext context) {
//     return OutlinedButton.icon(
//       onPressed: onTap, icon: icon,
//       label: Text(label, style: const TextStyle(fontSize: 11,
//           fontWeight: FontWeight.w700, color: AppColors.muted2)),
//       style: OutlinedButton.styleFrom(
//         side: const BorderSide(color: AppColors.border2, width: 1),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         backgroundColor: AppColors.card, padding: const EdgeInsets.symmetric(vertical: 11),
//         foregroundColor: AppColors.muted2,
//       ),
//     );
//   }
// }

// Le fond (halos + grille) vit désormais dans widgets/kobeta_backdrop.dart,
// partagé avec l'onboarding.
