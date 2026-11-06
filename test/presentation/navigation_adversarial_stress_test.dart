import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mosque_display/core/providers/display_provider.dart';
import 'package:mosque_display/core/theme/app_theme.dart';
import 'package:mosque_display/data/models/commune.dart';
import 'package:mosque_display/data/models/prayer_offsets.dart';
import 'package:mosque_display/data/models/prayer_schedule.dart';
import 'package:mosque_display/data/models/wilaya.dart';
import 'package:mosque_display/data/repositories/prayer_repository.dart';
import 'package:mosque_display/ui/screens/dua_showcase_screen.dart';
import 'package:mosque_display/ui/screens/iqamah_countdown_screen.dart';
import 'package:mosque_display/ui/screens/main_dashboard_screen.dart';
import 'package:mosque_display/ui/screens/salat_blackout_screen.dart';
import 'package:mosque_display/ui/screens/settings_screen.dart';
import 'package:mosque_display/ui/widgets/simulation_control_dialog.dart';

class _FakePrayerRepo implements IPrayerRepository {
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
  Future<List<Commune>> getCommunesForWilaya(int wilayaCode) async => [
        const Commune(
          code: 1601,
          wilayaCode: 16,
          nameAr: 'الجزائر الوسطى',
          nameFr: 'Alger Centre',
          latitude: 36.75,
          longitude: 3.05,
        ),
        const Commune(
          code: 1602,
          wilayaCode: 16,
          nameAr: 'سيدي امحمد',
          nameFr: "Sidi M'Hamed",
          latitude: 36.75,
          longitude: 3.05,
        ),
      ];

  @override
  Future<Commune?> getCommuneByCode(int communeCode) async => null;
}

