import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

class ClockAlarm {
  const ClockAlarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    required this.weekdays,
    required this.enabled,
  });

  final int id;
  final int hour;
  final int minute;
  final String label;
  final List<int> weekdays;
  final bool enabled;

  ClockAlarm withEnabled(bool value) => ClockAlarm(
        id: id,
        hour: hour,
        minute: minute,
        label: label,
        weekdays: weekdays,
        enabled: value,
      );

  factory ClockAlarm.fromJson(Map<String, dynamic> json) => ClockAlarm(
        id: json['id'] as int,
        hour: json['hour'] as int,
        minute: json['minute'] as int,
        label: json['label'] as String,
        weekdays: (json['weekdays'] as List<dynamic>).cast<int>(),
        enabled: json['enabled'] as bool,
      );

  Map<String, Object> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'weekdays': weekdays,
        'enabled': enabled,
      };
}

class AlarmPermissionDenied implements Exception {
  const AlarmPermissionDenied();

  @override
  String toString() => 'Notification permission was not granted.';
}

class AlarmService {
  AlarmService._(this._preferences);

  static const String _alarmsKey = 'clockAlarms';
  static const String _nextIdKey = 'nextClockAlarmId';
  static const MethodChannel _timeZoneChannel =
      MethodChannel('clock/local_timezone');

  final SharedPreferences _preferences;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final List<ClockAlarm> _alarms = [];

  List<ClockAlarm> get alarms => List<ClockAlarm>.unmodifiable(_alarms);

  static Future<AlarmService> initialize(
    SharedPreferences preferences,
  ) async {
    timezone_data.initializeTimeZones();
    final String? timeZoneName =
        await _timeZoneChannel.invokeMethod<String>('getLocalTimeZone');
    if (timeZoneName == null || timeZoneName.isEmpty) {
      throw StateError('The device did not provide its local time zone.');
    }
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    final AlarmService service = AlarmService._(preferences);
    final bool? initialized = await service._notifications.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    if (initialized != true) {
      throw StateError('Could not initialize local notifications.');
    }
    await service._loadAlarms();
    return service;
  }

  Future<void> _loadAlarms() async {
    final String? json = _preferences.getString(_alarmsKey);
    if (json == null) return;
    final List<dynamic> decoded = jsonDecode(json) as List<dynamic>;
    _alarms
      ..clear()
      ..addAll(
        decoded.map(
          (entry) => ClockAlarm.fromJson(entry as Map<String, dynamic>),
        ),
      );
  }

  Future<void> _saveAlarms() async {
    final bool saved = await _preferences.setString(
      _alarmsKey,
      jsonEncode(_alarms.map((alarm) => alarm.toJson()).toList()),
    );
    if (!saved) throw StateError('Could not save alarms.');
  }

  Future<ClockAlarm> createAlarm({
    required int hour,
    required int minute,
    required String label,
    required List<int> weekdays,
  }) async {
    final bool permissionGranted = await _requestPermission();
    if (!permissionGranted) throw const AlarmPermissionDenied();

    final int id = _preferences.getInt(_nextIdKey) ?? 1;
    final ClockAlarm alarm = ClockAlarm(
      id: id,
      hour: hour,
      minute: minute,
      label: label,
      weekdays: List<int>.unmodifiable(weekdays..sort()),
      enabled: true,
    );

    await _schedule(alarm);
    _alarms.add(alarm);
    try {
      await _saveAlarms();
      final bool saved = await _preferences.setInt(_nextIdKey, id + 1);
      if (!saved) throw StateError('Could not save the next alarm identifier.');
    } on Exception {
      _alarms.removeWhere((existing) => existing.id == id);
      await _cancel(alarm);
      rethrow;
    }
    return alarm;
  }

  Future<void> setEnabled(ClockAlarm alarm, bool enabled) async {
    if (alarm.enabled == enabled) return;
    final ClockAlarm updated = alarm.withEnabled(enabled);
    if (enabled) {
      if (!await _requestPermission()) throw const AlarmPermissionDenied();
      await _schedule(updated);
    } else {
      await _cancel(alarm);
    }

    final int index = _alarms.indexWhere((item) => item.id == alarm.id);
    if (index < 0) throw StateError('Alarm ${alarm.id} no longer exists.');
    _alarms[index] = updated;
    try {
      await _saveAlarms();
    } on Exception {
      _alarms[index] = alarm;
      if (enabled) {
        await _cancel(updated);
      } else {
        await _schedule(alarm);
      }
      rethrow;
    }
  }

  Future<void> deleteAlarm(ClockAlarm alarm) async {
    await _cancel(alarm);
    final int index = _alarms.indexWhere((item) => item.id == alarm.id);
    if (index < 0) return;
    _alarms.removeAt(index);
    try {
      await _saveAlarms();
    } on Exception {
      _alarms.insert(index, alarm);
      if (alarm.enabled) await _schedule(alarm);
      rethrow;
    }
  }

  Future<bool> _requestPermission() async {
    final IOSFlutterLocalNotificationsPlugin? iosNotifications =
        _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosNotifications == null) {
      throw StateError('iOS notification support is unavailable.');
    }
    return await iosNotifications.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  Future<void> _schedule(ClockAlarm alarm) async {
    if (alarm.weekdays.isEmpty) {
      final tz.TZDateTime scheduled =
          _nextTime(alarm.hour, alarm.minute, weekday: null);
      await _notifications.zonedSchedule(
        id: alarm.id * 8,
        title: alarm.label.isEmpty ? 'Alarm' : alarm.label,
        body: 'It is time.',
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return;
    }

    for (final int weekday in alarm.weekdays) {
      await _notifications.zonedSchedule(
        id: alarm.id * 8 + weekday,
        title: alarm.label.isEmpty ? 'Alarm' : alarm.label,
        body: 'It is time.',
        scheduledDate: _nextTime(alarm.hour, alarm.minute, weekday: weekday),
        notificationDetails: const NotificationDetails(
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  tz.TZDateTime _nextTime(int hour, int minute, {int? weekday}) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    if (weekday == null) {
      tz.TZDateTime candidate =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (!candidate.isAfter(now)) {
        candidate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day + 1,
          hour,
          minute,
        );
      }
      return candidate;
    }

    int daysAhead = (weekday - now.weekday + 7) % 7;
    tz.TZDateTime candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysAhead,
      hour,
      minute,
    );
    if (!candidate.isAfter(now)) {
      daysAhead += 7;
      candidate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + daysAhead,
        hour,
        minute,
      );
    }
    return candidate;
  }

  Future<void> _cancel(ClockAlarm alarm) async {
    if (alarm.weekdays.isEmpty) {
      await _notifications.cancel(id: alarm.id * 8);
      return;
    }
    for (final int weekday in alarm.weekdays) {
      await _notifications.cancel(id: alarm.id * 8 + weekday);
    }
  }
}
