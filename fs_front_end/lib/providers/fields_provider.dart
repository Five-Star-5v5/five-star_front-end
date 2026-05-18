import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/fields_service.dart';

class FieldsProvider extends ChangeNotifier {
  final FieldsService _service = FieldsService.instance;

  List<SoccerField> _fields = [];
  bool _isLoading = false;
  String? _error;
  Position? _currentPosition;
  bool _hasLocationPermission = false;
  int _searchRadiusMeters = 20000;
  bool _radiusFilterActive = false;

  List<SoccerField> get fields => _filteredFields;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Position? get currentPosition => _currentPosition;
  bool get hasLocationPermission => _hasLocationPermission;
  int get searchRadiusMeters => _searchRadiusMeters;
  bool get radiusFilterActive => _radiusFilterActive;

  List<SoccerField> get _filteredFields {
    if (!_radiusFilterActive) return _fields;
    return _fields
        .where((f) => f.distanceMeters <= _searchRadiusMeters)
        .toList();
  }

  /// Charge la position utilisateur et tous les centres France en parallèle.
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Lancer les deux en parallèle
    await Future.wait([
      _loadLocation(),
      _loadChainVenues(),
    ]);

    // Une fois la position connue, recalculer les distances
    if (_currentPosition != null) {
      _recalculateDistances();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadLocation() async {
    _hasLocationPermission = await _service.checkLocationPermission();
    if (_hasLocationPermission) {
      _currentPosition = await _service.getCurrentPosition();
    }
  }

  Future<void> _loadChainVenues() async {
    try {
      _fields = await _service.fetchChainVenues(
        userPosition: _currentPosition,
      );
    } catch (e) {
      _error = 'Erreur lors de la recherche des terrains';
    }
  }

  /// Recalcule les distances après avoir obtenu la position.
  void _recalculateDistances() {
    if (_currentPosition == null) return;
    _fields = _fields.map((field) {
      final d = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        field.latitude,
        field.longitude,
      );
      return SoccerField(
        id: field.id,
        name: field.name,
        address: field.address,
        latitude: field.latitude,
        longitude: field.longitude,
        distanceMeters: d,
        type: field.type,
        phone: field.phone,
        website: field.website,
        openingHours: field.openingHours,
        operator: field.operator,
        surface: field.surface,
        isIndoor: field.isIndoor,
        isFiveSide: field.isFiveSide,
      );
    }).toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
  }

  /// Force un rechargement depuis l'API (ignore le cache).
  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await _service.clearCache();
    _currentPosition = await _service.getCurrentPosition();

    try {
      _fields = await _service.fetchChainVenues(userPosition: _currentPosition);
      if (_currentPosition != null) _recalculateDistances();
    } catch (e) {
      _error = 'Erreur lors du rafraîchissement';
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSearchRadius(int radiusMeters) {
    _searchRadiusMeters = radiusMeters;
    _radiusFilterActive = true;
    notifyListeners();
  }

  void clearFilters() {
    _searchRadiusMeters = 20000;
    _radiusFilterActive = false;
    notifyListeners();
  }

  SoccerField? getFieldById(String id) {
    try {
      return _fields.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }
}
