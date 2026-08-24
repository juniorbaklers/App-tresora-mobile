import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/evenement.dart';

/// Table `evenements`. Pas de trigger de recalcul côté base pour
/// montant_collecte/participants (contrairement aux tranches de
/// cotisation) : on lit la valeur courante puis on l'incrémente ici.
class EvenementsService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Evenement>> streamEvenements(String espaceId) {
    return _client
        .from('evenements')
        .stream(primaryKey: ['id'])
        .eq('espace_id', espaceId)
        .order('date_debut', ascending: false)
        .map((rows) => rows.map(Evenement.fromMap).toList());
  }

  Future<void> creer(Evenement evenement) => _client.from('evenements').insert(evenement.toInsertMap());

  /// Enregistre une contribution à la collecte : ajoute [montant] au total
  /// collecté et incrémente le nombre de participants d'une unité.
  Future<void> enregistrerCollecte(String evenementId, double montant) async {
    final row = await _client
        .from('evenements')
        .select('montant_collecte, participants')
        .eq('id', evenementId)
        .single();
    final montantCollecte = (row['montant_collecte'] as num).toDouble() + montant;
    final participants = (row['participants'] as num).toInt() + 1;
    await _client
        .from('evenements')
        .update({'montant_collecte': montantCollecte, 'participants': participants})
        .eq('id', evenementId);
  }

  Future<void> changerStatut(String evenementId, StatutEvenement statut) =>
      _client.from('evenements').update({'statut': statut.valeurBdd}).eq('id', evenementId);
}
