import 'dart:math' as math;
import 'package:flutter/services.dart';

String _two(int n) => n.toString().padLeft(2, '0');

String fmtThreadTime(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms), n = DateTime.now();
  if (d.year == n.year && d.month == n.month && d.day == n.day) {
    return '${_two(d.hour)}:${_two(d.minute)}';
  }
  return '${_two(d.day)}.${_two(d.month)}';
}

String fmtStamp(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms), n = DateTime.now();
  final t = '${_two(d.hour)}:${_two(d.minute)}';
  if (d.year == n.year && d.month == n.month && d.day == n.day) return t;
  return '${_two(d.day)}.${_two(d.month)}. // $t';
}

bool sameAddr(String a, String b) {
  final da = a.replaceAll(RegExp(r'\D'), ''), db = b.replaceAll(RegExp(r'\D'), '');
  if (da.length < 5 || db.length < 5) return a.toLowerCase() == b.toLowerCase();
  final n = math.min(8, math.min(da.length, db.length));
  return da.substring(da.length - n) == db.substring(db.length - n);
}

class SmsThread {
  final int id, date, unread, type;
  final String address, snippet;
  final String? name;
  SmsThread.fromMap(Map m)
      : id = (m['id'] as num).toInt(),
        date = (m['date'] as num).toInt(),
        unread = (m['unread'] as num).toInt(),
        type = (m['type'] as num).toInt(),
        address = m['address'] as String,
        snippet = m['snippet'] as String,
        name = m['name'] as String?;
  String get title => (name != null && name!.isNotEmpty) ? name! : address;
  bool get lastMine => type != 1;
}

class SmsMsg {
  final int id, date, type;
  final String address, body;
  SmsMsg.fromMap(Map m)
      : id = (m['id'] as num).toInt(),
        date = (m['date'] as num).toInt(),
        type = (m['type'] as num).toInt(),
        address = m['address'] as String,
        body = m['body'] as String;
  bool get mine => type != 1;
  bool get failed => type == 5;
}

class SmsBridge {
  static const _m = MethodChannel('nightcity/sms');
  static const _e = EventChannel('nightcity/sms/events');

  /// single shared stream (android EventChannel only supports one native listener)
  static final Stream<Map> events = _e.receiveBroadcastStream().cast<Map>();

  static Future<bool> isDefault() async => (await _m.invokeMethod<bool>('isDefault')) ?? false;
  static Future<bool> requestDefault() async =>
      (await _m.invokeMethod<bool>('requestDefault')) ?? false;

  static Future<List<SmsThread>> threads() async {
    final r = await _m.invokeListMethod<Map>('threads') ?? [];
    return r.map(SmsThread.fromMap).toList();
  }

  static Future<List<SmsMsg>> messages(int threadId) async {
    final r = await _m.invokeListMethod<Map>('messages', {'threadId': threadId}) ?? [];
    return r.map(SmsMsg.fromMap).toList();
  }

  static Future<void> send(String address, String body) =>
      _m.invokeMethod('send', {'address': address, 'body': body});

  static Future<void> markRead(int threadId) =>
      _m.invokeMethod('markRead', {'threadId': threadId});

  static Future<int> threadIdFor(String address) async =>
      (await _m.invokeMethod<int>('threadIdFor', {'address': address})) ?? -1;

  static Future<String?> initialAddress() => _m.invokeMethod<String>('initialAddress');
}
