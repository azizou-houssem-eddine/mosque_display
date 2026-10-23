import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mosque_display/data/models/wilaya.dart';
import 'package:mosque_display/data/models/prayer_schedule.dart';
import 'package:mosque_display/data/models/prayer_offsets.dart';
import 'package:mosque_display/domain/calculation/algerian_prayer_calculator.dart';
import 'package:mosque_display/domain/calculation/hijri_calculator.dart';
import 'package:mosque_display/data/datasources/bundled_timetable_datasource.dart';
import 'package:mosque_display/data/repositories/prayer_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Challenger M1: Extreme Geographical Coordinates Stress Tests', () {
    // Extreme Wilayas in Algerian territory
    final inGuezzam = algerianWilayas.firstWhere((w) => w.code == 54); // Extreme South (19.57°N, 5.77°E)
    final skikda = algerianWilayas.firstWhere((w) => w.code == 21);    // Extreme North (36.88°N, 6.91°E)
    final annaba = algerianWilayas.firstWhere((w) => w.code == 23);    // Far North Coast (36.90°N, 7.77°E)
    final tindouf = algerianWilayas.firstWhere((w) => w.code == 37);   // Extreme West (-8.15°W, 27.67°N)
    final djanet = algerianWilayas.firstWhere((w) => w.code == 56);    // Extreme East (9.49°E, 24.55°N)
    final bordjBadji = algerianWilayas.firstWhere((w) => w.code == 50);// Extreme South-West (21.33°N, 0.95°E)

    final extremeWilayas = [inGuezzam, skikda, annaba, tindouf, djanet, bordjBadji];

    // Key seasonal dates
    final seasonalDates = [
      DateTime(2026, 6, 21), // Summer Solstice (longest day)
      DateTime(2026, 12, 21),// Winter Solstice (shortest day)
      DateTime(2026, 3, 20), // Spring Equinox
      DateTime(2026, 9, 22), // Autumn Equinox
      DateTime(2027, 6, 21), // Future Summer Solstice
      DateTime(2027, 12, 21),// Future Winter Solstice
    ];

    test('All extreme geographical points compute valid chronological schedules across all seasons', () {
      for (final wilaya in extremeWilayas) {
        for (final date in seasonalDates) {
          final s = AlgerianPrayerCalculator.calculateForWilaya(
            wilaya: wilaya,
            date: date,
          );

          // 1. Strict chronological ordering
          expect(s.fajr.isBefore(s.sunrise), isTrue,
              reason: 'Fajr must precede Sunrise for ${wilaya.nameFr} on $date');
          expect(s.sunrise.isBefore(s.dhuhr), isTrue,
              reason: 'Sunrise must precede Dhuhr for ${wilaya.nameFr} on $date');
          expect(s.dhuhr.isBefore(s.asr), isTrue,
              reason: 'Dhuhr must precede Asr for ${wilaya.nameFr} on $date');
          expect(s.asr.isBefore(s.maghrib), isTrue,
              reason: 'Asr must precede Maghrib for ${wilaya.nameFr} on $date');
          expect(s.maghrib.isBefore(s.isha), isTrue,
              reason: 'Maghrib must precede Isha for ${wilaya.nameFr} on $date');

          // 2. Minimum astronomical intervals in Algeria
          expect(s.sunrise.difference(s.fajr).inMinutes, greaterThanOrEqualTo(60),
              reason: 'Fajr-to-Sunrise duration >= 60m in ${wilaya.nameFr}');
          expect(s.dhuhr.difference(s.sunrise).inMinutes, greaterThanOrEqualTo(240),
              reason: 'Sunrise-to-Dhuhr duration >= 4h in ${wilaya.nameFr}');
          expect(s.asr.difference(s.dhuhr).inMinutes, greaterThanOrEqualTo(120),
              reason: 'Dhuhr-to-Asr duration >= 2h in ${wilaya.nameFr}');
          expect(s.maghrib.difference(s.asr).inMinutes, greaterThanOrEqualTo(90),
              reason: 'Asr-to-Maghrib duration >= 1.5h in ${wilaya.nameFr}');
          expect(s.isha.difference(s.maghrib).inMinutes, greaterThanOrEqualTo(60),
              reason: 'Maghrib-to-Isha duration >= 60m in ${wilaya.nameFr}');

          // 3. Solar noon (Dhuhr) occurs within Algerian daytime window [12:00, 13:30]
          expect(s.dhuhr.hour, inInclusiveRange(12, 13),
              reason: 'Dhuhr hour must be 12 or 13 in ${wilaya.nameFr} (UTC+1)');
        }
      }
    });

    test('East-West solar time lag between Djanet (East) and Tindouf (West) is 65-75 minutes', () {
      for (final date in seasonalDates) {
        final djanetSchedule = AlgerianPrayerCalculator.calculateForWilaya(wilaya: djanet, date: date);
        final tindoufSchedule = AlgerianPrayerCalculator.calculateForWilaya(wilaya: tindouf, date: date);

        // Djanet (9.49°E) is strictly east of Tindouf (-8.15°W), delta ≈ 17.64°
        // 17.64° * 4 min/deg ≈ 70.5 minutes
        final dhuhrLagMinutes = tindoufSchedule.dhuhr.difference(djanetSchedule.dhuhr).inMinutes;
        expect(dhuhrLagMinutes, inInclusiveRange(65, 75),
            reason: 'Solar lag between Djanet and Tindouf on $date must be ~70m');

        final maghribLagMinutes = tindoufSchedule.maghrib.difference(djanetSchedule.maghrib).inMinutes;
        expect(maghribLagMinutes, inInclusiveRange(55, 85),
            reason: 'Maghrib lag between Djanet and Tindouf on $date must be realistic');
      }
    });
  });

  group('Challenger M1: Leap Year and Calendar Transition Stress Tests', () {
    test('Calculates flawlessly on Leap Day 2024-02-29 and 2028-02-29 for all 58 Wilayas', () {
      final leapDays = [
        DateTime(2024, 2, 29),
        DateTime(2028, 2, 29),
      ];

      for (final leapDay in leapDays) {
        for (final wilaya in algerianWilayas) {
          final s = AlgerianPrayerCalculator.calculateForWilaya(
            wilaya: wilaya,
            date: leapDay,
          );

          expect(s.fajr.day, equals(29));
          expect(s.fajr.month, equals(2));
          expect(s.fajr.year, equals(leapDay.year));

          expect(s.fajr.isBefore(s.sunrise), isTrue);
          expect(s.sunrise.isBefore(s.dhuhr), isTrue);
          expect(s.dhuhr.isBefore(s.asr), isTrue);
          expect(s.asr.isBefore(s.maghrib), isTrue);
          expect(s.maghrib.isBefore(s.isha), isTrue);
        }
      }
    });

    test('Non-leap February 28 to March 1 transitions smoothly without date jumps', () {
      final feb28 = DateTime(2026, 2, 28);
      final mar01 = DateTime(2026, 3, 1);
      final alger = algerianWilayas.firstWhere((w) => w.code == 16);

      final sFeb = AlgerianPrayerCalculator.calculateForWilaya(wilaya: alger, date: feb28);
      final sMar = AlgerianPrayerCalculator.calculateForWilaya(wilaya: alger, date: mar01);

      expect(sFeb.fajr.day, equals(28));
      expect(sMar.fajr.day, equals(1));

      // 1 day apart, difference between consecutive Fajr times should be within 2 minutes
      final fajrDiff = sMar.fajr.difference(sFeb.fajr).inMinutes - (24 * 60);
      expect(fajrDiff.abs(), lessThanOrEqualTo(2));
    });

    test('Year boundary transition (Dec 31 23:55 to Jan 1 00:05) handles countdowns accurately', () {
      final dec31 = DateTime(2026, 12, 31);
      final alger = algerianWilayas.firstWhere((w) => w.code == 16);
      final sDec31 = AlgerianPrayerCalculator.calculateForWilaya(wilaya: alger, date: dec31);

      // Current time is late night on Dec 31
      final nowAtNight = DateTime(2026, 12, 31, 23, 50);

      // getNextPrayer should return Fajr (of next year, Jan 1)
      expect(sDec31.getNextPrayer(nowAtNight), equals(Prayer.fajr));

      // getTimeRemainingToNextPrayer should compute duration to tomorrow's Fajr
      final remaining = sDec31.getTimeRemainingToNextPrayer(nowAtNight);
      expect(remaining.isNegative, isFalse);
      expect(remaining.inHours, inInclusiveRange(5, 7)); // Fajr in winter is ~06:00
    });

    test('BundledTimetableDataSource loads Leap Day 02-29 for all 58 Wilayas', () async {
      final file = File('assets/data/algerian_prayer_times.json');
      expect(file.existsSync(), isTrue, reason: 'algerian_prayer_times.json must exist');

      final jsonContent = await file.readAsString();
      final data = json.decode(jsonContent) as Map<String, dynamic>;

      final leapDate = DateTime(2028, 2, 29);
      final dataSource = BundledTimetableDataSource(initialCache: data);

      for (int code = 1; code <= 58; code++) {
        final schedule = await dataSource.getPrayerSchedule(code, leapDate);
        expect(schedule, isNotNull, reason: 'Wilaya $code must have 02-29 timetable');
        expect(schedule!.fajr.month, equals(2));
        expect(schedule.fajr.day, equals(29));
        expect(schedule.fajr.year, equals(2028));

        expect(schedule.fajr.isBefore(schedule.sunrise), isTrue);
        expect(schedule.sunrise.isBefore(schedule.dhuhr), isTrue);
        expect(schedule.dhuhr.isBefore(schedule.asr), isTrue);
        expect(schedule.asr.isBefore(schedule.maghrib), isTrue);
        expect(schedule.maghrib.isBefore(schedule.isha), isTrue);
      }
    });
  });

  group('Challenger M1: Exhaustive 58-Wilaya Full-Year Chronological Invariant Stress Harness', () {
    test('Verifies strict chronological ordering across 24 sample dates for all 58 Wilayas (1,392 points)', () {
      // 1st and 15th of each month in 2026
      final sampleDates = <DateTime>[];
      for (int m = 1; m <= 12; m++) {
        sampleDates.add(DateTime(2026, m, 1));
        sampleDates.add(DateTime(2026, m, 15));
      }

      for (final wilaya in algerianWilayas) {
        for (final date in sampleDates) {
          final s = AlgerianPrayerCalculator.calculateForWilaya(
            wilaya: wilaya,
            date: date,
          );

          expect(s.fajr.isBefore(s.sunrise), isTrue,
              reason: 'Fajr < Sunrise failed for W${wilaya.code} on $date');
          expect(s.sunrise.isBefore(s.dhuhr), isTrue,
              reason: 'Sunrise < Dhuhr failed for W${wilaya.code} on $date');
          expect(s.dhuhr.isBefore(s.asr), isTrue,
              reason: 'Dhuhr < Asr failed for W${wilaya.code} on $date');
          expect(s.asr.isBefore(s.maghrib), isTrue,
              reason: 'Asr < Maghrib failed for W${wilaya.code} on $date');
          expect(s.maghrib.isBefore(s.isha), isTrue,
              reason: 'Maghrib < Isha failed for W${wilaya.code} on $date');
        }
      }
    });

    test('Verifies complete 366 days in bundled JSON asset across all 58 Wilayas (21,228 timetable entries)', () async {
      final file = File('assets/data/algerian_prayer_times.json');
      final jsonContent = await file.readAsString();
      final data = json.decode(jsonContent) as Map<String, dynamic>;

      expect(data.keys.length, equals(58), reason: 'Must contain exactly 58 Wilaya entries');

      final daysInMonths = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]; // 366 days

      for (int code = 1; code <= 58; code++) {
        final wilayaMap = data[code.toString()] as Map<String, dynamic>?;
        expect(wilayaMap, isNotNull, reason: 'Wilaya $code missing from timetable');
        expect(wilayaMap!.keys.length, equals(366),
            reason: 'Wilaya $code must have exactly 366 days');

        // Check chronological invariant for every single day
        for (int m = 1; m <= 12; m++) {
          for (int d = 1; d <= daysInMonths[m - 1]; d++) {
            final key = '${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
            final times = wilayaMap[key] as List<dynamic>?;
            expect(times, isNotNull, reason: 'Missing day $key in W$code');
            expect(times!.length, equals(6), reason: 'Day $key in W$code must have 6 prayer times');

            // Parse and check chronological ordering
            final parsedMinutes = times.map((t) {
              final parts = t.toString().split(':');
              return int.parse(parts[0]) * 60 + int.parse(parts[1]);
            }).toList();

            for (int i = 0; i < 5; i++) {
              expect(parsedMinutes[i] < parsedMinutes[i + 1], isTrue,
                  reason: 'Inverted times at index $i vs ${i + 1} for W$code on $key: $times');
            }
          }
        }
      }
    });
  });

  group('Challenger M1: Communal Offsets Boundary & Adverse Inversion Stress', () {
    final alger = algerianWilayas.firstWhere((w) => w.code == 16);
    final inGuezzam = algerianWilayas.firstWhere((w) => w.code == 54);
    final testDate = DateTime(2026, 6, 21); // Summer Solstice (short night, tightest prayer intervals)

    test('Adversarial divergent offsets (±15 min max compression) do not invert prayer order', () {
      for (final wilaya in [alger, inGuezzam]) {
        final base = AlgerianPrayerCalculator.calculateForWilaya(wilaya: wilaya, date: testDate);

        // Maximum adversarial compression:
        // Push Fajr later (+15), Sunrise earlier (-15) -> shrinks Fajr-Sunrise window by 30 min
        // Push Dhuhr later (+15), Asr earlier (-15) -> shrinks Dhuhr-Asr window by 30 min
        // Push Asr later (+15), Maghrib earlier (-15) -> shrinks Asr-Maghrib window by 30 min
        // Push Maghrib later (+15), Isha earlier (-15) -> shrinks Maghrib-Isha window by 30 min
        const adverseOffsets = PrayerOffsets(
          fajr: 15,
          sunrise: -15,
          dhuhr: 15,
          asr: -15,
          maghrib: 15,
          isha: -15,
        );

        final calibrated = base.applyOffsets(adverseOffsets);

        expect(calibrated.fajr.isBefore(calibrated.sunrise), isTrue,
            reason: 'Fajr must remain before Sunrise despite adverse ±15 min offsets');
        expect(calibrated.sunrise.isBefore(calibrated.dhuhr), isTrue,
            reason: 'Sunrise must remain before Dhuhr despite adverse ±15 min offsets');
        expect(calibrated.dhuhr.isBefore(calibrated.asr), isTrue,
            reason: 'Dhuhr must remain before Asr despite adverse ±15 min offsets');
        expect(calibrated.asr.isBefore(calibrated.maghrib), isTrue,
            reason: 'Asr must remain before Maghrib despite adverse ±15 min offsets');
        expect(calibrated.maghrib.isBefore(calibrated.isha), isTrue,
            reason: 'Maghrib must remain before Isha despite adverse ±15 min offsets');

        // Check that remaining Maghrib-Isha gap is still safe (>= 30 min)
        final maghribToIsha = calibrated.isha.difference(calibrated.maghrib).inMinutes;
        expect(maghribToIsha, greaterThanOrEqualTo(30),
            reason: 'Maghrib to Isha margin must remain >= 30m');
      }
    });

    test('Direct constructor assertions reject out-of-boundary offsets', () {
      expect(() => PrayerOffsets(fajr: 16), throwsA(isA<AssertionError>()));
      expect(() => PrayerOffsets(fajr: -16), throwsA(isA<AssertionError>()));
      expect(() => PrayerOffsets(sunrise: 20), throwsA(isA<AssertionError>()));
      expect(() => PrayerOffsets(dhuhr: -25), throwsA(isA<AssertionError>()));
      expect(() => PrayerOffsets(asr: 99), throwsA(isA<AssertionError>()));
      expect(() => PrayerOffsets(maghrib: -100), throwsA(isA<AssertionError>()));
      expect(() => PrayerOffsets(isha: 16), throwsA(isA<AssertionError>()));
    });

    test('fromJson defensively clamps out-of-boundary values without throwing', () {
      final jsonMap = {
        'fajr': 999,
        'sunrise': -500,
        'dhuhr': 16,
        'asr': -16,
        'maghrib': 42,
        'isha': -42,
      };

      final offsets = PrayerOffsets.fromJson(jsonMap);
      expect(offsets.fajr, equals(15));
      expect(offsets.sunrise, equals(-15));
      expect(offsets.dhuhr, equals(15));
      expect(offsets.asr, equals(-15));
      expect(offsets.maghrib, equals(15));
      expect(offsets.isha, equals(-15));
    });

    test('copyWith defensively clamps out-of-boundary values without throwing', () {
      const offsets = PrayerOffsets();
      final updated = offsets.copyWith(fajr: 50, isha: -50);
      expect(updated.fajr, equals(15));
      expect(updated.isha, equals(-15));
    });
  });

  group('Challenger M1: Geographic Dataset & Boundary Validation', () {
    test('All 58 Wilayas in wilayas.json strictly follow Algerian spatial boundaries', () async {
      final file = File('assets/data/wilayas.json');
      expect(file.existsSync(), isTrue);

      final jsonContent = await file.readAsString();
      final list = json.decode(jsonContent) as List<dynamic>;

      expect(list.length, equals(58));

      final seenCodes = <int>{};
      for (final item in list) {
        final w = Wilaya.fromJson(item as Map<String, dynamic>);

        expect(seenCodes.contains(w.code), isFalse, reason: 'Duplicate code ${w.code}');
        seenCodes.add(w.code);

        expect(w.code, inInclusiveRange(1, 58));
        expect(w.latitude, inInclusiveRange(18.0, 38.0),
            reason: 'Latitude out of bounds for ${w.nameFr}: ${w.latitude}');
        expect(w.longitude, inInclusiveRange(-9.0, 12.0),
            reason: 'Longitude out of bounds for ${w.nameFr}: ${w.longitude}');
        expect(w.nameAr.trim().isNotEmpty, isTrue);
        expect(w.nameFr.trim().isNotEmpty, isTrue);
      }

      expect(seenCodes.length, equals(58));
    });

    test('Wilaya constructor assertions reject invalid codes and coordinates', () {
      // Code out of range
      expect(
        () => Wilaya(code: 0, nameAr: 'A', nameFr: 'A', latitude: 36.0, longitude: 3.0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => Wilaya(code: 59, nameAr: 'A', nameFr: 'A', latitude: 36.0, longitude: 3.0),
        throwsA(isA<AssertionError>()),
      );
      // Latitude out of range
      expect(
        () => Wilaya(code: 16, nameAr: 'A', nameFr: 'A', latitude: 17.9, longitude: 3.0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => Wilaya(code: 16, nameAr: 'A', nameFr: 'A', latitude: 38.1, longitude: 3.0),
        throwsA(isA<AssertionError>()),
      );
      // Longitude out of range
      expect(
        () => Wilaya(code: 16, nameAr: 'A', nameFr: 'A', latitude: 36.0, longitude: -9.1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => Wilaya(code: 16, nameAr: 'A', nameFr: 'A', latitude: 36.0, longitude: 12.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('HybridAlgerianPrayerRepository throws ArgumentError on non-existent Wilaya code', () async {
      final repository = HybridAlgerianPrayerRepository(
        bundledDataSource: BundledTimetableDataSource(initialCache: {}),
      );

      expect(
        () => repository.getPrayerTimes(wilayaCode: 99, date: DateTime(2026, 10, 6)),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repository.getPrayerTimes(wilayaCode: 0, date: DateTime(2026, 10, 6)),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Challenger M1: Hijri Engine Boundary & Moonsighting Stress Tests', () {
    test('Moonsighting offsets are clamped strictly to [-2, +2] days', () {
      final date = DateTime(2026, 10, 6);

      final overPositive = HijriCalculator.calculate(gregorianDate: date, offsetDays: 10);
      expect(overPositive.offsetDays, equals(2));

      final overNegative = HijriCalculator.calculate(gregorianDate: date, offsetDays: -10);
      expect(overNegative.offsetDays, equals(-2));
    });

    test('Eastern Arabic numerals converter handles edge cases gracefully', () {
      expect(HijriCalculator.toEasternArabicDigits(''), equals(''));
      expect(HijriCalculator.toEasternArabicDigits('0123456789'), equals('٠١٢٣٤٥٦٧٨٩'));
      expect(HijriCalculator.toEasternArabicDigits('Year 2026 / 1448 AH'),
          equals('Year ٢٠٢٦ / ١٤٤٨ AH'));
    });

    test('Hijri calculation across leap year Feb 29 yields valid non-null date', () {
      final leapDay = DateTime(2028, 2, 29);
      final hijri = HijriCalculator.calculate(gregorianDate: leapDay);

      expect(hijri.year, inInclusiveRange(1449, 1450));
      expect(hijri.month, inInclusiveRange(1, 12));
      expect(hijri.day, inInclusiveRange(1, 30));
      expect(hijri.dayNameAr.isNotEmpty, isTrue);
      expect(hijri.monthNameAr.isNotEmpty, isTrue);
      expect(hijri.formattedAr.contains('هـ'), isTrue);
    });
  });

  group('Challenger M1: Exhaustive 21,170 Full-Year Mathematical Engine Stress', () {
    test('Calculates 365 days across all 58 Wilayas (21,170 calculations) without a single invariant violation', () {
      final baseDate = DateTime(2026, 1, 1);
      final stopwatch = Stopwatch()..start();

      int evaluatedCount = 0;
      for (final wilaya in algerianWilayas) {
        for (int dayOffset = 0; dayOffset < 365; dayOffset++) {
          final date = baseDate.add(Duration(days: dayOffset));
          final s = AlgerianPrayerCalculator.calculateForWilaya(
            wilaya: wilaya,
            date: date,
          );

          expect(s.fajr.isBefore(s.sunrise), isTrue);
          expect(s.sunrise.isBefore(s.dhuhr), isTrue);
          expect(s.dhuhr.isBefore(s.asr), isTrue);
          expect(s.asr.isBefore(s.maghrib), isTrue);
          expect(s.maghrib.isBefore(s.isha), isTrue);
          evaluatedCount++;
        }
      }
      stopwatch.stop();
      expect(evaluatedCount, equals(58 * 365));
    });
  });

  group('Challenger M1: Future Dates (2027) Engine Consistency & Benchmark Parity', () {
    test('Calculates valid schedules for benchmarks across 2027 future dates', () {
      final futureDates = [
        DateTime(2027, 1, 15),
        DateTime(2027, 4, 10),
        DateTime(2027, 7, 20),
        DateTime(2027, 10, 6),
      ];

      for (final code in [16, 31, 25, 30]) {
        final wilaya = algerianWilayas.firstWhere((w) => w.code == code);
        for (final date in futureDates) {
          final s = AlgerianPrayerCalculator.calculateForWilaya(
            wilaya: wilaya,
            date: date,
          );

          expect(s.fajr.year, equals(2027));
          expect(s.fajr.isBefore(s.sunrise), isTrue);
          expect(s.sunrise.isBefore(s.dhuhr), isTrue);
          expect(s.dhuhr.isBefore(s.asr), isTrue);
          expect(s.asr.isBefore(s.maghrib), isTrue);
          expect(s.maghrib.isBefore(s.isha), isTrue);
        }
      }
    });

    test('Perpetual bundled timetable matches mathematical engine within ±1 minute astronomical shift for 2027', () async {
      final file = File('assets/data/algerian_prayer_times.json');
      final jsonContent = await file.readAsString();
      final data = json.decode(jsonContent) as Map<String, dynamic>;
      final dataSource = BundledTimetableDataSource(initialCache: data);

      final date2027 = DateTime(2027, 10, 6);

      for (final code in [16, 31, 25, 30]) {
        final wilaya = algerianWilayas.firstWhere((w) => w.code == code);
        final calcSchedule = AlgerianPrayerCalculator.calculateForWilaya(wilaya: wilaya, date: date2027);
        final bundledSchedule = await dataSource.getPrayerSchedule(code, date2027);

        expect(bundledSchedule, isNotNull);

        // Perpetual timetable vs 2027 calculation discrepancy must be <= 1 min
        expect((calcSchedule.fajr.difference(bundledSchedule!.fajr).inMinutes).abs(), lessThanOrEqualTo(1));
        expect((calcSchedule.sunrise.difference(bundledSchedule.sunrise).inMinutes).abs(), lessThanOrEqualTo(1));
        expect((calcSchedule.dhuhr.difference(bundledSchedule.dhuhr).inMinutes).abs(), lessThanOrEqualTo(1));
        expect((calcSchedule.asr.difference(bundledSchedule.asr).inMinutes).abs(), lessThanOrEqualTo(1));
        expect((calcSchedule.maghrib.difference(bundledSchedule.maghrib).inMinutes).abs(), lessThanOrEqualTo(1));
        expect((calcSchedule.isha.difference(bundledSchedule.isha).inMinutes).abs(), lessThanOrEqualTo(1));
      }
    });
  });

  group('Challenger M1: PrayerSchedule Boundary & Precision Invariants', () {
    final alger = algerianWilayas.firstWhere((w) => w.code == 16);
    final testDate = DateTime(2026, 10, 6);
    final s = AlgerianPrayerCalculator.calculateForWilaya(wilaya: alger, date: testDate);

    test('getCurrentPrayer handles exact boundary timestamps', () {
      // 1 millisecond before Fajr
      expect(s.getCurrentPrayer(s.fajr.subtract(const Duration(milliseconds: 1))), isNull);

      // Exactly at Fajr
      expect(s.getCurrentPrayer(s.fajr), equals(Prayer.fajr));

      // Exactly at Sunrise
      expect(s.getCurrentPrayer(s.sunrise), equals(Prayer.sunrise));

      // Exactly at Dhuhr
      expect(s.getCurrentPrayer(s.dhuhr), equals(Prayer.dhuhr));

      // Exactly at Asr
      expect(s.getCurrentPrayer(s.asr), equals(Prayer.asr));

      // Exactly at Maghrib
      expect(s.getCurrentPrayer(s.maghrib), equals(Prayer.maghrib));

      // Exactly at Isha
      expect(s.getCurrentPrayer(s.isha), equals(Prayer.isha));

      // End of day (23:59:59)
      expect(s.getCurrentPrayer(DateTime(2026, 10, 6, 23, 59, 59)), equals(Prayer.isha));
    });

    test('getNextPrayer transitions smoothly across exact boundary timestamps', () {
      // 1 ms before Fajr -> next is Fajr
      expect(s.getNextPrayer(s.fajr.subtract(const Duration(milliseconds: 1))), equals(Prayer.fajr));

      // Exactly at Fajr -> next is Sunrise
      expect(s.getNextPrayer(s.fajr), equals(Prayer.sunrise));

      // Exactly at Sunrise -> next is Dhuhr
      expect(s.getNextPrayer(s.sunrise), equals(Prayer.dhuhr));

      // Exactly at Dhuhr -> next is Asr
      expect(s.getNextPrayer(s.dhuhr), equals(Prayer.asr));

      // Exactly at Asr -> next is Maghrib
      expect(s.getNextPrayer(s.asr), equals(Prayer.maghrib));

      // Exactly at Maghrib -> next is Isha
      expect(s.getNextPrayer(s.maghrib), equals(Prayer.isha));

      // Exactly at Isha -> next is tomorrow Fajr
      expect(s.getNextPrayer(s.isha), equals(Prayer.fajr));

      // 23:59:59 -> next is tomorrow Fajr
      expect(s.getNextPrayer(DateTime(2026, 10, 6, 23, 59, 59)), equals(Prayer.fajr));
    });

    test('getTimeRemainingToNextPrayer is always positive throughout the entire 24h day', () {
      for (int h = 0; h < 24; h++) {
        for (int m = 0; m < 60; m += 15) {
          final now = DateTime(2026, 10, 6, h, m);
          final remaining = s.getTimeRemainingToNextPrayer(now);
          expect(remaining.isNegative, isFalse, reason: 'Remaining duration must be >= 0 at $h:$m');
          expect(remaining.inMinutes, greaterThanOrEqualTo(0));
          expect(remaining.inHours, lessThanOrEqualTo(24));
        }
      }
    });

    test('Timezone offset shifts prayer times proportionately', () {
      final utc1Schedule = AlgerianPrayerCalculator.calculateForCoordinates(
        latitude: alger.latitude,
        longitude: alger.longitude,
        date: testDate,
        targetTimeZoneOffset: const Duration(hours: 1),
      );

      final utc2Schedule = AlgerianPrayerCalculator.calculateForCoordinates(
        latitude: alger.latitude,
        longitude: alger.longitude,
        date: testDate,
        targetTimeZoneOffset: const Duration(hours: 2),
      );

      // 1 hour timezone difference should shift times by exactly 60 minutes
      expect(utc2Schedule.dhuhr.difference(utc1Schedule.dhuhr).inMinutes, equals(60));
      expect(utc2Schedule.fajr.difference(utc1Schedule.fajr).inMinutes, equals(60));
      expect(utc2Schedule.maghrib.difference(utc1Schedule.maghrib).inMinutes, equals(60));
    });
  });
}

