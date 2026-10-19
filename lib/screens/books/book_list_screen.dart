import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/breakpoints.dart';
import '../../core/reference_data.dart';
import '../../models/book.dart';
import '../../models/book_query.dart';
import '../../state/book_list_notifier.dart';
import '../../state/load_status.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/entity_card_list.dart';
import '../../widgets/entity_table.dart';
import '../../widgets/filters/book_filters.dart';
import '../../widgets/pagination.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFromUrl();
      if (context.read<BookListNotifier>().status == LoadStatus.idle) {
        context.read<BookListNotifier>().load();
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
    final queryFromUrl = BookQuery.fromUri(state.uri);
    final notifier = context.read<BookListNotifier>();
    if (notifier.query != queryFromUrl) {
      notifier.applyQuery(queryFromUrl);
    }
  }

  void _applyQuery(BookQuery newQuery) {
    context.read<BookListNotifier>().applyQuery(newQuery);
    final uri = Uri(
      path: '/books',
      queryParameters: newQuery.toQueryParameters(),
    );
    final qs = uri.query;
    context.go(qs.isEmpty ? '/books' : '/books?$qs');
  }

  void _confirmDeleteSelected() async {
    final notifier = context.read<BookListNotifier>();
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

  void _confirmSoftDelete(Book book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить книгу?'),
        content: Text('«${book.title}» будет помечена как удалённая.'),
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
      await context.read<BookListNotifier>().softDelete(book.id);
    }
  }

  void _confirmHardDelete(Book book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить навсегда?'),
        content: Text('«${book.title}» будет стёрта полностью.'),
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
      await context.read<BookListNotifier>().hardDelete(book.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BookListNotifier>();
    final screenSize = screenSizeOf(context);

    return AppScaffold(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Книги'),
          actions: [
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
              child: BookFilters(
                query: notifier.query,
                onQueryChanged: _applyQuery,
              ),
            ),
            Expanded(child: _buildBody(notifier, screenSize)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BookListNotifier notifier, ScreenSize screenSize) {
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

  Widget _buildList(BookListNotifier notifier, ScreenSize screenSize) {
        final allColumns = <TableColumnSpec<Book>>[
      TableColumnSpec(
        label: 'Название',
        sortField: 'title',
        build: (b) => MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go('/books/${b.id}'),
            child: Text(
              b.title,
              style: TextStyle(
                decoration: b.isDeleted ? TextDecoration.lineThrough : null,
                color: b.isDeleted ? Colors.grey : null,
              ),
            ),
          ),
        ),
      ),
      TableColumnSpec(
        label: 'ISBN',
        build: (b) => Text(b.isbn, style: const TextStyle(fontSize: 12)),
      ),
      TableColumnSpec(
        label: 'Год',
        sortField: 'year',
        numeric: true,
        build: (b) => Text('${b.year}'),
      ),
      TableColumnSpec(
        label: 'Страниц',
        sortField: 'pages',
        numeric: true,
        build: (b) => Text('${b.pages}'),
      ),
      TableColumnSpec(
        label: 'Жанр',
        build: (b) => Text(b.genreIds.map(genreName).join(', ')),
      ),
      TableColumnSpec(
        label: 'Издательство',
        build: (b) => Text(publisherName(b.publisherId)),
      ),
      TableColumnSpec(
        label: 'Экз.',
        numeric: true,
        build: (b) => Text('${b.copiesAvailable}/${b.copiesTotal}'),
      ),
    ];
    
    final columns = screenSize == ScreenSize.expanded
        ? allColumns
        : allColumns
            .where((c) => const {'Название', 'Год', 'Страниц'}.contains(c.label))
            .toList();

    List<Widget> buildActions(Book b) {
      if (b.isDeleted) {
        return [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Восстановить',
            onPressed: () => context.read<BookListNotifier>().restore(b.id),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Удалить навсегда',
            onPressed: () => _confirmHardDelete(b),
            color: Theme.of(context).colorScheme.error,
          ),
        ];
      }
      return [
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'Подробнее',
          onPressed: () => context.go('/books/${b.id}'),
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: 'Удалить',
          onPressed: () => _confirmSoftDelete(b),
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
                    final b = notifier.result.items[index];
                    return EntityCardItem<Book>(
                      item: b,
                      id: b.id,
                      title: b.title,
                      subtitle: b.isbn,
                      selectable: true,
                      selected: notifier.selected.contains(b.id),
                      onToggleSelect: () => notifier.toggleSelection(b.id),
                      onTap: () => context.go('/books/${b.id}'),
                      fields: [
                        Text('Год: ${b.year}, ${b.pages} стр.'),
                        Text(publisherName(b.publisherId)),
                        Text('Экз.: ${b.copiesAvailable}/${b.copiesTotal}'),
                      ],
                      actions: buildActions(b),
                    );
                  },
                )
              : EntityTable<Book>(
                  columns: columns,
                  items: notifier.result.items,
                  idOf: (b) => b.id,
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