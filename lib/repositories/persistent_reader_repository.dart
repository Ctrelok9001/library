import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reader.dart';
import '../models/library_card.dart';
import '../models/reader_query.dart';
import '../models/page_result.dart';
import 'reader_repository.dart';

final List<Reader> seedReaders = [
  Reader(id: 1, firstName: 'Иван', lastName: 'Петров', email: 'petrov@mail.ru', phone: '+79001112233', card: LibraryCard(number: 'Б-00001', issuedAt: DateTime(2023, 1, 15))),
  Reader(id: 2, firstName: 'Мария', lastName: 'Сидорова', email: 'sidorova@mail.ru', phone: '+79002223344', card: LibraryCard(number: 'Б-00002', issuedAt: DateTime(2023, 3, 10))),
  Reader(id: 3, firstName: 'Алексей', lastName: 'Иванов', email: 'ivanov@mail.ru', phone: '+79003334455', card: LibraryCard(number: 'Б-00003', issuedAt: DateTime(2022, 11, 5))),
  Reader(id: 4, firstName: 'Елена', lastName: 'Кузнецова', email: 'kuznetsova@mail.ru', phone: '+79004445566', card: LibraryCard(number: 'Б-00004', issuedAt: DateTime(2024, 2, 20))),
  Reader(id: 5, firstName: 'Дмитрий', lastName: 'Смирнов', email: 'smirnov@mail.ru', phone: '+79005556677', card: LibraryCard(number: 'Б-00005', issuedAt: DateTime(2023, 7, 1))),
];

class PersistentReaderRepository implements ReaderRepository {
  static const _key = 'readers_v1';
  final SharedPreferences _prefs;
  final List<Reader> _readers = [];
  int _nextId = 1;

  PersistentReaderRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _readers.addAll(seedReaders);
      _nextId = seedReaders.length + 1;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _readers
          .addAll(list.map((e) => Reader.fromJson(e as Map<String, dynamic>)));
      _nextId = _readers.isEmpty
          ? 1
          : _readers.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
    } catch (_) {
      _readers.addAll(seedReaders);
      _nextId = seedReaders.length + 1;
      _persist();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
        _key, jsonEncode(_readers.map((r) => r.toJson()).toList()));
  }

  @override
  Future<List<Reader>> findAll() async => List.of(_readers);

  @override
  bool emailExists(String email, {int? exceptId}) {
    final needle = email.trim().toLowerCase();
    return _readers.any((r) =>
        r.id != exceptId &&
        !r.isDeleted &&
        r.email.trim().toLowerCase() == needle);
  }

  @override
  Future<PageResult<Reader>> find(ReaderQuery q, {CancelToken? cancelToken}) async {
    await Future.delayed(const Duration(milliseconds: 150));

    var rows = _readers.where((r) => q.includeDeleted || !r.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final n = q.search.trim().toLowerCase();
      rows = rows
          .where((r) =>
              r.lastName.toLowerCase().contains(n) ||
              r.email.toLowerCase().contains(n) ||
              r.phone.toLowerCase().contains(n))
          .toList();
    }

    rows.sort((a, b) {
      final r = switch (q.sortField) {
        'firstName' => a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()),
        'email' => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? r : -r;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Reader>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Reader?> findById(int id) async {
    try {
      return _readers.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Reader> create(Reader r) async {
    final created = Reader(
      id: _nextId++,
      firstName: r.firstName,
      lastName: r.lastName,
      email: r.email,
      phone: r.phone,
      card: r.card,
    );
    _readers.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Reader> update(Reader r) async {
    final i = _readers.indexWhere((x) => x.id == r.id);
    if (i == -1) throw StateError('Читатель ${r.id} не найден');
    _readers[i] = r;
    await _persist();
    return r;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _readers.indexWhere((r) => r.id == id);
    if (i == -1) throw StateError('Читатель $id не найден');
    _readers[i] = _readers[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _readers.removeWhere((r) => r.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _readers.indexWhere((r) => r.id == id);
    if (i == -1) throw StateError('Читатель $id не найден');
    _readers[i] = _readers[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _readers.indexWhere((r) => r.id == id && !r.isDeleted);
      if (i != -1) {
        _readers[i] = _readers[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    if (count > 0) await _persist();
    return count;
  }
}