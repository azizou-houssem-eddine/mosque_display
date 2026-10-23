import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/islamic_supplication.dart';

/// Repository for authentic Islamic supplications, Du'as, and Hadiths.
class SupplicationsRepository {
  static List<IslamicSupplication>? _cachedSupplications;

  /// Loads and caches the full collection of Islamic supplications.
  static Future<List<IslamicSupplication>> getAll() async {
    if (_cachedSupplications != null) {
      return _cachedSupplications!;
    }

    try {
      final jsonStr = await rootBundle
          .loadString('assets/data/islamic_supplications.json');
      final list = json.decode(jsonStr) as List<dynamic>;
      _cachedSupplications = list
          .map((item) =>
              IslamicSupplication.fromJson(item as Map<String, dynamic>))
          .toList();
      return _cachedSupplications!;
    } catch (e) {
      // Fallback if bundle load fails
      return defaultItems;
    }
  }

  /// Returns items filtered by category key.
  static Future<List<IslamicSupplication>> getByCategory(
      String category) async {
    final all = await getAll();
    if (category == 'all' || category.isEmpty) return all;
    return all.where((s) => s.category == category).toList();
  }

  /// Returns formatted strings for ticker cycling.
  static Future<List<String>> getTickerItems({String category = 'all'}) async {
    final items = await getByCategory(category);
    if (items.isEmpty) {
      return defaultItems.map((e) => e.tickerFormatted).toList();
    }
    return items.map((e) => e.tickerFormatted).toList();
  }

  /// Default baseline supplications for offline/testing fallback.
  static const List<IslamicSupplication> defaultItems = [
    IslamicSupplication(
      id: 'quran_01',
      category: 'quranic_dua',
      categoryAr: 'أدعية قرآنية مباركة',
      text: '﴿رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ﴾',
      source: 'سورة البقرة: 201',
      virtue: 'أجمع دعاء لخيري الدنيا والآخرة',
    ),
    IslamicSupplication(
      id: 'prophetic_01',
      category: 'prophetic_dua',
      categoryAr: 'جوامع الدعاء النبوي الشريف',
      text: '«اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ»',
      source: 'رواه أبو داود',
      virtue: 'سؤال العافية التامة في الدين والدنيا',
    ),
    IslamicSupplication(
      id: 'masjid_01',
      category: 'masjid_dua',
      categoryAr: 'أدعية المسجد والأذان',
      text: '«اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ»',
      source: 'صحيح مسلم',
      virtue: 'دعاء دخول المسجد',
    ),
    IslamicSupplication(
      id: 'friday_01',
      category: 'friday_dua',
      categoryAr: 'أدعية وفضائل يوم الجمعة',
      text: '«اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ، اللَّهُمَّ اغْفِرْ لَنَا فِي هَذِهِ السَّاعَةِ الْمُبَارَكَةِ، وَاشْرَحْ صُدُورَنَا وَيَسِّرْ أُمُورَنَا وَتَقَبَّلْ دُعَاءَنَا»',
      source: 'مأثور يوم الجمعة',
      virtue: 'دعاء ساعة الإجابة يوم الجمعة',
    ),
    IslamicSupplication(
      id: 'eid_01',
      category: 'eid_dua',
      categoryAr: 'تكبيرات وأدعية العيدين',
      text: '«اللهُ أَكْبَرُ، اللهُ أَكْبَرُ، اللهُ أَكْبَرُ، لَا إِلَهَ إِلَّا اللهُ، اللهُ أَكْبَرُ، اللهُ أَكْبَرُ، وَلِلَّهِ الْحَمْدُ»',
      source: 'سنة التكبير في العيدين',
      virtue: 'تكبيرات العيد المبارك',
    ),
    IslamicSupplication(
      id: 'ramadan_01',
      category: 'ramadan_dua',
      categoryAr: 'أدعية شهر رمضان المبارك',
      text: '«اللَّهُمَّ إِنَّكَ عَفُوٌّ كَرِيمٌ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي»',
      source: 'رواه الترمذي وصححه',
      virtue: 'دعاء ليلة القدر والعشر الأواخر',
    ),
    IslamicSupplication(
      id: 'hadith_01',
      category: 'hadith_fadl',
      categoryAr: 'فضائل الصلاة والمساجد',
      text: 'قال رسول الله ﷺ: «مَنْ بَنَى لِلَّهِ مَسْجِدًا بَنَى اللَّهُ لَهُ مِثْلَهُ فِي الجَنَّةِ»',
      source: 'متفق عليه',
      virtue: 'البشارة لعمّار بيوت الله',
    ),
  ];
}
