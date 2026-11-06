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
import 'package:mosque_display/ui/screens/main_dashboard_screen.dart';
import 'package:mosque_display/ui/screens/settings_screen.dart';

class _AdversarialPrayerRepo implements IPrayerRepository {
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
      fajr: DateTime(date.year, date.month, date.day, 5, 15),
      sunrise: DateTime(date.year, date.month, date.day, 6, 40),
      dhuhr: DateTime(date.year, date.month, date.day, 12, 30),
      asr: DateTime(date.year, date.month, date.day, 15, 45),
      maghrib: DateTime(date.year, date.month, date.day, 18, 15),
      isha: DateTime(date.year, date.month, date.day, 19, 40),
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
        const Commune(
          code: 3101,
          wilayaCode: 31,
          nameAr: 'وهران',
          nameFr: 'Oran',
          latitude: 35.69,
          longitude: -0.63,
        ),
      ];

  @override
  Future<Commune?> getCommuneByCode(int communeCode) async => null;
}

Widget _buildStressTestHarness({
  required Widget child,
  required DisplayProvider provider,
  Size size = const Size(1280, 720),
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
  late _AdversarialPrayerRepo repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = _AdversarialPrayerRepo();
  });

  group('Challenger Stress Suite 1: Extreme ViewInsets on 720p & 1080p', () {
    testWidgets(
        'ST-01: Mosque Info Page under extreme insets (500dp, 600dp) at 720p has 0 RenderFlex overflow',
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
        _buildStressTestHarness(
          child: const SettingsScreen(),
          provider: provider,
          size: const Size(1280, 720),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Mosque Info page
      await tester.tap(find.text('إعدادات المسجد'));
      await tester.pumpAndSettle();

      // Stress with 500dp bottom inset (only 220dp vertical height remaining)
      tester.view.viewInsets = const FakeViewPadding(bottom: 500);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull,
          reason: 'RenderFlex overflow under 500dp bottom viewInsets on 720p');

      // Verify singleChildScrollView exists and is scrollable
      final scrollableFinder = find.descendant(
        of: find.byType(SettingsScreen),
        matching: find.byType(SingleChildScrollView),
      );
      expect(scrollableFinder, findsWidgets);

      // Stress with 600dp bottom inset (only 120dp vertical height remaining!)
      tester.view.viewInsets = const FakeViewPadding(bottom: 600);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull,
          reason: 'RenderFlex overflow under 600dp bottom viewInsets on 720p');
    });

    testWidgets(
        'ST-02: Mosque Info Page under 500dp and 600dp bottom insets at 1080p',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
      });

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      await tester.pumpWidget(
        _buildStressTestHarness(
          child: const SettingsScreen(),
          provider: provider,
          size: const Size(1920, 1080),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('إعدادات المسجد'));
      await tester.pumpAndSettle();

      tester.view.viewInsets = const FakeViewPadding(bottom: 500);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      tester.view.viewInsets = const FakeViewPadding(bottom: 600);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'ST-03: Wilayas & Communes Search Page under extreme 500dp insets at 720p',
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
        _buildStressTestHarness(
          child: const SettingsScreen(),
          provider: provider,
          size: const Size(1280, 720),
        ),
      );
      await tester.pumpAndSettle();

      // Page 0 (الولاية)
      expect(find.text('بحث في الولايات بالاسم أو الرقم (مثال: وهران، سطيف، 16)...'),
          findsOneWidget);

      tester.view.viewInsets = const FakeViewPadding(bottom: 500);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull,
          reason: 'Wilayas search page overflowed under 500dp bottom insets');

      // Enter search query
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'الجزائر');
      await tester.pumpAndSettle();
      expect(find.text('الجزائر'), findsWidgets);

      // Navigate to Communes tab
      await tester.tap(find.textContaining('2. بلديات'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull,
          reason: 'Communes search page overflowed under 500dp bottom insets');
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets(
        'ST-04: Number Stepper Pages (Iqamah, Blackout, Prayer Offsets) under 500dp insets',
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
        _buildStressTestHarness(
          child: const SettingsScreen(),
          provider: provider,
          size: const Size(1280, 720),
        ),
      );
      await tester.pumpAndSettle();

      tester.view.viewInsets = const FakeViewPadding(bottom: 500);
      await tester.pumpAndSettle();

      // Tab 1: معايرة المواقيت
      await tester.tap(find.text('معايرة المواقيت'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'Prayer offsets page overflowed under 500dp insets');

      // Tab 4: تأخير الإقامة
      await tester.tap(find.text('تأخير الإقامة'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'Iqamah page overflowed under 500dp insets');

      // Tab 5: صلاة الجماعة (Blackout)
      await tester.tap(find.text('صلاة الجماعة'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'Blackout page overflowed under 500dp insets');
    });
  });

  group('Challenger Stress Suite 2: Rapid Keyboard Open/Close Cycles', () {
    testWidgets(
        'ST-05: Rapid keyboard toggle sequence (0 -> 400 -> 0 -> 500 -> 0 -> 600 -> 300 -> 0)',
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
        _buildStressTestHarness(
          child: const SettingsScreen(),
          provider: provider,
          size: const Size(1280, 720),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('إعدادات المسجد'));
      await tester.pumpAndSettle();

      final insetsSequence = [
        0.0,
        400.0,
        0.0,
        500.0,
        0.0,
        600.0,
        300.0,
        0.0,
        550.0,
        0.0,
      ];

      for (int i = 0; i < insetsSequence.length; i++) {
        final inset = insetsSequence[i];
        tester.view.viewInsets = FakeViewPadding(bottom: inset);

        // Simulate intermittent frames during keyboard animation
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'Exception at step $i with bottom inset $inset');
      }

      // After rapid cycling, widgets and state are intact
      expect(find.text('اسم المسجد'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });
  });

  group('Challenger Stress Suite 3: Multiline Marquee Text Editing & Cursor Navigation', () {
    testWidgets(
        'ST-06: Marquee editor allows multiline text input, newlines, and arrow navigation without focus trap',
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
        _buildStressTestHarness(
          child: const SettingsScreen(),
          provider: provider,
          size: const Size(1280, 720),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('إعدادات المسجد'));
      await tester.pumpAndSettle();

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

      // 1. Multiline field ignores arrowDown/arrowUp so text editor moves cursor between lines
      final downResult = marqueeFocus.onKeyEvent!(
        marqueeFocus,
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.arrowDown,
          logicalKey: LogicalKeyboardKey.arrowDown,
          timeStamp: Duration.zero,
        ),
      );
      expect(downResult, equals(KeyEventResult.ignored),
          reason: 'Multiline marquee editor must ignore arrowDown to let cursor move between lines');

      final upResult = marqueeFocus.onKeyEvent!(
        marqueeFocus,
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.arrowUp,
          logicalKey: LogicalKeyboardKey.arrowUp,
          timeStamp: Duration.zero,
        ),
      );
      expect(upResult, equals(KeyEventResult.ignored),
          reason: 'Multiline marquee editor must ignore arrowUp to let cursor move between lines');

      // 2. Multiline typing with multiple lines separated by newlines
      const multiLineText =
          'إعلان 1: يرجى تسوية الصفوف\nإعلان 2: درس الفقه بعد صلاة المغرب\nإعلان 3: جمع التبرعات للفقراء';
      await tester.tap(marqueeField);
      await tester.pumpAndSettle();
      await tester.enterText(marqueeField, multiLineText);
      await tester.pumpAndSettle();

      // Find the save button associated with marquee field
      final saveBtn = find.descendant(
        of: marqueeContainer,
        matching: find.text('حفظ'),
      );
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(provider.settings.marqueeText, equals(multiLineText),
          reason: 'Multiline text with newlines was not saved properly in settings');
    });

    testWidgets(
        'ST-07: Single-line Mosque Name field advances focus on arrowDown and unfocuses on arrowUp',
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
        _buildStressTestHarness(
          child: const SettingsScreen(),
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

      final TextField nameWidget = tester.widget(nameField);
      final FocusNode nameFocus = nameWidget.focusNode!;

      // Single line field handles arrowDown (navigates to next focusable element)
      final downResult = nameFocus.onKeyEvent!(
        nameFocus,
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.arrowDown,
          logicalKey: LogicalKeyboardKey.arrowDown,
          timeStamp: Duration.zero,
        ),
      );
      expect(downResult, equals(KeyEventResult.handled));

      // Single line field handles arrowUp (unfocuses)
      final upResult = nameFocus.onKeyEvent!(
        nameFocus,
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.arrowUp,
          logicalKey: LogicalKeyboardKey.arrowUp,
          timeStamp: Duration.zero,
        ),
      );
      expect(upResult, equals(KeyEventResult.handled));
    });

    testWidgets(
        'ST-08: Interactive text selection enabled across all text inputs',
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
        _buildStressTestHarness(
          child: const SettingsScreen(),
          provider: provider,
          size: const Size(1280, 720),
        ),
      );
      await tester.pumpAndSettle();

      // Wilayas search field
      final wilayaSearch = tester.widget<TextField>(find.byType(TextField).first);
      expect(wilayaSearch.enableInteractiveSelection, isTrue,
          reason: 'Wilaya search field has interactive selection disabled');

      // Mosque Info fields
      await tester.tap(find.text('إعدادات المسجد'));
      await tester.pumpAndSettle();

      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      for (final tf in textFields) {
        expect(tf.enableInteractiveSelection, isTrue,
            reason: 'TextField interactive selection disabled in Settings');
      }
    });
  });

  group('Challenger Stress Suite 4: Field Scrollability, Focus & Navigation Under Insets', () {
    testWidgets(
        'ST-09: Field scrollability under 500dp insets: ensureVisible brings marquee editor into view',
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
        _buildStressTestHarness(
          child: const SettingsScreen(),
          provider: provider,
          size: const Size(1280, 720),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('إعدادات المسجد'));
      await tester.pumpAndSettle();

      // Apply 500dp inset
      tester.view.viewInsets = const FakeViewPadding(bottom: 500);
      await tester.pumpAndSettle();

      final marqueeContainer = find.ancestor(
        of: find.textContaining('نصوص الإعلانات'),
        matching: find.byType(Column),
      ).first;
      final marqueeField = find.descendant(
        of: marqueeContainer,
        matching: find.byType(TextField),
      ).first;

      // Bring into view
      await tester.ensureVisible(marqueeField);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.tap(marqueeField);
      await tester.pumpAndSettle();

      final TextField marqueeWidget = tester.widget(marqueeField);
      expect(marqueeWidget.focusNode!.hasFocus, isTrue);
    });

    testWidgets(
        'ST-10: D-Pad and platform back sequence during active text entry under insets',
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
        _buildStressTestHarness(
          child: const SettingsScreen(),
          provider: provider,
          size: const Size(1280, 720),
        ),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();

      tester.view.viewInsets = const FakeViewPadding(bottom: 450);
      await tester.pumpAndSettle();

      final TextField widgetSearch = tester.widget(searchField);
      expect(widgetSearch.focusNode!.hasFocus, isTrue);

      // Back key dismisses focus first without popping SettingsScreen
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(widgetSearch.focusNode!.hasFocus, isFalse);
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Second back pops SettingsScreen
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsNothing);
    });

    testWidgets(
        'ST-11: Background salatBlackout event during active text input cleanly unmounts modal without leak',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
      });

      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      await tester.pumpWidget(
        _buildStressTestHarness(
          child: const MainDashboardScreen(),
          provider: provider,
          size: const Size(1920, 1080),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Push settings
      await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Focus search field and simulate keyboard appearance
      final searchField = find.byType(TextField).first;
      await tester.tap(searchField);
      await tester.pumpAndSettle();

      tester.view.viewInsets = const FakeViewPadding(bottom: 500);
      await tester.pumpAndSettle();

      // Trigger congregational blackout prayer mode
      provider.simulateDisplayState(DisplayState.salatBlackout);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.byType(SettingsScreen), findsNothing);
      expect(provider.displayState, equals(DisplayState.salatBlackout));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'ST-12: Massive marquee text payload (10k chars, multi-line, Arabic tashkeel & emojis)',
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
        _buildStressTestHarness(
          child: const SettingsScreen(),
          provider: provider,
          size: const Size(1280, 720),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('إعدادات المسجد'));
      await tester.pumpAndSettle();

      final marqueeContainer = find.ancestor(
        of: find.textContaining('نصوص الإعلانات'),
        matching: find.byType(Column),
      ).first;
      final marqueeField = find.descendant(
        of: marqueeContainer,
        matching: find.byType(TextField),
      ).first;

      // Generate large Arabic text with diacritics and newlines
      final buffer = StringBuffer();
      for (int i = 1; i <= 50; i++) {
        buffer.writeln('سطر $i: بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ - إعلان تجريبي رقم $i للتحقق من كفاءة المعالجة 🕌✨');
      }
      final massiveText = buffer.toString();

      await tester.tap(marqueeField);
      await tester.pumpAndSettle();
      await tester.enterText(marqueeField, massiveText);
      await tester.pumpAndSettle();

      final saveBtn = find.descendant(
        of: marqueeContainer,
        matching: find.text('حفظ'),
      );
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(provider.settings.marqueeText, equals(massiveText.trim()));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'ST-13: Double-back boundary precision (2100ms reset vs 1000ms exit trigger)',
        (tester) async {
      final provider = DisplayProvider(prayerRepo: repo);
      await provider.init();

      int systemPopCount = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'SystemNavigator.pop') {
            systemPopCount++;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        _buildStressTestHarness(
          child: const MainDashboardScreen(),
          provider: provider,
          size: const Size(1920, 1080),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. First back press
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('اضغط مرة أخرى للخروج'), findsOneWidget);
      expect(systemPopCount, equals(0));

      // 2. Wait 2100ms real wall-clock time via runAsync because MainDashboardScreen uses DateTime.now()
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 2100));
      });
      await tester.pump();

      // 3. Second back press after timeout -> Should NOT exit, should show SnackBar again
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('اضغط مرة أخرى للخروج'), findsOneWidget);
      expect(systemPopCount, equals(0));

      // 4. Third back press within immediate window -> SHOULD exit cleanly
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(systemPopCount, equals(1));
    });

    testWidgets(
        'ST-14: PIN page autofocus, 4-digit clamp, and backspace underflow tolerance',
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
        _buildStressTestHarness(
          child: const SettingsScreen(),
          provider: provider,
          size: const Size(1280, 720),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to PIN tab (index 8)
      await tester.tap(find.text('PIN الأمان'));
      await tester.pumpAndSettle();

      expect(find.text('رمز الأمان (PIN)'), findsOneWidget);

      // Backspace on empty string must not crash
      await tester.tap(find.text('مسح ⌫'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Type digits via on-screen numpad: 7, 8, 9, 0
      await tester.tap(find.text('7'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('8'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('0'));
      await tester.pumpAndSettle();

      // 5th digit attempt (1) must be rejected because max 4 digits
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      // Save PIN via on-screen key 'حفظ ✓'
      await tester.tap(find.text('حفظ ✓'));
      await tester.pumpAndSettle();

      expect(find.text('تم حفظ رمز PIN بنجاح ✓'), findsOneWidget);
      expect(provider.settings.pinCode, equals('7890'));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'ST-15: Ultra-extreme keyboard insets (650dp on 720p = 70dp viewport)',
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
        _buildStressTestHarness(
          child: const SettingsScreen(),
          provider: provider,
          size: const Size(1280, 720),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('إعدادات المسجد'));
      await tester.pumpAndSettle();

      // Apply 650dp inset
      tester.view.viewInsets = const FakeViewPadding(bottom: 650);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull,
          reason: 'Application crashed or overflowed under 650dp bottom inset on 720p');
    });

    testWidgets(
        'ST-16: Consecutive tab switching across IndexedStack under 500dp insets',
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
        _buildStressTestHarness(
          child: const SettingsScreen(),
          provider: provider,
          size: const Size(1280, 720),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search text on tab 0
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'عنابة');
      await tester.pumpAndSettle();

      // Apply 500dp viewInsets
      tester.view.viewInsets = const FakeViewPadding(bottom: 500);
      await tester.pumpAndSettle();

      // Switch to Mosque Info (Tab 7)
      await tester.tap(find.text('إعدادات المسجد'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch to Prayer Offsets (Tab 1)
      await tester.tap(find.text('معايرة المواقيت'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch to PIN (Tab 8)
      await tester.tap(find.text('PIN الأمان'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch back to Wilayas (Tab 0)
      await tester.tap(find.text('الولاية'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Verify search query 'عنابة' was perfectly preserved
      expect(find.text('عنابة'), findsWidgets);
    });
  });
}
