import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'alarm_screen.dart';
import 'alarm_service.dart';
import 'app_colors.dart';
import 'first_run_setup.dart';
import 'glass_tab_bar.dart';
import 'nightstand_screen.dart';
import 'settings_controller.dart';
import 'settings_screen.dart';
import 'stopwatch_screen.dart';
import 'world_clock_screen.dart';

class ClockHome extends StatefulWidget {
  const ClockHome({
    required this.controller,
    required this.alarmService,
    super.key,
  });

  final SettingsController controller;
  final AlarmService alarmService;

  @override
  State<ClockHome> createState() => _ClockHomeState();
}

class _ClockHomeState extends State<ClockHome> with WidgetsBindingObserver {
  static const List<GlassTabBarItem> _items = [
    GlassTabBarItem(icon: CupertinoIcons.globe, label: 'World Clock'),
    GlassTabBarItem(icon: CupertinoIcons.alarm, label: 'Alarm'),
    GlassTabBarItem(icon: CupertinoIcons.stopwatch, label: 'Stopwatch'),
    GlassTabBarItem(icon: CupertinoIcons.timer, label: 'Timer'),
  ];

  int _currentIndex = 2;
  bool _settingsSelected = false;
  Timer? _alarmTimer;
  bool _ringRouteOpen = false;
  String? _trackedMinute;
  final Set<int> _rungAlarmIds = <int>{};
  ClockAlarm? _snoozedAlarm;
  DateTime? _snoozeAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_settingsChanged);
    _syncAlarmTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.controller.setupCompleted) {
        _runSetup();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncAlarmTimer();
    } else {
      _alarmTimer?.cancel();
      _alarmTimer = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_settingsChanged);
    _alarmTimer?.cancel();
    super.dispose();
  }

  void _settingsChanged() => _syncAlarmTimer();

  Future<void> _runSetup() {
    return showFirstRunSetup(
      context: context,
      controller: widget.controller,
      alarmService: widget.alarmService,
    );
  }

  Future<void> _openNightstand() {
    return Navigator.of(context).push<void>(
      CupertinoPageRoute<void>(
        builder: (context) => NightstandScreen(
          controller: widget.controller,
          alarmService: widget.alarmService,
        ),
      ),
    );
  }

  void _syncAlarmTimer() {
    if (!widget.controller.inAppAlarmRing ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      _alarmTimer?.cancel();
      _alarmTimer = null;
      return;
    }
    _alarmTimer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkDueAlarm(),
    );
  }

  void _checkDueAlarm() {
    if (!mounted || !widget.controller.inAppAlarmRing || _ringRouteOpen) return;
    final DateTime now = DateTime.now();
    ClockAlarm? alarm;
    final DateTime? snoozeAt = _snoozeAt;
    if (_snoozedAlarm != null && snoozeAt != null && !now.isBefore(snoozeAt)) {
      alarm = _snoozedAlarm;
      _snoozedAlarm = null;
      _snoozeAt = null;
    } else {
      final String minuteKey =
          '${now.year}-${now.month}-${now.day}-${now.hour}-${now.minute}';
      if (_trackedMinute != minuteKey) {
        _trackedMinute = minuteKey;
        _rungAlarmIds.clear();
      }
      for (final ClockAlarm due in widget.alarmService.alarmsDueAt(now)) {
        if (!_rungAlarmIds.contains(due.id)) {
          alarm = due;
          break;
        }
      }
    }
    if (alarm == null) return;
    _rungAlarmIds.add(alarm.id);
    _ringRouteOpen = true;
    Navigator.of(context)
        .push<void>(
      CupertinoPageRoute<void>(
        builder: (context) => _AlarmRingScreen(
          alarm: alarm!,
          onSnooze: () {
            _snoozedAlarm = alarm;
            _snoozeAt = DateTime.now().add(const Duration(minutes: 9));
          },
        ),
      ),
    )
        .whenComplete(() {
      _ringRouteOpen = false;
    });
  }

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
                  WorldClockScreen(
                    onOpenNightstand: _openNightstand,
                  ),
                  AlarmScreen(service: widget.alarmService),
                  const StopwatchScreen(),
                  const _ComingSoonScreen(title: 'Timer'),
                  SettingsScreen(
                    controller: widget.controller,
                    onRunSetupAgain: _runSetup,
                    alarmService: widget.alarmService,
                  ),
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
        backgroundColor: AppColors.of(context).background,
        border: null,
      ),
      child: Center(
        child: Text(
          'Coming soon',
          style: TextStyle(color: AppColors.of(context).secondaryText),
        ),
      ),
    );
  }
}

class _AlarmRingScreen extends StatefulWidget {
  const _AlarmRingScreen({
    required this.alarm,
    required this.onSnooze,
  });

  final ClockAlarm alarm;
  final VoidCallback onSnooze;

  @override
  State<_AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<_AlarmRingScreen>
    with WidgetsBindingObserver {
  Timer? _alertTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startAlerts();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startAlerts();
    } else {
      _alertTimer?.cancel();
      _alertTimer = null;
    }
  }

  void _startAlerts() {
    if (_alertTimer != null) return;
    _playAlert();
    _alertTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _playAlert(),
    );
  }

  void _playAlert() {
    unawaited(SystemSound.play(SystemSoundType.alert));
    unawaited(HapticFeedback.heavyImpact());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _alertTimer?.cancel();
    super.dispose();
  }

  void _dismiss({bool snooze = false}) {
    if (snooze) widget.onSnooze();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.of(context).background,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.alarm,
                  color: CupertinoTheme.of(context).primaryColor,
                  size: 52,
                ),
                const SizedBox(height: 22),
                Text(
                  widget.alarm.label.isEmpty ? 'Alarm' : widget.alarm.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.of(context).primaryText,
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${widget.alarm.hour.toString().padLeft(2, '0')}:'
                  '${widget.alarm.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: AppColors.of(context).secondaryText,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 64),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _dismiss,
                    child: const Text('Stop'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: AppColors.of(context).secondaryButton,
                    onPressed: () => _dismiss(snooze: true),
                    child: const Text('Snooze · 9 minutes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
