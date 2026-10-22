import 'dart:collection';
import 'package:flutter/foundation.dart';

import '../models/reader.dart';
import '../models/page_result.dart';
import '../models/reader_query.dart';
import '../repositories/reader_repository.dart';
import 'load_status.dart';

class ReaderListNotifier extends ChangeNotifier {
  final ReaderRepository _repository;

  ReaderListNotifier(this._repository);

  ReaderQuery _query = const ReaderQuery();
  PageResult<Reader> _result = PageResult<Reader>.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  bool _disposed = false;

  ReaderQuery get query => _query;
  PageResult<Reader> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => UnmodifiableSetView(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    _safeNotify();

    try {
      _result = await _repository.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить список: $e';
      _status = LoadStatus.error;
    }
    _safeNotify();
  }

  Future<void> applyQuery(ReaderQuery next) async {
    if (_query == next) return;
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    _safeNotify();
  }

  void clearSelection() {
    if (_selected.isEmpty) return;
    _selected.clear();
    _safeNotify();
  }

  Future<int> softDeleteSelected() async {
    final count = await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
    return count;
  }

  Future<void> softDelete(int id) async {
    await _repository.softDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repository.hardDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await load();
  }
}