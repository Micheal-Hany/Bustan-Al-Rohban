import 'package:flutter_bloc/flutter_bloc.dart';

/// In-memory reader text size (a multiplier). Persisted in Task 6.
class TextScaleCubit extends Cubit<double> {
  TextScaleCubit() : super(steps[defaultIndex]);

  static const steps = [0.85, 1.0, 1.15, 1.3, 1.5, 1.75, 2.0];
  static const defaultIndex = 1;

  int get _index {
    final i = steps.indexOf(state);
    return i < 0 ? defaultIndex : i;
  }

  bool get canIncrease => _index < steps.length - 1;
  bool get canDecrease => _index > 0;

  void larger() {
    if (canIncrease) emit(steps[_index + 1]);
  }

  void smaller() {
    if (canDecrease) emit(steps[_index - 1]);
  }

  void reset() => emit(steps[defaultIndex]);
}
