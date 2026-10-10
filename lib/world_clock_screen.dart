import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class WorldClockScreen extends StatefulWidget {
  const WorldClockScreen({super.key});

  @override
  State<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends State<WorldClockScreen> {
  static const String _storageKey = 'worldClockCities';

  final ValueNotifier<DateTime> _now = ValueNotifier<DateTime>(DateTime.now());
  final List<_ClockCity> _cities = [];
  Timer? _ticker;
  bool _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _now.value = DateTime.now(),
    );
    unawaited(_loadCities());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _now.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final List<String> stored = preferences.getStringList(_storageKey) ?? [];
      final List<_ClockCity> loaded = stored
          .map((entry) => _ClockCity.fromJson(
                jsonDecode(entry) as Map<String, dynamic>,
              ))
          .toList();
      if (!mounted) return;
      setState(() {
        _cities
          ..clear()
          ..addAll(loaded);
        _loaded = true;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load saved cities: $error';
        _loaded = true;
      });
    }
  }

  Future<void> _saveCities() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final bool saved = await preferences.setStringList(
      _storageKey,
      _cities.map((city) => jsonEncode(city.toJson())).toList(),
    );
    if (!saved) throw StateError('Could not save the world clock cities.');
  }

  Future<void> _addCity() async {
    final _ClockCity? city = await Navigator.of(context).push<_ClockCity>(
      CupertinoPageRoute<_ClockCity>(
        builder: (context) => const _CitySearchScreen(),
      ),
    );
    if (city == null || !mounted) return;
    if (_cities.any(
      (existing) => existing.name.toLowerCase() == city.name.toLowerCase(),
    )) {
      await _showMessage('City already added', '${city.name} is on the list.');
      return;
    }
    setState(() => _cities.add(city));
    try {
      await _saveCities();
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _cities.remove(city));
      await _showMessage('Could not save city', '$error');
    }
  }

  Future<void> _removeCity(_ClockCity city) async {
    final int index = _cities.indexOf(city);
    if (index < 0) return;
    setState(() => _cities.removeAt(index));
    try {
      await _saveCities();
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _cities.insert(index, city));
      await _showMessage('Could not save city list', '$error');
    }
  }

  Future<void> _showMessage(String title, String message) {
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('World Clock'),
        backgroundColor: CupertinoColors.black,
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(32, 32),
          onPressed: _addCity,
          child: const Icon(CupertinoIcons.add, size: 25),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: CupertinoColors.systemRed),
                  ),
                ),
              )
            : !_loaded
                ? const Center(child: CupertinoActivityIndicator())
                : _cities.isEmpty
                    ? const Center(
                        child: Text(
                          'Add a city to see its local time.',
                          style: TextStyle(color: CupertinoColors.systemGrey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: _cities.length,
                        itemBuilder: (context, index) {
                          final _ClockCity city = _cities[index];
                          return Dismissible(
                            key: ValueKey(city.name),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => _removeCity(city),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              color: CupertinoColors.systemRed,
                              child: const Icon(
                                CupertinoIcons.delete,
                                color: CupertinoColors.white,
                              ),
                            ),
                            child: _CityRow(city: city, now: _now),
                          );
                        },
                      ),
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({required this.city, required this.now});

  final _ClockCity city;
  final ValueListenable<DateTime> now;

  @override
  Widget build(BuildContext context) {
    final tz.TZDateTime localNow = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime cityNow = tz.TZDateTime.now(
      tz.getLocation(city.timeZone),
    );
    final String relativeDate = _relativeDate(cityNow, localNow);
    final String difference = _formatOffset(
      cityNow.timeZoneOffset - localNow.timeZoneOffset,
    );

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF38383A))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city.name,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$relativeDate, $difference',
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<DateTime>(
            valueListenable: now,
            builder: (context, now, child) {
              final tz.TZDateTime time = tz.TZDateTime.from(
                now,
                tz.getLocation(city.timeZone),
              );
              final String hour =
                  (time.hour % 12 == 0 ? 12 : time.hour % 12).toString();
              final String minute = time.minute.toString().padLeft(2, '0');
              final String second = time.second.toString().padLeft(2, '0');
              return Text(
                '$hour:$minute:$second ${time.hour < 12 ? 'AM' : 'PM'}',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 31,
                  fontFeatures: [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w200,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

String _relativeDate(DateTime city, DateTime local) {
  final DateTime cityDate = DateTime.utc(city.year, city.month, city.day);
  final DateTime localDate = DateTime.utc(local.year, local.month, local.day);
  final int difference = cityDate.difference(localDate).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Tomorrow';
  if (difference == -1) return 'Yesterday';
  return difference > 0 ? 'In $difference days' : '${-difference} days ago';
}

String _formatOffset(Duration offset) {
  final int minutes = offset.inMinutes;
  if (minutes == 0) return 'Same time';
  final String sign = minutes > 0 ? '+' : '-';
  final int absoluteMinutes = minutes.abs();
  final int hours = absoluteMinutes ~/ 60;
  final int remainingMinutes = absoluteMinutes % 60;
  return remainingMinutes == 0
      ? '$sign${hours}h'
      : '$sign${hours}h ${remainingMinutes}m';
}

class _ClockCity {
  const _ClockCity({required this.name, required this.timeZone});

  final String name;
  final String timeZone;

  factory _ClockCity.fromJson(Map<String, dynamic> json) {
    return _ClockCity(
      name: json['name'] as String,
      timeZone: json['timeZone'] as String,
    );
  }

  Map<String, String> toJson() => {'name': name, 'timeZone': timeZone};
}

class _CitySearchScreen extends StatefulWidget {
  const _CitySearchScreen();

  @override
  State<_CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<_CitySearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final List<_ClockCity> matches = _majorCities
        .where((city) => city.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Add City'),
        previousPageTitle: 'World Clock',
        backgroundColor: CupertinoColors.black,
        border: null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: CupertinoSearchTextField(
                placeholder: 'Search cities',
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final _ClockCity city = matches[index];
                  return CupertinoListTile(
                    title: Text(city.name),
                    additionalInfo: Text(
                      city.timeZone,
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 11,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(city),
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

const List<_ClockCity> _majorCities = [
  _ClockCity(name: 'New York', timeZone: 'America/New_York'),
  _ClockCity(name: 'Los Angeles', timeZone: 'America/Los_Angeles'),
  _ClockCity(name: 'Chicago', timeZone: 'America/Chicago'),
  _ClockCity(name: 'Denver', timeZone: 'America/Denver'),
  _ClockCity(name: 'Phoenix', timeZone: 'America/Phoenix'),
  _ClockCity(name: 'Anchorage', timeZone: 'America/Anchorage'),
  _ClockCity(name: 'Honolulu', timeZone: 'Pacific/Honolulu'),
  _ClockCity(name: 'Toronto', timeZone: 'America/Toronto'),
  _ClockCity(name: 'Vancouver', timeZone: 'America/Vancouver'),
  _ClockCity(name: 'Mexico City', timeZone: 'America/Mexico_City'),
  _ClockCity(name: 'Sao Paulo', timeZone: 'America/Sao_Paulo'),
  _ClockCity(name: 'Buenos Aires', timeZone: 'America/Argentina/Buenos_Aires'),
  _ClockCity(name: 'Santiago', timeZone: 'America/Santiago'),
  _ClockCity(name: 'Bogota', timeZone: 'America/Bogota'),
  _ClockCity(name: 'Lima', timeZone: 'America/Lima'),
  _ClockCity(name: 'Reykjavik', timeZone: 'Atlantic/Reykjavik'),
  _ClockCity(name: 'London', timeZone: 'Europe/London'),
  _ClockCity(name: 'Dublin', timeZone: 'Europe/Dublin'),
  _ClockCity(name: 'Lisbon', timeZone: 'Europe/Lisbon'),
  _ClockCity(name: 'Paris', timeZone: 'Europe/Paris'),
  _ClockCity(name: 'Madrid', timeZone: 'Europe/Madrid'),
  _ClockCity(name: 'Amsterdam', timeZone: 'Europe/Amsterdam'),
  _ClockCity(name: 'Brussels', timeZone: 'Europe/Brussels'),
  _ClockCity(name: 'Berlin', timeZone: 'Europe/Berlin'),
  _ClockCity(name: 'Rome', timeZone: 'Europe/Rome'),
  _ClockCity(name: 'Zurich', timeZone: 'Europe/Zurich'),
  _ClockCity(name: 'Vienna', timeZone: 'Europe/Vienna'),
  _ClockCity(name: 'Prague', timeZone: 'Europe/Prague'),
  _ClockCity(name: 'Warsaw', timeZone: 'Europe/Warsaw'),
  _ClockCity(name: 'Budapest', timeZone: 'Europe/Budapest'),
  _ClockCity(name: 'Athens', timeZone: 'Europe/Athens'),
  _ClockCity(name: 'Istanbul', timeZone: 'Europe/Istanbul'),
  _ClockCity(name: 'Moscow', timeZone: 'Europe/Moscow'),
  _ClockCity(name: 'Helsinki', timeZone: 'Europe/Helsinki'),
  _ClockCity(name: 'Stockholm', timeZone: 'Europe/Stockholm'),
  _ClockCity(name: 'Oslo', timeZone: 'Europe/Oslo'),
  _ClockCity(name: 'Copenhagen', timeZone: 'Europe/Copenhagen'),
  _ClockCity(name: 'Kyiv', timeZone: 'Europe/Kyiv'),
  _ClockCity(name: 'Cairo', timeZone: 'Africa/Cairo'),
  _ClockCity(name: 'Johannesburg', timeZone: 'Africa/Johannesburg'),
  _ClockCity(name: 'Nairobi', timeZone: 'Africa/Nairobi'),
  _ClockCity(name: 'Lagos', timeZone: 'Africa/Lagos'),
  _ClockCity(name: 'Casablanca', timeZone: 'Africa/Casablanca'),
  _ClockCity(name: 'Dubai', timeZone: 'Asia/Dubai'),
  _ClockCity(name: 'Riyadh', timeZone: 'Asia/Riyadh'),
  _ClockCity(name: 'Tehran', timeZone: 'Asia/Tehran'),
  _ClockCity(name: 'Karachi', timeZone: 'Asia/Karachi'),
  _ClockCity(name: 'Mumbai', timeZone: 'Asia/Kolkata'),
  _ClockCity(name: 'Delhi', timeZone: 'Asia/Kolkata'),
  _ClockCity(name: 'Dhaka', timeZone: 'Asia/Dhaka'),
  _ClockCity(name: 'Bangkok', timeZone: 'Asia/Bangkok'),
  _ClockCity(name: 'Jakarta', timeZone: 'Asia/Jakarta'),
  _ClockCity(name: 'Singapore', timeZone: 'Asia/Singapore'),
  _ClockCity(name: 'Kuala Lumpur', timeZone: 'Asia/Kuala_Lumpur'),
  _ClockCity(name: 'Manila', timeZone: 'Asia/Manila'),
  _ClockCity(name: 'Hong Kong', timeZone: 'Asia/Hong_Kong'),
  _ClockCity(name: 'Shanghai', timeZone: 'Asia/Shanghai'),
  _ClockCity(name: 'Beijing', timeZone: 'Asia/Shanghai'),
  _ClockCity(name: 'Seoul', timeZone: 'Asia/Seoul'),
  _ClockCity(name: 'Tokyo', timeZone: 'Asia/Tokyo'),
  _ClockCity(name: 'Taipei', timeZone: 'Asia/Taipei'),
  _ClockCity(name: 'Perth', timeZone: 'Australia/Perth'),
  _ClockCity(name: 'Adelaide', timeZone: 'Australia/Adelaide'),
  _ClockCity(name: 'Sydney', timeZone: 'Australia/Sydney'),
  _ClockCity(name: 'Melbourne', timeZone: 'Australia/Melbourne'),
  _ClockCity(name: 'Auckland', timeZone: 'Pacific/Auckland'),
];
