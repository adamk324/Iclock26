import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

enum InstallType { trollStore, standard }

enum ClockThemeMode { system, light, dark }

class SettingsController extends ChangeNotifier {
  SettingsController._({
    required SharedPreferences? preferences,
    required bool glassTransparencyEnabled,
    required double transparencyAmount,
    required bool vibrationEnabled,
    required bool setupCompleted,
    required InstallType? installType,
    required bool inAppAlarmRing,
    required ClockThemeMode themeMode,
    required int accentIndex,
    required bool nightstandRedMode,
    required bool nightstandShowSeconds,
  })  : _preferences = preferences,
        _glassTransparencyEnabled = glassTransparencyEnabled,
        _transparencyAmount = transparencyAmount,
        _vibrationEnabled = vibrationEnabled,
        _setupCompleted = setupCompleted,
        _installType = installType,
        _inAppAlarmRing = inAppAlarmRing,
        _themeMode = themeMode,
        _accentIndex = accentIndex,
        _nightstandRedMode = nightstandRedMode,
        _nightstandShowSeconds = nightstandShowSeconds;

  static const String _glassTransparencyKey = 'glassTransparencyEnabled';
  static const String _transparencyAmountKey = 'transparencyAmount';
  static const String _vibrationKey = 'vibrationEnabled';
  static const String _setupCompletedKey = 'setupCompleted';
  static const String _installTypeKey = 'installType';
  static const String _inAppAlarmRingKey = 'inAppAlarmRing';
  static const String _themeModeKey = 'themeMode';
  static const String _accentIndexKey = 'accentIndex';
  static const String _nightstandRedModeKey = 'nightstandRedMode';
  static const String _nightstandShowSecondsKey = 'nightstandShowSeconds';

  final SharedPreferences? _preferences;
  bool _glassTransparencyEnabled;
  double _transparencyAmount;
  bool _vibrationEnabled;
  bool _setupCompleted;
  InstallType? _installType;
  bool _inAppAlarmRing;
  ClockThemeMode _themeMode;
  int _accentIndex;
  bool _nightstandRedMode;
  bool _nightstandShowSeconds;

