/// إضافات على String
extension StringExtensions on String {
  // التحقق من البريد الإلكتروني
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  // التحقق من رقم الهاتف (يمني أو عام)
  bool get isValidPhone {
    final phoneRegex = RegExp(r'^[0-9]{9,15}$');
    return phoneRegex.hasMatch(replaceAll(RegExp(r'[\s\-\+]'), ''));
  }

  // التحقق من كلمة المرور (6 أحرف على الأقل)
  bool get isValidPassword => length >= 6;

  // تحويل أول حرف لكبير
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  // إزالة المسافات الزائدة
  String get trimAll => replaceAll(RegExp(r'\s+'), ' ').trim();

  // هل النص فارغ أو يحتوي مسافات فقط
  bool get isBlank => trim().isEmpty;
  bool get isNotBlank => !isBlank;

  // تحويل لأرقام عربية
  String get toArabicNumbers {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = this;
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }

  // تحويل لأرقام إنجليزية
  String get toEnglishNumbers {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    String result = this;
    for (int i = 0; i < arabic.length; i++) {
      result = result.replaceAll(arabic[i], english[i]);
    }
    return result;
  }
}

/// إضافات على String?
extension NullableStringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  bool get isNotNullOrEmpty => !isNullOrEmpty;

  String orEmpty() => this ?? '';
  String orDefault(String defaultValue) => isNullOrEmpty ? defaultValue : this!;
}
