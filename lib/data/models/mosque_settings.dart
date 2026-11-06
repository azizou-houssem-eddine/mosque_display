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
  final bool showFastingTimes;
  final String watchFaceTemplate;
  final String colorTheme;
  final double uiScaleFactor;
  final bool showSeconds;
  final bool showGregorianDate;
  final int adhkarDurationMinutes;
  final bool remoteAdminEnabled;
  final int remoteAdminPort;

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
    this.showFastingTimes = true,
    this.watchFaceTemplate = 'classicAstrolabe',
    this.colorTheme = 'royalEmerald',
    this.uiScaleFactor = 1.0,
    this.showSeconds = true,
    this.showGregorianDate = true,
    this.adhkarDurationMinutes = 7,
    this.remoteAdminEnabled = false,
    this.remoteAdminPort = 8080,
  })  : assert(selectedWilayaCode >= 1 && selectedWilayaCode <= 58,
            'Wilaya code must be between 1 and 58'),
        assert(blackoutDurationMinutes >= 5 && blackoutDurationMinutes <= 45,
            'Blackout duration must be 5-45 minutes'),
        assert(hijriOffsetDays >= -2 && hijriOffsetDays <= 2,
            'Hijri offset must be between -2 and +2 days'),
        assert(pinCode.length == 4, 'PIN code must be exactly 4 digits'),
        assert(adhkarDurationMinutes >= 2 && adhkarDurationMinutes <= 15,
            'Adhkar duration must be between 2 and 15 minutes'),
        assert(remoteAdminPort >= 1024 && remoteAdminPort <= 65535,
            'Remote admin port must be between 1024 and 65535');

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
    bool? showFastingTimes,
    String? watchFaceTemplate,
    String? colorTheme,
    double? uiScaleFactor,
    bool? showSeconds,
    bool? showGregorianDate,
    int? adhkarDurationMinutes,
    bool? remoteAdminEnabled,
    int? remoteAdminPort,
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
      showFastingTimes: showFastingTimes ?? this.showFastingTimes,
      watchFaceTemplate: watchFaceTemplate ?? this.watchFaceTemplate,
      colorTheme: colorTheme ?? this.colorTheme,
      uiScaleFactor: uiScaleFactor ?? this.uiScaleFactor,
      showSeconds: showSeconds ?? this.showSeconds,
      showGregorianDate: showGregorianDate ?? this.showGregorianDate,
      adhkarDurationMinutes:
          adhkarDurationMinutes ?? this.adhkarDurationMinutes,
      remoteAdminEnabled: remoteAdminEnabled ?? this.remoteAdminEnabled,
      remoteAdminPort: remoteAdminPort ?? this.remoteAdminPort,
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
      'showFastingTimes': showFastingTimes,
      'watchFaceTemplate': watchFaceTemplate,
      'colorTheme': colorTheme,
      'uiScaleFactor': uiScaleFactor,
      'showSeconds': showSeconds,
      'showGregorianDate': showGregorianDate,
      'adhkarDurationMinutes': adhkarDurationMinutes,
      'remoteAdminEnabled': remoteAdminEnabled,
      'remoteAdminPort': remoteAdminPort,
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
      showFastingTimes: (json['showFastingTimes'] as bool?) ?? true,
      watchFaceTemplate:
          (json['watchFaceTemplate'] as String?) ?? 'classicAstrolabe',
      colorTheme: (json['colorTheme'] as String?) ?? 'royalEmerald',
      uiScaleFactor:
          ((json['uiScaleFactor'] as num?)?.toDouble() ?? 1.0).clamp(0.75, 1.25),
      showSeconds: (json['showSeconds'] as bool?) ?? true,
      showGregorianDate: (json['showGregorianDate'] as bool?) ?? true,
      adhkarDurationMinutes:
          ((json['adhkarDurationMinutes'] as num?)?.toInt() ?? 7).clamp(2, 15),
      remoteAdminEnabled: (json['remoteAdminEnabled'] as bool?) ?? false,
      remoteAdminPort:
          ((json['remoteAdminPort'] as num?)?.toInt() ?? 8080).clamp(1024, 65535),
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
          tickerCategory == other.tickerCategory &&
          showFastingTimes == other.showFastingTimes &&
          watchFaceTemplate == other.watchFaceTemplate &&
          colorTheme == other.colorTheme &&
          uiScaleFactor == other.uiScaleFactor &&
          showSeconds == other.showSeconds &&
          showGregorianDate == other.showGregorianDate &&
          adhkarDurationMinutes == other.adhkarDurationMinutes &&
          remoteAdminEnabled == other.remoteAdminEnabled &&
          remoteAdminPort == other.remoteAdminPort;

  @override
  int get hashCode => Object.hashAll([
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
        showFastingTimes,
        watchFaceTemplate,
        colorTheme,
        uiScaleFactor,
        showSeconds,
        showGregorianDate,
        adhkarDurationMinutes,
        remoteAdminEnabled,
        remoteAdminPort,
      ]);

  @override
  String toString() =>
      'MosqueSettings(wilaya: $selectedWilayaCode, commune: $selectedCommuneCode ("$selectedCommuneName"), template: $watchFaceTemplate, theme: $colorTheme, scale: $uiScaleFactor, blackout: ${blackoutDurationMinutes}m, dim: $blackoutDimMode, hijriOffset: $hijriOffsetDays, mosque: "$mosqueName", pin: "$pinCode", fasting: $showFastingTimes, gregorian: $showGregorianDate, remoteAdmin: $remoteAdminEnabled:$remoteAdminPort)';
}
