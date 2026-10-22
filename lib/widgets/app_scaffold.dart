import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/breakpoints.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  static const _destinations = [
    (icon: Icons.menu_book, label: 'Книги', path: '/books'),
    (icon: Icons.person, label: 'Авторы', path: '/authors'),
    (icon: Icons.category, label: 'Жанры', path: '/genres'),
    (icon: Icons.business, label: 'Издательства', path: '/publishers'),
    (icon: Icons.people, label: 'Читатели', path: '/readers'),
  ];

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/authors')) return 1;
    if (path.startsWith('/genres')) return 2;
    if (path.startsWith('/publishers')) return 3;
    if (path.startsWith('/readers')) return 4;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    context.go(_destinations[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final size = screenSizeOf(context);
    final selectedIndex = _selectedIndex(context);

    if (size == ScreenSize.compact) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) => _onDestinationSelected(context, i),
          destinations: [
            for (final d in _destinations)
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
            onDestinationSelected: (i) => _onDestinationSelected(context, i),
            extended: size == ScreenSize.expanded,
            labelType: size == ScreenSize.expanded
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
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