import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:library_app/main.dart';
import 'package:library_app/repositories/persistent_author_repository.dart';
import 'package:library_app/repositories/persistent_book_repository.dart';
import 'package:library_app/repositories/persistent_genre_repository.dart';
import 'package:library_app/repositories/persistent_publisher_repository.dart';
import 'package:library_app/repositories/persistent_reader_repository.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final bookRepo = PersistentBookRepository(prefs);

    await tester.pumpWidget(LibraryApp(
      bookRepository: bookRepo,
      authorRepository: PersistentAuthorRepository(prefs),
      genreRepository: PersistentGenreRepository(prefs),
      publisherRepository: PersistentPublisherRepository(prefs, bookRepo),
      readerRepository: PersistentReaderRepository(prefs),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}