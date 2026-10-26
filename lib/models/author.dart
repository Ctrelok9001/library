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
    factory Author.fromJson(Map<String, dynamic> j) {
    String firstName = (j['firstName'] as String?) ?? '';
    String lastName = (j['lastName'] as String?) ?? '';

    final full = j['fullName'] as String?;
    if (full != null && full.trim().isNotEmpty) {
      final parts = full.trim().split(RegExp(r'\s+'));
      lastName = parts.first;
      firstName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    return Author(
      id: (j['id'] as num?)?.toInt() ?? 0,
      firstName: firstName,
      lastName: lastName,
      country: (j['country'] as String?) ?? '',
      birthYear: (j['birthYear'] as num?)?.toInt() ?? 0,
      deathYear: (j['deathYear'] as num?)?.toInt(),
      deletedAt: j['deletedAt'] == null
          ? null
          : DateTime.tryParse(j['deletedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'fullName': '$lastName $firstName',
        'birthYear': birthYear,
        'country': country,
        'deathYear': deathYear,
      };
}