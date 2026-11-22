import '../core/constants.dart';

class Validators {
  static String? title(String? value, String emptyMessage) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return emptyMessage;
    if (v.length > AppLimits.titleMaxLength) {
      return 'Название не должно превышать ${AppLimits.titleMaxLength} символов';
    }
    return null;
  }

  static String? description(String? value) {
    final v = value ?? '';
    if (v.length > AppLimits.descriptionMaxLength) {
      return 'Описание не должно превышать ${AppLimits.descriptionMaxLength} символов';
    }
    return null;
  }

  static String? category(String? value) {
    final v = value ?? '';
    if (v.length > AppLimits.categoryMaxLength) {
      return 'Категория не должна превышать ${AppLimits.categoryMaxLength} символов';
    }
    return null;
  }

  static String? location(String? value) {
    final v = value ?? '';
    if (v.length > AppLimits.locationMaxLength) {
      return 'Место не должно превышать ${AppLimits.locationMaxLength} символов';
    }
    return null;
  }

  static String? targetValue(String? value) {
    final n = int.tryParse(value ?? '');
    if (n == null || n <= 0) return 'Укажите положительное значение';
    if (n > 999) return 'Значение не должно превышать 999';
    return null;
  }

  static bool isValidQuery(String query) {
    return query.trim().isNotEmpty;
  }
}