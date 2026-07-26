import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme_config/colors_config.dart';
import 'auth/login.dart';
import 'auth/signup.dart';
import 'auth/welcome_page.dart';
import 'auth/forgot_password_page.dart';
import 'main_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_colors.dart';

class FootApp extends StatefulWidget {
  const FootApp({super.key});

  @override
  State<FootApp> createState() => _FootAppState();
}

class _FootAppState extends State<FootApp> {
  final ThemeData _lightTheme = ThemeData(
    primaryColor: MyprimaryDark,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.green,
      accentColor: myAccentVibrantBlue,
    ),
    scaffoldBackgroundColor: myLightBackground,
    useMaterial3: true,
  );

  final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: myAccentVibrantBlue,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.green,
      accentColor: myAccentVibrantBlue,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: myDarkBackground,
    useMaterial3: true,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // handle loading state
        if (auth.isLoading) {
          return MaterialApp(
            title: 'Foot 5 Réservation',
            debugShowCheckedModeBanner: false,
            theme: _lightTheme,
            darkTheme: _darkTheme,
            themeMode: theme.mode,
            home: const Scaffold(
              backgroundColor: AppColors.bg,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.amber),
              ),
            ),
          );
        }

        return MaterialApp(
          title: 'Foot 5 Réservation',
          debugShowCheckedModeBanner: false,
          theme: _lightTheme,
          darkTheme: _darkTheme,
          themeMode: theme.mode,
          home: auth.isAuthenticated ? const MainScreen() : const WelcomePage(),
          routes: {
            '/login': (context) => const LoginPage(),
            '/signup': (context) => const SignUpPage(),
            '/forgot_password': (context) => const ForgotPasswordPage(),
          },
        );
      },
    );
  }
}
