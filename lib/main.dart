import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/display_provider.dart';
import 'data/datasources/bundled_timetable_datasource.dart';
import 'data/repositories/prayer_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'ui/screens/main_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce 24/7 TV Display Awake
  try {
    await WakelockPlus.enable();
  } catch (_) {
    // Graceful fallback for headless test runners
  }

  // Lock to TV Landscape Orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize data layer & load persisted settings
  final bundledDataSource = BundledTimetableDataSource();
  await bundledDataSource.preload();
  final prayerRepo = HybridAlgerianPrayerRepository(
    bundledDataSource: bundledDataSource,
  );
  final savedSettings = await SettingsRepository.load();

  final displayProvider = DisplayProvider(
    prayerRepo: prayerRepo,
    initialSettings: savedSettings,
  );
  await displayProvider.init();

  runApp(
    ChangeNotifierProvider<DisplayProvider>.value(
      value: displayProvider,
      child: const MosqueDisplayApp(),
    ),
  );
}

class MosqueDisplayApp extends StatelessWidget {
  const MosqueDisplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منارة المساجد - مواقيت الصلاة',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'DZ'),
      supportedLocales: const [
        Locale('ar', 'DZ'),
        Locale('ar'),
        Locale('fr'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.theme,
      home: const MainDashboardScreen(),
    );
  }
}
