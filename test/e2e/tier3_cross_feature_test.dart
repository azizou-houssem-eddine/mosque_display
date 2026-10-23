import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tier 3: Cross-Feature Combinations (T3.1 - T3.6)', () {
    testWidgets('T3.1: Wilaya switch mid-Iqamah countdown safely recalculates state',
        (WidgetTester tester) async {
      final fakePrayerRepo = FakePrayerRepository();
      final fakeSettingsRepo = FakeSettingsRepository();
      // On 2026-10-06:
      // Alger 16: Dhuhr is 12:36. Adhan ends 12:38. Iqamah ends 12:53.
      // Oran 31: Dhuhr is 12:51.
      var currentTime = DateTime(2026, 10, 6, 12, 40); // Inside Alger Iqamah countdown

      final stateMachine = TestDisplayStateMachine(
        prayerRepository: fakePrayerRepo,
        settingsRepository: fakeSettingsRepo,
        initialTime: currentTime,
      );

      await tester.pumpWidget(MosqueE2EApp(
        stateMachine: stateMachine,
        settingsRepository: fakeSettingsRepo,
      ));
      await tester.pumpAndSettle();

      // State is Iqamah Countdown for Alger Dhuhr
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.iqamah));
      expect(stateMachine.currentState.value.targetPrayer, equals(Prayer.dhuhr));

      // Open settings, unlock, switch Wilaya to 31 (Oran)
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();
      final zeroBtn = find.byKey(const Key('btn_keypad_0'));
      for (int i = 0; i < 4; i++) {
        await tester.tap(zeroBtn);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byKey(const Key('btn_wilaya_31')));
      await tester.pumpAndSettle();

      // Close settings
      await tester.tap(find.byKey(const Key('btn_close_settings')));
      await tester.pumpAndSettle();

      // At 12:40 in Oran, Dhuhr (12:51) has NOT arrived yet!
      // The state machine must safely transition back to Standard mode counting down to Oran Dhuhr!
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.standard),
          reason: 'Switching to Oran where Dhuhr is 12:51 must revert to Standard countdown mode');
      expect(stateMachine.currentState.value.targetPrayer, equals(Prayer.dhuhr));
    });

    testWidgets('T3.2: Offset adjustment during Adhan alert state shifts subsequent timeline',
        (WidgetTester tester) async {
      final fakePrayerRepo = FakePrayerRepository();
      final fakeSettingsRepo = FakeSettingsRepository();
      // At 12:36:30 (during Dhuhr Adhan alert)
      var currentTime = DateTime(2026, 10, 6, 12, 36, 30);

      final stateMachine = TestDisplayStateMachine(
        prayerRepository: fakePrayerRepo,
        settingsRepository: fakeSettingsRepo,
        initialTime: currentTime,
      );

      await tester.pumpWidget(MosqueE2EApp(
        stateMachine: stateMachine,
        settingsRepository: fakeSettingsRepo,
      ));
      await tester.pumpAndSettle();

      expect(stateMachine.currentState.value.mode, equals(DisplayMode.adhan));

      // Adjust Dhuhr offset by +5 minutes
      final currentSettings = fakeSettingsRepo.settingsNotifier.value;
      await fakeSettingsRepo.saveSettings(
        currentSettings.copyWith(
          offsets: currentSettings.offsets.copyWith(dhuhr: 5),
        ),
      );
      await tester.pumpAndSettle();

      // Dhuhr is now 12:41. At 12:36:30, Dhuhr has not yet arrived!
      // Must smoothly transition to Standard mode counting down to 12:41
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.standard));
      expect(stateMachine.currentState.value.targetPrayer, equals(Prayer.dhuhr));
    });

    test('T3.3: Cold-boot wall-clock recovery during active Salat blackout window', () async {
      final fakePrayerRepo = FakePrayerRepository();
      final fakeSettingsRepo = FakeSettingsRepository();

      // Dhuhr is 12:36. Adhan alert ends 12:38. Iqamah ends 12:53.
      // Blackout is 12:53 to 13:13 (20 min).
      // Simulate TV cold boot at 13:00 (7 minutes into Salat Blackout).
      final coldBootTime = DateTime(2026, 10, 6, 13, 0);

      final stateMachine = TestDisplayStateMachine(
        prayerRepository: fakePrayerRepo,
        settingsRepository: fakeSettingsRepo,
        initialTime: coldBootTime,
      );

      // Force schedule load and evaluation
      stateMachine.updateTick(coldBootTime);

      // State machine must immediately enter SalatBlackoutDisplayState with 13 minutes remaining!
      final state = stateMachine.currentState.value;
      expect(state.mode, equals(DisplayMode.blackout),
          reason: 'Cold boot during prayer time must immediately resume Salat Blackout');
      expect((state as SalatBlackoutDisplayState).remainingBlackoutDuration.inMinutes,
          equals(13),
          reason: 'Remaining blackout time must be exactly 13:13 - 13:00 = 13 minutes');
    });

    testWidgets('T3.4: D-Pad settings interaction concurrent with active ticker',
        (WidgetTester tester) async {
      final fakePrayerRepo = FakePrayerRepository();
      final fakeSettingsRepo = FakeSettingsRepository();
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

      // Verify ticker text is still present in background
      expect(find.byKey(const Key('text_marquee_content')), findsOneWidget);

      // Enter PIN
      final zeroBtn = find.byKey(const Key('btn_keypad_0'));
      for (int i = 0; i < 4; i++) {
        await tester.tap(zeroBtn);
        await tester.pumpAndSettle();
      }

      // Settings open without freezing ticker
      expect(find.byKey(const Key('settings_content_panel')), findsOneWidget);
    });

    testWidgets('T3.5: Blackout mode toggle (OLED pitch black vs Dim calligraphy) updates view instantly',
        (WidgetTester tester) async {
      final fakePrayerRepo = FakePrayerRepository();
      final fakeSettingsRepo = FakeSettingsRepository();
      // 12:55 is inside Dhuhr blackout
      final blackoutTime = DateTime(2026, 10, 6, 12, 55);

      final stateMachine = TestDisplayStateMachine(
        prayerRepository: fakePrayerRepo,
        settingsRepository: fakeSettingsRepo,
        initialTime: blackoutTime,
      );

      await tester.pumpWidget(MosqueE2EApp(
        stateMachine: stateMachine,
        settingsRepository: fakeSettingsRepo,
      ));
      await tester.pumpAndSettle();

      // Default mode: OLED Pitch Black (#000000)
      expect(find.byKey(const Key('screen_salat_blackout_oled')), findsOneWidget);
      expect(find.byKey(const Key('screen_salat_blackout_dim')), findsNothing);

      // Switch to Dim Calligraphy mode
      final current = fakeSettingsRepo.settingsNotifier.value;
      await fakeSettingsRepo.saveSettings(current.copyWith(blackoutDimMode: true));
      await tester.pumpAndSettle();

      // Dim Mode rendered
      expect(find.byKey(const Key('screen_salat_blackout_dim')), findsOneWidget);
      expect(find.byKey(const Key('text_blackout_calligraphy')), findsOneWidget);
      expect(find.byKey(const Key('text_phone_silence_reminder')), findsOneWidget);
    });

    test('T3.6: Atomic multi-setting persistence round-trip saves all fields without loss', () async {
      final fakeSettingsRepo = FakeSettingsRepository();

      const complexSettings = MosqueSettings(
        selectedWilayaCode: 30, // Ouargla
        offsets: PrayerOffsets(fajr: 10, dhuhr: -5, asr: 2, maghrib: 4, isha: -8),
        iqamahDelays: IqamahDelays(fajr: 30, dhuhr: 20, asr: 15, maghrib: 7, isha: 20),
        blackoutDurationMinutes: 25,
        blackoutDimMode: true,
        hijriOffsetDays: -1,
        mosqueName: 'مسجد الهدى - ورقلة',
        marqueeText: 'تذكير: درس الفقه الأسبوعي يوم الخميس بين المغرب والعشاء',
        pinCode: '7788',
      );

      await fakeSettingsRepo.saveSettings(complexSettings);
      final loaded = await fakeSettingsRepo.loadSettings();

      expect(loaded.selectedWilayaCode, equals(30));
      expect(loaded.offsets.fajr, equals(10));
      expect(loaded.offsets.dhuhr, equals(-5));
      expect(loaded.iqamahDelays.fajr, equals(30));
      expect(loaded.iqamahDelays.maghrib, equals(7));
      expect(loaded.blackoutDurationMinutes, equals(25));
      expect(loaded.blackoutDimMode, isTrue);
      expect(loaded.hijriOffsetDays, equals(-1));
      expect(loaded.mosqueName, equals('مسجد الهدى - ورقلة'));
      expect(loaded.marqueeText, contains('درس الفقه الأسبوعي'));
      expect(loaded.pinCode, equals('7788'));
    });
  });
}
