import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../models/author.dart';
import '../../repositories/author_repository.dart';
import '../../widgets/entity_form.dart';

class AuthorFormScreen extends StatefulWidget {
  final int? id;
  const AuthorFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<AuthorFormScreen> createState() => _AuthorFormScreenState();
}

class _AuthorFormScreenState extends State<AuthorFormScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _country = TextEditingController();
  final _birthYear = TextEditingController();
  final _deathYear = TextEditingController();

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.id == null) {
      setState(() => _loading = false);
      return;
    }
    final a = await context.read<AuthorRepository>().findById(widget.id!);
    if (!mounted) return;
    if (a == null) {
      setState(() => _error = 'Автор не найден');
      return;
    }
    setState(() {
      _firstName.text = a.firstName;
      _lastName.text = a.lastName;
      _country.text = a.country;
      _birthYear.text = a.birthYear.toString();
      _deathYear.text = a.deathYear?.toString() ?? '';
      _loading = false;
    });
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _country.dispose();
    _birthYear.dispose();
    _deathYear.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final repo = context.read<AuthorRepository>();
    final death = _deathYear.text.trim();
    final author = Author(
      id: widget.id ?? 0,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      country: _country.text.trim(),
      birthYear: int.parse(_birthYear.text.trim()),
      deathYear: death.isEmpty ? null : int.parse(death),
    );
    if (widget.isEditing) {
      await repo.update(author);
    } else {
      await repo.create(author);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _error != null) {
      return Scaffold(
        appBar: AppBar(
            title: Text(widget.isEditing ? 'Редактирование автора' : 'Новый автор')),
        body: Center(
          child: _error != null
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!),
                  FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Назад')),
                ])
              : const CircularProgressIndicator(),
        ),
      );
    }

    return EntityForm(
      title: widget.isEditing ? 'Редактирование автора' : 'Новый автор',
      isEditing: widget.isEditing,
      onSubmit: _submit,
      fields: [
        EntityFormField(
          name: 'lastName',
          build: (_) => TextFormField(
            controller: _lastName,
            decoration: const InputDecoration(
                labelText: 'Фамилия', border: OutlineInputBorder()),
            validator: V.combine([V.required(), V.length(min: 2, max: 100)]),
          ),
        ),
        EntityFormField(
          name: 'firstName',
          build: (_) => TextFormField(
            controller: _firstName,
            decoration: const InputDecoration(
                labelText: 'Имя', border: OutlineInputBorder()),
            validator: V.combine([V.required(), V.length(min: 2, max: 100)]),
          ),
        ),
        EntityFormField(
          name: 'country',
          build: (_) => TextFormField(
            controller: _country,
            decoration: const InputDecoration(
                labelText: 'Страна', border: OutlineInputBorder()),
            validator: V.combine([V.required(), V.length(min: 2, max: 100)]),
          ),
        ),
        EntityFormField(
          name: 'birthYear',
          build: (_) => TextFormField(
            controller: _birthYear,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Год рождения', border: OutlineInputBorder()),
            validator: V.integer(min: 1, max: 2100, label: 'Год рождения'),
          ),
        ),
        EntityFormField(
          name: 'deathYear',
          build: (_) => TextFormField(
            controller: _deathYear,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Год смерти (необязательно)',
                border: OutlineInputBorder()),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final n = int.tryParse(v.trim());
              if (n == null) return 'Введите целое число';
              if (n < 1 || n > 2100) return 'Год вне диапазона';
              final birth = int.tryParse(_birthYear.text.trim());
              if (birth != null && n <= birth) {
                return 'Год смерти должен быть больше года рождения';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}