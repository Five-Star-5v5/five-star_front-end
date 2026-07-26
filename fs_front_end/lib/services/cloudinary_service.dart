import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'cloudinary_config.dart';

class CloudinaryService {
  CloudinaryService._privateConstructor();
  static final CloudinaryService instance =
      CloudinaryService._privateConstructor();

  // ⚠️ À récupérer depuis CloudinaryConfig
  static String get _cloudName => CloudinaryConfig.cloudName;
  static String get _uploadPreset => CloudinaryConfig.uploadPreset;

  /// Upload une image à Cloudinary de manière non-signée
  /// Retourne l'URL publique si succès, null sinon
  Future<String?> uploadAvatar(Uint8List imageBytes, int userId) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      // Ajouter timestamp pour éviter les conflits de public_id
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['public_id'] = 'kobeta_avatars/user_${userId}_$timestamp'
        ..fields['resource_type'] = 'auto'
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: 'avatar.jpg',
          ),
        );

      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Parser la réponse JSON pour extraire l'URL
        final Map<String, dynamic> data = _parseJson(responseBody);
        final String? secureUrl = data['secure_url'] as String?;
        // Ajouter cache buster pour forcer le refresh
        if (secureUrl != null) {
          return '$secureUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        }
        return secureUrl;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Supprime une image de Cloudinary
  /// publicId ex: "kobeta_avatars/user_123"
  Future<bool> deleteAvatar(String publicId) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/destroy',
      );

      final request = http.MultipartRequest('POST', url)
        ..fields['public_id'] = publicId
        ..fields['upload_preset'] = _uploadPreset;

      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Extrait le public_id depuis une URL Cloudinary
  /// Ex: "https://res.cloudinary.com/abc/image/upload/v123/kobeta_avatars/user_123.jpg"
  /// Retourne: "kobeta_avatars/user_123"
  static String? extractPublicIdFromUrl(String? url) {
    if (url == null) return null;
    try {
      // Format: https://res.cloudinary.com/{cloud}/image/upload/{version}/{folder}/{name}.{ext}
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Chercher l'index de "upload" et prendre tout après
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex + 2 >= pathSegments.length) {
        return null;
      }

      // Récupérer tout après /upload/v{version}/
      // Format: pathSegments[uploadIndex + 1] = "v123"
      // pathSegments[uploadIndex + 2+] = "folder/name"
      final remainingSegments = pathSegments.skip(uploadIndex + 2);
      final joinedPath = remainingSegments.join('/');

      // Enlever l'extension
      final withoutExt = joinedPath.split('.').first;
      return withoutExt;
    } catch (e) {
      return null;
    }
  }

  /// Helper: parser JSON rudimentaire
  Map<String, dynamic> _parseJson(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
