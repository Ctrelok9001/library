import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/breakpoints.dart';
import '../state/auth_notifier.dart';
import '../models/role.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final size = screenSizeOf(context);
    final user = auth.user;

    final destinations = [
      (
        icon: Icons.menu_book,
        label: 'Книги',
        path: '/books',
        role: Role.reader
      ),
      (
        icon: Icons.person,
        label: 'Авторы',
        path: '/authors',
        role: Role.reader
      ),
      (
        icon: Icons.category,
        label: 'Жанры',
        path: '/genres',
        role: Role.librarian
      ),
      (
        icon: Icons.business,
        label: 'Издательства',
        path: '/publishers',
        role: Role.librarian
      ),
      (
        icon: Icons.people,
        label: 'Читатели',
        path: '/readers',
        role: Role.librarian
      ),
      (
        icon: Icons.admin_panel_settings,
        label: 'Админка',
        path: '/admin',
        role: Role.admin
      ),
    ].where((d) => auth.hasRole(d.role)).toList();

    if (destinations.isEmpty) {
      return Scaffold(body: child);
    }

    final path = GoRouterState.of(context).uri.path;
    int selectedIndex = destinations.indexWhere((d) => path.startsWith(d.path));
    if (selectedIndex == -1) selectedIndex = 0;

    void onDestinationSelected(int index) {
      if (index >= 0 && index < destinations.length) {
        context.go(destinations[index].path);
      }
    }

    if (size == ScreenSize.compact) {
      return Scaffold(
        appBar: AppBar(
          title: Text(user != null
              ? '${user.fullName} (${user.role.label})'
              : 'Библиотека'),
          actions: [
            if (auth.isAuthenticated)
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Выйти',
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) context.go('/login');
                },
              ),
          ],
        ),
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            for (final d in destinations)
              NavigationDestination(icon: Icon(d.icon), label: d.label),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            extended: size == ScreenSize.expanded,
            labelType: size == ScreenSize.expanded
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: auth.isAuthenticated && user != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.fullName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: user.role == Role.admin
                                ? Colors.red.withAlpha(40)
                                : (user.role == Role.librarian
                                    ? Colors.blue.withAlpha(40)
                                    : Colors.green.withAlpha(40)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.role.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: user.role == Role.admin
                                  ? Colors.red[800]
                                  : (user.role == Role.librarian
                                      ? Colors.blue[800]
                                      : Colors.green[800]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.logout, size: 16),
                          label: const Text('Выйти',
                              style: TextStyle(fontSize: 12)),
                          onPressed: () async {
                            await auth.logout();
                            if (context.mounted) context.go('/login');
                          },
                        ),
                      ],
                    ),
                  )
                : null,
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.icon,
                      color: Theme.of(context).colorScheme.primary),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
