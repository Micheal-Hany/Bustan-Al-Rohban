import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../library/presentation/load_status.dart';
import '../data/search_repository.dart';

enum SearchStatus { idle, building, results, noResults, error }

class SearchState {
  const SearchState({
    required this.status,
    this.query = '',
    this.response,
    this.error,
  });

  final SearchStatus status;
  final String query;
  final SearchResponse? response;
  final String? error;
}

/// Runs searches against the local index. Typing is debounced; submitting
/// searches at once. Late answers to older queries are dropped.
class SearchCubit extends Cubit<SearchState> {
  SearchCubit(
    this._repository, {
    this.debounce = const Duration(milliseconds: 300),
  }) : super(const SearchState(status: SearchStatus.idle));

  final SearchRepository _repository;
  final Duration debounce;
  Timer? _timer;
  int _seq = 0;

  void queryChanged(String query) {
    _timer?.cancel();
    if (query.trim().isEmpty) {
      _seq++;
      emit(const SearchState(status: SearchStatus.idle));
      return;
    }
    _timer = Timer(debounce, () => search(query));
  }

  Future<void> submit(String query) {
    _timer?.cancel();
    return search(query);
  }

  Future<void> retry() => search(state.query);

  Future<void> search(String query) async {
    final seq = ++_seq;
    if (query.trim().isEmpty) {
      emit(const SearchState(status: SearchStatus.idle));
      return;
    }
    if (!_repository.isBuilt) {
      emit(SearchState(status: SearchStatus.building, query: query));
    }
    try {
      final response = await _repository.search(query);
      if (isClosed || seq != _seq) return;
      if (response.tokens.isEmpty) {
        emit(const SearchState(status: SearchStatus.idle));
        return;
      }
      emit(SearchState(
        status: response.total == 0
            ? SearchStatus.noResults
            : SearchStatus.results,
        query: query,
        response: response,
      ));
    } catch (e) {
      if (isClosed || seq != _seq) return;
      emit(SearchState(
        status: SearchStatus.error,
        query: query,
        error: describeError(e),
      ));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
