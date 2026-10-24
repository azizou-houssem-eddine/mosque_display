import 'package:flutter/foundation.dart';
import 'prayer_offsets.dart';
import 'iqamah_delays.dart';

/// Immutable model representing all local, persisted TV settings.
@immutable
class MosqueSettings {
  final int selectedWilayaCode;
  final int? selectedCommuneCode;
  final String? selectedCommuneName;
  final PrayerOffsets offsets;
  final IqamahDelays iqamahDelays;
  final int blackoutDurationMinutes;
  final bool blackoutDimMode;
  final int hijriOffsetDays;
  final String mosqueName;
  final String marqueeText;
  final String pinCode;
  final String islamicFont;
  final String tickerCategory;

  const MosqueSettings({
    this.selectedWilayaCode = 16,
    this.selectedCommuneCode,
    this.selectedCommuneName,
    this.offsets = const PrayerOffsets(),
    this.iqamahDelays = const IqamahDelays(),
    this.blackoutDurationMinutes = 20,
    this.blackoutDimMode = false,
    this.hijriOffsetDays = 0,
    this.mosqueName = 'مسجد الفتح',
    this.marqueeText =
        'قال رسول الله ﷺ: مَن بنى للهِ مسجدًا بنى اللهُ له مِثلَه في الجنَّة',
    this.pinCode = '0000',
    this.islamicFont = 'amiriQuran',
    this.tickerCategory = 'all',
  })  : assert(selectedWilayaCode >= 1 && selectedWilayaCode <= 58,
            'Wilaya code must be between 1 and 58'),
        assert(blackoutDurationMinutes >= 5 && blackoutDurationMinutes <= 45,
            'Blackout duration must be 5-45 minutes'),
        assert(hijriOffsetDays >= -2 && hijriOffsetDays <= 2,
            'Hijri offset must be between -2 and +2 days'),
        assert(pinCode.length == 4, 'PIN code must be exactly 4 digits');

  /// Validates entered 4-digit PIN against active settings PIN.
  bool verifyPin(String enteredPin) => enteredPin == pinCode;

  /// True if admin has changed the PIN from factory default '0000'.
  bool get isCustomPinConfigured => pinCode != '0000';

  MosqueSettings copyWith({
    int? selectedWilayaCode,
    int? selectedCommuneCode,
    String? selectedCommuneName,
    bool clearCommune = false,
    PrayerOffsets? offsets,
    IqamahDelays? iqamahDelays,
    int? blackoutDurationMinutes,
    bool? blackoutDimMode,
    int? hijriOffsetDays,
    String? mosqueName,
    String? marqueeText,
    String? pinCode,
    String? islamicFont,
    String? tickerCategory,
  }) {
    return MosqueSettings(
      selectedWilayaCode: selectedWilayaCode ?? this.selectedWilayaCode,
      selectedCommuneCode: clearCommune
          ? null
          : (selectedCommuneCode ?? this.selectedCommuneCode),
      selectedCommuneName: clearCommune
          ? null
          : (selectedCommuneName ?? this.selectedCommuneName),
      offsets: offsets ?? this.offsets,
      iqamahDelays: iqamahDelays ?? this.iqamahDelays,
      blackoutDurationMinutes:
          blackoutDurationMinutes ?? this.blackoutDurationMinutes,
      blackoutDimMode: blackoutDimMode ?? this.blackoutDimMode,
      hijriOffsetDays: hijriOffsetDays ?? this.hijriOffsetDays,
      mosqueName: mosqueName ?? this.mosqueName,
      marqueeText: marqueeText ?? this.marqueeText,
      pinCode: pinCode ?? this.pinCode,
      islamicFont: islamicFont ?? this.islamicFont,
      tickerCategory: tickerCategory ?? this.tickerCategory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedWilayaCode': selectedWilayaCode,
      'selectedCommuneCode': selectedCommuneCode,
      'selectedCommuneName': selectedCommuneName,
      'offsets': offsets.toJson(),
      'iqamahDelays': iqamahDelays.toJson(),
      'blackoutDurationMinutes': blackoutDurationMinutes,
      'blackoutDimMode': blackoutDimMode,
      'hijriOffsetDays': hijriOffsetDays,
      'mosqueName': mosqueName,
      'marqueeText': marqueeText,
      'pinCode': pinCode,
      'islamicFont': islamicFont,
      'tickerCategory': tickerCategory,
    };
  }

