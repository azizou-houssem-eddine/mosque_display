import 'package:flutter_test/flutter_test.dart';
import 'package:mosque_display/data/models/wilaya.dart';
import 'package:mosque_display/data/models/prayer_schedule.dart';
import 'package:mosque_display/data/models/prayer_offsets.dart';
import 'package:mosque_display/data/models/iqamah_delays.dart';
import 'package:mosque_display/data/models/mosque_settings.dart';

void main() {
  group('Wilaya Model Tests', () {
    test('Constructs and serializes correctly', () {
      const wilaya = Wilaya(
        code: 16,
        nameAr: 'الجزائر',
        nameFr: 'Alger',
        latitude: 36.7538,
        longitude: 3.0588,
      );

      expect(wilaya.displayNameAr, equals('16 - الجزائر'));
      expect(wilaya.displayNameFr, equals('16 - Alger'));
      expect(wilaya.displayName, equals('16 - الجزائر (Alger)'));

      final json = wilaya.toJson();
      final fromJson = Wilaya.fromJson(json);
      expect(fromJson, equals(wilaya));
    });

    test('Query matching functions accurately', () {
      const wilaya = Wilaya(
        code: 31,
        nameAr: 'وهران',
        nameFr: 'Oran',
        latitude: 35.6971,
        longitude: -0.6308,
      );

      expect(wilaya.matchesQuery('31'), isTrue);
      expect(wilaya.matchesQuery('oran'), isTrue);
      expect(wilaya.matchesQuery('وهران'), isTrue);
      expect(wilaya.matchesQuery('alger'), isFalse);
    });

    test('Throws on invalid code or coordinates', () {
      expect(
        () => Wilaya(code: 0, nameAr: 'A', nameFr: 'A', latitude: 30.0, longitude: 3.0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => Wilaya(code: 59, nameAr: 'A', nameFr: 'A', latitude: 30.0, longitude: 3.0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => Wilaya(code: 16, nameAr: 'A', nameFr: 'A', latitude: 3.0, longitude: 36.0), // Inverted!
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('PrayerOffsets Model Tests', () {
    test('Default zero offsets and clamping', () {
      const offsets = PrayerOffsets();
      expect(offsets.fajr, equals(0));
      expect(offsets.getOffsetFor(Prayer.fajr), equals(0));

      final adjusted = offsets.copyWith(fajr: 10, isha: -12);
      expect(adjusted.fajr, equals(10));
      expect(adjusted.isha, equals(-12));

      // Test clamping beyond ±15
      final clamped = offsets.copyWith(fajr: 30, isha: -40);
      expect(clamped.fajr, equals(15));
      expect(clamped.isha, equals(-15));
    });

    test('Serialization with invalid JSON values clamps safely', () {
      final json = {'fajr': 99, 'isha': -99, 'dhuhr': 5};
      final deserialized = PrayerOffsets.fromJson(json);
      expect(deserialized.fajr, equals(15));
      expect(deserialized.isha, equals(-15));
      expect(deserialized.dhuhr, equals(5));
    });
  });

  group('PrayerSchedule Model Tests', () {
    final date = DateTime(2026, 10, 6);
    final times = ['05:21', '06:47', '12:36', '15:54', '18:24', '19:45'];

    test('fromTimetableList parses correctly', () {
      final schedule = PrayerSchedule.fromTimetableList(date: date, times: times);
      expect(schedule.fajr, equals(DateTime(2026, 10, 6, 5, 21)));
      expect(schedule.sunrise, equals(DateTime(2026, 10, 6, 6, 47)));
      expect(schedule.dhuhr, equals(DateTime(2026, 10, 6, 12, 36)));
      expect(schedule.asr, equals(DateTime(2026, 10, 6, 15, 54)));
      expect(schedule.maghrib, equals(DateTime(2026, 10, 6, 18, 24)));
      expect(schedule.isha, equals(DateTime(2026, 10, 6, 19, 45)));
    });

    test('applyOffsets shifts dates accurately', () {
      final schedule = PrayerSchedule.fromTimetableList(date: date, times: times);
      const offsets = PrayerOffsets(fajr: 5, maghrib: -3);
      final adjusted = schedule.applyOffsets(offsets);

      expect(adjusted.fajr, equals(DateTime(2026, 10, 6, 5, 26)));
      expect(adjusted.maghrib, equals(DateTime(2026, 10, 6, 18, 21)));
      expect(adjusted.dhuhr, equals(schedule.dhuhr));
    });

    test('getNextPrayer logic across time boundary', () {
      final schedule = PrayerSchedule.fromTimetableList(date: date, times: times);

      // Morning before Fajr
      expect(schedule.getNextPrayer(DateTime(2026, 10, 6, 4, 0)), equals(Prayer.fajr));
      // Between Fajr and Sunrise
      expect(schedule.getNextPrayer(DateTime(2026, 10, 6, 6, 0)), equals(Prayer.sunrise));
      // Midday before Dhuhr
      expect(schedule.getNextPrayer(DateTime(2026, 10, 6, 12, 0)), equals(Prayer.dhuhr));
      // Late night after Isha (returns Fajr of tomorrow)
      expect(schedule.getNextPrayer(DateTime(2026, 10, 6, 22, 0)), equals(Prayer.fajr));
    });
  });

  group('IqamahDelays Model Tests', () {
    test('Default values and retrieval', () {
      const delays = IqamahDelays();
      expect(delays.fajr, equals(20));
      expect(delays.dhuhr, equals(15));
      expect(delays.asr, equals(15));
      expect(delays.maghrib, equals(5));
      expect(delays.isha, equals(15));
      expect(delays.getDelayFor(Prayer.sunrise), equals(0));
    });
  });

  group('MosqueSettings Model Tests', () {
    test('Constructs with defaults and serializes cleanly', () {
      const settings = MosqueSettings();
      expect(settings.selectedWilayaCode, equals(16));
      expect(settings.pinCode, equals('0000'));
      expect(settings.verifyPin('0000'), isTrue);
      expect(settings.verifyPin('1234'), isFalse);
      expect(settings.isCustomPinConfigured, isFalse);

      final json = settings.toJson();
      final fromJson = MosqueSettings.fromJson(json);
      expect(fromJson, equals(settings));
    });
  });
}
