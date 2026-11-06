import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../providers/display_provider.dart';
import '../../data/models/prayer_schedule.dart';
import '../../data/models/iqamah_delays.dart';
import '../../data/models/prayer_offsets.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/occasions/islamic_occasions_engine.dart';

enum _AuthResult {
  authorized,
  forbidden,
  lockedOut,
}

/// Embedded local HTTP administration server running on Android TV.
/// Enables wireless pairing via QR code or direct LAN URL.
/// Allows mosque administrators/imams to configure settings and trigger actions
/// from any smartphone or laptop on the local Wi-Fi without needing a remote control.
class RemoteAdminServer {
  final DisplayProvider displayProvider;
  int port;

  HttpServer? _server;
  String _sessionToken;
  String _localIp = '127.0.0.1';
  bool _isRunning = false;
  int _failedPinAttempts = 0;
  DateTime? _pinLockoutUntil;
  Future<void> _settingsSaveQueue = Future.value();

  RemoteAdminServer({
    required this.displayProvider,
    this.port = 8080,
    String? sessionToken,
  }) : _sessionToken = sessionToken ?? _generateToken();

  bool get isRunning => _isRunning;
  String get sessionToken => _sessionToken;
  String get localIp => _localIp;
  int get activePort => _server?.port ?? port;
  int get failedPinAttempts => _failedPinAttempts;
  bool get isPinLockedOut =>
      _pinLockoutUntil != null && DateTime.now().isBefore(_pinLockoutUntil!);
  Duration? get pinLockoutRemaining =>
      isPinLockedOut ? _pinLockoutUntil!.difference(DateTime.now()) : null;

  /// Direct URL without credentials.
  String get directUrl => 'http://$_localIp:$activePort';

  /// Pre-authenticated pairing URL with session token for zero-friction QR scan.
  String get pairingUrl => 'http://$_localIp:$activePort/?token=$_sessionToken';

