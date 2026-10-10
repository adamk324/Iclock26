import 'package:flutter/cupertino.dart';

import 'clock_home.dart';
import 'settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SettingsController controller = await SettingsController.load();
  runApp(ClockApp(controller: controller));
}

class ClockApp extends StatelessWidget {
  const ClockApp({required this.controller, super.key});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.systemOrange,
        scaffoldBackgroundColor: CupertinoColors.black,
      ),
      home: ClockHome(controller: controller),
    );
  }
}
