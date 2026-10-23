import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// ============================================================================
// 1. DOMAIN CONTRACTS (Matching PROJECT.md Interface Contracts)
// ============================================================================

enum Prayer { fajr, sunrise, dhuhr, asr, maghrib, isha }

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
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wilaya &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => code.hashCode ^ latitude.hashCode ^ longitude.hashCode;
}

class PrayerOffsets {
  final int fajr;
  final int dhuhr;
  final int asr;
  final int maghrib;
  final int isha;

  const PrayerOffsets({
    this.fajr = 0,
    this.dhuhr = 0,
    this.asr = 0,
    this.maghrib = 0,
    this.isha = 0,
  });

  bool isValid() {
    return fajr >= -15 &&
        fajr <= 15 &&
        dhuhr >= -15 &&
        dhuhr <= 15 &&
        asr >= -15 &&
        asr <= 15 &&
        maghrib >= -15 &&
        maghrib <= 15 &&
        isha >= -15 &&
        isha <= 15;
  }

  PrayerOffsets copyWith({
    int? fajr,
    int? dhuhr,
    int? asr,
    int? maghrib,
    int? isha,
  }) {
    return PrayerOffsets(
      fajr: fajr ?? this.fajr,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
    );
  }

  Map<String, dynamic> toJson() => {
        'fajr': fajr,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
      };

  factory PrayerOffsets.fromJson(Map<String, dynamic> json) => PrayerOffsets(
        fajr: json['fajr'] as int? ?? 0,
        dhuhr: json['dhuhr'] as int? ?? 0,
        asr: json['asr'] as int? ?? 0,
        maghrib: json['maghrib'] as int? ?? 0,
        isha: json['isha'] as int? ?? 0,
      );
}

class IqamahDelays {
  final int fajr;
  final int dhuhr;
  final int asr;
  final int maghrib;
  final int isha;

  const IqamahDelays({
    this.fajr = 20,
    this.dhuhr = 15,
    this.asr = 15,
    this.maghrib = 5,
    this.isha = 15,
  });

  int forPrayer(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return fajr;
      case Prayer.dhuhr:
        return dhuhr;
      case Prayer.asr:
        return asr;
      case Prayer.maghrib:
        return maghrib;
      case Prayer.isha:
        return isha;
      case Prayer.sunrise:
        return 0;
    }
  }

  IqamahDelays copyWith({
    int? fajr,
    int? dhuhr,
    int? asr,
    int? maghrib,
    int? isha,
  }) {
    return IqamahDelays(
      fajr: fajr ?? this.fajr,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
    );
  }

  Map<String, dynamic> toJson() => {
        'fajr': fajr,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
      };

  factory IqamahDelays.fromJson(Map<String, dynamic> json) => IqamahDelays(
        fajr: json['fajr'] as int? ?? 20,
        dhuhr: json['dhuhr'] as int? ?? 15,
        asr: json['asr'] as int? ?? 15,
        maghrib: json['maghrib'] as int? ?? 5,
        isha: json['isha'] as int? ?? 15,
      );
}

