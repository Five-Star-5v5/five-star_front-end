import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'login.dart';
import 'signup.dart';

// ── Design tokens ──────────────────────────────────────────────────────────
const _kBg = Color(0xFF0E1014);
const _kCard = Color(0xFF181A21);
const _kCard2 = Color(0xFF1E2029);
const _kAmber = Color(0xFFFF7F2A);
const _kAmberD = Color(0xFFD96820);
const _kWhite = Color(0xFFF0F2F5);
const _kMuted2 = Color(0x9EF0F2F5); // 62%
const _kMuted = Color(0x61F0F2F5); // 38%
const _kBorder = Color(0x12FFFFFF); // 7%
const _kBorder2 = Color(0x2DFFFFFF); // 18%

// ── SVG strings ────────────────────────────────────────────────────────────
const _kOrangePaths =
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

const _kGrayPaths =
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

String _hexSvg(String pathData, String fillColor, String clipId) =>
    '''
<svg width="130" height="130" viewBox="0 0 130 130" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <clipPath id="$clipId">
      <polygon points="65,6 112,32 112,84 65,110 18,84 18,32"/>
    </clipPath>
  </defs>
  <g clip-path="url(#$clipId)">
    <g transform="translate(-6,4) scale(0.1234)">
      <path fill="$fillColor" d="$pathData"/>
    </g>
  </g>
</svg>
''';

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
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Background mesh + grid
          CustomPaint(painter: _BgPainter(), size: Size.infinite),
          SafeArea(
            child: Column(
              children: [
                // Logo area (flex = 1)
                Expanded(child: _buildLogoArea()),
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
                      _hexSvg(_kOrangePaths, '#FF7F2A', 'hexClipO'),
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
                      _hexSvg(_kGrayPaths, '#e6e6e6', 'hexClipG'),
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
                    style: TextStyle(color: _kWhite),
                  ),
                  TextSpan(
                    text: 'beta',
                    style: TextStyle(color: _kAmber),
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
                color: _kMuted2,
                letterSpacing: 3.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Dots ───────────────────────────────────────────────────────────────
  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Active dot (wider, amber)
        Container(
          width: 22,
          height: 6,
          decoration: BoxDecoration(
            color: _kAmber,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }

  // ── Bottom card ────────────────────────────────────────────────────────
  Widget _buildBottomCard() {
    return Container(
      decoration: const BoxDecoration(
        color: _kCard2,
        border: Border(top: BorderSide(color: _kBorder, width: 1)),
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
              color: _kWhite,
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
              color: _kMuted2,
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
          const SizedBox(height: 16),
          // Divider
          Row(
            children: [
              Expanded(child: Container(height: 1, color: _kBorder)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'OU CONTINUER AVEC',
                  style: TextStyle(
                    fontSize: 10,
                    color: _kMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(child: Container(height: 1, color: _kBorder)),
            ],
          ),
          const SizedBox(height: 16),
          // Social buttons
          Row(
            children: [
              Expanded(
                child: _SocialButton(
                  label: 'Google',
                  icon: Image.asset(
                    'assets/logos/google_logo_icon.png',
                    height: 18,
                  ),
                  onTap: () => debugPrint('Google'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SocialButton(
                  label: 'Apple',
                  icon: Image.asset(
                    'assets/logos/apple_logo_icon.png',
                    height: 18,
                  ),
                  onTap: () => debugPrint('Apple'),
                ),
              ),
            ],
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
              colors: [_kAmber, _kAmberD],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _kAmber.withValues(alpha: 0.32),
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
        side: const BorderSide(color: _kBorder2, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size(double.infinity, 0),
        foregroundColor: _kMuted2,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _kMuted2,
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: icon,
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _kMuted2,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _kBorder2, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: _kCard,
        padding: const EdgeInsets.symmetric(vertical: 11),
        foregroundColor: _kMuted2,
      ),
    );
  }
}

// ── Background painter ─────────────────────────────────────────────────────
class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Amber radial glow at top-center
    final amberGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.7),
        radius: 0.7,
        colors: [const Color(0xFFE8923A).withValues(alpha: 0.13), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, amberGlow);

    // Green radial glow at bottom-left
    final greenGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.7, 0.6),
        radius: 0.5,
        colors: [const Color(0xFF4CAF82).withValues(alpha: 0.06), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, greenGlow);

    // Grid lines 32px
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
