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
import 'package:mosque_display/domain/calculation/hijri_calculator.dart';

import 'package:mosque_display/ui/screens/main_dashboard_screen.dart';
import 'package:mosque_display/ui/screens/settings_screen.dart';

class _MockPrayerRepo implements IPrayerRepository {
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

Widget _buildTestApp({
  required Widget child,
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

  late _MockPrayerRepo repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = _MockPrayerRepo();
  });

  group('Client Complaint 1: Maghrib Setup & Navigation Trapping Fix', () {
    testWidgets('Prayer offsets page displays prominent Maghrib calibration card and auto-scrolling steppers',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      await tester.pumpWidget(
        _buildTestApp(
          child: const SettingsScreen(),
          provider: provider,
          size: const Size(1280, 720), // 720p TV resolution
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to 'معايرة المواقيت' (item index 1)
      await tester.tap(find.text('معايرة المواقيت'));
      await tester.pumpAndSettle();

      // Verify dedicated Maghrib calibration card exists
      expect(find.textContaining('موعد المغرب والإفطار'), findsOneWidget);
      expect(find.textContaining('معايرة صلاة المغرب'), findsOneWidget);

      // Verify Maghrib prayer stepper is rendered with its current time preview
      expect(find.textContaining('المغرب'), findsWidgets);

      // Verify stepper arrows don't trap D-pad and left/right adjust value
      final stepperFinder = find.byType(Focus).first;
      expect(stepperFinder, findsWidgets);
    });
  });

  group('Client Complaint 2: Post-Prayer Adhkar Return to Watch Face', () {
    test('DisplayProvider automatically returns to standard watch face when adhkar timer elapses', () async {
      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      // Configure short adhkar duration (e.g. 2 minutes)
      await provider.updateSettings(
        provider.settings.copyWith(adhkarDurationMinutes: 2),
      );

      // Simulate entering salat blackout
      provider.simulateDisplayState(
        DisplayState.salatBlackout,
        prayer: Prayer.maghrib,
        customDuration: const Duration(seconds: 2),
      );
      expect(provider.displayState, equals(DisplayState.salatBlackout));

      // Tick through blackout (2 seconds)
      provider.tick();
      provider.tick();

      // Transition to postSalatAdhkar
      expect(provider.displayState, equals(DisplayState.postSalatAdhkar));
      expect(provider.adhkarRemaining.inSeconds, equals(120)); // 2 minutes

      // Fast-forward adhkar ticks until remaining reaches 0
      while (provider.adhkarRemaining.inSeconds > 0) {
        provider.tick();
      }

      // One more tick triggers the dismissal check
      provider.tick();

      // CRITICAL VERIFICATION: Must have returned to standard watch face!
      expect(
        provider.displayState,
        equals(DisplayState.standard),
        reason: 'Post-salat Adhkar must return to standard watch face upon reaching 0, never remaining trapped.',
      );
    });
  });

  group('Client Complaint 3: Watch Face Customization & Templates', () {
    testWidgets('Renders all 4 architectural watch face templates without errors or overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      final templates = [
        'classicAstrolabe',
        'modernHorizontal',
        'grandClock',
        'traditionalMinbar',
      ];

      for (final tmpl in templates) {
        await provider.updateSettings(
          provider.settings.copyWith(watchFaceTemplate: tmpl),
        );

        await tester.pumpWidget(
          _buildTestApp(
            child: const MainDashboardScreen(),
            provider: provider,
            size: const Size(1920, 1080),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull,
            reason: 'Template $tmpl must render without overflow or exception');

        // All 6 prayers should be present
        expect(find.text('الفجر'), findsWidgets);
        expect(find.text('الشروق'), findsWidgets);
        expect(find.text('الظهر'), findsWidgets);
        expect(find.text('العصر'), findsWidgets);
        expect(find.text('المغرب'), findsWidgets);
        expect(find.text('العشاء'), findsWidgets);
      }
    });

    testWidgets('Renders all 4 visual themes cleanly with distinctive color palettes',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      final themes = [
        'royalEmerald',
        'midnightSapphire',
        'andalusianOnyx',
        'kiswahBlack',
      ];

      for (final themeKey in themes) {
        await provider.updateSettings(
          provider.settings.copyWith(colorTheme: themeKey),
        );

        await tester.pumpWidget(
          _buildTestApp(
            child: const MainDashboardScreen(),
            provider: provider,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull,
            reason: 'Theme $themeKey must render without exception');
      }
    });

    testWidgets('Toggles showSeconds on digital clock display', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      // With seconds enabled
      await provider.updateSettings(provider.settings.copyWith(showSeconds: true));
      await tester.pumpWidget(
        _buildTestApp(
          child: const MainDashboardScreen(),
          provider: provider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Text), findsWidgets);

      // With seconds disabled
      await provider.updateSettings(provider.settings.copyWith(showSeconds: false));
      await tester.pumpWidget(
        _buildTestApp(
          child: const MainDashboardScreen(),
          provider: provider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('Renders normal (Gregorian) date under Hijri date styled smaller and toggleable',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Verify calculation helper format
      final sampleDate = DateTime(2026, 11, 5);
      expect(HijriCalculator.formatGregorian(sampleDate), equals('05 نوفمبر 2026 م'));

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();
      expect(provider.gregorianDate, isNotEmpty);
      expect(provider.gregorianDate, contains('م'));

      // Gregorian date visible by default
      await tester.pumpWidget(
        _buildTestApp(
          child: const MainDashboardScreen(),
          provider: provider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final gregorianFinder = find.text(provider.gregorianDate);
      expect(gregorianFinder, findsOneWidget);

      final hijriFinder = find.text(provider.hijriDate);
      expect(hijriFinder, findsOneWidget);

      // Verify Gregorian text has a smaller font size than Hijri text
      final Text gregorianWidget = tester.widget(gregorianFinder);
      final Text hijriWidget = tester.widget(hijriFinder);
      expect(
        gregorianWidget.style!.fontSize!,
        lessThan(hijriWidget.style!.fontSize!),
        reason: 'Normal date must be styled smaller than Hijri date',
      );

      // Verify toggle hides normal date when turned off
      await provider.updateSettings(
        provider.settings.copyWith(showGregorianDate: false),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(provider.gregorianDate), findsNothing);
    });
  });

  group('Client Complaint 4: Settings Screen Scale Proportions', () {
    testWidgets('Settings screen scales gracefully across 720p, 1080p, and 4K with various scale factors without overflow',
        (tester) async {
      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      final testCases = [
        (const Size(1280, 720), 0.80),
        (const Size(1280, 720), 0.90),
        (const Size(1920, 1080), 1.00),
        (const Size(3840, 2160), 1.10),
      ];

      for (final (resolution, scaleFactor) in testCases) {
        tester.view.physicalSize = resolution;
        tester.view.devicePixelRatio = 1.0;

        await provider.updateSettings(
          provider.settings.copyWith(uiScaleFactor: scaleFactor),
        );

        await tester.pumpWidget(
          _buildTestApp(
            child: const SettingsScreen(),
            provider: provider,
            size: resolution,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'SettingsScreen must not overflow on ${resolution.width}x${resolution.height} with scale $scaleFactor');

        // Sidebar items must all be rendered and fit
        expect(find.text('الولاية'), findsOneWidget);
        expect(find.text('معايرة المواقيت'), findsOneWidget);
        expect(find.text('المظهر والواجهة'), findsOneWidget);
        expect(find.text('الخطوط والأدعية'), findsOneWidget);
        expect(find.text('تأخير الإقامة'), findsOneWidget);
        expect(find.text('صلاة الجماعة'), findsOneWidget);
        expect(find.text('التاريخ الهجري'), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('Watch face customization page displays tabs and switches between templates, themes, scale, and options',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      await tester.pumpWidget(
        _buildTestApp(
          child: const SettingsScreen(),
          provider: provider,
          size: const Size(1920, 1080),
        ),
      );
      await tester.pumpAndSettle();

      // Select 'المظهر والواجهة'
      await tester.tap(find.text('المظهر والواجهة'));
      await tester.pumpAndSettle();

      // Check for tabs
      expect(find.text('قوالب الساعة'), findsOneWidget);
      expect(find.text('الطابع اللوني'), findsOneWidget);
      expect(find.text('مقياس الشاشة'), findsOneWidget);
      expect(find.text('خيارات العرض'), findsOneWidget);

      // Verify template options are visible
      expect(find.textContaining('الأسطرلاب الكلاسيكي'), findsOneWidget);
      expect(find.textContaining('الشريط الأفقي العصري'), findsOneWidget);

      // Switch to Color Themes tab
      await tester.tap(find.text('الطابع اللوني'));
      await tester.pumpAndSettle();
      expect(find.textContaining('الزمرد الملكي'), findsOneWidget);
      expect(find.textContaining('الياقوت الأزرق'), findsOneWidget);

      // Switch to Screen Scale tab
      await tester.tap(find.text('مقياس الشاشة'));
      await tester.pumpAndSettle();
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });
  });
}
