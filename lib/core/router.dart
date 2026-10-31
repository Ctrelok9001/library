import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/auth_notifier.dart';
import '../models/role.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forbidden_screen.dart';
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
import '../screens/admin/admin_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(AuthNotifier auth) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: auth,
    initialLocation: '/books',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';

      if (!loggedIn && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }

      if (loggedIn && isPublic) {
        return '/books';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/forbidden', builder: (c, s) => const ForbiddenScreen()),
      GoRoute(
        path: '/books',
        redirect: (context, state) =>
            auth.hasRole(Role.reader) ? null : '/forbidden',
        pageBuilder: (c, s) => const NoTransitionPage(child: BookListScreen()),
        routes: [
          GoRoute(
            path: 'new',
            builder: (c, s) => const BookFormScreen(),
            redirect: (c, s) =>
                auth.hasRole(Role.librarian) ? null : '/forbidden',
          ),
          GoRoute(
            path: ':id',
            builder: (c, s) =>
                BookDetailScreen(id: int.parse(s.pathParameters['id']!)),
            redirect: (c, s) => auth.hasRole(Role.reader) ? null : '/forbidden',
          ),
          GoRoute(
            path: ':id/edit',
            builder: (c, s) =>
                BookFormScreen(id: int.tryParse(s.pathParameters['id']!)),
            redirect: (c, s) =>
                auth.hasRole(Role.librarian) ? null : '/forbidden',
          ),
        ],
      ),
      GoRoute(
        path: '/authors',
        redirect: (context, state) =>
            auth.hasRole(Role.reader) ? null : '/forbidden',
        pageBuilder: (c, s) =>
            const NoTransitionPage(child: AuthorListScreen()),
        routes: [
          GoRoute(
            path: 'new',
            builder: (c, s) => const AuthorFormScreen(),
            redirect: (c, s) =>
                auth.hasRole(Role.librarian) ? null : '/forbidden',
          ),
          GoRoute(
            path: ':id',
            builder: (c, s) =>
                AuthorDetailScreen(id: int.parse(s.pathParameters['id']!)),
            redirect: (c, s) => auth.hasRole(Role.reader) ? null : '/forbidden',
          ),
          GoRoute(
            path: ':id/edit',
            builder: (c, s) =>
                AuthorFormScreen(id: int.tryParse(s.pathParameters['id']!)),
            redirect: (c, s) =>
                auth.hasRole(Role.librarian) ? null : '/forbidden',
          ),
        ],
      ),
      GoRoute(
        path: '/genres',
        redirect: (context, state) =>
            auth.hasRole(Role.librarian) ? null : '/forbidden',
        pageBuilder: (c, s) => const NoTransitionPage(child: GenreListScreen()),
        routes: [
          GoRoute(path: 'new', builder: (c, s) => const GenreFormScreen()),
          GoRoute(
              path: ':id',
              builder: (c, s) =>
                  GenreDetailScreen(id: int.parse(s.pathParameters['id']!))),
          GoRoute(
              path: ':id/edit',
              builder: (c, s) =>
                  GenreFormScreen(id: int.tryParse(s.pathParameters['id']!))),
        ],
      ),
      GoRoute(
        path: '/publishers',
        redirect: (context, state) =>
            auth.hasRole(Role.librarian) ? null : '/forbidden',
        pageBuilder: (c, s) =>
            const NoTransitionPage(child: PublisherListScreen()),
        routes: [
          GoRoute(path: 'new', builder: (c, s) => const PublisherFormScreen()),
          GoRoute(
              path: ':id',
              builder: (c, s) => PublisherDetailScreen(
                  id: int.parse(s.pathParameters['id']!))),
          GoRoute(
              path: ':id/edit',
              builder: (c, s) => PublisherFormScreen(
                  id: int.tryParse(s.pathParameters['id']!))),
        ],
      ),
      GoRoute(
        path: '/readers',
        redirect: (context, state) =>
            auth.hasRole(Role.librarian) ? null : '/forbidden',
        pageBuilder: (c, s) =>
            const NoTransitionPage(child: ReaderListScreen()),
        routes: [
          GoRoute(path: 'new', builder: (c, s) => const ReaderFormScreen()),
          GoRoute(
              path: ':id',
              builder: (c, s) =>
                  ReaderDetailScreen(id: int.parse(s.pathParameters['id']!))),
          GoRoute(
              path: ':id/edit',
              builder: (c, s) =>
                  ReaderFormScreen(id: int.tryParse(s.pathParameters['id']!))),
        ],
      ),
      GoRoute(
        path: '/admin',
        redirect: (context, state) =>
            auth.hasRole(Role.admin) ? null : '/forbidden',
        pageBuilder: (c, s) => const NoTransitionPage(child: AdminScreen()),
      ),
    ],
    errorBuilder: (c, s) => Scaffold(
      appBar: AppBar(title: const Text('Ошибка 404')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text('404: Страница «${s.uri}» не найдена',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => c.go('/books'),
              child: const Text('Вернуться к книгам'),
            ),
          ],
        ),
      ),
    ),
  );
}
