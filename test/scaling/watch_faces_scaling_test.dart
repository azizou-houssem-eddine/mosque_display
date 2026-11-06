import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mosque_display/core/providers/display_provider.dart';
import 'package:mosque_display/ui/screens/main_dashboard_screen.dart';
import 'package:mosque_display/ui/widgets/prayer_card_widget.dart';
import 'resolution_matrix.dart';
import 'multi_resolution_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const watchFaces = [
    'classicAstrolabe',
    'modernHorizontal',
    'grandClock',
    'traditionalMinbar',
  ];

  for (final template in watchFaces) {
    group('Watch Face: $template Scaling Verification', () {
      late MockPrayerRepo repo;

      setUp(() {
        SharedPreferences.setMockInitialValues({});
        repo = MockPrayerRepo();
      });

      testMultiResolution(
        'Renders $template cleanly with 0 overflow',
        resolutions: coreTvResolutions,
        testBody: (tester, res) async {
          final provider = DisplayProvider(prayerRepo: repo);
          await provider.init();
          await provider.updateSettings(
            provider.settings.copyWith(watchFaceTemplate: template),
          );

          await tester.pumpWidget(buildScalingTestApp(
            child: const MainDashboardScreen(),
            provider: provider,
          ));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Verifications
          expect(find.byType(PrayerCardWidget), findsNWidgets(6));
          expect(find.text('الفجر'), findsAtLeastNWidgets(1));
          expect(find.text('الظهر'), findsAtLeastNWidgets(1));
          expect(find.text('العصر'), findsAtLeastNWidgets(1));
          expect(find.text('المغرب'), findsAtLeastNWidgets(1));
          expect(find.text('العشاء'), findsAtLeastNWidgets(1));
        },
      );
    });
  }
}
