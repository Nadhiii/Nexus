import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import '../../utils/sms_parser.dart';
import '../../models/detected_transaction.dart';

class SmsInboxService {
  final SmsQuery _query = SmsQuery();

  Future<List<SmsMessage>> getRecentMessages({int days = 7}) async {
    final now = DateTime.now();
    final since = now.subtract(Duration(days: days));
    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 200,
    );
    return messages.where((m) => (m.date ?? now).isAfter(since)).toList();
  }

  Future<List<DetectedTransaction>> detectTransactions({int days = 7}) async {
    final msgs = await getRecentMessages(days: days);
    final results = <DetectedTransaction>[];
    for (final m in msgs) {
      final body = m.body ?? '';
      if (body.isEmpty) continue;
      final parsed = SmsParser.parse(
        body: body,
        address: m.address,
        date: m.date,
      );
      if (parsed != null) results.add(parsed);
    }
    return results;
  }
}
