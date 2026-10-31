import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'package:library_app/main.dart';
import 'package:library_app/state/auth_notifier.dart';
import 'package:library_app/core/api_client.dart';
import 'package:library_app/repositories/api_book_repository.dart';
import 'package:library_app/repositories/api_author_repository.dart';
import 'package:library_app/repositories/api_genre_repository.dart';
import 'package:library_app/repositories/api_publisher_repository.dart';
import 'package:library_app/repositories/api_reader_repository.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    late final AuthNotifier authNotifier;
    late final Dio dio;

    authNotifier = AuthNotifier(prefs, () => dio);
    dio = buildDio(authNotifier);

    final bookRepo = ApiBookRepository(dio);

    await tester.pumpWidget(LibraryApp(
      authNotifier: authNotifier,
      dio: dio,
      bookRepository: bookRepo,
      authorRepository: ApiAuthorRepository(dio),
      genreRepository: ApiGenreRepository(dio),
      publisherRepository: ApiPublisherRepository(
        dio,
      ),
      readerRepository: ApiReaderRepository(dio),
    ));

    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
