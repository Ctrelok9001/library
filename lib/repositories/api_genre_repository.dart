import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/page_result.dart';
import 'genre_repository.dart';

class ApiGenreRepository implements GenreRepository {
  final Dio _dio;
  ApiGenreRepository(this._dio);

    @override
  Future<PageResult<Genre>> find(GenreQuery q, {CancelToken? cancelToken}) => guard(() async {
        final r = await _dio.get('/genres',
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
              .map(Genre.fromJson)
              .toList(),
          page: data['page'] as int? ?? q.page,
          size: data['size'] as int? ?? q.size,
          total: data['total'] as int? ?? 0,
        );
      }, retryOnNetwork: true);

  @override
  Future<List<Genre>> findAll() async =>
      (await find(const GenreQuery(size: 1000))).items;

  @override
  Future<Genre?> findById(int id) => guard(() async {
        try {
          final r = await _dio.get('/genres/$id');
          return Genre.fromJson(r.data as Map<String, dynamic>);
        } on NotFoundException {
          return null;
        }
      }, retryOnNetwork: true);

  @override
  Future<Genre> create(Genre g) => guard(() async {
        final r = await _dio.post('/genres', data: g.toJson());
        return Genre.fromJson(r.data as Map<String, dynamic>);
      });

  @override
  Future<Genre> update(Genre g) => guard(() async {
        final r = await _dio.put('/genres/${g.id}', data: g.toJson());
        return Genre.fromJson(r.data as Map<String, dynamic>);
      });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/genres/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/genres/$id', queryParameters: {'hard': 'true'}));

  @override
  Future<void> restore(int id) => guard(() => _dio.post('/genres/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final r = await _dio.post('/genres/bulk-delete', data: {'ids': ids});
        return (r.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
      });
}