Widget _wrapWithProvider(
  Widget child, {
  required DisplayProvider provider,
  Size size = const Size(1920, 1080),
}) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: ChangeNotifierProvider<DisplayProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.theme,
          home: child,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakePrayerRepo repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = _FakePrayerRepo();
  });

  group('Adversarial Stress Test: Back Button Timing & Sequences', () {
    testWidgets(
        'ST-01: Single back shows SnackBar; gap >2s resets timer; gap <2s exits',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      int popInvocationCount = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'SystemNavigator.pop') {
            popInvocationCount++;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        _wrapWithProvider(
          const MainDashboardScreen(),
          provider: provider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Single back press
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('اضغط مرة أخرى للخروج'), findsOneWidget);
      expect(popInvocationCount, equals(0));

      // 2. Wait 2.2 seconds (> 2s threshold) - runAsync allows real wall-clock to advance
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 2100));
      });
      await tester.pump();

      // 3. Second press after >2s -> MUST NOT exit; must show SnackBar again
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('اضغط مرة أخرى للخروج'), findsOneWidget);
      expect(popInvocationCount, equals(0));

      // 4. Third press within 500ms (< 2s) -> MUST invoke SystemNavigator.pop
      await tester.pump(const Duration(milliseconds: 500));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(popInvocationCount, equals(1));
    });

    testWidgets(
        'ST-02: Burst rapid-fire back presses (10 clicks in 500ms) does not crash',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      int popInvocationCount = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'SystemNavigator.pop') {
            popInvocationCount++;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        _wrapWithProvider(
          const MainDashboardScreen(),
          provider: provider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Fire 10 rapid back presses with 50ms intervals
      for (int i = 0; i < 10; i++) {
        await tester.binding.handlePopRoute();
        await tester.pump(const Duration(milliseconds: 50));
      }

      // No crash, and pop was called (first click shows snackbar, subsequent clicks within 2s call pop)
      expect(tester.takeException(), isNull);
      expect(popInvocationCount, greaterThanOrEqualTo(1));
    });

    testWidgets(
        'ST-03: Back press during active display states dismisses them instead of exiting',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      bool didPop = false;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'SystemNavigator.pop') {
            didPop = true;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        _wrapWithProvider(
          const MainDashboardScreen(),
          provider: provider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // A. salatBlackout state
      provider.simulateDisplayState(DisplayState.salatBlackout);
      await tester.pump();
      expect(find.byType(SalatBlackoutScreen), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(provider.displayState, equals(DisplayState.standard));
      expect(didPop, isFalse);

      // B. iqamahCountdown state
      provider.simulateDisplayState(DisplayState.iqamahCountdown);
      await tester.pump();
      expect(find.byType(IqamahCountdownScreen), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(provider.displayState, equals(DisplayState.standard));
      expect(didPop, isFalse);

      // C. postSalatAdhkar state
      provider.simulateDisplayState(DisplayState.postSalatAdhkar);
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(provider.displayState, equals(DisplayState.standard));
      expect(didPop, isFalse);
    });
  });

  group('Adversarial Stress Test: Deep Hierarchical Back Navigation Ladder', () {
    testWidgets(
        'ST-04: Strict step-by-step ladder: Focused field -> Communes -> Wilayas -> Settings -> Dashboard -> SnackBar -> Pop',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      int popCount = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'SystemNavigator.pop') {
            popCount++;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        _wrapWithProvider(
          const MainDashboardScreen(),
          provider: provider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Open Settings
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SettingsScreen), findsOneWidget);

      // 2. Open Communes sub-view (16. الجزائر)
      await tester.tap(find.textContaining('2. بلديات'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('← العودة لقائمة الولايات'), findsOneWidget);

      // 3. Focus commune search text field
      final communeSearchField = find.byType(TextField).first;
      await tester.tap(communeSearchField);
      await tester.pumpAndSettle();
      final EditableText editable = tester.widget(
        find.descendant(of: communeSearchField, matching: find.byType(EditableText)),
      );
      expect(editable.focusNode.hasFocus, isTrue);

      // STEP 1: First Back must unfocus the text field ONLY
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(editable.focusNode.hasFocus, isFalse);
      expect(find.text('← العودة لقائمة الولايات'), findsOneWidget);
      expect(find.byType(SettingsScreen), findsOneWidget);

      // STEP 2: Second Back must return from Communes to Wilayas list
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('← العودة لقائمة الولايات'), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);

      final f = FocusManager.instance.primaryFocus;
      // ignore: avoid_print
      print('DEBUG ST-04: focus=$f, widget=${f?.context?.widget}, isEditable=${f != null && (f.context?.widget is EditableText || f.context?.findAncestorWidgetOfExactType<EditableText>() != null)}');

      // STEP 3: Third Back must pop SettingsScreen to MainDashboardScreen
      final popHandled = await tester.binding.handlePopRoute();
      // ignore: avoid_print
      print('DEBUG ST-04: STEP 3 handlePopRoute returned $popHandled');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      final settingsElement = find.byType(SettingsScreen).evaluate().firstOrNull;
      if (settingsElement != null) {
        final r = ModalRoute.of(settingsElement);
        // ignore: avoid_print
        print('DEBUG ST-04: route=$r, isCurrent=${r?.isCurrent}, isActive=${r?.isActive}, animationStatus=${r?.animation?.status}, animationValue=${r?.animation?.value}');
      }
      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.byType(MainDashboardScreen), findsOneWidget);

      // STEP 4: Fourth Back must show exit SnackBar
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('اضغط مرة أخرى للخروج'), findsOneWidget);
      expect(popCount, equals(0));

      // STEP 5: Fifth Back within 2s must call SystemNavigator.pop
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(popCount, equals(1));
    });
  });

  group('Adversarial Stress Test: Multi-layer Modal Stacking & Emergency Dismissal', () {
    testWidgets(
        'ST-05: 4-layer modal stack unwinds cleanly one-by-one via Escape/Back keys',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      await tester.pumpWidget(
        _wrapWithProvider(
          const MainDashboardScreen(),
          provider: provider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Level 1: Push Settings
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Level 2: Push DuaShowcaseScreen over Settings
      Navigator.of(tester.element(find.byType(SettingsScreen))).push(
        MaterialPageRoute<void>(builder: (_) => const DuaShowcaseScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DuaShowcaseScreen), findsOneWidget);

      // Level 3: Push SimulationControlDialog over DuaShowcaseScreen
      SimulationControlDialog.show(tester.element(find.byType(DuaShowcaseScreen)));
      await tester.pumpAndSettle();
      expect(find.byType(SimulationControlDialog), findsOneWidget);

      // Unwind Level 3: Escape pops Dialog
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(SimulationControlDialog), findsNothing);
      expect(find.byType(DuaShowcaseScreen), findsOneWidget);

      // Unwind Level 2: Escape pops DuaShowcaseScreen
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(DuaShowcaseScreen), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);

      final f5 = FocusManager.instance.primaryFocus;
      // ignore: avoid_print
      print('DEBUG ST-05: primaryFocus after DuaShowcase popped = $f5, context=${f5?.context}');

      // Unwind Level 1: Escape pops SettingsScreen
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      // ignore: avoid_print
      print('DEBUG ST-05: SettingsScreen present after Escape = ${find.byType(SettingsScreen).evaluate().isNotEmpty}');

      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.byType(MainDashboardScreen), findsOneWidget);
    });

    testWidgets(
        'ST-06: Emergency dismissal: 4-layer modal stack collapsed instantly to root on salatBlackout',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      await tester.pumpWidget(
        _wrapWithProvider(
          const MainDashboardScreen(),
          provider: provider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Push Settings
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Push DuaShowcaseScreen
      Navigator.of(tester.element(find.byType(SettingsScreen))).push(
        MaterialPageRoute<void>(builder: (_) => const DuaShowcaseScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DuaShowcaseScreen), findsOneWidget);

      // Push SimulationControlDialog
      SimulationControlDialog.show(tester.element(find.byType(DuaShowcaseScreen)));
      await tester.pumpAndSettle();
      expect(find.byType(SimulationControlDialog), findsOneWidget);

      // Trigger congregational blackout!
      provider.simulateDisplayState(DisplayState.salatBlackout);
      await tester.pump();
      // Pump successive frames to allow all 3 stacked routes to finish their pop transitions
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      // ALL modal dialogs and screens collapsed
      expect(find.byType(SimulationControlDialog), findsNothing);
      expect(find.byType(DuaShowcaseScreen), findsNothing);
      expect(find.byType(SettingsScreen), findsNothing);

      // Root shows SalatBlackoutScreen
      expect(find.byType(SalatBlackoutScreen), findsOneWidget);
      expect(provider.displayState, equals(DisplayState.salatBlackout));
    });

    testWidgets(
        'ST-07: Emergency dismissal: modal routes collapsed on adhanAlert',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      await tester.pumpWidget(
        _wrapWithProvider(
          const MainDashboardScreen(),
          provider: provider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Push Settings
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Push SimulationDialog
      SimulationControlDialog.show(tester.element(find.byType(SettingsScreen)));
      await tester.pumpAndSettle();
      expect(find.byType(SimulationControlDialog), findsOneWidget);

      // Trigger adhanAlert
      provider.simulateDisplayState(DisplayState.adhanAlert);
      await tester.pump();
      // Pump successive frames to allow both dialog and route transitions to complete
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }

      // All modals collapsed
      expect(find.byType(SimulationControlDialog), findsNothing);
      expect(find.byType(SettingsScreen), findsNothing);
      expect(provider.displayState, equals(DisplayState.adhanAlert));
    });
  });

  group('Adversarial Stress Test: Tab Cycling & Dirty Input State Preservation across IndexedStack', () {
    testWidgets(
        'ST-08: Full cycle through all 10 tabs with dirty inputs in Tab 0, Tab 1, and Tab 7',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      final List<FlutterErrorDetails> overflowErrors = [];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) {
          overflowErrors.add(details);
        } else {
          originalOnError?.call(details);
        }
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(
        _wrapWithProvider(
          const SettingsScreen(),
          provider: provider,
        ),
      );
      await tester.pumpAndSettle();

      // 1. In Tab 0 (_WilayaPage): enter search query 'تلمسان'
      final wilayaSearchField = find.byType(TextField).first;
      await tester.enterText(wilayaSearchField, 'تلمسان');
      await tester.pumpAndSettle();
      expect(find.text('تلمسان'), findsWidgets);

      // 2. Select Wilaya 13 (تلمسان) to switch to Communes sub-view
      await tester.tap(find.text('تلمسان').last);
      await tester.pumpAndSettle();
      expect(find.text('← العودة لقائمة الولايات'), findsOneWidget);

      // In Communes sub-view: enter commune search query 'منصورة'
      final communeSearchField = find.byType(TextField).first;
      await tester.enterText(communeSearchField, 'منصورة');
      await tester.pumpAndSettle();
      expect(find.text('منصورة'), findsWidgets);

      // 3. Navigate to Tab 7 (إعدادات المسجد): dirty Mosque Name and Marquee text
      await tester.tap(find.text('إعدادات المسجد'));
      await tester.pumpAndSettle();

      final mosqueNameField = find.descendant(
        of: find.ancestor(of: find.text('اسم المسجد'), matching: find.byType(Column)).first,
        matching: find.byType(TextField),
      ).first;
      await tester.enterText(mosqueNameField, 'مسجد التقوى والإيمان');
      await tester.pumpAndSettle();

      // 4. Cycle through ALL 10 tabs sequentially in both directions to stress IndexedStack
      final tabs = [
        'معايرة المواقيت', // 1
        'المظهر والواجهة', // 2
        'الخطوط والأدعية', // 3
        'تأخير الإقامة',   // 4
        'صلاة الجماعة',    // 5
        'التاريخ الهجري',  // 6
        'إعدادات المسجد',  // 7
        'PIN الأمان',      // 8
        'محاكاة واختبار',  // 9
        'الولاية',         // 0
      ];

      for (final tab in tabs) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
      }

      // 5. Verify Tab 0 is STILL in Communes sub-view and search query is STILL 'منصورة'
      expect(find.text('← العودة لقائمة الولايات'), findsOneWidget);
      expect(find.text('منصورة'), findsWidgets);

      // 6. Navigate back to Tab 7 (إعدادات المسجد) and verify Mosque Name text is intact
      await tester.tap(find.text('إعدادات المسجد'));
      await tester.pumpAndSettle();
      expect(find.text('مسجد التقوى والإيمان'), findsWidgets);

      // 7. Verify back action on Tab 7 with focused input unfocuses first
      await tester.tap(mosqueNameField);
      await tester.pumpAndSettle();
      final EditableText nameEditable = tester.widget(
        find.descendant(of: mosqueNameField, matching: find.byType(EditableText)),
      );
      expect(nameEditable.focusNode.hasFocus, isTrue);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(nameEditable.focusNode.hasFocus, isFalse);
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Report any detected layout overflows during the 10-tab cycle
      // ignore: avoid_print
      print('DEBUG ST-08: detected ${overflowErrors.length} overflow errors:');
      for (final e in overflowErrors) {
        // ignore: avoid_print
        print('  -> ${e.exceptionAsString().split('\n').first}');
      }
      FlutterError.onError = originalOnError;
      expect(
        overflowErrors,
        isEmpty,
        reason: 'RenderFlex overflows detected during 10-tab IndexedStack cycling: ${overflowErrors.map((e) => e.exceptionAsString().split('\n').first).toList()}',
      );
    });
  });
}
