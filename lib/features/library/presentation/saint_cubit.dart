import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/content/content_models.dart';
import '../data/library_repository.dart';
import 'load_status.dart';

class SaintState {
  const SaintState({required this.status, this.saint, this.error});

  final LoadStatus status;
  final Saint? saint;
  final String? error;
}

/// Loads one saint (its sections) on demand.
class SaintCubit extends Cubit<SaintState> {
  SaintCubit(this._repository, this.saintId)
      : super(const SaintState(status: LoadStatus.loading));

  final LibraryRepository _repository;
  final String saintId;

  Future<void> load() async {
    emit(const SaintState(status: LoadStatus.loading));
    try {
      final saint = await _repository.saint(saintId);
      if (isClosed) return;
      emit(SaintState(
        status: saint.sections.isEmpty ? LoadStatus.empty : LoadStatus.loaded,
        saint: saint,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(SaintState(status: LoadStatus.error, error: describeError(e)));
    }
  }
}
