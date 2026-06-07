import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../auth/login.dart';
import '../services/contact_service.dart';
import 'edit_profile_page.dart';
import 'tos_page.dart';
import '../theme/app_colors.dart';

class SettingsPage extends StatelessWidget {
  final AuthProvider authProvider;

  const SettingsPage({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.card2,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border2),
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.muted2, size: 16),
          ),
        ),
        title: Text(
          'PARAMÈTRES',
          style: GoogleFonts.syne(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
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
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          // ── Section COMPTE ──────────────────────────────────────────────────
          _sectionLabel('COMPTE'),
          const SizedBox(height: 8),

          // Modifier le profil
          _buildRow(
            icon: Icons.edit_outlined,
            iconColor: AppColors.amber,
            iconBg: AppColors.amberDim,
            label: 'Modifier le profil',
            subtitle: 'Mettre à jour mes informations',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfilePage()),
            ),
          ),
          const SizedBox(height: 8),

          // ── Section APPARENCE ────────────────────────────────────────────────
          const SizedBox(height: 16),
          _sectionLabel('APPARENCE'),
          const SizedBox(height: 8),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return _buildToggleRow(
                icon: themeProvider.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                iconColor: AppColors.amber,
                iconBg: AppColors.amberDim,
                label: themeProvider.isDark ? 'Thème sombre' : 'Thème clair',
                subtitle: 'Changer l\'apparence de l\'application',
                value: themeProvider.isDark,
                onToggle: () => themeProvider.toggleTheme(),
              );
            },
          ),

          // ── Section SUPPORT ─────────────────────────────────────────────────
          const SizedBox(height: 16),
          _sectionLabel('SUPPORT'),
          const SizedBox(height: 8),

          _buildRow(
            icon: Icons.mail_outline,
            iconColor: AppColors.amber,
            iconBg: AppColors.amberDim,
            label: 'Nous contacter',
            subtitle: 'Envoyer un message à l\'équipe Kobeta',
            onTap: () => _showContactDialog(context),
          ),
          const SizedBox(height: 8),

          _buildRow(
            icon: Icons.description_outlined,
            iconColor: AppColors.amber,
            iconBg: AppColors.amberDim,
            label: "Conditions d'utilisation",
            subtitle: 'CGU — Version 1.1 — 19 mai 2026',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TosPage()),
            ),
          ),

          // ── Section DANGER ──────────────────────────────────────────────────
          const SizedBox(height: 16),
          _sectionLabel('ZONE DANGER'),
          const SizedBox(height: 8),

          // Supprimer le compte
          _buildRow(
            icon: Icons.delete_outline,
            iconColor: AppColors.rose,
            iconBg: AppColors.roseDim,
            label: 'Supprimer mon compte',
            subtitle: 'Action irréversible',
            trailingColor: AppColors.rose,
            onTap: () => _showDeleteAccountDialog(context),
          ),
        ],
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: GoogleFonts.syne(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: AppColors.muted2,
        ),
      ),
    );
  }

  // ── Row item ───────────────────────────────────────────────────────────────
  Widget _buildRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String subtitle,
    Color? trailingColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border2),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.syne(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: trailingColor ?? AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted2),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: trailingColor ?? AppColors.muted2,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ── Toggle row ─────────────────────────────────────────────────────────────
  Widget _buildToggleRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String subtitle,
    required bool value,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border2),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.syne(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted2),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: (_) => onToggle(),
              activeThumbColor: AppColors.amber,
              activeTrackColor: AppColors.amberDim,
              inactiveThumbColor: AppColors.muted2,
              inactiveTrackColor: AppColors.card2,
            ),
          ],
        ),
      ),
    );
  }

  // ── Contact dialog ─────────────────────────────────────────────────────────
  void _showContactDialog(BuildContext context) {
    final emailController = TextEditingController(text: authProvider.currentUser?.email ?? '');
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isLoading = false;
        String? errorMsg;

        return StatefulBuilder(
          builder: (ctx, setDialog) {
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.amberDim,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.mail_outline, color: AppColors.amber, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Nous contacter',
                          style: GoogleFonts.syne(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Email field
                    Text(
                      'Votre email',
                      style: GoogleFonts.syne(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: AppColors.muted2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.white),
                      cursorColor: AppColors.amber,
                      decoration: InputDecoration(
                        hintText: 'votre@email.com',
                        hintStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted2),
                        filled: true,
                        fillColor: AppColors.card2,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Message field
                    Text(
                      'Votre message',
                      style: GoogleFonts.syne(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: AppColors.muted2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: messageController,
                      maxLines: 5,
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.white),
                      cursorColor: AppColors.amber,
                      decoration: InputDecoration(
                        hintText: 'Décrivez votre problème ou votre demande…',
                        hintStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted2),
                        filled: true,
                        fillColor: AppColors.card2,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        alignLabelWithHint: true,
                      ),
                    ),

                    // Error message
                    if (errorMsg != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorMsg!,
                        style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.rose),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(dialogContext).pop(),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.card2,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border2),
                              ),
                              child: Center(
                                child: Text(
                                  'Annuler',
                                  style: GoogleFonts.syne(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.muted2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: isLoading
                                ? null
                                : () async {
                                    final email = emailController.text.trim();
                                    final msg = messageController.text.trim();

                                    if (email.isEmpty) {
                                      setDialog(() => errorMsg = 'Veuillez saisir votre email.');
                                      return;
                                    }
                                    if (msg.isEmpty) {
                                      setDialog(() => errorMsg = 'Veuillez écrire un message.');
                                      return;
                                    }

                                    setDialog(() { isLoading = true; errorMsg = null; });

                                    try {
                                      await ContactService.send(
                                        fromEmail: email,
                                        message: msg,
                                      );
                                      if (context.mounted) Navigator.of(dialogContext).pop();
                                      if (context.mounted) {
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Message envoyé ! Un email de confirmation a été envoyé à $email.',
                                                  style: GoogleFonts.dmSans(fontSize: 13),
                                                ),
                                                backgroundColor: AppColors.amber,
                                                duration: const Duration(seconds: 4),
                                              ),
                                            );
                                          }
                                        });
                                      }
                                    } catch (_) {
                                      setDialog(() {
                                        isLoading = false;
                                        errorMsg = 'Erreur lors de l\'envoi. Réessayez.';
                                      });
                                    }
                                  },
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.amberDim,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.amber, width: 1.5),
                              ),
                              child: Center(
                                child: isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: AppColors.amber,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Envoyer',
                                        style: GoogleFonts.syne(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
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
              ),
            );
          },
        );
      },
    ).then((_) {
      emailController.dispose();
      messageController.dispose();
    });
  }

  // ── Delete account dialog ──────────────────────────────────────────────────
  void _showDeleteAccountDialog(BuildContext context) {
    final TextEditingController confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.roseDim,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.warning_amber_outlined,
                        color: AppColors.rose,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Supprimer le compte',
                      style: GoogleFonts.syne(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.rose,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Warning list
                Text(
                  'Cette action est IRRÉVERSIBLE et entraînera :',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 10),
                ...[
                  'Suppression de toutes vos données personnelles',
                  'Suppression de vos équipes (si propriétaire)',
                  'Retrait de toutes les équipes dont vous êtes membre',
                  'Suppression de votre historique de matchs',
                  'Suppression de tous vos messages',
                ].map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppColors.rose,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.muted2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Confirmation field
                Text(
                  'Tapez "SUPPRIMER" pour confirmer :',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmController,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.syne(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppColors.white,
                  ),
                  cursorColor: AppColors.rose,
                  decoration: InputDecoration(
                    hintText: 'SUPPRIMER',
                    hintStyle: GoogleFonts.syne(
                      fontSize: 13,
                      letterSpacing: 2,
                      color: AppColors.muted2,
                    ),
                    filled: true,
                    fillColor: AppColors.card2,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.rose, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.card2,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border2),
                          ),
                          child: Center(
                            child: Text(
                              'Annuler',
                              style: GoogleFonts.syne(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatefulBuilder(
                        builder: (ctx, setBtn) {
                          return GestureDetector(
                            onTap: () async {
                              if (confirmController.text == 'SUPPRIMER') {
                                Navigator.of(dialogContext).pop();
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.rose,
                                    ),
                                  ),
                                );
                                final success = await authProvider
                                    .deleteAccount();
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                                if (success) {
                                  if (context.mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (_) => const LoginPage(
                                          successMessage:
                                              'Votre compte a été supprimé avec succès',
                                        ),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Erreur lors de la suppression du compte',
                                        ),
                                        backgroundColor: AppColors.rose,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Veuillez taper "SUPPRIMER" pour confirmer',
                                    ),
                                    backgroundColor: AppColors.rose,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.roseDim,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.rose, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  'Supprimer',
                                  style: GoogleFonts.syne(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.rose,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
}
