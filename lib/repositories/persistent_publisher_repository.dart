import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../models/page_result.dart';
import '../models/book.dart';
import 'publisher_repository.dart';
import 'book_repository.dart';
import '../core/reference_data.dart' as ref;

class PersistentPublisherRepository implements PublisherRepository {
  static const _key = 'publishers_v1';
  final SharedPreferences _prefs;
  final BookRepository _bookRepo;
  final List<Publisher> _items = [];
  int _nextId = 1;

  PersistentPublisherRepository(this._prefs, this._bookRepo) {
    _restore();
  }

  static List<Publisher> get _seed => ref.publishers
      .map((p) => Publisher(id: p.id, name: p.name, country: ''))
      .toList();

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _items.addAll(_seed);
      _nextId = _seed.length + 1;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _items
          .addAll(list.map((e) => Publisher.fromJson(e as Map<String, dynamic>)));
      _nextId = _items.isEmpty
          ? 1
          : _items.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
    } catch (_) {
      _items.addAll(_seed);
      _nextId = _seed.length + 1;
      _persist();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
        _key, jsonEncode(_items.map((p) => p.toJson()).toList()));
  }

  @override
  Future<List<Publisher>> findAll() async => List.of(_items);

  @override
  Future<int> countBooksUsing(int publisherId) async {
    final books = await _bookRepo.findAll();
    return books.where((b) => b.publisherId == publisherId && !b.isDeleted).length;
  }

  @override
  Future<PageResult<Publisher>> find(PublisherQuery q) async {
    await Future.delayed(const Duration(milliseconds: 150));

    var rows = _items.where((p) => q.includeDeleted || !p.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final n = q.search.trim().toLowerCase();
      rows = rows
          .where((p) =>
              p.name.toLowerCase().contains(n) ||
              p.country.toLowerCase().contains(n))
          .toList();
    }
    if (q.country != null) {
      rows = rows.where((p) => p.country == q.country).toList();
    }

    rows.sort((a, b) {
      final r = switch (q.sortField) {
        'country' => a.country.compareTo(b.country),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? r : -r;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Publisher>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Publisher?> findById(int id) async {
    try {
      return _items.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Publisher> create(Publisher p) async {
    final created = Publisher(
      id: _nextId++,
      name: p.name,
      country: p.country,
    );
    _items.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Publisher> update(Publisher p) async {
    final i = _items.indexWhere((x) => x.id == p.id);
    if (i == -1) throw StateError('Издательство ${p.id} не найдено');
    _items[i] = p;
    await _persist();
    return p;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Издательство $id не найдено');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((p) => p.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Издательство $id не найдено');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((p) => p.id == id && !p.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    if (count > 0) await _persist();
    return count;
  }
}