import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'js_env_stub.dart' if (dart.library.js) 'js_env_web.dart';

class ApiConfig {
  // ── Back-end local (dev) ────────────────────────────────────────────────
  // Passe à `true` pour taper le back-end qui tourne sur ta machine (docker).
  // ⚠️ REMETS `false` avant tout build de prod / envoi App Store.
  static const bool useLocalBackend = true;

  // Hôte du back-end local :
  //  - Simulateur iOS ou web         → 'localhost'
  //  - iPhone physique (même Wi-Fi)  → l'IP LAN du Mac, ex '192.168.1.42'
  //    (récupère-la avec : ipconfig getifaddr en0)
  static const String localHost = 'localhost';

  // Chaque service écoute sur son port et préfixe ses routes (/auth, /teams…).
  // Le préfixe fait donc partie de l'URL de base, comme en prod.
  static String _local(int port, String prefix) =>
      'http://$localHost:$port$prefix';

  static String _getEnv(String key, String fallback) {
    if (kIsWeb) {
      final val = jsEnvLookup(key);
      if (val != null && val.isNotEmpty) return val;
    }
    return fallback;
  }

  static String get authUrl {
    if (useLocalBackend) return _local(8000, '/auth');
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _getEnv('AUTH_URL', 'http://10.0.2.2:8000');
    }
    return _getEnv('AUTH_URL', 'https://www.kobeta.fr/auth');
  }

  static String get friendsUrl {
    if (useLocalBackend) return _local(8001, '/friends');
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _getEnv('FRIENDS_URL', 'http://10.0.2.2:8001');
    }
    return _getEnv('FRIENDS_URL', 'https://www.kobeta.fr/friends');
  }

  static String get messagesUrl {
    if (useLocalBackend) return _local(8002, '/messages');
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _getEnv('MESSAGES_URL', 'http://10.0.2.2:8002');
    }
    return _getEnv('MESSAGES_URL', 'https://www.kobeta.fr/messages');
  }

  static String get teamsUrl {
    if (useLocalBackend) return _local(8003, '/teams');
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _getEnv('TEAMS_URL', 'http://10.0.2.2:8003');
    }
    return _getEnv('TEAMS_URL', 'https://www.kobeta.fr/teams');
  }
}
