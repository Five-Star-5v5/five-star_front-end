import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'login.dart';
import 'welcome_page.dart';
import '../providers/auth_provider.dart';
import '../pages/tos_page.dart';
import '../theme/app_colors.dart';
import '../widgets/kobeta_logo.dart';

// ── Validation règles (alignées avec le backend) ──────────────────────────────
final _reUsername = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
final _reUsernameChars = RegExp(r'[a-zA-Z0-9_]');
final _rePwdUpper = RegExp(r'[A-Z]');
final _rePwdLower = RegExp(r'[a-z]');
final _rePwdDigit = RegExp(r'\d');
final _rePwdSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/;`~]');

// ── Widget ────────────────────────────────────────────────────────────────────
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _usernameFocused = false;
  bool _emailFocused = false;
  bool _passwordFocused = false;
  bool _confirmFocused = false;

  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    _usernameFocus.addListener(
      () => setState(() => _usernameFocused = _usernameFocus.hasFocus),
    );
    _emailFocus.addListener(
      () => setState(() => _emailFocused = _emailFocus.hasFocus),
    );
    _passwordFocus.addListener(
      () => setState(() => _passwordFocused = _passwordFocus.hasFocus),
    );
    _confirmFocus.addListener(
      () => setState(() => _confirmFocused = _confirmFocus.hasFocus),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  // ── Validation helpers ────────────────────────────────────────────────────
  bool get _usernameValid =>
      _reUsername.hasMatch(_usernameController.text.trim());
  bool get _emailValid => RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+',
  ).hasMatch(_emailController.text.trim());
  bool get _passwordValid {
    final v = _passwordController.text;
    return v.length >= 8 &&
        _rePwdUpper.hasMatch(v) &&
        _rePwdLower.hasMatch(v) &&
        _rePwdDigit.hasMatch(v) &&
        _rePwdSpecial.hasMatch(v);
  }

  bool get _confirmValid =>
      _confirmController.text == _passwordController.text &&
      _confirmController.text.isNotEmpty;

  String? get _usernameError {
    final v = _usernameController.text.trim();
    if (v.isEmpty) return null;
    if (v.length < 3) return 'Au moins 3 caractères';
    if (v.length > 20) return 'Maximum 20 caractères';
    if (!_reUsername.hasMatch(v)) return 'Lettres, chiffres et _ uniquement';
    return null;
  }

  String? get _passwordError {
    final v = _passwordController.text;
    if (v.isEmpty) return null;
    if (v.length < 8) return 'Au moins 8 caractères';
    if (!_rePwdUpper.hasMatch(v)) return 'Une majuscule requise (A-Z)';
    if (!_rePwdLower.hasMatch(v)) return 'Une minuscule requise (a-z)';
    if (!_rePwdDigit.hasMatch(v)) return 'Un chiffre requis (0-9)';
    if (!_rePwdSpecial.hasMatch(v)) return 'Un symbole requis (!@#...)';
    return null;
  }

  void _signUp() {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmController.text;

    if (username.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _showSnack('Veuillez remplir tous les champs');
      return;
    }
    if (_usernameError != null) {
      _showSnack(_usernameError!);
      return;
    }
    if (!_emailValid) {
      _showSnack('Adresse email invalide');
      return;
    }
    if (_passwordError != null) {
      _showSnack(_passwordError!);
      return;
    }
    if (pass != confirm) {
      _showSnack('Les mots de passe ne correspondent pas');
      return;
    }
    if (!_acceptTerms) {
      _showSnack("Veuillez accepter les conditions d'utilisation");
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.signup(username, email, pass).then((res) {
      if (!mounted) return;
      if (res['ok'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LoginPage(
              successMessage: 'Compte créé ! Vous pouvez vous connecter.',
            ),
          ),
        );
      } else {
        _showSnack(res['message']?.toString() ?? 'Erreur lors de la création');
      }
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFD4607A)),
    );
  }

  // ── Password checklist (temps réel) ──────────────────────────────────────
  Widget _buildPasswordChecklist() {
    final v = _passwordController.text;
    if (v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2, bottom: 2),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          _pwdRule(v.length >= 8, '8 caractères min.'),
          _pwdRule(_rePwdUpper.hasMatch(v), 'Majuscule (A-Z)'),
          _pwdRule(_rePwdLower.hasMatch(v), 'Minuscule (a-z)'),
          _pwdRule(_rePwdDigit.hasMatch(v), 'Chiffre (0-9)'),
          _pwdRule(_rePwdSpecial.hasMatch(v), 'Symbole (!@#...)'),
        ],
      ),
    );
  }

  Widget _pwdRule(bool ok, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ok ? Icons.check_rounded : Icons.close_rounded,
          size: 11,
          color: ok ? AppColors.sage : const Color(0xFFD4607A),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: ok ? AppColors.sage : AppColors.muted2,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmMatch() {
    final v = _confirmController.text;
    if (v.isEmpty) return const SizedBox.shrink();
    final ok = v == _passwordController.text;
    return Padding(
      padding: const EdgeInsets.only(top: 5, left: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_rounded : Icons.close_rounded,
            size: 11,
            color: ok ? AppColors.sage : const Color(0xFFD4607A),
          ),
          const SizedBox(width: 3),
          Text(
            ok ? 'Mots de passe identiques' : 'Ne correspond pas',
            style: TextStyle(
              fontSize: 10,
              color: ok ? AppColors.sage : const Color(0xFFD4607A),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
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
                        const SizedBox(height: 4),
                        _buildBrandMini(),
                        const SizedBox(height: 24),
                        _buildField(
                          label: 'NOM D\'UTILISATEUR',
                          hint: '3-20 car. — lettres, chiffres, _',
                          controller: _usernameController,
                          focusNode: _usernameFocus,
                          isFocused: _usernameFocused,
                          isValid: _usernameValid && !_usernameFocused,
                          icon: Icons.person_outline_rounded,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(_reUsernameChars),
                            LengthLimitingTextInputFormatter(20),
                          ],
                          errorText: _usernameError,
                        ),
                        _buildField(
                          label: 'ADRESSE E-MAIL',
                          hint: 'ton@email.com',
                          controller: _emailController,
                          focusNode: _emailFocus,
                          isFocused: _emailFocused,
                          isValid: _emailValid && !_emailFocused,
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        _buildPasswordField(
                          label: 'MOT DE PASSE',
                          hint: '8 car. — maj, min, chiffre, symbole',
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          isFocused: _passwordFocused,
                          isValid: _passwordValid && !_passwordFocused,
                          isVisible: _passwordVisible,
                          onToggle: () => setState(
                            () => _passwordVisible = !_passwordVisible,
                          ),
                          extraContent: _buildPasswordChecklist(),
                        ),
                        _buildPasswordField(
                          label: 'CONFIRMER LE MOT DE PASSE',
                          hint: 'Répète ton mot de passe',
                          controller: _confirmController,
                          focusNode: _confirmFocus,
                          isFocused: _confirmFocused,
                          isValid: _confirmValid && !_confirmFocused,
                          isError:
                              _confirmController.text.isNotEmpty &&
                              !_confirmValid &&
                              !_confirmFocused,
                          isVisible: _confirmVisible,
                          onToggle: () => setState(
                            () => _confirmVisible = !_confirmVisible,
                          ),
                          extraContent: _buildConfirmMatch(),
                        ),
                        const SizedBox(height: 4),
                        _buildTermsRow(),
                        const SizedBox(height: 16),
                        _buildSignUpButton(),
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

  // ── App bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Row(
        children: [
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
              'INSCRIPTION',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.muted2,
                letterSpacing: 0.08 * 12,
              ),
            ),
          ),
          const SizedBox(width: 34),
        ],
      ),
    );
  }

  // ── Brand mini ────────────────────────────────────────────────────────────
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

  // ── Generic text field ────────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required bool isValid,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final showError = errorText != null && !isFocused;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
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
              color: showError
                  ? AppColors.errorBorder
                  : isValid
                  ? AppColors.validBorder
                  : isFocused
                  ? AppColors.focusedBorder
                  : AppColors.border2,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 13),
                child: Icon(icon, size: 16, color: AppColors.muted),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  style: const TextStyle(fontSize: 13, color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 10,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
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
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.errorBorder,
              ),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ── Password field ────────────────────────────────────────────────────────
  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required bool isValid,
    required bool isVisible,
    required VoidCallback onToggle,
    bool isError = false,
    String? errorText,
    Widget? extraContent,
  }) {
    final showError = (errorText != null || isError) && !isFocused;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
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
              color: showError
                  ? AppColors.errorBorder
                  : isValid
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
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: AppColors.muted,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: !isVisible,
                  style: const TextStyle(fontSize: 13, color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 10,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 13),
                  child: Icon(
                    isVisible
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
        if (showError && errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.errorBorder,
              ),
            ),
          ),
        if (extraContent != null) extraContent,
        const SizedBox(height: 12),
      ],
    );
  }

  // ── Terms row ─────────────────────────────────────────────────────────────
  Widget _buildTermsRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _acceptTerms = !_acceptTerms),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: _acceptTerms ? AppColors.amber : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: _acceptTerms ? AppColors.amber : AppColors.border2,
                width: 1.5,
              ),
            ),
            child: _acceptTerms
                ? const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: AppColors.night,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 11, color: AppColors.muted2),
              children: [
                const TextSpan(text: "J'accepte les "),
                TextSpan(
                  text: "conditions d'utilisation",
                  style: const TextStyle(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w700,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TosPage()),
                    ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Sign up button ────────────────────────────────────────────────────────
  Widget _buildSignUpButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            onTap: auth.isLoading ? null : _signUp,
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
                            'CRÉER MON COMPTE',
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
          MaterialPageRoute(builder: (_) => const LoginPage()),
        ),
        child: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 12, color: AppColors.muted2),
            children: [
              TextSpan(text: 'Déjà un compte ? '),
              TextSpan(
                text: 'SE CONNECTER',
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
