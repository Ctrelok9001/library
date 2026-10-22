import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../models/reader.dart';
import '../../models/library_card.dart';
import '../../repositories/reader_repository.dart';
import '../../widgets/entity_form.dart';

class ReaderFormScreen extends StatefulWidget {
  final int? id;
  const ReaderFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<ReaderFormScreen> createState() => _ReaderFormScreenState();
}

class _ReaderFormScreenState extends State<ReaderFormScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _cardNumber = TextEditingController();
  final _cardIssued = TextEditingController();
  final _cardValid = TextEditingController();

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.id == null) {
      _cardIssued.text = _dateToString(DateTime.now());
      setState(() => _loading = false);
      return;
    }
    final r = await context.read<ReaderRepository>().findById(widget.id!);
    if (!mounted) return;
    if (r == null) {
      setState(() => _error = 'Читатель не найден');
      return;
    }
    setState(() {
      _firstName.text = r.firstName;
      _lastName.text = r.lastName;
      _email.text = r.email;
      _phone.text = r.phone;
      _cardNumber.text = r.card.number;
      _cardIssued.text = _dateToString(r.card.issuedAt);
      _cardValid.text = r.card.validUntil == null
          ? ''
          : _dateToString(r.card.validUntil!);
      _loading = false;
    });
  }

  String _dateToString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  DateTime? _parseDate(String s) {
    if (s.trim().isEmpty) return null;
    return DateTime.tryParse(s.trim());
  }

  Future<void> _pickDate(TextEditingController c) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(c.text) ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) c.text = _dateToString(picked);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _cardNumber.dispose();
    _cardIssued.dispose();
    _cardValid.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final repo = context.read<ReaderRepository>();
    final card = LibraryCard(
      number: _cardNumber.text.trim(),
      issuedAt: _parseDate(_cardIssued.text) ?? DateTime.now(),
      validUntil: _parseDate(_cardValid.text),
    );
    final reader = Reader(
      id: widget.id ?? 0,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      card: card,
    );
    if (widget.isEditing) {
      await repo.update(reader);
    } else {
      await repo.create(reader);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ReaderRepository>();

    if (_loading || _error != null) {
      return Scaffold(
        appBar: AppBar(
            title: Text(
                widget.isEditing ? 'Редактирование читателя' : 'Новый читатель')),
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
          ? 'Редактирование читателя'
          : 'Новый читатель',
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
          name: 'email',
          build: (_) => TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
                labelText: 'Email', border: OutlineInputBorder()),
            validator: V.combine([
              V.required(),
              V.email(),
              V.uniqueEmail(repo, exceptId: widget.id),
            ]),
          ),
        ),
        EntityFormField(
          name: 'phone',
          build: (_) => TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'Телефон', border: OutlineInputBorder()),
            validator: V.combine([V.required(), V.phone()]),
          ),
        ),
        EntityFormField(
          name: 'card_header',
          build: (_) => const Padding(
            padding: EdgeInsets.only(top: 16, bottom: 8),
            child: Text('Читательский билет',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        EntityFormField(
          name: 'cardNumber',
          build: (_) => TextFormField(
            controller: _cardNumber,
            decoration: const InputDecoration(
                labelText: 'Номер билета', border: OutlineInputBorder()),
            validator: V.combine([V.required(), V.length(min: 3, max: 20)]),
          ),
        ),
        EntityFormField(
          name: 'cardIssued',
          build: (_) => TextFormField(
            controller: _cardIssued,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Дата выдачи',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            onTap: () => _pickDate(_cardIssued),
            validator: V.required('Укажите дату выдачи'),
          ),
        ),
        EntityFormField(
          name: 'cardValid',
          build: (_) => TextFormField(
            controller: _cardValid,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Действителен до (необязательно)',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            onTap: () => _pickDate(_cardValid),
          ),
        ),
      ],
    );
  }
}