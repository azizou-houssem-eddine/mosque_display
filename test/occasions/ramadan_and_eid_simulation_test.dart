import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mosque_display/core/providers/display_provider.dart';
import 'package:mosque_display/data/models/commune.dart';
import 'package:mosque_display/data/models/prayer_offsets.dart';
import 'package:mosque_display/data/models/prayer_schedule.dart';
import 'package:mosque_display/data/models/wilaya.dart';
import 'package:mosque_display/data/repositories/prayer_repository.dart';
import 'package:mosque_display/domain/occasions/islamic_occasions_engine.dart';
import 'package:mosque_display/ui/screens/main_dashboard_screen.dart';

class _FakePrayerRepo implements IPrayerRepository {
  @override
  Future<List<Wilaya>> getAllWilayas() async => algerianWilayas;

  @override
  Future<PrayerSchedule> getPrayerTimes({
    required int wilayaCode,
    Commune? commune,
    required DateTime date,
    PrayerOffsets offsets = const PrayerOffsets(),
  }) async {
    return PrayerSchedule(
      fajr: DateTime(date.year, date.month, date.day, 5, 30),
      sunrise: DateTime(date.year, date.month, date.day, 6, 45),
      dhuhr: DateTime(date.year, date.month, date.day, 12, 45),
      asr: DateTime(date.year, date.month, date.day, 16, 15),
      maghrib: DateTime(date.year, date.month, date.day, 18, 30),
      isha: DateTime(date.year, date.month, date.day, 19, 50),
    ).applyOffsets(offsets);
  }

  @override
  Future<List<Commune>> getCommunesForWilaya(int wilayaCode) async => [];

  @override
  Future<Commune?> getCommuneByCode(int communeCode) async => null;
}

