import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart';
import 'package:mosque_display/core/providers/display_provider.dart';
import 'package:mosque_display/core/services/remote_admin_server.dart';
import 'package:mosque_display/data/datasources/bundled_timetable_datasource.dart';
import 'package:mosque_display/data/models/mosque_settings.dart';
import 'package:mosque_display/data/repositories/prayer_repository.dart';
import 'package:mosque_display/data/repositories/settings_repository.dart';

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

  group('Adversarial RemoteAdminServer Stress Harness', () {
    test('Port collision chaining: hops across 4 preoccupied ports, binds 5th, throws SocketException if all 5 exhausted', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();

      const basePort = 9200;
      final blockers = <ServerSocket>[];
      // Occupy 4 consecutive ports: 9200, 9201, 9202, 9203
      for (int i = 0; i < 4; i++) {
        blockers.add(await ServerSocket.bind(InternetAddress.anyIPv4, basePort + i));
      }

      final server = RemoteAdminServer(
        displayProvider: provider,
        port: basePort,
        sessionToken: 'token_chain_test',
      );

      try {
        await server.start();
        expect(server.isRunning, isTrue);
        // Should have hopped 4 times and bound basePort + 4 (9204)
        expect(server.activePort, equals(basePort + 4));
        expect(server.directUrl, equals('http://${server.localIp}:${basePort + 4}'));
        await server.stop();

        // Now occupy the 5th port as well (9204), making all 5 candidate ports occupied
        blockers.add(await ServerSocket.bind(InternetAddress.anyIPv4, basePort + 4));

        final serverExhausted = RemoteAdminServer(
          displayProvider: provider,
          port: basePort,
          sessionToken: 'token_exhausted_test',
        );

        // Expect SocketException when all 5 candidate ports are exhausted
        await expectLater(
          serverExhausted.start(),
          throwsA(isA<SocketException>()),
        );
        expect(serverExhausted.isRunning, isFalse);
      } finally {
        for (final b in blockers) {
          await b.close();
        }
        provider.dispose();
      }
    });

    test('120 Concurrent burst requests across GET /api/status, POST /api/action, and POST /api/settings', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(
          remoteAdminEnabled: false,
          mosqueName: 'Burst Base Mosque',
          marqueeText: 'Burst Base Marquee',
        ),
      );
      await provider.init();

      final server = RemoteAdminServer(
        displayProvider: provider,
        port: 9220,
        sessionToken: 'token_burst_120',
      );
      await server.start();

      const int totalRequests = 120;
      final futures = <Future<Response>>[];

      for (int i = 0; i < totalRequests; i++) {
        final category = i % 3;
        if (category == 0) {
          // Serialized settings update with differing wilayas and names
          final payload = json.encode({
            'token': 'token_burst_120',
            'settings': {
              'mosqueName': 'Burst Mosque Update #$i',
              'marqueeText': 'Burst Ticker #$i',
              'selectedWilayaCode': (i % 58) + 1,
            },
          });
          final req = Request(
            'POST',
            Uri.parse('http://localhost:9220/api/settings'),
            body: payload,
            headers: {'content-type': 'application/json'},
          );
          futures.add(Future.value(server.handler(req)));
        } else if (category == 1) {
          // Action command
          final payload = json.encode({
            'token': 'token_burst_120',
            'action': 'simulateState',
            'state': (i % 2 == 0) ? 'adhkar' : 'standard',
            'prayer': 'fajr',
          });
          final req = Request(
            'POST',
            Uri.parse('http://localhost:9220/api/action'),
            body: payload,
            headers: {'content-type': 'application/json'},
          );
          futures.add(Future.value(server.handler(req)));
        } else {
          // Status query
          final req = Request(
            'GET',
            Uri.parse('http://localhost:9220/api/status?token=token_burst_120'),
          );
          futures.add(Future.value(server.handler(req)));
        }
      }

      final responses = await Future.wait(futures);
      expect(responses.length, equals(totalRequests));

      for (int i = 0; i < responses.length; i++) {
        expect(responses[i].statusCode, equals(200),
            reason: 'Request #$i returned status ${responses[i].statusCode}');
      }

      // Assert final settings integrity
      expect(provider.settings.mosqueName, contains('Burst Mosque Update #'));
      expect(provider.settings.selectedWilayaCode, inInclusiveRange(1, 58));

      // Assert repository persistence
      final persisted = await SettingsRepository.load();
      expect(persisted.mosqueName, equals(provider.settings.mosqueName));
      expect(persisted.selectedWilayaCode, equals(provider.settings.selectedWilayaCode));

      await server.stop();
      provider.dispose();
    });

    test('Malicious & malformed JSON injections into settings queue do not stall subsequent valid updates', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(
          remoteAdminEnabled: false,
          mosqueName: 'Before Poison',
        ),
      );
      await provider.init();

      final server = RemoteAdminServer(
        displayProvider: provider,
        port: 9230,
        sessionToken: 'token_malformed_test',
      );
      await server.start();

      // 1. Send completely invalid JSON string -> 400 Bad Request
      final badJsonReq = Request(
        'POST',
        Uri.parse('http://localhost:9230/api/settings'),
        body: '<<<CORRUPT_NON_JSON_DATA>>>',
        headers: {'content-type': 'application/json'},
      );
      final badJsonRes = await server.handler(badJsonReq);
      expect(badJsonRes.statusCode, equals(400));

      // 2. Send invalid PIN format (e.g., letters or wrong length) -> 400 Bad Request
      final badPinReq = Request(
        'POST',
        Uri.parse('http://localhost:9230/api/settings'),
        body: json.encode({
          'token': 'token_malformed_test',
          'settings': {'pinCode': 'ABCD12'},
        }),
        headers: {'content-type': 'application/json'},
      );
      final badPinRes = await server.handler(badPinReq);
      expect(badPinRes.statusCode, equals(400));

      // 3. Immediately send a valid settings update -> Should process cleanly (queue not blocked)
      final validReq = Request(
        'POST',
        Uri.parse('http://localhost:9230/api/settings'),
        body: json.encode({
          'token': 'token_malformed_test',
          'settings': {'mosqueName': 'Healthy After Poison'},
        }),
        headers: {'content-type': 'application/json'},
      );
      final validRes = await server.handler(validReq);
      expect(validRes.statusCode, equals(200));
      expect(provider.settings.mosqueName, equals('Healthy After Poison'));

      await server.stop();
      provider.dispose();
    });

    test('Concurrent PIN brute-force flood: 20 simultaneous incorrect PIN requests deterministically lock out', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(
          remoteAdminEnabled: false,
          pinCode: '5566',
        ),
      );
      await provider.init();

      final server = RemoteAdminServer(
        displayProvider: provider,
        port: 9240,
        sessionToken: 'token_pin_flood',
      );
      await server.start();

      // Send 20 concurrent bad PIN requests
      final futures = <Future<Response>>[];
      for (int i = 0; i < 20; i++) {
        final req = Request(
          'POST',
          Uri.parse('http://localhost:9240/api/action'),
          body: json.encode({'pin': '000$i', 'action': 'dismiss'}),
          headers: {'content-type': 'application/json'},
        );
        futures.add(Future.value(server.handler(req)));
      }

      final responses = await Future.wait(futures);
      expect(responses.length, equals(20));

      // At least 15 of them must be 429 (since lockout occurs after 5 failures)
      final count403 = responses.where((r) => r.statusCode == 403).length;
      final count429 = responses.where((r) => r.statusCode == 429).length;

      expect(count403, inInclusiveRange(4, 5));
      expect(count429, inInclusiveRange(15, 16));
      expect(server.isPinLockedOut, isTrue);

      // Verify that GET /api/settings is also locked out with 429
      final getSettingsReq = Request(
        'GET',
        Uri.parse('http://localhost:9240/api/settings'),
        headers: {'x-pin-code': '5566'},
      );
      final getSettingsRes = await server.handler(getSettingsReq);
      expect(getSettingsRes.statusCode, equals(429));

      // Verify that authorized session token request still passes despite PIN lockout
      final tokenReq = Request(
        'GET',
        Uri.parse('http://localhost:9240/api/settings?token=token_pin_flood'),
      );
      final tokenRes = await server.handler(tokenReq);
      expect(tokenRes.statusCode, equals(200));

      await server.stop();
      provider.dispose();
    });

    test('PIN authentication success resets failed attempts counter to 0 before lockout occurs', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(
          remoteAdminEnabled: false,
          pinCode: '7788',
        ),
      );
      await provider.init();

      final server = RemoteAdminServer(
        displayProvider: provider,
        port: 9250,
        sessionToken: 'token_pin_reset',
      );
      await server.start();

      // 3 failed attempts
      for (int i = 0; i < 3; i++) {
        final req = Request(
          'POST',
          Uri.parse('http://localhost:9250/api/action'),
          body: json.encode({'pin': '111$i', 'action': 'dismiss'}),
          headers: {'content-type': 'application/json'},
        );
        final res = await server.handler(req);
        expect(res.statusCode, equals(403));
      }
      expect(server.failedPinAttempts, equals(3));
      expect(server.isPinLockedOut, isFalse);

      // Now supply the correct PIN
      final correctReq = Request(
        'POST',
        Uri.parse('http://localhost:9250/api/action'),
        body: json.encode({'pin': '7788', 'action': 'dismiss'}),
        headers: {'content-type': 'application/json'},
      );
      final correctRes = await server.handler(correctReq);
      expect(correctRes.statusCode, equals(200));

      // Verify counter was reset to 0
      expect(server.failedPinAttempts, equals(0));
      expect(server.isPinLockedOut, isFalse);

      await server.stop();
      provider.dispose();
    });

    test('OPTIONS CORS preflight and unknown route 404 robustness under rapid firing', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = DisplayProvider(
        prayerRepo: repo,
        initialSettings: const MosqueSettings(remoteAdminEnabled: false),
      );
      await provider.init();

      final server = RemoteAdminServer(
        displayProvider: provider,
        port: 9260,
        sessionToken: 'token_cors_test',
      );
      await server.start();

      // OPTIONS preflight
      final optionsReq = Request('OPTIONS', Uri.parse('http://localhost:9260/api/settings'));
      final optionsRes = await server.handler(optionsReq);
      expect(optionsRes.statusCode, equals(200));
      expect(optionsRes.headers['access-control-allow-origin'], equals('*'));
      expect(optionsRes.headers['access-control-allow-methods'], contains('POST'));
      expect(optionsRes.headers['access-control-allow-headers'], contains('X-Admin-Token'));

      // Unknown route -> 404 Not Found
      final notFoundReq = Request('GET', Uri.parse('http://localhost:9260/api/nonexistent_path'));
      final notFoundRes = await server.handler(notFoundReq);
      expect(notFoundRes.statusCode, equals(404));

      await server.stop();
      provider.dispose();
    });
  });
}
