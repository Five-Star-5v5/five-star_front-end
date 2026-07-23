import 'package:flutter/material.dart';
import 'package:five_star_5v5/theme/app_typography.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../theme/app_colors.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  XFile? _selectedImage;

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
    String? newAvatarUrl;
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
      final imageBytes = await _selectedImage!.readAsBytes();
      newAvatarUrl = await CloudinaryService.instance.uploadAvatar(
        imageBytes,
        currentUser.id,
      );

      if (!mounted) return;

      if (newAvatarUrl == null) {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du upload de l\'image'),
            backgroundColor: Color(0xFFD4607A),
          ),
        );
        return;
      }

      // Enlever le cache buster avant de sauvegarder
      final cleanUrl = newAvatarUrl.split('?').first;
      newAvatarUrl = cleanUrl;

      // 2️⃣ Pas besoin de supprimer l'ancienne image — Cloudinary la remplace automatiquement
    }

    // 3️⃣ Sauvegarder les infos au backend
    final result = await AuthService.instance.updateCurrentUser(
      phone: _phoneController.text.trim(),
      preferredPosition: _selectedPosition,
      avatarUrl: newAvatarUrl, // null si pas de nouvelle image
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['ok'] == true) {
      await authProvider.refreshCurrentUser();
      if (mounted) {
        setState(() {
          _selectedImage = null;
        });
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

  /// Sélectionne et crop une image depuis la galerie
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          // Sur web: pas de crop, utiliser l'image directement
          setState(() => _selectedImage = pickedFile);
        } else {
          // Sur mobile: crop en carré 1:1
          final croppedFile = await ImageCropper().cropImage(
            sourcePath: pickedFile.path,
            aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Crop Avatar',
                toolbarColor: const Color(0xFF181A21),
                toolbarWidgetColor: const Color(0xFFFF7F2A),
                initAspectRatio: CropAspectRatioPreset.square,
                lockAspectRatio: true,
              ),
              IOSUiSettings(title: 'Crop Avatar', minimumAspectRatio: 1.0),
            ],
          );

          if (croppedFile != null) {
            setState(() => _selectedImage = XFile(croppedFile.path));
          }
        }
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
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.muted2,
              size: 16,
            ),
          ),
        ),
        title: Text(
          'MODIFIER LE PROFIL',
          style: AppTypography.display(
            fontSize: 13,
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
                style: AppTypography.display(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mettez à jour vos informations de profil',
                style: AppTypography.body(
                  fontSize: 13,
                  color: AppColors.muted2,
                ),
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
                        colors: [AppColors.amberSoft, AppColors.amberD],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.amber, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.amber.withValues(alpha: 0.2),
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
                            child: FutureBuilder<Uint8List>(
                              key: ValueKey(_selectedImage!.path),
                              future: _selectedImage!.readAsBytes(),
                              builder: (_, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                    key: ValueKey(_selectedImage!.path),
                                  );
                                }
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
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
                                        style: AppTypography.display(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 32,
                                          color: AppColors.card,
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
                                  style: AppTypography.display(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 32,
                                    color: AppColors.card,
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
                        style: AppTypography.body(
                          fontSize: 11,
                          color: AppColors.muted2,
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
                              color: AppColors.amberDim,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Nouvelle image',
                              style: AppTypography.display(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.amber,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _selectedImage = null),
                            child: Text(
                              'Annuler',
                              style: AppTypography.body(
                                fontSize: 10,
                                color: AppColors.muted2,
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
                style: AppTypography.body(fontSize: 14, color: AppColors.white),
                cursorColor: AppColors.amber,
                decoration: InputDecoration(
                  hintText: 'Ex : 06 12 34 56 78',
                  hintStyle: AppTypography.body(
                    fontSize: 13,
                    color: AppColors.muted2,
                  ),
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.amber,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.amber,
                      width: 1.5,
                    ),
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
                style: AppTypography.body(fontSize: 14, color: AppColors.white),
                dropdownColor: AppColors.card2,
                iconEnabledColor: AppColors.muted2,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.sports_soccer_outlined,
                    color: AppColors.amber,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.amber,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                hint: Text(
                  'Sélectionnez votre poste',
                  style: AppTypography.body(
                    fontSize: 13,
                    color: AppColors.muted2,
                  ),
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
                      colors: [AppColors.amberSoft, AppColors.amberD],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.amber.withValues(alpha: 0.3),
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
                            style: AppTypography.display(
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
                    border: Border.all(color: AppColors.border2, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      'Annuler',
                      style: AppTypography.display(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted2,
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
      style: AppTypography.display(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: AppColors.muted2,
      ),
    );
  }
}
