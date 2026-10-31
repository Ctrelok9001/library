import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/core/validators.dart';
import 'package:library_app/models/book.dart';
import 'package:library_app/models/author.dart';
import 'package:library_app/models/genre_query.dart';

void main() {
  group('1. Unit Tests - Validators', () {
    test('V.required rejects empty string and null, accepts valid text', () {
      expect(V.required()(''), isNotNull);
      expect(V.required()('   '), isNotNull);
      expect(V.required()(null), isNotNull);
      expect(V.required()('Война и мир'), isNull);
    });

    test('V.length validates min and max boundaries', () {
      final validator = V.length(min: 3, max: 10);
      expect(validator('ab'), isNotNull);
      expect(validator('abc'), isNull);
      expect(validator('1234567890'), isNull);
      expect(validator('12345678901'), isNotNull);
    });

    test('V.integer validates numbers and ranges', () {
      final validator = V.integer(min: 1800, max: 2026, label: 'Год');
      expect(validator('not_a_number'), equals('Не является целым числом'));
      expect(validator('1799'), equals('Год не меньше 1800'));
      expect(validator('2030'), equals('Год не больше 2026'));
      expect(validator('1984'), isNull);
    });

    test('V.positive requires number >= 1', () {
      final validator = V.positive(label: 'Количество');
      expect(validator('0'), equals('Количество не меньше 1'));
      expect(validator('-5'), equals('Количество не меньше 1'));
      expect(validator('5'), isNull);
    });

    test('V.email validates email address format', () {
      final validator = V.email();
      expect(validator('invalid_email'), isNotNull);
      expect(validator('user@example'), isNotNull);
      expect(validator('reader@library.ru'), isNull);
    });

    test('V.isbn validates standard ISBN formats', () {
      final validator = V.isbn();
      expect(validator('123'), isNotNull);
      expect(validator('978-5-17-118366-4'), isNull);
      expect(validator('0-19-853453-1'), isNull);
    });

    test('V.combine stops at the first failing validator', () {
      final validator = V.combine([
        V.required('Поле обязательно'),
        V.length(min: 5),
      ]);
      expect(validator(''), equals('Поле обязательно'));
      expect(validator('abc'), equals('Не короче 5 символов'));
      expect(validator('valid_value'), isNull);
    });
  });

  group('2. Unit Tests - Model Parsing', () {
    test('Book.fromJson parses flat and nested publisher correctly', () {
      final jsonNested = {
        'id': 1,
        'title': 'Евгений Онегин',
        'isbn': '978-5-17-000001-1',
        'year': 1833,
        'pages': 250,
        'publisher': {'id': 10, 'name': 'Эксмо'},
        'authorIds': [1, 2],
        'genreIds': [3],
        'copiesTotal': 5,
        'copiesAvailable': 3,
      };

      final book = Book.fromJson(jsonNested);
      expect(book.id, equals(1));
      expect(book.title, equals('Евгений Онегин'));
      expect(book.publisherId, equals(10));
      expect(book.authorIds, equals([1, 2]));
      expect(book.isDeleted, isFalse);
    });

    test('Author.fromJson parses author properties', () {
      final json = {
        'id': 42,
        'firstName': 'Александр',
        'lastName': 'Пушкин',
        'country': 'Россия',
        'birthYear': 1799,
        'deathYear': 1837,
      };

      final author = Author.fromJson(json);
      expect(author.id, equals(42));
      expect(author.firstName, equals('Александр'));
      expect(author.lastName, equals('Пушкин'));
      expect(author.fullName, equals('Пушкин А.'));
      expect(author.country, equals('Россия'));
      expect(author.birthYear, equals(1799));
      expect(author.deathYear, equals(1837));
      expect(author.isDeleted, isFalse);
    });

    test('GenreQuery.fromUri extracts search, pagination, and sorting', () {
      final uri = Uri.parse(
          'http://localhost:8000/genres?search=драма&page=2&size=20&sort=name,desc');
      final query = GenreQuery.fromUri(uri);

      expect(query.search, equals('драма'));
      expect(query.page, equals(2));
      expect(query.size, equals(20));
      expect(query.sortField, equals('name'));
      expect(query.sortAscending, isFalse);
    });
  });
}
