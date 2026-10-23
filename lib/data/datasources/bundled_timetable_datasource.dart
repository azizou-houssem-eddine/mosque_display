import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/prayer_schedule.dart';

abstract class IBundledTimetableDataSource {
  Future<PrayerSchedule?> getPrayerSchedule(int wilayaCode, DateTime date);
  Future<void> preload();
}

class BundledTimetableDataSource implements IBundledTimetableDataSource {
  static const String assetPath = 'assets/data/algerian_prayer_times.json';

  final AssetBundle? _bundle;
  Map<String, dynamic>? _cache;

  BundledTimetableDataSource({
    AssetBundle? bundle,
    Map<String, dynamic>? initialCache,
  })  : _bundle = bundle,
        _cache = initialCache;

  @override
  Future<void> preload() async {
    if (_cache != null) return;
    final bundle = _bundle ?? rootBundle;
    final jsonString = await bundle.loadString(assetPath);
    _cache = json.decode(jsonString) as Map<String, dynamic>;
  }

  @override
  Future<PrayerSchedule?> getPrayerSchedule(int wilayaCode, DateTime date) async {
    if (_cache == null) {
      await preload();
    }

    final wilayaKey = wilayaCode.toString();
    final wilayaData = _cache?[wilayaKey] as Map<String, dynamic>?;
    if (wilayaData == null) return null;

    final monthStr = date.month.toString().padLeft(2, '0');
    final dayStr = date.day.toString().padLeft(2, '0');
    final dateKey = '$monthStr-$dayStr';

    final timesList = wilayaData[dateKey] as List<dynamic>?;
    if (timesList == null || timesList.length < 6) return null;

    final stringTimes = timesList.map((e) => e.toString()).toList();
    return PrayerSchedule.fromTimeStrings(date: date, times: stringTimes);
  }
}
