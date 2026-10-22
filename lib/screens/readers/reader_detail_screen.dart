import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/reader.dart';
import '../../repositories/reader_repository.dart';
import '../../widgets/app_scaffold.dart';

class ReaderDetailScreen extends StatelessWidget {
  final int id;
  const ReaderDetailScreen({super.key, required this.id});

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Scaffold(
        appBar: AppBar(title: const Text('Читатель')),
        body: FutureBuilder<Reader?>(
          future: context.read<ReaderRepository>().findById(id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final r = snapshot.data;
            if (r == null) {
              return const Center(child: Text('Читатель не найден'));
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text('${r.firstName} ${r.lastName}',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 16),
                    if (r.isDeleted)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Удалён ${r.deletedAt}',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer)),
                      ),
                    const SizedBox(height: 16),
                    _infoRow('Фамилия', r.lastName, context),
                    _infoRow('Имя', r.firstName, context),
                    _infoRow('Email', r.email, context),
                    _infoRow('Телефон', r.phone, context),
                    const Divider(height: 32),
                    Text('Читательский билет',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _infoRow('Номер', r.card.number, context),
                    _infoRow('Выдан', _fmt(r.card.issuedAt), context),
                    _infoRow(
                        'Действителен до',
                        r.card.validUntil == null
                            ? '—'
                            : _fmt(r.card.validUntil!),
                        context),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: () =>
                              context.go('/readers/${r.id}/edit'),
                          child: const Text('Редактировать'),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: () => context.go('/readers'),
                          child: const Text('Назад к списку'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 160,
              child:
                  Text(label, style: Theme.of(context).textTheme.labelLarge)),
          Expanded(
            child:
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}