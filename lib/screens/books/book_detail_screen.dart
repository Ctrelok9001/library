import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/reference_data.dart';
import '../../models/book.dart';
import '../../repositories/book_repository.dart';
import '../../widgets/app_scaffold.dart';

class BookDetailScreen extends StatelessWidget {
  final int id;
  const BookDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Scaffold(
        appBar: AppBar(title: const Text('Книга')),
        body: FutureBuilder<Book?>(
          future: context.read<BookRepository>().findById(id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final book = snapshot.data;
            if (book == null) {
              return const Center(child: Text('Книга не найдена'));
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(book.title,
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 16),
                    if (book.isDeleted)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Удалена ${book.deletedAt}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            )),
                      ),
                    const SizedBox(height: 16),
                    _infoRow('ISBN', book.isbn, context),
                    _infoRow('Год издания', '${book.year}', context),
                    _infoRow('Страниц', '${book.pages}', context),
                    _infoRow('Издательство', publisherName(book.publisherId),
                        context),
                    _infoRow('Жанры', book.genreIds.map(genreName).join(', '),
                        context),
                    _infoRow(
                        'Экземпляры',
                        '${book.copiesAvailable} из ${book.copiesTotal}',
                        context),
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
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
