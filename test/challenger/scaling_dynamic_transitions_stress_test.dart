import 'dart:convert';
import 'package:flutter/material.dart';
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
import 'package:mosque_display/domain/occasions/islamic_occasions_engine.dart';
import 'package:mosque_display/ui/screens/adhkar_carousel_screen.dart';
import 'package:mosque_display/ui/screens/iqamah_countdown_screen.dart';
import 'package:mosque_display/ui/screens/jumuah_khutbah_screen.dart';
import 'package:mosque_display/ui/screens/main_dashboard_screen.dart';
import 'package:mosque_display/ui/screens/salat_blackout_screen.dart';

import '../scaling/overflow_assertion.dart';
import '../scaling/resolution_matrix.dart';

// ── Extreme Text Payloads ─────────────────────────────────────────────────────

const String extremeMosqueName =
    'جامع الشيخ العلامة الإمام عبد الحميد بن باديس الكبير والمركز الثقافي الإسلامي النموذجي بمحاذاة الساحة المركزية';

const String extremeMarqueeText =
    'تنبيه هام للمصلين الكرام: يرجى تسوية الصفوف وإطفاء الهواتف النقالة وعدم ترك الأطفال في الممرات الخلفية\n'
    'إعلان عن موعد صلاة التراويح وقيام الليل في العشر الأواخر من شهر رمضان المبارك وختم القرآن الكريم\n'
    'دروس فقهية يومية بعد صلاة العصر يلقيها فضيلة الإمام الراتب في رحاب المسجد العامر نفعنا الله بعلمه';

const String ayatAlKursi282Chars =
    'اللهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ '
    'لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ '
    'يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ '
    'وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ';

const String takbiratEid =
    '«اللهُ أَكْبَرُ، اللهُ أَكْبَرُ، اللهُ أَكْبَرُ، لَا إِلَهَ إِلَّا اللهُ، '
    'اللهُ أَكْبَرُ، اللهُ أَكْبَرُ، وَلِلَّهِ الْحَمْدُ، اللهُ أَكْبَرُ كَبِيرًا، '
    'وَالْحَمْدُ لِلَّهِ كَثِيرًا، وَسُبْحَانَ اللهِ بُكْرَةً وَأَصِيلًا»';

// ── Target Resolution Matrix (4:3, 16:10, 720p) ──────────────────────────────

const List<TvResolution> targetStressResolutions = [
  TvResolution(
    id: '1024x768_4_3',
    name: 'XGA 4:3 Non-Standard Display',
    width: 1024,
    height: 768,
    aspectRatio: TvAspectRatio.ar4_3,
  ),
  TvResolution(
    id: '1280x720_16_9',
    name: '720p HD Ready Standard TV',
    width: 1280,
    height: 720,
    aspectRatio: TvAspectRatio.ar16_9,
  ),
  TvResolution(
    id: '1280x800_16_10',
    name: 'WXGA 16:10 Non-Standard Display',
    width: 1280,
    height: 800,
    aspectRatio: TvAspectRatio.ar16_10,
  ),
  TvResolution(
    id: '960x720_4_3',
    name: '720p Narrow 4:3 Boundary Edge Display',
    width: 960,
    height: 720,
    aspectRatio: TvAspectRatio.ar4_3,
  ),
];

// ── Adversarial Mocks & Asset Bundles ─────────────────────────────────────────

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
          nameAr: 'الجزائر الوسطى - المركز العتيق',
          nameFr: 'Alger Centre Ancien',
          latitude: 36.75,
          longitude: 3.05,
        ),
      ];

  @override
  Future<Commune?> getCommuneByCode(int communeCode) async => const Commune(
        code: 1601,
        wilayaCode: 16,
        nameAr: 'الجزائر الوسطى - المركز العتيق',
        nameFr: 'Alger Centre Ancien',
        latitude: 36.75,
        longitude: 3.05,
      );
}

class _AyatAlKursiAssetBundle extends Fake implements AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return jsonEncode([
      {
        'id': 'ayat_al_kursi_stress',
        'arabic': ayatAlKursi282Chars,
        'transliteration': 'Ayat al-Kursi',
        'translation': 'آية الكرسي كاملة (282 حرفاً)',
        'count': 1,
        'reference': 'سورة البقرة: الآية 255',
      }
    ]);
  }
}

