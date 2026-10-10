import 'package:flutter/cupertino.dart';

import 'alarm_service.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({
    required this.service,
    super.key,
  });

  final AlarmService service;

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  late List<ClockAlarm> _alarms = widget.service.alarms;
  String? _error;

  Future<void> _addAlarm() async {
    final _AlarmDraft? draft = await showCupertinoModalPopup<_AlarmDraft>(
      context: context,
      builder: (context) => const _AlarmEditorSheet(),
    );
    if (draft == null || !mounted) return;

    try {
      await widget.service.createAlarm(
        hour: draft.time.hour,
        minute: draft.time.minute,
        label: draft.label.trim(),
        weekdays: draft.weekdays,
      );
      if (!mounted) return;
      setState(() {
        _alarms = widget.service.alarms;
        _error = null;
      });
    } on AlarmPermissionDenied {
      await _showAlert(
        'Notifications are off',
        'Allow notifications in Settings to create an alarm.',
      );
    } on Exception catch (error) {
      await _showAlert('Could not create alarm', '$error');
    }
  }

  Future<void> _setEnabled(ClockAlarm alarm, bool enabled) async {
    try {
      await widget.service.setEnabled(alarm, enabled);
      if (!mounted) return;
      setState(() {
        _alarms = widget.service.alarms;
        _error = null;
      });
    } on AlarmPermissionDenied {
      await _showAlert(
        'Notifications are off',
        'Allow notifications in Settings to enable this alarm.',
      );
    } on Exception catch (error) {
      await _showAlert('Could not update alarm', '$error');
    }
  }

  Future<void> _deleteAlarm(ClockAlarm alarm) async {
    try {
      await widget.service.deleteAlarm(alarm);
      if (!mounted) return;
      setState(() {
        _alarms = widget.service.alarms;
        _error = null;
      });
    } on Exception catch (error) {
      await _showAlert('Could not delete alarm', '$error');
    }
  }

  Future<void> _showAlert(String title, String message) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatTime(ClockAlarm alarm) {
    final int displayHour = alarm.hour % 12 == 0 ? 12 : alarm.hour % 12;
    return '$displayHour:${alarm.minute.toString().padLeft(2, '0')} '
        '${alarm.hour < 12 ? 'AM' : 'PM'}';
  }

  String _repeatLabel(ClockAlarm alarm) {
    if (alarm.weekdays.isEmpty) return 'Never';
    if (alarm.weekdays.length == 7) return 'Every day';
    return alarm.weekdays.map((day) => _weekdays[day - 1]).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final List<ClockAlarm> alarms = [..._alarms]..sort((first, second) {
        final int hourOrder = first.hour.compareTo(second.hour);
        return hourOrder == 0
            ? first.minute.compareTo(second.minute)
            : hourOrder;
      });

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Alarm'),
        backgroundColor: CupertinoColors.black,
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(32, 32),
          onPressed: _addAlarm,
          child: const Icon(CupertinoIcons.add, size: 25),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _error!,
                  style: const TextStyle(color: CupertinoColors.systemRed),
                ),
              ),
            if (alarms.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64, horizontal: 24),
                child: Center(
                  child: Text(
                    'No alarms',
                    style: TextStyle(color: CupertinoColors.systemGrey),
                  ),
                ),
              ),
            for (final ClockAlarm alarm in alarms)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 13, 16, 13),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF38383A)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onLongPress: () => _deleteAlarm(alarm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatTime(alarm),
                              style: TextStyle(
                                color: alarm.enabled
                                    ? CupertinoColors.white
                                    : CupertinoColors.systemGrey,
                                fontSize: 38,
                                fontWeight: FontWeight.w200,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              alarm.label.isEmpty ? 'Alarm' : alarm.label,
                              style: const TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _repeatLabel(alarm),
                              style: const TextStyle(
                                color: CupertinoColors.systemGrey2,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    CupertinoSwitch(
                      value: alarm.enabled,
                      onChanged: (value) => _setEnabled(alarm, value),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.only(left: 8),
                      minimumSize: const Size(32, 32),
                      onPressed: () => _deleteAlarm(alarm),
                      child: const Icon(
                        CupertinoIcons.delete,
                        color: CupertinoColors.systemGrey,
                        size: 19,
                      ),
                    ),
                  ],
                ),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'Alarms use notifications, so they may not ring in silent mode '
                'or Do Not Disturb.',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlarmDraft {
  const _AlarmDraft({
    required this.time,
    required this.label,
    required this.weekdays,
  });

  final DateTime time;
  final String label;
  final List<int> weekdays;
}

class _AlarmEditorSheet extends StatefulWidget {
  const _AlarmEditorSheet();

  @override
  State<_AlarmEditorSheet> createState() => _AlarmEditorSheetState();
}

class _AlarmEditorSheetState extends State<_AlarmEditorSheet> {
  late DateTime _time = DateTime.now();
  final TextEditingController _label = TextEditingController();
  final Set<int> _repeatDays = {};

  static const List<String> _weekdays = [
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(
      _AlarmDraft(
        time: _time,
        label: _label.text,
        weekdays: _repeatDays.toList()..sort(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double sheetHeight = MediaQuery.sizeOf(context).height * 0.88;
    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Text(
                    'Add Alarm',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: 190,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        use24hFormat: false,
                        initialDateTime: _time,
                        onDateTimeChanged: (value) =>
                            setState(() => _time = value),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: CupertinoTextField(
                        controller: _label,
                        placeholder: 'Label',
                        clearButtonMode: OverlayVisibilityMode.editing,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Repeat',
                            style: TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (var index = 0;
                                  index < _weekdays.length;
                                  index++)
                                _WeekdayButton(
                                  label: _weekdays[index],
                                  selected: _repeatDays.contains(index + 1),
                                  onPressed: () {
                                    setState(() {
                                      if (!_repeatDays.add(index + 1)) {
                                        _repeatDays.remove(index + 1);
                                      }
                                    });
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayButton extends StatelessWidget {
  const _WeekdayButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(34, 34),
      onPressed: onPressed,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              selected ? CupertinoColors.systemOrange : const Color(0xFF3A3A3C),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? CupertinoColors.black : CupertinoColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
