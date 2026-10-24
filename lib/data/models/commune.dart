import 'package:flutter/foundation.dart';

/// Represents an Algerian administrative municipality (بلدية) or district (دائرة).
/// Conforms to Algerian Ministry of Religious Affairs (MARW) and CRAAG standards.
@immutable
class Commune {
  final int code;
  final int wilayaCode;
  final String nameAr;
  final String nameFr;
  final double latitude;
  final double longitude;
  final int minuteOffset;

  const Commune({
    required this.code,
    required this.wilayaCode,
    required this.nameAr,
    required this.nameFr,
    required this.latitude,
    required this.longitude,
    this.minuteOffset = 0,
  });

  factory Commune.fromJson(Map<String, dynamic> json) {
    return Commune(
      code: (json['code'] as num).toInt(),
      wilayaCode: (json['wilayaCode'] as num).toInt(),
      nameAr: json['nameAr'] as String,
      nameFr: json['nameFr'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      minuteOffset: (json['minuteOffset'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'wilayaCode': wilayaCode,
      'nameAr': nameAr,
      'nameFr': nameFr,
      'latitude': latitude,
      'longitude': longitude,
      'minuteOffset': minuteOffset,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Commune &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          wilayaCode == other.wilayaCode;

  @override
  int get hashCode => Object.hash(code, wilayaCode);

  @override
  String toString() => '$nameAr ($nameFr) - W$wilayaCode (فارق $minuteOffset د)';
}
