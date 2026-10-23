import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mosque_display/domain/calculation/hijri_calculator.dart';
import 'package:mosque_display/data/models/mosque_settings.dart';
import 'package:mosque_display/data/models/prayer_offsets.dart';
import 'package:mosque_display/data/models/iqamah_delays.dart';
import 'package:mosque_display/data/models/prayer_schedule.dart';
import 'package:mosque_display/data/models/wilaya.dart';
import 'package:mosque_display/data/datasources/bundled_timetable_datasource.dart';

void main() {
  group('Challenger M1.2: Hijri Calendar Engine Stress Tests', () {
    test('Moonsighting adjustment clamping for extreme out-of-bounds offsets', () {
      final baseDate = DateTime(2026, 10, 6); // 25 Rabi al-Thani 1448

      final extremePlus = HijriCalculator.calculate(gregorianDate: baseDate, offsetDays: 100);
      expect(extremePlus.offsetDays, equals(2), reason: 'Offset +100 must clamp to +2');
      expect(extremePlus.day, equals(27));

      final extremeMinus = HijriCalculator.calculate(gregorianDate: baseDate, offsetDays: -50);
      expect(extremeMinus.offsetDays, equals(-2), reason: 'Offset -50 must clamp to -2');
      expect(extremeMinus.day, equals(23));

      final plusThree = HijriCalculator.calculate(gregorianDate: baseDate, offsetDays: 3);
      expect(plusThree.offsetDays, equals(2), reason: 'Offset +3 must clamp to +2');

      final minusThree = HijriCalculator.calculate(gregorianDate: baseDate, offsetDays: -3);
      expect(minusThree.offsetDays, equals(-2), reason: 'Offset -3 must clamp to -2');
    });

    test('Civil weekday invariant: weekday name remains strictly anchored to Gregorian day', () {
      // 2026-10-06 is Tuesday
      final tuesday = DateTime(2026, 10, 6);
      for (int offset = -5; offset <= 5; offset++) {
        final hijri = HijriCalculator.calculate(gregorianDate: tuesday, offsetDays: offset);
        expect(hijri.dayNameAr, equals('الثلاثاء'),
            reason: 'Civil day must remain Tuesday regardless of moonsighting offset $offset');
      }

      // 2026-10-09 is Friday (Jumuah)
      final friday = DateTime(2026, 10, 9);
      for (int offset = -2; offset <= 2; offset++) {
        final hijri = HijriCalculator.calculate(gregorianDate: friday, offsetDays: offset);
        expect(hijri.dayNameAr, equals('الجمعة'),
            reason: 'Friday must always be الجمعة');
      }
    });

    test('Month boundary transitions across 365 days of 2026 and 2027', () {
      // Step through every day of 2026 and 2027 with -2, 0, +2 offsets
      for (final offset in [-2, 0, 2]) {
        DateTime current = DateTime(2026, 1, 1);
        final end = DateTime(2027, 12, 31);

        while (current.isBefore(end)) {
          final hijri = HijriCalculator.calculate(gregorianDate: current, offsetDays: offset);

          // Invariant checks
          expect(hijri.month, inInclusiveRange(1, 12),
              reason: 'Hijri month must be 1..12 on $current with offset $offset');
          expect(hijri.day, inInclusiveRange(1, 30),
              reason: 'Hijri day must be 1..30 on $current with offset $offset');
          expect(hijri.year, inInclusiveRange(1447, 1449),
              reason: 'Hijri year must be 1447..1449 on $current with offset $offset');
          expect(hijri.monthNameAr, isNotEmpty);
          expect(hijri.dayNameAr, isNotEmpty);
          expect(hijri.formattedAr, contains('هـ'));
          expect(hijri.formattedEasternAr, contains('هـ'));

          current = current.add(const Duration(days: 1));
        }
      }
    });

    test('Moonsighting transition at Shawwal (Eid al-Fitr boundary)', () {
      // In 1447 AH, Ramadan ends around March 19-20, 2026
      // Find the exact 29 Ramadan 1447 date
      DateTime ramadan29 = DateTime(2026, 3, 19);
      while (true) {
        final h = HijriCalculator.calculate(gregorianDate: ramadan29, offsetDays: 0);
        if (h.month == 9 && h.day >= 29) break;
        if (h.month == 10) {
          ramadan29 = ramadan29.subtract(const Duration(days: 1));
          break;
        }
        ramadan29 = ramadan29.add(const Duration(days: 1));
      }

      final hBase = HijriCalculator.calculate(gregorianDate: ramadan29, offsetDays: 0);
      expect(hBase.month, equals(9)); // Ramadan

      // Offset +1 shifts into 30 Ramadan or 1 Shawwal
      final hPlusOne = HijriCalculator.calculate(gregorianDate: ramadan29, offsetDays: 1);
      expect(hPlusOne.month == 9 || hPlusOne.month == 10, isTrue);

      // Offset +2 shifts further into Shawwal
      final hPlusTwo = HijriCalculator.calculate(gregorianDate: ramadan29, offsetDays: 2);
      expect(hPlusTwo.month == 9 || hPlusTwo.month == 10, isTrue);

      // Offset -1 pulls back to 28 Ramadan
      final hMinusOne = HijriCalculator.calculate(gregorianDate: ramadan29, offsetDays: -1);
      expect(hMinusOne.month, equals(9));
      expect(hMinusOne.day, lessThan(hBase.day));
    });

    test('Moonsighting transition at Islamic New Year boundary (1447 -> 1448 AH)', () {
      // Find 1 Muharram 1448
      DateTime muharram1 = DateTime(2026, 6, 15);
      while (true) {
        final h = HijriCalculator.calculate(gregorianDate: muharram1, offsetDays: 0);
        if (h.year == 1448 && h.month == 1 && h.day == 1) break;
        muharram1 = muharram1.add(const Duration(days: 1));
      }

      final h1 = HijriCalculator.calculate(gregorianDate: muharram1, offsetDays: 0);
      expect(h1.year, equals(1448));
      expect(h1.month, equals(1));
      expect(h1.day, equals(1));

      // Moonsighting offset -1 should land on 29 or 30 Dhu al-Hijjah 1447 AH
      final hPrev = HijriCalculator.calculate(gregorianDate: muharram1, offsetDays: -1);
      expect(hPrev.year, equals(1447));
      expect(hPrev.month, equals(12)); // Dhu al-Hijjah
      expect(hPrev.day, isIn([29, 30]));

      // Moonsighting offset +1 should land on 2 Muharram 1448 AH
      final hNext = HijriCalculator.calculate(gregorianDate: muharram1, offsetDays: 1);
      expect(hNext.year, equals(1448));
      expect(hNext.month, equals(1));
      expect(hNext.day, equals(2));
    });
  });

  group('Challenger M1.2: Model Deserialization Resilience Tests', () {
    test('MosqueSettings.fromJson handles completely empty JSON map', () {
      final settings = MosqueSettings.fromJson(const {});
      expect(settings.selectedWilayaCode, equals(16));
      expect(settings.offsets.fajr, equals(0));
      expect(settings.iqamahDelays.fajr, equals(20));
      expect(settings.blackoutDurationMinutes, equals(20));
      expect(settings.blackoutDimMode, isFalse);
      expect(settings.hijriOffsetDays, equals(0));
      expect(settings.mosqueName, equals('مسجد الفتح'));
      expect(settings.pinCode, equals('0000'));
    });

    test('MosqueSettings.fromJson bounds clamps all numeric fields safely', () {
      final settings = MosqueSettings.fromJson(const {
        'selectedWilayaCode': 999, // out of range
        'blackoutDurationMinutes': 999, // out of range
        'hijriOffsetDays': 50, // out of range
        'pinCode': '123', // invalid length
      });

      expect(settings.selectedWilayaCode, equals(58));
      expect(settings.blackoutDurationMinutes, equals(45));
      expect(settings.hijriOffsetDays, equals(2));
      expect(settings.pinCode, equals('0000'));

      final settingsUnderflow = MosqueSettings.fromJson(const {
        'selectedWilayaCode': -10,
        'blackoutDurationMinutes': 0,
        'hijriOffsetDays': -50,
        'pinCode': '12345678',
      });

      expect(settingsUnderflow.selectedWilayaCode, equals(1));
      expect(settingsUnderflow.blackoutDurationMinutes, equals(5));
      expect(settingsUnderflow.hijriOffsetDays, equals(-2));
      expect(settingsUnderflow.pinCode, equals('0000'));
    });

    test('MosqueSettings.fromJson strips and handles empty/blank string inputs', () {
      final settings = MosqueSettings.fromJson(const {
        'mosqueName': '   ',
        'marqueeText': '   \n  ',
      });
      expect(settings.mosqueName, equals('مسجد الفتح'));
      expect(settings.marqueeText, contains('مَن بنى للهِ مسجدًا'));
    });

    test('PrayerOffsets.fromJson clamps out-of-range offsets to [-15, +15]', () {
      final offsets = PrayerOffsets.fromJson(const {
        'fajr': 100,
        'sunrise': -50,
        'dhuhr': 15,
        'asr': -15,
        'maghrib': 20,
        'isha': -20,
      });

      expect(offsets.fajr, equals(15));
      expect(offsets.sunrise, equals(-15));
      expect(offsets.dhuhr, equals(15));
      expect(offsets.asr, equals(-15));
      expect(offsets.maghrib, equals(15));
      expect(offsets.isha, equals(-15));
    });

    test('IqamahDelays.fromJson clamps out-of-range delays per-prayer limits', () {
      final delays = IqamahDelays.fromJson(const {
        'fajr': 100, // max 60
        'dhuhr': 1, // min 5
        'asr': 50, // max 45
        'maghrib': 2, // min 3
        'isha': 60, // max 45
      });

      expect(delays.fajr, equals(60));
      expect(delays.dhuhr, equals(5));
      expect(delays.asr, equals(45));
      expect(delays.maghrib, equals(3));
      expect(delays.isha, equals(45));
    });

    test('PrayerSchedule round-trip JSON serialization preserves all timestamps', () {
      final schedule = PrayerSchedule(
        fajr: DateTime(2026, 10, 6, 5, 21),
        sunrise: DateTime(2026, 10, 6, 6, 47),
        dhuhr: DateTime(2026, 10, 6, 12, 36),
        asr: DateTime(2026, 10, 6, 15, 54),
        maghrib: DateTime(2026, 10, 6, 18, 24),
        isha: DateTime(2026, 10, 6, 19, 45),
      );

      final json = schedule.toJson();
      final roundTrip = PrayerSchedule.fromJson(json);

      expect(roundTrip, equals(schedule));
      expect(roundTrip.fajr, equals(schedule.fajr));
      expect(roundTrip.sunrise, equals(schedule.sunrise));
      expect(roundTrip.dhuhr, equals(schedule.dhuhr));
      expect(roundTrip.asr, equals(schedule.asr));
      expect(roundTrip.maghrib, equals(schedule.maghrib));
      expect(roundTrip.isha, equals(schedule.isha));
    });

    test('All 58 Algerian Wilayas in dataset satisfy geographic and administrative invariants', () {
      expect(algerianWilayas.length, equals(58));

      final codes = <int>{};
      for (final w in algerianWilayas) {
        expect(codes.add(w.code), isTrue, reason: 'Duplicate Wilaya code ${w.code}');
        expect(w.code, inInclusiveRange(1, 58));
        expect(w.nameAr.trim(), isNotEmpty);
        expect(w.nameFr.trim(), isNotEmpty);
        expect(w.latitude, inInclusiveRange(18.0, 38.0), reason: 'Latitude out of bounds for ${w.nameFr}');
        expect(w.longitude, inInclusiveRange(-9.0, 12.0), reason: 'Longitude out of bounds for ${w.nameFr}');
        // Verify non-inverted coordinates: In Algeria, latitude is always > longitude
        expect(w.latitude, greaterThan(w.longitude), reason: 'Coordinates appear inverted for ${w.nameFr}');

        // Test serialization
        final json = w.toJson();
        final fromJson = Wilaya.fromJson(json);
        expect(fromJson, equals(w));
      }
    });
  });

  group('Challenger M1.2: Perpetual Timetable Dataset Stress Tests', () {
    late Map<String, dynamic> timetableJson;

    setUpAll(() {
      final file = File('assets/data/algerian_prayer_times.json');
      expect(file.existsSync(), isTrue, reason: 'Perpetual timetable JSON asset must exist');
      final content = file.readAsStringSync();
      timetableJson = json.decode(content) as Map<String, dynamic>;
    });

    test('Dataset contains all 58 Wilaya keys', () {
      for (int code = 1; code <= 58; code++) {
        expect(timetableJson.containsKey(code.toString()), isTrue,
            reason: 'Missing Wilaya $code in algerian_prayer_times.json');
      }
    });

    test('Every Wilaya contains all 366 days including leap day 02-29', () {
      // Generate all 366 month-day keys
      final expectedDateKeys = <String>[];
      const leapYear = 2024; // Leap year
      DateTime date = DateTime(leapYear, 1, 1);
      while (date.year == leapYear) {
        final m = date.month.toString().padLeft(2, '0');
        final d = date.day.toString().padLeft(2, '0');
        expectedDateKeys.add('$m-$d');
        date = date.add(const Duration(days: 1));
      }
      expect(expectedDateKeys.length, equals(366));
      expect(expectedDateKeys.contains('02-29'), isTrue);

      for (int code = 1; code <= 58; code++) {
        final wilayaData = timetableJson[code.toString()] as Map<String, dynamic>;
        expect(wilayaData.length, equals(366),
            reason: 'Wilaya $code does not have exactly 366 days (has ${wilayaData.length})');

        for (final dateKey in expectedDateKeys) {
          expect(wilayaData.containsKey(dateKey), isTrue,
              reason: 'Wilaya $code missing date $dateKey');
        }
      }
    });

    test('Chronological ordering invariant holds across all 58 Wilayas x 366 days (21,228 schedules)', () {
      final timeRegex = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
      final dummyDate = DateTime(2026, 1, 1);

      int totalSchedulesChecked = 0;

      for (int code = 1; code <= 58; code++) {
        final wilayaData = timetableJson[code.toString()] as Map<String, dynamic>;

        for (final entry in wilayaData.entries) {
          final times = entry.value as List<dynamic>;
          expect(times.length, equals(6),
              reason: 'Wilaya $code on ${entry.key} does not have exactly 6 times');

          for (final t in times) {
            expect(timeRegex.hasMatch(t.toString()), isTrue,
                reason: 'Wilaya $code on ${entry.key} has malformed time: $t');
          }

          final schedule = PrayerSchedule.fromTimetableList(
            date: dummyDate,
            times: times,
          );

          // Fajr < Sunrise < Dhuhr < Asr < Maghrib < Isha
          expect(schedule.fajr.isBefore(schedule.sunrise), isTrue,
              reason: 'Fajr not before Sunrise on Wilaya $code, date ${entry.key}');
          expect(schedule.sunrise.isBefore(schedule.dhuhr), isTrue,
              reason: 'Sunrise not before Dhuhr on Wilaya $code, date ${entry.key}');
          expect(schedule.dhuhr.isBefore(schedule.asr), isTrue,
              reason: 'Dhuhr not before Asr on Wilaya $code, date ${entry.key}');
          expect(schedule.asr.isBefore(schedule.maghrib), isTrue,
              reason: 'Asr not before Maghrib on Wilaya $code, date ${entry.key}');
          expect(schedule.maghrib.isBefore(schedule.isha), isTrue,
              reason: 'Maghrib not before Isha on Wilaya $code, date ${entry.key}');

          totalSchedulesChecked++;
        }
      }

      expect(totalSchedulesChecked, equals(58 * 366));
    });

    test('BundledTimetableDataSource successfully retrieves schedules without exceptions', () async {
      final dataSource = BundledTimetableDataSource(initialCache: timetableJson);

      for (final code in [1, 16, 25, 30, 31, 47, 58]) {
        // Test normal date
        final s1 = await dataSource.getPrayerSchedule(code, DateTime(2026, 10, 6));
        expect(s1, isNotNull, reason: 'Failed lookup for wilaya $code on 2026-10-06');

        // Test leap day
        final s2 = await dataSource.getPrayerSchedule(code, DateTime(2028, 2, 29));
        expect(s2, isNotNull, reason: 'Failed lookup for wilaya $code on leap day 2028-02-29');

        // Test year start / end
        final s3 = await dataSource.getPrayerSchedule(code, DateTime(2026, 1, 1));
        expect(s3, isNotNull);
        final s4 = await dataSource.getPrayerSchedule(code, DateTime(2026, 12, 31));
        expect(s4, isNotNull);
      }
    });

    test('Adversarial max-opposing offsets (±15 min) preserve chronological order across all 21,228 schedules', () {
      final dummyDate = DateTime(2026, 1, 1);
      // Case 1: Fajr pushed late (+15), Sunrise early (-15), Dhuhr late (+15), Asr early (-15), Maghrib late (+15), Isha early (-15)
      const maxConvergingOffsets = PrayerOffsets(
        fajr: 15,
        sunrise: -15,
        dhuhr: 15,
        asr: -15,
        maghrib: 15,
        isha: -15,
      );

      // Case 2: Inverted
      const maxDivergingOffsets = PrayerOffsets(
        fajr: -15,
        sunrise: 15,
        dhuhr: -15,
        asr: 15,
        maghrib: -15,
        isha: 15,
      );

      for (int code = 1; code <= 58; code++) {
        final wilayaData = timetableJson[code.toString()] as Map<String, dynamic>;

        for (final entry in wilayaData.entries) {
          final schedule = PrayerSchedule.fromTimetableList(
            date: dummyDate,
            times: entry.value as List<dynamic>,
          );

          for (final offsets in [maxConvergingOffsets, maxDivergingOffsets]) {
            final calibrated = schedule.applyOffsets(offsets);

            expect(calibrated.fajr.isBefore(calibrated.sunrise), isTrue,
                reason: 'Fajr not before Sunrise under offsets for Wilaya $code on ${entry.key}');
            expect(calibrated.sunrise.isBefore(calibrated.dhuhr), isTrue,
                reason: 'Sunrise not before Dhuhr under offsets for Wilaya $code on ${entry.key}');
            expect(calibrated.dhuhr.isBefore(calibrated.asr), isTrue,
                reason: 'Dhuhr not before Asr under offsets for Wilaya $code on ${entry.key}');
            expect(calibrated.asr.isBefore(calibrated.maghrib), isTrue,
                reason: 'Asr not before Maghrib under offsets for Wilaya $code on ${entry.key}');
            expect(calibrated.maghrib.isBefore(calibrated.isha), isTrue,
                reason: 'Maghrib not before Isha under offsets for Wilaya $code on ${entry.key}');
          }
        }
      }
    });
  });

  group('Challenger M1.2: PrayerSchedule Millisecond Boundary State Tests', () {
    final schedule = PrayerSchedule(
      fajr: DateTime(2026, 10, 6, 5, 21),
      sunrise: DateTime(2026, 10, 6, 6, 47),
      dhuhr: DateTime(2026, 10, 6, 12, 36),
      asr: DateTime(2026, 10, 6, 15, 54),
      maghrib: DateTime(2026, 10, 6, 18, 24),
      isha: DateTime(2026, 10, 6, 19, 45),
    );

    test('Microsecond boundaries around every prayer transition correctly', () {
      // 1 ms before Fajr
      final beforeFajr = schedule.fajr.subtract(const Duration(milliseconds: 1));
      expect(schedule.getCurrentPrayer(beforeFajr), isNull);
      expect(schedule.getNextPrayer(beforeFajr), equals(Prayer.fajr));
      expect(schedule.getTimeRemainingToNextPrayer(beforeFajr).inMilliseconds, equals(1));

      // Exact Fajr
      expect(schedule.getCurrentPrayer(schedule.fajr), equals(Prayer.fajr));
      expect(schedule.getNextPrayer(schedule.fajr), equals(Prayer.sunrise));
      expect(schedule.getTimeRemainingToNextPrayer(schedule.fajr), equals(schedule.sunrise.difference(schedule.fajr)));

      // 1 ms after Fajr
      final afterFajr = schedule.fajr.add(const Duration(milliseconds: 1));
      expect(schedule.getCurrentPrayer(afterFajr), equals(Prayer.fajr));
      expect(schedule.getNextPrayer(afterFajr), equals(Prayer.sunrise));

      // Exact Sunrise
      expect(schedule.getCurrentPrayer(schedule.sunrise), equals(Prayer.sunrise));
      expect(schedule.getNextPrayer(schedule.sunrise), equals(Prayer.dhuhr));

      // Exact Dhuhr
      expect(schedule.getCurrentPrayer(schedule.dhuhr), equals(Prayer.dhuhr));
      expect(schedule.getNextPrayer(schedule.dhuhr), equals(Prayer.asr));

      // Exact Asr
      expect(schedule.getCurrentPrayer(schedule.asr), equals(Prayer.asr));
      expect(schedule.getNextPrayer(schedule.asr), equals(Prayer.maghrib));

      // Exact Maghrib
      expect(schedule.getCurrentPrayer(schedule.maghrib), equals(Prayer.maghrib));
      expect(schedule.getNextPrayer(schedule.maghrib), equals(Prayer.isha));

      // Exact Isha
      expect(schedule.getCurrentPrayer(schedule.isha), equals(Prayer.isha));
      expect(schedule.getNextPrayer(schedule.isha), equals(Prayer.fajr));
      expect(schedule.getTimeRemainingToNextPrayer(schedule.isha).isNegative, isFalse);

      // Late night: 23:59:59.999
      final midnightEve = DateTime(2026, 10, 6, 23, 59, 59, 999);
      expect(schedule.getCurrentPrayer(midnightEve), equals(Prayer.isha));
      expect(schedule.getNextPrayer(midnightEve), equals(Prayer.fajr));
      final remaining = schedule.getTimeRemainingToNextPrayer(midnightEve);
      expect(remaining.isNegative, isFalse);
      expect(remaining.inHours, equals(5)); // ~5h 21m until tomorrow Fajr

      // Midnight: 00:00:00.000
      final midnightStart = DateTime(2026, 10, 6, 0, 0, 0, 0);
      expect(schedule.getCurrentPrayer(midnightStart), isNull);
      expect(schedule.getNextPrayer(midnightStart), equals(Prayer.fajr));
      expect(schedule.getTimeRemainingToNextPrayer(midnightStart), equals(const Duration(hours: 5, minutes: 21)));
    });
  });

  group('Challenger M1.2: Adversarial Failure Mode Exploration', () {
    test('HijriCalculator time-of-day invariance: 00:00 vs 23:59 return identical Hijri date', () {
      final morning = DateTime(2026, 10, 6, 0, 0, 0);
      final midday = DateTime(2026, 10, 6, 12, 30, 0);
      final evening = DateTime(2026, 10, 6, 23, 59, 59);

      for (int offset = -2; offset <= 2; offset++) {
        final hMorning = HijriCalculator.calculate(gregorianDate: morning, offsetDays: offset);
        final hMidday = HijriCalculator.calculate(gregorianDate: midday, offsetDays: offset);
        final hEvening = HijriCalculator.calculate(gregorianDate: evening, offsetDays: offset);

        expect(hMorning.year, equals(hMidday.year));
        expect(hMorning.month, equals(hMidday.month));
        expect(hMorning.day, equals(hMidday.day));
        expect(hMorning.dayNameAr, equals(hMidday.dayNameAr));

        expect(hMorning.year, equals(hEvening.year));
        expect(hMorning.month, equals(hEvening.month));
        expect(hMorning.day, equals(hEvening.day));
        expect(hMorning.dayNameAr, equals(hEvening.dayNameAr));
      }
    });

    test('HijriCalculator leap day 2028-02-29 transitions smoothly across all offsets', () {
      final leapDay = DateTime(2028, 2, 29); // Tuesday
      for (int offset = -2; offset <= 2; offset++) {
        final h = HijriCalculator.calculate(gregorianDate: leapDay, offsetDays: offset);
        expect(h.month, inInclusiveRange(1, 12));
        expect(h.day, inInclusiveRange(1, 30));
        expect(h.dayNameAr, equals('الثلاثاء'));
      }
    });

    test('Adversarial finding: MosqueSettings.fromJson throws TypeError on Map<dynamic, dynamic>', () {
      final dynamicMap = <String, dynamic>{
        'selectedWilayaCode': 16,
        'offsets': <dynamic, dynamic>{'fajr': 5},
      };

      expect(
        () => MosqueSettings.fromJson(dynamicMap),
        throwsA(isA<TypeError>()),
        reason: 'Empirically confirms vulnerability: nested dynamic map causes unhandled _TypeError',
      );
    });

    test('Adversarial finding: Integer pinCode in JSON causes TypeError', () {
      final jsonWithIntPin = <String, dynamic>{
        'pinCode': 1234, // Integer instead of String
      };

      // Empirically demonstrates the strict cast behavior
      expect(
        () => MosqueSettings.fromJson(jsonWithIntPin),
        throwsA(isA<TypeError>()),
        reason: 'json["pinCode"] as String? throws TypeError when int is supplied',
      );
    });
  });
}

