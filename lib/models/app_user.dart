import 'role.dart';

class AppUser {
  final int id;
  final String username;
  final String fullName;
  final Role role;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    String roleStr = (json['role'] as String? ?? 'reader').toLowerCase();
    Role role = Role.values.firstWhere(
      (e) => e.name == roleStr,
      orElse: () => Role.reader,
    );
    return AppUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: role,
    );
  }
}
