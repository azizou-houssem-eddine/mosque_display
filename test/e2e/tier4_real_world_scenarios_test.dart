import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tier 4: Real-World Mosque Scenarios (T4.1 - T4.5)', () {
    test('T4.1: 24-Hour Continuous Mosque Lifecycle through all prayers and states', () {
      final fakePrayerRepo = FakePrayerRepository();
      final fakeSettingsRepo = FakeSettingsRepository();
      final testDate = DateTime(2026, 10, 6);

      // Initialize at 04:30 (Fajr is 05:21)
      var currentTime = DateTime(2026, 10, 6, 4, 30);
      final stateMachine = TestDisplayStateMachine(
        prayerRepository: fakePrayerRepo,
        settingsRepository: fakeSettingsRepo,
        initialTime: currentTime,
      );

      void advanceTo(int hour, int minute, [int second = 0]) {
        currentTime = DateTime(testDate.year, testDate.month, testDate.day, hour, minute, second);
        stateMachine.updateTick(currentTime);
      }

      // 1. Pre-Fajr: Standard Mode
      advanceTo(4, 30);
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.standard));
      expect(stateMachine.currentState.value.targetPrayer, equals(Prayer.fajr));

      // 2. Fajr Adhan: 05:21:00
      advanceTo(5, 21, 0);
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.adhan));
      expect(stateMachine.currentState.value.targetPrayer, equals(Prayer.fajr));

      // 3. Fajr Iqamah: 05:23:01 (Fajr delay is 20 min)
      advanceTo(5, 23, 1);
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.iqamah));
      expect(stateMachine.currentState.value.targetPrayer, equals(Prayer.fajr));

      // 4. Fajr Salat Blackout: 05:43:01 (20 min duration)
      advanceTo(5, 43, 1);
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.blackout));

      // 5. Post-Fajr Standard: 06:03:01 -> Next is Sunrise (06:47)
      advanceTo(6, 3, 1);
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.standard));
      expect(stateMachine.currentState.value.targetPrayer, equals(Prayer.sunrise));

      // 6. Post-Sunrise Standard: 06:48:00 -> Next is Dhuhr (12:36)
      advanceTo(6, 48, 0);
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.standard));
      expect(stateMachine.currentState.value.targetPrayer, equals(Prayer.dhuhr));

      // 7. Dhuhr Adhan: 12:36:00
      advanceTo(12, 36, 0);
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.adhan));
      expect(stateMachine.currentState.value.targetPrayer, equals(Prayer.dhuhr));

      // 8. Dhuhr Iqamah: 12:38:01 (15 min delay)
      advanceTo(12, 38, 1);
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.iqamah));

      // 9. Dhuhr Salat Blackout: 12:53:01 (20 min)
      advanceTo(12, 53, 1);
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.blackout));

      // 10. Post-Dhuhr Standard: 13:13:01 -> Next is Asr (15:54)
      advanceTo(13, 13, 1);
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.standard));
      expect(stateMachine.currentState.value.targetPrayer, equals(Prayer.asr));

      // 11. Asr Adhan: 15:54:00
      advanceTo(15, 54, 0);
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.adhan));

      // 12. Asr Iqamah: 15:56:01 -> Blackout: 16:11:01 -> Post-Asr: 16:31:01 (Maghrib 18:24)
      advanceTo(16, 31, 1);
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.standard));
      expect(stateMachine.currentState.value.targetPrayer, equals(Prayer.maghrib));

      // 13. Maghrib Adhan: 18:24:00
      advanceTo(18, 24, 0);
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.adhan));

      // 14. Maghrib Iqamah: 18:26:01 (strict 5 min delay)
      advanceTo(18, 26, 1);
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.iqamah));

      // 15. Maghrib Salat Blackout: 18:31:01 (20 min)
      advanceTo(18, 31, 1);
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.blackout));

      // 16. Post-Maghrib Standard: 18:51:01 -> Next is Isha (19:45)
      advanceTo(18, 51, 1);
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.standard));
      expect(stateMachine.currentState.value.targetPrayer, equals(Prayer.isha));

      // 17. Isha Adhan: 19:45:00
      advanceTo(19, 45, 0);
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.adhan));

      // 18. Isha Iqamah: 19:47:01 (15 min delay) -> Blackout: 20:02:01 (20 min)
      advanceTo(20, 2, 1);
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.blackout));

      // 19. Post-Isha Night Standard: 20:22:01 -> Next is tomorrow's Fajr
      advanceTo(20, 22, 1);
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.standard));
      expect(stateMachine.currentState.value.targetPrayer, equals(Prayer.fajr));
    });

    test('T4.2: Jumu\'ah (Friday Prayer) schedule preserves prayer state consistency', () {
      final fakePrayerRepo = FakePrayerRepository();
      final fakeSettingsRepo = FakeSettingsRepository();
      // Friday 2026-10-09
      final fridayDate = DateTime(2026, 10, 9, 12, 0);
      expect(fridayDate.weekday, equals(DateTime.friday));

      final stateMachine = TestDisplayStateMachine(
        prayerRepository: fakePrayerRepo,
        settingsRepository: fakeSettingsRepo,
        initialTime: fridayDate,
      );

      final state = stateMachine.currentState.value;
      expect(state.mode, equals(DisplayMode.standard));
      expect(state.targetPrayer, equals(Prayer.dhuhr));
    });

    test('T4.3: Ramadan Timing & Strict Maliki 5-minute Maghrib Iqamah Window', () {
      final fakePrayerRepo = FakePrayerRepository();
      final fakeSettingsRepo = FakeSettingsRepository();
      // Maghrib enters at 18:24. Adhan alert ends 18:26.
      // At 18:30:15 (4 min 15 sec into 5-minute Iqamah countdown, 45s remaining)
      final nearIqamahTime = DateTime(2026, 10, 6, 18, 30, 15);

      final stateMachine = TestDisplayStateMachine(
        prayerRepository: fakePrayerRepo,
        settingsRepository: fakeSettingsRepo,
        initialTime: nearIqamahTime,
      );

      final state = stateMachine.currentState.value;
      expect(state.mode, equals(DisplayMode.iqamah));
      final iqamahState = state as IqamahCountdownDisplayState;

      // Verify remaining seconds < 60 (amber alert phase)
      expect(iqamahState.remainingIqamahDuration.inSeconds, lessThan(60),
          reason: 'Maghrib remaining Iqamah under 60 seconds triggers amber alert');
    });

    test('T4.4: Sudden TV Reboot Recovery during Dhuhr Iqamah Countdown', () {
      final fakePrayerRepo = FakePrayerRepository();
      final fakeSettingsRepo = FakeSettingsRepository();

      // Dhuhr is 12:36. Adhan alert ends 12:38. Iqamah ends 12:53 (15 min delay).
      // TV crashes and reboots at 12:45:00 (7 minutes into Iqamah countdown).
      final rebootTime = DateTime(2026, 10, 6, 12, 45, 0);

      final stateMachine = TestDisplayStateMachine(
        prayerRepository: fakePrayerRepo,
        settingsRepository: fakeSettingsRepo,
        initialTime: rebootTime,
      );

      // Wall-clock recovery immediately restores Iqamah countdown state
      final state = stateMachine.currentState.value;
      expect(state.mode, equals(DisplayMode.iqamah),
          reason: 'State machine must immediately recover to Iqamah countdown upon reboot');
      expect((state as IqamahCountdownDisplayState).remainingIqamahDuration.inMinutes,
          equals(8),
          reason: 'Remaining Iqamah must be 12:53 - 12:45 = 8 minutes');
    });

    test('T4.5: Year-long offline autonomous calculation without network', () {
      // Test 12 sample dates across all 12 months for Wilaya 16 (Alger)
      for (int month = 1; month <= 12; month++) {
        final sampleDate = DateTime(2026, month, 15);
        final schedule = ReferenceMethod19Calculator.calculate(
          latitude: 36.7538,
          longitude: 3.0588,
          date: sampleDate,
        );

        expect(schedule.fajr.isBefore(schedule.sunrise), isTrue);
        expect(schedule.sunrise.isBefore(schedule.dhuhr), isTrue);
        expect(schedule.dhuhr.isBefore(schedule.asr), isTrue);
        expect(schedule.asr.isBefore(schedule.maghrib), isTrue);
        expect(schedule.maghrib.isBefore(schedule.isha), isTrue);
      }
    });
  });
}
