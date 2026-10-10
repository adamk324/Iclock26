import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/cupertino.dart';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  // Stopwatch keeps elapsed time monotonic; the timer only schedules display updates.
  final Stopwatch _stopwatch = Stopwatch();
  final ValueNotifier<int> _elapsedMicroseconds = ValueNotifier<int>(0);
  final List<_Lap> _laps = <_Lap>[];

  Timer? _ticker;
  int _lastLapElapsedMicroseconds = 0;

  bool get _isRunning => _stopwatch.isRunning;

  @override
  void dispose() {
    _ticker?.cancel();
    _elapsedMicroseconds.dispose();
    super.dispose();
  }

  void _startStopwatch() {
    _stopwatch.start();
    // Publish elapsed time independently so the lap list stays idle between actions.
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _elapsedMicroseconds.value = _stopwatch.elapsedMicroseconds;
    });
    setState(() {});
  }

  void _stopStopwatch() {
    _stopwatch.stop();
    _ticker?.cancel();
    _ticker = null;
    _elapsedMicroseconds.value = _stopwatch.elapsedMicroseconds;
    setState(() {});
  }

  void _recordLap() {
    final int elapsed = _stopwatch.elapsedMicroseconds;
    setState(() {
      // Compare split durations, not cumulative elapsed times, to rank each lap.
      _laps.add(
        _Lap(
          number: _laps.length + 1,
          durationMicroseconds: elapsed - _lastLapElapsedMicroseconds,
        ),
      );
      _lastLapElapsedMicroseconds = elapsed;
    });
  }

  void _resetStopwatch() {
    _stopwatch.reset();
    _elapsedMicroseconds.value = 0;
    setState(() {
      _laps.clear();
      _lastLapElapsedMicroseconds = 0;
    });
  }

  void _handleSecondaryAction() {
    if (_isRunning) {
      _recordLap();
    } else {
      _resetStopwatch();
    }
  }

  String _formatTime(int microseconds) {
    // Truncate to hundredths to match the Clock app's displayed precision.
    final int centiseconds = microseconds ~/ Duration.microsecondsPerMillisecond ~/ 10;
    final int minutes = centiseconds ~/ 6000;
    final int seconds = (centiseconds ~/ 100) % 60;
    final int hundredths = centiseconds % 100;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${hundredths.toString().padLeft(2, '0')}';
  }

  int? get _fastestLapIndex {
    if (_laps.isEmpty) return null;
    var fastestIndex = 0;
    for (var index = 1; index < _laps.length; index++) {
      if (_laps[index].durationMicroseconds <
          _laps[fastestIndex].durationMicroseconds) {
        fastestIndex = index;
      }
    }
    return fastestIndex;
  }

  int? get _slowestLapIndex {
    if (_laps.isEmpty) return null;
    var slowestIndex = 0;
    for (var index = 1; index < _laps.length; index++) {
      if (_laps[index].durationMicroseconds >
          _laps[slowestIndex].durationMicroseconds) {
        slowestIndex = index;
      }
    }
    return slowestIndex;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Stopwatch'),
        backgroundColor: CupertinoColors.black,
        border: null,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _elapsedMicroseconds,
                    builder: (context, elapsed, child) => Text(
                      _formatTime(elapsed),
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontFamily: 'Menlo',
                        fontSize: 64,
                        fontFeatures: [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StopwatchButton(
                    label: _isRunning ? 'Lap' : 'Reset',
                    color: const Color(0xFF333336),
                    foregroundColor: CupertinoColors.white,
                    onPressed: _handleSecondaryAction,
                  ),
                  _StopwatchButton(
                    label: _isRunning ? 'Stop' : 'Start',
                    color: _isRunning
                        ? const Color(0xFF3A1717)
                        : const Color(0xFF173A20),
                    foregroundColor: _isRunning
                        ? CupertinoColors.systemRed
                        : CupertinoColors.systemGreen,
                    onPressed: _isRunning ? _stopStopwatch : _startStopwatch,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Container(height: 1, color: const Color(0xFF38383A)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Laps',
                    style: TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${_laps.length}',
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _laps.isEmpty
                  ? const Center(
                      child: Text(
                        'No laps yet',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _laps.length,
                      separatorBuilder: (context, index) => Container(
                        height: 1,
                        color: const Color(0xFF38383A),
                      ),
                      itemBuilder: (context, index) {
                        final int lapIndex = _laps.length - index - 1;
                        final _Lap lap = _laps[lapIndex];
                        final bool isFastest = lapIndex == _fastestLapIndex;
                        final bool isSlowest = lapIndex == _slowestLapIndex;
                        final Color lapColor = isFastest
                            ? CupertinoColors.systemGreen
                            : isSlowest
                                ? CupertinoColors.systemRed
                                : CupertinoColors.white;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Lap ${lap.number}',
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                children: [
                                  if (isFastest)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Text(
                                        'Fastest',
                                        style: const TextStyle(
                                          color: CupertinoColors.systemGreen,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  if (isSlowest)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Text(
                                        'Slowest',
                                        style: const TextStyle(
                                          color: CupertinoColors.systemRed,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    _formatTime(lap.durationMicroseconds),
                                    style: TextStyle(
                                      color: lapColor,
                                      fontFamily: 'Menlo',
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Lap {
  const _Lap({
    required this.number,
    required this.durationMicroseconds,
  });

  final int number;
  final int durationMicroseconds;
}

class _StopwatchButton extends StatelessWidget {
  const _StopwatchButton({
    required this.label,
    required this.color,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(42),
      color: color,
      child: SizedBox(
        width: 84,
        height: 84,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 16,
            ),
          ),
        ),
      ), minimumSize: Size(84, 84),
    );
  }
}