Widget _buildStressTestApp({
  required Widget child,
  required DisplayProvider provider,
}) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: ChangeNotifierProvider<DisplayProvider>.value(
      value: provider,
      child: MaterialApp(
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: child,
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

  // ── SUITE 1: Complete Dynamic State Transitions Lifecycle ──────────────────

  group('Challenger Stress Suite 1: Full Dynamic State Lifecycle across Non-Standard Viewports', () {
    for (final res in targetStressResolutions) {
      testWidgets(
        'Dynamic sequence (Standard -> Adhan -> Iqamah -> Blackout -> Adhkar -> Khutbah -> Standard) on $res',
        (tester) async {
          tester.view.physicalSize = res.physicalSize;
          tester.view.devicePixelRatio = res.devicePixelRatio;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final overflowTracker = OverflowReport();
          overflowTracker.attach();
          addTearDown(() => overflowTracker.detach());

          final provider = DisplayProvider(prayerRepo: repo);
          await provider.init();
          await provider.updateSettings(
            provider.settings.copyWith(
              mosqueName: extremeMosqueName,
              marqueeText: extremeMarqueeText,
              selectedCommuneCode: 1601,
              selectedCommuneName: 'الجزائر الوسطى - المركز العتيق',
              watchFaceTemplate: 'classicAstrolabe',
            ),
          );

          // Mount root reactive coordinator
          await tester.pumpWidget(_buildStressTestApp(
            child: const MainDashboardScreen(),
            provider: provider,
          ));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // 1. Assert Standard Mode with extreme mosque name
          expect(find.byType(MainDashboardScreen), findsOneWidget);
          expect(find.text(extremeMosqueName), findsOneWidget);
          expectZeroLayoutOverflow(tester, reason: 'Standard dashboard on $res');
          overflowTracker.assertZeroOverflow('$res Standard');

          // 2. Transition -> Adhan Alert
          provider.simulateDisplayState(
            DisplayState.adhanAlert,
            prayer: Prayer.maghrib,
            customDuration: const Duration(seconds: 90),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(IqamahCountdownScreen), findsOneWidget);
          expect(find.text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'), findsOneWidget);
          expectZeroLayoutOverflow(tester, reason: 'Adhan Alert on $res');
          overflowTracker.assertZeroOverflow('$res Adhan Alert');

          // 3. Transition -> Iqamah Countdown
          provider.simulateDisplayState(
            DisplayState.iqamahCountdown,
            prayer: Prayer.maghrib,
            customDuration: const Duration(minutes: 5),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(IqamahCountdownScreen), findsOneWidget);
          expect(find.text('حَتَّى الإِقَامَةِ'), findsOneWidget);
          expectZeroLayoutOverflow(tester, reason: 'Iqamah Countdown on $res');
          overflowTracker.assertZeroOverflow('$res Iqamah Countdown');

          // 4. Transition -> Salat Blackout
          provider.simulateDisplayState(
            DisplayState.salatBlackout,
            prayer: Prayer.maghrib,
            customDuration: const Duration(minutes: 20),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(SalatBlackoutScreen), findsOneWidget);
          expect(find.text('صلاة المغرب'), findsOneWidget);
          expect(find.text('«اسْتَوُوا وَاعْتَدِلُوا وَسَوُّوا صُفُوفَكُمْ»'), findsOneWidget);
          expectZeroLayoutOverflow(tester, reason: 'Salat Blackout on $res');
          overflowTracker.assertZeroOverflow('$res Salat Blackout');

          // 5. Transition -> Post-Salat Adhkar
          provider.simulateDisplayState(
            DisplayState.postSalatAdhkar,
            prayer: Prayer.maghrib,
            customDuration: const Duration(minutes: 7),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(AdhkarCarouselScreen), findsOneWidget);
          expect(find.text('أذكار ما بعد الصلاة'), findsOneWidget);
          expectZeroLayoutOverflow(tester, reason: 'Post-Salat Adhkar on $res');
          overflowTracker.assertZeroOverflow('$res Post-Salat Adhkar');

          // 6. Transition -> Jumuah Khutbah
          provider.simulateDisplayState(
            DisplayState.jumuahKhutbah,
            prayer: Prayer.dhuhr,
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(JumuahKhutbahScreen), findsOneWidget);
          expect(find.textContaining('خُطْبَةُ يَوْمِ الجُمُعَةِ'), findsOneWidget);
          expect(find.text('أَنْصِتْ وَاسْتَمِعْ رَحِمَكَ اللهُ'), findsOneWidget);
          expect(find.text(extremeMosqueName), findsOneWidget);
          expectZeroLayoutOverflow(tester, reason: 'Jumuah Khutbah on $res');
          overflowTracker.assertZeroOverflow('$res Jumuah Khutbah');

          // 7. Transition -> Standard Display Return
          provider.dismissActiveState();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(MainDashboardScreen), findsOneWidget);
          expect(find.text(extremeMosqueName), findsOneWidget);
          expectZeroLayoutOverflow(tester, reason: 'Return to Standard on $res');
          overflowTracker.assertZeroOverflow('$res Return to Standard');
        },
      );
    }
  });

  // ── SUITE 2: Ramadan Fasting Dynamic Sequence & Occasion Banners ───────────

  group('Challenger Stress Suite 2: Ramadan Fasting & Extended Occasion Notices on 4:3 & 720p', () {
    for (final res in targetStressResolutions) {
      testWidgets(
        'Ramadan fasting occasion sequence with 2x3 grid reflow on $res',
        (tester) async {
          tester.view.physicalSize = res.physicalSize;
          tester.view.devicePixelRatio = res.devicePixelRatio;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final overflowTracker = OverflowReport();
          overflowTracker.attach();
          addTearDown(() => overflowTracker.detach());

          final provider = DisplayProvider(prayerRepo: repo);
          await provider.init();
          await provider.simulateOccasion(OccasionType.ramadan);
          await provider.updateSettings(
            provider.settings.copyWith(
              mosqueName: extremeMosqueName,
              marqueeText: extremeMarqueeText,
              watchFaceTemplate: 'modernHorizontal',
              showFastingTimes: true,
            ),
          );

          await tester.pumpWidget(_buildStressTestApp(
            child: const MainDashboardScreen(),
            provider: provider,
          ));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Verify Ramadan occasion banner and fasting labels
          expect(find.textContaining('رمضان المبارك'), findsWidgets);
          expect(find.textContaining('الإمساك:'), findsWidgets);
          expect(find.textContaining('الإفطار:'), findsWidgets);
          expectZeroLayoutOverflow(tester, reason: 'Ramadan modernHorizontal on $res');
          overflowTracker.assertZeroOverflow('$res Ramadan Standard');

          // Transition to Iqamah Countdown (showing Ramadan fasting supplication)
          provider.simulateDisplayState(
            DisplayState.iqamahCountdown,
            prayer: Prayer.maghrib,
            customDuration: const Duration(minutes: 10),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(IqamahCountdownScreen), findsOneWidget);
          expect(find.textContaining('رَمَضَانَ'), findsWidgets);
          expectZeroLayoutOverflow(tester, reason: 'Ramadan Iqamah on $res');
          overflowTracker.assertZeroOverflow('$res Ramadan Iqamah');

          // Return to Standard
          provider.dismissActiveState();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(MainDashboardScreen), findsOneWidget);
          expectZeroLayoutOverflow(tester, reason: 'Return to Ramadan Standard on $res');
          overflowTracker.assertZeroOverflow('$res Return to Ramadan Standard');
        },
      );
    }
  });

  // ── SUITE 3: Ayat al-Kursi (282 chars) and Takbirat Extreme Text Stress ──────

  group('Challenger Stress Suite 3: Ayat al-Kursi (282 chars) and Takbirat in Active States', () {
    for (final res in targetStressResolutions) {
      testWidgets(
        'AdhkarCarousel renders Ayat al-Kursi 282 chars without overflow on $res',
        (tester) async {
          tester.view.physicalSize = res.physicalSize;
          tester.view.devicePixelRatio = res.devicePixelRatio;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final overflowTracker = OverflowReport();
          overflowTracker.attach();
          addTearDown(() => overflowTracker.detach());

          final provider = DisplayProvider(prayerRepo: repo);
          await provider.init();
          provider.triggerAdhkarOnDemand();

          await tester.pumpWidget(_buildStressTestApp(
            child: AdhkarCarouselScreen(assetBundle: _AyatAlKursiAssetBundle()),
            provider: provider,
          ));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(find.textContaining('الْحَيُّ الْقَيُّومُ'), findsOneWidget);
          expect(find.textContaining('282 حرفاً'), findsOneWidget);
          expectZeroLayoutOverflow(tester, reason: 'Ayat al-Kursi 282 chars on $res');
          overflowTracker.assertZeroOverflow('$res Ayat al-Kursi');
        },
      );

      testWidgets(
        'Iqamah countdown renders Eid Takbirat without overflow on $res',
        (tester) async {
          tester.view.physicalSize = res.physicalSize;
          tester.view.devicePixelRatio = res.devicePixelRatio;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final overflowTracker = OverflowReport();
          overflowTracker.attach();
          addTearDown(() => overflowTracker.detach());

          final provider = DisplayProvider(prayerRepo: repo);
          await provider.init();
          await provider.simulateOccasion(OccasionType.eidFitr);
          provider.simulateDisplayState(
            DisplayState.iqamahCountdown,
            prayer: Prayer.fajr,
            customDuration: const Duration(minutes: 15),
          );

          await tester.pumpWidget(_buildStressTestApp(
            child: const IqamahCountdownScreen(),
            provider: provider,
          ));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(find.textContaining('تَكْبِيرَاتُ'), findsOneWidget);
          expect(find.textContaining('وَلِلَّهِ الْحَمْدُ'), findsOneWidget);
          expectZeroLayoutOverflow(tester, reason: 'Eid Takbirat on $res');
          overflowTracker.assertZeroOverflow('$res Eid Takbirat');
        },
      );
    }
  });

  // ── SUITE 4: Rapid State Cycling Stress Across All 4 Watch Faces ───────────

  group('Challenger Stress Suite 4: Rapid State Cycling across All 4 Watch Faces (1024x768 & 1280x720)', () {
    const watchFaces = [
      'classicAstrolabe',
      'modernHorizontal',
      'grandClock',
      'traditionalMinbar',
    ];

    for (final face in watchFaces) {
      testWidgets(
        'Rapid 3x cycle (Standard->Adhan->Iqamah->Blackout->Adhkar->Khutbah->Standard) on $face at 1024x768',
        (tester) async {
          tester.view.physicalSize = const Size(1024, 768);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final overflowTracker = OverflowReport();
          overflowTracker.attach();
          addTearDown(() => overflowTracker.detach());

          final provider = DisplayProvider(prayerRepo: repo);
          await provider.init();
          await provider.updateSettings(
            provider.settings.copyWith(
              watchFaceTemplate: face,
              mosqueName: extremeMosqueName,
              marqueeText: extremeMarqueeText,
            ),
          );

          await tester.pumpWidget(_buildStressTestApp(
            child: const MainDashboardScreen(),
            provider: provider,
          ));
          await tester.pump();

          // Rapid 3 full cycles
          for (int cycle = 1; cycle <= 3; cycle++) {
            // Standard
            await tester.pump(const Duration(milliseconds: 50));
            expectZeroLayoutOverflow(tester, reason: 'Cycle $cycle Standard ($face)');

            // Adhan Alert
            provider.simulateDisplayState(DisplayState.adhanAlert);
            await tester.pump(const Duration(milliseconds: 50));
            expectZeroLayoutOverflow(tester, reason: 'Cycle $cycle Adhan ($face)');

            // Iqamah Countdown
            provider.simulateDisplayState(DisplayState.iqamahCountdown);
            await tester.pump(const Duration(milliseconds: 50));
            expectZeroLayoutOverflow(tester, reason: 'Cycle $cycle Iqamah ($face)');

            // Salat Blackout
            provider.simulateDisplayState(DisplayState.salatBlackout);
            await tester.pump(const Duration(milliseconds: 50));
            expectZeroLayoutOverflow(tester, reason: 'Cycle $cycle Blackout ($face)');

            // Post-Salat Adhkar
            provider.simulateDisplayState(DisplayState.postSalatAdhkar);
            await tester.pump(const Duration(milliseconds: 50));
            expectZeroLayoutOverflow(tester, reason: 'Cycle $cycle Adhkar ($face)');

            // Jumuah Khutbah
            provider.simulateDisplayState(DisplayState.jumuahKhutbah);
            await tester.pump(const Duration(milliseconds: 50));
            expectZeroLayoutOverflow(tester, reason: 'Cycle $cycle Khutbah ($face)');

            // Back to Standard
            provider.dismissActiveState();
            await tester.pump(const Duration(milliseconds: 50));
            expectZeroLayoutOverflow(tester, reason: 'Cycle $cycle Return ($face)');
          }

          overflowTracker.assertZeroOverflow('Rapid 3x Cycle $face');
        },
      );
    }
  });

  // ── SUITE 5: Maximum UI Scale Factor (1.2x) on 4:3 Non-Standard Displays ───

  group('Challenger Stress Suite 5: Maximum UI Scale (1.2x) on 4:3 (1024x768 & 960x720)', () {
    const narrowResolutions = [
      TvResolution(
        id: '1024x768_4_3_scale1_2',
        name: 'XGA 4:3 @ 1.2x UI Scale',
        width: 1024,
        height: 768,
        aspectRatio: TvAspectRatio.ar4_3,
      ),
      TvResolution(
        id: '960x720_4_3_scale1_2',
        name: '720p Narrow 4:3 @ 1.2x UI Scale',
        width: 960,
        height: 720,
        aspectRatio: TvAspectRatio.ar4_3,
      ),
    ];

    for (final res in narrowResolutions) {
      testWidgets(
        'Dynamic sequence under 1.2x UI Scale on $res with extreme text',
        (tester) async {
          tester.view.physicalSize = res.physicalSize;
          tester.view.devicePixelRatio = res.devicePixelRatio;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final overflowTracker = OverflowReport();
          overflowTracker.attach();
          addTearDown(() => overflowTracker.detach());

          final provider = DisplayProvider(prayerRepo: repo);
          await provider.init();
          await provider.updateSettings(
            provider.settings.copyWith(
              uiScaleFactor: 1.2,
              mosqueName: extremeMosqueName,
              marqueeText: extremeMarqueeText,
              watchFaceTemplate: 'modernHorizontal',
            ),
          );

          await tester.pumpWidget(_buildStressTestApp(
            child: const MainDashboardScreen(),
            provider: provider,
          ));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expectZeroLayoutOverflow(tester, reason: '1.2x UI Scale Standard on $res');

          // Step through Adhan -> Iqamah -> Blackout -> Adhkar -> Khutbah -> Standard
          provider.simulateDisplayState(DisplayState.adhanAlert);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expectZeroLayoutOverflow(tester, reason: '1.2x UI Scale Adhan on $res');

          provider.simulateDisplayState(DisplayState.iqamahCountdown);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expectZeroLayoutOverflow(tester, reason: '1.2x UI Scale Iqamah on $res');

          provider.simulateDisplayState(DisplayState.salatBlackout);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expectZeroLayoutOverflow(tester, reason: '1.2x UI Scale Blackout on $res');

          provider.simulateDisplayState(DisplayState.postSalatAdhkar);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expectZeroLayoutOverflow(tester, reason: '1.2x UI Scale Adhkar on $res');

          provider.simulateDisplayState(DisplayState.jumuahKhutbah);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expectZeroLayoutOverflow(tester, reason: '1.2x UI Scale Khutbah on $res');

          provider.dismissActiveState();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expectZeroLayoutOverflow(tester, reason: '1.2x UI Scale Return on $res');

          overflowTracker.assertZeroOverflow('$res 1.2x UI Scale Sequence');
        },
      );
    }
  });
}