class PrayerSchedule {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  const PrayerSchedule({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  DateTime forPrayer(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return fajr;
      case Prayer.sunrise:
        return sunrise;
      case Prayer.dhuhr:
        return dhuhr;
      case Prayer.asr:
        return asr;
      case Prayer.maghrib:
        return maghrib;
      case Prayer.isha:
        return isha;
    }
  }

  PrayerSchedule applyOffsets(PrayerOffsets offsets) {
    return PrayerSchedule(
      fajr: fajr.add(Duration(minutes: offsets.fajr)),
      sunrise: sunrise,
      dhuhr: dhuhr.add(Duration(minutes: offsets.dhuhr)),
      asr: asr.add(Duration(minutes: offsets.asr)),
      maghrib: maghrib.add(Duration(minutes: offsets.maghrib)),
      isha: isha.add(Duration(minutes: offsets.isha)),
    );
  }

  String formatPrayer(Prayer prayer) {
    final dt = forPrayer(prayer);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class MosqueSettings {
  final int selectedWilayaCode;
  final PrayerOffsets offsets;
  final IqamahDelays iqamahDelays;
  final int blackoutDurationMinutes;
  final bool blackoutDimMode;
  final int hijriOffsetDays;
  final String mosqueName;
  final String marqueeText;
  final String pinCode;

  const MosqueSettings({
    this.selectedWilayaCode = 16,
    this.offsets = const PrayerOffsets(),
    this.iqamahDelays = const IqamahDelays(),
    this.blackoutDurationMinutes = 20,
    this.blackoutDimMode = false,
    this.hijriOffsetDays = 0,
    this.mosqueName = 'مسجد الفتح',
    this.marqueeText =
        'قال رسول الله ﷺ: مَن بنى للهِ مسجدًا بنى اللهُ له مِثلَه في الجنَّة',
    this.pinCode = '0000',
  });

  MosqueSettings copyWith({
    int? selectedWilayaCode,
    PrayerOffsets? offsets,
    IqamahDelays? iqamahDelays,
    int? blackoutDurationMinutes,
    bool? blackoutDimMode,
    int? hijriOffsetDays,
    String? mosqueName,
    String? marqueeText,
    String? pinCode,
  }) {
    return MosqueSettings(
      selectedWilayaCode: selectedWilayaCode ?? this.selectedWilayaCode,
      offsets: offsets ?? this.offsets,
      iqamahDelays: iqamahDelays ?? this.iqamahDelays,
      blackoutDurationMinutes:
          blackoutDurationMinutes ?? this.blackoutDurationMinutes,
      blackoutDimMode: blackoutDimMode ?? this.blackoutDimMode,
      hijriOffsetDays: hijriOffsetDays ?? this.hijriOffsetDays,
      mosqueName: mosqueName ?? this.mosqueName,
      marqueeText: marqueeText ?? this.marqueeText,
      pinCode: pinCode ?? this.pinCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'selectedWilayaCode': selectedWilayaCode,
        'offsets': offsets.toJson(),
        'iqamahDelays': iqamahDelays.toJson(),
        'blackoutDurationMinutes': blackoutDurationMinutes,
        'blackoutDimMode': blackoutDimMode,
        'hijriOffsetDays': hijriOffsetDays,
        'mosqueName': mosqueName,
        'marqueeText': marqueeText,
        'pinCode': pinCode,
      };

  factory MosqueSettings.fromJson(Map<String, dynamic> json) => MosqueSettings(
        selectedWilayaCode: json['selectedWilayaCode'] as int? ?? 16,
        offsets: json['offsets'] != null
            ? PrayerOffsets.fromJson(json['offsets'] as Map<String, dynamic>)
            : const PrayerOffsets(),
        iqamahDelays: json['iqamahDelays'] != null
            ? IqamahDelays.fromJson(
                json['iqamahDelays'] as Map<String, dynamic>)
            : const IqamahDelays(),
        blackoutDurationMinutes: json['blackoutDurationMinutes'] as int? ?? 20,
        blackoutDimMode: json['blackoutDimMode'] as bool? ?? false,
        hijriOffsetDays: json['hijriOffsetDays'] as int? ?? 0,
        mosqueName: json['mosqueName'] as String? ?? 'مسجد الفتح',
        marqueeText: json['marqueeText'] as String? ??
            'قال رسول الله ﷺ: مَن بنى للهِ مسجدًا بنى اللهُ له مِثلَه في الجنَّة',
        pinCode: json['pinCode'] as String? ?? '0000',
      );
}

// ============================================================================
// 2. STATE MACHINE CONTRACTS
// ============================================================================

enum DisplayMode { standard, adhan, iqamah, blackout }

abstract class DisplayState {
  final DisplayMode mode;
  final PrayerSchedule schedule;
  final Prayer targetPrayer;

  const DisplayState({
    required this.mode,
    required this.schedule,
    required this.targetPrayer,
  });
}

class StandardDisplayState extends DisplayState {
  final Duration timeRemainingToNextAdhan;

  const StandardDisplayState({
    required super.schedule,
    required super.targetPrayer,
    required this.timeRemainingToNextAdhan,
  }) : super(mode: DisplayMode.standard);
}

class AdhanAlertDisplayState extends DisplayState {
  final Duration remainingAlertDuration;

  const AdhanAlertDisplayState({
    required super.schedule,
    required super.targetPrayer,
    required this.remainingAlertDuration,
  }) : super(mode: DisplayMode.adhan);
}

class IqamahCountdownDisplayState extends DisplayState {
  final Duration remainingIqamahDuration;
  final Duration totalIqamahDuration;

  const IqamahCountdownDisplayState({
    required super.schedule,
    required super.targetPrayer,
    required this.remainingIqamahDuration,
    required this.totalIqamahDuration,
  }) : super(mode: DisplayMode.iqamah);
}

class SalatBlackoutDisplayState extends DisplayState {
  final Duration remainingBlackoutDuration;
  final bool dimMode;

  const SalatBlackoutDisplayState({
    required super.schedule,
    required super.targetPrayer,
    required this.remainingBlackoutDuration,
    required this.dimMode,
  }) : super(mode: DisplayMode.blackout);
}

abstract class IDisplayStateMachine {
  ValueNotifier<DisplayState> get currentState;
  void updateTick(DateTime now);
}

abstract class IPrayerRepository {
  Future<PrayerSchedule> getPrayerTimes({
    required int wilayaCode,
    required DateTime date,
    PrayerOffsets offsets = const PrayerOffsets(),
  });
  Future<List<Wilaya>> getAllWilayas();
}

abstract class ISettingsRepository {
  Future<MosqueSettings> loadSettings();
  Future<void> saveSettings(MosqueSettings settings);
  ValueNotifier<MosqueSettings> get settingsNotifier;
}

// ============================================================================
// 3. OFFICIAL 58 WILAYAS DATASET & BENCHMARKS (Survey 2 Authority)
// ============================================================================

const List<Wilaya> verified58Wilayas = [
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

// Ground-Truth Reference Table for 2026-10-06 (Survey 2 & AlAdhan Method 19 API)
class BenchmarkData {
  static final DateTime benchmarkDate = DateTime(2026, 10, 6);

  static final Map<int, Map<Prayer, String>> groundTruth20261006 = {
    16: {
      Prayer.fajr: '05:21',
      Prayer.sunrise: '06:47',
      Prayer.dhuhr: '12:36',
      Prayer.asr: '15:54',
      Prayer.maghrib: '18:24',
      Prayer.isha: '19:45',
    },
    31: {
      Prayer.fajr: '05:37',
      Prayer.sunrise: '07:01',
      Prayer.dhuhr: '12:51',
      Prayer.asr: '16:09',
      Prayer.maghrib: '18:39',
      Prayer.isha: '19:59',
    },
    25: {
      Prayer.fajr: '05:07',
      Prayer.sunrise: '06:33',
      Prayer.dhuhr: '12:22',
      Prayer.asr: '15:40',
      Prayer.maghrib: '18:10',
      Prayer.isha: '19:30',
    },
    30: {
      Prayer.fajr: '05:15',
      Prayer.sunrise: '06:36',
      Prayer.dhuhr: '12:27',
      Prayer.asr: '15:47',
      Prayer.maghrib: '18:17',
      Prayer.isha: '19:34',
    },
  };

  static PrayerSchedule getScheduleFor(int wilayaCode, DateTime date) {
    final times = groundTruth20261006[wilayaCode];
    if (times == null) {
      throw ArgumentError('Benchmark Wilaya $wilayaCode not found');
    }
    DateTime parseTime(String hhMm) {
      final parts = hhMm.split(':');
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    }

    return PrayerSchedule(
      fajr: parseTime(times[Prayer.fajr]!),
      sunrise: parseTime(times[Prayer.sunrise]!),
      dhuhr: parseTime(times[Prayer.dhuhr]!),
      asr: parseTime(times[Prayer.asr]!),
      maghrib: parseTime(times[Prayer.maghrib]!),
      isha: parseTime(times[Prayer.isha]!),
    );
  }
}

// ============================================================================
// 4. ALGORITHMIC METHOD 19 REFERENCE CALCULATOR (Offline Oracle)
// ============================================================================

class ReferenceMethod19Calculator {
  static const double fajrAngle = 18.0;
  static const double ishaAngle = 17.0;
  static const int timezoneOffsetHours = 1; // Algeria UTC+1 (no DST)

  static PrayerSchedule calculate({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) {
    // Julian Date calculation
    final y = date.year;
    final m = date.month;
    final d = date.day;
    final jd = _julianDate(y, m, d);

    // Solar coordinates
    final dEpoch = jd - 2451545.0;
    final g = (357.529 + 0.98560028 * dEpoch) % 360.0;
    final q = (280.459 + 0.98564736 * dEpoch) % 360.0;
    final l = (q +
            1.915 * math.sin(_rad(g)) +
            0.020 * math.sin(_rad(2 * g))) %
        360.0;
    final e = 23.439 - 0.00000036 * dEpoch;
    final ra = _deg(math.atan2(
            math.cos(_rad(e)) * math.sin(_rad(l)), math.cos(_rad(l)))) /
        15.0;
    final dec = _deg(math.asin(math.sin(_rad(e)) * math.sin(_rad(l))));

    // Equation of time in hours
    final eqt = (q / 15.0) - (ra < 0 ? ra + 24.0 : ra);

    // Solar noon (Dhuhr) in hours UTC
    final noonUtc = 12.0 - (longitude / 15.0) - eqt;
    // Dhuhr: +1 hour timezone + 1 min (+0.016667h) Zawāl safety margin
    final dhuhrHours = noonUtc + timezoneOffsetHours + (1.0 / 60.0);

    // Hour angle functions
    double hourAngle(double angle) {
      final cosHa = (-math.sin(_rad(angle)) -
              math.sin(_rad(latitude)) * math.sin(_rad(dec))) /
          (math.cos(_rad(latitude)) * math.cos(_rad(dec)));
      if (cosHa < -1.0 || cosHa > 1.0) return 0.0;
      return _deg(math.acos(cosHa)) / 15.0;
    }

    // Fajr (18° below horizon)
    final haFajr = hourAngle(fajrAngle);
    final fajrHours = dhuhrHours - haFajr - (1.0 / 60.0);

    // Sunrise (0.833° atmospheric refraction + semi-diameter)
    final haSunrise = hourAngle(0.833);
    final sunriseHours = dhuhrHours - haSunrise - (1.0 / 60.0);

    // Asr (Maliki factor 1: shadow = obj + noonShadow)
    final noonAlt = 90.0 - (latitude - dec).abs();
    final noonShadow = 1.0 / math.tan(_rad(noonAlt));
    final asrAlt = _deg(math.atan(1.0 / (1.0 + noonShadow)));
    final cosHaAsr = (math.sin(_rad(asrAlt)) -
            math.sin(_rad(latitude)) * math.sin(_rad(dec))) /
        (math.cos(_rad(latitude)) * math.cos(_rad(dec)));
    final haAsr = _deg(math.acos(cosHaAsr.clamp(-1.0, 1.0))) / 15.0;
    final asrHours = dhuhrHours + haAsr;

    // Maghrib (0.833°)
    final maghribHours = dhuhrHours + haSunrise;

    // Isha (17° below horizon)
    final haIsha = hourAngle(ishaAngle);
    final ishaHours = dhuhrHours + haIsha;

    DateTime toDate(double h) {
      final totalMinutes = (h * 60).round();
      final hr = (totalMinutes ~/ 60) % 24;
      final mn = totalMinutes % 60;
      return DateTime(date.year, date.month, date.day, hr, mn);
    }

    return PrayerSchedule(
      fajr: toDate(fajrHours),
      sunrise: toDate(sunriseHours),
      dhuhr: toDate(dhuhrHours),
      asr: toDate(asrHours),
      maghrib: toDate(maghribHours),
      isha: toDate(ishaHours),
    );
  }

  static double _rad(double d) => d * math.pi / 180.0;
  static double _deg(double r) => r * 180.0 / math.pi;

  static double _julianDate(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524.5;
  }
}

// ============================================================================
// 5. TEST REPOSITORIES & CONTROLLABLE STATE MACHINE HARNESS
// ============================================================================

class FakePrayerRepository implements IPrayerRepository {
  @override
  Future<List<Wilaya>> getAllWilayas() async => verified58Wilayas;

  @override
  Future<PrayerSchedule> getPrayerTimes({
    required int wilayaCode,
    required DateTime date,
    PrayerOffsets offsets = const PrayerOffsets(),
  }) async {
    // 1. Primary: If benchmark Wilaya & benchmark date, return exact official table
    if (BenchmarkData.groundTruth20261006.containsKey(wilayaCode) &&
        date.year == 2026 &&
        date.month == 10 &&
        date.day == 6) {
      final base = BenchmarkData.getScheduleFor(wilayaCode, date);
      return base.applyOffsets(offsets);
    }

    // 2. Fallback: Algorithmic Method 19 calculation
    final wilaya = verified58Wilayas.firstWhere(
      (w) => w.code == wilayaCode,
      orElse: () => verified58Wilayas.first,
    );
    final calculated = ReferenceMethod19Calculator.calculate(
      latitude: wilaya.latitude,
      longitude: wilaya.longitude,
      date: date,
    );
    return calculated.applyOffsets(offsets);
  }
}

class FakeSettingsRepository implements ISettingsRepository {
  MosqueSettings _settings;
  final ValueNotifier<MosqueSettings> _notifier;

  FakeSettingsRepository([MosqueSettings? initial])
      : _settings = initial ?? const MosqueSettings(),
        _notifier =
            ValueNotifier<MosqueSettings>(initial ?? const MosqueSettings());

  @override
  Future<MosqueSettings> loadSettings() async => _settings;

  @override
  Future<void> saveSettings(MosqueSettings settings) async {
    _settings = settings;
    _notifier.value = settings;
  }

  @override
  ValueNotifier<MosqueSettings> get settingsNotifier => _notifier;
}

class TestDisplayStateMachine implements IDisplayStateMachine {
  final IPrayerRepository prayerRepository;
  final ISettingsRepository settingsRepository;

  late ValueNotifier<DisplayState> _stateNotifier;
  DateTime _currentTime;
  int _activeWilayaCode;
  PrayerOffsets _offsets;
  IqamahDelays _iqamahDelays;
  int _blackoutDurationMinutes;
  bool _blackoutDimMode;
  PrayerSchedule? _cachedSchedule;

  static const int adhanAlertDurationSeconds = 120; // 2 minutes

  TestDisplayStateMachine({
    required this.prayerRepository,
    required this.settingsRepository,
    required DateTime initialTime,
  }) : _currentTime = initialTime,
       _activeWilayaCode = 16,
       _offsets = const PrayerOffsets(),
       _iqamahDelays = const IqamahDelays(),
       _blackoutDurationMinutes = 20,
       _blackoutDimMode = false,
       _cachedSchedule = _dummySchedule(initialTime) {
    _stateNotifier = ValueNotifier<DisplayState>(
      StandardDisplayState(
        schedule: _dummySchedule(initialTime),
        targetPrayer: Prayer.fajr,
        timeRemainingToNextAdhan: const Duration(hours: 1),
      ),
    );

    settingsRepository.settingsNotifier.addListener(_onSettingsChanged);
    _onSettingsChanged();
    updateTick(initialTime);
  }

  static PrayerSchedule _dummySchedule(DateTime dt) => PrayerSchedule(
        fajr: DateTime(dt.year, dt.month, dt.day, 5, 21),
        sunrise: DateTime(dt.year, dt.month, dt.day, 6, 47),
        dhuhr: DateTime(dt.year, dt.month, dt.day, 12, 36),
        asr: DateTime(dt.year, dt.month, dt.day, 15, 54),
        maghrib: DateTime(dt.year, dt.month, dt.day, 18, 24),
        isha: DateTime(dt.year, dt.month, dt.day, 19, 45),
      );

  void _onSettingsChanged() {
    final s = settingsRepository.settingsNotifier.value;
    _activeWilayaCode = s.selectedWilayaCode;
    _offsets = s.offsets;
    _iqamahDelays = s.iqamahDelays;
    _blackoutDurationMinutes = s.blackoutDurationMinutes;
    _blackoutDimMode = s.blackoutDimMode;
    _refreshScheduleAndEvaluate();
  }

  Future<void> _refreshScheduleAndEvaluate() async {
    _cachedSchedule = await prayerRepository.getPrayerTimes(
      wilayaCode: _activeWilayaCode,
      date: _currentTime,
      offsets: _offsets,
    );
    updateTick(_currentTime);
  }

  @override
  ValueNotifier<DisplayState> get currentState => _stateNotifier;

  @override
  void updateTick(DateTime now) {
    _currentTime = now;
    if (_cachedSchedule == null) return;

    final schedule = _cachedSchedule!;
    final prayers = [
      Prayer.fajr,
      Prayer.sunrise,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];

    // Evaluate state intervals deterministically
    for (final p in prayers) {
      if (p == Prayer.sunrise) continue; // Sunrise does not trigger Iqamah/Blackout

      final prayerTime = schedule.forPrayer(p);
      final adhanEnd =
          prayerTime.add(Duration(seconds: adhanAlertDurationSeconds));
      final iqamahDuration =
          Duration(minutes: _iqamahDelays.forPrayer(p));
      final iqamahEnd = adhanEnd.add(iqamahDuration);
      final blackoutDuration =
          Duration(minutes: _blackoutDurationMinutes);
      final blackoutEnd = iqamahEnd.add(blackoutDuration);

      // Adhan Alert Interval
      if (!now.isBefore(prayerTime) && now.isBefore(adhanEnd)) {
        final rem = adhanEnd.difference(now);
        _stateNotifier.value = AdhanAlertDisplayState(
          schedule: schedule,
          targetPrayer: p,
          remainingAlertDuration: rem,
        );
        return;
      }

      // Iqamah Countdown Interval
      if (!now.isBefore(adhanEnd) && now.isBefore(iqamahEnd)) {
        final rem = iqamahEnd.difference(now);
        _stateNotifier.value = IqamahCountdownDisplayState(
          schedule: schedule,
          targetPrayer: p,
          remainingIqamahDuration: rem,
          totalIqamahDuration: iqamahDuration,
        );
        return;
      }

      // Salat Blackout Interval
      if (!now.isBefore(iqamahEnd) && now.isBefore(blackoutEnd)) {
        final rem = blackoutEnd.difference(now);
        _stateNotifier.value = SalatBlackoutDisplayState(
          schedule: schedule,
          targetPrayer: p,
          remainingBlackoutDuration: rem,
          dimMode: _blackoutDimMode,
        );
        return;
      }
    }

    // Default: Standard Display Mode - find next upcoming prayer
    Prayer nextPrayer = Prayer.fajr;
    Duration minRemaining = const Duration(days: 1);

    for (final p in prayers) {
      final t = schedule.forPrayer(p);
      if (t.isAfter(now)) {
        nextPrayer = p;
        minRemaining = t.difference(now);
        break;
      }
    }

    // If past Isha, next prayer is tomorrow's Fajr
    if (now.isAfter(schedule.isha)) {
      nextPrayer = Prayer.fajr;
      final tomorrowFajr =
          schedule.fajr.add(const Duration(days: 1));
      minRemaining = tomorrowFajr.difference(now);
    }

    _stateNotifier.value = StandardDisplayState(
      schedule: schedule,
      targetPrayer: nextPrayer,
      timeRemainingToNextAdhan: minRemaining,
    );
  }
}

// ============================================================================
// 6. CONCEPT 2 UI VERIFIERS (WCAG AAA, Geometry, Sizing)
// ============================================================================

class Concept2ThemeTokens {
  static const Color emeraldBase = Color(0xFF06231A);
  static const Color emeraldLuminous = Color(0xFF0B3326);
  static const Color emeraldCard = Color(0xFF093125);
  static const Color emeraldCardBorder = Color(0xFF134A38);
  static const Color goldRadiant = Color(0xFFF2C94C);
  static const Color goldRoyal = Color(0xFFD4AF37);
  static const Color goldAntique = Color(0xFF8C7326);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textSilver = Color(0xFFD0DCD6);
  static const Color blackOLED = Color(0xFF000000);
  static const Color blackDim = Color(0xFF020907);
  static const Color warningAmber = Color(0xFFFF9800);

  static double relativeLuminance(Color c) {
    double comp(double v) =>
        v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    final r = comp(c.r);
    final g = comp(c.g);
    final b = comp(c.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double contrastRatio(Color fg, Color bg) {
    final l1 = relativeLuminance(fg);
    final l2 = relativeLuminance(bg);
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }
}

// ============================================================================
// 7. COMPLETE CONTRACT-COMPLIANT E2E MOSQUE TEST WIDGET
// ============================================================================

class MosqueE2EApp extends StatefulWidget {
  final IDisplayStateMachine stateMachine;
  final ISettingsRepository settingsRepository;

  const MosqueE2EApp({
    super.key,
    required this.stateMachine,
    required this.settingsRepository,
  });

  @override
  State<MosqueE2EApp> createState() => _MosqueE2EAppState();
}

class _MosqueE2EAppState extends State<MosqueE2EApp> {
  bool _isSettingsOpen = false;

  void _openSettings() {
    setState(() => _isSettingsOpen = true);
  }

  void _closeSettings() {
    setState(() => _isSettingsOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'DZ'),
      supportedLocales: const [
        Locale('ar', 'DZ'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Concept2ThemeTokens.emeraldBase,
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.contextMenu ||
                      event.logicalKey == LogicalKeyboardKey.f1)) {
                _openSettings();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 1920,
                height: 1080,
                child: Stack(
                  children: [
                    ValueListenableBuilder<DisplayState>(
                      valueListenable: widget.stateMachine.currentState,
                      builder: (context, state, _) {
                        switch (state.mode) {
                          case DisplayMode.standard:
                            return _buildStandardDashboard(
                                state as StandardDisplayState);
                          case DisplayMode.adhan:
                            return _buildAdhanAlertScreen(
                                state as AdhanAlertDisplayState);
                          case DisplayMode.iqamah:
                            return _buildIqamahCountdownScreen(
                                state as IqamahCountdownDisplayState);
                          case DisplayMode.blackout:
                            return _buildSalatBlackoutScreen(
                                state as SalatBlackoutDisplayState);
                        }
                      },
                    ),

                    // On-screen TV Settings Overlay
                    if (_isSettingsOpen)
                      Positioned.fill(
                        child: _SettingsDialog(
                          settingsRepository: widget.settingsRepository,
                          onClose: _closeSettings,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardDashboard(StandardDisplayState state) {
    return Container(
      key: const Key('screen_standard_dashboard'),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -0.1),
          radius: 1.2,
          colors: [
            Concept2ThemeTokens.emeraldLuminous,
            Concept2ThemeTokens.emeraldBase,
          ],
        ),
      ),
      child: Stack(
        children: [
          // 16-point geometric mandala watermark
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: MandalaWatermarkPainter(),
              ),
            ),
          ),

          // Main Layout: Header, 3-column Center, Footer
          Column(
            children: [
              // Top Bar: Clock, Mosque Title, Hijri Date
              _buildTopBar(),
              const SizedBox(height: 24),

              // Symmetrical Prayer Cards + Central Circular Gauge
              Expanded(
                child: Row(
                  children: [
                    // Left Column (Fajr, Shuruk, Dhuhr)
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPrayerCard(
                              Prayer.fajr, 'الفجر', state.schedule.fajr, state.targetPrayer == Prayer.fajr),
                          _buildPrayerCard(
                              Prayer.sunrise, 'الشروق', state.schedule.sunrise, state.targetPrayer == Prayer.sunrise),
                          _buildPrayerCard(
                              Prayer.dhuhr, 'الظهر', state.schedule.dhuhr, state.targetPrayer == Prayer.dhuhr),
                        ],
                      ),
                    ),

                    // Center Column: Radiant Segmented Circular Gauge
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: _RadiantCircularGaugeWidget(
                          remaining: state.timeRemainingToNextAdhan,
                          targetPrayer: state.targetPrayer,
                        ),
                      ),
                    ),

                    // Right Column (Asr, Maghrib, Isha)
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPrayerCard(
                              Prayer.asr, 'العصر', state.schedule.asr, state.targetPrayer == Prayer.asr),
                          _buildPrayerCard(
                              Prayer.maghrib, 'المغرب', state.schedule.maghrib, state.targetPrayer == Prayer.maghrib),
                          _buildPrayerCard(
                              Prayer.isha, 'العشاء', state.schedule.isha, state.targetPrayer == Prayer.isha),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Bottom Bar: Hadith / Announcement Marquee Ticker
              _buildMarqueeTicker(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Live Clock (>= 88sp for distant TV legibility)
        const Text(
          '12:15',
          key: Key('text_clock_time'),
          style: TextStyle(
            fontSize: 92,
            fontWeight: FontWeight.bold,
            color: Concept2ThemeTokens.textWhite,
            letterSpacing: 2.0,
          ),
        ),
        // Mosque Name & Wilaya
        Column(
          children: [
            ValueListenableBuilder<MosqueSettings>(
              valueListenable: widget.settingsRepository.settingsNotifier,
              builder: (_, s, __) => Text(
                s.mosqueName,
                key: const Key('text_mosque_name'),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Concept2ThemeTokens.goldRadiant,
                ),
              ),
            ),
            const Text(
              'ولاية الجزائر',
              key: Key('text_wilaya_name'),
              style: TextStyle(
                fontSize: 28,
                color: Concept2ThemeTokens.textSilver,
              ),
            ),
          ],
        ),
        // Hijri Date
        const Text(
          '25 ربيع الثاني 1448 هـ',
          key: Key('text_hijri_date'),
          style: TextStyle(
            fontSize: 32,
            color: Concept2ThemeTokens.textSilver,
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerCard(
      Prayer p, String name, DateTime time, bool isActive) {
    final hhMm =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Container(
      key: Key('prayer_card_${p.name}'),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: isActive
            ? Concept2ThemeTokens.emeraldLuminous
            : Concept2ThemeTokens.emeraldCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? Concept2ThemeTokens.goldRadiant
              : Concept2ThemeTokens.emeraldCardBorder,
          width: isActive ? 3.0 : 1.5,
        ),
        boxShadow: isActive
            ? [
                const BoxShadow(
                  color: Color(0x66F2C94C),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: isActive
                  ? Concept2ThemeTokens.goldRadiant
                  : Concept2ThemeTokens.textWhite,
            ),
          ),
          Text(
            hhMm,
            style: TextStyle(
              fontSize: 44,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              color: isActive
                  ? Concept2ThemeTokens.goldRadiant
                  : Concept2ThemeTokens.textWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarqueeTicker() {
    return Container(
      key: const Key('hadith_marquee_ticker'),
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Concept2ThemeTokens.emeraldCardBorder),
      ),
      alignment: Alignment.center,
      child: ValueListenableBuilder<MosqueSettings>(
        valueListenable: widget.settingsRepository.settingsNotifier,
        builder: (_, s, __) => Text(
          s.marqueeText,
          key: const Key('text_marquee_content'),
          style: const TextStyle(
            fontSize: 26,
            color: Concept2ThemeTokens.textSilver,
          ),
        ),
      ),
    );
  }

  Widget _buildAdhanAlertScreen(AdhanAlertDisplayState state) {
    return Container(
      key: const Key('screen_adhan_alert'),
      decoration: const BoxDecoration(
        color: Concept2ThemeTokens.emeraldBase,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_active,
              size: 140,
              color: Concept2ThemeTokens.goldRadiant,
            ),
            const SizedBox(height: 32),
            Text(
              'حان الآن موعد أذان ${_arabicPrayerName(state.targetPrayer)}',
              key: const Key('text_adhan_alert_title'),
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Concept2ThemeTokens.goldRadiant,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'الله أكبر • الله أكبر',
              style: TextStyle(
                fontSize: 48,
                color: Concept2ThemeTokens.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIqamahCountdownScreen(IqamahCountdownDisplayState state) {
    final minutes =
        state.remainingIqamahDuration.inMinutes.toString().padLeft(2, '0');
    final seconds = (state.remainingIqamahDuration.inSeconds % 60)
        .toString()
        .padLeft(2, '0');
    final isAmberAlert = state.remainingIqamahDuration.inSeconds < 60;

    return Container(
      key: const Key('screen_iqamah_countdown'),
      color: Concept2ThemeTokens.emeraldBase,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'الإقامة بعد',
              style: TextStyle(
                fontSize: 44,
                color: isAmberAlert
                    ? Concept2ThemeTokens.warningAmber
                    : Concept2ThemeTokens.goldRoyal,
              ),
            ),
            const SizedBox(height: 24),
            // Fullscreen Progress Ring & Big Digits
            Container(
              key: const Key('iqamah_circular_ring'),
              width: 440,
              height: 440,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAmberAlert
                      ? Concept2ThemeTokens.warningAmber
                      : Concept2ThemeTokens.goldRadiant,
                  width: 14,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isAmberAlert
                        ? const Color(0x66FF9800)
                        : const Color(0x66F2C94C),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '$minutes:$seconds',
                key: const Key('text_iqamah_timer'),
                style: TextStyle(
                  fontSize: 104,
                  fontWeight: FontWeight.bold,
                  color: isAmberAlert
                      ? Concept2ThemeTokens.warningAmber
                      : Concept2ThemeTokens.textWhite,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'صلاة ${_arabicPrayerName(state.targetPrayer)}',
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: Concept2ThemeTokens.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalatBlackoutScreen(SalatBlackoutDisplayState state) {
    if (!state.dimMode) {
      // OLED Pitch Black Mode (#000000)
      return Container(
        key: const Key('screen_salat_blackout_oled'),
        color: Concept2ThemeTokens.blackOLED,
        child: const Center(
          child: Text(
            '•',
            style: TextStyle(color: Color(0x11FFFFFF), fontSize: 24),
          ),
        ),
      );
    }

    // Spiritual Dim Calligraphy Mode (#020907)
    return Container(
      key: const Key('screen_salat_blackout_dim'),
      color: Concept2ThemeTokens.blackDim,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 96),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.phonelink_erase,
                size: 96,
                color: Concept2ThemeTokens.goldRoyal,
              ),
              SizedBox(height: 36),
              Text(
                'اسْتَوُوا وَاعْتَدِلُوا وَسَوُّوا صُفُوفَكُمْ',
                key: Key('text_blackout_calligraphy'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Concept2ThemeTokens.goldRoyal,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'يرجى التأكد من إغلاق الهواتف النقالة',
                key: Key('text_phone_silence_reminder'),
                style: TextStyle(
                  fontSize: 38,
                  color: Concept2ThemeTokens.textSilver,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _arabicPrayerName(Prayer p) {
    switch (p) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.sunrise:
        return 'الشروق';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
    }
  }
}

class _OpenSettingsIntent extends Intent {
  const _OpenSettingsIntent();
}

// ============================================================================
// 8. 16-POINT MANDALA ROSETTE WATERMARK PAINTER
// ============================================================================

class MandalaWatermarkPainter extends CustomPainter {
  const MandalaWatermarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42;

    final paint = Paint()
      ..color = Concept2ThemeTokens.goldRoyal.withValues(alpha: 0.06)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // 16-fold rotational symmetry (22.5 degrees step)
    const points = 16;
    const step = 2 * math.pi / points;

    for (int i = 0; i < points; i++) {
      final angle = i * step;
      final x1 = center.dx + radius * math.cos(angle);
      final y1 = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x1, y1), paint);

      // Star interlacing
      final nextAngle = (i + 5) * step;
      final x2 = center.dx + radius * math.cos(nextAngle);
      final y2 = center.dy + radius * math.sin(nextAngle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 9. RADIANT CIRCULAR COUNTDOWN GAUGE WIDGET
// ============================================================================

class _RadiantCircularGaugeWidget extends StatelessWidget {
  final Duration remaining;
  final Prayer targetPrayer;

  const _RadiantCircularGaugeWidget({
    required this.remaining,
    required this.targetPrayer,
  });

  @override
  Widget build(BuildContext context) {
    final hours = remaining.inHours.toString().padLeft(2, '0');
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      key: const Key('radiant_circular_gauge'),
      width: 360,
      height: 360,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF0D4534),
            Color(0xFF06231A),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33F2C94C),
            blurRadius: 50,
            spreadRadius: 6,
          ),
        ],
        border: Border.all(
          color: Concept2ThemeTokens.goldRoyal,
          width: 8,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'الأذان القادم: ${_prayerNameAr(targetPrayer)}',
              key: const Key('text_gauge_target_prayer'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Concept2ThemeTokens.goldRadiant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '- $hours:$minutes:$seconds',
              key: const Key('text_gauge_countdown_digits'),
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: Concept2ThemeTokens.textWhite,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'الوقت المتبقي للأذان',
              style: TextStyle(
                fontSize: 22,
                color: Concept2ThemeTokens.textSilver,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _prayerNameAr(Prayer p) {
    switch (p) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.sunrise:
        return 'الشروق';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
    }
  }
}

// ============================================================================
// 10. TV SETTINGS DIALOG WITH D-PAD REMOTE ENGINE & PIN LOCK
// ============================================================================

class _SettingsDialog extends StatefulWidget {
  final ISettingsRepository settingsRepository;
  final VoidCallback onClose;

  const _SettingsDialog({
    required this.settingsRepository,
    required this.onClose,
  });

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  bool _isPinUnlocked = false;
  String _enteredPin = '';
  late MosqueSettings _currentSettings;

  @override
  void initState() {
    super.initState();
    _currentSettings = widget.settingsRepository.settingsNotifier.value;
  }

  void _onPinDigit(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        if (_enteredPin.length == 4) {
          if (_enteredPin == _currentSettings.pinCode) {
            _isPinUnlocked = true;
          } else {
            _enteredPin = ''; // Reset on incorrect PIN
          }
        }
      });
    }
  }

  void _updateSettings(MosqueSettings next) {
    setState(() => _currentSettings = next);
    widget.settingsRepository.saveSettings(next);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('tv_settings_dialog'),
      color: const Color(0xE6020D09),
      padding: const EdgeInsets.symmetric(horizontal: 160, vertical: 80),
      child: Material(
        color: Concept2ThemeTokens.emeraldBase,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(
            color: Concept2ThemeTokens.goldRadiant,
            width: 3.5,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _isPinUnlocked ? _buildSettingsContent() : _buildPinPad(),
        ),
      ),
    );
  }

  Widget _buildPinPad() {
    return Column(
      key: const Key('pin_lock_screen'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'أدخل الرقم السري لفتح الإعدادات',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Concept2ThemeTokens.goldRadiant,
          ),
        ),
        const SizedBox(height: 32),
        // PIN bullets
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final isFilled = index < _enteredPin.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled
                    ? Concept2ThemeTokens.goldRadiant
                    : Concept2ThemeTokens.emeraldCardBorder,
              ),
            );
          }),
        ),
        const SizedBox(height: 48),
        // 3x4 TV Keypad
        Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: [
            for (int i = 1; i <= 9; i++) _buildKeypadButton(i.toString()),
            _buildKeypadButton('C', onPressed: () => setState(() => _enteredPin = '')),
            _buildKeypadButton('0'),
            _buildKeypadButton('خروج', onPressed: widget.onClose),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String label, {VoidCallback? onPressed}) {
    return _TvFocusableButton(
      key: Key('btn_keypad_$label'),
      onPressed: onPressed ?? () => _onPinDigit(label),
      child: Container(
        width: 100,
        height: 80,
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Concept2ThemeTokens.textWhite,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      key: const Key('settings_content_panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'إعدادات المسجد (جهاز التحكم عن بعد)',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Concept2ThemeTokens.goldRadiant,
                  ),
                ),
              ),
              _TvFocusableButton(
                key: const Key('btn_close_settings'),
                onPressed: widget.onClose,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('حفظ وإغلاق', style: TextStyle(fontSize: 26)),
                ),
              ),
            ],
          ),
          const Divider(color: Concept2ThemeTokens.goldRoyal, height: 48),

          // Wilaya Selector (58 Wilayas)
          const Text(
            '1. اختيار الولاية (58 ولاية):',
            style: TextStyle(fontSize: 28, color: Concept2ThemeTokens.textSilver),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final w in [
                const Wilaya(code: 16, nameAr: 'الجزائر', nameFr: 'Alger', latitude: 36.7538, longitude: 3.0588),
                const Wilaya(code: 31, nameAr: 'وهران', nameFr: 'Oran', latitude: 35.6971, longitude: -0.6308),
                const Wilaya(code: 25, nameAr: 'قسنطينة', nameFr: 'Constantine', latitude: 36.3650, longitude: 6.6147),
                const Wilaya(code: 30, nameAr: 'ورقلة', nameFr: 'Ouargla', latitude: 31.9493, longitude: 5.3250),
              ])
                _TvFocusableButton(
                  key: Key('btn_wilaya_${w.code}'),
                  onPressed: () {
                    _updateSettings(_currentSettings.copyWith(selectedWilayaCode: w.code));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    color: _currentSettings.selectedWilayaCode == w.code
                        ? Concept2ThemeTokens.emeraldLuminous
                        : null,
                    child: Text(
                      '${w.code} - ${w.nameAr}',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 36),
          // Prayer Offset Stepper
          const Text(
            '2. معايرة وقت الفجر (±15 دقيقة):',
            style: TextStyle(fontSize: 28, color: Concept2ThemeTokens.textSilver),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _TvFocusableButton(
                key: const Key('btn_offset_fajr_minus'),
                onPressed: () {
                  final cur = _currentSettings.offsets.fajr;
                  if (cur > -15) {
                    _updateSettings(_currentSettings.copyWith(
                      offsets: _currentSettings.offsets.copyWith(fajr: cur - 1),
                    ));
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text('-', style: TextStyle(fontSize: 32)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '${_currentSettings.offsets.fajr} دقيقة',
                  key: const Key('text_offset_fajr_value'),
                  style: const TextStyle(fontSize: 28, color: Concept2ThemeTokens.goldRadiant),
                ),
              ),
              _TvFocusableButton(
                key: const Key('btn_offset_fajr_plus'),
                onPressed: () {
                  final cur = _currentSettings.offsets.fajr;
                  if (cur < 15) {
                    _updateSettings(_currentSettings.copyWith(
                      offsets: _currentSettings.offsets.copyWith(fajr: cur + 1),
                    ));
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text('+', style: TextStyle(fontSize: 32)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 36),
          // Blackout Duration & Dim Mode Toggle
          const Text(
            '3. تعتيم الصلاة:',
            style: TextStyle(fontSize: 28, color: Concept2ThemeTokens.textSilver),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _TvFocusableButton(
                key: const Key('btn_toggle_blackout_mode'),
                onPressed: () {
                  _updateSettings(_currentSettings.copyWith(
                    blackoutDimMode: !_currentSettings.blackoutDimMode,
                  ));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    _currentSettings.blackoutDimMode ? 'وضع التنبيه الهادئ' : 'شاشة سوداء كاملة (OLED)',
                    key: const Key('text_blackout_mode_label'),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TvFocusableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _TvFocusableButton({
    super.key,
    required this.child,
    required this.onPressed,
  });

  @override
  State<_TvFocusableButton> createState() => _TvFocusableButtonState();
}

class _TvFocusableButtonState extends State<_TvFocusableButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: _isFocused
              ? Matrix4.diagonal3Values(1.04, 1.04, 1.0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: _isFocused
                ? const Color(0xFF0E4534)
                : Concept2ThemeTokens.emeraldCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused
                  ? Concept2ThemeTokens.goldRadiant
                  : Concept2ThemeTokens.emeraldCardBorder,
              width: _isFocused ? 3.5 : 1.5,
            ),
            boxShadow: _isFocused
                ? const [
                    BoxShadow(
                      color: Color(0x66F2C94C),
                      blurRadius: 18,
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
