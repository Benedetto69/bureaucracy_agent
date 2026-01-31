import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../utils/deadline_calculator.dart';

/// Servizio per gestire le notifiche delle scadenze
class DeadlineNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const String _notificationsEnabledKey = 'deadline_notifications_enabled';
  static const String _scheduledNotificationsKey = 'scheduled_deadline_notifications';

  /// Inizializza il servizio di notifiche
  static Future<bool> initialize() async {
    if (_initialized) return true;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Rome'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final result = await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = result ?? false;
    return _initialized;
  }

  /// Richiede i permessi per le notifiche
  static Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return result ?? false;
    }
    return false;
  }

  /// Verifica se le notifiche sono abilitate
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? false;
  }

  /// Abilita o disabilita le notifiche
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);

    if (!enabled) {
      await cancelAllNotifications();
    }
  }

  /// Programma le notifiche per una multa
  static Future<void> scheduleDeadlineNotifications({
    required String fineId,
    required String fineDescription,
    required DateTime notificationDate,
    required double amount,
  }) async {
    if (!await areNotificationsEnabled()) return;
    if (!_initialized) await initialize();

    final info = DeadlineCalculator.getDeadlineInfo(notificationDate);

    // Non programmare se già scaduto
    if (info.isExpired) return;

    // Cancella eventuali notifiche precedenti per questa multa
    await cancelNotificationsForFine(fineId);

    final baseId = fineId.hashCode.abs() % 100000;
    final scheduledIds = <int>[];

    // Notifica 10 giorni prima della scadenza
    if (info.daysRemainingPrefetto > 10) {
      final id = baseId + 1;
      await _scheduleNotification(
        id: id,
        title: 'Scadenza ricorso tra 10 giorni',
        body: 'Multa di €${amount.toStringAsFixed(0)}: hai ancora 10 giorni per il ricorso al Prefetto.',
        scheduledDate: info.prefettoDeadline.subtract(const Duration(days: 10)),
        payload: fineId,
      );
      scheduledIds.add(id);
    }

    // Notifica 5 giorni prima della scadenza
    if (info.daysRemainingPrefetto > 5) {
      final id = baseId + 2;
      await _scheduleNotification(
        id: id,
        title: 'Scadenza ricorso tra 5 giorni!',
        body: 'Multa di €${amount.toStringAsFixed(0)}: urgente! Solo 5 giorni rimasti per il ricorso.',
        scheduledDate: info.prefettoDeadline.subtract(const Duration(days: 5)),
        payload: fineId,
      );
      scheduledIds.add(id);
    }

    // Notifica 2 giorni prima della scadenza
    if (info.daysRemainingPrefetto > 2) {
      final id = baseId + 3;
      await _scheduleNotification(
        id: id,
        title: 'URGENTE: Scadenza tra 2 giorni!',
        body: 'Multa di €${amount.toStringAsFixed(0)}: ultima possibilità per il ricorso!',
        scheduledDate: info.prefettoDeadline.subtract(const Duration(days: 2)),
        payload: fineId,
      );
      scheduledIds.add(id);
    }

    // Notifica per pagamento ridotto (5 giorni)
    if (info.daysRemainingEarlyPayment > 1) {
      final id = baseId + 4;
      await _scheduleNotification(
        id: id,
        title: 'Ultimo giorno per lo sconto!',
        body: 'Multa di €${amount.toStringAsFixed(0)}: paga oggi per avere il 30% di sconto.',
        scheduledDate: notificationDate.add(const Duration(days: 4)),
        payload: fineId,
      );
      scheduledIds.add(id);
    }

    // Salva gli ID delle notifiche programmate
    await _saveScheduledNotifications(fineId, scheduledIds);
  }

  /// Programma una singola notifica
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    // Non programmare notifiche nel passato
    if (scheduledDate.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'deadline_reminders',
      'Promemoria Scadenze',
      channelDescription: 'Notifiche per le scadenze dei ricorsi',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Errore programmazione notifica: $e');
    }
  }

  /// Cancella tutte le notifiche per una multa
  static Future<void> cancelNotificationsForFine(String fineId) async {
    final prefs = await SharedPreferences.getInstance();
    final scheduledJson = prefs.getString(_scheduledNotificationsKey);

    if (scheduledJson != null) {
      try {
        final scheduled = Map<String, List<dynamic>>.from(
          (scheduledJson.isNotEmpty)
              ? Map.from(_parseJson(scheduledJson))
              : {},
        );

        final ids = scheduled[fineId];
        if (ids != null) {
          for (final id in ids) {
            await _notifications.cancel(id as int);
          }
          scheduled.remove(fineId);
          await prefs.setString(
            _scheduledNotificationsKey,
            _encodeJson(scheduled),
          );
        }
      } catch (e) {
        debugPrint('Errore cancellazione notifiche: $e');
      }
    }
  }

  /// Cancella tutte le notifiche
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scheduledNotificationsKey);
  }

  /// Salva gli ID delle notifiche programmate
  static Future<void> _saveScheduledNotifications(
    String fineId,
    List<int> ids,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final scheduledJson = prefs.getString(_scheduledNotificationsKey);

    Map<String, List<dynamic>> scheduled;
    if (scheduledJson != null && scheduledJson.isNotEmpty) {
      scheduled = Map<String, List<dynamic>>.from(_parseJson(scheduledJson));
    } else {
      scheduled = {};
    }

    scheduled[fineId] = ids;
    await prefs.setString(_scheduledNotificationsKey, _encodeJson(scheduled));
  }

  /// Callback quando una notifica viene toccata
  static void _onNotificationTapped(NotificationResponse response) {
    // Il payload contiene il fineId
    final fineId = response.payload;
    debugPrint('Notifica toccata per multa: $fineId');
  }

  /// Ottieni le notifiche pendenti
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Parse JSON string to Map safely
  static Map<String, dynamic> _parseJson(String json) {
    if (json.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(json) as Map);
    } catch (_) {
      return {};
    }
  }

  /// Encode Map to JSON string
  static String _encodeJson(Map<String, List<dynamic>> map) {
    return jsonEncode(map);
  }
}
