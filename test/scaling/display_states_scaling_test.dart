import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mosque_display/core/providers/display_provider.dart';
import 'package:mosque_display/data/models/prayer_schedule.dart';
import 'package:mosque_display/ui/screens/iqamah_countdown_screen.dart';
import 'package:mosque_display/ui/screens/salat_blackout_screen.dart';
import 'package:mosque_display/ui/screens/adhkar_carousel_screen.dart';
import 'package:mosque_display/ui/screens/jumuah_khutbah_screen.dart';
import 'resolution_matrix.dart';
import 'multi_resolution_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPrayerRepo repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = MockPrayerRepo();
  });

  group('Iqamah Countdown Screen Multi-Resolution Suite', () {
    testMultiResolution(
      'Iqamah countdown scales with zero overflow',
      resolutions: coreTvResolutions,
      testBody: (tester, res) async {
        final provider = DisplayProvider(prayerRepo: repo);
        await provider.init();
        provider.simulateDisplayState(
          DisplayState.iqamahCountdown,
          prayer: Prayer.maghrib,
          customDuration: const Duration(minutes: 10),
        );

        await tester.pumpWidget(buildScalingTestApp(
          child: const IqamahCountdownScreen(),
          provider: provider,
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'), findsOneWidget);
        expect(find.textContaining('المغرب'), findsWidgets);
      },
    );
  });

  group('Adhan Alert Screen Multi-Resolution Suite', () {
    testMultiResolution(
      'Adhan alert pulse scales with zero overflow',
      resolutions: coreTvResolutions,
      testBody: (tester, res) async {
        final provider = DisplayProvider(prayerRepo: repo);
        await provider.init();
        provider.simulateDisplayState(
          DisplayState.adhanAlert,
          prayer: Prayer.maghrib,
          customDuration: const Duration(minutes: 2),
        );

        await tester.pumpWidget(buildScalingTestApp(
          child: const IqamahCountdownScreen(),
          provider: provider,
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'), findsOneWidget);
        expect(find.textContaining('المغرب'), findsWidgets);
      },
    );
  });

  group('Salat Blackout Screen Multi-Resolution Suite', () {
    testMultiResolution(
      'Salat blackout (OLED & Dim) scales with zero overflow',
      resolutions: coreTvResolutions,
      testBody: (tester, res) async {
        final provider = DisplayProvider(prayerRepo: repo);
        await provider.init();
        provider.simulateDisplayState(DisplayState.salatBlackout, prayer: Prayer.isha);

        await tester.pumpWidget(buildScalingTestApp(
          child: const SalatBlackoutScreen(),
          provider: provider,
        ));
        await tester.pumpAndSettle();

        expect(find.text('صلاة العشاء'), findsOneWidget);
        expect(find.text('«اسْتَوُوا وَاعْتَدِلُوا وَسَوُّوا صُفُوفَكُمْ»'), findsOneWidget);
      },
    );
  });

  group('Post-Salat Adhkar Carousel Multi-Resolution Suite', () {
    testMultiResolution(
      'Adhkar carousel scales with zero overflow',
      resolutions: coreTvResolutions,
      testBody: (tester, res) async {
        final provider = DisplayProvider(prayerRepo: repo);
        await provider.init();
        provider.triggerAdhkarOnDemand();

        await tester.pumpWidget(buildScalingTestApp(
          child: const AdhkarCarouselScreen(),
          provider: provider,
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('أذكار ما بعد الصلاة'), findsOneWidget);
      },
    );
  });

  group('Jumuah Khutbah Screen Multi-Resolution Suite', () {
    testMultiResolution(
      'Jumuah khutbah reverence mode scales with zero overflow',
      resolutions: coreTvResolutions,
      testBody: (tester, res) async {
        final provider = DisplayProvider(prayerRepo: repo);
        await provider.init();
        provider.simulateDisplayState(DisplayState.jumuahKhutbah, prayer: Prayer.dhuhr);

        await tester.pumpWidget(buildScalingTestApp(
          child: const JumuahKhutbahScreen(),
          provider: provider,
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.textContaining('خُطْبَةُ يَوْمِ الجُمُعَةِ'), findsOneWidget);
        expect(find.text('أَنْصِتْ وَاسْتَمِعْ رَحِمَكَ اللهُ'), findsOneWidget);
      },
    );
  });
}
