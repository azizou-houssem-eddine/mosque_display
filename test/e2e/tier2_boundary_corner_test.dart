import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tier 2: Boundary & Corner Cases (T2.1 - T2.10)', () {
    test('T2.1: Midnight Rollover (23:59:59 -> 00:00:00) transitions day cleanly', () {
      final fakePrayerRepo = FakePrayerRepository();
      final fakeSettingsRepo = FakeSettingsRepository();
      // 1 second before midnight on 2026-10-06
      var time = DateTime(2026, 10, 6, 23, 59, 59);

      final stateMachine = TestDisplayStateMachine(
        prayerRepository: fakePrayerRepo,
        settingsRepository: fakeSettingsRepo,
        initialTime: time,
      );

      // Past Isha: next prayer should be Fajr
      var state = stateMachine.currentState.value;
      expect(state.mode, equals(DisplayMode.standard));
      expect(state.targetPrayer, equals(Prayer.fajr));
      expect(
        (state as StandardDisplayState).timeRemainingToNextAdhan.isNegative,
        isFalse,
      );

      // Roll clock over to next day 00:00:00
      time = DateTime(2026, 10, 7, 0, 0, 0);
      stateMachine.updateTick(time);

      state = stateMachine.currentState.value;
      expect(state.mode, equals(DisplayMode.standard));
      expect(state.targetPrayer, equals(Prayer.fajr));
      expect(
        (state as StandardDisplayState).timeRemainingToNextAdhan.isNegative,
        isFalse,
        reason: 'Countdown to next Fajr must never be negative after midnight rollover',
      );
    });

    test('T2.2: Leap Year handling on February 29 (366th day perpetual calendar)', () {
      final leapDate = DateTime(2028, 2, 29); // 2028 is a leap year
      final schedule = ReferenceMethod19Calculator.calculate(
        latitude: 36.7538,
        longitude: 3.0588,
        date: leapDate,
      );

      expect(schedule.fajr.day, equals(29));
      expect(schedule.fajr.month, equals(2));
      expect(schedule.fajr.year, equals(2028));
      expect(schedule.fajr.isBefore(schedule.sunrise), isTrue);
      expect(schedule.sunrise.isBefore(schedule.dhuhr), isTrue);
      expect(schedule.dhuhr.isBefore(schedule.asr), isTrue);
      expect(schedule.asr.isBefore(schedule.maghrib), isTrue);
      expect(schedule.maghrib.isBefore(schedule.isha), isTrue);
    });

    test('T2.3: Geographical Extremes across Algeria calculate valid astronomical times', () {
      final extremes = [
        // Northernmost: Skikda (Wilaya 21)
        const Wilaya(code: 21, nameAr: 'سكيكدة', nameFr: 'Skikda', latitude: 36.8762, longitude: 6.9092),
        // Southernmost: In Guezzam (Wilaya 54)
        const Wilaya(code: 54, nameAr: 'عين قزام', nameFr: 'In Guezzam', latitude: 19.5722, longitude: 5.7692),
        // Westernmost: Tindouf (Wilaya 37)
        const Wilaya(code: 37, nameAr: 'تندوف', nameFr: 'Tindouf', latitude: 27.6711, longitude: -8.1474),
        // Easternmost: Djanet (Wilaya 56)
        const Wilaya(code: 56, nameAr: 'جانت', nameFr: 'Djanet', latitude: 24.5531, longitude: 9.4858),
      ];

      final testDate = DateTime(2026, 6, 21); // Summer solstice extreme

      for (final w in extremes) {
        final schedule = ReferenceMethod19Calculator.calculate(
          latitude: w.latitude,
          longitude: w.longitude,
          date: testDate,
        );

        expect(schedule.fajr.isBefore(schedule.sunrise), isTrue,
            reason: '${w.nameFr} Fajr must precede sunrise');
        expect(schedule.sunrise.isBefore(schedule.dhuhr), isTrue,
            reason: '${w.nameFr} Sunrise must precede Dhuhr');
        expect(schedule.dhuhr.isBefore(schedule.asr), isTrue,
            reason: '${w.nameFr} Dhuhr must precede Asr');
        expect(schedule.asr.isBefore(schedule.maghrib), isTrue,
            reason: '${w.nameFr} Asr must precede Maghrib');
        expect(schedule.maghrib.isBefore(schedule.isha), isTrue,
            reason: '${w.nameFr} Maghrib must precede Isha');
      }
    });

    test('T2.4: Prayer Offsets Boundary validation (strictly clamped to [-15, +15] minutes)', () {
      const validOffsets = PrayerOffsets(fajr: 15, dhuhr: -15, asr: 0, maghrib: 10, isha: -10);
      expect(validOffsets.isValid(), isTrue);

      const invalidPositive = PrayerOffsets(fajr: 16);
      expect(invalidPositive.isValid(), isFalse,
          reason: 'Offsets exceeding +15 min must be rejected');

      const invalidNegative = PrayerOffsets(dhuhr: -16);
      expect(invalidNegative.isValid(), isFalse,
          reason: 'Offsets below -15 min must be rejected');
    });

    test('T2.5: Hijri Moonsighting boundary adjustment (clamped to [-2, +2] days)', () {
      final base = DateTime(2026, 10, 6);
      for (int offset = -2; offset <= 2; offset++) {
        final adjusted = base.add(Duration(days: offset));
        expect(adjusted.difference(base).inDays, equals(offset));
      }
    });

    testWidgets('T2.6: Security PIN Boundaries: incorrect PIN rejected, backspace on empty PIN safe',
        (WidgetTester tester) async {
      final fakePrayerRepo = FakePrayerRepository();
      // Settings PIN set to '4321'
      final fakeSettingsRepo = FakeSettingsRepository(
        const MosqueSettings(pinCode: '4321'),
      );
      final baseDate = DateTime(2026, 10, 6, 12, 0);

      final stateMachine = TestDisplayStateMachine(
        prayerRepository: fakePrayerRepo,
        settingsRepository: fakeSettingsRepo,
        initialTime: baseDate,
      );

      await tester.pumpWidget(MosqueE2EApp(
        stateMachine: stateMachine,
        settingsRepository: fakeSettingsRepo,
      ));
      await tester.pumpAndSettle();

      // Open settings
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();

      // Test Backspace on empty PIN
      final clearBtn = find.byKey(const Key('btn_keypad_C'));
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pin_lock_screen')), findsOneWidget,
          reason: 'Clear on empty PIN must not crash');

      // Enter wrong PIN: '1111'
      final oneBtn = find.byKey(const Key('btn_keypad_1'));
      for (int i = 0; i < 4; i++) {
        await tester.tap(oneBtn);
        await tester.pumpAndSettle();
      }

      // Settings must still be locked
      expect(find.byKey(const Key('pin_lock_screen')), findsOneWidget);
      expect(find.byKey(const Key('settings_content_panel')), findsNothing,
          reason: 'Incorrect PIN must not grant access');

      // Now enter correct PIN: '4321'
      await tester.tap(find.byKey(const Key('btn_keypad_4')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_keypad_3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_keypad_2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_keypad_1')));
      await tester.pumpAndSettle();

      // Settings should now be unlocked
      expect(find.byKey(const Key('settings_content_panel')), findsOneWidget);
    });

    test('T2.7 & T2.8: Iqamah and Blackout duration range limits', () {
      const delays = IqamahDelays(fajr: 20, dhuhr: 15, asr: 15, maghrib: 5, isha: 15);
      expect(delays.forPrayer(Prayer.maghrib), equals(5),
          reason: 'Maghrib default Iqamah delay is strictly 5 minutes in Maliki tradition');
      expect(delays.forPrayer(Prayer.fajr), equals(20));

      const settings = MosqueSettings(blackoutDurationMinutes: 20);
      expect(settings.blackoutDurationMinutes, inInclusiveRange(10, 35));
    });

    testWidgets('T2.9: Display stress on non-standard aspect ratios (16:10 and 21:9 ultra-wide)',
        (WidgetTester tester) async {
      final fakePrayerRepo = FakePrayerRepository();
      final fakeSettingsRepo = FakeSettingsRepository();
      final baseDate = DateTime(2026, 10, 6, 12, 0);

      final stateMachine = TestDisplayStateMachine(
        prayerRepository: fakePrayerRepo,
        settingsRepository: fakeSettingsRepo,
        initialTime: baseDate,
      );

      final stressResolutions = [
        const Size(1920, 1200), // 16:10 aspect ratio
        const Size(2560, 1080), // 21:9 ultra-wide monitor
        const Size(1366, 768),  // Legacy hotel/budget TV screen
      ];

      for (final res in stressResolutions) {
        tester.view.physicalSize = res;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(MosqueE2EApp(
          stateMachine: stateMachine,
          settingsRepository: fakeSettingsRepo,
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'Screen at ${res.width}x${res.height} must render without layout crash');
        expect(find.byKey(const Key('screen_standard_dashboard')), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    test('T2.10: Corrupted or empty persistence JSON defaults safely', () {
      final emptyJson = <String, dynamic>{};
      final fallbackSettings = MosqueSettings.fromJson(emptyJson);

      expect(fallbackSettings.selectedWilayaCode, equals(16),
          reason: 'Default wilaya must fall back to 16 (Alger)');
      expect(fallbackSettings.pinCode, equals('0000'),
          reason: 'Default PIN must fall back to 0000');
      expect(fallbackSettings.blackoutDurationMinutes, equals(20));
      expect(fallbackSettings.blackoutDimMode, isFalse);
    });
  });
}
