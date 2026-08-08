import 'package:shared_preferences/shared_preferences.dart';

/// Persistance de l'onboarding déjà vu par l'utilisateur.
///
/// Le carrousel de présentation vit désormais dans la WelcomePage (écran
/// pré-authentification), il n'a donc pas besoin d'être mémorisé. Seul le tuto
/// guidé de l'onglet Équipe, qui ne doit se jouer qu'une fois, l'est ici.
class OnboardingPrefs {
  const OnboardingPrefs._();

  static const _kTeamTour = 'onboarding_team_tour_seen';

  static Future<bool> hasSeenTeamTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTeamTour) ?? false;
  }

  static Future<void> markTeamTourSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTeamTour, true);
  }

  /// Remet le tuto à zéro — utile pour le rejouer depuis les réglages.
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTeamTour);
  }
}
