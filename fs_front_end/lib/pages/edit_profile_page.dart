import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _eBg = Color(0xFF0A0C10);
const _eCard = Color(0xFF181A21);
const _eCard2 = Color(0xFF1E2029);
const _eBorder2 = Color(0x21FFFFFF);
const _eAmber = Color(0xFFFF7F2A);
const _eAmberSoft = Color(0xFFFF9A55);
const _eAmberD = Color(0xFFD96820);
const _eAmberDim = Color(0x1CFF7F2A);
const _eWhite = Color(0xFFF0F2F5);
const _eMuted2 = Color(0x9EF0F2F5);

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _positionController = TextEditingController();
  bool _isLoading = false;
  File? _selectedImage;
  String? _newAvatarUrl;

  final List<String> _positions = [
    'Gardien',
    'Défenseur',
    'Milieu défensif',
    'Milieu offensif',
    'Ailier gauche',
    'Ailier droit',
    'Attaquant',
    'Buteur',
  ];

  String? _selectedPosition;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      _phoneController.text = user.phone ?? '';
      final userPosition = user.preferredPosition;
      if (userPosition != null && _positions.contains(userPosition)) {
        _selectedPosition = userPosition;
      } else {
        _selectedPosition = _mapPositionToFrench(userPosition);
      }
    }
  }

  String? _mapPositionToFrench(String? position) {
    if (position == null) return null;
    final lowerPos = position.toLowerCase();

    if (lowerPos.contains('goalkeeper') || lowerPos.contains('gardien')) {
      return 'Gardien';
    } else if (lowerPos.contains('defender') ||
        lowerPos.contains('défenseur')) {
      return 'Défenseur';
    } else if (lowerPos.contains('midfielder') || lowerPos.contains('milieu')) {
      return lowerPos.contains('defensive')
          ? 'Milieu défensif'
          : 'Milieu offensif';
    } else if (lowerPos.contains('forward') || lowerPos.contains('attaquant')) {
      return 'Attaquant';
    } else if (lowerPos.contains('winger') || lowerPos.contains('ailier')) {
      return 'Ailier droit';
    }

    for (final pos in _positions) {
      if (pos.toLowerCase() == lowerPos) return pos;
    }
    return null;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    // Store context-dependent references before async gaps
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // 1️⃣ Si nouvelle image sélectionnée, upload à Cloudinary
    if (_selectedImage != null) {
      if (currentUser == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          messenger.showSnackBar(
            const SnackBar(content: Text('Erreur: utilisateur non trouvé')),
          );
        }
        return;
      }

      // Upload la nouvelle image
      _newAvatarUrl = await CloudinaryService.instance.uploadAvatar(
        _selectedImage!,
        currentUser.id,
      );

      if (!mounted) return;

      if (_newAvatarUrl == null) {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du upload de l\'image'),
            backgroundColor: Color(0xFFD4607A),
          ),
        );
        return;
      }

      // 2️⃣ Supprimer l'ancienne image (si elle existe)
      if (currentUser.avatarUrl != null && currentUser.avatarUrl!.isNotEmpty) {
        final oldPublicId = CloudinaryService.extractPublicIdFromUrl(
          currentUser.avatarUrl,
        );
        if (oldPublicId != null) {
          await CloudinaryService.instance.deleteAvatar(oldPublicId);
        }
      }
    }

    // 3️⃣ Sauvegarder les infos au backend
    final result = await AuthService.instance.updateCurrentUser(
      phone: _phoneController.text.trim(),
      preferredPosition: _selectedPosition,
      avatarUrl: _newAvatarUrl, // null si pas de nouvelle image
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['ok'] == true) {
      await authProvider.refreshCurrentUser();
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès !'),
            backgroundColor: Color(0xFF4CAF82),
          ),
        );
        navigator.pop();
      }
    } else {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ?? 'Erreur lors de la mise à jour',
            ),
            backgroundColor: const Color(0xFFD4607A),
          ),
        );
      }
    }
  }

  /// Sélectionne une image depuis la galerie
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compresser à 80%
        maxWidth: 500,
        maxHeight: 500,
      );

      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _eBg,
      appBar: AppBar(
        backgroundColor: _eCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _eCard2,
              shape: BoxShape.circle,
              border: Border.all(color: _eBorder2),
            ),
            child: const Icon(Icons.arrow_back, color: _eMuted2, size: 16),
          ),
        ),
        title: Text(
          'MODIFIER LE PROFIL',
          style: GoogleFonts.syne(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: _eWhite,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Text(
                'Informations personnelles',
                style: GoogleFonts.syne(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _eWhite,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mettez à jour vos informations de profil',
                style: GoogleFonts.dmSans(fontSize: 13, color: _eMuted2),
              ),
              const SizedBox(height: 32),

              // ── Avatar ──────────────────────────────────────────────────────
              _fieldLabel('PHOTO DE PROFIL'),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: _isLoading ? null : _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_eAmberSoft, _eAmberD],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: _eAmber, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _eAmber.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 1️⃣ Image sélectionnée OU image actuelle OU initiale
                        if (_selectedImage != null)
                          ClipOval(
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Consumer<AuthProvider>(
                            builder: (ctx, auth, _) {
                              final currentUser = auth.currentUser;
                              final hasAvatar =
                                  currentUser?.avatarUrl != null &&
                                  currentUser!.avatarUrl!.isNotEmpty;

                              if (hasAvatar) {
                                return ClipOval(
                                  // The second ! is required by Image.network type signature
                                  // ignore: unnecessary_non_null_assertion
                                  child: Image.network(
                                    currentUser!.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Center(
                                      child: Text(
                                        currentUser.username.isNotEmpty
                                            ? currentUser.username[0]
                                                  .toUpperCase()
                                            : '?',
                                        style: GoogleFonts.syne(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 32,
                                          color: _eCard,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return Center(
                                child: Text(
                                  currentUser?.username.isNotEmpty == true
                                      ? currentUser!.username[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.syne(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 32,
                                    color: _eCard,
                                  ),
                                ),
                              );
                            },
                          ),
                        // 2️⃣ Overlay: icône caméra
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: _selectedImage == null
                    ? Text(
                        'Appuyez pour changer',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: _eMuted2,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _eAmberDim,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Nouvelle image',
                              style: GoogleFonts.syne(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _eAmber,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _selectedImage = null),
                            child: Text(
                              'Annuler',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color: _eMuted2,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 32),

              // ── Téléphone ────────────────────────────────────────────────
              _fieldLabel('NUMÉRO DE TÉLÉPHONE'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.dmSans(fontSize: 14, color: _eWhite),
                cursorColor: _eAmber,
                decoration: InputDecoration(
                  hintText: 'Ex : 06 12 34 56 78',
                  hintStyle: GoogleFonts.dmSans(fontSize: 13, color: _eMuted2),
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: _eAmber,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: _eCard,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _eBorder2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _eAmber, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFD4607A),
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFD4607A),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final phoneRegex = RegExp(r'^[0-9\s\+\-\.]+$');
                    if (!phoneRegex.hasMatch(value)) {
                      return 'Format de téléphone invalide';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ── Poste préféré ────────────────────────────────────────────
              _fieldLabel('POSTE PRÉFÉRÉ'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedPosition,
                style: GoogleFonts.dmSans(fontSize: 14, color: _eWhite),
                dropdownColor: _eCard2,
                iconEnabledColor: _eMuted2,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.sports_soccer_outlined,
                    color: _eAmber,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: _eCard,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _eBorder2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _eAmber, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                hint: Text(
                  'Sélectionnez votre poste',
                  style: GoogleFonts.dmSans(fontSize: 13, color: _eMuted2),
                ),
                items: _positions.map((pos) {
                  return DropdownMenuItem<String>(value: pos, child: Text(pos));
                }).toList(),
                onChanged: (value) => _selectedPosition = value,
              ),
              const SizedBox(height: 40),

              // ── Bouton Sauvegarder ─────────────────────────────────────
              GestureDetector(
                onTap: _isLoading ? null : _saveProfile,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_eAmberSoft, _eAmberD],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _eAmber.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Color(0xFF0B0D11),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'SAUVEGARDER',
                            style: GoogleFonts.syne(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: const Color(0xFF0B0D11),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Bouton Annuler ─────────────────────────────────────────
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _eBorder2, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      'Annuler',
                      style: GoogleFonts.syne(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _eMuted2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.syne(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: _eMuted2,
      ),
    );
  }
}
