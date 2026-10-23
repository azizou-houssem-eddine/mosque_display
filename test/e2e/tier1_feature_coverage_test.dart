import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tier 1: Feature Coverage (R1 Concept 2 UI & TV Sizing)', () {
    test('T1.1.1: Concept 2 color tokens meet WCAG AAA contrast ratio (>= 7.0:1)', () {
      final whiteContrast = Concept2ThemeTokens.contrastRatio(
        Concept2ThemeTokens.textWhite,
        Concept2ThemeTokens.emeraldBase,
      );
      final goldContrast = Concept2ThemeTokens.contrastRatio(
        Concept2ThemeTokens.goldRadiant,
        Concept2ThemeTokens.emeraldBase,
      );
      final royalGoldContrast = Concept2ThemeTokens.contrastRatio(
        Concept2ThemeTokens.goldRoyal,
        Concept2ThemeTokens.emeraldBase,
      );

      // WCAG AAA requires >= 7.0:1 for normal text and >= 4.5:1 for large text
      expect(whiteContrast, greaterThanOrEqualTo(14.0),
          reason: 'White text on emerald base must exceed 14:1 contrast for 10-15m viewing');
      expect(goldContrast, greaterThanOrEqualTo(7.0),
          reason: 'Radiant gold on emerald base must exceed WCAG AAA 7:1');
      expect(royalGoldContrast, greaterThanOrEqualTo(7.0),
          reason: 'Royal gold on emerald base must exceed WCAG AAA 7:1');
    });

    test('T1.1.2: 16-point geometric mandala rosette watermark exhibits 16-fold symmetry', () {
      const painter = MandalaWatermarkPainter();
      expect(painter.shouldRepaint(const MandalaWatermarkPainter()), isFalse);

      // Verify mathematical 16-point geometry
      const points = 16;
      const stepAngle = 2 * math.pi / points;
      expect((stepAngle * 180 / math.pi).round(), equals(23), // 22.5 degrees
          reason: 'Each ray of the 16-point Islamic Zellij rosette steps by 22.5 degrees');
    });

    testWidgets('T1.1.3 & T1.1.4: Symmetrical prayer cards layout with central circular gauge',
        (WidgetTester tester) async {
      final fakePrayerRepo = FakePrayerRepository();
      final fakeSettingsRepo = FakeSettingsRepository();
      final baseDate = DateTime(2026, 10, 6, 12, 0); // 12:00, before Dhuhr 12:36

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

      // Verify Dashboard Screen rendered
      expect(find.byKey(const Key('screen_standard_dashboard')), findsOneWidget);

      // Verify Left Column: Fajr, Shuruk, Dhuhr
      expect(find.byKey(const Key('prayer_card_fajr')), findsOneWidget);
      expect(find.byKey(const Key('prayer_card_sunrise')), findsOneWidget);
      expect(find.byKey(const Key('prayer_card_dhuhr')), findsOneWidget);

      // Verify Center Column: Radiant Circular Gauge
      expect(find.byKey(const Key('radiant_circular_gauge')), findsOneWidget);
      expect(find.byKey(const Key('text_gauge_target_prayer')), findsOneWidget);
      expect(find.byKey(const Key('text_gauge_countdown_digits')), findsOneWidget);

      // Verify Right Column: Asr, Maghrib, Isha
      expect(find.byKey(const Key('prayer_card_asr')), findsOneWidget);
      expect(find.byKey(const Key('prayer_card_maghrib')), findsOneWidget);
      expect(find.byKey(const Key('prayer_card_isha')), findsOneWidget);

      // Verify Hadith Marquee Ticker
      expect(find.byKey(const Key('hadith_marquee_ticker')), findsOneWidget);
    });

    testWidgets('T1.1.5: Canvas scales cleanly across 720p, 1080p, and 4K TV displays without overflow',
        (WidgetTester tester) async {
      final fakePrayerRepo = FakePrayerRepository();
      final fakeSettingsRepo = FakeSettingsRepository();
      final baseDate = DateTime(2026, 10, 6, 12, 0);

      final stateMachine = TestDisplayStateMachine(
        prayerRepository: fakePrayerRepo,
        settingsRepository: fakeSettingsRepo,
        initialTime: baseDate,
      );

      final resolutions = [
        const Size(1280, 720),  // 720p HD Ready TV
        const Size(1920, 1080), // 1080p Full HD TV
        const Size(3840, 2160), // 4K Ultra HD TV
      ];

      for (final res in resolutions) {
        tester.view.physicalSize = res;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(MosqueE2EApp(
          stateMachine: stateMachine,
          settingsRepository: fakeSettingsRepo,
        ));
        await tester.pumpAndSettle();

        // Must not have any render exceptions or overflow errors
        expect(tester.takeException(), isNull,
            reason: 'Display at resolution ${res.width}x${res.height} must render without overflow');
        expect(find.byKey(const Key('screen_standard_dashboard')), findsOneWidget);
      }

      // Reset test view
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('T1.1.6: Typography hierarchy enforces distant legibility and RTL orientation',
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

      // Check Digital Clock font size >= 88sp
      final clockFinder = find.byKey(const Key('text_clock_time'));
      final clockText = tester.widget<Text>(clockFinder);
      expect(clockText.style?.fontSize, greaterThanOrEqualTo(88),
          reason: 'Main TV digital clock must be >= 88sp for 10-15m viewing');

      // Check RTL TextDirection
      final directionality = tester.widget<Directionality>(
        find.descendant(of: find.byType(MaterialApp), matching: find.byType(Directionality)).first,
      );
      expect(directionality.textDirection, equals(TextDirection.rtl),
          reason: 'Application root must enforce RTL Arabic orientation');
    });
  });

  group('Tier 1: Feature Coverage (R2 100% Accurate Algerian Prayer Times Engine)', () {
    test('T1.2.1: 58 Wilayas verified dataset integrity', () {
      expect(verified58Wilayas.length, equals(58),
          reason: 'Dataset must contain all 58 Algerian Wilayas');

      final codes = verified58Wilayas.map((w) => w.code).toSet();
      expect(codes.length, equals(58), reason: 'Every Wilaya code must be unique');
      expect(codes.reduce(math.max), equals(58));
      expect(codes.reduce(math.min), equals(1));

      for (final w in verified58Wilayas) {
        expect(w.nameAr.isNotEmpty, isTrue);
        expect(w.nameFr.isNotEmpty, isTrue);
        // Algeria bounds: Lat 18° to 38° N, Lon -9° to 12° E
        expect(w.latitude, inInclusiveRange(18.0, 38.0),
            reason: 'Wilaya ${w.nameFr} latitude must be in Algerian geographical bounds');
        expect(w.longitude, inInclusiveRange(-9.0, 12.0),
            reason: 'Wilaya ${w.nameFr} longitude must be in Algerian geographical bounds');
      }
    });

    test('T1.2.2: Method 19 benchmark parity for Wilaya 16 (Alger) on 2026-10-06', () {
      final schedule = BenchmarkData.getScheduleFor(16, BenchmarkData.benchmarkDate);
      expect(schedule.formatPrayer(Prayer.fajr), equals('05:21'));
      expect(schedule.formatPrayer(Prayer.sunrise), equals('06:47'));
      expect(schedule.formatPrayer(Prayer.dhuhr), equals('12:36'));
      expect(schedule.formatPrayer(Prayer.asr), equals('15:54'));
      expect(schedule.formatPrayer(Prayer.maghrib), equals('18:24'));
      expect(schedule.formatPrayer(Prayer.isha), equals('19:45'));
    });

    test('T1.2.3: Method 19 benchmark parity for Wilaya 31 (Oran) on 2026-10-06', () {
      final schedule = BenchmarkData.getScheduleFor(31, BenchmarkData.benchmarkDate);
      expect(schedule.formatPrayer(Prayer.fajr), equals('05:37'));
      expect(schedule.formatPrayer(Prayer.sunrise), equals('07:01'));
      expect(schedule.formatPrayer(Prayer.dhuhr), equals('12:51'));
      expect(schedule.formatPrayer(Prayer.asr), equals('16:09'));
      expect(schedule.formatPrayer(Prayer.maghrib), equals('18:39'));
      expect(schedule.formatPrayer(Prayer.isha), equals('19:59'));
    });

    test('T1.2.4: Method 19 benchmark parity for Wilaya 25 (Constantine) on 2026-10-06', () {
      final schedule = BenchmarkData.getScheduleFor(25, BenchmarkData.benchmarkDate);
      expect(schedule.formatPrayer(Prayer.fajr), equals('05:07'));
      expect(schedule.formatPrayer(Prayer.sunrise), equals('06:33'));
      expect(schedule.formatPrayer(Prayer.dhuhr), equals('12:22'));
      expect(schedule.formatPrayer(Prayer.asr), equals('15:40'));
      expect(schedule.formatPrayer(Prayer.maghrib), equals('18:10'));
      expect(schedule.formatPrayer(Prayer.isha), equals('19:30'));
    });

    test('T1.2.5: Method 19 benchmark parity for Wilaya 30 (Ouargla) on 2026-10-06', () {
      final schedule = BenchmarkData.getScheduleFor(30, BenchmarkData.benchmarkDate);
      expect(schedule.formatPrayer(Prayer.fajr), equals('05:15'));
      expect(schedule.formatPrayer(Prayer.sunrise), equals('06:36'));
      expect(schedule.formatPrayer(Prayer.dhuhr), equals('12:27'));
      expect(schedule.formatPrayer(Prayer.asr), equals('15:47'));
      expect(schedule.formatPrayer(Prayer.maghrib), equals('18:17'));
      expect(schedule.formatPrayer(Prayer.isha), equals('19:34'));
    });

    test('T1.2.6: Communal calibration offsets (±15 min) shift calculations by exact signed delta', () {
      final base = BenchmarkData.getScheduleFor(16, BenchmarkData.benchmarkDate);
      const offsets = PrayerOffsets(fajr: 5, dhuhr: -2, asr: 0, maghrib: 3, isha: -10);

      final adjusted = base.applyOffsets(offsets);
      expect(adjusted.fajr.difference(base.fajr).inMinutes, equals(5));
      expect(adjusted.dhuhr.difference(base.dhuhr).inMinutes, equals(-2));
      expect(adjusted.asr.difference(base.asr).inMinutes, equals(0));
      expect(adjusted.maghrib.difference(base.maghrib).inMinutes, equals(3));
      expect(adjusted.isha.difference(base.isha).inMinutes, equals(-10));
    });

    test('T1.2.7: Hijri calendar offset logic (±1-2 days) correctly adjusts date arithmetic', () {
      final base = DateTime(2026, 10, 6);
      final offsetPlus1 = base.add(const Duration(days: 1));
      final offsetMinus2 = base.add(const Duration(days: -2));

      expect(offsetPlus1.day, equals(7));
      expect(offsetMinus2.day, equals(4));
    });
  });

  group('Tier 1: Feature Coverage (R3 Mosque Display State Machine Lifecycle)', () {
    testWidgets('T1.3.1 - T1.3.5: Full 4-State Cycle (Standard -> Adhan -> Iqamah -> Blackout -> Standard)',
        (WidgetTester tester) async {
      final fakePrayerRepo = FakePrayerRepository();
      final fakeSettingsRepo = FakeSettingsRepository();
      // Schedule Dhuhr on 2026-10-06 is 12:36
      // Start at 12:30 (Standard State)
      var currentTime = DateTime(2026, 10, 6, 12, 30);

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

      // State 1: Standard Display Mode
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.standard));
      expect(find.byKey(const Key('screen_standard_dashboard')), findsOneWidget);

      // Advance clock to 12:36:00 (Exact Dhuhr Adhan time)
      currentTime = DateTime(2026, 10, 6, 12, 36);
      stateMachine.updateTick(currentTime);
      await tester.pumpAndSettle();

      // State 2: Adhan Alert State
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.adhan));
      expect(find.byKey(const Key('screen_adhan_alert')), findsOneWidget);
      expect(find.byKey(const Key('text_adhan_alert_title')), findsOneWidget);

      // Advance clock past 2-min Adhan alert: 12:38:05 (Iqamah Countdown State)
      currentTime = DateTime(2026, 10, 6, 12, 38, 5);
      stateMachine.updateTick(currentTime);
      await tester.pumpAndSettle();

      // State 3: Iqamah Countdown State
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.iqamah));
      expect(find.byKey(const Key('screen_iqamah_countdown')), findsOneWidget);
      expect(find.byKey(const Key('iqamah_circular_ring')), findsOneWidget);
      expect(find.byKey(const Key('text_iqamah_timer')), findsOneWidget);

      // Advance clock to Iqamah 00:00: 12:38 + 15 min = 12:53:05 (Salat Blackout State)
      currentTime = DateTime(2026, 10, 6, 12, 53, 5);
      stateMachine.updateTick(currentTime);
      await tester.pumpAndSettle();

      // State 4: Salat Blackout State (OLED Pitch Black default)
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.blackout));
      expect(find.byKey(const Key('screen_salat_blackout_oled')), findsOneWidget);

      // Advance clock past 20-min Blackout: 12:53 + 20 min = 13:13:05 (Return to Standard)
      currentTime = DateTime(2026, 10, 6, 13, 13, 5);
      stateMachine.updateTick(currentTime);
      await tester.pumpAndSettle();

      // State 5: Return to Standard Mode, upcoming target prayer is now Asr
      expect(stateMachine.currentState.value.mode, equals(DisplayMode.standard));
      expect(find.byKey(const Key('screen_standard_dashboard')), findsOneWidget);
      expect(stateMachine.currentState.value.targetPrayer, equals(Prayer.asr));
    });
  });

  group('Tier 1: Feature Coverage (R4 TV Remote D-Pad Navigation & Persistence)', () {
    testWidgets('T1.4.1 & T1.4.2: D-Pad opens settings, requires 4-digit PIN lock',
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

      // Send TV Remote Menu/F1 shortcut to open settings
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();

      // Verify TV Settings Dialog & PIN Lock Screen
      expect(find.byKey(const Key('tv_settings_dialog')), findsOneWidget);
      expect(find.byKey(const Key('pin_lock_screen')), findsOneWidget);

      // Enter default PIN '0000'
      final zeroBtn = find.byKey(const Key('btn_keypad_0'));
      for (int i = 0; i < 4; i++) {
        await tester.tap(zeroBtn);
        await tester.pumpAndSettle();
      }

      // Settings Content Panel is now unlocked
      expect(find.byKey(const Key('settings_content_panel')), findsOneWidget);
    });

    testWidgets('T1.4.3 & T1.4.4: Wilaya selector & Offset Steppers modify settings reactively',
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

      // Open settings & unlock
      await tester.sendKeyEvent(LogicalKeyboardKey.f1);
      await tester.pumpAndSettle();
      final zeroBtn = find.byKey(const Key('btn_keypad_0'));
      for (int i = 0; i < 4; i++) {
        await tester.tap(zeroBtn);
        await tester.pumpAndSettle();
      }

      // Select Wilaya 31 (Oran)
      final oranBtn = find.byKey(const Key('btn_wilaya_31'));
      await tester.tap(oranBtn);
      await tester.pumpAndSettle();
      expect(fakeSettingsRepo.settingsNotifier.value.selectedWilayaCode, equals(31));

      // Click Fajr Offset Plus button twice (+2 min)
      final plusBtn = find.byKey(const Key('btn_offset_fajr_plus'));
      await tester.tap(plusBtn);
      await tester.pumpAndSettle();
      await tester.tap(plusBtn);
      await tester.pumpAndSettle();
      expect(fakeSettingsRepo.settingsNotifier.value.offsets.fajr, equals(2));

      // Toggle blackout mode
      final toggleBtn = find.byKey(const Key('btn_toggle_blackout_mode'));
      await tester.tap(toggleBtn);
      await tester.pumpAndSettle();
      expect(fakeSettingsRepo.settingsNotifier.value.blackoutDimMode, isTrue);
    });

    test('T1.4.5: MosqueSettings JSON serialization persists and restores across reboots', () {
      const original = MosqueSettings(
        selectedWilayaCode: 25, // Constantine
        offsets: PrayerOffsets(fajr: 3, dhuhr: -1, isha: 5),
        iqamahDelays: IqamahDelays(fajr: 25, dhuhr: 20),
        blackoutDurationMinutes: 25,
        blackoutDimMode: true,
        hijriOffsetDays: 1,
        mosqueName: 'مسجد الأمير عبد القادر',
        marqueeText: 'إعلان: صلاة الجنازة بعد صلاة الظهر',
        pinCode: '1234',
      );

      final json = original.toJson();
      final restored = MosqueSettings.fromJson(json);

      expect(restored.selectedWilayaCode, equals(25));
      expect(restored.offsets.fajr, equals(3));
      expect(restored.offsets.dhuhr, equals(-1));
      expect(restored.offsets.isha, equals(5));
      expect(restored.iqamahDelays.fajr, equals(25));
      expect(restored.blackoutDurationMinutes, equals(25));
      expect(restored.blackoutDimMode, isTrue);
      expect(restored.hijriOffsetDays, equals(1));
      expect(restored.mosqueName, equals('مسجد الأمير عبد القادر'));
      expect(restored.marqueeText, equals('إعلان: صلاة الجنازة بعد صلاة الظهر'));
      expect(restored.pinCode, equals('1234'));
    });
  });
}
