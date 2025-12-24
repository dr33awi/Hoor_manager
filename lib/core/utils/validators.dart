import '../constants/app_strings.dart';
import '../extensions/string_extensions.dart';

/// التحقق من صحة المدخلات
class Validators {
  Validators._();

  /// التحقق من الحقل المطلوب
  static String? required(String? value) {
    if (value.isNullOrEmpty) {
      return AppStrings.required;
    }
    return null;
  }

  /// التحقق من البريد الإلكتروني
  static String? email(String? value) {
    if (value.isNullOrEmpty) {
      return AppStrings.required;
    }
    if (!value!.isValidEmail) {
      return AppStrings.invalidEmail;
    }
    return null;
  }

  /// التحقق من كلمة المرور
  static String? password(String? value) {
    if (value.isNullOrEmpty) {
      return AppStrings.required;
    }
    if (!value!.isValidPassword) {
      return AppStrings.invalidPassword;
    }
    return null;
  }

  /// التحقق من تطابق كلمات المرور
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value.isNullOrEmpty) {
        return AppStrings.required;
      }
      if (value != password) {
        return AppStrings.passwordMismatch;
      }
      return null;
    };
  }

  /// التحقق من رقم الهاتف
  static String? phone(String? value) {
    if (value.isNullOrEmpty) {
      return AppStrings.required;
    }
    if (!value!.isValidPhone) {
      return AppStrings.invalidPhone;
    }
    return null;
  }

  /// التحقق من رقم الهاتف (اختياري)
  static String? phoneOptional(String? value) {
    if (value.isNullOrEmpty) {
      return null;
    }
    if (!value!.isValidPhone) {
      return AppStrings.invalidPhone;
    }
    return null;
  }

  /// التحقق من الاسم
  static String? name(String? value) {
    if (value.isNullOrEmpty) {
      return AppStrings.required;
    }
    if (value!.length < 2) {
      return 'الاسم يجب أن يكون حرفين على الأقل';
    }
    return null;
  }

  /// التحقق من الرقم الموجب
  static String? positiveNumber(String? value) {
    if (value.isNullOrEmpty) {
      return AppStrings.required;
    }
    final number = double.tryParse(value!);
    if (number == null) {
      return 'يرجى إدخال رقم صحيح';
    }
    if (number <= 0) {
      return 'يجب أن يكون الرقم أكبر من صفر';
    }
    return null;
  }

  /// التحقق من الرقم غير السالب
  static String? nonNegativeNumber(String? value) {
    if (value.isNullOrEmpty) {
      return AppStrings.required;
    }
    final number = double.tryParse(value!);
    if (number == null) {
      return 'يرجى إدخال رقم صحيح';
    }
    if (number < 0) {
      return 'لا يمكن أن يكون الرقم سالباً';
    }
    return null;
  }

  /// التحقق من عدد صحيح موجب
  static String? positiveInteger(String? value) {
    if (value.isNullOrEmpty) {
      return AppStrings.required;
    }
    final number = int.tryParse(value!);
    if (number == null) {
      return 'يرجى إدخال رقم صحيح';
    }
    if (number <= 0) {
      return 'يجب أن يكون الرقم أكبر من صفر';
    }
    return null;
  }

  /// دمج عدة validators
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }
}
