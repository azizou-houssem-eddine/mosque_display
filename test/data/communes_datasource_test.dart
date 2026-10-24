import 'package:flutter_test/flutter_test.dart';
import 'package:mosque_display/data/datasources/communes_datasource.dart';
import 'package:mosque_display/data/datasources/bundled_timetable_datasource.dart';
import 'package:mosque_display/data/models/prayer_offsets.dart';
import 'package:mosque_display/data/repositories/prayer_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BundledCommunesDataSource & Commune Models', () {
    late BundledCommunesDataSource dataSource;

    setUp(() {
      dataSource = BundledCommunesDataSource();
    });

    test('Loads all Algerian communes from bundled asset', () async {
      final communes = await dataSource.getAllCommunes();
      expect(communes.length, greaterThanOrEqualTo(300));

      final elEulma = communes.firstWhere((c) => c.nameFr == 'El Eulma');
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
      final elEulma = await dataSource.getCommuneByCode(1902);
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

    test('HybridAlgerianPrayerRepository integrates commune minute offset', () async {
      final timetableSource = BundledTimetableDataSource();
      await timetableSource.preload();
      final repo = HybridAlgerianPrayerRepository(
        bundledDataSource: timetableSource,
        communesDataSource: dataSource,
      );

      final date = DateTime(2026, 4, 15);
      final wilayaSchedule = await repo.getPrayerTimes(
        wilayaCode: 19,
        date: date,
      );

      final commune = await dataSource.getCommuneByCode(1902); // El Eulma
      expect(commune, isNotNull);

      final communeSchedule = await repo.getPrayerTimes(
        wilayaCode: 19,
        commune: commune,
        date: date,
      );

      final expectedFajr = wilayaSchedule.fajr.add(Duration(minutes: commune!.minuteOffset));
      expect(communeSchedule.fajr, equals(expectedFajr));
    });
  });
}
