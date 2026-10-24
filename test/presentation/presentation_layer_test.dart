import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mosque_display/core/providers/display_provider.dart';
import 'package:mosque_display/data/models/mosque_settings.dart';
import 'package:mosque_display/data/models/commune.dart';
import 'package:mosque_display/data/models/prayer_offsets.dart';
import 'package:mosque_display/data/models/prayer_schedule.dart';
import 'package:mosque_display/data/models/wilaya.dart';
import 'package:mosque_display/data/repositories/prayer_repository.dart';
import 'package:mosque_display/data/repositories/settings_repository.dart';
import 'package:mosque_display/domain/occasions/islamic_occasions_engine.dart';
import 'package:mosque_display/domain/calculation/hijri_calculator.dart';

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
      fajr: DateTime(date.year, date.month, date.day, 5, 20),
      sunrise: DateTime(date.year, date.month, date.day, 6, 45),
      dhuhr: DateTime(date.year, date.month, date.day, 12, 35),
      asr: DateTime(date.year, date.month, date.day, 15, 50),
      maghrib: DateTime(date.year, date.month, date.day, 18, 20),
      isha: DateTime(date.year, date.month, date.day, 19, 45),
    ).applyOffsets(offsets);
  }

  @override
  Future<List<Commune>> getCommunesForWilaya(int wilayaCode) async => [];

  @override
  Future<Commune?> getCommuneByCode(int communeCode) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Presentation & State Machine (M2 - M4)', () {
    late _FakePrayerRepo repo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = _FakePrayerRepo();
    });

    test('DisplayProvider initializes and loads prayer schedule and Hijri date', () async {
      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
      expect(provider.todaySchedule, isNotNull);
      expect(provider.displayState, equals(DisplayState.standard));
      expect(provider.hijriDate.isNotEmpty, isTrue);
    });

    test('DisplayProvider on-demand Adhkar shortcut and dismissal work correctly', () async {
      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      expect(provider.displayState, equals(DisplayState.standard));

      // Trigger on-demand shortcut
      provider.triggerAdhkarOnDemand();
      expect(provider.displayState, equals(DisplayState.postSalatAdhkar));
      expect(provider.adhkarShortcutActive, isTrue);
      expect(provider.adhkarRemaining.inMinutes, equals(7));

      // Dismiss early via D-pad Back
      provider.dismissAdhkar();
      expect(provider.displayState, equals(DisplayState.standard));
      expect(provider.adhkarShortcutActive, isFalse);
      expect(provider.adhkarRemaining, equals(Duration.zero));
    });

    test('DisplayProvider updateSettings updates settings and reloads schedule', () async {
      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      expect(provider.settings.selectedWilayaCode, equals(16));

      const newSettings = MosqueSettings(
        selectedWilayaCode: 31,
        mosqueName: 'مسجد وهران الكبير',
      );
      await provider.updateSettings(newSettings);

      expect(provider.settings.selectedWilayaCode, equals(31));
      expect(provider.settings.mosqueName, equals('مسجد وهران الكبير'));
    });

    test('IslamicOccasionsEngine detects Friday correctly', () {
      // Find a Friday
      final friday = DateTime(2026, 10, 9); // Friday
      expect(friday.weekday, equals(DateTime.friday));

      final occasions = IslamicOccasionsEngine.getOccasions(friday);
      expect(occasions.any((o) => o.type == OccasionType.friday), isTrue);
      final fridayOccasion = occasions.firstWhere((o) => o.type == OccasionType.friday);
      expect(fridayOccasion.titleAr, contains('الجمعة'));
      expect(fridayOccasion.messageAr, contains('الكهف'));
    });

    test('IslamicOccasionsEngine Ramadan and Imsak time calculation', () {
      final fajr = DateTime(2026, 3, 10, 5, 15);
      const hijri = HijriDate(
        year: 1447,
        month: 9, // Ramadan
        day: 1,
        dayNameAr: 'الثلاثاء',
        monthNameAr: 'رمضان',
      );

      final imsak = IslamicOccasionsEngine.getImsakTime(fajr, hijri);
      expect(imsak, isNotNull);
      expect(imsak, equals(DateTime(2026, 3, 10, 5, 5))); // 10 min before Fajr

      final iftarDua = IslamicOccasionsEngine.getIftarDua(hijri);
      expect(iftarDua, isNotNull);
      expect(iftarDua, contains('اللهم لك صمت'));
    });

    test('SettingsRepository saves and reloads MosqueSettings reliably', () async {
      SharedPreferences.setMockInitialValues({});

      const customSettings = MosqueSettings(
        selectedWilayaCode: 25,
        mosqueName: 'جامع الأمير عبد القادر',
        blackoutDurationMinutes: 25,
        blackoutDimMode: true,
        hijriOffsetDays: 1,
        pinCode: '1234',
      );

      await SettingsRepository.save(customSettings);
      final loaded = await SettingsRepository.load();

      expect(loaded.selectedWilayaCode, equals(25));
      expect(loaded.mosqueName, equals('جامع الأمير عبد القادر'));
      expect(loaded.blackoutDurationMinutes, equals(25));
      expect(loaded.blackoutDimMode, isTrue);
      expect(loaded.hijriOffsetDays, equals(1));
      expect(loaded.pinCode, equals('1234'));
      expect(loaded.verifyPin('1234'), isTrue);
      expect(loaded.verifyPin('0000'), isFalse);
    });
  });
}