  static String _generateToken() {
    final rand = Random.secure();
    final values = List<int>.generate(12, (_) => rand.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Regenerates the session token for security.
  void regenerateToken() {
    _sessionToken = _generateToken();
  }

  /// Resolves the device's local LAN IPv4 address.
  Future<String> resolveLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      ).timeout(const Duration(seconds: 3), onTimeout: () => []);
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            // Prioritize standard local subnets (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
            final ip = addr.address;
            if (ip.startsWith('192.168.') ||
                ip.startsWith('10.') ||
                ip.startsWith('172.')) {
              _localIp = ip;
              return ip;
            }
          }
        }
      }
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        _localIp = interfaces.first.addresses.first.address;
        return _localIp;
      }
    } catch (e) {
      debugPrint('Failed to resolve local IP: $e');
    }
    _localIp = '127.0.0.1';
    return _localIp;
  }

  /// Refreshes and returns the device's local LAN IPv4 address.
  Future<String> refreshLocalIp() async {
    return await resolveLocalIp();
  }

  /// Creates the configured Shelf request handler.
  Handler get handler {
    final router = _buildRouter();
    return const Pipeline()
        .addMiddleware(_corsMiddleware())
        .addMiddleware(logRequests())
        .addHandler(router.call);
  }

  /// Starts the embedded HTTP server.
  /// Gracefully attempts fallback ports if the desired port is bound.
  Future<void> start() async {
    if (_isRunning) return;

    await resolveLocalIp();

    int candidatePort = port;
    const int maxAttempts = 5;

    for (int i = 0; i < maxAttempts; i++) {
      try {
        _server = await shelf_io.serve(
          handler,
          InternetAddress.anyIPv4,
          candidatePort,
        ).timeout(const Duration(seconds: 5));
        port = candidatePort;
        _isRunning = true;
        debugPrint('RemoteAdminServer running at $pairingUrl');
        return;
      } on Exception catch (e) {
        debugPrint('Port $candidatePort unavailable or timed out: $e');
        candidatePort++;
      }
    }
    throw SocketException('Failed to bind RemoteAdminServer after $maxAttempts attempts starting at port $port');
  }

  /// Stops the server.
  Future<void> stop() async {
    if (!_isRunning) return;
    await _server?.close(force: true);
    _server = null;
    _isRunning = false;
    debugPrint('RemoteAdminServer stopped');
  }

  Middleware _corsMiddleware() {
    return (innerHandler) {
      return (request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization, X-Admin-Token, X-Pin-Code',
          });
        }
        final response = await innerHandler(request);
        return response.change(headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization, X-Admin-Token, X-Pin-Code',
        });
      };
    };
  }

  void _recordFailedPin() {
    _failedPinAttempts++;
    if (_failedPinAttempts >= 5) {
      _pinLockoutUntil = DateTime.now().add(const Duration(seconds: 60));
      debugPrint('RemoteAdminServer: PIN locked out for 60 seconds after 5 failed attempts.');
    }
  }

  void _resetFailedPin() {
    _failedPinAttempts = 0;
    _pinLockoutUntil = null;
  }

  _AuthResult _checkAuthorization(Request request, [Map<String, dynamic>? body]) {
    // 1. Session token in query
    final queryToken = request.url.queryParameters['token'];
    if (queryToken != null && queryToken.isNotEmpty && queryToken == _sessionToken) {
      return _AuthResult.authorized;
    }

    // 2. Token in custom header
    final headerToken = request.headers['x-admin-token'];
    if (headerToken != null && headerToken.isNotEmpty && headerToken == _sessionToken) {
      return _AuthResult.authorized;
    }

    // 3. Token in JSON body
    if (body != null) {
      final bodyToken = body['token'] as String?;
      if (bodyToken != null && bodyToken.isNotEmpty && bodyToken == _sessionToken) {
        return _AuthResult.authorized;
      }
    }

    // If token didn't authorize, check if PIN lockout is active
    if (isPinLockedOut) {
      return _AuthResult.lockedOut;
    }

    // 4. PIN check
    final pinHeader = request.headers['x-pin-code'];
    final bodyPin = body != null ? body['pin'] as String? : null;
    final candidatePin = pinHeader ?? bodyPin;

    if (candidatePin != null && candidatePin.isNotEmpty) {
      if (displayProvider.settings.verifyPin(candidatePin)) {
        _resetFailedPin();
        return _AuthResult.authorized;
      } else {
        _recordFailedPin();
        if (isPinLockedOut) {
          return _AuthResult.lockedOut;
        }
        return _AuthResult.forbidden;
      }
    }

    return _AuthResult.forbidden;
  }

  Future<Response> _enqueueSettingsSave(Future<Response> Function() action) {
    final completer = Completer<Response>();
    _settingsSaveQueue = _settingsSaveQueue.then((_) async {
      try {
        final res = await action();
        completer.complete(res);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  Router _buildRouter() {
    final router = Router();

    // ── Web Dashboard (Self-contained offline HTML) ───────────────────────────
    router.get('/', (Request request) {
      final token = request.url.queryParameters['token'] ?? '';
      final html = _generateDashboardHtml(token);
      return Response.ok(
        html,
        headers: {'content-type': 'text/html; charset=utf-8'},
      );
    });

    // ── API: Status ──────────────────────────────────────────────────────────
    router.get('/api/status', (Request request) {
      final schedule = displayProvider.todaySchedule;
      final now = displayProvider.effectiveDate;
      final nextPrayer = schedule?.getNextPrayer(now);

      final data = {
        'online': true,
        'effectiveTime': displayProvider.formatTime(now),
        'hijriDate': displayProvider.hijriDate,
        'gregorianDate': displayProvider.gregorianDate,
        'displayState': displayProvider.displayState.name,
        'displayStateAr': _getDisplayStateAr(displayProvider.displayState),
        'activePrayer': displayProvider.activePrayer?.name,
        'activePrayerAr': displayProvider.activePrayer?.nameAr,
        'nextPrayer': nextPrayer?.name,
        'nextPrayerAr': (displayProvider.isFriday && nextPrayer == Prayer.dhuhr)
            ? 'صلاة الجمعة'
            : nextPrayer?.nameAr,
        'isFriday': displayProvider.isFriday,
        'isRamadan': displayProvider.isRamadan,
        'isSimulationActive': displayProvider.isSimulationActive,
        'mosqueName': displayProvider.settings.mosqueName,
        'wilayaCode': displayProvider.settings.selectedWilayaCode,
        'communeName': displayProvider.settings.selectedCommuneName,
        'countdownSeconds': displayProvider.countdownToNextAdhan.inSeconds,
      };

      return Response.ok(
        json.encode(data),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    // ── API: Settings ────────────────────────────────────────────────────────
    router.get('/api/settings', (Request request) {
      final auth = _checkAuthorization(request);
      if (auth == _AuthResult.lockedOut) {
        return Response(
          429,
          body: json.encode({
            'error': 'تم قفل محاولات رمز PIN مؤقتاً لمدة 60 ثانية لتكرار إدخال رمز خاطئ',
            'lockedOut': true,
          }),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (auth != _AuthResult.authorized) {
        return Response.forbidden(
          json.encode({'error': 'رمز الدخول أو رمز PIN مطلوب للوصول للإعدادات'}),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      final settings = displayProvider.settings;
      final settingsJson = settings.toJson();
      settingsJson.remove('pinCode'); // Prevent leaking master PIN
      final data = {
        'settings': settingsJson,
        'isCustomPinConfigured': settings.isCustomPinConfigured,
      };
      return Response.ok(
        json.encode(data),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    router.post('/api/settings', (Request request) async {
      final content = await request.readAsString();
      Map<String, dynamic> body;
      try {
        body = json.decode(content) as Map<String, dynamic>;
      } catch (_) {
        return Response.badRequest(
          body: json.encode({'error': 'تنسيق JSON غير صالح'}),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      final auth = _checkAuthorization(request, body);
      if (auth == _AuthResult.lockedOut) {
        return Response(
          429,
          body: json.encode({
            'error': 'تم قفل محاولات رمز PIN مؤقتاً لمدة 60 ثانية لتكرار إدخال رمز خاطئ',
            'lockedOut': true,
          }),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (auth != _AuthResult.authorized) {
        return Response.forbidden(
          json.encode({'error': 'رمز الدخول أو رمز PIN غير صحيح'}),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      return await _enqueueSettingsSave(() async {
        try {
          final settingsMap = (body['settings'] as Map<String, dynamic>?) ?? body;
          final current = displayProvider.settings;

          // Validate pinCode if provided
          String? validatedPin;
          if (settingsMap.containsKey('pinCode')) {
            final candidatePin = (settingsMap['pinCode'] as String?)?.trim();
            if (candidatePin != null && RegExp(r'^\d{4}$').hasMatch(candidatePin)) {
              validatedPin = candidatePin;
            } else if (candidatePin != null && candidatePin.isNotEmpty) {
              return Response.badRequest(
                body: json.encode({'error': 'رمز PIN يجب أن يتكون من 4 أرقام عددية'}),
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }
          }

          // Validate remoteAdminPort if provided
          int? validatedPort;
          if (settingsMap.containsKey('remoteAdminPort')) {
            final portNum = (settingsMap['remoteAdminPort'] as num?)?.toInt();
            if (portNum != null && portNum >= 1024 && portNum <= 65535) {
              validatedPort = portNum;
            }
          }

          // Build updated settings
          final updated = current.copyWith(
            mosqueName: settingsMap['mosqueName'] as String?,
            marqueeText: settingsMap['marqueeText'] as String?,
            selectedWilayaCode: (settingsMap['selectedWilayaCode'] as num?)?.toInt(),
            selectedCommuneCode: (settingsMap['selectedCommuneCode'] as num?)?.toInt(),
            selectedCommuneName: settingsMap['selectedCommuneName'] as String?,
            clearCommune: settingsMap['clearCommune'] == true,
            pinCode: validatedPin,
            remoteAdminPort: validatedPort,
            hijriOffsetDays: (settingsMap['hijriOffsetDays'] as num?)?.toInt(),
            blackoutDurationMinutes: (settingsMap['blackoutDurationMinutes'] as num?)?.toInt(),
            blackoutDimMode: settingsMap['blackoutDimMode'] as bool?,
            adhkarDurationMinutes: (settingsMap['adhkarDurationMinutes'] as num?)?.toInt(),
            showSeconds: settingsMap['showSeconds'] as bool?,
            showGregorianDate: settingsMap['showGregorianDate'] as bool?,
            showFastingTimes: settingsMap['showFastingTimes'] as bool?,
            watchFaceTemplate: settingsMap['watchFaceTemplate'] as String?,
            colorTheme: settingsMap['colorTheme'] as String?,
            islamicFont: settingsMap['islamicFont'] as String?,
            uiScaleFactor: (settingsMap['uiScaleFactor'] as num?)?.toDouble(),
            iqamahDelays: settingsMap['iqamahDelays'] != null
                ? IqamahDelays.fromJson(settingsMap['iqamahDelays'] as Map<String, dynamic>)
                : null,
            offsets: settingsMap['offsets'] != null
                ? PrayerOffsets.fromJson(settingsMap['offsets'] as Map<String, dynamic>)
                : null,
          );

          final wilayaChanged = current.selectedWilayaCode != updated.selectedWilayaCode;
          final communeChanged = current.selectedCommuneCode != updated.selectedCommuneCode;

          await displayProvider.updateSettings(
            updated,
            reloadSchedule: wilayaChanged || communeChanged,
          );
          try {
            await SettingsRepository.save(updated);
          } catch (e) {
            debugPrint('SettingsRepository.save error: $e');
          }

          final responseSettingsJson = updated.toJson();
          responseSettingsJson.remove('pinCode');

          return Response.ok(
            json.encode({
              'success': true,
              'message': 'تم حفظ الإعدادات وتحديث شاشة المسجد بنجاح',
              'settings': responseSettingsJson,
            }),
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } catch (e) {
          return Response.internalServerError(
            body: json.encode({'error': 'فشل حفظ الإعدادات: $e'}),
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
      });
    });

    // ── API: Remote Actions ──────────────────────────────────────────────────
    router.post('/api/action', (Request request) async {
      final content = await request.readAsString();
      Map<String, dynamic> body;
      try {
        body = json.decode(content) as Map<String, dynamic>;
      } catch (_) {
        return Response.badRequest(
          body: json.encode({'error': 'تنسيق JSON غير صالح'}),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      final auth = _checkAuthorization(request, body);
      if (auth == _AuthResult.lockedOut) {
        return Response(
          429,
          body: json.encode({
            'error': 'تم قفل محاولات رمز PIN مؤقتاً لمدة 60 ثانية لتكرار إدخال رمز خاطئ',
            'lockedOut': true,
          }),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (auth != _AuthResult.authorized) {
        return Response.forbidden(
          json.encode({'error': 'رمز الدخول أو رمز PIN غير صحيح'}),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      final action = body['action'] as String?;

      switch (action) {
        case 'dismiss':
          displayProvider.dismissActiveState();
          return Response.ok(
            json.encode({'success': true, 'message': 'تمت العودة للواجهة الرئيسية'}),
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        case 'adhkar':
          displayProvider.triggerAdhkarOnDemand();
          return Response.ok(
            json.encode({'success': true, 'message': 'تم تشغيل أذكار ما بعد الصلاة'}),
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        case 'jumuah':
          displayProvider.simulateDisplayState(
            DisplayState.jumuahKhutbah,
            prayer: Prayer.dhuhr,
          );
          return Response.ok(
            json.encode({'success': true, 'message': 'تم تفعيل وضع خطبة الجمعة والإنصات'}),
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        case 'blackout':
          displayProvider.enterBlackout();
          return Response.ok(
            json.encode({'success': true, 'message': 'تم بدء وضع صلاة الجماعة (السواد)'}),
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        case 'simulateState':
          final stateName = body['state'] as String?;
          final prayerName = body['prayer'] as String? ?? 'maghrib';
          final seconds = (body['seconds'] as num?)?.toInt();

          final state = DisplayState.values.firstWhere(
            (s) => s.name == stateName,
            orElse: () => DisplayState.standard,
          );
          final prayer = Prayer.values.firstWhere(
            (p) => p.name == prayerName,
            orElse: () => Prayer.maghrib,
          );

          displayProvider.simulateDisplayState(
            state,
            prayer: prayer,
            customDuration: seconds != null ? Duration(seconds: seconds) : null,
          );
          return Response.ok(
            json.encode({'success': true, 'message': 'تم تطبيق المحاكاة: $stateName'}),
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        case 'simulateOccasion':
          final occName = body['occasion'] as String?;
          final occasion = OccasionType.values.firstWhere(
            (o) => o.name == occName,
            orElse: () => OccasionType.friday,
          );
          await displayProvider.simulateOccasion(occasion);
          return Response.ok(
            json.encode({'success': true, 'message': 'تمت محاكاة المناسبة: $occName'}),
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        case 'resetSimulation':
          await displayProvider.resetSimulation();
          return Response.ok(
            json.encode({'success': true, 'message': 'تمت إعادة الضبط للوقت الحقيقي'}),
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        default:
          return Response.badRequest(
            body: json.encode({'error': 'إجراء غير معروف'}),
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
      }
    });

    return router;
  }

  static String _getDisplayStateAr(DisplayState state) {
    switch (state) {
      case DisplayState.standard:
        return 'الواجهة الرئيسية القياسية';
      case DisplayState.adhanAlert:
        return 'تنبيه الأذان ودخول الوقت';
      case DisplayState.iqamahCountdown:
        return 'العد التنازلي لإقامة الصلاة';
      case DisplayState.jumuahKhutbah:
        return 'خطبة الجمعة (وضع الإنصات والسكينة)';
      case DisplayState.salatBlackout:
        return 'صلاة الجماعة قائمة (سواد الشاشة)';
      case DisplayState.postSalatAdhkar:
        return 'أذكار ما بعد الصلاة المفروضة';
    }
  }

  /// Self-contained offline HTML web dashboard.
  /// Zero CDN links, zero external CSS/JS, 100% offline-ready.
  String _generateDashboardHtml(String token) {
    return '''<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>منارة المساجد — لوحة التحكم عن بعد</title>
<style>
:root {
  --bg-deep: #06231a;
  --bg-mid: #0b3326;
  --bg-card: #0f4535;
  --gold-primary: #f2c94c;
  --gold-accent: #d4af37;
  --gold-dim: #b8962e;
  --gold-light: #fff176;
  --text-main: #f5f0e8;
  --text-dim: #beb9a8;
  --success: #27ae60;
  --danger: #e74c3c;
  --radius: 12px;
}
* { box-sizing: border-box; margin: 0; padding: 0; }
body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Cairo", sans-serif;
  background: radial-gradient(circle at center, var(--bg-mid) 0%, var(--bg-deep) 100%);
  color: var(--text-main);
  min-height: 100vh;
  padding: 16px;
  line-height: 1.5;
}
.container { max-width: 900px; margin: 0 auto; }
header {
  text-align: center;
  padding: 16px;
  background: rgba(11, 51, 38, 0.85);
  border: 1px solid var(--gold-dim);
  border-radius: var(--radius);
  margin-bottom: 16px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.4);
}
h1 { color: var(--gold-primary); font-size: 1.5rem; margin-bottom: 4px; }
.subtitle { color: var(--text-dim); font-size: 0.9rem; }
.badge {
  display: inline-block;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 0.8rem;
  font-weight: bold;
  background: rgba(242, 201, 76, 0.15);
  color: var(--gold-primary);
  border: 1px solid var(--gold-accent);
  margin-top: 8px;
}
.live-status {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 10px;
  margin-bottom: 16px;
}
.status-box {
  background: var(--bg-card);
  padding: 12px;
  border-radius: var(--radius);
  border: 1px solid rgba(242, 201, 76, 0.25);
  text-align: center;
}
.status-box .title { font-size: 0.75rem; color: var(--text-dim); }
.status-box .val { font-size: 1.1rem; color: var(--gold-light); font-weight: bold; margin-top: 2px; }
.card {
  background: rgba(15, 69, 53, 0.9);
  border: 1px solid rgba(242, 201, 76, 0.3);
  border-radius: var(--radius);
  padding: 18px;
  margin-bottom: 16px;
  box-shadow: 0 4px 14px rgba(0,0,0,0.3);
}
.card h2 {
  font-size: 1.15rem;
  color: var(--gold-primary);
  border-bottom: 1px solid rgba(242, 201, 76, 0.25);
  padding-bottom: 8px;
  margin-bottom: 14px;
  display: flex;
  align-items: center;
  gap: 8px;
}
.btn-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(130px, 1fr));
  gap: 10px;
}
button {
  cursor: pointer;
  border: none;
  border-radius: 8px;
  padding: 12px 14px;
  font-size: 0.9rem;
  font-weight: bold;
  font-family: inherit;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
}
.btn-gold {
  background: linear-gradient(135deg, var(--gold-primary), var(--gold-accent));
  color: #06231a;
}
.btn-gold:hover { filter: brightness(1.1); transform: translateY(-1px); }
.btn-action {
  background: var(--bg-mid);
  color: var(--text-main);
  border: 1px solid var(--gold-dim);
}
.btn-action:hover {
  background: var(--gold-dim);
  color: #06231a;
}
.btn-danger {
  background: rgba(231, 76, 60, 0.25);
  color: #ff7675;
  border: 1px solid var(--danger);
}
.btn-danger:hover { background: var(--danger); color: white; }
.form-group {
  margin-bottom: 14px;
}
label {
  display: block;
  font-size: 0.85rem;
  color: var(--text-dim);
  margin-bottom: 4px;
  font-weight: 600;
}
input[type="text"], input[type="number"], select, textarea {
  width: 100%;
  padding: 10px 12px;
  background: #06231a;
  border: 1px solid rgba(242, 201, 76, 0.4);
  border-radius: 8px;
  color: var(--text-main);
  font-size: 0.95rem;
  font-family: inherit;
  direction: rtl;
}
input:focus, select:focus, textarea:focus {
  outline: none;
  border-color: var(--gold-primary);
  box-shadow: 0 0 8px rgba(242, 201, 76, 0.3);
}
.row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(130px, 1fr));
  gap: 10px;
}
.toggle-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px;
  background: #06231a;
  border-radius: 8px;
  border: 1px solid rgba(242, 201, 76, 0.25);
  margin-bottom: 10px;
}
.toggle-row input[type="checkbox"] {
  width: 20px;
  height: 20px;
  accent-color: var(--gold-primary);
  cursor: pointer;
}
.toast {
  position: fixed;
  bottom: 20px;
  left: 50%;
  transform: translateX(-50%);
  background: #27ae60;
  color: white;
  padding: 12px 24px;
  border-radius: 30px;
  font-weight: bold;
  box-shadow: 0 4px 20px rgba(0,0,0,0.5);
  display: none;
  z-index: 1000;
}
.toast.error { background: #e74c3c; }
footer {
  text-align: center;
  font-size: 0.8rem;
  color: var(--text-dim);
  padding: 20px 0;
}
</style>
</head>
<body>
<div class="container">
  <header>
    <h1 id="headerMosqueName">🕌 منارة المساجد — لوحة الإدارة</h1>
    <div class="subtitle">التحكم اللاسلكي الفوري عبر شبكة المسجد المحلية</div>
    <div class="badge" id="tvConnectionBadge">● متصل بشاشة التلفاز</div>
  </header>

  <!-- Live Status Dashboard -->
  <div class="live-status">
    <div class="status-box">
      <div class="title">الوقت الآن</div>
      <div class="val" id="stTime">--:--:--</div>
    </div>
    <div class="status-box">
      <div class="title">حالة الشاشة</div>
      <div class="val" id="stState" style="font-size:0.95rem;">الرئيسية</div>
    </div>
    <div class="status-box">
      <div class="title">الصلاة القادمة</div>
      <div class="val" id="stNextPrayer">--</div>
    </div>
    <div class="status-box">
      <div class="title">العد التنازلي</div>
      <div class="val" id="stCountdown">--:--</div>
    </div>
  </div>

  <!-- Quick Actions -->
  <div class="card">
    <h2>⚡ أوامر فورية سريعة</h2>
    <div class="btn-grid">
      <button class="btn-action" onclick="sendAction('jumuah')">🕌 خطبة الجمعة</button>
      <button class="btn-action" onclick="sendAction('blackout')">🕋 صلاة الجماعة</button>
      <button class="btn-action" onclick="sendAction('adhkar')">📿 تشغيل الأذكار</button>
      <button class="btn-action" onclick="sendAction('dismiss')">↩ الشاشة الرئيسية</button>
      <button class="btn-action" onclick="sendAction('simulateOccasion', {occasion: 'ramadan'})">🌙 شهر رمضان</button>
      <button class="btn-danger" onclick="sendAction('resetSimulation')">🔄 إنهاء المحاكاة</button>
    </div>
  </div>

  <!-- Mosque Settings Form -->
  <form id="settingsForm" onsubmit="saveSettings(event)">
    <div class="card">
      <h2>🏛️ معلومات المسجد والإعلانات</h2>
      <div class="form-group">
        <label>اسم المسجد:</label>
        <input type="text" id="mosqueName" required>
      </div>
      <div class="form-group">
        <label>نص الشريط الإعلاني المتحرك:</label>
        <textarea id="marqueeText" rows="3"></textarea>
      </div>
    </div>

    <div class="card">
      <h2>📍 الولاية والبلدية</h2>
      <div class="row">
        <div class="form-group">
          <label>الولاية الجزائرية (1 - 58):</label>
          <select id="selectedWilayaCode">
            <!-- 58 Wilayas will be injected -->
          </select>
        </div>
        <div class="form-group">
          <label>اسم البلدية (اختياري لمعايرة دقيقة):</label>
          <input type="text" id="selectedCommuneName" placeholder="اتركه فارغاً لاعتماد مركز الولاية">
        </div>
      </div>
    </div>

    <div class="card">
      <h2>⏳ أوقات تأخير الإقامة والجمعة (بالدقائق)</h2>
      <div class="row">
        <div class="form-group">
          <label>الفجر (5-60):</label>
          <input type="number" id="iqFajr" min="5" max="60">
        </div>
        <div class="form-group">
          <label>الظهر (5-45):</label>
          <input type="number" id="iqDhuhr" min="5" max="45">
        </div>
        <div class="form-group">
          <label>العصر (5-45):</label>
          <input type="number" id="iqAsr" min="5" max="45">
        </div>
        <div class="form-group">
          <label>المغرب (3-30):</label>
          <input type="number" id="iqMaghrib" min="3" max="30">
        </div>
        <div class="form-group">
          <label>العشاء (5-45):</label>
          <input type="number" id="iqIsha" min="5" max="45">
        </div>
        <div class="form-group">
          <label>خطبة الجمعة (15-90):</label>
          <input type="number" id="iqJumuah" min="15" max="90">
        </div>
      </div>
    </div>

    <div class="card">
      <h2>⏱️ معايرة أوقات الصلاة بالدقائق (Offsets)</h2>
      <div class="row">
        <div class="form-group">
          <label>الفجر:</label>
          <input type="number" id="offFajr" min="-15" max="15">
        </div>
        <div class="form-group">
          <label>الشروق:</label>
          <input type="number" id="offSunrise" min="-15" max="15">
        </div>
        <div class="form-group">
          <label>الظهر:</label>
          <input type="number" id="offDhuhr" min="-15" max="15">
        </div>
        <div class="form-group">
          <label>العصر:</label>
          <input type="number" id="offAsr" min="-15" max="15">
        </div>
        <div class="form-group">
          <label>المغرب:</label>
          <input type="number" id="offMaghrib" min="-15" max="15">
        </div>
        <div class="form-group">
          <label>العشاء:</label>
          <input type="number" id="offIsha" min="-15" max="15">
        </div>
      </div>
    </div>

    <div class="card">
      <h2>🕌 صلاة الجماعة والأذكار والتقويم</h2>
      <div class="row">
        <div class="form-group">
          <label>مدة صلاة الجماعة (دقائق):</label>
          <input type="number" id="blackoutDurationMinutes" min="5" max="45">
        </div>
        <div class="form-group">
          <label>مدة أذكار ما بعد الصلاة (دقائق):</label>
          <input type="number" id="adhkarDurationMinutes" min="2" max="15">
        </div>
        <div class="form-group">
          <label>تعديل التاريخ الهجري (-2 إلى +2):</label>
          <input type="number" id="hijriOffsetDays" min="-2" max="2">
        </div>
      </div>
      <div class="toggle-row">
        <span>وضع الشاشة الخافتة أثناء الصلاة (بدلاً من الإسود التام):</span>
        <input type="checkbox" id="blackoutDimMode">
      </div>
    </div>

    <div class="card">
      <h2>🎨 المظهر والعرض البصري</h2>
      <div class="row">
        <div class="form-group">
          <label>القالب البصري للشاشة:</label>
          <select id="watchFaceTemplate">
            <option value="classicAstrolabe">الأسطرلاب الكلاسيكي (افتراضي متوازن)</option>
            <option value="modernHorizontal">الأفقي العصري (شريط سفلي عريض)</option>
            <option value="grandClock">الساعة الكبرى الفخمة</option>
            <option value="traditionalMinbar">المنبر التراثي الأندلسي</option>
          </select>
        </div>
        <div class="form-group">
          <label>النسق اللوني:</label>
          <select id="colorTheme">
            <option value="royalEmerald">الزمرد الملكي (الأخضر والذهب)</option>
            <option value="andalusianOnyx">العقيق الأندلسي (الفحم والعنبر)</option>
            <option value="kiswahBlack">الكسوة الشريفة (OLED والذهب)</option>
          </select>
        </div>
      </div>
      <div class="row">
        <div class="form-group">
          <label>الخط القرآني للأدعية:</label>
          <select id="islamicFont">
            <option value="amiriQuran">الخط القرآني (Amiri Quran)</option>
            <option value="scheherazadeNew">خط شهرزاد المطور</option>
            <option value="amiri">خط النسخ التراثي (Amiri)</option>
            <option value="arefRuqaa">خط الرقعة الأصيل</option>
            <option value="cairo">الخط الحديث (Cairo)</option>
          </select>
        </div>
        <div class="form-group">
          <label>مقياس الواجهة:</label>
          <select id="uiScaleFactor">
            <option value="0.80">80% - شاشات 720p HD</option>
            <option value="0.90">90% - مدمج متناسق</option>
            <option value="1.00">100% - قياسي افتراضي</option>
            <option value="1.10">110% - شاشات 4K ومساجد واسعة</option>
          </select>
        </div>
      </div>
      <div class="toggle-row">
        <span>إظهار الثواني في الساعة:</span>
        <input type="checkbox" id="showSeconds">
      </div>
      <div class="toggle-row">
        <span>إظهار التاريخ الميلادي:</span>
        <input type="checkbox" id="showGregorianDate">
      </div>
      <div class="toggle-row">
        <span>إظهار أوقات الإمساك والإفطار في مواسم الصيام:</span>
        <input type="checkbox" id="showFastingTimes">
      </div>
    </div>

    <div class="card">
      <h2>🔒 رمز PIN الأمان</h2>
      <div class="form-group">
        <label>رمز PIN للتحكم (4 أرقام):</label>
        <input type="text" id="pinCode" maxlength="4" pattern="[0-9]{4}">
      </div>
    </div>

    <button type="submit" class="btn-gold" style="width: 100%; padding: 16px; font-size: 1.1rem; margin-bottom: 24px;">
      💾 حفظ وتطبيق الإعدادات على الشاشة فوراً
    </button>
  </form>

  <footer>
    منارة المساجد — نظام التلفاز وإدارة مواقيت الصلاة الجزائري • متصل محلياً
  </footer>
</div>

<div id="toast" class="toast">✓ تم تطبيق التعديل بنجاح</div>

<script>
const TOKEN = "$token" || new URLSearchParams(window.location.search).get('token') || '';

const WILAYAS = [
  [1, "أدرار"], [2, "الشلف"], [3, "الأغواط"], [4, "أم البواقي"], [5, "باتنة"],
  [6, "بجاية"], [7, "بسكرة"], [8, "بشار"], [9, "البليدة"], [10, "البويرة"],
  [11, "تمنراست"], [12, "تبسة"], [13, "تلمسان"], [14, "تيارت"], [15, "تيزي وزو"],
  [16, "الجزائر العاصمة"], [17, "الجلفة"], [18, "جيجل"], [19, "سطيف"], [20, "سعيدة"],
  [21, "سكيكدة"], [22, "سيدي بلعباس"], [23, "عنابة"], [24, "قالمة"], [25, "قسنطينة"],
  [26, "المدية"], [27, "مستغانم"], [28, "المسيلة"], [29, "معسكر"], [30, "ورقلة"],
  [31, "وهران"], [32, "البيض"], [33, "إليزي"], [34, "برج بوعريريج"], [35, "بومرداس"],
  [36, "الطارف"], [37, "تندوف"], [38, "تيسمسيلت"], [39, "الوادي"], [40, "خنشلة"],
  [41, "سوق أهراس"], [42, "تيبازة"], [43, "ميلة"], [44, "عين الدفلى"], [45, "النعامة"],
  [46, "عين تموشنت"], [47, "غرداية"], [48, "غليزان"], [49, "تيميمون"], [50, "برج باجي مختار"],
  [51, "أولاد جلال"], [52, "بني عباس"], [53, "عين صالح"], [54, "عين قزام"], [55, "تقرت"],
  [56, "جانت"], [57, "المغير"], [58, "المنيعة"]
];

function initWilayas() {
  const sel = document.getElementById('selectedWilayaCode');
  sel.innerHTML = WILAYAS.map(([code, name]) =>
    `<option value="\${code}">\${code} - \${name}</option>`
  ).join('');
}

function showToast(msg, isError = false) {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.className = isError ? 'toast error' : 'toast';
  t.style.display = 'block';
  setTimeout(() => { t.style.display = 'none'; }, 3000);
}

function formatCountdown(sec) {
  if (sec <= 0) return '00:00';
  const h = Math.floor(sec / 3600);
  const m = Math.floor((sec % 3600) / 60);
  const s = sec % 60;
  if (h > 0) return `\${h}:\${m.toString().padStart(2, '0')}:\${s.toString().padStart(2, '0')}`;
  return `\${m.toString().padStart(2, '0')}:\${s.toString().padStart(2, '0')}`;
}

async function fetchStatus() {
  try {
    const res = await fetch('/api/status?token=' + encodeURIComponent(TOKEN));
    if (!res.ok) return;
    const data = await res.json();
    document.getElementById('stTime').textContent = data.effectiveTime || '--:--:--';
    document.getElementById('stState').textContent = data.displayStateAr || 'الرئيسية';
    document.getElementById('stNextPrayer').textContent = data.nextPrayerAr || '--';
    document.getElementById('stCountdown').textContent = formatCountdown(data.countdownSeconds || 0);
    if (data.mosqueName) {
      document.getElementById('headerMosqueName').textContent = '🕌 ' + data.mosqueName;
    }
  } catch (e) {
    console.error('Status fetch error', e);
  }
}

async function fetchSettings() {
  try {
    const res = await fetch('/api/settings?token=' + encodeURIComponent(TOKEN));
    if (!res.ok) return;
    const { settings } = await res.json();
    if (!settings) return;

    document.getElementById('mosqueName').value = settings.mosqueName || '';
    document.getElementById('marqueeText').value = settings.marqueeText || '';
    document.getElementById('selectedWilayaCode').value = settings.selectedWilayaCode || 16;
    document.getElementById('selectedCommuneName').value = settings.selectedCommuneName || '';
    document.getElementById('pinCode').value = settings.pinCode || '0000';

    if (settings.iqamahDelays) {
      document.getElementById('iqFajr').value = settings.iqamahDelays.fajr || 20;
      document.getElementById('iqDhuhr').value = settings.iqamahDelays.dhuhr || 15;
      document.getElementById('iqAsr').value = settings.iqamahDelays.asr || 15;
      document.getElementById('iqMaghrib').value = settings.iqamahDelays.maghrib || 5;
      document.getElementById('iqIsha').value = settings.iqamahDelays.isha || 15;
      document.getElementById('iqJumuah').value = settings.iqamahDelays.jumuah || 40;
    }

    if (settings.offsets) {
      document.getElementById('offFajr').value = settings.offsets.fajr || 0;
      document.getElementById('offSunrise').value = settings.offsets.sunrise || 0;
      document.getElementById('offDhuhr').value = settings.offsets.dhuhr || 0;
      document.getElementById('offAsr').value = settings.offsets.asr || 0;
      document.getElementById('offMaghrib').value = settings.offsets.maghrib || 0;
      document.getElementById('offIsha').value = settings.offsets.isha || 0;
    }

    document.getElementById('blackoutDurationMinutes').value = settings.blackoutDurationMinutes || 20;
    document.getElementById('blackoutDimMode').checked = !!settings.blackoutDimMode;
    document.getElementById('adhkarDurationMinutes').value = settings.adhkarDurationMinutes || 7;
    document.getElementById('hijriOffsetDays').value = settings.hijriOffsetDays || 0;

    document.getElementById('watchFaceTemplate').value = settings.watchFaceTemplate || 'classicAstrolabe';
    document.getElementById('colorTheme').value = settings.colorTheme || 'royalEmerald';
    document.getElementById('islamicFont').value = settings.islamicFont || 'amiriQuran';
    document.getElementById('uiScaleFactor').value = (settings.uiScaleFactor || 1.0).toFixed(2);
    document.getElementById('showSeconds').checked = settings.showSeconds !== false;
    document.getElementById('showGregorianDate').checked = settings.showGregorianDate !== false;
    document.getElementById('showFastingTimes').checked = settings.showFastingTimes !== false;
  } catch (e) {
    console.error('Settings fetch error', e);
  }
}

async function sendAction(action, extra = {}) {
  try {
    const res = await fetch('/api/action', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Admin-Token': TOKEN
      },
      body: JSON.stringify({ action, token: TOKEN, ...extra })
    });
    const data = await res.json();
    if (res.ok) {
      showToast(data.message || 'تم تنفيذ الأمر');
      fetchStatus();
    } else {
      showToast(data.error || 'فشل تنفيذ الأمر', true);
    }
  } catch (e) {
    showToast('تعذر الاتصال بالشاشة', true);
  }
}

async function saveSettings(e) {
  e.preventDefault();

  const settingsPayload = {
    mosqueName: document.getElementById('mosqueName').value.trim(),
    marqueeText: document.getElementById('marqueeText').value.trim(),
    selectedWilayaCode: parseInt(document.getElementById('selectedWilayaCode').value, 10),
    selectedCommuneName: document.getElementById('selectedCommuneName').value.trim() || null,
    pinCode: document.getElementById('pinCode').value.trim(),
    blackoutDurationMinutes: parseInt(document.getElementById('blackoutDurationMinutes').value, 10),
    blackoutDimMode: document.getElementById('blackoutDimMode').checked,
    adhkarDurationMinutes: parseInt(document.getElementById('adhkarDurationMinutes').value, 10),
    hijriOffsetDays: parseInt(document.getElementById('hijriOffsetDays').value, 10),
    watchFaceTemplate: document.getElementById('watchFaceTemplate').value,
    colorTheme: document.getElementById('colorTheme').value,
    islamicFont: document.getElementById('islamicFont').value,
    uiScaleFactor: parseFloat(document.getElementById('uiScaleFactor').value),
    showSeconds: document.getElementById('showSeconds').checked,
    showGregorianDate: document.getElementById('showGregorianDate').checked,
    showFastingTimes: document.getElementById('showFastingTimes').checked,
    iqamahDelays: {
      fajr: parseInt(document.getElementById('iqFajr').value, 10),
      dhuhr: parseInt(document.getElementById('iqDhuhr').value, 10),
      asr: parseInt(document.getElementById('iqAsr').value, 10),
      maghrib: parseInt(document.getElementById('iqMaghrib').value, 10),
      isha: parseInt(document.getElementById('iqIsha').value, 10),
      jumuah: parseInt(document.getElementById('iqJumuah').value, 10),
    },
    offsets: {
      fajr: parseInt(document.getElementById('offFajr').value, 10),
      sunrise: parseInt(document.getElementById('offSunrise').value, 10),
      dhuhr: parseInt(document.getElementById('offDhuhr').value, 10),
      asr: parseInt(document.getElementById('offAsr').value, 10),
      maghrib: parseInt(document.getElementById('offMaghrib').value, 10),
      isha: parseInt(document.getElementById('offIsha').value, 10),
    }
  };

  try {
    const res = await fetch('/api/settings', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Admin-Token': TOKEN
      },
      body: JSON.stringify({
        token: TOKEN,
        pin: document.getElementById('pinCode').value.trim(),
        settings: settingsPayload
      })
    });
    const data = await res.json();
    if (res.ok) {
      showToast('✓ تم حفظ الإعدادات وتحديث شاشة المسجد بنجاح');
      fetchStatus();
    } else {
      showToast(data.error || 'فشل حفظ الإعدادات', true);
    }
  } catch (e) {
    showToast('تعذر الاتصال بالشاشة للحفظ', true);
  }
}

// Initial setup
initWilayas();
fetchSettings();
fetchStatus();
setInterval(fetchStatus, 3000);
</script>
</body>
</html>''';
  }
}
