import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'signup.dart';
import 'welcome_page.dart';
import '../providers/auth_provider.dart';

import '../theme/app_colors.dart';
import '../widgets/kobeta_logo.dart';

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
              backgroundColor: AppColors.sage,
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
      // Ne pas pousser MainScreen ici : app.dart bascule déjà dessus dès que
      // `isAuthenticated` passe à true. En empiler une seconde instance, on se
      // retrouvait avec deux HomePage vivantes — et donc deux tutos superposés.
      // Il suffit de dépiler jusqu'à la route racine, devenue MainScreen.
      Navigator.popUntil(context, (r) => r.isFirst);
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
      backgroundColor: AppColors.bg,
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
                        const SizedBox(height: 48),
                        _buildBrandMini(),
                        const SizedBox(height: 36),
                        _buildUsernameField(),
                        _buildPasswordField(),
                        _buildForgotPassword(),
                        const SizedBox(height: 4),
                        _buildLoginButton(),
                        const SizedBox(height: 16),
                        // TODO: réactiver Google/Apple sign-in
                        // _buildDivider(),
                        // const SizedBox(height: 14),
                        // _buildSocialButtons(),
                        // const SizedBox(height: 16),
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
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border2, width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 14,
                color: AppColors.white,
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
                color: AppColors.muted2,
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
          const KobetaLogo(size: 36),
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
            color: AppColors.muted2,
            letterSpacing: 0.16 * 10,
          ),
        ),
        const SizedBox(height: 5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isFocused ? AppColors.focusedBg : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isValid
                  ? AppColors.validBorder
                  : isFocused
                  ? AppColors.focusedBorder
                  : AppColors.border2,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 13),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: AppColors.muted,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _usernameController,
                  focusNode: _usernameFocus,
                  style: const TextStyle(fontSize: 13, color: AppColors.white),
                  decoration: const InputDecoration(
                    hintText: 'Ton nom d\'utilisateur',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.muted),
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
                  child: Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: AppColors.sage,
                  ),
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
            color: AppColors.muted2,
            letterSpacing: 0.16 * 10,
          ),
        ),
        const SizedBox(height: 5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isFocused ? AppColors.focusedBg : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFocused ? AppColors.focusedBorder : AppColors.border2,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 13),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: AppColors.muted,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: !_passwordVisible,
                  style: const TextStyle(fontSize: 13, color: AppColors.white),
                  decoration: const InputDecoration(
                    hintText: '••••••••',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.muted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 10,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
                child: Padding(
                  padding: const EdgeInsets.only(right: 13),
                  child: Icon(
                    _passwordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 14,
                    color: AppColors.muted,
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
              color: AppColors.amber,
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
                  colors: [AppColors.amberSoft, AppColors.amberD],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.amber.withValues(alpha: 0.28),
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
                          color: AppColors.night,
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
                              color: AppColors.night,
                              letterSpacing: 0.06 * 14,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: AppColors.night,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  // TODO: réactiver Google/Apple sign-in
  // Widget _buildDivider() { ... }
  // Widget _buildSocialButtons() { ... }

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
            style: TextStyle(fontSize: 12, color: AppColors.muted2),
            children: [
              TextSpan(text: 'Pas encore de compte ? '),
              TextSpan(
                text: "S'INSCRIRE",
                style: TextStyle(
                  color: AppColors.amber,
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

// TODO: réactiver Google/Apple sign-in
// class _SocialBtn extends StatelessWidget { ... }
