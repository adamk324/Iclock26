import 'package:flutter/cupertino.dart';

import 'stopwatch_screen.dart';

void main() {
  runApp(const StopwatchApp());
}

class StopwatchApp extends StatelessWidget {
  const StopwatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.systemGreen,
        scaffoldBackgroundColor: CupertinoColors.black,
      ),
      home: StopwatchScreen(),
    );
  }
}
