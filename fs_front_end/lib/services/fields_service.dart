import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FieldsService {
  FieldsService._privateConstructor();
  static final FieldsService instance = FieldsService._privateConstructor();

  // Clé injectée via : flutter run --dart-define=PLACES_API_KEY=ta_cle
  static const String _apiKey = String.fromEnvironment(
    'PLACES_API_KEY',
    defaultValue: '',
  );
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/place';

  // Cache 7 jours
  static const Duration _cacheTtl = Duration(days: 7);
  static const String _cacheKey = 'chain_venues_v2';
  static const String _cacheTsKey = 'chain_venues_ts_v2';

  // Chaînes à récupérer sur toute la France
  static const List<String> _chainQueries = [
    'Urban Soccer France',
    'Le Five France',
    'Z5 football France',
  ];

  // ── Localisation ───────────────────────────────────────────────────────────

  Future<bool> checkLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      if (!await checkLocationPermission()) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  // ── Chaînes (Urban Soccer, Le Five, Z5) ───────────────────────────────────

  /// Retourne tous les centres en France.
  /// Utilise le cache 7 jours, puis Google Places, puis la base locale.
  Future<List<SoccerField>> fetchChainVenues({Position? userPosition}) async {
    final cached = await _loadCache(userPosition);
    if (cached != null) {
      return cached;
    }

    if (_apiKey.isNotEmpty) {
      final venues = await _fetchFromPlaces(userPosition);
      if (venues.isNotEmpty) {
        await _saveCache(venues);
        return venues;
      }
    } else {
    }

    return _localFallback(userPosition);
  }

  Future<List<SoccerField>> _fetchFromPlaces(Position? userPosition) async {
    final all = <SoccerField>[];
    final seenIds = <String>{};

    for (final query in _chainQueries) {
      final venues = await _textSearch(query, seenIds, userPosition);
      all.addAll(venues);
    }

    return all;
  }

  Future<List<SoccerField>> _textSearch(
    String query,
    Set<String> seenIds,
    Position? userPosition,
  ) async {
    final venues = <SoccerField>[];
    String? pageToken;
    int page = 0;

    do {
      final params = <String, String>{
        'query': query,
        'region': 'fr',
        'language': 'fr',
        'key': _apiKey,
        if (pageToken != null) 'pagetoken': pageToken,
      };

      final uri = Uri.parse('$_baseUrl/textsearch/json').replace(
        queryParameters: params,
      );

      try {
        final response = await http
            .get(uri)
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final results =
              (data['results'] as List? ?? []).cast<Map<String, dynamic>>();

          for (final place in results) {
            final id = place['place_id'] as String? ?? '';
            if (seenIds.contains(id)) continue;
            seenIds.add(id);

            final venue = _parsePlaceResult(place, userPosition, query);
            if (venue != null) venues.add(venue);
          }

          pageToken = data['next_page_token'] as String?;
          // Google exige 2s entre pages
          if (pageToken != null) {
            await Future.delayed(const Duration(seconds: 2));
          }
        } else {
          break;
        }
      } catch (e) {
        break;
      }

      page++;
    } while (pageToken != null && page < 3);

    return venues;
  }

  SoccerField? _parsePlaceResult(
    Map<String, dynamic> place,
    Position? userPosition,
    String query,
  ) {
    try {
      final name = place['name'] as String? ?? '';
      final geo =
          place['geometry']?['location'] as Map<String, dynamic>?;
      if (geo == null) return null;

      final lat = (geo['lat'] as num).toDouble();
      final lng = (geo['lng'] as num).toDouble();

      final distance = userPosition != null
          ? Geolocator.distanceBetween(
              userPosition.latitude,
              userPosition.longitude,
              lat,
              lng,
            )
          : 0.0;

      final nameLower = name.toLowerCase();
      final queryLower = query.toLowerCase();

      String? operator_;
      if (queryLower.contains('urban') || nameLower.contains('urban soccer')) {
        operator_ = 'Urban Soccer';
      } else if (queryLower.contains('five') ||
          nameLower.contains('le five') ||
          nameLower.contains('lefive')) {
        operator_ = 'Le Five';
      } else if (queryLower.contains('z5') || nameLower.contains('z5')) {
        operator_ = 'Z5';
      }

      return SoccerField(
        id: 'gmaps_${place['place_id']}',
        name: name,
        address: place['formatted_address'] as String?,
        latitude: lat,
        longitude: lng,
        distanceMeters: distance,
        type: FieldType.fiveSide,
        phone: null,
        website: null,
        openingHours: _parseOpeningHours(place['opening_hours']),
        operator: operator_,
        surface: 'synthetic',
        isIndoor: true,
        isFiveSide: true,
      );
    } catch (e) {
      return null;
    }
  }

  String? _parseOpeningHours(dynamic hours) {
    if (hours == null) return null;
    try {
      final weekday = hours['weekday_text'] as List?;
      return weekday?.first as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Cache ──────────────────────────────────────────────────────────────────

  Future<List<SoccerField>?> _loadCache(Position? userPosition) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getInt(_cacheTsKey);
      if (ts == null) return null;

      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(ts),
      );
      if (age > _cacheTtl) return null;

      final json = prefs.getString(_cacheKey);
      if (json == null) return null;

      final list =
          (jsonDecode(json) as List).cast<Map<String, dynamic>>();
      return list.map((m) => SoccerField.fromJson(m, userPosition)).toList();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveCache(List<SoccerField> venues) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode(venues.map((v) => v.toJson()).toList()),
      );
      await prefs.setInt(
        _cacheTsKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
    }
  }

  /// Force le rechargement depuis l'API (ignore le cache)
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTsKey);
  }

  // ── Fallback local ─────────────────────────────────────────────────────────

  List<SoccerField> _localFallback(Position? userPosition) {
    return _knownCenters.map((c) {
      final lat = c['lat'] as double;
      final lon = c['lon'] as double;
      final distance = userPosition != null
          ? Geolocator.distanceBetween(
              userPosition.latitude,
              userPosition.longitude,
              lat,
              lon,
            )
          : 0.0;

      return SoccerField(
        id: c['id'] as String,
        name: c['name'] as String,
        address: c['address'] as String?,
        latitude: lat,
        longitude: lon,
        distanceMeters: distance,
        type: FieldType.fiveSide,
        phone: c['phone'] as String?,
        website: c['website'] as String?,
        openingHours: null,
        operator: c['operator'] as String?,
        surface: 'synthetic',
        isIndoor: true,
        isFiveSide: true,
      );
    }).toList();
  }

  // ── Base locale de secours ─────────────────────────────────────────────────

  static final List<Map<String, dynamic>> _knownCenters = [
    // ── Urban Soccer ──────────────────────────────────────────────────────────
    {'id': 'us_evry', 'name': 'Urban Soccer Évry', 'lat': 48.6289, 'lon': 2.4301, 'address': 'ZAC du Bois Briard, Évry', 'phone': '+33 1 60 79 20 20', 'website': 'https://www.urbansoccer.fr', 'operator': 'Urban Soccer'},
    {'id': 'us_aubervilliers', 'name': 'Urban Soccer Aubervilliers', 'lat': 48.9075, 'lon': 2.3743, 'address': 'Rue des Gardinoux, Aubervilliers', 'website': 'https://www.urbansoccer.fr', 'operator': 'Urban Soccer'},
    {'id': 'us_puteaux', 'name': 'Urban Soccer Puteaux', 'lat': 48.8760, 'lon': 2.2435, 'address': '1 Allée des Sports, Puteaux', 'website': 'https://www.urbansoccer.fr', 'operator': 'Urban Soccer'},
    {'id': 'us_creteil', 'name': 'Urban Soccer Créteil', 'lat': 48.7775, 'lon': 2.4628, 'website': 'https://www.urbansoccer.fr', 'operator': 'Urban Soccer'},
    {'id': 'us_torcy', 'name': 'Urban Soccer Torcy', 'lat': 48.8501, 'lon': 2.6563, 'website': 'https://www.urbansoccer.fr', 'operator': 'Urban Soccer'},
    {'id': 'us_orsay', 'name': 'Urban Soccer Orsay', 'lat': 48.7084, 'lon': 2.1782, 'website': 'https://www.urbansoccer.fr', 'operator': 'Urban Soccer'},
    {'id': 'us_asnieres', 'name': 'Urban Soccer Asnières', 'lat': 48.9128, 'lon': 2.2853, 'website': 'https://www.urbansoccer.fr', 'operator': 'Urban Soccer'},
    {'id': 'us_lyon', 'name': 'Urban Soccer Lyon', 'lat': 45.7117, 'lon': 4.9047, 'website': 'https://www.urbansoccer.fr', 'operator': 'Urban Soccer'},
    {'id': 'us_lille', 'name': 'Urban Soccer Lille', 'lat': 50.6167, 'lon': 3.0995, 'website': 'https://www.urbansoccer.fr', 'operator': 'Urban Soccer'},
    {'id': 'us_nantes', 'name': 'Urban Soccer Nantes', 'lat': 47.1903, 'lon': -1.4848, 'website': 'https://www.urbansoccer.fr', 'operator': 'Urban Soccer'},
    {'id': 'us_strasbourg', 'name': 'Urban Soccer Strasbourg', 'lat': 48.5935, 'lon': 7.7316, 'website': 'https://www.urbansoccer.fr', 'operator': 'Urban Soccer'},
    {'id': 'us_montpellier', 'name': 'Urban Soccer Montpellier', 'lat': 43.6287, 'lon': 3.9093, 'website': 'https://www.urbansoccer.fr', 'operator': 'Urban Soccer'},
    // ── Le Five ───────────────────────────────────────────────────────────────
    {'id': 'five_paris18', 'name': 'Le Five Paris 18', 'lat': 48.8978, 'lon': 2.3698, 'address': "217 Rue d'Aubervilliers, Paris 18", 'website': 'https://www.lefive.fr', 'operator': 'Le Five'},
    {'id': 'five_paris17', 'name': 'Le Five Paris 17', 'lat': 48.9004, 'lon': 2.3221, 'website': 'https://www.lefive.fr', 'operator': 'Le Five'},
    {'id': 'five_paris13', 'name': 'Le Five Paris 13', 'lat': 48.8180, 'lon': 2.3655, 'website': 'https://www.lefive.fr', 'operator': 'Le Five'},
    {'id': 'five_bobigny', 'name': 'Le Five Bobigny', 'lat': 48.9014, 'lon': 2.4316, 'website': 'https://www.lefive.fr', 'operator': 'Le Five'},
    {'id': 'five_sarcelles', 'name': 'Le Five Sarcelles', 'lat': 48.9978, 'lon': 2.3901, 'website': 'https://www.lefive.fr', 'operator': 'Le Five'},
    {'id': 'five_creteil', 'name': 'Le Five Créteil', 'lat': 48.7639, 'lon': 2.4705, 'website': 'https://www.lefive.fr', 'operator': 'Le Five'},
    {'id': 'five_lyon', 'name': 'Le Five Lyon', 'lat': 45.7275, 'lon': 4.8320, 'website': 'https://www.lefive.fr', 'operator': 'Le Five'},
    {'id': 'five_bordeaux', 'name': 'Le Five Bordeaux', 'lat': 44.8799, 'lon': -0.5594, 'website': 'https://www.lefive.fr', 'operator': 'Le Five'},
    {'id': 'five_strasbourg', 'name': 'Le Five Strasbourg', 'lat': 48.5900, 'lon': 7.6805, 'website': 'https://www.lefive.fr', 'operator': 'Le Five'},
    {'id': 'five_roubaix', 'name': 'Le Five Roubaix', 'lat': 50.6919, 'lon': 3.1632, 'website': 'https://www.lefive.fr', 'operator': 'Le Five'},
    {'id': 'five_reims', 'name': 'Le Five Reims', 'lat': 49.2691, 'lon': 4.0380, 'website': 'https://www.lefive.fr', 'operator': 'Le Five'},
    // ── Z5 ────────────────────────────────────────────────────────────────────
    {'id': 'z5_paris15', 'name': 'Z5 Paris 15', 'lat': 48.8417, 'lon': 2.2944, 'address': 'Paris 15e', 'website': 'https://www.z5.fr', 'operator': 'Z5'},
    {'id': 'z5_paris19', 'name': 'Z5 Paris 19', 'lat': 48.8872, 'lon': 2.3831, 'address': 'Paris 19e', 'website': 'https://www.z5.fr', 'operator': 'Z5'},
    {'id': 'z5_vincennes', 'name': 'Z5 Vincennes', 'lat': 48.8472, 'lon': 2.4399, 'address': 'Vincennes', 'website': 'https://www.z5.fr', 'operator': 'Z5'},
    {'id': 'z5_lyon', 'name': 'Z5 Lyon', 'lat': 45.7640, 'lon': 4.8357, 'address': 'Lyon', 'website': 'https://www.z5.fr', 'operator': 'Z5'},
    {'id': 'z5_marseille', 'name': 'Z5 Marseille', 'lat': 43.2965, 'lon': 5.3698, 'address': 'Marseille', 'website': 'https://www.z5.fr', 'operator': 'Z5'},
    {'id': 'z5_bordeaux', 'name': 'Z5 Bordeaux', 'lat': 44.8378, 'lon': -0.5792, 'address': 'Bordeaux', 'website': 'https://www.z5.fr', 'operator': 'Z5'},
    {'id': 'z5_toulouse', 'name': 'Z5 Toulouse', 'lat': 43.6047, 'lon': 1.4442, 'address': 'Toulouse', 'website': 'https://www.z5.fr', 'operator': 'Z5'},
    {'id': 'z5_lille', 'name': 'Z5 Lille', 'lat': 50.6292, 'lon': 3.0573, 'address': 'Lille', 'website': 'https://www.z5.fr', 'operator': 'Z5'},
    {'id': 'z5_nantes', 'name': 'Z5 Nantes', 'lat': 47.2184, 'lon': -1.5536, 'address': 'Nantes', 'website': 'https://www.z5.fr', 'operator': 'Z5'},
  ];
}