  factory MosqueSettings.fromJson(Map<String, dynamic> json) {
    return MosqueSettings(
      selectedWilayaCode: ((json['selectedWilayaCode'] as num?)?.toInt() ?? 16)
          .clamp(1, 58),
      selectedCommuneCode: (json['selectedCommuneCode'] as num?)?.toInt(),
      selectedCommuneName: json['selectedCommuneName'] as String?,
      offsets: json['offsets'] != null
          ? PrayerOffsets.fromJson(json['offsets'] as Map<String, dynamic>)
          : const PrayerOffsets(),
      iqamahDelays: json['iqamahDelays'] != null
          ? IqamahDelays.fromJson(json['iqamahDelays'] as Map<String, dynamic>)
          : const IqamahDelays(),
      blackoutDurationMinutes:
          ((json['blackoutDurationMinutes'] as num?)?.toInt() ?? 20)
              .clamp(5, 45),
      blackoutDimMode: (json['blackoutDimMode'] as bool?) ?? false,
      hijriOffsetDays:
          ((json['hijriOffsetDays'] as num?)?.toInt() ?? 0).clamp(-2, 2),
      mosqueName: (json['mosqueName'] as String?)?.trim().isNotEmpty == true
          ? (json['mosqueName'] as String).trim()
          : 'مسجد الفتح',
      marqueeText: (json['marqueeText'] as String?)?.trim().isNotEmpty == true
          ? (json['marqueeText'] as String).trim()
          : 'قال رسول الله ﷺ: مَن بنى للهِ مسجدًا بنى اللهُ له مِثلَه في الجنَّة',
      pinCode: (json['pinCode'] as String?)?.length == 4
          ? (json['pinCode'] as String)
          : '0000',
      islamicFont: (json['islamicFont'] as String?) ?? 'amiriQuran',
      tickerCategory: (json['tickerCategory'] as String?) ?? 'all',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MosqueSettings &&
          runtimeType == other.runtimeType &&
          selectedWilayaCode == other.selectedWilayaCode &&
          selectedCommuneCode == other.selectedCommuneCode &&
          selectedCommuneName == other.selectedCommuneName &&
          offsets == other.offsets &&
          iqamahDelays == other.iqamahDelays &&
          blackoutDurationMinutes == other.blackoutDurationMinutes &&
          blackoutDimMode == other.blackoutDimMode &&
          hijriOffsetDays == other.hijriOffsetDays &&
          mosqueName == other.mosqueName &&
          marqueeText == other.marqueeText &&
          pinCode == other.pinCode &&
          islamicFont == other.islamicFont &&
          tickerCategory == other.tickerCategory;

  @override
  int get hashCode => Object.hash(
        selectedWilayaCode,
        selectedCommuneCode,
        selectedCommuneName,
        offsets,
        iqamahDelays,
        blackoutDurationMinutes,
        blackoutDimMode,
        hijriOffsetDays,
        mosqueName,
        marqueeText,
        pinCode,
        islamicFont,
        tickerCategory,
      );

  @override
  String toString() =>
      'MosqueSettings(wilaya: $selectedWilayaCode, commune: $selectedCommuneCode ("$selectedCommuneName"), blackout: ${blackoutDurationMinutes}m, dim: $blackoutDimMode, hijriOffset: $hijriOffsetDays, mosque: "$mosqueName", pin: "$pinCode")';
}
