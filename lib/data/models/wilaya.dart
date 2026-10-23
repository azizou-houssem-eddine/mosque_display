import 'package:flutter/foundation.dart';

/// Immutable model representing an Algerian Wilaya (province).
///
/// Contains official administrative code (1-58), Arabic name, French name,
/// and verified geographic coordinates (latitude, longitude) of the capital/central mosque.
@immutable
class Wilaya {
  final int code;
  final String nameAr;
  final String nameFr;
  final double latitude;
  final double longitude;

  const Wilaya({
    required this.code,
    required this.nameAr,
    required this.nameFr,
    required this.latitude,
    required this.longitude,
  })  : assert(code >= 1 && code <= 58, 'Wilaya code must be between 1 and 58'),
        assert(latitude >= 18.0 && latitude <= 38.0,
            'Latitude must be within Algerian territory (18.0 - 38.0)'),
        assert(longitude >= -9.0 && longitude <= 12.0,
            'Longitude must be within Algerian territory (-9.0 - 12.0)');

  /// Formatted Arabic display string: "16 - الجزائر"
  String get displayNameAr => '$code - $nameAr';

  /// Formatted French display string: "16 - Alger"
  String get displayNameFr => '$code - $nameFr';

  /// Bilingual display string: "16 - الجزائر (Alger)"
  String get displayName => '$code - $nameAr ($nameFr)';

  /// Checks if this Wilaya matches a search query (by code, Arabic name, or French name).
  bool matchesQuery(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return true;

    // Match numeric code
    if (code.toString() == cleanQuery) return true;

    // Match French name
    if (nameFr.toLowerCase().contains(cleanQuery)) return true;

    // Match Arabic name
    if (nameAr.contains(cleanQuery)) return true;

    return false;
  }

