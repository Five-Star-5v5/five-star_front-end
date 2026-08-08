/// Formatage du temps écoulé depuis un événement, en français.
///
/// Renvoie une chaîne du type « à l'instant », « il y a 5 min », « il y a 2 h »,
/// « il y a 3 j », « il y a 2 sem », « il y a 4 mois » ou « il y a 1 an ».
///
/// [date] doit être une date déjà en heure locale (voir [parseServerDate] dans
/// `server_date.dart` pour les timestamps renvoyés par le backend).
String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);

  // Dates dans le futur (léger décalage d'horloge) : on affiche « à l'instant ».
  if (diff.isNegative || diff.inSeconds < 60) return "à l'instant";
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';

  final weeks = (diff.inDays / 7).floor();
  if (weeks < 5) return 'il y a $weeks sem';

  final months = (diff.inDays / 30).floor();
  if (months < 12) return 'il y a $months mois';

  final years = (diff.inDays / 365).floor();
  return 'il y a $years an${years > 1 ? 's' : ''}';
}
