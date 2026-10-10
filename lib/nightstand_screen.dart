import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'alarm_service.dart';
import 'settings_controller.dart';

class NightstandScreen extends StatefulWidget {
  const NightstandScreen({
    required this.controller,
    required this.alarmService,
    super.key,
  });

  final SettingsController controller;
  final AlarmService alarmService;

  @override
  State<NightstandScreen> createState() => _NightstandScreenState();
}

class _NightstandScreenState extends State<NightstandScreen> {
  final ValueNotifier<DateTime> _now = ValueNotifier<DateTime>(DateTime.now());
  Timer? _clockTimer;
  Timer? _closeHintTimer;
  double _dimming = 0;
  bool _showClose = false;
  String? _systemError;
  late final Future<void> _systemSetup;

  @override
  void initState() {
    super.initState();
    _systemSetup = _enterNightstand();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _now.value = DateTime.now(),
    );
  }

  Future<void> _enterNightstand() async {
    try {
      await Future.wait<void>([
        SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]),
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
        WakelockPlus.enable(),
      ]);
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'nightstand',
          context: ErrorDescription('while enabling nightstand mode'),
        ),
      );
      if (mounted) setState(() => _systemError = error.toString());
    }
  }

  Future<void> _restoreSystem() async {
    try {
      await Future.wait<void>([
        SystemChrome.setPreferredOrientations(DeviceOrientation.values),
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
        WakelockPlus.disable(),
      ]);
    } on Object catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'nightstand',
          context: ErrorDescription('while restoring system display settings'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _closeHintTimer?.cancel();
    _now.dispose();
    unawaited(_systemSetup.then((_) => _restoreSystem()));
    super.dispose();
  }

  void _showCloseTemporarily() {
    _closeHintTimer?.cancel();
    setState(() => _showClose = true);
    _closeHintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showClose = false);
    });
  }

  String _dateLabel(DateTime time) {
    const List<String> weekdays = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const List<String> months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[time.weekday - 1]}, ${months[time.month - 1]} '
        '${time.day}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) => CupertinoPageScaffold(
        backgroundColor: CupertinoColors.black,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _showCloseTemporarily,
          onVerticalDragUpdate: (details) {
            final double height = MediaQuery.sizeOf(context).height;
            setState(() {
              _dimming = (_dimming + details.delta.dy / height)
                  .clamp(0.0, 0.8)
                  .toDouble();
            });
          },
          child: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    SizedBox(
                      height: 44,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedOpacity(
                          opacity: _showClose ? 1 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: CupertinoButton(
                            onPressed: _showClose
                                ? () => Navigator.of(context).pop()
                                : null,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: const Icon(
                              CupertinoIcons.xmark,
                              color: CupertinoColors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ValueListenableBuilder<DateTime>(
                        valueListenable: _now,
                        builder: (context, now, child) {
                          final String time = widget.controller
                                  .nightstandShowSeconds
                              ? '${now.hour.toString().padLeft(2, '0')}:'
                                  '${now.minute.toString().padLeft(2, '0')}:'
                                  '${now.second.toString().padLeft(2, '0')}'
                              : '${now.hour.toString().padLeft(2, '0')}:'
                                  '${now.minute.toString().padLeft(2, '0')}';
                          final Color timeColor =
                              widget.controller.nightstandRedMode
                                  ? CupertinoColors.systemRed
                                  : CupertinoColors.white;
                          final Color dateColor =
                              widget.controller.nightstandRedMode
                                  ? const Color(0xADFF3B30)
                                  : const Color(0xADFFFFFF);
                          final DateTime? nextAlarm =
                              widget.alarmService.nextAlarmDateTime(now);
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  time,
                                  style: TextStyle(
                                    color: timeColor,
                                    fontSize: 112,
                                    fontWeight: FontWeight.w200,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _dateLabel(now),
                                style: TextStyle(
                                  color: dateColor,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              if (nextAlarm != null) ...[
                                const SizedBox(height: 14),
                                Text(
                                  'Next alarm: '
                                  '${nextAlarm.hour.toString().padLeft(2, '0')}:'
                                  '${nextAlarm.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: dateColor,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    if (_systemError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _systemError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: CupertinoColors.systemRed,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _NightstandToggle(
                            label: 'Red mode',
                            value: widget.controller.nightstandRedMode,
                            onChanged: widget.controller.setNightstandRedMode,
                          ),
                          _NightstandToggle(
                            label: 'Seconds',
                            value: widget.controller.nightstandShowSeconds,
                            onChanged:
                                widget.controller.setNightstandShowSeconds,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Color.fromARGB(
                      (_dimming * 255).round(),
                      0,
                      0,
                      0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NightstandToggle extends StatelessWidget {
  const _NightstandToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: CupertinoColors.systemGrey,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 6),
        CupertinoSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}
