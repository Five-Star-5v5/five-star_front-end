import 'dart:async';

import 'package:flutter/material.dart';
import 'package:five_star_5v5/theme/app_typography.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/fields_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/teams_provider.dart';
import '../services/fields_service.dart';
import '../services/teams_service.dart';
import '../main_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/kobeta_logo.dart';

// ── Google Maps dark style ────────────────────────────────────────────────
const _kMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0d0f14"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#9ea5b0"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0a0c10"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#1a1d24"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#bbbfc5"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#141a1a"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#4caf82"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1e2029"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#141820"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#5c6370"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2a2d38"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#181a21"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f3d19c"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#181a21"}]},
  {"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#060810"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
]
''';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _mapCompleter = Completer();
  GoogleMapController? _mapController;
  SoccerField? _selectedField;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<FieldsProvider>().initialize();
      // Une fois l'init terminée (position connue), centrer la carte
      await _mapCompleter.future;
      if (mounted) _centerOnUserLocation();
    });
  }

  void _centerOnUserLocation() {
    final provider = context.read<FieldsProvider>();
    if (provider.currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            provider.currentPosition!.latitude,
            provider.currentPosition!.longitude,
          ),
          14.0,
        ),
      );
    }
  }

  void _selectField(SoccerField field) {
    setState(() => _selectedField = field);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(field.latitude, field.longitude), 16.0),
    );
  }

  BitmapDescriptor _markerIcon(Color color) {
    double hue;
    if (color == AppColors.amber) {
      hue = 25.0; // orange
    } else if (color == AppColors.sage) {
      hue = BitmapDescriptor.hueGreen;
    } else {
      hue = BitmapDescriptor.hueRose;
    }
    return BitmapDescriptor.defaultMarkerWithHue(hue);
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
    if (field.isFiveSide) return AppColors.amber;
    if (field.isIndoor) return AppColors.rose;
    return AppColors.sage;
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
      backgroundColor: AppColors.bg,
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
    final initials = user != null && user.username.isNotEmpty
        ? user.username.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      color: AppColors.bg,
      padding: EdgeInsets.fromLTRB(15, top + 10, 15, 0),
      child: Column(
        children: [
          // App bar row
          Row(
            children: [
              // Logo
              const KobetaLogo(size: 40),
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
                            color: AppColors.card,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.border2,
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            size: 15,
                            color: AppColors.muted2,
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
                                color: AppColors.amber,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.night,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  teams.totalNotificationsCount > 9
                                      ? '9+'
                                      : '${teams.totalNotificationsCount}',
                                  style: const TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.night,
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
                      colors: [AppColors.amberSoft, AppColors.amberD],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: AppTypography.display(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.bg,
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
              color: AppColors.card,
              border: Border.all(color: AppColors.border2, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.fromLTRB(12, 7, 7, 7),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.muted2,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    provider.currentPosition != null
                        ? 'Position actuelle'
                        : (provider.isLoading
                              ? 'Localisation...'
                              : 'Paris, Île-de-France'),
                    style: AppTypography.body(
                      fontSize: 11,
                      color: AppColors.muted2,
                    ),
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
                      color: AppColors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Filtrer',
                      style: AppTypography.display(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.06,
                        color: AppColors.bg,
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

    const defaultCenter = LatLng(48.8566, 2.3522);
    final center = provider.currentPosition != null
        ? LatLng(
            provider.currentPosition!.latitude,
            provider.currentPosition!.longitude,
          )
        : defaultCenter;

    final markers = <Marker>{
      if (provider.currentPosition != null)
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(
            provider.currentPosition!.latitude,
            provider.currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(200),
          zIndexInt: 2,
        ),
      ...provider.fields.map((field) {
        final isSelected = _selectedField?.id == field.id;
        final color = _fieldColor(field);
        return Marker(
          markerId: MarkerId('field_${field.id}'),
          position: LatLng(field.latitude, field.longitude),
          icon: _markerIcon(color),
          onTap: () => _selectField(field),
          zIndexInt: isSelected ? 1 : 0,
        );
      }),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
      child: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: center, zoom: 13.0),
            onMapCreated: (controller) {
              if (!_mapCompleter.isCompleted)
                _mapCompleter.complete(controller);
              _mapController = controller;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _centerOnUserLocation();
              });
            },
            style: _kMapStyle,
            markers: markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            padding: const EdgeInsets.only(bottom: 90),
            onTap: (_) => setState(() => _selectedField = null),
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

          // Zoom controls (+/−)
          Positioned(
            right: 12,
            bottom: _selectedField == null && provider.currentPosition != null
                ? 134
                : 88,
            child: Column(
              children: [
                _buildZoomButton(Icons.add, () {
                  _mapController?.animateCamera(CameraUpdate.zoomIn());
                }),
                const SizedBox(height: 6),
                _buildZoomButton(Icons.remove, () {
                  _mapController?.animateCamera(CameraUpdate.zoomOut());
                }),
              ],
            ),
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
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border2),
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
                    color: AppColors.amber,
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
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendItem(AppColors.amber, 'Disponible'),
          const SizedBox(height: 4),
          _legendItem(AppColors.sage, 'Nouveau'),
          const SizedBox(height: 4),
          _legendItem(AppColors.rose, 'Complet'),
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
        Text(
          label,
          style: AppTypography.body(fontSize: 9, color: AppColors.muted2),
        ),
      ],
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x80000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.amber, size: 17),
      ),
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
            style: AppTypography.display(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.06,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _pill(
                '⚡ Ce soir',
                AppColors.amber,
                const Color(0x1CFF7F2A),
                const Color(0x40FF7F2A),
              ),
              _pill(
                'Places dispo',
                AppColors.sage,
                const Color(0x1F4CAF82),
                const Color(0x404CAF82),
              ),
              _pill(
                'Tous niveaux',
                AppColors.muted2,
                const Color(0x0DFFFFFF),
                AppColors.border2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color textColor, Color bgColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        text,
        style: AppTypography.display(
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border2, width: 1),
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
                      style: AppTypography.display(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
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
                          color: AppColors.muted2,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          field.formattedDistance,
                          style: AppTypography.body(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        if (field.isIndoor) ...[
                          const SizedBox(width: 6),
                          _pill(
                            'Indoor',
                            AppColors.rose,
                            const Color(0x1FD4607A),
                            const Color(0x40D4607A),
                          ),
                        ],
                        if (field.isFiveSide) ...[
                          const SizedBox(width: 6),
                          _pill(
                            'Foot 5',
                            AppColors.amber,
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
                  child: const Icon(
                    Icons.close,
                    color: AppColors.muted2,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),

          // Address
          if (field.address != null) ...[
            const SizedBox(height: 10),
            Text(
              field.address!,
              style: AppTypography.body(fontSize: 11, color: AppColors.muted2),
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
                  color: AppColors.muted2,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    field.openingHours!,
                    style: AppTypography.body(
                      fontSize: 11,
                      color: AppColors.muted2,
                    ),
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
                        colors: [AppColors.amberSoft, AppColors.amberD],
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
                          style: AppTypography.display(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.bg,
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
                      color: AppColors.sage,
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
              color: AppColors.amber,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Recherche des terrains...',
            style: AppTypography.body(fontSize: 12, color: AppColors.muted2),
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
                color: AppColors.rose,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: AppTypography.body(fontSize: 13, color: AppColors.muted2),
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
                    colors: [AppColors.amberSoft, AppColors.amberD],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Réessayer',
                  style: AppTypography.display(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bg,
                  ),
                ),
              ),
            ),
            if (!provider.hasLocationPermission) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse('app-settings:'),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  'Ouvrir les paramètres',
                  style: AppTypography.body(
                    fontSize: 12,
                    color: AppColors.amber,
                  ),
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
      backgroundColor: AppColors.card,
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
                          color: AppColors.border2,
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
                          style: AppTypography.display(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            provider.clearFilters();
                            setModalState(() {});
                          },
                          child: Text(
                            'Réinitialiser',
                            style: AppTypography.body(
                              fontSize: 12,
                              color: AppColors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Rayon : ${(provider.searchRadiusMeters / 1000).toStringAsFixed(0)} km',
                      style: AppTypography.display(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.amber,
                        inactiveTrackColor: const Color(0xFF2A2D38),
                        thumbColor: AppColors.amber,
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
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.amberSoft, AppColors.amberD],
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
                          style: AppTypography.display(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.06,
                            color: AppColors.bg,
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
        border: Border.all(color: AppColors.border2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              color: AppColors.amber,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Recherche...',
            style: AppTypography.body(fontSize: 11, color: AppColors.muted2),
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
        color: AppColors.card,
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
              color: AppColors.border2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          // Header
          Row(
            children: [
              Text(
                'Notifications',
                style: AppTypography.display(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
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
                    color: AppColors.amberDim,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: const Color(0x40FF7F2A),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$totalCount',
                    style: const TextStyle(
                      color: AppColors.amber,
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
                style: AppTypography.body(
                  color: AppColors.muted2,
                  fontSize: 13,
                ),
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
                        style: AppTypography.display(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted2,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    ...invitations.map(
                      (inv) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildInvitationItem(context, inv, teams),
                      ),
                    ),
                  ],
                  if (challenges.isNotEmpty) ...[
                    if (invitations.isNotEmpty) const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'DÉFIS DE MATCH',
                        style: AppTypography.display(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted2,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    ...challenges.asMap().entries.map(
                      (e) => Padding(
                        padding: EdgeInsets.only(
                          bottom: e.key < challenges.length - 1 ? 10 : 0,
                        ),
                        child: _buildItem(context, e.value, teams),
                      ),
                    ),
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
    final isLoading = _loadingIds.contains(
      -invitation.id,
    ); // negative ID for invitations

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
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
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
                        child: Image.network(
                          invitation.teamLogoUrl!,
                          fit: BoxFit.cover,
                        ),
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
                      style: AppTypography.display(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Invitation · ${invitation.invitingUsername}',
                      style: AppTypography.body(
                        fontSize: 10,
                        color: AppColors.muted2,
                      ),
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
                          if (mounted)
                            setState(() => _loadingIds.remove(-invitation.id));
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
                        style: AppTypography.display(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.rose,
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
                      color: AppColors.amberDim,
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
                                color: AppColors.amber,
                              ),
                            )
                          : Text(
                              'Accepter',
                              style: AppTypography.display(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
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
                  color: AppColors.amberDim,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x33FF7F2A), width: 1),
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
                            color: AppColors.amber,
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
                      style: AppTypography.display(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Défi reçu',
                      style: AppTypography.body(
                        fontSize: 10,
                        color: AppColors.muted2,
                      ),
                    ),
                  ],
                ),
              ),
              if (challenge.proposedDate != null)
                Text(
                  DateFormat('d MMM', 'fr_FR').format(challenge.proposedDate!),
                  style: AppTypography.body(
                    fontSize: 10,
                    color: AppColors.muted2,
                  ),
                ),
            ],
          ),
          if (challenge.message != null && challenge.message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.bg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                challenge.message!,
                style: AppTypography.body(
                  fontSize: 12,
                  color: AppColors.muted2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (challenge.proposedLocation != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 12,
                  color: AppColors.muted2,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    challenge.proposedLocation!,
                    style: AppTypography.body(
                      fontSize: 11,
                      color: AppColors.muted2,
                    ),
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
                    border: Border.all(color: AppColors.rose, width: 1.5),
                  ),
                  child: Text(
                    'REFUSER',
                    style: AppTypography.display(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      letterSpacing: 0.6,
                      color: AppColors.rose,
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
                      colors: [AppColors.amberSoft, AppColors.amberD],
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
                                color: AppColors.night,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          'ACCEPTER',
                          style: AppTypography.display(
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.6,
                            color: AppColors.night,
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
