import 'package:flutter/foundation.dart';
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
import 'package:mosque_display/domain/occasions/islamic_occasions_engine.dart';
import 'package:mosque_display/ui/screens/adhkar_carousel_screen.dart';
import 'package:mosque_display/ui/screens/iqamah_countdown_screen.dart';
import 'package:mosque_display/ui/screens/jumuah_khutbah_screen.dart';
import 'package:mosque_display/ui/screens/main_dashboard_screen.dart';
import 'package:mosque_display/ui/screens/salat_blackout_screen.dart';
import 'package:mosque_display/ui/widgets/prayer_card_widget.dart';

class _AdversarialPrayerRepo implements IPrayerRepository {
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

class AdversarialResolution {
  final String label;
  final double width;
  final double height;
  final double dpr;
  final double uiScale;

  const AdversarialResolution({
    required this.label,
    required this.width,
    required this.height,
    this.dpr = 1.0,
    this.uiScale = 1.0,
  });

  Size get physicalSize => Size(width, height);
}

class AdversarialOverflowDetector {
  final List<String> caughtErrors = [];
  FlutterExceptionHandler? _oldHandler;

  void attach() {
    _oldHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final msg = details.exceptionAsString();
      if (msg.contains('overflowed by') ||
          msg.contains('RenderFlex') ||
          msg.contains('BoxConstraints') ||
          msg.contains('A RenderFlex overflowed')) {
        caughtErrors.add(msg);
        debugPrint('>>> ADVERSARIAL OVERFLOW CAUGHT:\n$msg\n${details.informationCollector?.call().map((e) => e.toString()).join("\n")}');
      }
      _oldHandler?.call(details);
    };
  }

  void detach() {
    FlutterError.onError = _oldHandler;
  }

  void assertClean([String context = '']) {
    if (caughtErrors.isNotEmpty) {
      fail('Adversarial Layout Violation caught [$context]:\n${caughtErrors.join("\n")}');
    }
  }
}