Widget _wrapWidget(Widget child, DisplayProvider provider) {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(size: Size(1920, 1080)),
      child: ChangeNotifierProvider<DisplayProvider>.value(
        value: provider,
        child: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ramadan & Eid Calculations and Occasions Invariants', () {
    test('PrayerSchedule accurately computes Algerian Imsak, Iftar, and Eid prayer', () {
      final now = DateTime(2026, 3, 20);
      final schedule = PrayerSchedule(
        fajr: DateTime(now.year, now.month, now.day, 5, 20),
        sunrise: DateTime(now.year, now.month, now.day, 6, 40),
        dhuhr: DateTime(now.year, now.month, now.day, 12, 35),
        asr: DateTime(now.year, now.month, now.day, 15, 55),
        maghrib: DateTime(now.year, now.month, now.day, 18, 25),
        isha: DateTime(now.year, now.month, now.day, 19, 45),
      );

      // Official Algerian Imsak = 10 min before Fajr
      expect(schedule.imsak, equals(DateTime(2026, 3, 20, 5, 10)));
      expect(schedule.imsakFormatted, equals('05:10'));

      // Official Algerian Iftar = Maghrib
      expect(schedule.iftar, equals(DateTime(2026, 3, 20, 18, 25)));
      expect(schedule.iftarFormatted, equals('18:25'));

      // Official Algerian Eid Prayer = 30 min after Sunrise
      expect(schedule.eidPrayer, equals(DateTime(2026, 3, 20, 7, 10)));
      expect(schedule.eidPrayerFormatted, equals('07:10'));
    });

    test('IslamicOccasionsEngine prioritizes Eid over Friday when they coincide', () {
      // 1 Shawwal 1447 in 2026 falls on a Friday (2026-03-20)
      final eidFriday = DateTime(2026, 3, 20);
      final occasions = IslamicOccasionsEngine.getOccasions(eidFriday);

      expect(occasions, isNotEmpty);
      expect(occasions.first.type, equals(OccasionType.eidFitr),
          reason: 'Annual Eid holiday must have higher priority than weekly Friday');
      expect(occasions.any((o) => o.type == OccasionType.friday), isTrue,
          reason: 'Friday must still be present as a secondary occasion in the list');
    });

    test('Representative dates for Ramadan and Eid specify daytime hours for realistic TV preview', () {
      final ramadanDate = IslamicOccasionsEngine.getRepresentativeDate(OccasionType.ramadan);
      expect(ramadanDate.hour, equals(18));
      expect(ramadanDate.minute, equals(15));

      final eidDate = IslamicOccasionsEngine.getRepresentativeDate(OccasionType.eidFitr);
      expect(eidDate.hour, equals(6));
      expect(eidDate.minute, equals(40));
    });
  });

  group('DisplayProvider Ramadan & Eid Simulation State', () {
    late _FakePrayerRepo repo;
    late DisplayProvider provider;

    setUp(() async {
      repo = _FakePrayerRepo();
      provider = DisplayProvider(prayerRepo: repo);
      await provider.init();
    });

    test('simulateOccasion(OccasionType.ramadan) configures Ramadan fasting state and Imsak/Iftar', () async {
      await provider.simulateOccasion(OccasionType.ramadan);

      expect(provider.isSimulationActive, isTrue);
      expect(provider.isRamadan, isTrue);
      expect(provider.isFastingDay, isTrue);
      expect(provider.activeSimulatedOccasion, equals(OccasionType.ramadan));
      expect(provider.primaryOccasion?.type, equals(OccasionType.ramadan));
      expect(provider.imsakTime, isNotNull);
      expect(provider.iftarTime, isNotNull);
      expect(provider.todaySchedule?.imsakFormatted, equals('05:20'));
      expect(provider.todaySchedule?.iftarFormatted, equals('18:30'));
    });

    test('simulateOccasion(OccasionType.eidFitr) configures Eid state and Eid prayer timing', () async {
      await provider.simulateOccasion(OccasionType.eidFitr);

      expect(provider.isSimulationActive, isTrue);
      expect(provider.isEid, isTrue);
      expect(provider.activeSimulatedOccasion, equals(OccasionType.eidFitr));
      expect(provider.primaryOccasion?.type, equals(OccasionType.eidFitr));
      expect(provider.eidPrayerTime, isNotNull);
      expect(provider.todaySchedule?.eidPrayerFormatted, equals('07:15'));
    });

    test('resetSimulation resets effective date back to real world live time', () async {
      await provider.simulateOccasion(OccasionType.ramadan);
      expect(provider.isSimulationActive, isTrue);

      await provider.resetSimulation();
      expect(provider.isSimulationActive, isFalse);
      expect(provider.activeSimulatedOccasion, isNull);
    });
  });

  group('MainDashboardScreen Ramadan & Eid Visual Transformation UI Tests', () {
    late _FakePrayerRepo repo;
    late DisplayProvider provider;

    setUp(() async {
      repo = _FakePrayerRepo();
      provider = DisplayProvider(prayerRepo: repo);
      await provider.init();
    });

    testWidgets('Dashboard renders Ramadan banner, Imsak badge, and Iftar badge during Ramadan simulation',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await provider.simulateOccasion(OccasionType.ramadan);

      await tester.pumpWidget(_wrapWidget(const MainDashboardScreen(), provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Ramadan Banner contains Imsak and Iftar indicators
      expect(find.textContaining('رمضان المبارك'), findsWidgets);
      expect(find.textContaining('الإمساك: 05:20'), findsWidgets);
      expect(find.textContaining('الإفطار: 18:30'), findsWidgets);

      // Verify Prayer Cards contain auxiliary Imsak and Iftar labels
      expect(find.text('الإمساك'), findsOneWidget);
      expect(find.text('الإفطار'), findsOneWidget);

      // Verify Central Gauge subtitle indicates Iftar countdown
      expect(find.text('متبقي على موعد الإفطار (المغرب)'), findsOneWidget);
    });

    testWidgets('Dashboard renders Eid banner, Eid prayer timing, and festive greeting during Eid simulation',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await provider.simulateOccasion(OccasionType.eidFitr);

      await tester.pumpWidget(_wrapWidget(const MainDashboardScreen(), provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);

      // Verify Eid Banner contains title and Eid prayer time
      expect(find.textContaining('عيد الفطر المبارك'), findsWidgets);
      expect(find.textContaining('صلاة العيد: 07:15'), findsWidgets);

      // Verify Central Gauge subtitle indicates Eid prayer
      expect(find.text('حتى صلاة العيد المبارك'), findsOneWidget);
    });
  });
}
