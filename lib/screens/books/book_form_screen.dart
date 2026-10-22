import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../models/book.dart';
import '../../repositories/author_repository.dart';
import '../../repositories/book_repository.dart';
import '../../repositories/genre_repository.dart';
import '../../repositories/publisher_repository.dart';
import '../../widgets/entity_form.dart';
import '../../widgets/multi_select_field.dart';

class BookFormScreen extends StatefulWidget {
  final int? id;
  const BookFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _title = TextEditingController();
  final _isbn = TextEditingController();
  final _year = TextEditingController();
  final _pages = TextEditingController();
  final _copiesTotal = TextEditingController();
  final _copiesAvailable = TextEditingController();

  int? _publisherId;
  List<int> _authorIds = [];
  List<int> _genreIds = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.id == null) {
      setState(() => _loading = false);
      return;
    }
    final book = await context.read<BookRepository>().findById(widget.id!);
    if (!mounted) return;
    if (book == null) {
      setState(() => _error = 'Книга не найдена');
      return;
    }
    setState(() {
      _title.text = book.title;
      _isbn.text = book.isbn;
      _year.text = book.year.toString();
      _pages.text = book.pages.toString();
      _copiesTotal.text = book.copiesTotal.toString();
      _copiesAvailable.text = book.copiesAvailable.toString();
      _publisherId = book.publisherId;
      _authorIds = List.from(book.authorIds);
      _genreIds = List.from(book.genreIds);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _isbn.dispose();
    _year.dispose();
    _pages.dispose();
    _copiesTotal.dispose();
    _copiesAvailable.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final repo = context.read<BookRepository>();
    final book = Book(
      id: widget.id ?? 0,
      title: _title.text.trim(),
      isbn: _isbn.text.trim(),
      year: int.parse(_year.text.trim()),
      pages: int.parse(_pages.text.trim()),
      publisherId: _publisherId!,
      authorIds: List.from(_authorIds),
      genreIds: List.from(_genreIds),
      copiesTotal: int.parse(_copiesTotal.text.trim()),
      copiesAvailable: int.parse(_copiesAvailable.text.trim()),
    );
    if (widget.isEditing) {
      await repo.update(book);
    } else {
      await repo.create(book);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookRepo = context.read<BookRepository>();
    final authorRepo = context.read<AuthorRepository>();
    final genreRepo = context.read<GenreRepository>();
    final pubRepo = context.read<PublisherRepository>();

    if (_loading || _error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.isEditing ? 'Редактирование книги' : 'Новая книга')),
        body: Center(
          child: _error != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Назад')),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      );
    }

    return FutureBuilder(
      future: Future.wait([
        authorRepo.findAll(),
        genreRepo.findAll(),
        pubRepo.findAll(),
      ]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final authors = snap.data![0] as List;
        final genres = snap.data![1] as List;
        final publishers = snap.data![2] as List;

        return EntityForm(
          title: widget.isEditing ? 'Редактирование книги' : 'Новая книга',
          isEditing: widget.isEditing,
          onSubmit: _submit,
          fields: [
            EntityFormField(
              name: 'title',
              build: (_) => TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Название', border: OutlineInputBorder()),
                validator: V.combine([V.required(), V.length(min: 2, max: 300)]),
              ),
            ),
            EntityFormField(
              name: 'isbn',
              build: (_) => TextFormField(
                controller: _isbn,
                decoration: const InputDecoration(labelText: 'ISBN', border: OutlineInputBorder()),
                validator: V.combine([
                  V.required(),
                  V.isbn(),
                  V.uniqueIsbn(bookRepo, exceptId: widget.id),
                ]),
              ),
            ),
            EntityFormField(
              name: 'year',
              build: (_) => TextFormField(
                controller: _year,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Год издания', border: OutlineInputBorder()),
                validator: V.integer(min: 1450, max: 2100, label: 'Год'),
              ),
            ),
            EntityFormField(
              name: 'pages',
              build: (_) => TextFormField(
                controller: _pages,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Страниц', border: OutlineInputBorder()),
                validator: V.positive(label: 'Страниц'),
              ),
            ),
            EntityFormField(
              name: 'publisher',
              build: (_) => DropdownButtonFormField<int>(
                value: _publisherId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Издательство', border: OutlineInputBorder()),
                items: [
                  for (final p in publishers)
                    if (!(p as dynamic).isDeleted)
                      DropdownMenuItem(value: p.id as int, child: Text(p.name as String)),
                ],
                onChanged: (v) => setState(() => _publisherId = v),
                validator: (v) => v == null ? 'Выберите издательство' : null,
              ),
            ),
            EntityFormField(
              name: 'authors',
              build: (_) => MultiSelectField<int>(
                initialValue: _authorIds,
                label: 'Авторы',
                options: authors.where((a) => !(a as dynamic).isDeleted).cast<dynamic>().toList().map((a) => a.id as int).toList(),
                labelOf: (id) => authors.firstWhere((a) => a.id == id).fullName,
                validator: (v) => (v == null || v.isEmpty) ? 'Выберите хотя бы одного автора' : null,
                chipBuilder: (id, selected, toggle) => FilterChip(
                  label: Text(authors.firstWhere((a) => a.id == id).fullName),
                  selected: selected,
                  onSelected: (_) => toggle(),
                ),
              ),
            ),
            EntityFormField(
              name: 'genres',
              build: (_) => MultiSelectField<int>(
                initialValue: _genreIds,
                label: 'Жанры',
                options: genres.where((g) => !(g as dynamic).isDeleted).cast<dynamic>().toList().map((g) => g.id as int).toList(),
                labelOf: (id) => genres.firstWhere((g) => g.id == id).name,
                validator: (v) => (v == null || v.isEmpty) ? 'Выберите хотя бы один жанр' : null,
                chipBuilder: (id, selected, toggle) => FilterChip(
                  label: Text(genres.firstWhere((g) => g.id == id).name),
                  selected: selected,
                  onSelected: (_) => toggle(),
                ),
              ),
            ),
            EntityFormField(
              name: 'copiesTotal',
              build: (_) => TextFormField(
                controller: _copiesTotal,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Экземпляров всего', border: OutlineInputBorder()),
                validator: V.positive(label: 'Количество'),
              ),
            ),
            EntityFormField(
              name: 'copiesAvailable',
              build: (_) => TextFormField(
                controller: _copiesAvailable,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Экземпляров в наличии', border: OutlineInputBorder()),
                validator: V.integer(min: 0, label: 'Количество'),
              ),
            ),
          ],
        );
      },
    );
  }
}