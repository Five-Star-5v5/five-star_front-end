import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _eBg = Color(0xFF0A0C10);
const _eCard = Color(0xFF181A21);
const _eCard2 = Color(0xFF1E2029);
const _eBorder2 = Color(0x21FFFFFF);
const _eAmber = Color(0xFFFF7F2A);
const _eAmberSoft = Color(0xFFFF9A55);
const _eAmberD = Color(0xFFD96820);
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

    setState(() => _isLoading = true);

    // Store context-dependent references before async gaps
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final result = await AuthService.instance.updateCurrentUser(
      phone: _phoneController.text.trim(),
      preferredPosition: _selectedPosition,
    );

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
