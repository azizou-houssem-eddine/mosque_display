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
import 'package:mosque_display/ui/screens/jumuah_khutbah_screen.dart';
import 'package:mosque_display/ui/screens/iqamah_countdown_screen.dart';
import 'package:mosque_display/ui/screens/salat_blackout_screen.dart';
import 'package:mosque_display/ui/screens/main_dashboard_screen.dart';
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

  group('TV Remote Button Rapid Input & Modal Collapse Stress Tests (R2)', () {
    testWidgets('Rapidly hammer 50+ interleaved key events (Enter, Select, Space, GameButtonA, NumpadEnter, Escape)', (tester) async {
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

      final keysToSpam = [
        LogicalKeyboardKey.select,
        LogicalKeyboardKey.space,
        LogicalKeyboardKey.gameButtonA,
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.numpadEnter,
        LogicalKeyboardKey.escape,
      ];

      // Rapidly fire 60 key events without crashing
      for (int i = 0; i < 60; i++) {
        final key = keysToSpam[i % keysToSpam.length];
        await tester.sendKeyEvent(key);
        if (i % 10 == 0) {
          await tester.pump(const Duration(milliseconds: 16));
        }
      }

      // Unwind any opened routes with Escape
      for (int i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.pump(const Duration(milliseconds: 300));

      // Verify the application remains stable and returns to MainDashboardScreen
      expect(find.byType(MainDashboardScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      provider.dispose();
    });

    testWidgets('Friday Khutbah screen transitions instantly to Blackout on remote keys (Space, Enter, Select, GameButtonA)', (tester) async {
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

      // Press Space key to enter blackout early
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(provider.displayState, equals(DisplayState.salatBlackout));
      expect(find.byType(SalatBlackoutScreen), findsOneWidget);

      // Press Escape key to dismiss active blackout
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(provider.displayState, equals(DisplayState.standard));

      provider.dispose();
    });

    testWidgets('Emergency modal collapse: stacked modal routes collapse immediately on DisplayState.iqamahCountdown', (tester) async {
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

      final dashboardContext = tester.element(find.byType(MainDashboardScreen));

      // Push 2 modal routes on top of MainDashboardScreen
      Navigator.of(dashboardContext).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Modal Layer 1')),
        ),
      );
      await tester.pumpAndSettle();

      Navigator.of(dashboardContext).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Modal Layer 2')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Modal Layer 2'), findsOneWidget);
      expect(Navigator.of(dashboardContext).canPop(), isTrue);

      // Now trigger emergency Iqamah Countdown
      provider.simulateDisplayState(DisplayState.iqamahCountdown, prayer: Prayer.asr);
      await tester.pump();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      // Assert modal layers are completely collapsed
      expect(find.text('Modal Layer 2'), findsNothing);
      expect(find.text('Modal Layer 1'), findsNothing);
      expect(find.byType(IqamahCountdownScreen), findsOneWidget);

      provider.dispose();
    });

    testWidgets('Emergency modal collapse: stacked routes collapse on jumuahKhutbah and salatBlackout', (tester) async {
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
      provider.simulateDisplayState(DisplayState.standard);

      await tester.pumpWidget(_wrapWithProvider(const MainDashboardScreen(), provider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final dashboardContext = tester.element(find.byType(MainDashboardScreen));

      // Test collapse on Jumuah Khutbah
      Navigator.of(dashboardContext).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Settings Modal')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Settings Modal'), findsOneWidget);

      provider.simulateDisplayState(DisplayState.jumuahKhutbah, prayer: Prayer.dhuhr);
      await tester.pump();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      expect(find.text('Settings Modal'), findsNothing);
      expect(find.byType(JumuahKhutbahScreen), findsOneWidget);

      // Reset to standard
      provider.dismissActiveState();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Test collapse on Salat Blackout
      Navigator.of(dashboardContext).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('QR Dialog Modal')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('QR Dialog Modal'), findsOneWidget);

      provider.enterBlackout();
      await tester.pump();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      expect(find.text('QR Dialog Modal'), findsNothing);
      expect(find.byType(SalatBlackoutScreen), findsOneWidget);

      provider.dispose();
    });

    testWidgets('Settings numeric PIN keypad handles numpadEnter, space, and gameButtonA', (tester) async {
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

      await tester.pumpWidget(_wrapWithProvider(const SettingsScreen(), provider: provider));
      await tester.pumpAndSettle();

      // Open PIN Security tab (PIN الأمان)
      final pinTab = find.text('PIN الأمان');
      expect(pinTab, findsOneWidget);
      await tester.tap(pinTab);
      await tester.pumpAndSettle();

      // Find keypad buttons (digits 1, 2, 3...)
      final digit1 = find.text('1');
      expect(digit1, findsWidgets);

      // Send space, gameButtonA, and numpadEnter
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump(const Duration(milliseconds: 50));

      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonA);
      await tester.pump(const Duration(milliseconds: 50));

      await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);

      provider.dispose();
    });
  });
}
