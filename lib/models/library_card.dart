class LibraryCard {
  final String number;
  final DateTime issuedAt;
  final DateTime? validUntil;

  const LibraryCard({
    required this.number,
    required this.issuedAt,
    this.validUntil,
  });

  Map<String, dynamic> toJson() => {
        'number': number,
        'issuedAt': issuedAt.toIso8601String(),
        'validUntil': validUntil?.toIso8601String(),
      };

  factory LibraryCard.fromJson(Map<String, dynamic> j) => LibraryCard(
        number: (j['number'] as String?) ?? '',
        issuedAt: j['issuedAt'] == null
            ? DateTime.now()
            : DateTime.parse(j['issuedAt'] as String),
        validUntil: j['validUntil'] == null
            ? null
            : DateTime.tryParse(j['validUntil'] as String),
      );
}