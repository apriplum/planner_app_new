import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../data/services/notification_service.dart';
import '../data/services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Оформление',
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Системная тема'),
                subtitle: const Text(
                  'Тема зависит от настроек устройства',
                ),
                value: ThemeMode.system,
                groupValue: settings.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    settings.setThemeMode(value);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Светлая тема'),
                value: ThemeMode.light,
                groupValue: settings.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    settings.setThemeMode(value);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Тёмная тема'),
                value: ThemeMode.dark,
                groupValue: settings.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    settings.setThemeMode(value);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'Уведомления',
            children: [
              SwitchListTile(
                title: const Text('Локальные напоминания'),
                subtitle: const Text(
                  'Напоминания работают без подключения к интернету',
                ),
                value: settings.notificationsEnabled,
                onChanged: (value) async {
                  await settings.setNotificationsEnabled(value);

                  if (value) {
                    await NotificationService.instance.requestPermission();
                  }
                },
              ),
              SwitchListTile(
                title: const Text('Звук уведомлений'),
                subtitle: const Text(
                  'Звук включается только для важных напоминаний',
                ),
                value: settings.soundEnabled,
                onChanged: (value) => settings.setSoundEnabled(value),
              ),
              SwitchListTile(
                title: const Text('Вибрация'),
                subtitle: const Text(
                  'Тактильный отклик при выполнении действий',
                ),
                value: settings.vibrationEnabled,
                onChanged: (value) => settings.setVibrationEnabled(value),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'Язык и время',
            children: [
              ListTile(
                title: const Text('Язык интерфейса'),
                subtitle: Text(
                  settings.language == 'ru' ? 'Русский' : 'English',
                ),
                trailing: DropdownButton<String>(
                  value: settings.language,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: 'ru',
                      child: Text('Русский'),
                    ),
                    DropdownMenuItem(
                      value: 'en',
                      child: Text('English'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      settings.setLanguage(value);
                    }
                  },
                ),
              ),
              ListTile(
                title: const Text('Формат времени'),
                subtitle: Text(
                  settings.timeFormat == '24h'
                      ? '24-часовой формат'
                      : '12-часовой формат',
                ),
                trailing: DropdownButton<String>(
                  value: settings.timeFormat,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: '24h',
                      child: Text('24 часа'),
                    ),
                    DropdownMenuItem(
                      value: '12h',
                      child: Text('12 часов'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      settings.setTimeFormat(value);
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'Данные и конфиденциальность',
            children: [
              const ListTile(
                leading: Icon(Icons.shield_outlined),
                title: Text('Локальное хранение'),
                subtitle: Text(
                  'Задачи, события и привычки хранятся только на устройстве.',
                ),
              ),
              ListTile(
                leading: Icon(Icons.notifications_outlined),
                title: Text('Локальные уведомления'),
                subtitle: Text(
                  'Содержимое напоминаний не передаётся внешним сервисам.',
                ),
              ),
              ListTile(
                leading: Icon(Icons.delete_sweep_outlined),
                title: const Text('Сбросить настройки'),
                subtitle: const Text(
                  'Вернуть настройки по умолчанию. Данные не удаляются.',
                ),
                onTap: () => _confirmReset(context, settings),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: 'О приложении',
            children: [
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Планировщик'),
                subtitle: Text(
                  'Локальный планировщик задач, событий и привычек.',
                ),
              ),
              const ListTile(
                leading: Icon(Icons.storage_outlined),
                title: Text('Режим работы'),
                subtitle: Text(
                  'Офлайн-first. Облачная синхронизация отключена.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    SettingsService settings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Сбросить настройки?'),
        content: const Text(
          'Настройки будут возвращены к значениям по умолчанию. '
          'Задачи, события и привычки останутся.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await settings.resetSettings();
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}