import 'dart:convert';
import 'auth_service.dart';
import 'api_config.dart';
import 'app_http.dart' as http;

class ContactService {
  static Future<void> send({
    required String fromEmail,
    required String message,
  }) async {
    final authHeader = await AuthService.instance.getAuthHeader();
    if (authHeader == null) throw Exception('Non authentifié');

    final url = Uri.parse('${ApiConfig.authUrl}/contact');
    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
      body: jsonEncode({'from_email': fromEmail, 'message': message}),
    );

    if (resp.statusCode != 200) {
      throw Exception('Erreur serveur ${resp.statusCode}');
    }
  }
}
