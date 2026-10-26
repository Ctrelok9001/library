import '../models/author.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../repositories/author_repository.dart';
import '../repositories/genre_repository.dart';
import '../repositories/publisher_repository.dart';

class RefCache {
  final AuthorRepository _authors;
  final GenreRepository _genres;
  final PublisherRepository _publishers;

  RefCache(this._authors, this._genres, this._publishers);

  List<Author>? _authorsList;
  List<Genre>? _genresList;
  List<Publisher>? _publishersList;

  Future<List<Author>> authors() async =>
      _authorsList ??= await _authors.findAll();
  Future<List<Genre>> genres() async =>
      _genresList ??= await _genres.findAll();
  Future<List<Publisher>> publishers() async =>
      _publishersList ??= await _publishers.findAll();

  void invalidate() {
    _authorsList = null;
    _genresList = null;
    _publishersList = null;
  }
}