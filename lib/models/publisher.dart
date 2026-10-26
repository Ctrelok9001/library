class Publisher {
  final int id;
  final String name;
  final String country;
  final DateTime? deletedAt;

  const Publisher({
    required this.id,
    required this.name,
    this.country = '',
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Publisher copyWith({
    String? name,
    String? country,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Publisher(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'city': country,
      };

  factory Publisher.fromJson(Map<String, dynamic> j) => Publisher(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: (j['name'] as String?) ?? '',
        country: (j['country'] ?? j['city'] ?? '') as String,
        deletedAt: j['deletedAt'] == null
            ? null
            : DateTime.tryParse(j['deletedAt'] as String),
      );
}