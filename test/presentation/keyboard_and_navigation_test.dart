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
import 'package:mosque_display/ui/screens/main_dashboard_screen.dart';
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

  group('Gboard & Keyboard Insets Verification Suite', () {
    testWidgets(
        'T1: Mosque Info page does not overflow under 400px Gboard insets at 720p',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
      });

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      await tester.pumpWidget(
        _wrapWithProvider(
          const SettingsScreen(),
          provider: provider,
          size: const Size(1280, 720),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Mosque Info page (sidebar item 'إعدادات المسجد')
      await tester.tap(find.text('إعدادات المسجد'));
      await tester.pumpAndSettle();

      expect(find.text('اسم المسجد'), findsOneWidget);
      expect(find.textContaining('نصوص الإعلانات'), findsOneWidget);

      // Simulate Gboard opening with 400px bottom inset
      tester.view.viewInsets = const FakeViewPadding(bottom: 400);
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason:
            'RenderFlex overflow occurred on Mosque Info page when Gboard appeared',
      );
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets(
        'T2: Wilayas search field remains visible and functional under 350px insets',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
      });

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      await tester.pumpWidget(
        _wrapWithProvider(
          const SettingsScreen(),
          provider: provider,
          size: const Size(1280, 720),
        ),
      );
      await tester.pumpAndSettle();

      tester.view.viewInsets = const FakeViewPadding(bottom: 350);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final searchField = find.byType(TextField).first;
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'وهران');
      await tester.pumpAndSettle();
      expect(find.text('وهران'), findsWidgets);
    });

    testWidgets(
        'T3: Text inputs unfocus on tap outside, action submit, and Escape key',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      await tester.pumpWidget(
        _wrapWithProvider(
          const SettingsScreen(),
          provider: provider,
          size: const Size(1280, 720),
        ),
      );
      await tester.pumpAndSettle();

      final searchFieldFinder = find.byType(TextField).first;
      await tester.tap(searchFieldFinder);
      await tester.pumpAndSettle();

      final TextField searchWidget = tester.widget(searchFieldFinder);
      expect(searchWidget.focusNode!.hasFocus, isTrue);

      // 1. Unfocus on tap outside (tapping header area outside TextField)
      await tester.tap(find.text('الموقع الجغرافي وحساب المواقيت (الولايات والبلديات)'));
      await tester.pumpAndSettle();
      expect(searchWidget.focusNode!.hasFocus, isFalse);

      // 2. Unfocus on action submit
      await tester.tap(searchFieldFinder);
      await tester.pumpAndSettle();
      expect(searchWidget.focusNode!.hasFocus, isTrue);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(searchWidget.focusNode!.hasFocus, isFalse);

      // 3. Unfocus on Escape key
      await tester.tap(searchFieldFinder);
      await tester.pumpAndSettle();
      expect(searchWidget.focusNode!.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(searchWidget.focusNode!.hasFocus, isFalse);
    });

    testWidgets(
        'T4: Single-line Mosque Name saves on submitted, and multiline allows arrow keys',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      await tester.pumpWidget(
        _wrapWithProvider(
          const SettingsScreen(),
          provider: provider,
          size: const Size(1280, 720),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('إعدادات المسجد'));
      await tester.pumpAndSettle();

      final nameContainer = find.ancestor(
        of: find.text('اسم المسجد'),
        matching: find.byType(Column),
      ).first;
      final nameField = find.descendant(
        of: nameContainer,
        matching: find.byType(TextField),
      ).first;

      // 1. Single line onSubmitted saves input
      await tester.tap(nameField);
      await tester.pumpAndSettle();
      await tester.enterText(nameField, 'مسجد النور الكبير');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(provider.settings.mosqueName, equals('مسجد النور الكبير'));

      // 2. Multiline marquee editor allows arrow keys without jumping focus
      final marqueeContainer = find.ancestor(
        of: find.textContaining('نصوص الإعلانات'),
        matching: find.byType(Column),
      ).first;
      final marqueeField = find.descendant(
        of: marqueeContainer,
        matching: find.byType(TextField),
      ).first;
      final TextField marqueeWidget = tester.widget(marqueeField);
      final FocusNode marqueeFocus = marqueeWidget.focusNode!;

      // Multiline field passes arrowDown to text editor (ignored by navigation handler, not consumed)
      final multilineResult = marqueeFocus.onKeyEvent!(
        marqueeFocus,
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.arrowDown,
          logicalKey: LogicalKeyboardKey.arrowDown,
          timeStamp: Duration.zero,
        ),
      );
      expect(multilineResult, equals(KeyEventResult.ignored));

      // Single-line field handles arrowDown to advance focus
      final TextField nameWidget = tester.widget(nameField);
      final FocusNode nameFocus = nameWidget.focusNode!;
      final singlelineResult = nameFocus.onKeyEvent!(
        nameFocus,
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.arrowDown,
          logicalKey: LogicalKeyboardKey.arrowDown,
          timeStamp: Duration.zero,
        ),
      );
      expect(singlelineResult, equals(KeyEventResult.handled));
    });
  });

  group('Navigation Architecture & Back-Stack Verification Suite', () {
    testWidgets(
        'T5: PopScope intercepts platform back to exit Communes sub-view before popping screen',
        (tester) async {
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

      // Open Settings
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Open Communes sub-view
      await tester.tap(find.textContaining('2. بلديات'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('← العودة لقائمة الولايات'), findsOneWidget);

      // Simulate Android platform back
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Sub-view exited back to Wilayas list, SettingsScreen remains active
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('← العودة لقائمة الولايات'), findsNothing);

      // Second back pops SettingsScreen to dashboard
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.byType(MainDashboardScreen), findsOneWidget);
    });

    testWidgets(
        'T6: Focused TextField unfocuses on back action without popping SettingsScreen',
        (tester) async {
      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      await tester.pumpWidget(
        _wrapWithProvider(
          const SettingsScreen(),
          provider: provider,
        ),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();

      final EditableText editableText = tester.widget(
        find.descendant(of: searchField, matching: find.byType(EditableText)),
      );
      expect(editableText.focusNode.hasFocus, isTrue);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Field loses focus, screen NOT popped
      expect(editableText.focusNode.hasFocus, isFalse);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets(
        'T7: Input values and display state survive navigation transitions and keyboard insets via IndexedStack',
        (tester) async {
      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: ChangeNotifierProvider<DisplayProvider>.value(
            value: provider,
            child: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'قسنطينة');
      await tester.pumpAndSettle();

      // Switch to Prayer Offsets tab
      await tester.tap(find.text('معايرة المواقيت'));
      await tester.pumpAndSettle();

      // Switch back to Wilaya tab
      await tester.tap(find.text('الولاية'));
      await tester.pumpAndSettle();

      // Search query 'قسنطينة' must be preserved due to IndexedStack
      expect(find.text('قسنطينة'), findsWidgets);
    });

    testWidgets(
        'T8: MainDashboardScreen root route double-back handling',
        (tester) async {
      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      bool didInvokeSystemPop = false;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'SystemNavigator.pop') {
            didInvokeSystemPop = true;
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

      // 1. First back press shows SnackBar
      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(find.text('اضغط مرة أخرى للخروج'), findsOneWidget);
      expect(didInvokeSystemPop, isFalse);

      // 2. Second back press within 2 seconds calls SystemNavigator.pop
      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(didInvokeSystemPop, isTrue);
    });

    testWidgets(
        'T9: DuaShowcaseScreen captures remote keys with autofocus and escapes cleanly',
        (tester) async {
      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      await tester.pumpWidget(
        _wrapWithProvider(
          const DuaShowcaseScreen(),
          provider: provider,
        ),
      );
      await tester.pumpAndSettle();

      // DuaShowcaseScreen Focus widget has autofocus: true
      final focusFinder = find.descendant(
        of: find.byType(DuaShowcaseScreen),
        matching: find.byType(Focus),
      ).first;
      final Focus focusWidget = tester.widget(focusFinder);
      expect(focusWidget.autofocus, isTrue);

      // Navigate with TV remote keys
      await tester.sendKeyEvent(LogicalKeyboardKey.bracketLeft);
      await tester.pumpAndSettle();

      // Escape key pops the screen
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'T10: SimulationControlDialog autofocus and remote back dismisses dialog',
        (tester) async {
      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      await tester.pumpWidget(
        _wrapWithProvider(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => SimulationControlDialog.show(ctx),
              child: const Text('Open Dialog'),
            ),
          ),
          provider: provider,
        ),
      );
      await tester.pumpAndSettle();

      // Open Dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(SimulationControlDialog), findsOneWidget);

      // Send remote back / escape key
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(SimulationControlDialog), findsNothing);
    });

    testWidgets(
        'T11: Transition to salatBlackout or adhanAlert automatically pops pushed modal routes',
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

      // Push SettingsScreen over Dashboard
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Congregational prayer blackout starts
      provider.simulateDisplayState(DisplayState.salatBlackout);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      // Modal SettingsScreen was automatically popped, displaying the blackout screen
      expect(find.byType(SettingsScreen), findsNothing);
      expect(provider.displayState, equals(DisplayState.salatBlackout));
    });
  });
}
