class Genre {
  final int id;
  final String name;
  const Genre({required this.id, required this.name});
}

class Publisher {
  final int id;
  final String name;
  const Publisher({required this.id, required this.name});
}

const genres = <Genre>[
  Genre(id: 1, name: 'Фантастика'),
  Genre(id: 2, name: 'Классика'),
  Genre(id: 3, name: 'Детектив'),
  Genre(id: 4, name: 'Фэнтези'),
  Genre(id: 5, name: 'Исторический роман'),
  Genre(id: 6, name: 'Научпоп'),
  Genre(id: 7, name: 'Поэзия'),
  Genre(id: 8, name: 'Биография'),
];

const publishers = <Publisher>[
  Publisher(id: 1, name: 'АСТ'),
  Publisher(id: 2, name: 'Эксмо'),
  Publisher(id: 3, name: 'Лабиринт'),
  Publisher(id: 4, name: 'РИПОЛ классик'),
  Publisher(id: 5, name: 'Азбука'),
];

String genreName(int id) =>
    genres.firstWhere((g) => g.id == id, orElse: () => Genre(id: id, name: '?')).name;

String publisherName(int id) => publishers
    .firstWhere((p) => p.id == id, orElse: () => Publisher(id: id, name: '?'))
    .name;