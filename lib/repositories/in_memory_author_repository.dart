import 'package:dio/dio.dart';

import '../models/author.dart';
import '../models/page_result.dart';
import '../models/author_query.dart';
import 'author_repository.dart';

final List<Author> seedAuthors = [
  Author(
      id: 1,
      firstName: 'Лев',
      lastName: 'Толстой',
      country: 'Россия',
      birthYear: 1828,
      deathYear: 1910),
  Author(
      id: 2,
      firstName: 'Фёдор',
      lastName: 'Достоевский',
      country: 'Россия',
      birthYear: 1821,
      deathYear: 1881),
  Author(
      id: 3,
      firstName: 'Антон',
      lastName: 'Чехов',
      country: 'Россия',
      birthYear: 1860,
      deathYear: 1904),
  Author(
      id: 4,
      firstName: 'Александр',
      lastName: 'Пушкин',
      country: 'Россия',
      birthYear: 1799,
      deathYear: 1837),
  Author(
      id: 5,
      firstName: 'Николай',
      lastName: 'Гоголь',
      country: 'Россия',
      birthYear: 1809,
      deathYear: 1852),
  Author(
      id: 6,
      firstName: 'Михаил',
      lastName: 'Булгаков',
      country: 'Россия',
      birthYear: 1891,
      deathYear: 1940),
  Author(
      id: 7,
      firstName: 'Иван',
      lastName: 'Тургенев',
      country: 'Россия',
      birthYear: 1818,
      deathYear: 1883),
  Author(
      id: 8,
      firstName: 'Владимир',
      lastName: 'Набоков',
      country: 'Россия',
      birthYear: 1899,
      deathYear: 1977),
  Author(
      id: 9,
      firstName: 'Уильям',
      lastName: 'Шекспир',
      country: 'Англия',
      birthYear: 1564,
      deathYear: 1616),
  Author(
      id: 10,
      firstName: 'Чарльз',
      lastName: 'Диккенс',
      country: 'Англия',
      birthYear: 1812,
      deathYear: 1870),
];

class InMemoryAuthorRepository implements AuthorRepository {
  final List<Author> _authors = [...seedAuthors];
  int _nextId = seedAuthors.length + 1;

  @override
  Future<PageResult<Author>> find(AuthorQuery q,
      {CancelToken? cancelToken}) async {
    await Future.delayed(const Duration(milliseconds: 250));

    var rows = _authors.where((a) => q.includeDeleted || !a.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((a) =>
              a.lastName.toLowerCase().contains(needle) ||
              a.country.toLowerCase().contains(needle))
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
      final result = switch (q.sortField) {
        'country' => a.country.compareTo(b.country),
        'birthYear' => a.birthYear.compareTo(b.birthYear),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
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
    return created;
  }

  @override
  Future<Author> update(Author author) async {
    final i = _authors.indexWhere((a) => a.id == author.id);
    if (i == -1) throw StateError('Автор ${author.id} не найден');
    _authors[i] = author;
    return author;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Автор $id не найден');
    _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _authors.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Автор $id не найден');
    _authors[i] = _authors[i].copyWith(clearDeletedAt: true);
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
    return count;
  }

  @override
  Future<List<Author>> findAll() async => List.of(_authors);
}
