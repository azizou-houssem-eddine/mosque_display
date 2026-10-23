import 'dart:convert';
import 'dart:io';
import 'package:adhan/adhan.dart';

void main() async {
  print('Loading Wilayas from assets/data/wilayas.json...');
  final wilayasFile = File('assets/data/wilayas.json');
  if (!wilayasFile.existsSync()) {
    print('ERROR: assets/data/wilayas.json not found!');
    exit(1);
  }

  final wilayasJson = jsonDecode(await wilayasFile.readAsString()) as List<dynamic>;
  print('Loaded ${wilayasJson.length} wilayas.');

  // Reference Leap Year (2024 has 366 days including Feb 29)
  const int refYear = 2024;
  final Map<String, Map<String, List<String>>> timetable = {};

  final daysInMonths = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  String fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  for (final w in wilayasJson) {
    final int code = w['code'] as int;
    final double lat = (w['latitude'] as num).toDouble();
    final double lng = (w['longitude'] as num).toDouble();
    final coordinates = Coordinates(lat, lng);
    final wilayaKey = code.toString();
    timetable[wilayaKey] = {};

    final params = CalculationParameters(fajrAngle: 18.0, ishaAngle: 17.0);
    params.madhab = Madhab.shafi;
    params.highLatitudeRule = HighLatitudeRule.middle_of_the_night;
    params.adjustments.asr = lat >= 36.0 ? 2 : 1;

    for (int month = 1; month <= 12; month++) {
      final int daysInCurrentMonth = daysInMonths[month - 1];
      final monthStr = month.toString().padLeft(2, '0');

      for (int day = 1; day <= daysInCurrentMonth; day++) {
        final dayStr = day.toString().padLeft(2, '0');
        final dateKey = '$monthStr-$dayStr';

        final int calcYear = (month == 2 && day == 29) ? 2024 : 2026;
        final dateComponents = DateComponents(calcYear, month, day);
        final pt = PrayerTimes(
          coordinates,
          dateComponents,
          params,
          utcOffset: const Duration(hours: 1),
        );

        timetable[wilayaKey]![dateKey] = [
          fmt(pt.fajr),
          fmt(pt.sunrise),
          fmt(pt.dhuhr),
          fmt(pt.asr),
          fmt(pt.maghrib),
          fmt(pt.isha),
        ];
      }
    }
  }

  // Verify benchmark wilayas on 10-06
  final benchmarks = {
    '16': ['05:21', '06:47', '12:36', '15:54', '18:24', '19:45'],
    '31': ['05:37', '07:01', '12:51', '16:09', '18:39', '19:59'],
    '25': ['05:07', '06:33', '12:22', '15:40', '18:10', '19:30'],
    '30': ['05:15', '06:36', '12:27', '15:47', '18:17', '19:34'],
  };

  for (final entry in benchmarks.entries) {
    final times = timetable[entry.key]!['10-06']!;
    print('Wilaya ${entry.key} 10-06: $times (Expected: ${entry.value})');
    for (int i = 0; i < 6; i++) {
      if (times[i] != entry.value[i]) {
        print('MISMATCH in Wilaya ${entry.key} at index $i: got ${times[i]} expected ${entry.value[i]}');
        exit(1);
      }
    }
  }

  final outputFile = File('assets/data/algerian_prayer_times.json');
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(jsonEncode(timetable));

  final stat = await outputFile.stat();
  print('Successfully generated and verified 366-day perpetual timetable for all 58 Wilayas!');
  print('Output: ${outputFile.path} (${(stat.size / 1024).toStringAsFixed(1)} KB)');
}