// ── Type de terrain ────────────────────────────────────────────────────────────

enum FieldType { pitch, fiveSide, sportsCentre, stadium }

extension FieldTypeExtension on FieldType {
  String get displayName {
    switch (this) {
      case FieldType.pitch:
        return 'Terrain';
      case FieldType.fiveSide:
        return 'Foot à 5';
      case FieldType.sportsCentre:
        return 'Centre sportif';
      case FieldType.stadium:
        return 'Stade';
    }
  }
}

// ── Modèle SoccerField ────────────────────────────────────────────────────────

class SoccerField {
  final String id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final FieldType type;
  final String? phone;
  final String? website;
  final String? openingHours;
  final String? operator;
  final String? surface;
  final bool isIndoor;
  final bool isFiveSide;

  SoccerField({
    required this.id,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.type,
    this.phone,
    this.website,
    this.openingHours,
    this.operator,
    this.surface,
    this.isIndoor = false,
    this.isFiveSide = false,
  });

  String get formattedDistance {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }

  // Sérialisation pour le cache SharedPreferences
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'type': type.index,
    'phone': phone,
    'website': website,
    'openingHours': openingHours,
    'operator': operator,
    'surface': surface,
    'isIndoor': isIndoor,
    'isFiveSide': isFiveSide,
  };

  factory SoccerField.fromJson(
    Map<String, dynamic> json,
    Position? userPosition,
  ) {
    final lat = (json['latitude'] as num).toDouble();
    final lng = (json['longitude'] as num).toDouble();
    final distance = userPosition != null
        ? Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            lat,
            lng,
          )
        : 0.0;

    return SoccerField(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      latitude: lat,
      longitude: lng,
      distanceMeters: distance,
      type: FieldType.values[json['type'] as int],
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      openingHours: json['openingHours'] as String?,
      operator: json['operator'] as String?,
      surface: json['surface'] as String?,
      isIndoor: json['isIndoor'] as bool? ?? false,
      isFiveSide: json['isFiveSide'] as bool? ?? false,
    );
  }
}
