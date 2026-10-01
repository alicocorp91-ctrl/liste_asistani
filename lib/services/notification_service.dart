import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Yerel bildirimler (hatırlatıcılar). Singleton.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool get isReady => _ready;

  /// Bildirime tıklanınca çağrılır; payload = liste id.
  void Function(String payload)? onTap;

  static const _channelId = 'reminders';
  static const _channelName = 'Hatırlatıcılar';
  static const _channelDesc = 'Liste kalemleri için planlanmış hatırlatıcılar';

  Future<void> init() async {
    if (_ready) return;
    try {
      tz_data.initializeTimeZones();
      await _setLocalTimezone();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      // Masaüstü (Windows/Linux): uygulama PC'de geliştirilirken de
      // hatırlatıcıların çalışması için.
      const windows = WindowsInitializationSettings(
        appName: 'Liste Asistanı',
        appUserModelId: 'com.alico.liste_asistani',
        guid: '6f1c4d0e-2b7a-4c1e-9a3d-5e8f7b2c1a90',
      );
      const linux = LinuxInitializationSettings(defaultActionName: 'Aç');
      await _plugin.initialize(
        const InitializationSettings(
          android: android,
          iOS: ios,
          macOS: ios,
          windows: windows,
          linux: linux,
        ),
        onDidReceiveNotificationResponse: (resp) {
          final p = resp.payload;
          if (p != null && p.isNotEmpty) onTap?.call(p);
        },
      );
      if (Platform.isAndroid) {
        final impl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await impl?.requestNotificationsPermission();
        await impl?.requestExactAlarmsPermission();
      }
      _ready = true;
    } catch (e, st) {
      debugPrint('NotificationService init hatası: $e\n$st');
    }
  }

  Future<void> _setLocalTimezone() async {
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('Saat dilimi alınamadı, Europe/Istanbul kullanılıyor: $e');
      try {
        tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      } catch (_) {}
    }
  }

  /// Uygulama bir bildirime tıklanarak açıldıysa payload'ı döndürür.
  Future<String?> launchPayload() async {
    try {
      final d = await _plugin.getNotificationAppLaunchDetails();
      if (d?.didNotificationLaunchApp == true) {
        return d?.notificationResponse?.payload;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
  }) async {
    if (!_ready) return false;
    if (!at.isAfter(DateTime.now())) return false;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(at, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(
              presentAlert: true, presentSound: true, presentBadge: true),
          macOS: const DarwinNotificationDetails(
              presentAlert: true, presentSound: true, presentBadge: true),
          windows: const WindowsNotificationDetails(),
          linux: const LinuxNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      return true;
    } catch (e) {
      debugPrint('Bildirim planlanamadı: $e');
      return false;
    }
  }

  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
