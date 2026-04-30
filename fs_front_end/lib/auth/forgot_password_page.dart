import 'package:flutter/material.dart';
import '../services/auth_service.dart';

// ── Design tokens (même palette que login.dart) ──────────────────────────────
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
const _kBorder2 = Color(0x21FFFFFF);
const _kFocusedBg = Color(0xFF1C1510);
const _kFocusedBorder = Color(0x80FF7F2A);
const _kRose = Color(0xFFD4607A);

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // Étape 1 : email — Étape 2 : code + nouveau mot de passe
  int _step = 1;
  bool _isLoading = false;
  bool _success = false;

  // Étape 1
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  bool _emailFocused = false;

  // Étape 2
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _tokenFocus = FocusNode();
  final _newPasswordFocus = FocusNode();
  bool _tokenFocused = false;
  bool _newPasswordFocused = false;
  bool _newPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() => _emailFocused = _emailFocus.hasFocus));
    _tokenFocus.addListener(() => setState(() => _tokenFocused = _tokenFocus.hasFocus));
    _newPasswordFocus.addListener(() => setState(() => _newPasswordFocused = _newPasswordFocus.hasFocus));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    _tokenFocus.dispose();
    _newPasswordFocus.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _requestReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Saisis une adresse email valide');
      return;
    }

    setState(() => _isLoading = true);
    final res = await AuthService.instance.requestPasswordReset(email: email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['ok'] == true) {
      setState(() => _step = 2);
    } else {
      _showError(res['message']?.toString() ?? 'Erreur lors de la demande');
    }
  }

  Future<void> _confirmReset() async {
    final token = _tokenController.text.trim();
    final password = _newPasswordController.text;

    if (token.isEmpty) {
      _showError('Entre le code reçu par email');
      return;
    }
    if (password.length < 8) {
      _showError('Le mot de passe doit faire au moins 8 caractères');
      return;
    }

    setState(() => _isLoading = true);
    final res = await AuthService.instance.confirmPasswordReset(
      token: token,
      newPassword: password,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['ok'] == true) {
      setState(() => _success = true);
    } else {
      _showError(res['message']?.toString() ?? 'Code invalide ou expiré');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: _kRose),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Amber glow en haut
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
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
                    child: _success ? _buildSuccess() : _buildForm(),
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
          GestureDetector(
            onTap: () => _step == 2 && !_success
                ? setState(() => _step = 1)
                : Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder2),
              ),
              child: const Icon(Icons.arrow_back_ios_rounded, size: 14, color: _kWhite),
            ),
          ),
        ],
      ),
    );
  }

  // ── Formulaire ───────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        _buildHeader(),
        const SizedBox(height: 32),
        if (_step == 1) ...[
          _buildEmailField(),
          const SizedBox(height: 24),
          _buildActionButton(
            label: 'ENVOYER LE CODE',
            onTap: _requestReset,
          ),
        ] else ...[
          _buildStep2Info(),
          const SizedBox(height: 20),
          _buildTokenField(),
          const SizedBox(height: 16),
          _buildNewPasswordField(),
          const SizedBox(height: 24),
          _buildActionButton(
            label: 'RÉINITIALISER',
            onTap: _confirmReset,
          ),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _kAmber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.lock_reset_rounded, color: _kAmber, size: 22),
        ),
        const SizedBox(height: 16),
        Text(
          _step == 1 ? 'MOT DE PASSE\nOUBLIÉ ?' : 'NOUVEAU\nMOT DE PASSE',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _kWhite,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _step == 1
              ? 'Saisis ton adresse email et on t\'envoie un code de réinitialisation.'
              : 'Entre le code reçu par email et choisis un nouveau mot de passe.',
          style: const TextStyle(fontSize: 13, color: _kMuted2, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildStep2Info() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSage.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kSage.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.email_outlined, size: 14, color: _kSage),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Code envoyé à ${_emailController.text.trim()}',
              style: const TextStyle(fontSize: 12, color: _kSage),
            ),
          ),
        ],
      ),
    );
  }

  // ── Champs ───────────────────────────────────────────────────────────────

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ADRESSE EMAIL',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _kMuted2,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _emailFocused ? _kFocusedBg : _kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _emailFocused ? _kFocusedBorder : _kBorder2,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 13),
                child: Icon(Icons.alternate_email_rounded, size: 16, color: _kMuted),
              ),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _requestReset(),
                  style: const TextStyle(fontSize: 13, color: _kWhite),
                  decoration: const InputDecoration(
                    hintText: 'ton@email.com',
                    hintStyle: TextStyle(fontSize: 13, color: _kMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 13, horizontal: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTokenField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CODE DE RÉINITIALISATION',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _kMuted2,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _tokenFocused ? _kFocusedBg : _kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _tokenFocused ? _kFocusedBorder : _kBorder2,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 13),
                child: Icon(Icons.tag_rounded, size: 16, color: _kMuted),
              ),
              Expanded(
                child: TextField(
                  controller: _tokenController,
                  focusNode: _tokenFocus,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(fontSize: 13, color: _kWhite, letterSpacing: 2),
                  decoration: const InputDecoration(
                    hintText: 'Code reçu par email',
                    hintStyle: TextStyle(fontSize: 13, color: _kMuted, letterSpacing: 0),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 13, horizontal: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NOUVEAU MOT DE PASSE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _kMuted2,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _newPasswordFocused ? _kFocusedBg : _kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _newPasswordFocused ? _kFocusedBorder : _kBorder2,
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
                  controller: _newPasswordController,
                  focusNode: _newPasswordFocus,
                  obscureText: !_newPasswordVisible,
                  style: const TextStyle(fontSize: 13, color: _kWhite),
                  decoration: const InputDecoration(
                    hintText: '8 caractères minimum',
                    hintStyle: TextStyle(fontSize: 13, color: _kMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 13, horizontal: 10),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _newPasswordVisible = !_newPasswordVisible),
                child: Padding(
                  padding: const EdgeInsets.only(right: 13),
                  child: Icon(
                    _newPasswordVisible
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

  // ── Bouton action ────────────────────────────────────────────────────────

  Widget _buildActionButton({required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: _isLoading ? null : onTap,
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
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _kNight),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kNight,
                          letterSpacing: 0.84,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: _kNight),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Écran de succès ──────────────────────────────────────────────────────

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 80),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _kSage.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: _kSage, size: 36),
        ),
        const SizedBox(height: 24),
        const Text(
          'Mot de passe\nréinitialisé !',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _kWhite,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Tu peux maintenant te connecter avec\nton nouveau mot de passe.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: _kMuted2, height: 1.5),
        ),
        const SizedBox(height: 40),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            ),
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
              child: const SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SE CONNECTER',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kNight,
                          letterSpacing: 0.84,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: _kNight),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
