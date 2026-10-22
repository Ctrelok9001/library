import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../models/publisher.dart';
import '../../repositories/publisher_repository.dart';
import '../../widgets/entity_form.dart';

class PublisherFormScreen extends StatefulWidget {
  final int? id;
  const PublisherFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<PublisherFormScreen> createState() => _PublisherFormScreenState();
}

class _PublisherFormScreenState extends State<PublisherFormScreen> {
  final _name = TextEditingController();
  final _country = TextEditingController();

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
    final p = await context.read<PublisherRepository>().findById(widget.id!);
    if (!mounted) return;
    if (p == null) {
      setState(() => _error = 'Издательство не найдено');
      return;
    }
    setState(() {
      _name.text = p.name;
      _country.text = p.country;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _country.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final repo = context.read<PublisherRepository>();
    final pub = Publisher(
      id: widget.id ?? 0,
      name: _name.text.trim(),
      country: _country.text.trim(),
    );
    if (widget.isEditing) {
      await repo.update(pub);
    } else {
      await repo.create(pub);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _error != null) {
      return Scaffold(
        appBar: AppBar(
            title: Text(widget.isEditing
                ? 'Редактирование издательства'
                : 'Новое издательство')),
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
      title: widget.isEditing
          ? 'Редактирование издательства'
          : 'Новое издательство',
      isEditing: widget.isEditing,
      onSubmit: _submit,
      fields: [
        EntityFormField(
          name: 'name',
          build: (_) => TextFormField(
            controller: _name,
            decoration: const InputDecoration(
                labelText: 'Название', border: OutlineInputBorder()),
            validator: V.combine([V.required(), V.length(min: 2, max: 200)]),
          ),
        ),
        EntityFormField(
          name: 'country',
          build: (_) => TextFormField(
            controller: _country,
            decoration: const InputDecoration(
                labelText: 'Страна', border: OutlineInputBorder()),
            validator: V.length(max: 100),
          ),
        ),
      ],
    );
  }
}