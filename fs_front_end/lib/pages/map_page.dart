import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/fields_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/teams_provider.dart';
import '../services/fields_service.dart';
import '../services/teams_service.dart';
import '../main_screen.dart';

// ── Kobeta hex logo SVG paths ─────────────────────────────────────────────
const _mpLogoOrange =
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

const _mpLogoGray =
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

String _mpLogoHexSvg(String d, String fill, String id) => '''
<svg width="40" height="40" viewBox="0 0 130 130" xmlns="http://www.w3.org/2000/svg">
  <defs><clipPath id="$id"><polygon points="65,6 112,32 112,84 65,110 18,84 18,32"/></clipPath></defs>
  <g clip-path="url(#\$$id)"><g transform="translate(-6,4) scale(0.1234)"><path fill="$fill" d="$d"/></g></g>
</svg>
''';

// ── Design tokens ─────────────────────────────────────────────────────────
const _kAmber = Color(0xFFFF7F2A);
const _kAmberSoft = Color(0xFFFF9A52);
const _kAmberDark = Color(0xFFd96820);
const _kAmberDim = Color(0x1CFF7F2A);
const _kCard = Color(0xFF181A21);
const _kCard2 = Color(0xFF1E2029);
const _kNight = Color(0xFF0B0D11);
const _kBg = Color(0xFF0A0C10);
const _kWhite = Color(0xFFF0F2F5);
const _kMuted2 = Color(0x9EF0F2F5);
const _kBorder = Color(0x12FFFFFF);
const _kBorder2 = Color(0x2DFFFFFF);
const _kSage = Color(0xFF4CAF82);
const _kRose = Color(0xFFD4607A);

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  SoccerField? _selectedField;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FieldsProvider>().initialize();
    });
  }

  void _centerOnUserLocation() {
    final provider = context.read<FieldsProvider>();
    if (provider.currentPosition != null) {
      _mapController.move(
        LatLng(
          provider.currentPosition!.latitude,
          provider.currentPosition!.longitude,
        ),
        14.0,
      );
    }
  }

  void _selectField(SoccerField field) {
    setState(() => _selectedField = field);
    _mapController.move(LatLng(field.latitude, field.longitude), 16.0);
  }

  Future<void> _openInMaps(SoccerField field) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${field.latitude},${field.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _openWebsite(String website) async {
    final url = website.startsWith('http') ? website : 'https://$website';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _fieldColor(SoccerField field) {
    if (field.isFiveSide) return _kAmber;
    if (field.isIndoor) return _kRose;
    return _kSage;
  }

  void _showNotificationsSheet(BuildContext context, TeamsProvider teams) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: teams,
        child: const _MapNotificationsSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Consumer<FieldsProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              _buildTopSection(context, provider),
              Expanded(child: _buildMapArea(context, provider)),
            ],
          );
        },
      ),
    );
  }

  // ── Top section: app bar + search bar ────────────────────────────────────

  Widget _buildTopSection(BuildContext context, FieldsProvider provider) {
    final top = MediaQuery.of(context).padding.top;
    final user = context.watch<AuthProvider>().currentUser;
    final initials =
        user != null && user.username.isNotEmpty
            ? user.username.substring(0, 1).toUpperCase()
            : '?';

    return Container(
      color: _kBg,
      padding: EdgeInsets.fromLTRB(15, top + 10, 15, 0),
      child: Column(
        children: [
          // App bar row
          Row(
            children: [
              // Logo
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  children: [
                    SvgPicture.string(
                      _mpLogoHexSvg(_mpLogoOrange, '#FF7F2A', 'mpHexO'),
                      width: 40,
                      height: 40,
                    ),
                    SvgPicture.string(
                      _mpLogoHexSvg(_mpLogoGray, '#e6e6e6', 'mpHexG'),
                      width: 40,
                      height: 40,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Bell
              Consumer<TeamsProvider>(
                builder: (context, teams, _) => GestureDetector(
                  onTap: () => _showNotificationsSheet(context, teams),
                  child: SizedBox(
                    width: 31,
                    height: 31,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 31,
                          height: 31,
                          decoration: BoxDecoration(
                            color: _kCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: _kBorder2, width: 1),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            size: 15,
                            color: _kMuted2,
                          ),
                        ),
                        if (teams.totalNotificationsCount > 0)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: _kAmber,
                                shape: BoxShape.circle,
                                border: Border.all(color: _kNight, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  teams.totalNotificationsCount > 9
                                      ? '9+'
                                      : '${teams.totalNotificationsCount}',
                                  style: const TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.w800,
                                    color: _kNight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Avatar
              GestureDetector(
                onTap: () => MainScreen.of(context).goToTab(3),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_kAmberSoft, _kAmberDark],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.syne(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kBg,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Location / filter bar
          Container(
            decoration: BoxDecoration(
              color: _kCard,
              border: Border.all(color: _kBorder2, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.fromLTRB(12, 7, 7, 7),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: _kMuted2,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    provider.currentPosition != null
                        ? 'Position actuelle'
                        : (provider.isLoading
                            ? 'Localisation...'
                            : 'Paris, Île-de-France'),
                    style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted2),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showFilterSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _kAmber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Filtrer',
                      style: GoogleFonts.syne(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.06,
                        color: _kBg,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Map area ──────────────────────────────────────────────────────────────

  Widget _buildMapArea(BuildContext context, FieldsProvider provider) {
    if (provider.isLoading && provider.fields.isEmpty) {
      return _buildLoadingState();
    }
    if (provider.error != null && provider.fields.isEmpty) {
      return _buildErrorView(provider);
    }

    final defaultCenter = LatLng(48.8566, 2.3522);
    final center =
        provider.currentPosition != null
            ? LatLng(
              provider.currentPosition!.latitude,
              provider.currentPosition!.longitude,
            )
            : defaultCenter;

    return Container(
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
      child: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.0,
              onTap: (tapPos, _) => setState(() => _selectedField = null),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.fivestar.app',
              ),
              // User location dot
              if (provider.currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        provider.currentPosition!.latitude,
                        provider.currentPosition!.longitude,
                      ),
                      width: 16,
                      height: 16,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF7EB8D4),
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                            BorderSide(color: Colors.white, width: 2.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x664FD0F0),
                              blurRadius: 14,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              // Field markers
              MarkerLayer(
                markers:
                    provider.fields.map((field) {
                      final isSelected = _selectedField?.id == field.id;
                      final color = _fieldColor(field);
                      return Marker(
                        point: LatLng(field.latitude, field.longitude),
                        width: isSelected ? 34 : 28,
                        height: isSelected ? 43 : 37,
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          onTap: () => _selectField(field),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: isSelected ? 30 : 26,
                                height: isSelected ? 30 : 26,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: isSelected ? 12 : 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    '⚽',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                              Container(width: 2, height: 7, color: color),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),

          // Loading chip overlay
          if (provider.isLoading)
            const Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(child: _LoadingChip()),
            ),

          // Legend (top-right)
          Positioned(top: 10, right: 10, child: _buildLegend()),

          // Bottom gradient + summary banner
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBanner(provider),
          ),

          // Selected field card (above bottom banner)
          if (_selectedField != null)
            Positioned(
              bottom: 82,
              left: 12,
              right: 12,
              child: _buildFieldCard(_selectedField!),
            ),

          // Location FAB
          if (provider.currentPosition != null && _selectedField == null)
            Positioned(
              right: 12,
              bottom: 88,
              child: GestureDetector(
                onTap: _centerOnUserLocation,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBorder2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x80000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location_outlined,
                    color: _kAmber,
                    size: 17,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Legend ────────────────────────────────────────────────────────────────

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xE2111318),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendItem(_kAmber, 'Disponible'),
          const SizedBox(height: 4),
          _legendItem(_kSage, 'Nouveau'),
          const SizedBox(height: 4),
          _legendItem(_kRose, 'Complet'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.dmSans(fontSize: 9, color: _kMuted2)),
      ],
    );
  }

  // ── Bottom banner ─────────────────────────────────────────────────────────

  Widget _buildBottomBanner(FieldsProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xF7191C24), Colors.transparent],
          stops: [0.52, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(13, 20, 13, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${provider.fields.length} terrain${provider.fields.length != 1 ? 's' : ''} autour de toi',
            style: GoogleFonts.syne(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.06,
              color: _kWhite,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _pill(
                '⚡ Ce soir',
                _kAmber,
                const Color(0x1CFF7F2A),
                const Color(0x40FF7F2A),
              ),
              _pill(
                'Places dispo',
                _kSage,
                const Color(0x1F4CAF82),
                const Color(0x404CAF82),
              ),
              _pill(
                'Tous niveaux',
                _kMuted2,
                const Color(0x0DFFFFFF),
                _kBorder2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(
    String text,
    Color textColor,
    Color bgColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.syne(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          color: textColor,
        ),
      ),
    );
  }

  // ── Selected field card ───────────────────────────────────────────────────

  Widget _buildFieldCard(SoccerField field) {
    final color = _fieldColor(field);
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder2, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('⚽', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.name,
                      style: GoogleFonts.syne(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kWhite,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: _kMuted2,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          field.formattedDistance,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        if (field.isIndoor) ...[
                          const SizedBox(width: 6),
                          _pill(
                            'Indoor',
                            _kRose,
                            const Color(0x1FD4607A),
                            const Color(0x40D4607A),
                          ),
                        ],
                        if (field.isFiveSide) ...[
                          const SizedBox(width: 6),
                          _pill(
                            'Foot 5',
                            _kAmber,
                            const Color(0x1CFF7F2A),
                            const Color(0x40FF7F2A),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedField = null),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, color: _kMuted2, size: 14),
                ),
              ),
            ],
          ),

          // Address
          if (field.address != null) ...[
            const SizedBox(height: 10),
            Text(
              field.address!,
              style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Opening hours
          if (field.openingHours != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.access_time_outlined,
                  size: 12,
                  color: _kMuted2,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    field.openingHours!,
                    style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _openInMaps(field),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kAmberSoft, _kAmberDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40FF7F2A),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.directions_outlined,
                          size: 14,
                          color: Color(0xFF0A0C10),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Itinéraire',
                          style: GoogleFonts.syne(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _kBg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (field.phone != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _callPhone(field.phone!),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0x1F4CAF82),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x404CAF82)),
                    ),
                    child: const Icon(
                      Icons.phone_outlined,
                      color: _kSage,
                      size: 16,
                    ),
                  ),
                ),
              ],
              if (field.website != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _openWebsite(field.website!),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0x1A7EB8D4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x407EB8D4)),
                    ),
                    child: const Icon(
                      Icons.language_outlined,
                      color: Color(0xFF7EB8D4),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Loading & error states ────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: _kAmber,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Recherche des terrains...',
            style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted2),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(FieldsProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0x1FD4607A),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.location_off_outlined,
                size: 32,
                color: _kRose,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted2),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => provider.initialize(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kAmberSoft, _kAmberDark],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Réessayer',
                  style: GoogleFonts.syne(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kBg,
                  ),
                ),
              ),
            ),
            if (!provider.hasLocationPermission) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap:
                    () => launchUrl(
                      Uri.parse('app-settings:'),
                      mode: LaunchMode.externalApplication,
                    ),
                child: Text(
                  'Ouvrir les paramètres',
                  style: GoogleFonts.dmSans(fontSize: 12, color: _kAmber),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Filter bottom sheet ───────────────────────────────────────────────────

  void _showFilterSheet(BuildContext context) {
    final provider = context.read<FieldsProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 3,
                        decoration: BoxDecoration(
                          color: _kBorder2,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtres',
                          style: GoogleFonts.syne(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _kWhite,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            provider.clearFilters();
                            setModalState(() {});
                          },
                          child: Text(
                            'Réinitialiser',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: _kAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Rayon : ${(provider.searchRadiusMeters / 1000).toStringAsFixed(0)} km',
                      style: GoogleFonts.syne(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kWhite,
                      ),
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: _kAmber,
                        inactiveTrackColor: const Color(0xFF2A2D38),
                        thumbColor: _kAmber,
                        overlayColor: const Color(0x30FF7F2A),
                      ),
                      child: Slider(
                        value: provider.searchRadiusMeters.toDouble(),
                        min: 5000,
                        max: 60000,
                        divisions: 11,
                        label:
                            '${(provider.searchRadiusMeters / 1000).toStringAsFixed(0)} km',
                        onChanged: (value) {
                          provider.setSearchRadius(value.toInt());
                          setModalState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: Text(
                        'Foot à 5 uniquement',
                        style: GoogleFonts.dmSans(
                          color: _kWhite,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        'Urban Soccer, Le Five, etc.',
                        style: GoogleFonts.dmSans(
                          color: _kMuted2,
                          fontSize: 11,
                        ),
                      ),
                      value: provider.showOnlyFiveSide,
                      activeThumbColor: _kAmber,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (_) {
                        provider.toggleFiveSideFilter();
                        setModalState(() {});
                      },
                    ),
                    SwitchListTile(
                      title: Text(
                        'Indoor uniquement',
                        style: GoogleFonts.dmSans(
                          color: _kWhite,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        'Terrains couverts',
                        style: GoogleFonts.dmSans(
                          color: _kMuted2,
                          fontSize: 11,
                        ),
                      ),
                      value: provider.showOnlyIndoor,
                      activeThumbColor: _kAmber,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (_) {
                        provider.toggleIndoorFilter();
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kAmberSoft, _kAmberDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x50FF7F2A),
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          'Appliquer',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.syne(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.06,
                            color: _kBg,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Loading chip ──────────────────────────────────────────────────────────────

class _LoadingChip extends StatelessWidget {
  const _LoadingChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xE2111318),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(color: _kAmber, strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            'Recherche...',
            style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted2),
          ),
        ],
      ),
    );
  }
}

// ── Notifications sheet ───────────────────────────────────────────────────────

class _MapNotificationsSheet extends StatefulWidget {
  const _MapNotificationsSheet();

  @override
  State<_MapNotificationsSheet> createState() => _MapNotificationsSheetState();
}

class _MapNotificationsSheetState extends State<_MapNotificationsSheet> {
  final Set<int> _loadingIds = {};

  @override
  Widget build(BuildContext context) {
    final teams = context.watch<TeamsProvider>();
    final challenges = teams.pendingChallenges;
    final invitations = teams.pendingInvitations;
    final totalCount = challenges.length + invitations.length;

    return Container(
      decoration: const BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _kBorder2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          // Header
          Row(
            children: [
              Text(
                'Notifications',
                style: GoogleFonts.syne(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kWhite,
                ),
              ),
              const Spacer(),
              if (totalCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kAmberDim,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: const Color(0x40FF7F2A),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$totalCount',
                    style: const TextStyle(
                      color: _kAmber,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (totalCount == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'Aucune notification en attente',
                style: GoogleFonts.dmSans(color: _kMuted2, fontSize: 13),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (invitations.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'INVITATIONS D\'ÉQUIPE',
                        style: GoogleFonts.syne(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _kMuted2,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    ...invitations.map((inv) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildInvitationItem(context, inv, teams),
                    )),
                  ],
                  if (challenges.isNotEmpty) ...[
                    if (invitations.isNotEmpty)
                      const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'DÉFIS DE MATCH',
                        style: GoogleFonts.syne(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _kMuted2,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    ...challenges.asMap().entries.map((e) => Padding(
                      padding: EdgeInsets.only(bottom: e.key < challenges.length - 1 ? 10 : 0),
                      child: _buildItem(context, e.value, teams),
                    )),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInvitationItem(
    BuildContext context,
    TeamInvitation invitation,
    TeamsProvider teams,
  ) {
    final isLoading = _loadingIds.contains(-invitation.id); // negative ID for invitations

    final positionLabels = {
      'goalkeeper': 'Gardien',
      'defender': 'Défenseur',
      'midfielder': 'Milieu',
      'forward': 'Attaquant',
      'substitute': 'Remplaçant',
    };
    final posLabel = positionLabels[invitation.position] ?? invitation.position;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0x1A3B82F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x333B82F6), width: 1),
                ),
                child: invitation.teamLogoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.network(invitation.teamLogoUrl!, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Text(
                          invitation.teamName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.teamName,
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _kWhite,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Invitation · ${invitation.invitingUsername}',
                      style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted2),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x1A3B82F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  posLabel,
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isLoading
                      ? null
                      : () async {
                          setState(() => _loadingIds.add(-invitation.id));
                          await teams.respondToInvitation(
                            invitationId: invitation.id,
                            accept: false,
                          );
                          if (mounted) setState(() => _loadingIds.remove(-invitation.id));
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0x1AD4607A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x33D4607A)),
                    ),
                    child: Center(
                      child: Text(
                        'Refuser',
                        style: GoogleFonts.syne(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kRose,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: isLoading
                      ? null
                      : () async {
                          setState(() => _loadingIds.add(-invitation.id));
                          await teams.respondToInvitation(
                            invitationId: invitation.id,
                            accept: true,
                          );
                          if (mounted) {
                            setState(() => _loadingIds.remove(-invitation.id));
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _kAmberDim,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x33FF7F2A)),
                    ),
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _kAmber,
                              ),
                            )
                          : Text(
                              'Accepter',
                              style: GoogleFonts.syne(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kAmber,
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
    );
  }

  Widget _buildItem(
    BuildContext context,
    MatchChallenge challenge,
    TeamsProvider teams,
  ) {
    final isLoading = _loadingIds.contains(challenge.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kAmberDim,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0x33FF7F2A),
                    width: 1,
                  ),
                ),
                child: challenge.challengerTeamLogoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.network(
                          challenge.challengerTeamLogoUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          challenge.challengerTeamName[0].toUpperCase(),
                          style: const TextStyle(
                            color: _kAmber,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.challengerTeamName,
                      style: GoogleFonts.syne(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _kWhite,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Défi reçu',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: _kMuted2,
                      ),
                    ),
                  ],
                ),
              ),
              if (challenge.proposedDate != null)
                Text(
                  DateFormat('d MMM', 'fr_FR').format(challenge.proposedDate!),
                  style: GoogleFonts.dmSans(fontSize: 10, color: _kMuted2),
                ),
            ],
          ),
          if (challenge.message != null && challenge.message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _kBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                challenge.message!,
                style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (challenge.proposedLocation != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 12, color: _kMuted2),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    challenge.proposedLocation!,
                    style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: isLoading
                    ? null
                    : () => _respond(context, challenge, false, teams),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _kRose, width: 1.5),
                  ),
                  child: Text(
                    'REFUSER',
                    style: GoogleFonts.syne(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      letterSpacing: 0.6,
                      color: _kRose,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isLoading
                    ? null
                    : () => _respond(context, challenge, true, teams),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kAmberSoft, _kAmberDark],
                    ),
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33FF7F2A),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 50,
                          height: 14,
                          child: Center(
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _kNight,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          'ACCEPTER',
                          style: GoogleFonts.syne(
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.6,
                            color: _kNight,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _respond(
    BuildContext context,
    MatchChallenge challenge,
    bool accept,
    TeamsProvider teams,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loadingIds.add(challenge.id));
    final result = await TeamsService.instance.respondToChallenge(
      challenge.id,
      accept: accept,
    );
    if (!mounted) return;
    setState(() => _loadingIds.remove(challenge.id));
    if (result != null) {
      teams.loadPendingChallenges();
      if (accept) teams.loadMyTeam();
      messenger.showSnackBar(
        SnackBar(
          content: Text(accept ? 'Défi accepté !' : 'Défi refusé'),
          backgroundColor: accept ? Colors.green : Colors.grey[700],
        ),
      );
    }
  }
}
