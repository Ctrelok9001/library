enum Role {
  reader(1, 'Читатель'),
  librarian(2, 'Библиотекарь'),
  admin(3, 'Администратор');

  final int level;
  final String label;
  const Role(this.level, this.label);
}