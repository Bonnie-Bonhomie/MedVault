import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../barrel_export.dart';


/// Raises low-stock and expiry alerts locally, and subscribes the device to
/// Firebase Cloud Messaging so a scheduled backend job can push the same
/// alerts when the app is closed.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final Set<String> _alreadyAlerted = <String>{};
  int _id = 0;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'inventory_alerts',
    'Inventory alerts',
    channelDescription: 'Low stock and expiry warnings',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> init() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(settings);

    await FirebaseMessaging.instance.requestPermission();
    await FirebaseMessaging.instance.subscribeToTopic('inventory_alerts');

    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n != null) _show(n.title ?? 'Inventory alert', n.body ?? '');
    });
  }

  Future<void> _show(String title, String body) async {
    await _local.show(
      _id++,
      title,
      body,
      const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Called whenever a fresh medicine list arrives. Each medicine only
  /// raises one alert per app session so staff are not spammed.
  Future<void> evaluate(List<Medicine> medicines) async {
    for (final m in medicines) {
      if (m.stockStatus == StockStatus.out) {
        await _once('out-${m.id}', 'Out of stock',
            '${m.name} has run out. Reorder from ${m.supplierName}.');
      } else if (m.stockStatus == StockStatus.low) {
        await _once('low-${m.id}', 'Low stock',
            '${m.name} is down to ${m.quantity} ${m.unit}(s).');
      }

      if (m.isExpired) {
        await _once('exp-${m.id}', 'Expired stock',
            '${m.name} (batch ${m.batchNumber}) has passed its expiry date.');
      } else if (m.isExpiringSoon) {
        await _once('soon-${m.id}', 'Expiring soon',
            '${m.name} expires in ${m.daysToExpiry} days.');
      }
    }
  }

  Future<void> _once(String key, String title, String body) async {
    if (_alreadyAlerted.contains(key)) return;
    _alreadyAlerted.add(key);
    await _show(title, body);
  }
}
