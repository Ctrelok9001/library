import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';

class ApiBookRepository implements BookRepository {
  final Dio _dio;
  ApiBookRepository(this._dio);

  @override
  Future<PageResult<Book>> find(BookQuery q, {CancelToken? cancelToken}) =>
      guard(() async {
        final response = await _dio.get(
          '/books',
          queryParameters: {
            if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
            if (q.genreId != null) 'genreId': q.genreId,
            if (q.publisherId != null) 'publisherId': q.publisherId,
            if (q.yearFrom != null) 'yearFrom': q.yearFrom,
            if (q.yearTo != null) 'yearTo': q.yearTo,
            'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
            'page': q.page,
            'size': q.size,
            if (q.includeDeleted) 'includeDeleted': 'true',
          },
          cancelToken: cancelToken,
        );
        final data = response.data as Map<String, dynamic>;
        return PageResult(
          items: (data['items'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Book.fromJson)
              .toList(),
          page: data['page'] as int? ?? q.page,
          size: data['size'] as int? ?? q.size,
          total: data['total'] as int? ?? 0,
        );
      }, retryOnNetwork: true);

  @override
  Future<List<Book>> findAll() async {
    final first = await find(const BookQuery(size: 1000));
    return first.items;
  }

  @override
  bool isbnExists(String isbn, {int? exceptId}) {
    return false;
  }

  @override
  Future<Book?> findById(int id) => guard(() async {
        try {
          final r = await _dio.get('/books/$id');
          return Book.fromJson(r.data as Map<String, dynamic>);
        } on DioException catch (e) {
          if (mapDioError(e) is NotFoundException) {
            return null;
          }
          rethrow;
        } on NotFoundException {
          return null;
        }
      }, retryOnNetwork: true);

  @override
  Future<Book> create(Book book) => guard(() async {
        final r = await _dio.post('/books', data: {
          'title': book.title,
          'isbn': book.isbn,
          'year': book.year,
          'pages': book.pages,
          'publisherId': book.publisherId,
          'authorIds': book.authorIds,
          'genreIds': book.genreIds,
          'copiesTotal': book.copiesTotal,
        });
        return Book.fromJson(r.data as Map<String, dynamic>);
      });

  @override
  Future<Book> update(Book book) => guard(() async {
        final r = await _dio.put('/books/${book.id}', data: {
          'title': book.title,
          'isbn': book.isbn,
          'year': book.year,
          'pages': book.pages,
          'publisherId': book.publisherId,
          'authorIds': book.authorIds,
          'genreIds': book.genreIds,
          'copiesTotal': book.copiesTotal,
        });
        return Book.fromJson(r.data as Map<String, dynamic>);
      });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/books/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/books/$id', queryParameters: {'hard': 'true'}));

  @override
  Future<void> restore(int id) => guard(() => _dio.post('/books/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final r = await _dio.post('/books/batch-delete', data: {'ids': ids});
        return (r.data as Map<String, dynamic>)['deleted'] as int? ??
            ids.length;
      });
}
