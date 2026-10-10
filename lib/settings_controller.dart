import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  SettingsController._({
    required SharedPreferences? preferences,
    required bool glassTransparencyEnabled,
    required double transparencyAmount,
    required bool vibrationEnabled,
  })  : _preferences = preferences,
        _glassTransparencyEnabled = glassTransparencyEnabled,
        _transparencyAmount = transparencyAmount,
        _vibrationEnabled = vibrationEnabled;

  static const String _glassTransparencyKey = 'glassTransparencyEnabled';
  static const String _transparencyAmountKey = 'transparencyAmount';
  static const String _vibrationKey = 'vibrationEnabled';

  final SharedPreferences? _preferences;
  bool _glassTransparencyEnabled;
  double _transparencyAmount;
  bool _vibrationEnabled;

  static SettingsController defaults() => SettingsController._(
        preferences: null,
        glassTransparencyEnabled: true,
        transparencyAmount: 0.75,
        vibrationEnabled: true,
      );

  static Future<SettingsController> load({
    SharedPreferences? preferences,
  }) async {
    final SharedPreferences loadedPreferences =
        preferences ?? await SharedPreferences.getInstance();
    return SettingsController._(
      preferences: loadedPreferences,
      glassTransparencyEnabled:
          loadedPreferences.getBool(_glassTransparencyKey) ?? true,
      transparencyAmount:
          loadedPreferences.getDouble(_transparencyAmountKey) ?? 0.75,
      vibrationEnabled: loadedPreferences.getBool(_vibrationKey) ?? true,
    );
  }

  bool get glassTransparencyEnabled => _glassTransparencyEnabled;
  double get transparencyAmount => _transparencyAmount;
  bool get vibrationEnabled => _vibrationEnabled;

  int get fillAlpha {
    if (!_glassTransparencyEnabled) return 0xF0;
    return ((1 - _transparencyAmount) * 0xFF)
        .round()
        .clamp(0, 0xFF)
        .toInt();
  }

  void setGlassTransparencyEnabled(bool value) {
    if (_glassTransparencyEnabled == value) return;
    _glassTransparencyEnabled = value;
    notifyListeners();
    final SharedPreferences? preferences = _preferences;
    if (preferences == null) return;
    unawaited(_save(
      preferences.setBool(_glassTransparencyKey, value),
      _glassTransparencyKey,
    ));
  }

  void setTransparencyAmount(double value) {
    final double amount = value.clamp(0, 1).toDouble();
    if (_transparencyAmount == amount) return;
    _transparencyAmount = amount;
    notifyListeners();
    final SharedPreferences? preferences = _preferences;
    if (preferences == null) return;
    unawaited(_save(
      preferences.setDouble(_transparencyAmountKey, amount),
      _transparencyAmountKey,
    ));
  }

  void setVibrationEnabled(bool value) {
    if (_vibrationEnabled == value) return;
    _vibrationEnabled = value;
    notifyListeners();
    final SharedPreferences? preferences = _preferences;
    if (preferences == null) return;
    unawaited(_save(
      preferences.setBool(_vibrationKey, value),
      _vibrationKey,
    ));
  }

  Future<void> _save(Future<bool> operation, String key) async {
    try {
      if (!await operation) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: StateError('Could not save setting "$key".'),
            library: 'clock settings',
          ),
        );
      }
    } on Exception catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'clock settings',
          context: ErrorDescription('while saving "$key"'),
        ),
      );
    }
  }
}
