import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart';
import 'package:mosque_display/core/providers/display_provider.dart';
import 'package:mosque_display/core/services/remote_admin_server.dart';
import 'package:mosque_display/data/datasources/bundled_timetable_datasource.dart';
import 'package:mosque_display/data/models/mosque_settings.dart';
import 'package:mosque_display/data/models/prayer_schedule.dart';
import 'package:mosque_display/data/repositories/prayer_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BundledTimetableDataSource dataSource;
  late HybridAlgerianPrayerRepository repo;
  late DisplayProvider provider;
  late RemoteAdminServer server;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final file = File('assets/data/algerian_prayer_times.json');
    final content = await file.readAsString();
    dataSource = BundledTimetableDataSource(
      initialCache: json.decode(content) as Map<String, dynamic>,
    );
    repo = HybridAlgerianPrayerRepository(bundledDataSource: dataSource);
    provider = DisplayProvider(
      prayerRepo: repo,
      initialSettings: const MosqueSettings(remoteAdminEnabled: false),
    );
    await provider.init();

    server = RemoteAdminServer(
      displayProvider: provider,
      port: 8899,
      sessionToken: 'test_token_12345',
    );
    await server.start();
  });

  tearDown(() async {
    await server.stop();
    provider.dispose();
  });

  group('RemoteAdminServer Unit & API Tests', () {
    test('Server starts on specified port and reports active status and tokens', () {
      expect(server.isRunning, isTrue);
      expect(server.activePort, equals(8899));
      expect(server.sessionToken, equals('test_token_12345'));
      expect(server.directUrl, contains('8899'));
      expect(server.pairingUrl, contains('token=test_token_12345'));
    });

    test('GET / serves complete self-contained offline HTML web dashboard', () async {
      final req = Request('GET', Uri.parse('http://localhost:8899/?token=test_token_12345'));
      final res = await server.handler(req);

      expect(res.statusCode, equals(200));
      expect(res.headers['content-type'], contains('text/html'));
      final body = await res.readAsString();
      expect(body, contains('منارة المساجد'));
      expect(body, contains('لوحة الإدارة'));
      expect(body, contains('خطبة الجمعة'));
      expect(body, contains('صلاة الجماعة'));

      // Guarantees zero external network dependencies
      expect(body, isNot(contains('http://cdn')));
      expect(body, isNot(contains('https://cdn')));
      expect(body, isNot(contains('fonts.googleapis.com')));
    });

    test('GET /api/status returns live display and prayer status JSON', () async {
      final req = Request('GET', Uri.parse('http://localhost:8899/api/status?token=test_token_12345'));
      final res = await server.handler(req);

      expect(res.statusCode, equals(200));
      final jsonStr = await res.readAsString();
      final data = json.decode(jsonStr) as Map<String, dynamic>;

      expect(data['online'], isTrue);
      expect(data['mosqueName'], equals('مسجد الفتح'));
      expect(data['displayState'], equals('standard'));
      expect(data['displayStateAr'], contains('الرئيسية'));
      expect(data['isFriday'], isNotNull);
      expect(data['countdownSeconds'], isNotNull);
    });

    test('GET /api/settings returns serialized mosque settings', () async {
      final req = Request('GET', Uri.parse('http://localhost:8899/api/settings?token=test_token_12345'));
      final res = await server.handler(req);

      expect(res.statusCode, equals(200));
      final jsonStr = await res.readAsString();
      final data = json.decode(jsonStr) as Map<String, dynamic>;

      expect(data['settings'], isNotNull);
      final settings = data['settings'] as Map<String, dynamic>;
      expect(settings['selectedWilayaCode'], equals(16));
      expect(settings['pinCode'], isNull); // Sanitized to prevent leaking master PIN
      expect(settings['iqamahDelays']['jumuah'], equals(40));
    });

    test('GET /api/settings rejects unauthorized requests without token or PIN to prevent PIN leaks', () async {
      final req = Request('GET', Uri.parse('http://localhost:8899/api/settings'));
      final res = await server.handler(req);

      expect(res.statusCode, equals(403));
      final body = await res.readAsString();
      expect(body, contains('رمز الدخول أو رمز PIN مطلوب'));
    });

    test('POST /api/settings rejects unauthorized requests without token or PIN', () async {
      final payload = json.encode({
        'settings': {'mosqueName': 'مسجد النور'},
      });
      final req = Request(
        'POST',
        Uri.parse('http://localhost:8899/api/settings'),
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );
      final res = await server.handler(req);

      expect(res.statusCode, equals(403));
      expect(provider.settings.mosqueName, equals('مسجد الفتح')); // unchanged
    });

    test('POST /api/settings accepts valid token and updates provider and settings', () async {
      final payload = json.encode({
        'token': 'test_token_12345',
        'settings': {
          'mosqueName': 'مسجد القدس الشريف',
          'marqueeText': 'إعلان هام: درس الجمعة بعد صلاة المغرب',
          'selectedWilayaCode': 31,
          'iqamahDelays': {
            'fajr': 25,
            'dhuhr': 20,
            'asr': 20,
            'maghrib': 7,
            'isha': 20,
            'jumuah': 45,
          },
        },
      });
      final req = Request(
        'POST',
        Uri.parse('http://localhost:8899/api/settings'),
        headers: {
          'Content-Type': 'application/json',
          'X-Admin-Token': 'test_token_12345',
        },
        body: payload,
      );
      final res = await server.handler(req);

      expect(res.statusCode, equals(200));
      final resStr = await res.readAsString();
      final resData = json.decode(resStr) as Map<String, dynamic>;
      expect(resData['success'], isTrue);

      expect(provider.settings.mosqueName, equals('مسجد القدس الشريف'));
      expect(provider.settings.selectedWilayaCode, equals(31));
      expect(provider.settings.iqamahDelays.jumuah, equals(45));
      expect(provider.settings.iqamahDelays.fajr, equals(25));
    });

    test('POST /api/settings authenticates using PIN header when token is absent', () async {
      final payload = json.encode({
        'settings': {'mosqueName': 'مسجد الإحسان'},
      });
      final req = Request(
        'POST',
        Uri.parse('http://localhost:8899/api/settings'),
        headers: {
          'Content-Type': 'application/json',
          'X-Pin-Code': '0000', // Matches default PIN
        },
        body: payload,
      );
      final res = await server.handler(req);

      expect(res.statusCode, equals(200));
      expect(provider.settings.mosqueName, equals('مسجد الإحسان'));
    });

    test('POST /api/action executes remote actions on DisplayProvider', () async {
      // 1. Trigger Jumu'ah Khutbah mode
      final jumuahReq = Request(
        'POST',
        Uri.parse('http://localhost:8899/api/action'),
        headers: {
          'Content-Type': 'application/json',
          'X-Admin-Token': 'test_token_12345',
        },
        body: json.encode({'action': 'jumuah', 'token': 'test_token_12345'}),
      );
      final jumuahRes = await server.handler(jumuahReq);
      expect(jumuahRes.statusCode, equals(200));
      expect(provider.displayState, equals(DisplayState.jumuahKhutbah));
      expect(provider.activePrayer, equals(Prayer.dhuhr));

      // 2. Trigger early prayer blackout
      final blackoutReq = Request(
        'POST',
        Uri.parse('http://localhost:8899/api/action'),
        headers: {
          'Content-Type': 'application/json',
          'X-Admin-Token': 'test_token_12345',
        },
        body: json.encode({'action': 'blackout', 'token': 'test_token_12345'}),
      );
      final blackoutRes = await server.handler(blackoutReq);
      expect(blackoutRes.statusCode, equals(200));
      expect(provider.displayState, equals(DisplayState.salatBlackout));

      // 3. Trigger Post-Salat Adhkar
      final adhkarReq = Request(
        'POST',
        Uri.parse('http://localhost:8899/api/action'),
        headers: {
          'Content-Type': 'application/json',
          'X-Admin-Token': 'test_token_12345',
        },
        body: json.encode({'action': 'adhkar', 'token': 'test_token_12345'}),
      );
      final adhkarRes = await server.handler(adhkarReq);
      expect(adhkarRes.statusCode, equals(200));
      expect(provider.displayState, equals(DisplayState.postSalatAdhkar));

      // 4. Dismiss to Standard
      final dismissReq = Request(
        'POST',
        Uri.parse('http://localhost:8899/api/action'),
        headers: {
          'Content-Type': 'application/json',
          'X-Admin-Token': 'test_token_12345',
        },
        body: json.encode({'action': 'dismiss', 'token': 'test_token_12345'}),
      );
      final dismissRes = await server.handler(dismissReq);
      expect(dismissRes.statusCode, equals(200));
      expect(provider.displayState, equals(DisplayState.standard));
    });

    test('POST /api/settings rejects invalid PIN format with badRequest', () async {
      final payload = json.encode({
        'token': 'test_token_12345',
        'settings': {
          'pinCode': '123', // invalid 3-digit PIN
        },
      });
      final req = Request(
        'POST',
        Uri.parse('http://localhost:8899/api/settings'),
        headers: {
          'Content-Type': 'application/json',
          'X-Admin-Token': 'test_token_12345',
        },
        body: payload,
      );
      final res = await server.handler(req);

      expect(res.statusCode, equals(400));
      final resBody = await res.readAsString();
      expect(resBody, contains('رمز PIN يجب أن يتكون من 4 أرقام'));
      expect(provider.settings.pinCode, equals('0000')); // unchanged
    });

    test('DisplayProvider regenerateRemoteAdminToken updates token and notifies listeners', () async {
      await provider.startRemoteAdminServer(port: 8898, persist: false);
      final oldToken = provider.remoteAdminServer!.sessionToken;
      var notified = false;
      provider.addListener(() => notified = true);

      provider.regenerateRemoteAdminToken();

      expect(provider.remoteAdminServer!.sessionToken, isNot(equals(oldToken)));
      expect(notified, isTrue);
      await provider.stopRemoteAdminServer(persist: false);
    });
  });
}
