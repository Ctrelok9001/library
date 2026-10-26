import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import 'author_repository.dart';
import 'in_memory_author_repository.dart';

class PersistentAuthorRepository implements AuthorRepository {
  static const _key = 'authors_v1';
  final SharedPreferences _prefs;
  final List<Author> _authors = [];
  int _nextId = 1;

  PersistentAuthorRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _authors.addAll(seedAuthors);
      _nextId = seedAuthors.length + 1;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _authors
          .addAll(list.map((e) => Author.fromJson(e as Map<String, dynamic>)));
      _nextId = _authors.isEmpty
          ? 1
          : _authors.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1;
    } catch (_) {
      _authors.addAll(seedAuthors);
      _nextId = seedAuthors.length + 1;
      _persist();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
        _key, jsonEncode(_authors.map((a) => a.toJson()).toList()));
  }

  @override
  Future<List<Author>> findAll() async => List.of(_authors);

  @override
  Future<PageResult<Author>> find(AuthorQuery q, {CancelToken? cancelToken}) async {
    await Future.delayed(const Duration(milliseconds: 150));

    var rows = _authors.where((a) => q.includeDeleted || !a.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final n = q.search.trim().toLowerCase();
      rows = rows
          .where((a) =>
              a.lastName.toLowerCase().contains(n) ||
              a.country.toLowerCase().contains(n))
          .toList();
    }
    if (q.country != null) {
      rows = rows.where((a) => a.country == q.country).toList();
    }
    if (q.birthYearFrom != null) {
      rows = rows.where((a) => a.birthYear >= q.birthYearFrom!).toList();
    }
    if (q.birthYearTo != null) {
      rows = rows.where((a) => a.birthYear <= q.birthYearTo!).toList();
    }

    rows.sort((a, b) {
      final r = switch (q.sortField) {
        'country' => a.country.compareTo(b.country),
        'birthYear' => a.birthYear.compareTo(b.birthYear),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? r : -r;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Author>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Author?> findById(int id) async {
    try {
      return _authors.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Author> create(Author author) async {
    final created = Author(
      id: _nextId++,
      firstName: author.firstName,
      lastName: author.lastName,
      country: author.country,
      birthYear: author.birthYear,
      deathYear: author.deathYear,
    );
    _authors.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Author> update(Author author) async {
    final i = _authors.indexWhere((a) => a.id == author.id);
    if (i == -1) throw StateError('Автор ${author.id} не найден');
    _authors[i] = author;
    await _persist();
    return author;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Автор $id не найден');
    _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _authors.removeWhere((a) => a.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Автор $id не найден');
    _authors[i] = _authors[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _authors.indexWhere((a) => a.id == id && !a.isDeleted);
      if (i != -1) {
        _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    if (count > 0) await _persist();
    return count;
  }
}