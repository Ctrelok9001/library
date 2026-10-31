import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exceptions.dart';
import '../../core/validators.dart';
import '../../models/genre.dart';
import '../../repositories/genre_repository.dart';
import 'package:go_router/go_router.dart';

class GenreFormScreen extends StatefulWidget {
  final int? id;
  const GenreFormScreen({super.key, this.id});
  bool get isEditing => id != null;

  @override
  State<GenreFormScreen> createState() => _GenreFormScreenState();
}

class _GenreFormScreenState extends State<GenreFormScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  bool _loading = true;
  String? _error;
  Map<String, String> _serverErrors = {};
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

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
    final g = await context.read<GenreRepository>().findById(widget.id!);
    if (!mounted) return;
    if (g == null) {
      setState(() => _error = 'Жанр не найден');
      return;
    }
    setState(() {
      _name.text = g.name;
      _description.text = g.description;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _serverErrors = {};
      _saving = true;
    });
    try {
      final repo = context.read<GenreRepository>();
      final genre = Genre(
          id: widget.id ?? 0,
          name: _name.text.trim(),
          description: _description.text.trim());
      if (widget.isEditing) {
        await repo.update(genre);
      } else {
        await repo.create(genre);
      }
      if (mounted) {
        context.go('/genres');
      }
    } on ValidationException catch (e) {
      setState(() => _serverErrors = e.errors);
      _formKey.currentState?.validate();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _error != null) {
      return Scaffold(
        appBar: AppBar(
            title:
                Text(widget.isEditing ? 'Редактирование жанра' : 'Новый жанр')),
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

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Scaffold(
        appBar: AppBar(
            title:
                Text(widget.isEditing ? 'Редактирование жанра' : 'Новый жанр')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'Название', border: OutlineInputBorder()),
                  validator: (v) {
                    final local = V
                        .combine([V.required(), V.length(min: 2, max: 100)])(v);
                    return local ?? _serverErrors['name'];
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Описание', border: OutlineInputBorder()),
                  validator: V.length(max: 1000),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(widget.isEditing ? 'Сохранить' : 'Создать'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
