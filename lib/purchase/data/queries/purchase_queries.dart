import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../main.dart' show talker;

/// Supabase 구독 상태 조회
abstract class PurchaseQueries {
  PurchaseQueries._();

  static Future<List<Map<String, dynamic>>> getActiveSubscriptions(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      talker.warning('[PurchaseQueries] 구독 조회 실패: $e');
      return [];
    }
  }
}
