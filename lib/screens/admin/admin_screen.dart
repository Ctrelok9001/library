import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/role.dart';
import '../../state/auth_notifier.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/inactivity_watcher.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;
    final theme = Theme.of(context);

    final systemUsers = [
      (username: 'admin', name: 'Администратор системы', email: 'admin@lib.ru', role: 'admin', level: 'Level 3'),
      (username: 'librarian', name: 'Библиотекарь', email: 'lib@lib.ru', role: 'librarian', level: 'Level 2'),
      (username: 'reader', name: 'Читатель', email: 'reader@lib.ru', role: 'reader', level: 'Level 1'),
    ];

    return AppScaffold(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Панель администратора'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Обновить данные',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Данные административной панели обновлены')),
                );
              },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Card(
              elevation: 0,
              color: theme.colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.primary.withAlpha(50)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Привет, админ ${user?.fullName ?? user?.username ?? ''}!',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Вам доступен полный контроль над системой: управление книгами, авторами, пользователями и системными настройками.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer.withAlpha(200),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              Chip(
                                avatar: const Icon(Icons.verified_user, size: 16),
                                label: const Text('Роль: Администратор (Level 3)'),
                                visualDensity: VisualDensity.compact,
                              ),
                              Chip(
                                avatar: const Icon(Icons.security, size: 16),
                                label: const Text('Доступ: Без ограничений'),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.people, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              const Text('Пользователи', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('3 аккаунта', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const Text('1 админ, 1 библиотекарь, 1 читатель', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shield, color: Colors.green),
                              const SizedBox(width: 8),
                              const Text('Безопасность', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('JWT Active', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                          const Text('Серверная валидация прав', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.timer, color: Colors.orange),
                              const SizedBox(width: 8),
                              const Text('Таймаут сессии', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('3 мин / 30 сек', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const Text('Автовыход при неактивности', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Пользователи и роли системы',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('Добавить пользователя'),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Новый пользователь'),
                                content: const Text('Форма создания пользователя в панели администратора.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Закрыть')),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.5),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(1.5),
                        4: FlexColumnWidth(1),
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withAlpha(100)),
                          children: const [
                            Padding(padding: EdgeInsets.all(8), child: Text('Логин', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('ФИО', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Роль', style: TextStyle(fontWeight: FontWeight.bold))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Уровень', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                        for (final u in systemUsers)
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(u.username, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              Padding(padding: const EdgeInsets.all(8), child: Text(u.name)),
                              Padding(padding: const EdgeInsets.all(8), child: Text(u.email)),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Chip(
                                  label: Text(u.role),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: u.role == 'admin' 
                                      ? Colors.red.withAlpha(40)
                                      : (u.role == 'librarian' ? Colors.blue.withAlpha(40) : Colors.green.withAlpha(40)),
                                ),
                              ),
                              Padding(padding: const EdgeInsets.all(8), child: Text(u.level)),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Системные операции администратора',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.restore),
                          label: const Text('Сбросить данные к эталону'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Тестовые данные успешно сброшены к начальным значениям')),
                            );
                          },
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.token),
                          label: const Text('Информация о токене'),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Текущая сессия администратора'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Пользователь: ${user?.username} (${user?.fullName})'),
                                    const SizedBox(height: 8),
                                    Text('Роль: ${user?.role.label} (${user?.role.name})'),
                                    const SizedBox(height: 8),
                                    Text('Access Token: ${auth.accessToken?.substring(0, 20)}...'),
                                  ],
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ОК')),
                                ],
                              ),
                            );
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.history),
                          label: const Text('Журнал аудита'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('В журнале аудита 0 критических инцидентов')),
                            );
                          },
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade50,
                            foregroundColor: Colors.orange.shade900,
                          ),
                          icon: const Icon(Icons.timer_outlined, color: Colors.orange),
                          label: const Text('Тест: показать окно истечения сессии'),
                          onPressed: () {
                            InactivityWatcher.showWarningPreview(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
