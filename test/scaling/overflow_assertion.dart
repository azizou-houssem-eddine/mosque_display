import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class OverflowReport {
  final List<String> overflowErrors = [];
  FlutterExceptionHandler? _previousHandler;

  void attach() {
    _previousHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final msg = details.exceptionAsString();
      if (msg.contains('overflowed by') || msg.contains('RenderFlex')) {
        overflowErrors.add(msg);
      }
      _previousHandler?.call(details);
    };
  }

  void detach() {
    FlutterError.onError = _previousHandler;
  }

  void assertZeroOverflow([String? contextInfo]) {
    if (overflowErrors.isNotEmpty) {
      fail(
          'RenderFlex overflow detected${contextInfo != null ? " [$contextInfo]" : ""}:\n${overflowErrors.join("\n")}');
    }
  }
}

/// Helper asserting zero layout exceptions on the current tester state.
void expectZeroLayoutOverflow(WidgetTester tester, {String? reason}) {
  final exception = tester.takeException();
  expect(exception, isNull,
      reason: reason ?? 'Layout must have zero RenderFlex overflows');
}
