import 'package:flutter_test/flutter_test.dart';
import 'package:mosque_display/data/datasources/communes_datasource.dart';
import 'package:mosque_display/data/datasources/bundled_timetable_datasource.dart';
import 'package:mosque_display/data/models/prayer_offsets.dart';
import 'package:mosque_display/data/models/wilaya.dart';
import 'package:mosque_display/data/repositories/prayer_repository.dart';
import 'package:mosque_display/domain/calculation/algerian_prayer_calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BundledCommunesDataSource & Commune Models', () {
    late BundledCommunesDataSource dataSource;

    setUp(() {
      dataSource = BundledCommunesDataSource();
    });

    test('Loads all Algerian communes from bundled asset', () async {
      final communes = await dataSource.getAllCommunes();
      expect(communes.length, equals(1541));

      final elEulma = communes.firstWhere((c) => c.nameFr == 'El Eulma' && c.wilayaCode == 19);
      expect(elEulma.wilayaCode, 19);
      expect(elEulma.nameAr, 'العلمة');
      expect(elEulma.minuteOffset, isNotNull);
    });

    test('getCommunesForWilaya returns only communes belonging to that wilaya', () async {
      final setifCommunes = await dataSource.getCommunesForWilaya(19);
      expect(setifCommunes.isNotEmpty, isTrue);
      for (final c in setifCommunes) {
        expect(c.wilayaCode, 19);
      }

      final algerCommunes = await dataSource.getCommunesForWilaya(16);
      expect(algerCommunes.isNotEmpty, isTrue);
      for (final c in algerCommunes) {
        expect(c.wilayaCode, 16);
      }
    });

    test('getCommuneByCode returns matching commune or null', () async {
      final elEulma = await dataSource.getCommuneByCode(1920);
      expect(elEulma, isNotNull);
      expect(elEulma!.nameFr, 'El Eulma');

      final nonExistent = await dataSource.getCommuneByCode(99999);
      expect(nonExistent, isNull);
    });

    test('PrayerOffsets uniform and addition operator work accurately', () {
      final uniform = PrayerOffsets.uniform(2);
      expect(uniform.fajr, 2);
      expect(uniform.sunrise, 2);
      expect(uniform.dhuhr, 2);
      expect(uniform.asr, 2);
      expect(uniform.maghrib, 2);
      expect(uniform.isha, 2);

      const base = PrayerOffsets(fajr: 1, dhuhr: -1);
      final combined = base + uniform;
      expect(combined.fajr, 3);
      expect(combined.sunrise, 2);
      expect(combined.dhuhr, 1);
    });

    test('HybridAlgerianPrayerRepository applies official MARW commune offset to bundled Wilaya schedule', () async {
      final timetableSource = BundledTimetableDataSource();
      await timetableSource.preload();
      final repo = HybridAlgerianPrayerRepository(
        bundledDataSource: timetableSource,
        communesDataSource: dataSource,
      );

      final date = DateTime(2026, 4, 15);
      final commune = await dataSource.getCommuneByCode(1920); // El Eulma (W19)
      expect(commune, isNotNull);

      final communeSchedule = await repo.getPrayerTimes(
        wilayaCode: 19,
        commune: commune,
        date: date,
      );

      final wilayaSchedule = await timetableSource.getPrayerSchedule(19, date);
      expect(wilayaSchedule, isNotNull);
      final expectedSchedule = wilayaSchedule!.applyOffsets(PrayerOffsets.uniform(commune!.minuteOffset));

      expect(communeSchedule.fajr, equals(expectedSchedule.fajr));
      expect(communeSchedule.dhuhr, equals(expectedSchedule.dhuhr));
      expect(communeSchedule.asr, equals(expectedSchedule.asr));
      expect(communeSchedule.maghrib, equals(expectedSchedule.maghrib));
      expect(communeSchedule.isha, equals(expectedSchedule.isha));
    });

    test('HybridAlgerianPrayerRepository falls back to astronomical calculation if bundled data missing', () async {
      final emptyTimetable = BundledTimetableDataSource(initialCache: {});
      final repo = HybridAlgerianPrayerRepository(
        bundledDataSource: emptyTimetable,
        communesDataSource: dataSource,
      );

      final date = DateTime(2026, 4, 15);
      final commune = await dataSource.getCommuneByCode(1920); // El Eulma
      expect(commune, isNotNull);

      final communeSchedule = await repo.getPrayerTimes(
        wilayaCode: 19,
        commune: commune,
        date: date,
      );

      final expectedSchedule = AlgerianPrayerCalculator.calculateForCoordinates(
        latitude: commune!.latitude,
        longitude: commune.longitude,
        date: date,
      );

      expect(communeSchedule.fajr, equals(expectedSchedule.fajr));
      expect(communeSchedule.maghrib, equals(expectedSchedule.maghrib));
    });

    test('Wilayas 49-58 communes match their official Wilaya coordinates', () async {
      for (int code = 49; code <= 58; code++) {
        final wilaya = algerianWilayas.firstWhere((w) => w.code == code);
        final list = await dataSource.getCommunesForWilaya(code);
        expect(list.isNotEmpty, isTrue, reason: 'Wilaya $code (${wilaya.nameFr}) must have communes');
        final chefLieu = list.first;
        expect((chefLieu.longitude - wilaya.longitude).abs(), lessThan(0.1),
            reason: 'Wilaya $code chef-lieu ${chefLieu.nameFr} longitude must match ${wilaya.nameFr}');
      }
    });
  });
}