  static SettingsController defaults() => SettingsController._(
        preferences: null,
        glassTransparencyEnabled: true,
        transparencyAmount: 0.75,
        vibrationEnabled: true,
        setupCompleted: false,
        installType: null,
        inAppAlarmRing: false,
        themeMode: ClockThemeMode.system,
        accentIndex: 0,
        nightstandRedMode: false,
        nightstandShowSeconds: false,
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
      setupCompleted: loadedPreferences.getBool(_setupCompletedKey) ?? false,
      installType: _readInstallType(
        loadedPreferences.getString(_installTypeKey),
      ),
      inAppAlarmRing: loadedPreferences.getBool(_inAppAlarmRingKey) ?? false,
      themeMode: _readThemeMode(loadedPreferences.getString(_themeModeKey)),
      accentIndex: (loadedPreferences.getInt(_accentIndexKey) ?? 0)
          .clamp(0, AppColors.accentPalette.length - 1)
          .toInt(),
      nightstandRedMode:
          loadedPreferences.getBool(_nightstandRedModeKey) ?? false,
      nightstandShowSeconds:
          loadedPreferences.getBool(_nightstandShowSecondsKey) ?? false,
    );
  }

  bool get glassTransparencyEnabled => _glassTransparencyEnabled;
  double get transparencyAmount => _transparencyAmount;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get setupCompleted => _setupCompleted;
  InstallType? get installType => _installType;
  bool get inAppAlarmRing => _inAppAlarmRing;
  ClockThemeMode get themeMode => _themeMode;
  int get accentIndex => _accentIndex;
  Color get accentColor => AppColors.accentPalette[_accentIndex];
  bool get nightstandRedMode => _nightstandRedMode;
  bool get nightstandShowSeconds => _nightstandShowSeconds;

  static InstallType? _readInstallType(String? value) {
    for (final InstallType type in InstallType.values) {
      if (type.name == value) return type;
    }
    return null;
  }

  static ClockThemeMode _readThemeMode(String? value) {
    for (final ClockThemeMode mode in ClockThemeMode.values) {
      if (mode.name == value) return mode;
    }
    return ClockThemeMode.system;
  }

  void setThemeMode(ClockThemeMode value) {
    if (_themeMode == value) return;
    _themeMode = value;
    notifyListeners();
    _saveValue(_themeModeKey, (prefs) {
      return prefs.setString(_themeModeKey, value.name);
    });
  }

  void setAccentIndex(int value) {
    if (value < 0 || value >= AppColors.accentPalette.length) {
      throw RangeError.index(value, AppColors.accentPalette);
    }
    if (_accentIndex == value) return;
    _accentIndex = value;
    notifyListeners();
    _saveValue(_accentIndexKey, (prefs) {
      return prefs.setInt(_accentIndexKey, value);
    });
  }

  void setNightstandRedMode(bool value) {
    if (_nightstandRedMode == value) return;
    _nightstandRedMode = value;
    notifyListeners();
    _saveValue(_nightstandRedModeKey, (prefs) {
      return prefs.setBool(_nightstandRedModeKey, value);
    });
  }

  void setNightstandShowSeconds(bool value) {
    if (_nightstandShowSeconds == value) return;
    _nightstandShowSeconds = value;
    notifyListeners();
    _saveValue(_nightstandShowSecondsKey, (prefs) {
      return prefs.setBool(_nightstandShowSecondsKey, value);
    });
  }

  void completeSetup() {
    if (_setupCompleted) return;
    _setupCompleted = true;
    notifyListeners();
    _saveValue(_setupCompletedKey, (prefs) {
      return prefs.setBool(_setupCompletedKey, true);
    });
  }

  void resetSetup() {
    if (!_setupCompleted) return;
    _setupCompleted = false;
    notifyListeners();
    _saveValue(_setupCompletedKey, (prefs) {
      return prefs.setBool(_setupCompletedKey, false);
    });
  }

  void setInstallType(InstallType type) {
    if (_installType == type) return;
    _installType = type;
    _inAppAlarmRing = type == InstallType.trollStore;
    notifyListeners();
    _saveValue(_installTypeKey, (prefs) {
      return prefs.setString(_installTypeKey, type.name);
    });
    _saveValue(_inAppAlarmRingKey, (prefs) {
      return prefs.setBool(_inAppAlarmRingKey, _inAppAlarmRing);
    });
  }

  void setInAppAlarmRing(bool value) {
    if (_inAppAlarmRing == value) return;
    _inAppAlarmRing = value;
    notifyListeners();
    _saveValue(_inAppAlarmRingKey, (prefs) {
      return prefs.setBool(_inAppAlarmRingKey, value);
    });
  }

  int get fillAlpha {
    if (!_glassTransparencyEnabled) return 0xF0;
    return ((1 - _transparencyAmount) * 0xFF).round().clamp(0, 0xFF).toInt();
  }

  void setGlassTransparencyEnabled(bool value) {
    if (_glassTransparencyEnabled == value) return;
    _glassTransparencyEnabled = value;
    notifyListeners();
    final SharedPreferences? preferences = _preferences;
    if (preferences == null) return;
    _saveValue(_glassTransparencyKey, (prefs) {
      return prefs.setBool(_glassTransparencyKey, value);
    });
  }

  void setTransparencyAmount(double value) {
    final double amount = value.clamp(0, 1).toDouble();
    if (_transparencyAmount == amount) return;
    _transparencyAmount = amount;
    notifyListeners();
    final SharedPreferences? preferences = _preferences;
    if (preferences == null) return;
    _saveValue(_transparencyAmountKey, (prefs) {
      return prefs.setDouble(_transparencyAmountKey, amount);
    });
  }

  void setVibrationEnabled(bool value) {
    if (_vibrationEnabled == value) return;
    _vibrationEnabled = value;
    notifyListeners();
    final SharedPreferences? preferences = _preferences;
    if (preferences == null) return;
    _saveValue(_vibrationKey, (prefs) {
      return prefs.setBool(_vibrationKey, value);
    });
  }

  void _saveValue(
    String key,
    Future<bool> Function(SharedPreferences) write,
  ) {
    final SharedPreferences? preferences = _preferences;
    if (preferences == null) return;
    unawaited(_save(write(preferences), key));
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
