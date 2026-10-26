import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:library_app/core/api_exceptions.dart';
import 'package:library_app/models/book.dart';
import 'package:library_app/models/book_query.dart';
import 'package:library_app/repositories/api_book_repository.dart';

class _FakeDio extends Interceptor {
  final Response Function(RequestOptions) handler;
  _FakeDio(this.handler);
}

Dio _fakeDio(Response Function(RequestOptions) handler) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test/api'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, h) {
        try {
          h.resolve(handler(options));
        } catch (e) {
          h.reject(DioException(requestOptions: options, error: e));
        }
      },
    ),
  );
  return dio;
}

void main() {
  test('parse page response', () async {
    final dio = _fakeDio((req) => Response(
          requestOptions: req,
          statusCode: 200,
          data: {
            'items': [
              {
                'id': 1,
                'title': 'T',
                'isbn': '1',
                'year': 2000,
                'pages': 100,
                'publisher': {'id': 1, 'name': 'P'},
                'authors': [],
                'genres': [],
                'copiesTotal': 2,
                'copiesAvailable': 1,
              }
            ],
            'page': 1,
            'size': 10,
            'total': 1,
          },
        ));
    final repo = ApiBookRepository(dio);
    final r = await repo.find(const BookQuery());
    expect(r.total, 1);
    expect(r.items.first.title, 'T');
  });

  test('404 from findById returns null', () async {
    final dio = _fakeDio((req) {
      throw DioException(
        requestOptions: req,
        response: Response(
            requestOptions: req,
            statusCode: 404,
            data: {'message': 'не найдено'}),
        type: DioExceptionType.badResponse,
      );
    });
    final repo = ApiBookRepository(dio);
    expect(await repo.findById(999), isNull);
  });

  test('422 maps to ValidationException', () async {
    final dio = _fakeDio((req) {
      throw DioException(
        requestOptions: req,
        response: Response(
          requestOptions: req,
          statusCode: 422,
          data: {
            'message': 'Ошибка валидации',
            'errors': {'isbn': 'занят'},
          },
        ),
        type: DioExceptionType.badResponse,
        error: mapHttpError(
          422,
          {
            'message': 'Ошибка валидации',
            'errors': {'isbn': 'занят'},
          },
        ),
      );
    });
    final repo = ApiBookRepository(dio);
    expect(
      () => repo.create(const Book(
          id: 0,
          title: 'T',
          isbn: 'x',
          year: 2000,
          pages: 1,
          publisherId: 1,
          authorIds: [],
          genreIds: [],
          copiesTotal: 1,
          copiesAvailable: 1)),
      throwsA(isA<ValidationException>()),
    );
  });

  test('network error maps to NetworkException', () async {
    final dio = _fakeDio((req) {
      throw DioException(
        requestOptions: req,
        type: DioExceptionType.connectionError,
      );
    });
    final repo = ApiBookRepository(dio);
    expect(
      () => repo.create(const Book(
          id: 0,
          title: 'T',
          isbn: 'x',
          year: 2000,
          pages: 1,
          publisherId: 1,
          authorIds: [],
          genreIds: [],
          copiesTotal: 1,
          copiesAvailable: 1)),
      throwsA(isA<NetworkException>()),
    );
  });

  test('409 maps to ConflictException', () async {
    final dio = _fakeDio((req) {
      throw DioException(
        requestOptions: req,
        response: Response(
            requestOptions: req,
            statusCode: 409,
            data: {'message': 'нет экземпляров'}),
        type: DioExceptionType.badResponse,
        error: mapHttpError(409, {'message': 'нет экземпляров'}),
      );
    });
    final repo = ApiBookRepository(dio);
    expect(
      () => repo.create(const Book(
          id: 0,
          title: 'T',
          isbn: 'x',
          year: 2000,
          pages: 1,
          publisherId: 1,
          authorIds: [],
          genreIds: [],
          copiesTotal: 1,
          copiesAvailable: 1)),
      throwsA(isA<ConflictException>()),
    );
  });
}