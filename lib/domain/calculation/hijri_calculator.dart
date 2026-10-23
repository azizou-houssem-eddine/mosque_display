import 'package:hijri/hijri_calendar.dart';

/// Immutable model representing a calculated Hijri date.
class HijriDate {
  final int year;
  final int month;
  final int day;
  final String dayNameAr;
  final String monthNameAr;
  final int offsetDays;

  const HijriDate({
    required this.year,
    required this.month,
    required this.day,
    required this.dayNameAr,
    required this.monthNameAr,
    this.offsetDays = 0,
  });

  /// Formatted date in Arabic (e.g. "25 ربيع الثاني 1448 هـ")
  String get formattedAr => '$day $monthNameAr $year هـ';

  /// Full formatted date with weekday (e.g. "الثلاثاء، 25 ربيع الثاني 1448 هـ")
  String get fullFormattedAr => '$dayNameAr، $day $monthNameAr $year هـ';

  /// Formatted with Eastern Arabic digits (e.g. "٢٥ ربيع الثاني ١٤٤٨ هـ")
  String get formattedEasternAr {
    final dayStr = HijriCalculator.toEasternArabicDigits(day.toString());
    final yearStr = HijriCalculator.toEasternArabicDigits(year.toString());
    return '$dayStr $monthNameAr $yearStr هـ';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HijriDate &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day &&
          offsetDays == other.offsetDays;

  @override
  int get hashCode => Object.hash(year, month, day, offsetDays);

  @override
  String toString() => fullFormattedAr;
}

/// Hijri calendar engine with Algerian moonsighting calibration.
class HijriCalculator {
  static const List<String> arabicMonths = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الثاني',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  static const List<String> arabicWeekdays = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  /// Calculates Hijri date for a given Gregorian date, applying moonsighting offset (±1-2 days).
  static HijriDate calculate({
    required DateTime gregorianDate,
    int offsetDays = 0,
  }) {
    // Clamp offset between -2 and +2 days as per Algerian regulations
    final clampedOffset = offsetDays.clamp(-2, 2);

    // Apply moonsighting adjustment on Gregorian calendar timeline
    final adjustedDate = gregorianDate.add(Duration(days: clampedOffset));

    // Convert via Umm al-Qura algorithm
    final hCalendar = HijriCalendar.fromDate(adjustedDate);

    final monthIndex = (hCalendar.hMonth - 1).clamp(0, 11);
    final monthName = arabicMonths[monthIndex];

    // Civil weekday remains anchored to the active Gregorian day
    final weekdayIndex = (gregorianDate.weekday - 1).clamp(0, 6);
    final weekdayName = arabicWeekdays[weekdayIndex];

    return HijriDate(
      year: hCalendar.hYear,
      month: hCalendar.hMonth,
      day: hCalendar.hDay,
      dayNameAr: weekdayName,
      monthNameAr: monthName,
      offsetDays: clampedOffset,
    );
  }

  /// Converts Western numerals ('0'..'9') to Eastern Arabic numerals ('٠'..'٩').
  static String toEasternArabicDigits(String input) {
    const westernDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const easternDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    String output = input;
    for (int i = 0; i < 10; i++) {
      output = output.replaceAll(westernDigits[i], easternDigits[i]);
    }
    return output;
  }
}
