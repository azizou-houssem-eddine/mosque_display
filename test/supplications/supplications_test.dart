import 'package:flutter_test/flutter_test.dart';
import 'package:mosque_display/data/models/islamic_supplication.dart';
import 'package:mosque_display/data/repositories/supplications_repository.dart';
import 'package:mosque_display/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Islamic Supplications & Font System Tests', () {
    test('Default fallback supplications are well-formed and authentic', () {
      const items = SupplicationsRepository.defaultItems;
      expect(items, isNotEmpty);
      expect(items.length, greaterThanOrEqualTo(4));

      for (final item in items) {
        expect(item.id, isNotEmpty);
        expect(item.text, isNotEmpty);
        expect(item.source, isNotEmpty);
        expect(item.tickerFormatted, contains(item.text));
      }
    });

    test('IslamicSupplication model serialization roundtrip', () {
      const original = IslamicSupplication(
        id: 'test_dua_1',
        category: 'quranic_dua',
        categoryAr: 'أدعية قرآنية',
        text: '﴿رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً﴾',
        source: 'البقرة: 201',
        virtue: 'أجمع دعاء',
        repeatCount: 3,
      );

      final json = original.toJson();
      final restored = IslamicSupplication.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.category, equals(original.category));
      expect(restored.text, equals(original.text));
      expect(restored.source, equals(original.source));
      expect(restored.virtue, equals(original.virtue));
      expect(restored.repeatCount, equals(3));
    });

    test('AppTheme provides all 5 verified Islamic fonts', () {
      const fonts = AppTheme.islamicFonts;
      expect(fonts.length, equals(5));

      final keys = fonts.map((f) => f.key).toSet();
      expect(keys, containsAll([
        'amiriQuran',
        'scheherazadeNew',
        'amiri',
        'arefRuqaa',
        'cairo',
      ]));

      // Check font style generation for each font
      for (final font in fonts) {
        final style = AppTheme.getIslamicStyle(fontKey: font.key, fontSize: 24);
        expect(style, isNotNull);
        expect(style.fontSize, equals(24));
      }
    });
  });
}
