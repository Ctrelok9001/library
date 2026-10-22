import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/books/book_list_screen.dart';
import '../screens/books/book_detail_screen.dart';
import '../screens/books/book_form_screen.dart';
import '../screens/authors/author_list_screen.dart';
import '../screens/authors/author_detail_screen.dart';
import '../screens/authors/author_form_screen.dart';
import '../screens/genres/genre_list_screen.dart';
import '../screens/genres/genre_detail_screen.dart';
import '../screens/genres/genre_form_screen.dart';
import '../screens/publishers/publisher_list_screen.dart';
import '../screens/publishers/publisher_detail_screen.dart';
import '../screens/publishers/publisher_form_screen.dart';
import '../screens/readers/reader_list_screen.dart';
import '../screens/readers/reader_detail_screen.dart';
import '../screens/readers/reader_form_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/books',
  routes: [
    GoRoute(path: '/', redirect: (_, __) => '/books'),

    // Книги
    GoRoute(
      path: '/books',
      pageBuilder: (c, s) => const NoTransitionPage(child: BookListScreen()),
      routes: [
        GoRoute(path: 'new', builder: (c, s) => const BookFormScreen()),
        GoRoute(
          path: ':id',
          builder: (c, s) => BookDetailScreen(
              id: int.parse(s.pathParameters['id']!)),
        ),
        GoRoute(
          path: ':id/edit',
          builder: (c, s) => BookFormScreen(
              id: int.tryParse(s.pathParameters['id']!)),
        ),
      ],
    ),

    GoRoute(
      path: '/authors',
      pageBuilder: (c, s) => const NoTransitionPage(child: AuthorListScreen()),
      routes: [
        GoRoute(path: 'new', builder: (c, s) => const AuthorFormScreen()),
        GoRoute(
          path: ':id',
          builder: (c, s) => AuthorDetailScreen(
              id: int.parse(s.pathParameters['id']!)),
        ),
        GoRoute(
          path: ':id/edit',
          builder: (c, s) => AuthorFormScreen(
              id: int.tryParse(s.pathParameters['id']!)),
        ),
      ],
    ),

    GoRoute(
      path: '/genres',
      pageBuilder: (c, s) => const NoTransitionPage(child: GenreListScreen()),
      routes: [
        GoRoute(path: 'new', builder: (c, s) => const GenreFormScreen()),
        GoRoute(
          path: ':id',
          builder: (c, s) => GenreDetailScreen(
              id: int.parse(s.pathParameters['id']!)),
        ),
        GoRoute(
          path: ':id/edit',
          builder: (c, s) => GenreFormScreen(
              id: int.tryParse(s.pathParameters['id']!)),
        ),
      ],
    ),

    GoRoute(
      path: '/publishers',
      pageBuilder: (c, s) =>
          const NoTransitionPage(child: PublisherListScreen()),
      routes: [
        GoRoute(
            path: 'new', builder: (c, s) => const PublisherFormScreen()),
        GoRoute(
          path: ':id',
          builder: (c, s) => PublisherDetailScreen(
              id: int.parse(s.pathParameters['id']!)),
        ),
        GoRoute(
          path: ':id/edit',
          builder: (c, s) => PublisherFormScreen(
              id: int.tryParse(s.pathParameters['id']!)),
        ),
      ],
    ),

    GoRoute(
      path: '/readers',
      pageBuilder: (c, s) => const NoTransitionPage(child: ReaderListScreen()),
      routes: [
        GoRoute(path: 'new', builder: (c, s) => const ReaderFormScreen()),
        GoRoute(
          path: ':id',
          builder: (c, s) => ReaderDetailScreen(
              id: int.parse(s.pathParameters['id']!)),
        ),
        GoRoute(
          path: ':id/edit',
          builder: (c, s) => ReaderFormScreen(
              id: int.tryParse(s.pathParameters['id']!)),
        ),
      ],
    ),
  ],
);