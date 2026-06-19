import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'js_env_stub.dart'
    if (dart.library.js) 'js_env_web.dart';

class ApiConfig {
  static String _getEnv(String key, String fallback) {
    if (kIsWeb) {
      final val = jsEnvLookup(key);
      if (val != null && val.isNotEmpty) return val;
    }
    return fallback;
  }

  static String get authUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _getEnv('AUTH_URL', 'http://10.0.2.2:8000');
    }
    return _getEnv('AUTH_URL', 'https://kobeta.fr/auth');
  }

  static String get friendsUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _getEnv('FRIENDS_URL', 'http://10.0.2.2:8001');
    }
    return _getEnv('FRIENDS_URL', 'https://kobeta.fr/friends');
  }

  static String get messagesUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _getEnv('MESSAGES_URL', 'http://10.0.2.2:8002');
    }
    return _getEnv('MESSAGES_URL', 'https://kobeta.fr/messages');
  }

  static String get teamsUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _getEnv('TEAMS_URL', 'http://10.0.2.2:8003');
    }
    return _getEnv('TEAMS_URL', 'https://kobeta.fr/teams');
  }
}
