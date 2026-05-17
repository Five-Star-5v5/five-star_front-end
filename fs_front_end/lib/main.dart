import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/fields_provider.dart';
import 'providers/friends_provider.dart';
import 'providers/messages_provider.dart';
import 'providers/teams_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://5c76a246e4d2098a5dd4a9176e617156@o4511405802848256.ingest.de.sentry.io/4511405828472912';
      options.tracesSampleRate = 0.2;
      options.environment = 'production';
    },
    appRunner: () => runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => FriendsProvider()),
          ChangeNotifierProvider(create: (_) => MessagesProvider()),
          ChangeNotifierProvider(create: (_) => TeamsProvider()),
          ChangeNotifierProvider(create: (_) => FieldsProvider()),
        ],
        child: FootApp(),
      ),
    ),
  );
}
