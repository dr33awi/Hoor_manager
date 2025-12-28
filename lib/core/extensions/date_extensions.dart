import 'package:intl/intl.dart';

/// إضافات على DateTime
extension DateTimeExtensions on DateTime {
  // تنسيقات التاريخ
  String get toDateString => DateFormat('yyyy-MM-dd', 'ar').format(this);
  String get toTimeString => DateFormat('HH:mm', 'ar').format(this);
  String get toDateTimeString =>
      DateFormat('yyyy-MM-dd HH:mm', 'ar').format(this);

  // تنسيق الوقت فقط
  String toTime() => DateFormat('hh:mm a', 'ar').format(this);

  // تنسيقات عربية
  String toArabicDate() => DateFormat('d MMMM yyyy', 'ar').format(this);
  String toArabicDateTime() =>
      DateFormat('d MMMM yyyy - HH:mm', 'ar').format(this);
  String get toArabicDayDate =>
      DateFormat('EEEE، d MMMM yyyy', 'ar').format(this);

  // تنسيق مختصر
  String get toShortDate => DateFormat('d/M/yyyy', 'ar').format(this);
  String get toShortDateTime => DateFormat('d/M/yyyy HH:mm', 'ar').format(this);

  // بداية اليوم
  DateTime get startOfDay => DateTime(year, month, day);

  // نهاية اليوم
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  // بداية الشهر
  DateTime get startOfMonth => DateTime(year, month, 1);

  // نهاية الشهر
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);

  // بداية السنة
  DateTime get startOfYear => DateTime(year, 1, 1);

  // نهاية السنة
  DateTime get endOfYear => DateTime(year, 12, 31, 23, 59, 59, 999);

  // هل اليوم
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  // هل أمس
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  // هل غداً
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  // هل هذا الأسبوع
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  // هل هذا الشهر
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  // هل هذه السنة
  bool get isThisYear {
    return year == DateTime.now().year;
  }

  // إضافة أيام
  DateTime addDays(int days) => add(Duration(days: days));

  // طرح أيام
  DateTime subtractDays(int days) => subtract(Duration(days: days));

  // الفرق بالأيام
  int daysDifference(DateTime other) {
    return startOfDay.difference(other.startOfDay).inDays;
  }

  // نص نسبي (اليوم، أمس، ...)
  String get relativeDate {
    if (isToday) return 'اليوم';
    if (isYesterday) return 'أمس';
    if (isTomorrow) return 'غداً';
    if (isThisWeek) return DateFormat('EEEE', 'ar').format(this);
    if (isThisYear) return DateFormat('d MMMM', 'ar').format(this);
    return toArabicDate();
  }

  // نص نسبي كدالة
  String toRelativeDate() {
    if (isToday) return 'اليوم';
    if (isYesterday) return 'أمس';
    if (isTomorrow) return 'غداً';
    if (isThisWeek) return DateFormat('EEEE', 'ar').format(this);
    if (isThisYear) return DateFormat('d MMMM', 'ar').format(this);
    return toArabicDate();
  }
}
