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
import 'package:mosque_display/domain/occasions/islamic_occasions_engine.dart';

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

  group('RemoteAdminServer Concurrency & Security Stress Tests (R2)', () {
    test('Port collision fallback: automatically binds candidatePort++ when port is preoccupied', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();

      const occupiedPort = 8870;
      final blocker = await ServerSocket.bind(InternetAddress.anyIPv4, occupiedPort);

      final server = RemoteAdminServer(
        displayProvider: provider,
        port: occupiedPort,
        sessionToken: 'stress_token_port',
      );

      try {
        await server.start();
        expect(server.isRunning, isTrue);
        expect(server.activePort, equals(occupiedPort + 1));
        expect(server.pairingUrl, contains(':${occupiedPort + 1}/?token='));
      } finally {
        await server.stop();
        await blocker.close();
        provider.dispose();
      }
    });

    test('60 Concurrent HTTP requests: thread safety, serialized settings updates, and status queries', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(
          remoteAdminEnabled: false,
          mosqueName: 'Initial Mosque',
          marqueeText: 'Initial Marquee',
        ),
      );
      await provider.init();

      final server = RemoteAdminServer(
        displayProvider: provider,
        port: 8872,
        sessionToken: 'stress_token_concurrency',
      );
      await server.start();

      const int requestCount = 60;
      final futures = <Future<Response>>[];

      for (int i = 0; i < requestCount; i++) {
        final mode = i % 3;
        if (mode == 0) {
          // POST /api/settings (Serialized update)
          final payload = json.encode({
            'token': 'stress_token_concurrency',
            'settings': {
              'mosqueName': 'Mosque Concurrency #$i',
              'marqueeText': 'Ticker Text #$i',
            },
          });
          final req = Request(
            'POST',
            Uri.parse('http://localhost:8872/api/settings'),
            body: payload,
            headers: {'content-type': 'application/json'},
          );
          futures.add(Future.value(server.handler(req)));
        } else if (mode == 1) {
          // POST /api/action (Simulate action)
          final payload = json.encode({
            'token': 'stress_token_concurrency',
            'action': 'simulateState',
            'state': 'iqamahCountdown',
            'prayer': 'asr',
            'seconds': 300,
          });
          final req = Request(
            'POST',
            Uri.parse('http://localhost:8872/api/action'),
            body: payload,
            headers: {'content-type': 'application/json'},
          );
          futures.add(Future.value(server.handler(req)));
        } else {
          // GET /api/status
          final req = Request(
            'GET',
            Uri.parse('http://localhost:8872/api/status?token=stress_token_concurrency'),
          );
          futures.add(Future.value(server.handler(req)));
        }
      }

      final responses = await Future.wait(futures);

      expect(responses.length, equals(requestCount));
      for (final res in responses) {
        expect(res.statusCode, equals(200));
      }

      // Assert state integrity: final mosqueName is one of the valid concurrent updates
      expect(provider.settings.mosqueName, contains('Mosque Concurrency #'));
      expect(provider.settings.marqueeText, contains('Ticker Text #'));

      await server.stop();
      provider.dispose();
    });

    test('Brute-force PIN rate-limiting: 5 consecutive failures triggers 60s lockout (HTTP 429)', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(
          remoteAdminEnabled: false,
          pinCode: '1234',
        ),
      );
      await provider.init();

      final server = RemoteAdminServer(
        displayProvider: provider,
        port: 8873,
        sessionToken: 'stress_token_pin',
      );
      await server.start();

      expect(server.isPinLockedOut, isFalse);
      expect(server.failedPinAttempts, equals(0));

      // Attempt 1 - 4: Invalid PINs yield 403 Forbidden
      for (int i = 1; i <= 4; i++) {
        final req = Request(
          'POST',
          Uri.parse('http://localhost:8873/api/action'),
          body: json.encode({'pin': '999$i', 'action': 'dismiss'}),
          headers: {'content-type': 'application/json'},
        );
        final res = await server.handler(req);
        expect(res.statusCode, equals(403));
        expect(server.failedPinAttempts, equals(i));
        expect(server.isPinLockedOut, isFalse);
      }

      // Attempt 5: 5th failure triggers lockout -> 429 Too Many Requests
      final req5 = Request(
        'POST',
        Uri.parse('http://localhost:8873/api/action'),
        body: json.encode({'pin': '9995', 'action': 'dismiss'}),
        headers: {'content-type': 'application/json'},
      );
      final res5 = await server.handler(req5);
      expect(res5.statusCode, equals(429));
      final body5 = json.decode(await res5.readAsString()) as Map<String, dynamic>;
      expect(body5['lockedOut'], isTrue);
      expect(body5['error'], contains('تم قفل'));
      expect(server.isPinLockedOut, isTrue);
      expect(server.pinLockoutRemaining, isNotNull);

      // Attempt 6: Even with correct PIN, locked out requests are rejected with 429
      final req6 = Request(
        'POST',
        Uri.parse('http://localhost:8873/api/action'),
        body: json.encode({'pin': '1234', 'action': 'dismiss'}),
        headers: {'content-type': 'application/json'},
      );
      final res6 = await server.handler(req6);
      expect(res6.statusCode, equals(429));

      // Valid session token bypasses PIN lockout (authorized admin retains access)
      final reqToken = Request(
        'POST',
        Uri.parse('http://localhost:8873/api/action'),
        body: json.encode({'token': 'stress_token_pin', 'action': 'dismiss'}),
        headers: {'content-type': 'application/json'},
      );
      final resToken = await server.handler(reqToken);
      expect(resToken.statusCode, equals(200));

      await server.stop();
      provider.dispose();
    });

    test('Sensitive data sanitization: GET and POST /api/settings never expose pinCode in JSON responses', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(
          remoteAdminEnabled: false,
          pinCode: '7890',
        ),
      );
      await provider.init();

      final server = RemoteAdminServer(
        displayProvider: provider,
        port: 8874,
        sessionToken: 'stress_token_sanitize',
      );
      await server.start();

      // GET /api/settings
      final getReq = Request(
        'GET',
        Uri.parse('http://localhost:8874/api/settings?token=stress_token_sanitize'),
      );
      final getRes = await server.handler(getReq);
      expect(getRes.statusCode, equals(200));
      final getData = json.decode(await getRes.readAsString()) as Map<String, dynamic>;
      final getSettings = getData['settings'] as Map<String, dynamic>;
      expect(getSettings.containsKey('pinCode'), isFalse);
      expect(getData['isCustomPinConfigured'], isTrue);

      // POST /api/settings
      final postReq = Request(
        'POST',
        Uri.parse('http://localhost:8874/api/settings'),
        body: json.encode({
          'token': 'stress_token_sanitize',
          'settings': {'mosqueName': 'Sanitized Mosque'},
        }),
        headers: {'content-type': 'application/json'},
      );
      final postRes = await server.handler(postReq);
      expect(postRes.statusCode, equals(200));
      final postData = json.decode(await postRes.readAsString()) as Map<String, dynamic>;
      final postSettings = postData['settings'] as Map<String, dynamic>;
      expect(postSettings.containsKey('pinCode'), isFalse);

      await server.stop();
      provider.dispose();
    });

    test('DisplayProvider cold-boot wall-clock recovery correctly recovers into prayer states', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();

      final schedule = provider.todaySchedule;
      expect(schedule, isNotNull);

      // 1. Recover during Dhuhr Friday Khutbah
      // Friday: simulate Friday occasion
      await provider.simulateOccasion(OccasionType.friday);
      final dhuhr = schedule!.dhuhr;
      // 5 minutes after Dhuhr Adhan (within 40 min jumuahDelay)
      provider.recoverWallClockState(dhuhr.add(const Duration(minutes: 5)));
      expect(provider.displayState, equals(DisplayState.jumuahKhutbah));
      expect(provider.activePrayer, equals(Prayer.dhuhr));
      expect(provider.jumuahRemaining.inMinutes, greaterThan(0));

      // 2. Recover during active Salat Blackout (45 minutes after Dhuhr)
      provider.recoverWallClockState(dhuhr.add(const Duration(minutes: 45)));
      expect(provider.displayState, equals(DisplayState.salatBlackout));
      expect(provider.activePrayer, equals(Prayer.dhuhr));

      // 3. Recover during active Post-Salat Adhkar (62 minutes after Dhuhr: 40m delay + 20m blackout)
      provider.recoverWallClockState(dhuhr.add(const Duration(minutes: 62)));
      expect(provider.displayState, equals(DisplayState.postSalatAdhkar));
      expect(provider.activePrayer, equals(Prayer.dhuhr));

      // 4. Recover during standard mode hours before prayer
      provider.dismissActiveState();
      provider.recoverWallClockState(DateTime(dhuhr.year, dhuhr.month, dhuhr.day, 9, 0));
      expect(provider.displayState, equals(DisplayState.standard));

      // 5. Test refreshRemoteAdminIp method without errors
      await provider.refreshRemoteAdminIp();

      provider.dispose();
    });
  });
}
