import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../auth/login.dart';
import 'edit_profile_page.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _sBg = Color(0xFF0A0C10);
const _sCard = Color(0xFF181A21);
const _sCard2 = Color(0xFF1E2029);
const _sBorder2 = Color(0x21FFFFFF);
const _sAmber = Color(0xFFFF7F2A);
const _sAmberDim = Color(0x1CFF7F2A);
const _sRose = Color(0xFFD4607A);
const _sRoseDim = Color(0x1CD4607A);
const _sWhite = Color(0xFFF0F2F5);
const _sMuted2 = Color(0x9EF0F2F5);

class SettingsPage extends StatelessWidget {
  final AuthProvider authProvider;

  const SettingsPage({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _sBg,
      appBar: AppBar(
        backgroundColor: _sCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _sCard2,
              shape: BoxShape.circle,
              border: Border.all(color: _sBorder2),
            ),
            child: const Icon(Icons.arrow_back, color: _sMuted2, size: 16),
          ),
        ),
        title: Text(
          'PARAMÈTRES',
          style: GoogleFonts.syne(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: _sWhite,
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
            iconColor: _sAmber,
            iconBg: _sAmberDim,
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
                iconColor: _sAmber,
                iconBg: _sAmberDim,
                label: themeProvider.isDark ? 'Thème sombre' : 'Thème clair',
                subtitle: 'Changer l\'apparence de l\'application',
                value: themeProvider.isDark,
                onToggle: () => themeProvider.toggleTheme(),
              );
            },
          ),

          // ── Section DANGER ──────────────────────────────────────────────────
          const SizedBox(height: 16),
          _sectionLabel('ZONE DANGER'),
          const SizedBox(height: 8),

          // Supprimer le compte
          _buildRow(
            icon: Icons.delete_outline,
            iconColor: _sRose,
            iconBg: _sRoseDim,
            label: 'Supprimer mon compte',
            subtitle: 'Action irréversible',
            trailingColor: _sRose,
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
          color: _sMuted2,
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
          color: _sCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _sBorder2),
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
                      color: trailingColor ?? _sWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(fontSize: 11, color: _sMuted2),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: trailingColor ?? _sMuted2,
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
          color: _sCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _sBorder2),
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
                      color: _sWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(fontSize: 11, color: _sMuted2),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: (_) => onToggle(),
              activeThumbColor: _sAmber,
              activeTrackColor: _sAmberDim,
              inactiveThumbColor: _sMuted2,
              inactiveTrackColor: _sCard2,
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete account dialog ──────────────────────────────────────────────────
  void _showDeleteAccountDialog(BuildContext context) {
    final TextEditingController confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: _sCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _sBorder2),
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
                        color: _sRoseDim,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.warning_amber_outlined,
                        color: _sRose,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Supprimer le compte',
                      style: GoogleFonts.syne(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _sRose,
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
                    color: _sWhite,
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
                              color: _sRose,
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
                              color: _sMuted2,
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
                    color: _sWhite,
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
                    color: _sWhite,
                  ),
                  cursorColor: _sRose,
                  decoration: InputDecoration(
                    hintText: 'SUPPRIMER',
                    hintStyle: GoogleFonts.syne(
                      fontSize: 13,
                      letterSpacing: 2,
                      color: _sMuted2,
                    ),
                    filled: true,
                    fillColor: _sCard2,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _sBorder2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _sRose, width: 1.5),
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
                            color: _sCard2,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _sBorder2),
                          ),
                          child: Center(
                            child: Text(
                              'Annuler',
                              style: GoogleFonts.syne(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _sMuted2,
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
                                      color: _sRose,
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
                                        backgroundColor: _sRose,
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
                                    backgroundColor: _sRose,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: _sRoseDim,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _sRose, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  'Supprimer',
                                  style: GoogleFonts.syne(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _sRose,
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
