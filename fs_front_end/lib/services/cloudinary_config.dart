// ⚠️ CONFIGURATION CLOUDINARY - À REMPLIR OBLIGATOIREMENT

import 'package:flutter/foundation.dart';

class CloudinaryConfig {
  /// Ton Cloud Name (visible dans Cloudinary Dashboard)
  /// Ex: "dz1a2b3c4d"
  static const String cloudName = 'dpfmu5bwb';

  /// Unsigned Upload Preset (à créer dans Cloudinary Dashboard)
  /// 📍 Settings → Upload → Presets → Add Upload Preset
  /// - Nom: "Kobeta"
  /// - Type: "Unsigned"
  /// - Allowed extensions: jpg, jpeg, png, gif, webp
  /// - Settings → Eager transformations: (optionnel pour auto-resize)
  static const String uploadPreset = 'Kobeta';

  /// Mode debug pour logs
  static bool debugMode = kDebugMode;
}

// SETUP CLOUDINARY - ÉTAPES

// 1️⃣ Créer un compte (gratuit)
//    https://cloudinary.com/users/register/free
//
// 2️⃣ Récupérer ton Cloud Name
//    Dashboard → Copy API Environment Variable
//    Cherche: cloudinary://api_key:api_secret@{CLOUD_NAME}
//
// 3️⃣ Créer un Upload Preset (unsigned)
//    Settings → Upload → Upload presets → Add upload preset
//    - Preset name: "five_star_avatars"
//    - Unsigned: ✅ YES
//    - Folder: "five_star_avatars/" (optionnel)
//
// 4️⃣ Remplir les constants ci-dessus
//    cloudName = "ta_cloud_name"
//    uploadPreset = "five_star_avatars"
//
// 5️⃣ Tester dans Flutter
//    - Aller à Settings → Edit Profile
//    - Cliquer sur avatar
//    - Sélectionner image
//    - Cliquer Sauvegarder
