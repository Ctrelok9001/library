import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/breakpoints.dart';
import '../../models/author.dart';
import '../../models/author_query.dart';
import '../../state/author_list_notifier.dart';
import '../../state/load_status.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/entity_card_list.dart';
import '../../widgets/entity_table.dart';
import '../../widgets/filters/author_filters.dart';
import '../../widgets/pagination.dart';

class AuthorListScreen extends StatefulWidget {
  const AuthorListScreen({super.key});

  @override
  State<AuthorListScreen> createState() => _AuthorListScreenState();
}

class _AuthorListScreenState extends State<AuthorListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFromUrl();
      if (context.read<AuthorListNotifier>().status == LoadStatus.idle) {
        context.read<AuthorListNotifier>().load();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFromUrl();
  }

  void _syncFromUrl() {
    final state = GoRouterState.of(context);
    final queryFromUrl = AuthorQuery.fromUri(state.uri);
    final notifier = context.read<AuthorListNotifier>();
    if (notifier.query != queryFromUrl) {
      notifier.applyQuery(queryFromUrl);
    }
  }

  void _applyQuery(AuthorQuery newQuery) {
    context.read<AuthorListNotifier>().applyQuery(newQuery);
    final uri = Uri(
      path: '/authors',
      queryParameters: newQuery.toQueryParameters(),
    );
    final qs = uri.query;
    context.go(qs.isEmpty ? '/authors' : '/authors?$qs');
  }

  void _confirmDeleteSelected() async {
    final notifier = context.read<AuthorListNotifier>();
    final count = notifier.selected.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить выбранные?'),
        content: Text('Будет удалено записей: $count. Продолжить?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final deleted = await notifier.softDeleteSelected();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Удалено: $deleted')),
        );
      }
    }
  }

  void _confirmSoftDelete(Author author) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить автора?'),
        content:
            Text('${author.firstName} ${author.lastName} будет помечен как удалённый.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AuthorListNotifier>().softDelete(author.id);
    }
  }

  void _confirmHardDelete(Author author) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить навсегда?'),
        content: Text('${author.firstName} ${author.lastName} будет стёрт полностью.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AuthorListNotifier>().hardDelete(author.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AuthorListNotifier>();
    final screenSize = screenSizeOf(context);

    // Collect distinct countries for filter
    final countries = notifier.result.items
        .map((a) => a.country)
        .toSet()
        .toList()
      ..sort();

    return AppScaffold(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Авторы'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Новый автор',
              onPressed: () => context.go('/authors/new'),
            ),
            if (notifier.hasSelection) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Выбрано: ${notifier.selected.length}'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.clear_all),
                tooltip: 'Снять выделение',
                onPressed: notifier.clearSelection,
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Удалить выбранные',
                onPressed: _confirmDeleteSelected,
              ),
            ],
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AuthorFilters(
                query: notifier.query,
                onQueryChanged: _applyQuery,
                countries: countries.isNotEmpty
                    ? countries
                    : ['Россия', 'Англия'],
              ),
            ),
            Expanded(child: _buildBody(notifier, screenSize)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AuthorListNotifier notifier, ScreenSize screenSize) {
    switch (notifier.status) {
      case LoadStatus.idle:
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case LoadStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(notifier.error ?? 'Ошибка',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: notifier.load,
                child: const Text('Повторить'),
              ),
            ],
          ),
        );
      case LoadStatus.success:
        if (notifier.result.items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 64),
                SizedBox(height: 16),
                Text('Ничего не найдено'),
              ],
            ),
          );
        }
        return _buildList(notifier, screenSize);
    }
  }

  Widget _buildList(AuthorListNotifier notifier, ScreenSize screenSize) {
    final allColumns = <TableColumnSpec<Author>>[
      TableColumnSpec(
        label: 'Фамилия',
        sortField: 'lastName',
        build: (a) => MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go('/authors/${a.id}'),
            child: Text(
              a.lastName,
              style: TextStyle(
                decoration: a.isDeleted ? TextDecoration.lineThrough : null,
                color: a.isDeleted ? Colors.grey : null,
              ),
            ),
          ),
        ),
      ),
      TableColumnSpec(label: 'Имя', build: (a) => Text(a.firstName)),
      TableColumnSpec(label: 'Страна', sortField: 'country', build: (a) => Text(a.country)),
      TableColumnSpec(
        label: 'Год рожд.',
        sortField: 'birthYear',
        numeric: true,
        build: (a) => Text('${a.birthYear}'),
      ),
      TableColumnSpec(
        label: 'Год см.',
        numeric: true,
        build: (a) => Text(a.deathYear?.toString() ?? '—'),
      ),
    ];

    final columns = screenSize == ScreenSize.expanded
        ? allColumns
        : allColumns
            .where((c) => const {'Фамилия', 'Имя', 'Страна'}.contains(c.label))
            .toList();

    List<Widget> buildActions(Author a) {
      if (a.isDeleted) {
        return [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Восстановить',
            onPressed: () => context.read<AuthorListNotifier>().restore(a.id),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Удалить навсегда',
            onPressed: () => _confirmHardDelete(a),
            color: Theme.of(context).colorScheme.error,
          ),
        ];
      }
      return [
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'Редактировать',
          onPressed: () => context.go('/authors/${a.id}/edit'),
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: 'Удалить',
          onPressed: () => _confirmSoftDelete(a),
        ),
      ];
    }

    return Column(
      children: [
        Expanded(
          child: screenSize == ScreenSize.compact
              ? ListView.builder(
                  itemCount: notifier.result.items.length,
                  itemBuilder: (context, index) {
                    final a = notifier.result.items[index];
                    return EntityCardItem<Author>(
                      item: a,
                      id: a.id,
                      title: '${a.lastName} ${a.firstName}',
                      subtitle: a.country,
                      selectable: true,
                      selected: notifier.selected.contains(a.id),
                      onToggleSelect: () => notifier.toggleSelection(a.id),
                      onTap: () => context.go('/authors/${a.id}'),
                      fields: [
                        Text(
                          '${a.birthYear}${a.deathYear != null ? ' – ${a.deathYear}' : ''}',
                        ),
                      ],
                      actions: buildActions(a),
                    );
                  },
                )
              : EntityTable<Author>(
                  columns: columns,
                  items: notifier.result.items,
                  idOf: (a) => a.id,
                  selected: notifier.selected,
                  onToggleSelect: notifier.toggleSelection,
                  sortField: notifier.query.sortField,
                  sortAscending: notifier.query.sortAscending,
                  onSort: (field) {
                    final q = notifier.query;
                    _applyQuery(q.copyWith(
                      sortField: field,
                      sortAscending:
                          field == q.sortField ? !q.sortAscending : true,
                    ));
                  },
                  actions: buildActions,
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Pagination(
            currentPage: notifier.result.page,
            totalPages: notifier.result.totalPages,
            totalItems: notifier.result.total,
            pageSize: notifier.query.size,
            onPageChanged: (p) => _applyQuery(
              notifier.query.withPage(p),
            ),
            onPageSizeChanged: (s) => _applyQuery(
              notifier.query.copyWith(size: s, page: 1),
            ),
          ),
        ),
      ],
    );
  }
}