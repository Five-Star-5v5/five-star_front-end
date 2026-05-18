import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService.instance;

  bool _isAuthenticated = false;
  bool _isLoading = true;
  UserModel? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;

  AuthProvider() {
    AuthService.onUnauthorized = _onUnauthorized;
    _tryAutoLogin();
  }

  void _onUnauthorized() async {
    await _service.logout();
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();
    final valid = await _service.isAccessTokenValid();
    if (!valid) {
      final refreshed = await _service.refreshToken();
      _isAuthenticated = refreshed;
    } else {
      _isAuthenticated = true;
    }

    // Charger les infos utilisateur si authentifié
    if (_isAuthenticated) {
      await _loadCurrentUser();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadCurrentUser() async {
    final userData = await _service.getCurrentUser();
    if (userData != null) {
      _currentUser = UserModel.fromJson(userData);
      // Désactiver silencieusement si la dispo a expiré
      if (_currentUser!.isAvailable) {
        final endDateStr = _currentUser!.availabilityEndDate;
        if (endDateStr != null) {
          final endDate = DateTime.tryParse(endDateStr);
          if (endDate != null && endDate.isBefore(DateTime.now())) {
            _currentUser = _currentUser!.copyWith(isAvailable: false);
            _service.setAvailability(false);
          }
        }
      }
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    final res = await _service.login(username: username, password: password);
    if (res['ok'] == true) {
      _isAuthenticated = true;
      await _loadCurrentUser();
    }
    _isLoading = false;
    notifyListeners();
    return res;
  }

  Future<Map<String, dynamic>> signup(
    String username,
    String email,
    String password,
  ) async {
    _isLoading = true;
    notifyListeners();
    final res = await _service.signup(
      username: username,
      email: email,
      password: password,
    );
    _isLoading = false;
    notifyListeners();
    return res;
  }

  /// Recharge les informations de l'utilisateur depuis le serveur
  Future<void> refreshCurrentUser() async {
    await _loadCurrentUser();
    notifyListeners();
  }

  /// Supprime le compte de l'utilisateur
  Future<bool> deleteAccount() async {
    try {
      final success = await _service.deleteAccount();
      if (success) {
        _isAuthenticated = false;
        _currentUser = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }

  /// Bascule le statut de disponibilité du joueur (optimistic update)
  Future<bool> setAvailability(
    bool isAvailable, {
    List<String>? days,
    String? endDate,
    List<String>? cities,
    int? radiusKm,
  }) async {
    final prev = _currentUser?.isAvailable ?? false;
    _currentUser = _currentUser?.copyWith(
      isAvailable: isAvailable,
      availabilityDays: days,
      availabilityEndDate: endDate,
      availabilityCities: cities,
      availabilityRadiusKm: radiusKm,
    );
    notifyListeners();
    final success = await _service.setAvailability(
      isAvailable,
      days: days,
      endDate: endDate,
      cities: cities,
      radiusKm: radiusKm,
    );
    if (!success) {
      _currentUser = _currentUser?.copyWith(isAvailable: prev);
      notifyListeners();
    }
    return success;
  }
}
