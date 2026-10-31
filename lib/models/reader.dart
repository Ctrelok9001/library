import 'library_card.dart';

class Reader {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final LibraryCard card;
  final DateTime? deletedAt;

  const Reader({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.card,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  String get fullName => '$lastName ${firstName[0]}.';

  Reader copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    LibraryCard? card,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Reader(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      card: card ?? this.card,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'fullName': '$lastName $firstName',
        'email': email,
        'phone': phone,
      };

  factory Reader.fromJson(Map<String, dynamic> j) {
    String firstName = (j['firstName'] as String?) ?? '';
    String lastName = (j['lastName'] as String?) ?? '';

    final full = j['fullName'] as String?;
    if (full != null && full.trim().isNotEmpty) {
      final parts = full.trim().split(RegExp(r'\s+'));
      lastName = parts.first;
      firstName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    LibraryCard card;
    final c = j['card'];
    if (c is Map<String, dynamic>) {
      final validUntilStr = (c['validUntil'] ?? c['expiresAt']) as String?;
      card = LibraryCard(
        number: (c['number'] as String?) ?? '',
        issuedAt: c['issuedAt'] == null
            ? DateTime.now()
            : DateTime.parse(c['issuedAt'] as String),
        validUntil:
            validUntilStr == null ? null : DateTime.tryParse(validUntilStr),
      );
    } else {
      card = LibraryCard(number: '', issuedAt: DateTime.now());
    }

    return Reader(
      id: (j['id'] as num?)?.toInt() ?? 0,
      firstName: firstName,
      lastName: lastName,
      email: (j['email'] as String?) ?? '',
      phone: (j['phone'] as String?) ?? '',
      card: card,
      deletedAt: j['deletedAt'] == null
          ? null
          : DateTime.tryParse(j['deletedAt'] as String),
    );
  }
}
