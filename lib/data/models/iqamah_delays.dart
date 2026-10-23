import 'package:flutter/foundation.dart';
import 'prayer_schedule.dart';

/// Configurable waiting duration (in minutes) between Adhan and Iqamah for each prayer.
@immutable
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
  })  : assert(fajr >= 5 && fajr <= 60,
            'Fajr Iqamah delay must be between 5 and 60 minutes'),
        assert(dhuhr >= 5 && dhuhr <= 45,
            'Dhuhr Iqamah delay must be between 5 and 45 minutes'),
        assert(asr >= 5 && asr <= 45,
            'Asr Iqamah delay must be between 5 and 45 minutes'),
        assert(maghrib >= 3 && maghrib <= 30,
            'Maghrib Iqamah delay must be between 3 and 30 minutes'),
        assert(isha >= 5 && isha <= 45,
            'Isha Iqamah delay must be between 5 and 45 minutes');

  /// Returns the configured Iqamah delay for the given [prayer].
  int getDelayFor(Prayer prayer) {
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
      fajr: fajr != null ? fajr.clamp(5, 60) : this.fajr,
      dhuhr: dhuhr != null ? dhuhr.clamp(5, 45) : this.dhuhr,
      asr: asr != null ? asr.clamp(5, 45) : this.asr,
      maghrib: maghrib != null ? maghrib.clamp(3, 30) : this.maghrib,
      isha: isha != null ? isha.clamp(5, 45) : this.isha,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fajr': fajr,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
    };
  }

  factory IqamahDelays.fromJson(Map<String, dynamic> json) {
    return IqamahDelays(
      fajr: ((json['fajr'] as num?)?.toInt() ?? 20).clamp(5, 60),
      dhuhr: ((json['dhuhr'] as num?)?.toInt() ?? 15).clamp(5, 45),
      asr: ((json['asr'] as num?)?.toInt() ?? 15).clamp(5, 45),
      maghrib: ((json['maghrib'] as num?)?.toInt() ?? 5).clamp(3, 30),
      isha: ((json['isha'] as num?)?.toInt() ?? 15).clamp(5, 45),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IqamahDelays &&
          runtimeType == other.runtimeType &&
          fajr == other.fajr &&
          dhuhr == other.dhuhr &&
          asr == other.asr &&
          maghrib == other.maghrib &&
          isha == other.isha;

  @override
  int get hashCode => Object.hash(fajr, dhuhr, asr, maghrib, isha);

  @override
  String toString() =>
      'IqamahDelays(fajr: $fajr, dhuhr: $dhuhr, asr: $asr, maghrib: $maghrib, isha: $isha)';
}
