import 'package:flutter/foundation.dart';

/// Demande de changement d'onglet adressée à MainScreen.
///
/// `MainScreen.of(context)` ne fonctionne que depuis ses descendants. Une page
/// poussée sur le Navigator racine (les Réglages, par exemple) est une route
/// sœur de MainScreen, pas un enfant : elle ne peut donc pas l'atteindre par le
/// contexte. Ce signal global comble ce trou.
///
/// Index : 0 = Terrains, 1 = Équipe, 2 = Amis, 3 = Profil.
/// La valeur est remise à null par MainScreen une fois la demande honorée.
final ValueNotifier<int?> requestedTab = ValueNotifier<int?>(null);
