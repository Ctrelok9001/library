import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exceptions.dart';
import '../../core/validators.dart';
import '../../models/publisher.dart';
import '../../repositories/publisher_repository.dart';
import 'package:go_router/go_router.dart';

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
  Map<String, String> _serverErrors = {};
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (widget.id == null) { setState(() => _loading = false); return; }
    final p = await context.read<PublisherRepository>().findById(widget.id!);
    if (!mounted) return;
    if (p == null) { setState(() => _error = 'Издательство не найдено'); return; }
    setState(() {
      _name.text = p.name;
      _country.text = p.country;
      _loading = false;
    });
  }

  @override
  void dispose() { _name.dispose(); _country.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _serverErrors = {}; _saving = true; });
    try {
      final repo = context.read<PublisherRepository>();
      final pub = Publisher(id: widget.id ?? 0, name: _name.text.trim(), country: _country.text.trim());
      widget.isEditing ? await repo.update(pub) : await repo.create(pub);
      if (mounted) context.go('/publishers');
    } on ValidationException catch (e) {
      setState(() => _serverErrors = e.errors);
      _formKey.currentState?.validate();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Theme.of(context).colorScheme.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.isEditing ? 'Редактирование издательства' : 'Новое издательство')),
        body: Center(
          child: _error != null
              ? Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!), FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Назад'))])
              : const CircularProgressIndicator(),
        ),
      );
    }

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.isEditing ? 'Редактирование издательства' : 'Новое издательство')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Название', border: OutlineInputBorder()),
                  validator: (v) {
                    final local = V.combine([V.required(), V.length(min: 2, max: 200)])(v);
                    return local ?? _serverErrors['name'];
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _country,
                  decoration: const InputDecoration(labelText: 'Страна', border: OutlineInputBorder()),
                  validator: V.length(max: 100),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
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