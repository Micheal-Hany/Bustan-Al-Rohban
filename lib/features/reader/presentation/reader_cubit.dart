import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/strings.dart';
import '../../../core/content/content_models.dart';
import '../../insights/domain/insight.dart';
import '../../library/data/library_repository.dart';
import '../../library/presentation/load_status.dart';
import '../../audio/domain/speech_plan.dart';
import '../domain/editorial.dart';
import '../domain/reader_items.dart';
import '../progress/reading_progress.dart';

class ReaderState {
  const ReaderState({
    required this.status,
    this.saint,
    this.section,
    this.items = const [],
    this.initialIndex = 0,
    this.contentVersion = 1,
    this.insights = const [],
    this.speechPlan = const [],
    this.message,
    this.error,
  });

  final LoadStatus status;
  final Saint? saint;
  final Section? section;
  final List<ReaderItem> items;

  /// List index to start at (the anchor paragraph, or 0).
  final int initialIndex;

  /// Content version of the installed book (saved with bookmarks/progress).
  final int contentVersion;

  /// What reading aloud speaks for this section.
  final List<SpeechSegment> speechPlan;

  /// Insights that may be shown for this section (may be empty).
  final List<Insight> insights;

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
    this.progressLookup,
  })  : _editorial = editorial,
        super(const ReaderState(status: LoadStatus.loading));

  final LibraryRepository _repository;
  final String saintId;
  final String sectionId;
  final String? paragraphId;
  final EditorialSource? _editorial;

  /// Saved progress for a section (used to resume when no anchor is given).
  final Future<ReadingProgress?> Function(String sectionId)? progressLookup;

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
      var anchor = paragraphId == null ? -1 : indexOfParagraph(items, paragraphId!);
      if (paragraphId == null && progressLookup != null) {
        // No explicit anchor: resume where the reader left off.
        final saved = await progressLookup!(section.id);
        if (saved != null) anchor = indexOfParagraph(items, saved.paragraphId);
      }
      final insights = await _repository.insightsFor(saint, section.id);
      if (isClosed) return;
      emit(ReaderState(
        status: LoadStatus.loaded,
        insights: insights,
        speechPlan: buildSpeechPlan(section.paragraphs),
        saint: saint,
        section: section,
        items: items,
        initialIndex: math.max(0, anchor),
        contentVersion: manifest.contentVersion,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(ReaderState(status: LoadStatus.error, error: describeError(e)));
    }
  }
}
