import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import 'author_repository.dart';

class ApiAuthorRepository implements AuthorRepository {
  final Dio _dio;
  ApiAuthorRepository(this._dio);

  @override
  Future<PageResult<Author>> find(AuthorQuery q, {CancelToken? cancelToken}) =>
      guard(() async {
        final r = await _dio.get(
          '/authors',
          queryParameters: {
            if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
            'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
            'page': q.page,
            'size': q.size,
            if (q.includeDeleted) 'includeDeleted': 'true',
          },
          cancelToken: cancelToken,
        );
        final data = r.data as Map<String, dynamic>;
        return PageResult(
          items: (data['items'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Author.fromJson)
              .toList(),
          page: data['page'] as int? ?? q.page,
          size: data['size'] as int? ?? q.size,
          total: data['total'] as int? ?? 0,
        );
      }, retryOnNetwork: true);

  @override
  Future<List<Author>> findAll() async =>
      (await find(const AuthorQuery(size: 1000))).items;

  @override
  Future<Author?> findById(int id) => guard(() async {
        try {
          final r = await _dio.get('/authors/$id');
          return Author.fromJson(r.data as Map<String, dynamic>);
        } on NotFoundException {
          return null;
        }
      }, retryOnNetwork: true);

  @override
  Future<Author> create(Author a) => guard(() async {
        final r = await _dio.post('/authors', data: a.toJson());
        return Author.fromJson(r.data as Map<String, dynamic>);
      });

  @override
  Future<Author> update(Author a) => guard(() async {
        final r = await _dio.put('/authors/${a.id}', data: a.toJson());
        return Author.fromJson(r.data as Map<String, dynamic>);
      });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/authors/$id'));

  @override
  Future<void> hardDelete(int id) => guard(
      () => _dio.delete('/authors/$id', queryParameters: {'hard': 'true'}));

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/authors/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final r = await _dio.post('/authors/bulk-delete', data: {'ids': ids});
        return (r.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
      });
}
