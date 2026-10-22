import 'package:flutter/material.dart';

typedef FormFieldBuilder = Widget Function(BuildContext);

class EntityFormField {
  final String name;
  final FormFieldBuilder build;
  const EntityFormField({required this.name, required this.build});
}

class EntityForm extends StatefulWidget {
  final String title;
  final List<EntityFormField> fields;
  final Future<void> Function() onSubmit;
  final bool isEditing;

  const EntityForm({
    super.key,
    required this.title,
    required this.fields,
    required this.onSubmit,
    this.isEditing = false,
  });

  @override
  State<EntityForm> createState() => EntityFormState();
}

class EntityFormState extends State<EntityForm> {
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _dirty = false;

  void markDirty() => setState(() => _dirty = true);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit();
      _dirty = false;
      if (mounted) Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Несохранённые изменения'),
            content: const Text('Вы уверены, что хотите закрыть форму? '
                'Введённые данные будут потеряны.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Остаться'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Закрыть'),
              ),
            ],
          ),
        );
        if (ok == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: markDirty,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  for (final f in widget.fields) ...[
                    f.build(context),
                    const SizedBox(height: 16),
                  ],
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(widget.isEditing ? 'Сохранить' : 'Создать'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}