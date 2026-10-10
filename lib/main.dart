import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alarm_service.dart';
import 'clock_home.dart';
import 'settings_controller.dart';

const CupertinoThemeData _clockTheme = CupertinoThemeData(
  brightness: Brightness.dark,
  primaryColor: CupertinoColors.systemOrange,
  scaffoldBackgroundColor: CupertinoColors.black,
);

final ValueNotifier<List<String>> _startupErrors =
    ValueNotifier<List<String>>(<String>[]);

void _reportError(Object error, StackTrace stackTrace) {
  _startupErrors.value = List<String>.unmodifiable([
    ..._startupErrors.value,
    error.toString(),
  ]);
}

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        _reportError(details.exception, details.stack ?? StackTrace.current);
      };
      runApp(const BootGate());
    },
    _reportError,
  );
}

class _Services {
  const _Services(this.controller, this.alarmService);

  final SettingsController controller;
  final AlarmService alarmService;
}

class BootGate extends StatefulWidget {
  const BootGate({super.key});

  @override
  State<BootGate> createState() => _BootGateState();
}

class _BootGateState extends State<BootGate> {
  late final Future<_Services> _services;

  @override
  void initState() {
    super.initState();
    _services = _load();
  }

  Future<_Services> _load() async {
    SharedPreferences? preferences;
    try {
      preferences =
          await SharedPreferences.getInstance().timeout(const Duration(seconds: 5));
    } on Object catch (error, stackTrace) {
      _reportError(error, stackTrace);
    }

    SettingsController controller = SettingsController.defaults();
    if (preferences != null) {
      try {
        controller = await SettingsController.load(
          preferences: preferences,
        ).timeout(const Duration(seconds: 5));
      } on Object catch (error, stackTrace) {
        _reportError(error, stackTrace);
      }
    }

    AlarmService alarmService = AlarmService.unavailable(
      StateError('Shared preferences are unavailable.'),
    );
    if (preferences != null) {
      try {
        alarmService = await AlarmService.initialize(
          preferences,
        ).timeout(const Duration(seconds: 5));
        final Object? error = alarmService.initError;
        if (error != null) _reportError(error, StackTrace.current);
      } on Object catch (error, stackTrace) {
        _reportError(error, stackTrace);
        alarmService = AlarmService.unavailable(error);
      }
    } else {
      _reportError(
        StateError('Settings could not be loaded; using defaults.'),
        StackTrace.current,
      );
    }
    return _Services(controller, alarmService);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Services>(
      future: _services,
      builder: (context, snapshot) {
        final _Services? services = snapshot.data;
        if (services != null) {
          return ClockApp(
            controller: services.controller,
            alarmService: services.alarmService,
          );
        }
        return CupertinoApp(
          debugShowCheckedModeBanner: false,
          theme: _clockTheme,
          home: CupertinoPageScaffold(
            backgroundColor: CupertinoColors.black,
            child: Center(
              child: snapshot.hasError
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Startup failed:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: CupertinoColors.white),
                      ),
                    )
                  : const CupertinoActivityIndicator(),
            ),
          ),
        );
      },
    );
  }
}

class ClockApp extends StatelessWidget {
  const ClockApp({
    required this.controller,
    required this.alarmService,
    super.key,
  });

  final SettingsController controller;
  final AlarmService alarmService;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final Brightness? brightness = switch (controller.themeMode) {
          ClockThemeMode.system => null,
          ClockThemeMode.light => Brightness.light,
          ClockThemeMode.dark => Brightness.dark,
        };
        return CupertinoApp(
          debugShowCheckedModeBanner: false,
          theme: CupertinoThemeData(
            brightness: brightness,
            primaryColor: controller.accentColor,
            scaffoldBackgroundColor:
                brightness == Brightness.light ? const Color(0xFFF2F2F7) : null,
          ),
          home: ValueListenableBuilder<List<String>>(
            valueListenable: _startupErrors,
            builder: (context, errors, child) => Stack(
              children: [
                ClockHome(
                  controller: controller,
                  alarmService: alarmService,
                ),
                if (errors.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        color: CupertinoColors.black,
                        padding: const EdgeInsets.all(12),
                        child: SingleChildScrollView(
                          child: Text(
                            errors.join('\n'),
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
