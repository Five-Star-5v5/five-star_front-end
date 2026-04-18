/// Modèle représentant un utilisateur
class UserModel {
  final int id;
  final String username;
  final String codeId; // Code unique visible
  final String? email;
  final String? phone;
  final String? bio;
  final String? preferredPosition;
  final String? avatarUrl;
  final double? rating;
  final int matchesPlayed;
  final int matchesWon;
  final int matchesLost;
  final int matchesDrawn;
  final bool isAvailable;
  final List<String>? availabilityDays;
  final String? availabilityEndDate;
  final List<String>? availabilityCities;
  final int? availabilityRadiusKm;

  UserModel({
    required this.id,
    required this.username,
    required this.codeId,
    this.email,
    this.phone,
    this.bio,
    this.preferredPosition,
    this.avatarUrl,
    this.rating,
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.matchesLost = 0,
    this.matchesDrawn = 0,
    this.isAvailable = false,
    this.availabilityDays,
    this.availabilityEndDate,
    this.availabilityCities,
    this.availabilityRadiusKm,
  });

  /// Crée un UserModel à partir d'un JSON (réponse API)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String>? _parseJsonList(dynamic raw) {
      if (raw == null) return null;
      if (raw is List) return raw.map((e) => e.toString()).toList();
      try {
        final decoded = (raw as String);
        if (decoded.isEmpty) return null;
        // Simple JSON array parsing
        final trimmed = decoded.trim();
        if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
          final inner = trimmed.substring(1, trimmed.length - 1);
          if (inner.isEmpty) return [];
          return inner
              .split(',')
              .map((s) => s.trim().replaceAll('"', '').replaceAll("'", ''))
              .toList();
        }
        return [decoded];
      } catch (_) {
        return null;
      }
    }

    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      codeId: json['code_id'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      preferredPosition: json['preferred_position'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      matchesPlayed: json['matches_played'] as int? ?? 0,
      matchesWon: json['matches_won'] as int? ?? 0,
      matchesLost: json['matches_lost'] as int? ?? 0,
      matchesDrawn: json['matches_drawn'] as int? ?? 0,
      isAvailable: json['is_available'] as bool? ?? false,
      availabilityDays: _parseJsonList(json['availability_days']),
      availabilityEndDate: json['availability_end_date'] as String?,
      availabilityCities: _parseJsonList(json['availability_cities']),
      availabilityRadiusKm: json['availability_radius_km'] as int?,
    );
  }

  /// Convertit le modèle en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'code_id': codeId,
      'email': email,
      'phone': phone,
      'bio': bio,
      'preferred_position': preferredPosition,
      'avatar_url': avatarUrl,
      'rating': rating,
      'matches_played': matchesPlayed,
      'matches_won': matchesWon,
      'matches_lost': matchesLost,
      'matches_drawn': matchesDrawn,
      'is_available': isAvailable,
    };
  }

  UserModel copyWith({
    bool? isAvailable,
    List<String>? availabilityDays,
    String? availabilityEndDate,
    List<String>? availabilityCities,
    int? availabilityRadiusKm,
  }) {
    return UserModel(
      id: id,
      username: username,
      codeId: codeId,
      email: email,
      phone: phone,
      bio: bio,
      preferredPosition: preferredPosition,
      avatarUrl: avatarUrl,
      rating: rating,
      matchesPlayed: matchesPlayed,
      matchesWon: matchesWon,
      matchesLost: matchesLost,
      matchesDrawn: matchesDrawn,
      isAvailable: isAvailable ?? this.isAvailable,
      availabilityDays: availabilityDays ?? this.availabilityDays,
      availabilityEndDate: availabilityEndDate ?? this.availabilityEndDate,
      availabilityCities: availabilityCities ?? this.availabilityCities,
      availabilityRadiusKm: availabilityRadiusKm ?? this.availabilityRadiusKm,
    );
  }

  /// Calcule le pourcentage de victoires
  double get winRate {
    if (matchesPlayed == 0) return 0;
    return (matchesWon / matchesPlayed) * 100;
  }
}
