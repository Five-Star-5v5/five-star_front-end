/// Parsing des dates renvoyées par le backend.
///
/// Le backend génère ses timestamps avec `datetime.utcnow()` (Python), donc des
/// dates UTC « naïves » sérialisées SANS suffixe de fuseau (`Z`).
/// `DateTime.parse` interpréterait alors ces chaînes comme de l'heure locale,
/// ce qui décale l'affichage du fuseau de l'appareil (ex. +2h à Paris l'été).
///
/// [parseServerDate] réinterprète toute date sans fuseau comme de l'UTC, puis la
/// convertit en heure locale — les « il y a X heures » et les heures de chat
/// deviennent alors correctes.
///
/// À n'utiliser QUE pour les timestamps générés par le serveur
/// (created_at, updated_at, joined_at, applied_at, responded_at, read_at,
/// match_played_at). Les dates saisies par l'utilisateur et envoyées telles
/// quelles (match_date, proposed_date) font déjà un aller-retour cohérent en
/// heure locale et doivent rester sur `DateTime.parse`.
DateTime parseServerDate(String value) {
  final parsed = DateTime.parse(value);
  if (parsed.isUtc) return parsed.toLocal();
  // Pas d'information de fuseau dans la chaîne : on considère l'heure comme UTC.
  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  ).toLocal();
}
