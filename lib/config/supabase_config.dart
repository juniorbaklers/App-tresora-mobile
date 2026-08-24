/// Identifiants du projet Supabase — mêmes valeurs que `config.js` dans le
/// dépôt web `gestion-caisse-eglise` (Settings > API sur supabase.com).
/// L'app mobile et l'app web pointent vers la MÊME base : les données
/// saisies d'un côté apparaissent en temps réel de l'autre.
class SupabaseConfig {
  static const String url = 'https://VOTRE-PROJET.supabase.co';
  static const String anonKey = 'VOTRE_CLE_ANON_PUBLIC';
}
