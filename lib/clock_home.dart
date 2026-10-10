import 'package:flutter/cupertino.dart';

import 'glass_tab_bar.dart';
import 'settings_controller.dart';
import 'settings_screen.dart';
import 'stopwatch_screen.dart';

class ClockHome extends StatefulWidget {
  const ClockHome({
    required this.controller,
    super.key,
  });

  final SettingsController controller;

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
  bool _settingsSelected = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final double safeBottom = MediaQuery.paddingOf(context).bottom;
        return CupertinoPageScaffold(
          child: Stack(
            children: [
              IndexedStack(
                index: _settingsSelected ? 4 : _currentIndex,
                children: [
                  const _ComingSoonScreen(title: 'World Clock'),
                  const _ComingSoonScreen(title: 'Alarm'),
                  const StopwatchScreen(),
                  const _ComingSoonScreen(title: 'Timer'),
                  SettingsScreen(controller: widget.controller),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: safeBottom + 16,
                child: GlassTabBar(
                  items: _items,
                  currentIndex: _currentIndex,
                  settingsSelected: _settingsSelected,
                  fillAlpha: widget.controller.fillAlpha,
                  vibrationEnabled: widget.controller.vibrationEnabled,
                  onChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                      _settingsSelected = false;
                    });
                  },
                  onSettingsPressed: () {
                    setState(() => _settingsSelected = true);
                  },
                ),
              ),
            ],
          ),
        );
      },
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
