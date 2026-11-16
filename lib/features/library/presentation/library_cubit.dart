import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/content/content_models.dart';
import '../data/library_repository.dart';
import 'load_status.dart';

class LibraryState {
  const LibraryState({
    required this.status,
    this.manifest,
    this.saints = const [],
    this.error,
  });

  final LoadStatus status;
  final ContentManifest? manifest;
  final List<SaintEntry> saints;
  final String? error;
}

/// Loads the book manifest and its saints list (shared by the library home,
/// book overview, and saints list screens).
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this._repository)
      : super(const LibraryState(status: LoadStatus.loading));

  final LibraryRepository _repository;

  Future<void> load() async {
    emit(const LibraryState(status: LoadStatus.loading));
    try {
      final manifest = await _repository.manifest();
      final saints = await _repository.saints();
      if (isClosed) return;
      emit(LibraryState(
        status: saints.isEmpty ? LoadStatus.empty : LoadStatus.loaded,
        manifest: manifest,
        saints: saints,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(LibraryState(status: LoadStatus.error, error: describeError(e)));
    }
  }
}
