import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'package:library_app/core/api_exceptions.dart';
import 'package:library_app/models/app_user.dart';
import 'package:library_app/models/book.dart';
import 'package:library_app/models/book_query.dart';
import 'package:library_app/models/page_result.dart';
import 'package:library_app/models/role.dart';
import 'package:library_app/repositories/book_repository.dart';
import 'package:library_app/screens/auth/login_screen.dart';
import 'package:library_app/screens/books/book_list_screen.dart';
import 'package:library_app/state/auth_notifier.dart';
import 'package:library_app/state/book_list_notifier.dart';

class FakeBookRepository implements BookRepository {
  List<Book> items;
  bool shouldFail;
  Duration? delay;

  FakeBookRepository({
    this.items = const [],
    this.shouldFail = false,
    this.delay,
  });

  @override
  Future<PageResult<Book>> find(BookQuery query,
      {CancelToken? cancelToken}) async {
    if (delay != null) {
      await Future.delayed(delay!);
    }
    if (shouldFail) {
      throw const NetworkException('Ошибка соединения с сервером');
    }
    return PageResult(
      items: items,
      page: 1,
      size: 10,
      total: items.length,
    );
  }

  @override
  Future<List<Book>> findAll() async => items;

  @override
  Future<Book?> findById(int id) async =>
      items.where((b) => b.id == id).firstOrNull;

  @override
  Future<Book> create(Book book) async => book;

  @override
  Future<Book> update(Book book) async => book;

  @override
  Future<void> softDelete(int id) async {}

  @override
  Future<void> hardDelete(int id) async {}

  @override
  Future<void> restore(int id) async {}

  @override
  Future<int> deleteMany(List<int> ids) async => ids.length;

  @override
  bool isbnExists(String isbn, {int? exceptId}) => false;
}

class MockAuthNotifier extends AuthNotifier {
  final AppUser? mockUser;
  MockAuthNotifier(SharedPreferences prefs, {this.mockUser})
      : super(prefs, () => Dio());

  @override
  AppUser? get user => mockUser;

  @override
  bool get isAuthenticated => mockUser != null;

  @override
  bool hasRole(Role role) =>
      mockUser != null && mockUser!.role.level >= role.level;
}

Widget buildTestApp({
  required Widget child,
  required AuthNotifier auth,
  required BookListNotifier bookNotifier,
}) {
  final router = GoRouter(
    initialLocation: '/books',
    routes: [
      GoRoute(path: '/books', builder: (c, s) => child),
      GoRoute(
          path: '/books/new',
          builder: (c, s) => const Scaffold(body: Text('Новая книга'))),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    ],
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthNotifier>.value(value: auth),
      ChangeNotifierProvider<BookListNotifier>.value(value: bookNotifier),
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('Widget Tests (Requirement 12)', () {
    testWidgets('1. Срабатывание валидации формы при пустом вводе',
        (tester) async {
      final auth = MockAuthNotifier(prefs);
      final bookRepo = FakeBookRepository();
      final bookNotifier = BookListNotifier(bookRepo);

      await tester.pumpWidget(
        buildTestApp(
          child: const LoginScreen(),
          auth: auth,
          bookNotifier: bookNotifier,
        ),
      );

      await tester.tap(find.text('Войти'));
      await tester.pump();

      expect(find.text('Введите логин'), findsOneWidget);
      expect(find.text('Введите пароль'), findsOneWidget);
    });

    testWidgets('2. Скрытие кнопки добавления книги для роли Читатель',
        (tester) async {
      const readerUser = AppUser(
        id: 1,
        username: 'reader',
        fullName: 'Иван Читатель',
        role: Role.reader,
      );
      final auth = MockAuthNotifier(prefs, mockUser: readerUser);
      final bookRepo = FakeBookRepository(items: []);
      final bookNotifier = BookListNotifier(bookRepo);

      await tester.pumpWidget(
        buildTestApp(
          child: const BookListScreen(),
          auth: auth,
          bookNotifier: bookNotifier,
        ),
      );
      await tester.pump();

      expect(find.byTooltip('Новая книга'), findsNothing);
    });

    testWidgets('3. Отображение кнопки добавления книги для роли Библиотекарь',
        (tester) async {
      const librarianUser = AppUser(
        id: 2,
        username: 'librarian',
        fullName: 'Анна Библиотекарь',
        role: Role.librarian,
      );
      final auth = MockAuthNotifier(prefs, mockUser: librarianUser);
      final bookRepo = FakeBookRepository(items: []);
      final bookNotifier = BookListNotifier(bookRepo);

      await tester.pumpWidget(
        buildTestApp(
          child: const BookListScreen(),
          auth: auth,
          bookNotifier: bookNotifier,
        ),
      );
      await tester.pump();

      expect(find.byTooltip('Новая книга'), findsOneWidget);
    });

    testWidgets('4. Отображение состояния загрузки (CircularProgressIndicator)',
        (tester) async {
      final auth = MockAuthNotifier(prefs);
      final bookRepo =
          FakeBookRepository(delay: const Duration(milliseconds: 500));
      final bookNotifier = BookListNotifier(bookRepo);

      await tester.pumpWidget(
        buildTestApp(
          child: const BookListScreen(),
          auth: auth,
          bookNotifier: bookNotifier,
        ),
      );

      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      await tester.pumpAndSettle();
    });

    testWidgets('5. Отображение пустого результата («Ничего не найдено»)',
        (tester) async {
      final auth = MockAuthNotifier(prefs);
      final bookRepo = FakeBookRepository(items: []);
      final bookNotifier = BookListNotifier(bookRepo);

      await tester.pumpWidget(
        buildTestApp(
          child: const BookListScreen(),
          auth: auth,
          bookNotifier: bookNotifier,
        ),
      );

      await bookNotifier.load();
      await tester.pumpAndSettle();

      expect(find.text('Ничего не найдено'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('6. Отображение ошибки с кнопкой повтора при сбое сети',
        (tester) async {
      final auth = MockAuthNotifier(prefs);
      final bookRepo = FakeBookRepository(shouldFail: true);
      final bookNotifier = BookListNotifier(bookRepo);

      await tester.pumpWidget(
        buildTestApp(
          child: const BookListScreen(),
          auth: auth,
          bookNotifier: bookNotifier,
        ),
      );

      await bookNotifier.load();
      await tester.pumpAndSettle();

      expect(
          find.textContaining('Ошибка соединения с сервером'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Повторить'), findsOneWidget);
    });
  });
}
