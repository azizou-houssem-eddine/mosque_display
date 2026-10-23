import 'package:flutter/foundation.dart';
import 'prayer_schedule.dart';

/// Communal calibration offsets (±15 minutes) applied per-prayer.
@immutable
class PrayerOffsets {
  static const int minOffsetMinutes = -15;
  static const int maxOffsetMinutes = 15;

  final int fajr;
  final int sunrise;
  final int dhuhr;
  final int asr;
  final int maghrib;
  final int isha;

  const PrayerOffsets({
    this.fajr = 0,
    this.sunrise = 0,
    this.dhuhr = 0,
    this.asr = 0,
    this.maghrib = 0,
    this.isha = 0,
  })  : assert(fajr >= minOffsetMinutes && fajr <= maxOffsetMinutes,
            'Fajr offset out of bounds (-15 to 15)'),
        assert(sunrise >= minOffsetMinutes && sunrise <= maxOffsetMinutes,
            'Sunrise offset out of bounds (-15 to 15)'),
        assert(dhuhr >= minOffsetMinutes && dhuhr <= maxOffsetMinutes,
            'Dhuhr offset out of bounds (-15 to 15)'),
        assert(asr >= minOffsetMinutes && asr <= maxOffsetMinutes,
            'Asr offset out of bounds (-15 to 15)'),
        assert(maghrib >= minOffsetMinutes && maghrib <= maxOffsetMinutes,
            'Maghrib offset out of bounds (-15 to 15)'),
        assert(isha >= minOffsetMinutes && isha <= maxOffsetMinutes,
            'Isha offset out of bounds (-15 to 15)');

  const PrayerOffsets.zero()
      : fajr = 0,
        sunrise = 0,
        dhuhr = 0,
        asr = 0,
        maghrib = 0,
        isha = 0;

  static int clampOffset(int minutes) =>
      minutes.clamp(minOffsetMinutes, maxOffsetMinutes);

  int getOffsetFor(Prayer prayer) {
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

  PrayerOffsets copyWith({
    int? fajr,
    int? sunrise,
    int? dhuhr,
    int? asr,
    int? maghrib,
    int? isha,
  }) {
    return PrayerOffsets(
      fajr: fajr != null ? clampOffset(fajr) : this.fajr,
      sunrise: sunrise != null ? clampOffset(sunrise) : this.sunrise,
      dhuhr: dhuhr != null ? clampOffset(dhuhr) : this.dhuhr,
      asr: asr != null ? clampOffset(asr) : this.asr,
      maghrib: maghrib != null ? clampOffset(maghrib) : this.maghrib,
      isha: isha != null ? clampOffset(isha) : this.isha,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
    };
  }

  factory PrayerOffsets.fromJson(Map<String, dynamic> json) {
    return PrayerOffsets(
      fajr: clampOffset((json['fajr'] as num?)?.toInt() ?? 0),
      sunrise: clampOffset((json['sunrise'] as num?)?.toInt() ?? 0),
      dhuhr: clampOffset((json['dhuhr'] as num?)?.toInt() ?? 0),
      asr: clampOffset((json['asr'] as num?)?.toInt() ?? 0),
      maghrib: clampOffset((json['maghrib'] as num?)?.toInt() ?? 0),
      isha: clampOffset((json['isha'] as num?)?.toInt() ?? 0),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerOffsets &&
          runtimeType == other.runtimeType &&
          fajr == other.fajr &&
          sunrise == other.sunrise &&
          dhuhr == other.dhuhr &&
          asr == other.asr &&
          maghrib == other.maghrib &&
          isha == other.isha;

  @override
  int get hashCode =>
      Object.hash(fajr, sunrise, dhuhr, asr, maghrib, isha);

  @override
  String toString() =>
      'PrayerOffsets(fajr: $fajr, sunrise: $sunrise, dhuhr: $dhuhr, asr: $asr, maghrib: $maghrib, isha: $isha)';
}
