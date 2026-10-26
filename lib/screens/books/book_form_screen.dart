import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exceptions.dart';
import '../../core/ref_cache.dart';      
import '../../core/validators.dart';
import '../../models/book.dart';
import '../../repositories/book_repository.dart';
import '../../widgets/entity_form.dart';
import '../../widgets/multi_select_field.dart';
import 'package:go_router/go_router.dart';

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
  
  Map<String, String> _serverErrors = {};
  bool _saving = false;

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
    context.read<RefCache>().invalidate();
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _serverErrors = {};
      _saving = true;
    });

    try {
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
      
      if (!mounted) return;
      context.go('/books');
      
    } on ValidationException catch (e) {
      setState(() => _serverErrors = e.errors);
      _formKey.currentState?.validate(); 
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
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

    final refCache = context.read<RefCache>();

    return FutureBuilder(
      future: Future.wait([
        refCache.authors(),
        refCache.genres(),
        refCache.publishers(),
      ]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final authors = snap.data![0] as List<dynamic>;
        final genres = snap.data![1] as List<dynamic>;
        final publishers = snap.data![2] as List<dynamic>;

        return Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Scaffold(
            appBar: AppBar(title: Text(widget.isEditing ? 'Редактирование книги' : 'Новаяا книга')),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildField(
                      'Название',
                      _title,
                      V.combine([V.required(), V.length(min: 2, max: 300)]),
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      'ISBN',
                      _isbn,
                      (v) {
                        final local = V.combine([V.required(), V.isbn()])(v);
                        if (local != null) return local;
                        return _serverErrors['isbn']; 
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      'Год издания',
                      _year,
                      V.integer(min: 1450, max: 2100, label: 'Год'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      'Страниц',
                      _pages,
                      V.positive(label: 'Страниц'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _publisherId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Издательство', border: OutlineInputBorder()),
                      items: [
                        for (final p in publishers)
                          if (!(p as dynamic).isDeleted)
                            DropdownMenuItem(value: (p as dynamic).id as int, child: Text((p as dynamic).name as String)),
                      ],
                      onChanged: (v) => setState(() => _publisherId = v),
                      validator: (v) => v == null ? 'Выберите издательство' : null,
                    ),
                    const SizedBox(height: 16),
                    MultiSelectField<int>(
                      initialValue: _authorIds,
                      label: 'Авторы',
                      options: authors.where((a) => !(a as dynamic).isDeleted).map((a) => (a as dynamic).id as int).toList(),
                      labelOf: (id) => authors.firstWhere((a) => (a as dynamic).id == id).fullName,
                      validator: (v) => (v == null || v.isEmpty) ? 'Выберите хотя бы одного автора' : null,
                      chipBuilder: (id, selected, toggle) => FilterChip(
                        label: Text(authors.firstWhere((a) => (a as dynamic).id == id).fullName),
                        selected: selected,
                        onSelected: (_) => toggle(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    MultiSelectField<int>(
                      initialValue: _genreIds,
                      label: 'Жанры',
                      options: genres.where((g) => !(g as dynamic).isDeleted).map((g) => (g as dynamic).id as int).toList(),
                      labelOf: (id) => genres.firstWhere((g) => (g as dynamic).id == id).name,
                      validator: (v) => (v == null || v.isEmpty) ? 'Выберите хотя бы один жанр' : null,
                      chipBuilder: (id, selected, toggle) => FilterChip(
                        label: Text(genres.firstWhere((g) => (g as dynamic).id == id).name),
                        selected: selected,
                        onSelected: (_) => toggle(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      'Экземпляров всего',
                      _copiesTotal,
                      V.positive(label: 'Количество'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      'Экземпляров в наличии',
                      _copiesAvailable,
                      V.integer(min: 0, label: 'Количество'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _submit,
                        child: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(widget.isEditing ? 'Сохранить' : 'Создать'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildField(String label, TextEditingController controller, String? Function(String?) validator, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: validator,
    );
        }
}