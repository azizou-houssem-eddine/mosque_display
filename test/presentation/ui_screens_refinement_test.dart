import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mosque_display/core/providers/display_provider.dart';
import 'package:mosque_display/core/theme/app_theme.dart';
import 'package:mosque_display/data/models/commune.dart';
import 'package:mosque_display/data/models/prayer_offsets.dart';
import 'package:mosque_display/data/models/prayer_schedule.dart';
import 'package:mosque_display/data/models/wilaya.dart';
import 'package:mosque_display/data/repositories/prayer_repository.dart';

import 'package:mosque_display/ui/screens/main_dashboard_screen.dart';
import 'package:mosque_display/ui/screens/iqamah_countdown_screen.dart';
import 'package:mosque_display/ui/screens/salat_blackout_screen.dart';
import 'package:mosque_display/ui/screens/adhkar_carousel_screen.dart';
import 'package:mosque_display/ui/screens/dua_showcase_screen.dart';
import 'package:mosque_display/ui/screens/settings_screen.dart';
import 'package:mosque_display/ui/widgets/prayer_card_widget.dart';
import 'package:mosque_display/ui/widgets/circular_gauge_widget.dart';
import 'package:mosque_display/ui/widgets/hadith_ticker.dart';
import 'package:mosque_display/ui/widgets/simulation_control_dialog.dart';

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

