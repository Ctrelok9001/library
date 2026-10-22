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
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'card': card.toJson(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Reader.fromJson(Map<String, dynamic> j) => Reader(
        id: (j['id'] as num?)?.toInt() ?? 0,
        firstName: (j['firstName'] as String?) ?? '',
        lastName: (j['lastName'] as String?) ?? '',
        email: (j['email'] as String?) ?? '',
        phone: (j['phone'] as String?) ?? '',
        card: j['card'] is Map
            ? LibraryCard.fromJson(j['card'] as Map<String, dynamic>)
            : LibraryCard(number: '', issuedAt: DateTime.now()),
        deletedAt: j['deletedAt'] == null
            ? null
            : DateTime.tryParse(j['deletedAt'] as String),
      );
}