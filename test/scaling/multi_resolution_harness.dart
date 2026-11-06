import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mosque_display/core/theme/app_theme.dart';
import 'package:mosque_display/core/providers/display_provider.dart';
import 'package:mosque_display/data/repositories/prayer_repository.dart';
import 'package:mosque_display/data/models/prayer_schedule.dart';
import 'package:mosque_display/data/models/wilaya.dart';
import 'package:mosque_display/data/models/commune.dart';
import 'package:mosque_display/data/models/prayer_offsets.dart';
import 'resolution_matrix.dart';
import 'overflow_assertion.dart';

class MockPrayerRepo implements IPrayerRepository {
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

Widget buildScalingTestApp({
  required Widget child,
  required DisplayProvider provider,
}) {
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

/// Parameterized multi-resolution test runner creating isolated testWidgets per resolution.
void testMultiResolution(
  String description, {
  List<TvResolution> resolutions = coreTvResolutions,
  required Future<void> Function(WidgetTester tester, TvResolution res) testBody,
}) {
  for (final res in resolutions) {
    testWidgets('$description ($res)', (tester) async {
      tester.view.physicalSize = res.physicalSize;
      tester.view.devicePixelRatio = res.devicePixelRatio;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final overflowTracker = OverflowReport();
      overflowTracker.attach();
      addTearDown(() => overflowTracker.detach());

      await testBody(tester, res);

      expectZeroLayoutOverflow(tester,
          reason: 'Zero exceptions expected on $res');
      overflowTracker.assertZeroOverflow(res.toString());
    });
  }
}
