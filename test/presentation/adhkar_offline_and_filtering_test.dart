import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mosque_display/core/providers/display_provider.dart';
import 'package:mosque_display/core/theme/app_theme.dart';
import 'package:mosque_display/data/datasources/bundled_timetable_datasource.dart';
import 'package:mosque_display/data/models/mosque_settings.dart';
import 'package:mosque_display/data/models/prayer_schedule.dart';
import 'package:mosque_display/data/repositories/prayer_repository.dart';
import 'package:mosque_display/ui/screens/adhkar_carousel_screen.dart';

Widget _wrapWithProvider(
  Widget child, {
  required DisplayProvider provider,
  AssetBundle? customBundle,
}) {
  Widget app = ChangeNotifierProvider<DisplayProvider>.value(
    value: provider,
    child: MaterialApp(
      home: child,
    ),
  );

  if (customBundle != null) {
    app = DefaultAssetBundle(
      bundle: customBundle,
      child: app,
    );
  }

  return app;
}

class _RealAssetBundle extends CachingAssetBundle {
  final String _adhkarJson;
  _RealAssetBundle(this._adhkarJson);

  @override
  Future<ByteData> load(String key) async {
    final bytes = utf8.encode(_adhkarJson);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return _adhkarJson;
  }
}

class _FailingAssetBundle extends Fake implements AssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw const FileSystemException('Simulated asset corruption error');
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    throw const FileSystemException('Simulated asset corruption error');
  }
}

Future<void> _pumpUntilLoaded(WidgetTester tester) async {
  for (int i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(PageView).evaluate().isNotEmpty) return;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BundledTimetableDataSource dataSource;
  late HybridAlgerianPrayerRepository repo;
  late AssetBundle realBundle;

  setUpAll(() async {
    AppTheme.ensureOfflineFonts();
    final file = File('assets/data/algerian_prayer_times.json');
    final content = await file.readAsString();
    dataSource = BundledTimetableDataSource(
      initialCache: json.decode(content) as Map<String, dynamic>,
    );
    repo = HybridAlgerianPrayerRepository(bundledDataSource: dataSource);

    final adhkarFile = File('assets/data/adhkar_content.json');
    final adhkarRaw = await adhkarFile.readAsString();
    realBundle = _RealAssetBundle(adhkarRaw);
  });

  group('Offline Fonts & Prayer-Specific Adhkar Filtering Stress Tests (R1 & R2)', () {
    test('GoogleFonts runtime network fetching is strictly disabled', () {
      AppTheme.ensureOfflineFonts();
      expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
    });

    testWidgets('Prayer-specific filtering: Fajr displays exactly 9 items (7 generic + 2 morning)', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();
      provider.simulateDisplayState(DisplayState.postSalatAdhkar, prayer: Prayer.fajr);

      await tester.pumpWidget(_wrapWithProvider(AdhkarCarouselScreen(key: UniqueKey(), assetBundle: realBundle), provider: provider));
      await _pumpUntilLoaded(tester);

      final pageViewFinder = find.byType(PageView);
      expect(pageViewFinder, findsOneWidget);
      final pageView = tester.widget<PageView>(pageViewFinder);
      expect(pageView.childrenDelegate.estimatedChildCount, equals(9));

      provider.dispose();
    });

    testWidgets('Prayer-specific filtering: Asr & Maghrib display exactly 8 items (7 generic + 1 evening)', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();

      // Test Asr
      provider.simulateDisplayState(DisplayState.postSalatAdhkar, prayer: Prayer.asr);
      await tester.pumpWidget(_wrapWithProvider(AdhkarCarouselScreen(key: UniqueKey(), assetBundle: realBundle), provider: provider));
      await _pumpUntilLoaded(tester);

      var pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.childrenDelegate.estimatedChildCount, equals(8));

      // Test Maghrib
      provider.simulateDisplayState(DisplayState.postSalatAdhkar, prayer: Prayer.maghrib);
      await tester.pumpWidget(_wrapWithProvider(AdhkarCarouselScreen(key: UniqueKey(), assetBundle: realBundle), provider: provider));
      await _pumpUntilLoaded(tester);

      pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.childrenDelegate.estimatedChildCount, equals(8));

      provider.dispose();
    });

    testWidgets('Prayer-specific filtering: Dhuhr & Isha display exactly 7 generic items', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();

      // Test Dhuhr
      provider.simulateDisplayState(DisplayState.postSalatAdhkar, prayer: Prayer.dhuhr);
      await tester.pumpWidget(_wrapWithProvider(AdhkarCarouselScreen(key: UniqueKey(), assetBundle: realBundle), provider: provider));
      await _pumpUntilLoaded(tester);

      var pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.childrenDelegate.estimatedChildCount, equals(7));

      // Test Isha
      provider.simulateDisplayState(DisplayState.postSalatAdhkar, prayer: Prayer.isha);
      await tester.pumpWidget(_wrapWithProvider(AdhkarCarouselScreen(key: UniqueKey(), assetBundle: realBundle), provider: provider));
      await _pumpUntilLoaded(tester);

      pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.childrenDelegate.estimatedChildCount, equals(7));

      provider.dispose();
    });

    testWidgets('On-demand mode (null activePrayer) displays all 10 supplications unfiltered', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();
      provider.triggerAdhkarOnDemand();
      expect(provider.activePrayer, isNull);

      await tester.pumpWidget(_wrapWithProvider(AdhkarCarouselScreen(key: UniqueKey(), assetBundle: realBundle), provider: provider));
      await _pumpUntilLoaded(tester);

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.childrenDelegate.estimatedChildCount, equals(10));

      provider.dispose();
    });

    testWidgets('Asset load failure gracefully falls back to core 3-item tasbih collection without crashing', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();
      provider.triggerAdhkarOnDemand();

      // Inject failing asset bundle directly to widget
      final failingBundle = _FailingAssetBundle();
      await tester.pumpWidget(
        _wrapWithProvider(
          AdhkarCarouselScreen(key: UniqueKey(), assetBundle: failingBundle),
          provider: provider,
          customBundle: failingBundle,
        ),
      );
      await _pumpUntilLoaded(tester);

      expect(tester.takeException(), isNull);
      final pageView = tester.widget<PageView>(find.byType(PageView));
      // Fallback has 3 items
      expect(pageView.childrenDelegate.estimatedChildCount, equals(3));
      expect(find.text('سُبْحَانَ اللهِ'), findsOneWidget);

      provider.dispose();
    });
  });
}
