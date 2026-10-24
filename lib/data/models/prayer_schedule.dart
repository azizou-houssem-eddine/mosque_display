import 'package:adhan/adhan.dart' as adhan_lib;
import 'package:flutter/foundation.dart';
import 'prayer_offsets.dart';

/// Enumeration of all 6 timetable checkpoints (5 obligatory prayers + Sunrise).
enum Prayer {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha;

  /// True if this prayer is an obligatory congregational prayer (all except Sunrise).
  bool get isSalat => this != Prayer.sunrise;

  /// Arabic localized title.
  String get nameAr {
    switch (this) {
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

  /// French localized title.
  String get nameFr {
    switch (this) {
      case Prayer.fajr:
        return 'Fajr';
      case Prayer.sunrise:
        return 'Chourouk';
      case Prayer.dhuhr:
        return 'Dhuhr';
      case Prayer.asr:
        return 'Asr';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isha';
    }
  }
}

/// Immutable schedule representing the 6 prayer and solar times for a given day.
@immutable
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

  /// Retrieves the DateTime for the specified [prayer].
  DateTime getTime(Prayer prayer) {
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

  /// Official Algerian Imsak time: exactly 10 minutes before Fajr Adhan.
  DateTime get imsak => fajr.subtract(const Duration(minutes: 10));

  /// Official Algerian Iftar time: coincident with Maghrib Adhan.
  DateTime get iftar => maghrib;

  /// Official Algerian Eid Prayer time: 30 minutes after Sunrise (Duha).
  DateTime get eidPrayer => sunrise.add(const Duration(minutes: 30));

  /// Formatted Imsak string "HH:mm".
  String get imsakFormatted =>
      '${imsak.hour.toString().padLeft(2, '0')}:${imsak.minute.toString().padLeft(2, '0')}';

  /// Formatted Iftar string "HH:mm".
  String get iftarFormatted =>
      '${iftar.hour.toString().padLeft(2, '0')}:${iftar.minute.toString().padLeft(2, '0')}';

  /// Formatted Eid Prayer string "HH:mm".
  String get eidPrayerFormatted =>
      '${eidPrayer.hour.toString().padLeft(2, '0')}:${eidPrayer.minute.toString().padLeft(2, '0')}';

  /// Applies communal calibration offsets (±15 min) to each prayer time.
  PrayerSchedule applyOffsets(PrayerOffsets offsets) {
    return PrayerSchedule(
      fajr: fajr.add(Duration(minutes: offsets.fajr)),
      sunrise: sunrise.add(Duration(minutes: offsets.sunrise)),
      dhuhr: dhuhr.add(Duration(minutes: offsets.dhuhr)),
      asr: asr.add(Duration(minutes: offsets.asr)),
      maghrib: maghrib.add(Duration(minutes: offsets.maghrib)),
      isha: isha.add(Duration(minutes: offsets.isha)),
    );
  }

  /// Determines the upcoming prayer relative to [now].
  ///
  /// If [now] is after Isha, returns [Prayer.fajr] (which falls on the next calendar day).
  Prayer getNextPrayer(DateTime now) {
    if (now.isBefore(fajr)) return Prayer.fajr;
    if (now.isBefore(sunrise)) return Prayer.sunrise;
    if (now.isBefore(dhuhr)) return Prayer.dhuhr;
    if (now.isBefore(asr)) return Prayer.asr;
    if (now.isBefore(maghrib)) return Prayer.maghrib;
    if (now.isBefore(isha)) return Prayer.isha;
    return Prayer.fajr; // Next day's Fajr
  }

  /// Determines the current prayer window whose time has entered, or null if before Fajr.
  Prayer? getCurrentPrayer(DateTime now) {
    if (now.isBefore(fajr)) return null;
    if (now.isBefore(sunrise)) return Prayer.fajr;
    if (now.isBefore(dhuhr)) return Prayer.sunrise;
    if (now.isBefore(asr)) return Prayer.dhuhr;
    if (now.isBefore(maghrib)) return Prayer.asr;
    if (now.isBefore(isha)) return Prayer.maghrib;
    return Prayer.isha;
  }

  /// Calculates the time remaining to the next prayer.
  Duration getTimeRemainingToNextPrayer(DateTime now) {
    final next = getNextPrayer(now);
    final targetTime = getTime(next);
    if (targetTime.isAfter(now)) {
      return targetTime.difference(now);
    } else {
      // If next is Fajr tomorrow, targetTime is today's Fajr + 24 hours
      final tomorrowFajr = targetTime.add(const Duration(days: 1));
      return tomorrowFajr.difference(now);
    }
  }

  /// Constructs a [PrayerSchedule] from a 6-element list of 'HH:mm' strings for [date].
  factory PrayerSchedule.fromTimetableList({
    required DateTime date,
    required List<dynamic> times,
  }) {
    assert(times.length == 6, 'Timetable list must contain exactly 6 strings');

    DateTime parseTime(String hhMm) {
      final parts = hhMm.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    return PrayerSchedule(
      fajr: parseTime(times[0].toString()),
      sunrise: parseTime(times[1].toString()),
      dhuhr: parseTime(times[2].toString()),
      asr: parseTime(times[3].toString()),
      maghrib: parseTime(times[4].toString()),
      isha: parseTime(times[5].toString()),
    );
  }

  /// Alias for [fromTimetableList] with string typed list.
  factory PrayerSchedule.fromTimeStrings({
    required DateTime date,
    required List<String> times,
  }) {
    return PrayerSchedule.fromTimetableList(date: date, times: times);
  }

  /// Factory creating [PrayerSchedule] directly from adhan package's [PrayerTimes].
  factory PrayerSchedule.fromAdhan(
    adhan_lib.PrayerTimes rawTimes,
    DateTime date, {
    Duration targetTimeZoneOffset = const Duration(hours: 1),
  }) {
    DateTime normalize(DateTime dt) {
      return DateTime(
        date.year,
        date.month,
        date.day,
        dt.hour,
        dt.minute,
        dt.second,
      );
    }

    return PrayerSchedule(
      fajr: normalize(rawTimes.fajr),
      sunrise: normalize(rawTimes.sunrise),
      dhuhr: normalize(rawTimes.dhuhr),
      asr: normalize(rawTimes.asr),
      maghrib: normalize(rawTimes.maghrib),
      isha: normalize(rawTimes.isha),
    );
  }

  /// Serializes to a JSON map with ISO-8601 strings.
  Map<String, dynamic> toJson() {
    return {
      'fajr': fajr.toIso8601String(),
      'sunrise': sunrise.toIso8601String(),
      'dhuhr': dhuhr.toIso8601String(),
      'asr': asr.toIso8601String(),
      'maghrib': maghrib.toIso8601String(),
      'isha': isha.toIso8601String(),
    };
  }

  /// Deserializes from a JSON map with ISO-8601 strings.
  factory PrayerSchedule.fromJson(Map<String, dynamic> json) {
    return PrayerSchedule(
      fajr: DateTime.parse(json['fajr'] as String),
      sunrise: DateTime.parse(json['sunrise'] as String),
      dhuhr: DateTime.parse(json['dhuhr'] as String),
      asr: DateTime.parse(json['asr'] as String),
      maghrib: DateTime.parse(json['maghrib'] as String),
      isha: DateTime.parse(json['isha'] as String),
    );
  }

  /// Creates a copy with optionally modified times.
  PrayerSchedule copyWith({
    DateTime? fajr,
    DateTime? sunrise,
    DateTime? dhuhr,
    DateTime? asr,
    DateTime? maghrib,
    DateTime? isha,
  }) {
    return PrayerSchedule(
      fajr: fajr ?? this.fajr,
      sunrise: sunrise ?? this.sunrise,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerSchedule &&
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
      'PrayerSchedule(fajr: $fajr, sunrise: $sunrise, dhuhr: $dhuhr, asr: $asr, maghrib: $maghrib, isha: $isha)';
}
