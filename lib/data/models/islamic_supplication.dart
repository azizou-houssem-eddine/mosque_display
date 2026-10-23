import 'package:flutter/foundation.dart';

/// Represents a verified authentic Islamic supplication, dhikr, or hadith.
@immutable
class IslamicSupplication {
  final String id;
  final String category;
  final String categoryAr;
  final String text;
  final String source;
  final String? virtue;
  final int? repeatCount;

  const IslamicSupplication({
    required this.id,
    required this.category,
    required this.categoryAr,
    required this.text,
    required this.source,
    this.virtue,
    this.repeatCount,
  });

  /// Formatted string suitable for single-line ticker display.
  String get tickerFormatted {
    if (source.isNotEmpty) {
      return '$text ($source)';
    }
    return text;
  }

  factory IslamicSupplication.fromJson(Map<String, dynamic> json) {
    return IslamicSupplication(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      categoryAr: json['categoryAr'] as String? ?? 'أدعية وأذكار',
      text: json['text'] as String? ?? '',
      source: json['source'] as String? ?? '',
      virtue: json['virtue'] as String?,
      repeatCount: (json['repeatCount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'categoryAr': categoryAr,
      'text': text,
      'source': source,
      if (virtue != null) 'virtue': virtue,
      if (repeatCount != null) 'repeatCount': repeatCount,
    };
  }
}
