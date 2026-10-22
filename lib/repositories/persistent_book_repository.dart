import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';
import '../models/page_result.dart';
import '../models/book_query.dart';
import 'book_repository.dart';
import 'in_memory_book_repository.dart';

class PersistentBookRepository implements BookRepository {
  static const _key = 'books_v1';
  final SharedPreferences _prefs;
  final List<Book> _books = [];
  int _nextId = 1;

  PersistentBookRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _books.addAll(seedBooks);
      _nextId = seedBooks.length + 1;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _books.addAll(list.map((e) => Book.fromJson(e as Map<String, dynamic>)));
      _nextId = _books.isEmpty ? 1 : _books.map((b) => b.id).reduce((a, b) => a > b ? a : b) + 1;
    } catch (_) {
      _books.addAll(seedBooks);
      _nextId = seedBooks.length + 1;
      _prefs.setString('books_migrated_at', DateTime.now().toIso8601String());
      _persist();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, jsonEncode(_books.map((b) => b.toJson()).toList()));
  }

  @override
  Future<List<Book>> findAll() async => List.of(_books);

  @override
  bool isbnExists(String isbn, {int? exceptId}) {
    final needle = isbn.trim().toLowerCase();
    return _books.any((b) =>
        b.id != exceptId &&
        !b.isDeleted &&
        b.isbn.trim().toLowerCase() == needle);
  }

  @override
  Future<PageResult<Book>> find(BookQuery q) async {
    await Future.delayed(const Duration(milliseconds: 150));

    var rows = _books.where((b) => q.includeDeleted || !b.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final n = q.search.trim().toLowerCase();
      rows = rows
          .where((b) =>
              b.title.toLowerCase().contains(n) ||
              b.isbn.toLowerCase().contains(n))
          .toList();
    }
    if (q.genreId != null) {
      rows = rows.where((b) => b.genreIds.contains(q.genreId)).toList();
    }
    if (q.publisherId != null) {
      rows = rows.where((b) => b.publisherId == q.publisherId).toList();
    }
    if (q.yearFrom != null) {
      rows = rows.where((b) => b.year >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((b) => b.year <= q.yearTo!).toList();
    }

    rows.sort((a, b) {
      final r = switch (q.sortField) {
        'year' => a.year.compareTo(b.year),
        'pages' => a.pages.compareTo(b.pages),
        _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      };
      return q.sortAscending ? r : -r;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Book>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Book?> findById(int id) async {
    try {
      return _books.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Book> create(Book book) async {
    final created = Book(
      id: _nextId++,
      title: book.title,
      isbn: book.isbn,
      year: book.year,
      pages: book.pages,
      publisherId: book.publisherId,
      authorIds: List.from(book.authorIds),
      genreIds: List.from(book.genreIds),
      copiesTotal: book.copiesTotal,
      copiesAvailable: book.copiesAvailable,
    );
    _books.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Book> update(Book book) async {
    final i = _books.indexWhere((b) => b.id == book.id);
    if (i == -1) throw StateError('Книга ${book.id} не найдена');
    _books[i] = book;
    await _persist();
    return book;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _books.removeWhere((b) => b.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    _books[i] = _books[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _books.indexWhere((b) => b.id == id && !b.isDeleted);
      if (i != -1) {
        _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    if (count > 0) await _persist();
    return count;
  }
}