Widget _buildApp(Widget child, DisplayProvider provider) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: ChangeNotifierProvider<DisplayProvider>.value(
      value: provider,
      child: MaterialApp(
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _AdversarialPrayerRepo repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = _AdversarialPrayerRepo();
  });

  final watchFaces = [
    'classicAstrolabe',
    'modernHorizontal',
    'grandClock',
    'traditionalMinbar',
  ];

  // ───────────────────────────────────────────────────────────────────────────
  // TASK 1A: 5:4 Aspect Ratio (1280x1024)
  // ───────────────────────────────────────────────────────────────────────────
  group('Task 1A: 5:4 Aspect Ratio (1280x1024) Stress Tests', () {
    const res5_4 = AdversarialResolution(
      label: '5:4 (1280x1024)',
      width: 1280,
      height: 1024,
    );

    for (final wf in watchFaces) {
      testWidgets('Watch face $wf renders with zero overflow on 5:4 (1280x1024)',
          (tester) async {
        tester.view.physicalSize = res5_4.physicalSize;
        tester.view.devicePixelRatio = res5_4.dpr;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final detector = AdversarialOverflowDetector()..attach();
        addTearDown(detector.detach);

        final provider = DisplayProvider(prayerRepo: repo);
        await provider.init();
        await provider.updateSettings(
          provider.settings.copyWith(watchFaceTemplate: wf),
        );

        await tester.pumpWidget(_buildApp(const MainDashboardScreen(), provider));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(PrayerCardWidget), findsNWidgets(6));
        expect(tester.takeException(), isNull);
        detector.assertClean('5:4 $wf');
      });
    }

    testWidgets('Active Display States render with zero overflow on 5:4 (1280x1024)',
        (tester) async {
      tester.view.physicalSize = res5_4.physicalSize;
      tester.view.devicePixelRatio = res5_4.dpr;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final detector = AdversarialOverflowDetector()..attach();
      addTearDown(detector.detach);

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      // 1. Iqamah
      provider.simulateDisplayState(DisplayState.iqamahCountdown, prayer: Prayer.maghrib);
      await tester.pumpWidget(_buildApp(const IqamahCountdownScreen(), provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      detector.assertClean('5:4 IqamahCountdown');

      // 2. Adhan Alert
      provider.simulateDisplayState(DisplayState.adhanAlert, prayer: Prayer.fajr);
      await tester.pumpWidget(_buildApp(const IqamahCountdownScreen(), provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      detector.assertClean('5:4 AdhanAlert');

      // 3. Salat Blackout
      provider.simulateDisplayState(DisplayState.salatBlackout, prayer: Prayer.isha);
      await tester.pumpWidget(_buildApp(const SalatBlackoutScreen(), provider));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      detector.assertClean('5:4 SalatBlackout');

      // 4. Jumuah Khutbah
      provider.simulateDisplayState(DisplayState.jumuahKhutbah, prayer: Prayer.dhuhr);
      await tester.pumpWidget(_buildApp(const JumuahKhutbahScreen(), provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      detector.assertClean('5:4 JumuahKhutbah');

      // 5. Adhkar Carousel
      provider.triggerAdhkarOnDemand();
      await tester.pumpWidget(_buildApp(const AdhkarCarouselScreen(), provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      detector.assertClean('5:4 AdhkarCarousel');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // TASK 1B: 3:2 Aspect Ratio (1440x960)
  // ───────────────────────────────────────────────────────────────────────────
  group('Task 1B: 3:2 Aspect Ratio (1440x960) Stress Tests', () {
    const res3_2 = AdversarialResolution(
      label: '3:2 (1440x960)',
      width: 1440,
      height: 960,
    );

    for (final wf in watchFaces) {
      testWidgets('Watch face $wf renders with zero overflow on 3:2 (1440x960)',
          (tester) async {
        tester.view.physicalSize = res3_2.physicalSize;
        tester.view.devicePixelRatio = res3_2.dpr;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final detector = AdversarialOverflowDetector()..attach();
        addTearDown(detector.detach);

        final provider = DisplayProvider(prayerRepo: repo);
        await provider.init();
        await provider.updateSettings(
          provider.settings.copyWith(watchFaceTemplate: wf),
        );

        await tester.pumpWidget(_buildApp(const MainDashboardScreen(), provider));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(PrayerCardWidget), findsNWidgets(6));
        expect(tester.takeException(), isNull);
        detector.assertClean('3:2 $wf');
      });
    }

    testWidgets('Active Display States render with zero overflow on 3:2 (1440x960)',
        (tester) async {
      tester.view.physicalSize = res3_2.physicalSize;
      tester.view.devicePixelRatio = res3_2.dpr;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final detector = AdversarialOverflowDetector()..attach();
      addTearDown(detector.detach);

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      // All 5 states on 3:2
      provider.simulateDisplayState(DisplayState.iqamahCountdown, prayer: Prayer.dhuhr);
      await tester.pumpWidget(_buildApp(const IqamahCountdownScreen(), provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      detector.assertClean('3:2 IqamahCountdown');

      provider.simulateDisplayState(DisplayState.adhanAlert, prayer: Prayer.asr);
      await tester.pumpWidget(_buildApp(const IqamahCountdownScreen(), provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      detector.assertClean('3:2 AdhanAlert');

      provider.simulateDisplayState(DisplayState.salatBlackout, prayer: Prayer.maghrib);
      await tester.pumpWidget(_buildApp(const SalatBlackoutScreen(), provider));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      detector.assertClean('3:2 SalatBlackout');

      provider.simulateDisplayState(DisplayState.jumuahKhutbah, prayer: Prayer.dhuhr);
      await tester.pumpWidget(_buildApp(const JumuahKhutbahScreen(), provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      detector.assertClean('3:2 JumuahKhutbah');

      provider.triggerAdhkarOnDemand();
      await tester.pumpWidget(_buildApp(const AdhkarCarouselScreen(), provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      detector.assertClean('3:2 AdhkarCarousel');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // TASK 1C: Extreme Low Resolution (800x600, 640x480, 800x480)
  // ───────────────────────────────────────────────────────────────────────────
  group('Task 1C: Extreme Low Resolution Stress Tests (800x600, 640x480, 800x480)', () {
    const lowResMatrix = [
      AdversarialResolution(label: '800x600 (4:3 SVGA)', width: 800, height: 600),
      AdversarialResolution(label: '640x480 (4:3 VGA)', width: 640, height: 480),
      AdversarialResolution(label: '800x480 (5:3 WVGA)', width: 800, height: 480),
    ];

    for (final res in lowResMatrix) {
      for (final wf in watchFaces) {
        testWidgets('Watch face $wf on ${res.label} with zero overflow',
            (tester) async {
          tester.view.physicalSize = res.physicalSize;
          tester.view.devicePixelRatio = res.dpr;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final detector = AdversarialOverflowDetector()..attach();
          addTearDown(detector.detach);

          final provider = DisplayProvider(prayerRepo: repo);
          await provider.init();
          await provider.updateSettings(
            provider.settings.copyWith(watchFaceTemplate: wf),
          );

          await tester.pumpWidget(_buildApp(const MainDashboardScreen(), provider));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.byType(PrayerCardWidget), findsNWidgets(6));
          expect(tester.takeException(), isNull);
          detector.assertClean('${res.label} $wf');
        });
      }

      testWidgets('Iqamah countdown on ${res.label} with zero overflow',
          (tester) async {
        tester.view.physicalSize = res.physicalSize;
        tester.view.devicePixelRatio = res.dpr;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final detector = AdversarialOverflowDetector()..attach();
        addTearDown(detector.detach);

        final provider = DisplayProvider(prayerRepo: repo);
        await provider.init();
        provider.simulateDisplayState(DisplayState.iqamahCountdown, prayer: Prayer.fajr);
        await tester.pumpWidget(_buildApp(const IqamahCountdownScreen(), provider));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        detector.assertClean('${res.label} Iqamah');
      });

      testWidgets('Adhan alert pulse on ${res.label} with zero overflow',
          (tester) async {
        tester.view.physicalSize = res.physicalSize;
        tester.view.devicePixelRatio = res.dpr;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final detector = AdversarialOverflowDetector()..attach();
        addTearDown(detector.detach);

        final provider = DisplayProvider(prayerRepo: repo);
        await provider.init();
        provider.simulateDisplayState(DisplayState.adhanAlert, prayer: Prayer.dhuhr);
        await tester.pumpWidget(_buildApp(const IqamahCountdownScreen(), provider));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        detector.assertClean('${res.label} Adhan');
      });

      testWidgets('Salat blackout on ${res.label} with zero overflow',
          (tester) async {
        tester.view.physicalSize = res.physicalSize;
        tester.view.devicePixelRatio = res.dpr;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final detector = AdversarialOverflowDetector()..attach();
        addTearDown(detector.detach);

        final provider = DisplayProvider(prayerRepo: repo);
        await provider.init();
        provider.simulateDisplayState(DisplayState.salatBlackout, prayer: Prayer.asr);
        await tester.pumpWidget(_buildApp(const SalatBlackoutScreen(), provider));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        detector.assertClean('${res.label} Blackout');
      });

      testWidgets('Jumuah khutbah on ${res.label} with zero overflow',
          (tester) async {
        tester.view.physicalSize = res.physicalSize;
        tester.view.devicePixelRatio = res.dpr;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final detector = AdversarialOverflowDetector()..attach();
        addTearDown(detector.detach);

        final provider = DisplayProvider(prayerRepo: repo);
        await provider.init();
        provider.simulateDisplayState(DisplayState.jumuahKhutbah, prayer: Prayer.dhuhr);
        await tester.pumpWidget(_buildApp(const JumuahKhutbahScreen(), provider));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        detector.assertClean('${res.label} Khutbah');
      });

      testWidgets('Adhkar carousel (pages 0-3) on ${res.label} with zero overflow',
          (tester) async {
        tester.view.physicalSize = res.physicalSize;
        tester.view.devicePixelRatio = res.dpr;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final detector = AdversarialOverflowDetector()..attach();
        addTearDown(detector.detach);

        final provider = DisplayProvider(prayerRepo: repo);
        await provider.init();
        provider.triggerAdhkarOnDemand();
        await tester.pumpWidget(_buildApp(const AdhkarCarouselScreen(), provider));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        detector.assertClean('${res.label} Adhkar Page 0');

        final nextButton = find.byIcon(Icons.arrow_back_ios);
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton);
          await tester.pumpAndSettle();
          detector.assertClean('${res.label} Adhkar Page 1');

          await tester.tap(nextButton);
          await tester.pumpAndSettle();
          detector.assertClean('${res.label} Adhkar Page 2 (Ayat al-Kursi)');
        }
      });
    }
  });

  // ───────────────────────────────────────────────────────────────────────────
  // TASK 1D: High UI Scale Factors (1.25x - 1.30x) Combined with 4:3 & 5:4
  // ───────────────────────────────────────────────────────────────────────────
  group('Task 1D: High UI Scale Factors (1.25x - 1.30x) on 4:3 & 5:4', () {
    const scaleFactorStress = [1.25, 1.30];
    const resolutions = [
      Size(1024, 768), // 4:3 standard XGA
      Size(960, 720),   // 4:3 720p narrow
      Size(800, 600),   // 4:3 compact SVGA
      Size(1280, 1024), // 5:4 SXGA
    ];

    for (final scale in scaleFactorStress) {
      for (final res in resolutions) {
        final label = '${res.width.toInt()}x${res.height.toInt()} @ UI Scale ${scale}x';

        for (final wf in watchFaces) {
          testWidgets('Watch face $wf on $label with zero overflow',
              (tester) async {
            tester.view.physicalSize = res;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(() {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
            });

            final detector = AdversarialOverflowDetector()..attach();
            addTearDown(detector.detach);

            final provider = DisplayProvider(prayerRepo: repo);
            await provider.init();
            await provider.updateSettings(
              provider.settings.copyWith(
                uiScaleFactor: scale,
                watchFaceTemplate: wf,
              ),
            );

            await tester.pumpWidget(_buildApp(const MainDashboardScreen(), provider));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 500));

            expect(find.byType(PrayerCardWidget), findsNWidgets(6));
            expect(tester.takeException(), isNull);
            detector.assertClean('$label $wf');
          });
        }

        testWidgets('Iqamah countdown on $label with zero overflow',
            (tester) async {
          tester.view.physicalSize = res;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
          final detector = AdversarialOverflowDetector()..attach();
          addTearDown(detector.detach);

          final provider = DisplayProvider(prayerRepo: repo);
          await provider.init();
          await provider.updateSettings(
            provider.settings.copyWith(uiScaleFactor: scale),
          );

          provider.simulateDisplayState(DisplayState.iqamahCountdown, prayer: Prayer.isha);
          await tester.pumpWidget(_buildApp(const IqamahCountdownScreen(), provider));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          detector.assertClean('$label Iqamah');
        });

        testWidgets('Adhan alert pulse on $label with zero overflow',
            (tester) async {
          tester.view.physicalSize = res;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
          final detector = AdversarialOverflowDetector()..attach();
          addTearDown(detector.detach);

          final provider = DisplayProvider(prayerRepo: repo);
          await provider.init();
          await provider.updateSettings(
            provider.settings.copyWith(uiScaleFactor: scale),
          );

          provider.simulateDisplayState(DisplayState.adhanAlert, prayer: Prayer.maghrib);
          await tester.pumpWidget(_buildApp(const IqamahCountdownScreen(), provider));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          detector.assertClean('$label Adhan');
        });

        testWidgets('Salat blackout on $label with zero overflow',
            (tester) async {
          tester.view.physicalSize = res;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
          final detector = AdversarialOverflowDetector()..attach();
          addTearDown(detector.detach);

          final provider = DisplayProvider(prayerRepo: repo);
          await provider.init();
          await provider.updateSettings(
            provider.settings.copyWith(uiScaleFactor: scale),
          );

          provider.simulateDisplayState(DisplayState.salatBlackout, prayer: Prayer.maghrib);
          await tester.pumpWidget(_buildApp(const SalatBlackoutScreen(), provider));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          detector.assertClean('$label Blackout');
        });

        testWidgets('Jumuah khutbah on $label with zero overflow',
            (tester) async {
          tester.view.physicalSize = res;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
          final detector = AdversarialOverflowDetector()..attach();
          addTearDown(detector.detach);

          final provider = DisplayProvider(prayerRepo: repo);
          await provider.init();
          await provider.updateSettings(
            provider.settings.copyWith(uiScaleFactor: scale),
          );

          provider.simulateDisplayState(DisplayState.jumuahKhutbah, prayer: Prayer.dhuhr);
          await tester.pumpWidget(_buildApp(const JumuahKhutbahScreen(), provider));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          detector.assertClean('$label Khutbah');
        });

        testWidgets('Adhkar carousel on $label with zero overflow',
            (tester) async {
          tester.view.physicalSize = res;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
          final detector = AdversarialOverflowDetector()..attach();
          addTearDown(detector.detach);

          final provider = DisplayProvider(prayerRepo: repo);
          await provider.init();
          await provider.updateSettings(
            provider.settings.copyWith(uiScaleFactor: scale),
          );

          provider.triggerAdhkarOnDemand();
          await tester.pumpWidget(_buildApp(const AdhkarCarouselScreen(), provider));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          detector.assertClean('$label Adhkar');
        });
      }
    }
  });

  // ───────────────────────────────────────────────────────────────────────────
  // TASK 1E: Dynamic Viewport Transitions & Combinatorial Extremes
  // ───────────────────────────────────────────────────────────────────────────
  group('Task 1E: Dynamic Viewport Transitions & Content Density Stress', () {
    testWidgets('Rapid resolution resizing transitions without layout corruption or overflow',
        (tester) async {
      final transitionResolutions = [
        const Size(1920, 1080), // 16:9 1080p
        const Size(1280, 1024), // 5:4 SXGA
        const Size(800, 600),   // 4:3 SVGA
        const Size(640, 480),   // 4:3 VGA
        const Size(1440, 960),  // 3:2
        const Size(3840, 2160), // 4K UHD
        const Size(1920, 1080), // Return to 1080p
      ];

      final detector = AdversarialOverflowDetector()..attach();
      addTearDown(detector.detach);

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      for (final targetSize in transitionResolutions) {
        tester.view.physicalSize = targetSize;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(_buildApp(const MainDashboardScreen(), provider));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
        detector.assertClean('Resize transition to $targetSize');
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('Long mosque title and custom announcements at 640x480 with UI scale 1.30x',
        (tester) async {
      tester.view.physicalSize = const Size(640, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final detector = AdversarialOverflowDetector()..attach();
      addTearDown(detector.detach);

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();
      await provider.updateSettings(
        provider.settings.copyWith(
          uiScaleFactor: 1.30,
          mosqueName: 'مسجد الفتح المبين الكبير التاريخي العريق بولاية الجزائر العاصمة',
          marqueeText: 'إعلان هام: تقام صلاة الاستسقاء يوم السبت القادم بحول الله تعالى ونرجو من جميع المصلين الكرام الحضور في الموعد المحدد',
          watchFaceTemplate: 'modernHorizontal',
        ),
      );

      await tester.pumpWidget(_buildApp(const MainDashboardScreen(), provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      detector.assertClean('Extreme text density on 640x480 @ 1.30x');
    });

    testWidgets('Active Ramadan Occasion with Imsak/Iftar auxiliary labels on 4:3 at 1.30x scale',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final detector = AdversarialOverflowDetector()..attach();
      addTearDown(detector.detach);

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();
      provider.simulateOccasion(OccasionType.ramadan);
      await provider.updateSettings(
        provider.settings.copyWith(
          uiScaleFactor: 1.30,
          showFastingTimes: true,
          watchFaceTemplate: 'classicAstrolabe',
        ),
      );

      await tester.pumpWidget(_buildApp(const MainDashboardScreen(), provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('الإمساك'), findsOneWidget);
      expect(find.text('الإفطار'), findsOneWidget);
      expect(tester.takeException(), isNull);
      detector.assertClean('Ramadan on 1024x768 @ 1.30x');
    });
  });
}