  /// Creates a copy with optionally updated fields.
  Wilaya copyWith({
    int? code,
    String? nameAr,
    String? nameFr,
    double? latitude,
    double? longitude,
  }) {
    return Wilaya(
      code: code ?? this.code,
      nameAr: nameAr ?? this.nameAr,
      nameFr: nameFr ?? this.nameFr,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  /// Serializes to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'nameAr': nameAr,
      'nameFr': nameFr,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Deserializes from a JSON map.
  factory Wilaya.fromJson(Map<String, dynamic> json) {
    return Wilaya(
      code: json['code'] as int,
      nameAr: json['nameAr'] as String,
      nameFr: json['nameFr'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wilaya &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          nameAr == other.nameAr &&
          nameFr == other.nameFr &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(code, nameAr, nameFr, latitude, longitude);

  @override
  String toString() =>
      'Wilaya(code: $code, nameAr: $nameAr, nameFr: $nameFr, lat: $latitude, lng: $longitude)';
}

/// The official list of all 58 Algerian Wilayas according to Law 19-12.
const List<Wilaya> algerianWilayas = [
  Wilaya(code: 1, nameAr: 'أدرار', nameFr: 'Adrar', latitude: 27.8743, longitude: -0.2939),
  Wilaya(code: 2, nameAr: 'الشلف', nameFr: 'Chlef', latitude: 36.1647, longitude: 1.3317),
  Wilaya(code: 3, nameAr: 'الأغواط', nameFr: 'Laghouat', latitude: 33.8000, longitude: 2.8651),
  Wilaya(code: 4, nameAr: 'أم البواقي', nameFr: 'Oum El Bouaghi', latitude: 35.8753, longitude: 7.1135),
  Wilaya(code: 5, nameAr: 'باتنة', nameFr: 'Batna', latitude: 35.5560, longitude: 6.1741),
  Wilaya(code: 6, nameAr: 'بجاية', nameFr: 'Béjaïa', latitude: 36.7559, longitude: 5.0843),
  Wilaya(code: 7, nameAr: 'بسكرة', nameFr: 'Biskra', latitude: 34.8504, longitude: 5.7280),
  Wilaya(code: 8, nameAr: 'بشار', nameFr: 'Béchar', latitude: 31.6167, longitude: -2.2167),
  Wilaya(code: 9, nameAr: 'البليدة', nameFr: 'Blida', latitude: 36.4702, longitude: 2.8277),
  Wilaya(code: 10, nameAr: 'البويرة', nameFr: 'Bouira', latitude: 36.3749, longitude: 3.9020),
  Wilaya(code: 11, nameAr: 'تمنراست', nameFr: 'Tamanrasset', latitude: 22.7850, longitude: 5.5228),
  Wilaya(code: 12, nameAr: 'تبسة', nameFr: 'Tébessa', latitude: 35.4042, longitude: 8.1242),
  Wilaya(code: 13, nameAr: 'تلمسان', nameFr: 'Tlemcen', latitude: 34.8783, longitude: -1.3150),
  Wilaya(code: 14, nameAr: 'تيارت', nameFr: 'Tiaret', latitude: 35.3710, longitude: 1.3170),
  Wilaya(code: 15, nameAr: 'تيزي وزو', nameFr: 'Tizi Ouzou', latitude: 36.7118, longitude: 4.0459),
  Wilaya(code: 16, nameAr: 'الجزائر', nameFr: 'Alger', latitude: 36.7538, longitude: 3.0588),
  Wilaya(code: 17, nameAr: 'الجلفة', nameFr: 'Djelfa', latitude: 34.6728, longitude: 3.2630),
  Wilaya(code: 18, nameAr: 'جيجل', nameFr: 'Jijel', latitude: 36.8206, longitude: 5.7667),
  Wilaya(code: 19, nameAr: 'سطيف', nameFr: 'Sétif', latitude: 36.1911, longitude: 5.4137),
  Wilaya(code: 20, nameAr: 'سعيدة', nameFr: 'Saïda', latitude: 34.8303, longitude: 0.1517),
  Wilaya(code: 21, nameAr: 'سكيكدة', nameFr: 'Skikda', latitude: 36.8762, longitude: 6.9092),
  Wilaya(code: 22, nameAr: 'سيدي بلعباس', nameFr: 'Sidi Bel Abbès', latitude: 35.1899, longitude: -0.6308),
  Wilaya(code: 23, nameAr: 'عنابة', nameFr: 'Annaba', latitude: 36.9000, longitude: 7.7667),
  Wilaya(code: 24, nameAr: 'قالمة', nameFr: 'Guelma', latitude: 36.4621, longitude: 7.4261),
  Wilaya(code: 25, nameAr: 'قسنطينة', nameFr: 'Constantine', latitude: 36.3650, longitude: 6.6147),
  Wilaya(code: 26, nameAr: 'المدية', nameFr: 'Médéa', latitude: 36.2642, longitude: 2.7539),
  Wilaya(code: 27, nameAr: 'مستغانم', nameFr: 'Mostaganem', latitude: 35.9312, longitude: 0.0892),
  Wilaya(code: 28, nameAr: 'المسيلة', nameFr: 'M\'Sila', latitude: 35.7058, longitude: 4.5419),
  Wilaya(code: 29, nameAr: 'معسكر', nameFr: 'Mascara', latitude: 35.3947, longitude: 0.1403),
  Wilaya(code: 30, nameAr: 'ورقلة', nameFr: 'Ouargla', latitude: 31.9493, longitude: 5.3250),
  Wilaya(code: 31, nameAr: 'وهران', nameFr: 'Oran', latitude: 35.6971, longitude: -0.6308),
  Wilaya(code: 32, nameAr: 'البيض', nameFr: 'El Bayadh', latitude: 33.6832, longitude: 1.0193),
  Wilaya(code: 33, nameAr: 'إليزي', nameFr: 'Illizi', latitude: 26.4833, longitude: 8.4667),
  Wilaya(code: 34, nameAr: 'برج بوعريريج', nameFr: 'Bordj Bou Arreridj', latitude: 36.0732, longitude: 4.7611),
  Wilaya(code: 35, nameAr: 'بومرداس', nameFr: 'Boumerdès', latitude: 36.7664, longitude: 3.4772),
  Wilaya(code: 36, nameAr: 'الطارف', nameFr: 'El Tarf', latitude: 36.7672, longitude: 8.3138),
  Wilaya(code: 37, nameAr: 'تندوف', nameFr: 'Tindouf', latitude: 27.6711, longitude: -8.1474),
  Wilaya(code: 38, nameAr: 'تيسمسيلت', nameFr: 'Tissemsilt', latitude: 35.6072, longitude: 1.8108),
  Wilaya(code: 39, nameAr: 'الوادي', nameFr: 'El Oued', latitude: 33.3683, longitude: 6.8674),
  Wilaya(code: 40, nameAr: 'خنشلة', nameFr: 'Khenchela', latitude: 35.4358, longitude: 7.1433),
  Wilaya(code: 41, nameAr: 'سوق أهراس', nameFr: 'Souk Ahras', latitude: 36.2864, longitude: 7.9511),
  Wilaya(code: 42, nameAr: 'تيبازة', nameFr: 'Tipaza', latitude: 36.5897, longitude: 2.4475),
  Wilaya(code: 43, nameAr: 'ميلة', nameFr: 'Mila', latitude: 36.4503, longitude: 6.2644),
  Wilaya(code: 44, nameAr: 'عين الدفلى', nameFr: 'Aïn Defla', latitude: 36.2650, longitude: 1.9679),
  Wilaya(code: 45, nameAr: 'النعامة', nameFr: 'Naâma', latitude: 33.2667, longitude: -0.3167),
  Wilaya(code: 46, nameAr: 'عين تموشنت', nameFr: 'Aïn Témouchent', latitude: 35.2975, longitude: -1.1404),
  Wilaya(code: 47, nameAr: 'غرداية', nameFr: 'Ghardaïa', latitude: 32.4909, longitude: 3.6735),
  Wilaya(code: 48, nameAr: 'غليزان', nameFr: 'Relizane', latitude: 35.7373, longitude: 0.5559),
  Wilaya(code: 49, nameAr: 'تيميمون', nameFr: 'Timimoun', latitude: 29.2639, longitude: 0.2310),
  Wilaya(code: 50, nameAr: 'برج باجي مختار', nameFr: 'Bordj Badji Mokhtar', latitude: 21.3281, longitude: 0.9547),
  Wilaya(code: 51, nameAr: 'أولاد جلال', nameFr: 'Ouled Djellal', latitude: 34.4172, longitude: 5.0653),
  Wilaya(code: 52, nameAr: 'بني عباس', nameFr: 'Béni Abbès', latitude: 30.1333, longitude: -2.1667),
  Wilaya(code: 53, nameAr: 'عين صالح', nameFr: 'In Salah', latitude: 27.1936, longitude: 2.4608),
  Wilaya(code: 54, nameAr: 'عين قزام', nameFr: 'In Guezzam', latitude: 19.5722, longitude: 5.7692),
  Wilaya(code: 55, nameAr: 'تقرت', nameFr: 'Touggourt', latitude: 33.1053, longitude: 6.0581),
  Wilaya(code: 56, nameAr: 'جانت', nameFr: 'Djanet', latitude: 24.5531, longitude: 9.4858),
  Wilaya(code: 57, nameAr: 'المغير', nameFr: 'El M\'Ghair', latitude: 33.9500, longitude: 5.9222),
  Wilaya(code: 58, nameAr: 'المنيعة', nameFr: 'El Meniaa', latitude: 30.5833, longitude: 2.8833),
];
