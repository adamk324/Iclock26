import 'package:flutter/cupertino.dart';

import 'glass_tab_bar.dart';
import 'stopwatch_screen.dart';

class ClockHome extends StatefulWidget {
  const ClockHome({super.key});

  @override
  State<ClockHome> createState() => _ClockHomeState();
}

class _ClockHomeState extends State<ClockHome> {
  static const List<GlassTabBarItem> _items = [
    GlassTabBarItem(icon: CupertinoIcons.globe, label: 'World Clock'),
    GlassTabBarItem(icon: CupertinoIcons.alarm, label: 'Alarm'),
    GlassTabBarItem(icon: CupertinoIcons.stopwatch, label: 'Stopwatch'),
    GlassTabBarItem(icon: CupertinoIcons.timer, label: 'Timer'),
  ];

  int _currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    final double safeBottom = MediaQuery.paddingOf(context).bottom;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: const [
              _ComingSoonScreen(title: 'World Clock'),
              _ComingSoonScreen(title: 'Alarm'),
              StopwatchScreen(),
              _ComingSoonScreen(title: 'Timer'),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: safeBottom + 16,
            child: GlassTabBar(
              items: _items,
              currentIndex: _currentIndex,
              onChanged: (index) => setState(() => _currentIndex = index),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
        backgroundColor: CupertinoColors.black,
        border: null,
      ),
      child: const Center(
        child: Text(
          'Coming soon',
          style: TextStyle(color: CupertinoColors.systemGrey),
        ),
      ),
    );
  }
}
