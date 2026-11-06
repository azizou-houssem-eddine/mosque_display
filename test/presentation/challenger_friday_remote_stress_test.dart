import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mosque_display/core/providers/display_provider.dart';
import 'package:mosque_display/data/datasources/bundled_timetable_datasource.dart';
import 'package:mosque_display/data/models/mosque_settings.dart';
import 'package:mosque_display/data/models/prayer_schedule.dart';
import 'package:mosque_display/data/repositories/prayer_repository.dart';
import 'package:mosque_display/domain/occasions/islamic_occasions_engine.dart';
import 'package:mosque_display/ui/screens/iqamah_countdown_screen.dart';
import 'package:mosque_display/ui/screens/jumuah_khutbah_screen.dart';
import 'package:mosque_display/ui/screens/main_dashboard_screen.dart';
import 'package:mosque_display/ui/screens/salat_blackout_screen.dart';
import 'package:mosque_display/ui/screens/settings_screen.dart';

Widget _wrapWithProvider(Widget child, {required DisplayProvider provider}) {
  return ChangeNotifierProvider<DisplayProvider>.value(
    value: provider,
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BundledTimetableDataSource dataSource;
  late HybridAlgerianPrayerRepository repo;

  setUpAll(() async {
    final file = File('assets/data/algerian_prayer_times.json');
    final content = await file.readAsString();
    dataSource = BundledTimetableDataSource(
      initialCache: json.decode(content) as Map<String, dynamic>,
    );
    repo = HybridAlgerianPrayerRepository(bundledDataSource: dataSource);
  });

  group('Challenger Adversarial Stress Harness: Friday Lifecycle, Remote Keys & Boundary Conditions', () {
    testWidgets('100+ rapid interleaved remote keys across modals and active dashboard', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();

      await tester.pumpWidget(_wrapWithProvider(const MainDashboardScreen(), provider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final remoteKeys = [
        LogicalKeyboardKey.select,
        LogicalKeyboardKey.space,
        LogicalKeyboardKey.gameButtonA,
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.numpadEnter,
        LogicalKeyboardKey.escape,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.f1,
        LogicalKeyboardKey.f2,
        LogicalKeyboardKey.digit5,
      ];

      // Hammer 120 key events with varying pump delays
      for (int i = 0; i < 120; i++) {
        final key = remoteKeys[i % remoteKeys.length];
        await tester.sendKeyEvent(key);
        if (i % 5 == 0) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      }

      // Evacuate any open dialogs/screens
      for (int i = 0; i < 6; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MainDashboardScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      provider.dispose();
    });

    testWidgets('Deep 4-tier stacked modal routes collapse on emergency Iqamah countdown', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();

      await tester.pumpWidget(_wrapWithProvider(const MainDashboardScreen(), provider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final dashCtx = tester.element(find.byType(MainDashboardScreen));

      // Push Tier 1: SettingsScreen
      Navigator.of(dashCtx).push(
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Push Tier 2: Dialog
      showDialog<void>(
        context: dashCtx,
        builder: (_) => const AlertDialog(title: Text('Tier 2 Dialog')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Tier 2 Dialog'), findsOneWidget);

      // Push Tier 3: Nested Dialog
      showDialog<void>(
        context: dashCtx,
        builder: (_) => const AlertDialog(title: Text('Tier 3 Nested Dialog')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Tier 3 Nested Dialog'), findsOneWidget);

      // Trigger emergency Iqamah countdown
      provider.simulateDisplayState(DisplayState.iqamahCountdown, prayer: Prayer.asr);
      await tester.pump();
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Verify all 3 stacked tiers are collapsed back to root
      expect(find.text('Tier 3 Nested Dialog'), findsNothing);
      expect(find.text('Tier 2 Dialog'), findsNothing);
      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.byType(IqamahCountdownScreen), findsOneWidget);

      provider.dispose();
    });

    testWidgets('Deep 4-tier stacked modal routes collapse on Friday Jumuah Khutbah and Salat Blackout', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();

      await tester.pumpWidget(_wrapWithProvider(const MainDashboardScreen(), provider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final dashCtx = tester.element(find.byType(MainDashboardScreen));

      // Stack 3 modal dialogs
      showDialog<void>(
        context: dashCtx,
        builder: (_) => const SimpleDialog(title: Text('Layer 1')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      showDialog<void>(
        context: dashCtx,
        builder: (_) => const SimpleDialog(title: Text('Layer 2')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      showDialog<void>(
        context: dashCtx,
        builder: (_) => const SimpleDialog(title: Text('Layer 3')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Layer 3'), findsOneWidget);

      // Trigger Jumuah Khutbah
      provider.simulateDisplayState(DisplayState.jumuahKhutbah, prayer: Prayer.dhuhr);
      await tester.pump();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.text('Layer 3'), findsNothing);
      expect(find.text('Layer 2'), findsNothing);
      expect(find.text('Layer 1'), findsNothing);
      expect(find.byType(JumuahKhutbahScreen), findsOneWidget);

      // Dismiss back to standard
      provider.dismissActiveState();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Push 2 modals and test collapse on Salat Blackout
      showDialog<void>(
        context: dashCtx,
        builder: (_) => const SimpleDialog(title: Text('Blackout Modal A')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      showDialog<void>(
        context: dashCtx,
        builder: (_) => const SimpleDialog(title: Text('Blackout Modal B')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Blackout Modal B'), findsOneWidget);

      provider.enterBlackout();
      await tester.pump();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.text('Blackout Modal B'), findsNothing);
      expect(find.text('Blackout Modal A'), findsNothing);
      expect(find.byType(SalatBlackoutScreen), findsOneWidget);

      provider.dispose();
    });

    testWidgets('Friday Khutbah screen remote key spam and dismissal race conditions', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();
      provider.simulateDisplayState(DisplayState.jumuahKhutbah, prayer: Prayer.dhuhr);

      await tester.pumpWidget(_wrapWithProvider(const MainDashboardScreen(), provider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(JumuahKhutbahScreen), findsOneWidget);

      // Spam Enter, Select, Space, GameButtonA, NumpadEnter in rapid succession
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonA);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Must have transitioned cleanly to Salat Blackout
      expect(provider.displayState, equals(DisplayState.salatBlackout));
      expect(find.byType(SalatBlackoutScreen), findsOneWidget);

      // Spam Back/Escape on Blackout
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(provider.displayState, equals(DisplayState.standard));
      expect(find.byType(MainDashboardScreen), findsOneWidget);

      provider.dispose();
    });

    test('Wall-clock recovery across comprehensive second-by-second boundaries', () async {
      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(
          remoteAdminEnabled: false,
          blackoutDurationMinutes: 15,
          adhkarDurationMinutes: 10,
        ),
      );
      await provider.init();

      final schedule = provider.todaySchedule;
      expect(schedule, isNotNull);

      final pTime = schedule!.dhuhr;
      final jumuahDelay = provider.settings.iqamahDelays.getDelayFor(Prayer.dhuhr, isFriday: true);
      final iqamahTime = pTime.add(Duration(minutes: jumuahDelay));
      final blackoutTime = iqamahTime.add(const Duration(minutes: 15));
      final adhkarTime = blackoutTime.add(const Duration(minutes: 10));

      // Force Friday occasion for consistent Friday test
      await provider.simulateOccasion(OccasionType.friday);

      // Boundary 1: 31s before Adhan -> Standard
      provider.recoverWallClockState(pTime.subtract(const Duration(seconds: 31)));
      expect(provider.displayState, equals(DisplayState.standard));

      // Boundary 2: 29s before Adhan -> Adhan Alert
      provider.recoverWallClockState(pTime.subtract(const Duration(seconds: 29)));
      expect(provider.displayState, equals(DisplayState.adhanAlert));

      // Boundary 3: Exactly at prayer time -> Adhan Alert
      provider.recoverWallClockState(pTime);
      expect(provider.displayState, equals(DisplayState.adhanAlert));

      // Boundary 4: 89s after prayer time -> Adhan Alert
      provider.recoverWallClockState(pTime.add(const Duration(seconds: 89)));
      expect(provider.displayState, equals(DisplayState.adhanAlert));

      // Boundary 5: Exactly 90s after prayer time on Friday -> Jumuah Khutbah
      provider.recoverWallClockState(pTime.add(const Duration(seconds: 90)));
      expect(provider.displayState, equals(DisplayState.jumuahKhutbah));
      expect(provider.activePrayer, equals(Prayer.dhuhr));

      // Boundary 6: 1s before Iqamah on Friday -> Jumuah Khutbah
      provider.recoverWallClockState(iqamahTime.subtract(const Duration(seconds: 1)));
      expect(provider.displayState, equals(DisplayState.jumuahKhutbah));

      // Boundary 7: Exactly at Iqamah time -> Salat Blackout
      provider.recoverWallClockState(iqamahTime);
      expect(provider.displayState, equals(DisplayState.salatBlackout));

      // Boundary 8: 1s before Blackout ends -> Salat Blackout
      provider.recoverWallClockState(blackoutTime.subtract(const Duration(seconds: 1)));
      expect(provider.displayState, equals(DisplayState.salatBlackout));

      // Boundary 9: Exactly at Blackout end / Adhkar start -> Post-Salat Adhkar
      provider.recoverWallClockState(blackoutTime);
      expect(provider.displayState, equals(DisplayState.postSalatAdhkar));

      // Boundary 10: 1s before Adhkar ends -> Post-Salat Adhkar
      provider.recoverWallClockState(adhkarTime.subtract(const Duration(seconds: 1)));
      expect(provider.displayState, equals(DisplayState.postSalatAdhkar));

      // Boundary 11: Exactly at Adhkar end -> Returns to Standard (dismissActiveState)
      await provider.resetSimulation();
      provider.recoverWallClockState(adhkarTime);
      expect(provider.displayState, equals(DisplayState.standard));

      provider.dispose();
    });

    test('Wall-clock recovery Friday vs Non-Friday targetTime mismatch probe', () async {
      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(
          remoteAdminEnabled: false,
          blackoutDurationMinutes: 15,
          adhkarDurationMinutes: 10,
        ),
      );
      await provider.init();

      final schedule = provider.todaySchedule;
      expect(schedule, isNotNull);

      final dhuhrTime = schedule!.dhuhr;
      final midwayKhutbah = dhuhrTime.add(const Duration(minutes: 10));

      // Case A: When Friday occasion is simulated, recovers into Jumuah Khutbah
      await provider.simulateOccasion(OccasionType.friday);
      provider.recoverWallClockState(midwayKhutbah);
      expect(provider.displayState, equals(DisplayState.jumuahKhutbah));

      // Case B: Reset simulation back to real world
      // Probe: If targetTime is a Wednesday Dhuhr, but provider is on Friday host clock,
      // recoverWallClockState evaluates `isFriday` from host effectiveDate rather than targetTime!
      final wednesdayDate = DateTime(2026, 11, 4, midwayKhutbah.hour, midwayKhutbah.minute, midwayKhutbah.second);
      provider.recoverWallClockState(wednesdayDate);

      // On a Wednesday, Dhuhr should recover into iqamahCountdown, NOT jumuahKhutbah!
      // This test fails until line 282 is fixed: `final isJumuah = ((now.weekday == DateTime.friday || isFriday) && prayer == Prayer.dhuhr);`
      expect(provider.displayState, equals(DisplayState.iqamahCountdown));

      provider.dispose();
    });

    testWidgets('Cycle 50 state transitions rapidly with remote key interaction', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();

      await tester.pumpWidget(_wrapWithProvider(const MainDashboardScreen(), provider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final states = [
        DisplayState.standard,
        DisplayState.adhanAlert,
        DisplayState.iqamahCountdown,
        DisplayState.jumuahKhutbah,
        DisplayState.salatBlackout,
        DisplayState.postSalatAdhkar,
      ];

      for (int i = 0; i < 50; i++) {
        final state = states[i % states.length];
        provider.simulateDisplayState(state, prayer: Prayer.dhuhr);
        await tester.pump(const Duration(milliseconds: 16));

        // Interleave a remote key press
        if (i % 2 == 0) {
          await tester.sendKeyEvent(LogicalKeyboardKey.select);
        } else {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        }
        await tester.pump(const Duration(milliseconds: 16));
      }

      provider.dismissActiveState();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(MainDashboardScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      provider.dispose();
    });

    test('Empirical reproduction: dismissActiveState unawaited resetSimulation disposal race condition', () async {
      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();
      provider.simulateDisplayState(DisplayState.jumuahKhutbah);

      provider.dismissActiveState();
      provider.dispose();
      // Allow background _loadTodaySchedule to complete.
      // Must not throw "A DisplayProvider was used after being disposed"
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  });
}
