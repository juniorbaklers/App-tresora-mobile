import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import '../utils/cache_hors_ligne.dart';

/// Table `notifications` — jamais écrite directement par l'app (des
/// triggers côté base la remplissent), seulement lue et marquée comme lue.
class NotificationsService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<NotificationTresora>> streamMesNotifications(String userId) {
    final flux = _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('date', ascending: false);
    return avecCacheHorsLigne('notifications_$userId', flux)
        .map((rows) => rows.map(NotificationTresora.fromMap).toList());
  }

  Future<void> marquerLue(String id) =>
      _client.from('notifications').update({'lue': true}).eq('id', id);

  Future<void> marquerToutesLues(String userId) => _client
      .from('notifications')
      .update({'lue': true})
      .eq('user_id', userId)
      .eq('lue', false);
}
