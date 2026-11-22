import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF5E6AD2);
  static const highPriority = Color(0xFFFF6B6B);
  static const mediumPriority = Color(0xFFFFA500);
  static const lowPriority = Color(0xFF4ECDC4);
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSecondary = Color(0xFFF8F9FA);
  static const darkBackground = Color(0xFF121212);
  static const darkSecondary = Color(0xFF1E1E1E);
}

class AppLimits {
  static const int titleMaxLength = 100;
  static const int descriptionMaxLength = 500;
  static const int categoryMaxLength = 50;
  static const int unitMaxLength = 20;
  static const int locationMaxLength = 100;
  static const int maxDurationMinutes = 480;
  static const int trashRetentionDays = 30;
}

class AppStrings {
  static const enterTaskTitle = 'Введите название задачи';
  static const enterEventTitle = 'Введите название события';
  static const enterHabitTitle = 'Введите название привычки';
  static const recordNotFound = 'Запись не найдена';
  static const taskNotFound = 'Задача не найдена';
  static const eventNotFound = 'Событие не найдено';
  static const habitNotFound = 'Привычка не найдена';
  static const noSearchResults = 'По вашему запросу ничего не найдено';
  static const recordDeleted = 'Запись удалена';
  static const recordRestored = 'Запись восстановлена';
  static const expired = 'Срок хранения записи истёк. Восстановление невозможно';
  static const needInternet = 'Для входа через Яндекс требуется интернет-соединение. Проверьте подключение и попробуйте снова';
  static const sessionExpired = 'Сессия устарела. Пожалуйста, войдите снова';
}