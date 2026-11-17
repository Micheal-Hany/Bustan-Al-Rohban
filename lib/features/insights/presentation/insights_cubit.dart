import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/content/content_models.dart';
import '../../library/data/library_repository.dart';
import '../../library/presentation/load_status.dart';
import '../domain/insight.dart';

class InsightsState {
  const InsightsState({
    required this.status,
    this.saint,
    this.section,
    this.insights = const [],
    this.error,
  });

  final LoadStatus status;
  final Saint? saint;
  final Section? section;
  final List<Insight> insights;
  final String? error;
}

class InsightsCubit extends Cubit<InsightsState> {
  InsightsCubit(this._repository,
      {required this.saintId, required this.sectionId})
      : super(const InsightsState(status: LoadStatus.loading));

  final LibraryRepository _repository;
  final String saintId;
  final String sectionId;

  Future<void> load() async {
    emit(const InsightsState(status: LoadStatus.loading));
    try {
      final saint = await _repository.saint(saintId);
      Section? section;
      for (final s in saint.sections) {
        if (s.id == sectionId) section = s;
      }
      if (isClosed) return;
      if (section == null) {
        emit(InsightsState(status: LoadStatus.empty, saint: saint));
        return;
      }
      final insights = await _repository.insightsFor(saint, sectionId);
      if (isClosed) return;
      emit(InsightsState(
        status: insights.isEmpty ? LoadStatus.empty : LoadStatus.loaded,
        saint: saint,
        section: section,
        insights: insights,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(InsightsState(status: LoadStatus.error, error: describeError(e)));
    }
  }
}
