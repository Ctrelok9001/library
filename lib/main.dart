import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/config.dart';
import 'core/ref_cache.dart';
import 'core/router.dart';
import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';
import 'repositories/api_author_repository.dart';
import 'repositories/api_book_repository.dart';
import 'repositories/api_genre_repository.dart';
import 'repositories/api_publisher_repository.dart';
import 'repositories/api_reader_repository.dart';
import 'state/author_list_notifier.dart';
import 'state/book_list_notifier.dart';
import 'state/genre_list_notifier.dart';
import 'state/publisher_list_notifier.dart';
import 'state/reader_list_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final dio = buildDio();

  final bookRepository = ApiBookRepository(dio);
  final authorRepository = ApiAuthorRepository(dio);
  final genreRepository = ApiGenreRepository(dio);
  final publisherRepository = ApiPublisherRepository(dio);
  final readerRepository = ApiReaderRepository(dio);

  runApp(LibraryApp(
    bookRepository: bookRepository,
    authorRepository: authorRepository,
    genreRepository: genreRepository,
    publisherRepository: publisherRepository,
    readerRepository: readerRepository,
  ));
}

class LibraryApp extends StatelessWidget {
  final BookRepository bookRepository;
  final AuthorRepository authorRepository;
  final GenreRepository genreRepository;
  final PublisherRepository publisherRepository;
  final ReaderRepository readerRepository;

  const LibraryApp({
    super.key,
    required this.bookRepository,
    required this.authorRepository,
    required this.genreRepository,
    required this.publisherRepository,
    required this.readerRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<BookRepository>.value(value: bookRepository),
        Provider<AuthorRepository>.value(value: authorRepository),
        Provider<GenreRepository>.value(value: genreRepository),
        Provider<PublisherRepository>.value(value: publisherRepository),
        Provider<ReaderRepository>.value(value: readerRepository),
        Provider<RefCache>(
          create: (_) =>
              RefCache(authorRepository, genreRepository, publisherRepository),
        ),
        ChangeNotifierProvider(
          create: (c) => BookListNotifier(c.read<BookRepository>()),
        ),
        ChangeNotifierProvider(
          create: (c) => AuthorListNotifier(c.read<AuthorRepository>()),
        ),
        ChangeNotifierProvider(
          create: (c) => GenreListNotifier(c.read<GenreRepository>()),
        ),
        ChangeNotifierProvider(
          create: (c) => PublisherListNotifier(c.read<PublisherRepository>()),
        ),
        ChangeNotifierProvider(
          create: (c) => ReaderListNotifier(c.read<ReaderRepository>()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Библиотека',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32),
          ),
          useMaterial3: true,
        ),
        routerConfig: appRouter,
      ),
    );
  }
}