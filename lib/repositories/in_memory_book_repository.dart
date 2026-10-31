import 'package:dio/dio.dart';

import '../models/book.dart';
import '../models/page_result.dart';
import '../models/book_query.dart';
import 'book_repository.dart';

final List<Book> seedBooks = [
  Book(
      id: 1,
      title: 'Война и мир',
      isbn: '978-5-17-090796-7',
      year: 1869,
      pages: 1225,
      publisherId: 1,
      authorIds: [1],
      genreIds: [2, 5],
      copiesTotal: 5,
      copiesAvailable: 3),
  Book(
      id: 2,
      title: 'Анна Каренина',
      isbn: '978-5-04-098754-8',
      year: 1877,
      pages: 864,
      publisherId: 2,
      authorIds: [1],
      genreIds: [2],
      copiesTotal: 3,
      copiesAvailable: 2),
  Book(
      id: 3,
      title: 'Преступление и наказание',
      isbn: '978-5-17-083924-6',
      year: 1866,
      pages: 608,
      publisherId: 1,
      authorIds: [2],
      genreIds: [2, 3],
      copiesTotal: 4,
      copiesAvailable: 1),
  Book(
      id: 4,
      title: 'Братья Карамазовы',
      isbn: '978-5-367-00519-0',
      year: 1880,
      pages: 816,
      publisherId: 3,
      authorIds: [2],
      genreIds: [2],
      copiesTotal: 2,
      copiesAvailable: 0),
  Book(
      id: 5,
      title: 'Вишнёвый сад',
      isbn: '978-5-389-06433-4',
      year: 1904,
      pages: 224,
      publisherId: 5,
      authorIds: [3],
      genreIds: [2],
      copiesTotal: 3,
      copiesAvailable: 3),
  Book(
      id: 6,
      title: 'Евгений Онегин',
      isbn: '978-5-906838-18-9',
      year: 1833,
      pages: 320,
      publisherId: 4,
      authorIds: [4],
      genreIds: [2, 7],
      copiesTotal: 6,
      copiesAvailable: 4),
  Book(
      id: 7,
      title: 'Мёртвые души',
      isbn: '978-5-17-134014-0',
      year: 1842,
      pages: 480,
      publisherId: 1,
      authorIds: [5],
      genreIds: [2],
      copiesTotal: 3,
      copiesAvailable: 2),
  Book(
      id: 8,
      title: 'Мастер и Маргарита',
      isbn: '978-5-04-101083-2',
      year: 1967,
      pages: 480,
      publisherId: 2,
      authorIds: [6],
      genreIds: [2, 4],
      copiesTotal: 7,
      copiesAvailable: 2),
  Book(
      id: 9,
      title: 'Отцы и дети',
      isbn: '978-5-367-01107-5',
      year: 1862,
      pages: 256,
      publisherId: 3,
      authorIds: [7],
      genreIds: [2],
      copiesTotal: 4,
      copiesAvailable: 4),
  Book(
      id: 10,
      title: 'Лолита',
      isbn: '978-5-389-04262-2',
      year: 1955,
      pages: 448,
      publisherId: 5,
      authorIds: [8],
      genreIds: [2],
      copiesTotal: 2,
      copiesAvailable: 1),
  Book(
      id: 11,
      title: 'Гамлет',
      isbn: '978-5-906838-20-2',
      year: 1603,
      pages: 288,
      publisherId: 4,
      authorIds: [9],
      genreIds: [2],
      copiesTotal: 3,
      copiesAvailable: 3),
  Book(
      id: 12,
      title: 'Ромео и Джульетта',
      isbn: '978-5-17-102346-7',
      year: 1597,
      pages: 192,
      publisherId: 1,
      authorIds: [9],
      genreIds: [2],
      copiesTotal: 5,
      copiesAvailable: 5),
  Book(
      id: 13,
      title: 'Оливер Твист',
      isbn: '978-5-04-093210-4',
      year: 1838,
      pages: 512,
      publisherId: 2,
      authorIds: [10],
      genreIds: [2],
      copiesTotal: 2,
      copiesAvailable: 2),
  Book(
      id: 14,
      title: 'Посмертные записки Пиквикского клуба',
      isbn: '978-5-367-00927-1',
      year: 1837,
      pages: 768,
      publisherId: 3,
      authorIds: [10],
      genreIds: [2],
      copiesTotal: 1,
      copiesAvailable: 1),
  Book(
      id: 15,
      title: 'Воскресение',
      isbn: '978-5-389-08279-6',
      year: 1899,
      pages: 608,
      publisherId: 5,
      authorIds: [1],
      genreIds: [2],
      copiesTotal: 2,
      copiesAvailable: 2),
  Book(
      id: 16,
      title: 'Идиот',
      isbn: '978-5-17-088718-6',
      year: 1869,
      pages: 752,
      publisherId: 1,
      authorIds: [2],
      genreIds: [2],
      copiesTotal: 3,
      copiesAvailable: 0),
  Book(
      id: 17,
      title: 'Три сестры',
      isbn: '978-5-906838-35-6',
      year: 1901,
      pages: 176,
      publisherId: 4,
      authorIds: [3],
      genreIds: [2],
      copiesTotal: 4,
      copiesAvailable: 4),
  Book(
      id: 18,
      title: 'Руслан и Людмила',
      isbn: '978-5-04-104523-0',
      year: 1820,
      pages: 160,
      publisherId: 2,
      authorIds: [4],
      genreIds: [7],
      copiesTotal: 3,
      copiesAvailable: 3),
  Book(
      id: 19,
      title: 'Ревизор',
      isbn: '978-5-367-00223-4',
      year: 1836,
      pages: 208,
      publisherId: 3,
      authorIds: [5],
      genreIds: [2],
      copiesTotal: 5,
      copiesAvailable: 5),
  Book(
      id: 20,
      title: 'Собачье сердце',
      isbn: '978-5-389-09834-8',
      year: 1925,
      pages: 224,
      publisherId: 5,
      authorIds: [6],
      genreIds: [2, 4],
      copiesTotal: 3,
      copiesAvailable: 1),
  Book(
      id: 21,
      title: 'Белая гвардия',
      isbn: '978-5-17-134015-7',
      year: 1925,
      pages: 448,
      publisherId: 1,
      authorIds: [6],
      genreIds: [2, 5],
      copiesTotal: 2,
      copiesAvailable: 2),
  Book(
      id: 22,
      title: 'Дворянское гнездо',
      isbn: '978-5-04-095432-6',
      year: 1859,
      pages: 288,
      publisherId: 2,
      authorIds: [7],
      genreIds: [2],
      copiesTotal: 2,
      copiesAvailable: 2),
];

class InMemoryBookRepository implements BookRepository {
  final List<Book> _books = [...seedBooks];
  int _nextId = seedBooks.length + 1;

  @override
  Future<PageResult<Book>> find(BookQuery q, {CancelToken? cancelToken}) async {
    await Future.delayed(const Duration(milliseconds: 250));

    var rows = _books.where((b) => q.includeDeleted || !b.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((b) =>
              b.title.toLowerCase().contains(needle) ||
              b.isbn.toLowerCase().contains(needle))
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
      final result = switch (q.sortField) {
        'year' => a.year.compareTo(b.year),
        'pages' => a.pages.compareTo(b.pages),
        _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
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
    return created;
  }

  @override
  Future<Book> update(Book book) async {
    final i = _books.indexWhere((b) => b.id == book.id);
    if (i == -1) throw StateError('Книга ${book.id} не найдена');
    _books[i] = book;
    return book;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _books.removeWhere((b) => b.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    _books[i] = _books[i].copyWith(clearDeletedAt: true);
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
    return count;
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
}