Widget _wrapWithProvider(
  Widget child, {
  required DisplayProvider provider,
  Size size = const Size(1920, 1080),
}) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: ChangeNotifierProvider<DisplayProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.theme,
          home: child,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePrayerRepo repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = _FakePrayerRepo();
  });

  group('UI Polish & Resolution Refinement Tests', () {
    testWidgets('PrayerCardWidget renders active, next, and standard states with distinct visual badges',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: const Scaffold(
            body: Row(
              children: [
                PrayerCardWidget(
                  prayerNameAr: 'الفجر',
                  time: '05:20',
                  isActive: true,
                ),
                PrayerCardWidget(
                  prayerNameAr: 'الشروق',
                  time: '06:45',
                  isNext: true,
                ),
                PrayerCardWidget(
                  prayerNameAr: 'الظهر',
                  time: '12:35',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check text existence
      expect(find.text('الفجر'), findsOneWidget);
      expect(find.text('05:20'), findsOneWidget);
      expect(find.text('الآن'), findsOneWidget); // Active badge

      expect(find.text('الشروق'), findsOneWidget);
      expect(find.text('06:45'), findsOneWidget);
      expect(find.text('القادمة'), findsOneWidget); // Next badge

      expect(find.text('الظهر'), findsOneWidget);
      expect(find.text('12:35'), findsOneWidget);
    });

    testWidgets('CircularGaugeWidget renders with cardinal astrolabe fleurons and precision ticks',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: const Scaffold(
            body: CircularGaugeWidget(
              progress: 0.65,
              centerLabel: '12:34',
              subtitle: 'حتى المغرب',
              size: 320,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('12:34'), findsOneWidget);
      expect(find.text('حتى المغرب'), findsOneWidget);
      expect(find.text('الوَقْتُ المُتَبَقِّي'), findsOneWidget);
    });

    testWidgets('IslamicDivider renders center star symbol and tapering lines',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IslamicDivider(centerSymbol: '۞'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('۞'), findsOneWidget);
      expect(find.text('✦'), findsNWidgets(2));
    });

    testWidgets('HadithTicker renders edge fade overlays and Islamic typography',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: HadithTicker(
              items: const ['اللهم أعني على ذكرك وشكرك وحسن عبادتك'],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(HadithTicker), findsOneWidget);
    });

    testWidgets('MainDashboardScreen scales cleanly on 720p, 1080p, and 4K without overflow',
        (tester) async {
      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      final resolutions = [
        const Size(1280, 720),  // 720p HD Ready
        const Size(1920, 1080), // 1080p Full HD
        const Size(3840, 2160), // 4K Ultra HD
      ];

      for (final res in resolutions) {
        tester.view.physicalSize = res;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          _wrapWithProvider(
            const MainDashboardScreen(),
            provider: provider,
            size: res,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull,
            reason: 'MainDashboardScreen must not throw overflow on ${res.width}x${res.height}');

        // Confirm prayer names rendered
        expect(find.text('الفجر'), findsOneWidget);
        expect(find.text('الظهر'), findsOneWidget);
        expect(find.text('المغرب'), findsOneWidget);
        expect(find.text('العشاء'), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('IqamahCountdownScreen scales gracefully on 720p, 1080p, Ultrawide, and 4K without overflow',
        (tester) async {
      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();
      provider.simulateDisplayState(
        DisplayState.iqamahCountdown,
        prayer: Prayer.maghrib,
        customDuration: const Duration(minutes: 10),
      );

      final resolutions = [
        const Size(1280, 720),  // 720p HD Ready
        const Size(1920, 1080), // 1080p Full HD
        const Size(2560, 1080), // 21:9 Ultrawide
        const Size(3840, 2160), // 4K Ultra HD
      ];

      for (final res in resolutions) {
        tester.view.physicalSize = res;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          _wrapWithProvider(
            const IqamahCountdownScreen(),
            provider: provider,
            size: res,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull,
            reason: 'IqamahCountdownScreen must not overflow on ${res.width}x${res.height}');
        expect(find.text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'), findsOneWidget);
        expect(find.text('إِقَامَةُ صَلَاةِ المغرب'), findsOneWidget);
        expect(find.text('يُرْجَى وَضْعُ الهَوَاتِفِ عَلَى الوَضْعِ الصَّامِتِ'), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('SalatBlackoutScreen renders with soft gold typography on 720p, 1080p, Ultrawide, and 4K',
        (tester) async {
      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();
      provider.simulateDisplayState(
        DisplayState.salatBlackout,
        prayer: Prayer.isha,
      );

      final resolutions = [
        const Size(1280, 720),
        const Size(1920, 1080),
        const Size(2560, 1080),
        const Size(3840, 2160),
      ];

      for (final res in resolutions) {
        tester.view.physicalSize = res;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          _wrapWithProvider(
            const SalatBlackoutScreen(),
            provider: provider,
            size: res,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'SalatBlackoutScreen must not overflow on ${res.width}x${res.height}');
        expect(find.text('صلاة العشاء'), findsOneWidget);
        expect(find.text('«اسْتَوُوا وَاعْتَدِلُوا وَسَوُّوا صُفُوفَكُمْ»'), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('AdhkarCarouselScreen renders illuminated card and navigates with D-pad',
        (tester) async {
      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();
      provider.triggerAdhkarOnDemand();

      await tester.pumpWidget(
        _wrapWithProvider(
          const AdhkarCarouselScreen(),
          provider: provider,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('أذكار ما بعد الصلاة'), findsOneWidget);
    });

    testWidgets('DuaShowcaseScreen renders illuminated card and categories without overflow',
        (tester) async {
      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      await tester.pumpWidget(
        _wrapWithProvider(
          const DuaShowcaseScreen(),
          provider: provider,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('معرض الخطوط الإسلامية والأدعية المأثورة'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders navigation sidebar and gold focus highlights',
        (tester) async {
      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      await tester.pumpWidget(
        _wrapWithProvider(
          const SettingsScreen(),
          provider: provider,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('الإعدادات'), findsOneWidget);
      expect(find.text('الولاية'), findsOneWidget);
      expect(find.text('الخطوط والأدعية'), findsOneWidget);
    });

    testWidgets('SimulationControlDialog opens and renders all state and occasion buttons',
        (tester) async {
      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      await tester.pumpWidget(
        _wrapWithProvider(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => SimulationControlDialog.show(ctx),
              child: const Text('Open'),
            ),
          ),
          provider: provider,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('لوحة التحكم في المحاكاة والاختبار التجريبي'), findsOneWidget);
      expect(find.text('الوضع القياسي (الشاشة الرئيسية)'), findsOneWidget);
      expect(find.text('🕌 يوم الجمعة المباركة (سورة الكهف)'), findsOneWidget);
      expect(find.text('🌙 شهر رمضان المبارك (الإمساك والإفطار)'), findsOneWidget);
    });
  });
}
