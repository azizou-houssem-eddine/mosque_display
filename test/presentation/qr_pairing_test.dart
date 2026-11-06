import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mosque_display/core/providers/display_provider.dart';
import 'package:mosque_display/data/datasources/bundled_timetable_datasource.dart';
import 'package:mosque_display/data/models/mosque_settings.dart';
import 'package:mosque_display/data/repositories/prayer_repository.dart';
import 'package:mosque_display/ui/widgets/qr_pairing_dialog.dart';
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

  group('QR Pairing & Remote Admin UI Tests', () {
    testWidgets('QrPairingDialog renders QR code, IP, Port, PIN, and instructions', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: true, remoteAdminPort: 8890),
      );
      addTearDown(() async {
        await tester.runAsync(() => provider.stopRemoteAdminServer());
        provider.dispose();
      });

      await tester.runAsync(() async {
        await provider.init();
      });

      await tester.pumpWidget(_wrapWithProvider(const QrPairingDialog(), provider: provider));
      await tester.pump();
      await tester.pumpAndSettle();

      // Check title and instructions
      expect(find.textContaining('الاقتران والتحكم اللاسلكي'), findsOneWidget);
      expect(find.textContaining('امسح الرمز بكاميرا الهاتف'), findsOneWidget);
      expect(find.text('اتصل بشبكة المسجد'), findsOneWidget);
      expect(find.text('امسح رمز الاستجابة السريعة'), findsOneWidget);

      // Check QR Image View widget
      expect(find.byType(QrImageView), findsOneWidget);

      // Check credentials
      expect(find.text('****'), findsOneWidget); // Masked PIN for TV security
      expect(find.text('8890'), findsOneWidget); // Port

      // Check close button
      final closeButton = find.byTooltip('إغلاق (Esc / Q)');
      expect(closeButton, findsOneWidget);
    });

    testWidgets('Pressing Q on MainDashboardScreen opens QrPairingDialog', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: true, remoteAdminPort: 8891),
      );
      addTearDown(() async {
        await tester.runAsync(() => provider.stopRemoteAdminServer());
        provider.dispose();
      });

      await tester.runAsync(() async {
        await provider.init();
      });

      await tester.pumpWidget(_wrapWithProvider(const MainDashboardScreen(), provider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(QrPairingDialog), findsNothing);

      // Press key 'Q'
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(QrPairingDialog), findsOneWidget);

      // Press key 'Q' again to dismiss
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(QrPairingDialog), findsNothing);
    });

    testWidgets('Tapping "التحكم (QR)" button in top nav opens QrPairingDialog', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: true, remoteAdminPort: 8892),
      );
      addTearDown(() async {
        await tester.runAsync(() => provider.stopRemoteAdminServer());
        provider.dispose();
      });

      await tester.runAsync(() async {
        await provider.init();
      });

      await tester.pumpWidget(_wrapWithProvider(const MainDashboardScreen(), provider: provider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final qrNavButton = find.text('التحكم (QR)');
      expect(qrNavButton, findsOneWidget);

      await tester.tap(qrNavButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(QrPairingDialog), findsOneWidget);
    });

    testWidgets('Settings screen Tab 10 (التحكم عن بعد (QR)) renders RemoteAdminPage with QR and port config', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: true, remoteAdminPort: 8893),
      );
      addTearDown(() async {
        await tester.runAsync(() => provider.stopRemoteAdminServer());
        provider.dispose();
      });

      await tester.runAsync(() async {
        await provider.init();
      });

      await tester.pumpWidget(_wrapWithProvider(const SettingsScreen(), provider: provider));
      await tester.pumpAndSettle();

      // Find Tab 10
      final tab10 = find.text('التحكم عن بعد (QR)');
      expect(tab10, findsOneWidget);

      await tester.tap(tab10);
      await tester.pumpAndSettle();

      // Verify remote admin page contents
      expect(find.text('التحكم عن بعد والاقتران اللاسلكي (QR)'), findsWidgets);
      expect(find.text('تفعيل خادم الإدارة اللاسلكية عبر شبكة Wi-Fi المحلية'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('منفذ خادم الويب (Port)'), findsOneWidget);
    });
  });
}
