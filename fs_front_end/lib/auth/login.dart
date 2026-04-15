import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'signup.dart';
import 'welcome_page.dart';
import '../providers/auth_provider.dart';
import '../main_screen.dart';

// ── Design tokens ───────────────────────────────────────────────────────────
const _kBg = Color(0xFF0A0C10);
const _kNight = Color(0xFF0B0D11);
const _kCard = Color(0xFF181A21);
const _kAmber = Color(0xFFFF7F2A);
const _kAmberSoft = Color(0xFFFF9A55);
const _kAmberD = Color(0xFFD96820);
const _kSage = Color(0xFF4CAF82);
const _kWhite = Color(0xFFF0F2F5);
const _kMuted2 = Color(0x9EF0F2F5);
const _kMuted = Color(0x61F0F2F5);
const _kBorder = Color(0x12FFFFFF);
const _kBorder2 = Color(0x21FFFFFF);
const _kFocusedBg = Color(0xFF1C1510);
const _kFocusedBorder = Color(0x80FF7F2A);
const _kValidBorder = Color(0x664CAF82);

// ── SVG helpers (reused from welcome page) ──────────────────────────────────
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

String _hexSvg(String pathData, String fillColor, String clipId) => '''
<svg width="36" height="36" viewBox="0 0 130 130" xmlns="http://www.w3.org/2000/svg">
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

// ── Widget ──────────────────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  final String? successMessage;

  const LoginPage({super.key, this.successMessage});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _usernameFocused = false;
  bool _passwordFocused = false;
  bool _passwordVisible = false;
  bool _usernameValid = false;

  @override
  void initState() {
    super.initState();

    _usernameFocus.addListener(() {
      setState(() => _usernameFocused = _usernameFocus.hasFocus);
    });
    _passwordFocus.addListener(() {
      setState(() => _passwordFocused = _passwordFocus.hasFocus);
    });
    _usernameController.addListener(() {
      setState(
        () => _usernameValid = _usernameController.text.trim().isNotEmpty,
      );
    });

    if (widget.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.successMessage!),
              backgroundColor: _kSage,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    final res = await auth.login(username, password);

    if (!mounted) return;

    if (res['ok'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Erreur de connexion'),
          backgroundColor: const Color(0xFFD4607A),
        ),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Amber glow at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -1),
                  radius: 1.2,
                  colors: [Color(0x1AFF7F2A), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        _buildBrandMini(),
                        const SizedBox(height: 24),
                        _buildUsernameField(),
                        _buildPasswordField(),
                        _buildForgotPassword(),
                        const SizedBox(height: 4),
                        _buildLoginButton(),
                        const SizedBox(height: 16),
                        _buildDivider(),
                        const SizedBox(height: 14),
                        _buildSocialButtons(),
                        const SizedBox(height: 16),
                        _buildAuthLink(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── App bar ──────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const WelcomePage()),
            ),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _kCard,
                shape: BoxShape.circle,
                border: Border.all(color: _kBorder2, width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 14,
                color: _kWhite,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'CONNEXION',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _kMuted2,
                letterSpacing: 0.08 * 12,
              ),
            ),
          ),
          const SizedBox(width: 34), // spacer mirror
        ],
      ),
    );
  }

  // ── Brand mini ───────────────────────────────────────────────────────────
  Widget _buildBrandMini() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              children: [
                SvgPicture.string(
                  _hexSvg(_kOrangePaths, '#FF7F2A', 'lgnHexO'),
                  width: 36,
                  height: 36,
                ),
                SvgPicture.string(
                  _hexSvg(_kGrayPaths, '#e6e6e6', 'lgnHexG'),
                  width: 36,
                  height: 36,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1,
              ),
              children: [
                TextSpan(text: 'Ko', style: TextStyle(color: _kWhite)),
                TextSpan(text: 'beta', style: TextStyle(color: _kAmber)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Username field ───────────────────────────────────────────────────────
  Widget _buildUsernameField() {
    final isFocused = _usernameFocused;
    final isValid = _usernameValid && !isFocused;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NOM D\'UTILISATEUR',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _kMuted2,
            letterSpacing: 0.16 * 10,
          ),
        ),
        const SizedBox(height: 5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isFocused ? _kFocusedBg : _kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isValid
                  ? _kValidBorder
                  : isFocused
                      ? _kFocusedBorder
                      : _kBorder2,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 13),
                child: Icon(Icons.person_outline_rounded, size: 16, color: _kMuted),
              ),
              Expanded(
                child: TextField(
                  controller: _usernameController,
                  focusNode: _usernameFocus,
                  style: const TextStyle(fontSize: 13, color: _kWhite),
                  decoration: const InputDecoration(
                    hintText: 'Ton nom d\'utilisateur',
                    hintStyle: TextStyle(fontSize: 13, color: _kMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 10,
                    ),
                  ),
                ),
              ),
              if (isValid)
                const Padding(
                  padding: EdgeInsets.only(right: 13),
                  child: Icon(Icons.check_rounded, size: 14, color: _kSage),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ── Password field ───────────────────────────────────────────────────────
  Widget _buildPasswordField() {
    final isFocused = _passwordFocused;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MOT DE PASSE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _kMuted2,
            letterSpacing: 0.16 * 10,
          ),
        ),
        const SizedBox(height: 5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isFocused ? _kFocusedBg : _kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFocused ? _kFocusedBorder : _kBorder2,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 13),
                child: Icon(Icons.lock_outline_rounded, size: 16, color: _kMuted),
              ),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: !_passwordVisible,
                  style: const TextStyle(fontSize: 13, color: _kWhite),
                  decoration: const InputDecoration(
                    hintText: '••••••••',
                    hintStyle: TextStyle(fontSize: 13, color: _kMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 10,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _passwordVisible = !_passwordVisible),
                child: Padding(
                  padding: const EdgeInsets.only(right: 13),
                  child: Icon(
                    _passwordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 14,
                    color: _kMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Forgot password ──────────────────────────────────────────────────────
  Widget _buildForgotPassword() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/forgot_password'),
          child: const Text(
            'MOT DE PASSE OUBLIÉ ?',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _kAmber,
              letterSpacing: 0.06 * 10,
            ),
          ),
        ),
      ),
    );
  }

  // ── Login button ─────────────────────────────────────────────────────────
  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            onTap: auth.isLoading ? null : _login,
            borderRadius: BorderRadius.circular(13),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kAmberSoft, _kAmberD],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: _kAmber.withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                alignment: Alignment.center,
                child: auth.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _kNight,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'SE CONNECTER',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _kNight,
                              letterSpacing: 0.06 * 14,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 16, color: _kNight),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Divider ──────────────────────────────────────────────────────────────
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: _kBorder)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'OU CONTINUER AVEC',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _kMuted,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: _kBorder)),
      ],
    );
  }

  // ── Social buttons ───────────────────────────────────────────────────────
  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _SocialBtn(
            label: 'Google',
            icon: Image.asset('assets/logos/google_logo_icon.png', height: 16),
            onTap: () => debugPrint('Google'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SocialBtn(
            label: 'Apple',
            icon: Image.asset('assets/logos/apple_logo_icon.png', height: 16),
            onTap: () => debugPrint('Apple'),
          ),
        ),
      ],
    );
  }

  // ── Auth link ─────────────────────────────────────────────────────────────
  Widget _buildAuthLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignUpPage()),
        ),
        child: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 12, color: _kMuted2),
            children: [
              TextSpan(text: 'Pas encore de compte ? '),
              TextSpan(
                text: "S'INSCRIRE",
                style: TextStyle(
                  color: _kAmber,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.04 * 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Social button ────────────────────────────────────────────────────────────
class _SocialBtn extends StatelessWidget {
  const _SocialBtn({
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
          letterSpacing: 0.05 * 11,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _kBorder2, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        backgroundColor: _kCard,
        padding: const EdgeInsets.symmetric(vertical: 11),
        foregroundColor: _kMuted2,
      ),
    );
  }
}
