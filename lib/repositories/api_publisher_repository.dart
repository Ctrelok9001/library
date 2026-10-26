import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../models/page_result.dart';
import 'publisher_repository.dart';

class ApiPublisherRepository implements PublisherRepository {
  final Dio _dio;
  ApiPublisherRepository(this._dio);

    @override
  Future<PageResult<Publisher>> find(PublisherQuery q, {CancelToken? cancelToken}) => guard(() async {
        final r = await _dio.get('/publishers',
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
              .map(Publisher.fromJson)
              .toList(),
          page: data['page'] as int? ?? q.page,
          size: data['size'] as int? ?? q.size,
          total: data['total'] as int? ?? 0,
        );
      }, retryOnNetwork: true);

  @override
  Future<List<Publisher>> findAll() async =>
      (await find(const PublisherQuery(size: 1000))).items;

  @override
  Future<Publisher?> findById(int id) => guard(() async {
        try {
          final r = await _dio.get('/publishers/$id');
          return Publisher.fromJson(r.data as Map<String, dynamic>);
        } on NotFoundException {
          return null;
        }
      }, retryOnNetwork: true);

  @override
  Future<Publisher> create(Publisher p) => guard(() async {
        final r = await _dio.post('/publishers', data: p.toJson());
        return Publisher.fromJson(r.data as Map<String, dynamic>);
      });

  @override
  Future<Publisher> update(Publisher p) => guard(() async {
        final r = await _dio.put('/publishers/${p.id}', data: p.toJson());
        return Publisher.fromJson(r.data as Map<String, dynamic>);
      });

  @override
  Future<void> softDelete(int id) =>
      guard(() => _dio.delete('/publishers/$id'));

  @override
  Future<void> hardDelete(int id) => guard(
      () => _dio.delete('/publishers/$id', queryParameters: {'hard': 'true'}));

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/publishers/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final r =
            await _dio.post('/publishers/bulk-delete', data: {'ids': ids});
        return (r.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
      });


  @override
  Future<int> countBooksUsing(int publisherId) async {
    final r = await _dio.get(
      '/books',
      queryParameters: {
        'publisherId': publisherId,
        'size': 1,
      },
    );
    final data = r.data as Map<String, dynamic>;
    return (data['total'] as num?)?.toInt() ?? 0;
  }
}