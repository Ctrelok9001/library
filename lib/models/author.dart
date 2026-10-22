class Author {
  final int id;
  final String firstName;
  final String lastName;
  final String country;
  final int birthYear;
  final int? deathYear;
  final DateTime? deletedAt;

  const Author({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.country,
    required this.birthYear,
    this.deathYear,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  String get fullName => '$lastName ${firstName[0]}.';

  Author copyWith({
    String? firstName,
    String? lastName,
    String? country,
    int? birthYear,
    Object? deathYear = _unset,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Author(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      country: country ?? this.country,
      birthYear: birthYear ?? this.birthYear,
      deathYear: deathYear == _unset ? this.deathYear : deathYear as int?,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  static const _unset = Object();

    Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'country': country,
        'birthYear': birthYear,
        'deathYear': deathYear,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Author.fromJson(Map<String, dynamic> j) => Author(
        id: (j['id'] as num?)?.toInt() ?? 0,
        firstName: (j['firstName'] as String?) ?? '',
        lastName: (j['lastName'] as String?) ?? '',
        country: (j['country'] as String?) ?? '',
        birthYear: (j['birthYear'] as num?)?.toInt() ?? 0,
        deathYear: (j['deathYear'] as num?)?.toInt(),
        deletedAt: j['deletedAt'] == null
            ? null
            : DateTime.tryParse(j['deletedAt'] as String),
      );
}