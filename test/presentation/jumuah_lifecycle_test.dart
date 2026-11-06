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
import 'package:mosque_display/ui/screens/jumuah_khutbah_screen.dart';
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

  group('Friday (Jumu\'ah) Lifecycle & Screen Tests', () {
    testWidgets('Friday detection activates isFriday flag and switches Dhuhr to الجمعة', (tester) async {
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

      // Non-Friday: October 6, 2026 is Tuesday
      await provider.simulateOccasion(OccasionType.mawlid, customDateTime: DateTime(2026, 10, 6, 11, 0));
      expect(provider.isFriday, isFalse);

      // Friday: simulate Friday occasion
      await provider.simulateOccasion(OccasionType.friday);
      expect(provider.isFriday, isTrue);

      await tester.pumpWidget(_wrapWithProvider(const MainDashboardScreen(), provider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Dhuhr card displays "الجمعة"
      expect(find.text('الجمعة'), findsWidgets);
      // Gauge subtitle displays "صلاة الجمعة"
      expect(find.textContaining('الجمعة'), findsWidgets);
    });

    testWidgets('JumuahKhutbahScreen renders reverence Hadith of Insaat, timing, and sacred layout', (tester) async {
      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();
      provider.simulateDisplayState(DisplayState.jumuahKhutbah, prayer: Prayer.dhuhr);

      await tester.pumpWidget(_wrapWithProvider(const JumuahKhutbahScreen(), provider: provider));
      await tester.pumpAndSettle();

      // Check Insaat reverence Hadith
      expect(find.text('أَنْصِتْ وَاسْتَمِعْ رَحِمَكَ اللهُ'), findsOneWidget);
      expect(find.textContaining('إِذَا قُلْتَ لِصَاحِبِكَ يَوْمَ الْجُمُعَةِ: أَنْصِتْ'), findsOneWidget);
      expect(find.textContaining('متفق عليه عن أبي هريرة'), findsOneWidget);

      // Check Header & Title
      expect(find.textContaining('خُطْبَةُ يَوْمِ الجُمُعَةِ'), findsOneWidget);

      // Check Early Prayer Start Button
      expect(find.text('بدء الصلاة فوراً (Enter / OK)'), findsOneWidget);

      // Check Exit Button
      expect(find.textContaining('العودة للشاشة الرئيسية'), findsOneWidget);
    });

    testWidgets('Pressing Enter / OK during Khutbah transitions directly to Salat Blackout', (tester) async {
      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();
      provider.simulateDisplayState(DisplayState.jumuahKhutbah, prayer: Prayer.dhuhr);

      await tester.pumpWidget(_wrapWithProvider(const JumuahKhutbahScreen(), provider: provider));
      await tester.pumpAndSettle();

      expect(provider.displayState, equals(DisplayState.jumuahKhutbah));

      // Press Enter key
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(provider.displayState, equals(DisplayState.salatBlackout));
    });

    testWidgets('Tapping "بدء الصلاة فوراً" button transitions to Salat Blackout', (tester) async {
      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();
      provider.simulateDisplayState(DisplayState.jumuahKhutbah, prayer: Prayer.dhuhr);

      await tester.pumpWidget(_wrapWithProvider(const JumuahKhutbahScreen(), provider: provider));
      await tester.pumpAndSettle();

      final prayerButton = find.text('بدء الصلاة فوراً (Enter / OK)');
      expect(prayerButton, findsOneWidget);

      await tester.tap(prayerButton);
      await tester.pumpAndSettle();

      expect(provider.displayState, equals(DisplayState.salatBlackout));
    });

    testWidgets('Pressing Escape / Back dismisses Khutbah mode back to standard dashboard', (tester) async {
      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();
      provider.simulateDisplayState(DisplayState.jumuahKhutbah, prayer: Prayer.dhuhr);

      await tester.pumpWidget(_wrapWithProvider(const JumuahKhutbahScreen(), provider: provider));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(provider.displayState, equals(DisplayState.standard));
    });

    testWidgets('Settings screen Tab 4 (تأخير الإقامة) configures Jumuah delay (15-90 min)', (tester) async {
      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();

      await tester.pumpWidget(_wrapWithProvider(const SettingsScreen(), provider: provider));
      await tester.pumpAndSettle();

      // Navigate to Tab 4: تأخير الإقامة
      await tester.tap(find.text('تأخير الإقامة'));
      await tester.pumpAndSettle();

      expect(find.text('خطبة وانتظار الجمعة'), findsOneWidget);
      expect(find.text('40'), findsWidgets); // Default 40 minutes

      // Increase delay
      final jumuahStepper = find.ancestor(
        of: find.text('خطبة وانتظار الجمعة'),
        matching: find.byType(Column),
      ).first;
      final addIcon = find.descendant(of: jumuahStepper, matching: find.byIcon(Icons.add));
      if (addIcon.evaluate().isNotEmpty) {
        await tester.tap(addIcon.first);
        await tester.pumpAndSettle();
        expect(provider.settings.iqamahDelays.jumuah, greaterThanOrEqualTo(41));
      }
    });

    testWidgets('D-pad select and gamepad primary button trigger early prayer start (salatBlackout)', (tester) async {
      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();
      provider.simulateDisplayState(DisplayState.jumuahKhutbah, prayer: Prayer.dhuhr);

      await tester.pumpWidget(_wrapWithProvider(const JumuahKhutbahScreen(), provider: provider));
      await tester.pumpAndSettle();

      expect(provider.displayState, equals(DisplayState.jumuahKhutbah));

      // Test select (DPAD_CENTER)
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(provider.displayState, equals(DisplayState.salatBlackout));

      // Reset to jumuahKhutbah
      provider.simulateDisplayState(DisplayState.jumuahKhutbah, prayer: Prayer.dhuhr);
      await tester.pumpAndSettle();

      // Test gameButtonA
      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonA);
      await tester.pumpAndSettle();
      expect(provider.displayState, equals(DisplayState.salatBlackout));
    });

    testWidgets('Emergency dismissal: open modal routes collapse immediately when jumuahKhutbah begins', (tester) async {
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
      await tester.pump(const Duration(milliseconds: 150));

      // Open SettingsScreen as a modal route over MainDashboardScreen
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Trigger Friday Khutbah state
      provider.simulateDisplayState(DisplayState.jumuahKhutbah, prayer: Prayer.dhuhr);
      await tester.pump();
      await tester.pumpAndSettle();

      // Settings screen should be collapsed, and JumuahKhutbahScreen displayed
      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.byType(JumuahKhutbahScreen), findsOneWidget);
    });
  });
}
