import 'package:flutter_test/flutter_test.dart';
import '../lib/models/role.dart';
import '../lib/models/app_user.dart';

void main() {
  group('Role checks and permissions', () {
    final reader = AppUser(id: 1, username: 'reader', fullName: 'Иван Читатель', role: Role.reader);
    final librarian = AppUser(id: 2, username: 'librarian', fullName: 'Анна Библиотекарь', role: Role.librarian);
    final admin = AppUser(id: 3, username: 'admin', fullName: 'Главный Администратор', role: Role.admin);

    test('1. Reader has read-only access and cannot access librarian/admin operations', () {
      expect(reader.role.level >= Role.reader.level, isTrue);
      expect(reader.role.level >= Role.librarian.level, isFalse);
      expect(reader.role.level >= Role.admin.level, isFalse);
    });

    test('2. Librarian can manage books/authors but cannot access admin panel', () {
      expect(librarian.role.level >= Role.reader.level, isTrue);
      expect(librarian.role.level >= Role.librarian.level, isTrue);
      expect(librarian.role.level >= Role.admin.level, isFalse);
    });

    test('3. Admin has full access to all sections and operations', () {
      expect(admin.role.level >= Role.reader.level, isTrue);
      expect(admin.role.level >= Role.librarian.level, isTrue);
      expect(admin.role.level >= Role.admin.level, isTrue);
    });

    test('4. Role hierarchy levels are strictly ordered', () {
      expect(Role.reader.level, equals(1));
      expect(Role.librarian.level, equals(2));
      expect(Role.admin.level, equals(3));
      expect(Role.reader.level < Role.librarian.level, isTrue);
      expect(Role.librarian.level < Role.admin.level, isTrue);
    });

    test('5. User parsing from JSON handles various case formats and defaults', () {
      final adminUser = AppUser.fromJson({'id': 1, 'username': 'a', 'fullName': 'A', 'role': 'admin'});
      final upperAdmin = AppUser.fromJson({'id': 2, 'username': 'a2', 'fullName': 'A2', 'role': 'ADMIN'});
      final libUser = AppUser.fromJson({'id': 3, 'username': 'l', 'fullName': 'L', 'role': 'librarian'});
      final unknownUser = AppUser.fromJson({'id': 4, 'username': 'u', 'fullName': 'U', 'role': 'unknown_role'});

      expect(adminUser.role, equals(Role.admin));
      expect(upperAdmin.role, equals(Role.admin));
      expect(libUser.role, equals(Role.librarian));
      expect(unknownUser.role, equals(Role.reader));
    });

    test('6. Route guard simulations for /books/new and /admin', () {
      bool canAccessBooksNew(AppUser user) => user.role.level >= Role.librarian.level;
      bool canAccessAdminPanel(AppUser user) => user.role.level >= Role.admin.level;
      bool canViewCatalog(AppUser user) => user.role.level >= Role.reader.level;

      expect(canViewCatalog(reader), isTrue);
      expect(canViewCatalog(librarian), isTrue);
      expect(canViewCatalog(admin), isTrue);

      expect(canAccessBooksNew(reader), isFalse);
      expect(canAccessBooksNew(librarian), isTrue);
      expect(canAccessBooksNew(admin), isTrue);

      expect(canAccessAdminPanel(reader), isFalse);
      expect(canAccessAdminPanel(librarian), isFalse);
      expect(canAccessAdminPanel(admin), isTrue);
    });
  });
}
