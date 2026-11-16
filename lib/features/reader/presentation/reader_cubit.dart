import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/strings.dart';
import '../../../core/content/content_models.dart';
import '../../library/data/library_repository.dart';
import '../../library/presentation/load_status.dart';
import '../domain/editorial.dart';
import '../domain/reader_items.dart';

class ReaderState {
  const ReaderState({
    required this.status,
    this.saint,
    this.section,
    this.items = const [],
    this.initialIndex = 0,
    this.message,
    this.error,
  });

  final LoadStatus status;
  final Saint? saint;
  final Section? section;
  final List<ReaderItem> items;

  /// List index to start at (the anchor paragraph, or 0).
  final int initialIndex;

  /// Text for the empty state.
  final String? message;
  final String? error;
}

/// Loads one section for reading. [paragraphId] is an optional anchor to open
/// at (used later by bookmarks, progress, search and citations).
class ReaderCubit extends Cubit<ReaderState> {
  ReaderCubit(
    this._repository, {
    required this.saintId,
    required this.sectionId,
    this.paragraphId,
    EditorialSource? editorial,
  })  : _editorial = editorial,
        super(const ReaderState(status: LoadStatus.loading));

  final LibraryRepository _repository;
  final String saintId;
  final String sectionId;
  final String? paragraphId;
  final EditorialSource? _editorial;

  Future<void> load() async {
    emit(const ReaderState(status: LoadStatus.loading));
    try {
      final manifest = await _repository.manifest();
      final saint = await _repository.saint(saintId);
      Section? section;
      for (final s in saint.sections) {
        if (s.id == sectionId) section = s;
      }
      if (isClosed) return;
      if (section == null) {
        emit(ReaderState(
          status: LoadStatus.empty,
          saint: saint,
          message: AppStrings.notFound,
        ));
        return;
      }
      if (section.paragraphs.isEmpty) {
        emit(ReaderState(
          status: LoadStatus.empty,
          saint: saint,
          section: section,
          message: AppStrings.emptyParagraphs,
        ));
        return;
      }
      final source = _editorial ??
          (manifest.fixture
              ? const FakeEditorialSource()
              : const NoEditorialSource());
      final items = buildReaderItems(
        saint: saint,
        section: section,
        editorial: source.forSection(saint.id, section.id),
      );
      final anchor = paragraphId == null ? -1 : indexOfParagraph(items, paragraphId!);
      emit(ReaderState(
        status: LoadStatus.loaded,
        saint: saint,
        section: section,
        items: items,
        initialIndex: math.max(0, anchor),
      ));
    } catch (e) {
      if (isClosed) return;
      emit(ReaderState(status: LoadStatus.error, error: describeError(e)));
    }
  }
}
