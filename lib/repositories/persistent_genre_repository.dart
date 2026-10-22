import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/page_result.dart';
import 'genre_repository.dart';
import '../core/reference_data.dart' as ref;

class PersistentGenreRepository implements GenreRepository {
  static const _key = 'genres_v1';
  final SharedPreferences _prefs;
  final List<Genre> _genres = [];
  int _nextId = 1;

  PersistentGenreRepository(this._prefs) {
    _restore();
  }

  static List<Genre> get _seed => ref.genres
      .map((g) => Genre(id: g.id, name: g.name, description: ''))
      .toList();

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _genres.addAll(_seed);
      _nextId = _seed.length + 1;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _genres
          .addAll(list.map((e) => Genre.fromJson(e as Map<String, dynamic>)));
      _nextId = _genres.isEmpty
          ? 1
          : _genres.map((g) => g.id).reduce((a, b) => a > b ? a : b) + 1;
    } catch (_) {
      _genres.addAll(_seed);
      _nextId = _seed.length + 1;
      _persist();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
        _key, jsonEncode(_genres.map((g) => g.toJson()).toList()));
  }

  @override
  Future<List<Genre>> findAll() async => List.of(_genres);

  @override
  Future<PageResult<Genre>> find(GenreQuery q) async {
    await Future.delayed(const Duration(milliseconds: 150));

    var rows = _genres.where((g) => q.includeDeleted || !g.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final n = q.search.trim().toLowerCase();
      rows = rows
          .where((g) =>
              g.name.toLowerCase().contains(n) ||
              g.description.toLowerCase().contains(n))
          .toList();
    }

    rows.sort((a, b) {
      final r = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return q.sortAscending ? r : -r;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Genre>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Genre?> findById(int id) async {
    try {
      return _genres.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Genre> create(Genre g) async {
    final created = Genre(
      id: _nextId++,
      name: g.name,
      description: g.description,
    );
    _genres.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Genre> update(Genre g) async {
    final i = _genres.indexWhere((x) => x.id == g.id);
    if (i == -1) throw StateError('Жанр ${g.id} не найден');
    _genres[i] = g;
    await _persist();
    return g;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _genres.indexWhere((g) => g.id == id);
    if (i == -1) throw StateError('Жанр $id не найден');
    _genres[i] = _genres[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _genres.removeWhere((g) => g.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _genres.indexWhere((g) => g.id == id);
    if (i == -1) throw StateError('Жанр $id не найден');
    _genres[i] = _genres[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _genres.indexWhere((g) => g.id == id && !g.isDeleted);
      if (i != -1) {
        _genres[i] = _genres[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    if (count > 0) await _persist();
    return count;
  }
}