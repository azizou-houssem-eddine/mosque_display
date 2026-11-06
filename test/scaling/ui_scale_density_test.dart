import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mosque_display/core/providers/display_provider.dart';
import 'package:mosque_display/ui/screens/main_dashboard_screen.dart';
import 'resolution_matrix.dart';
import 'multi_resolution_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPrayerRepo repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = MockPrayerRepo();
  });

  group('UI Scale Factor Scaling Suite (0.8x - 1.2x)', () {
    const scaleFactors = [0.8, 0.9, 1.0, 1.1, 1.2];

    for (final factor in scaleFactors) {
      testWidgets(
          'Dashboard renders cleanly at UI scale factor $factor on 1080p',
          (tester) async {
        final provider = DisplayProvider(prayerRepo: repo);
        await provider.init();
        await provider.updateSettings(
          provider.settings.copyWith(uiScaleFactor: factor),
        );

        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildScalingTestApp(
          child: const MainDashboardScreen(),
          provider: provider,
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('الفجر'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
          'Dashboard renders cleanly at UI scale factor $factor on 4:3 (1024x768)',
          (tester) async {
        final provider = DisplayProvider(prayerRepo: repo);
        await provider.init();
        await provider.updateSettings(
          provider.settings.copyWith(uiScaleFactor: factor),
        );

        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildScalingTestApp(
          child: const MainDashboardScreen(),
          provider: provider,
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('الفجر'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Device Pixel Ratio Density Suite (1.5x, 2.0x, 3.0x)', () {
    testMultiResolution(
      'Dashboard renders cleanly across Android TV DPR density variations',
      resolutions: tvDensityResolutions,
      testBody: (tester, res) async {
        final provider = DisplayProvider(prayerRepo: repo);
        await provider.init();

        await tester.pumpWidget(buildScalingTestApp(
          child: const MainDashboardScreen(),
          provider: provider,
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('الفجر'), findsOneWidget);
        expect(find.text('العشاء'), findsOneWidget);
      },
    );
  });
}
