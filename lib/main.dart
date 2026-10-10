import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alarm_service.dart';
import 'clock_home.dart';
import 'settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final SettingsController controller = await SettingsController.load();
  final AlarmService alarmService =
      await AlarmService.initialize(preferences);
  runApp(ClockApp(
    controller: controller,
    alarmService: alarmService,
  ));
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
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.systemOrange,
        scaffoldBackgroundColor: CupertinoColors.black,
      ),
      home: ClockHome(
        controller: controller,
        alarmService: alarmService,
      ),
    );
  }
}
