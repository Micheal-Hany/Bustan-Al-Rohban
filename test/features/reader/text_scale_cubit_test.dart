import 'package:bustan_al_rohban/features/reader/presentation/text_scale_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextScaleCubit', () {
    test('starts at 100%', () {
      final c = TextScaleCubit();
      expect(c.state, 1.0);
      expect(c.canIncrease, isTrue);
      expect(c.canDecrease, isTrue);
    });

    test('larger steps up and stops at the maximum', () {
      final c = TextScaleCubit();
      for (var i = 0; i < 20; i++) {
        c.larger();
      }
      expect(c.state, TextScaleCubit.steps.last);
      expect(c.canIncrease, isFalse);
      c.larger();
      expect(c.state, TextScaleCubit.steps.last);
    });

    test('smaller steps down and stops at the minimum', () {
      final c = TextScaleCubit();
      for (var i = 0; i < 20; i++) {
        c.smaller();
      }
      expect(c.state, TextScaleCubit.steps.first);
      expect(c.canDecrease, isFalse);
    });

    test('steps are increasing and include 1.0', () {
      final s = TextScaleCubit.steps;
      for (var i = 1; i < s.length; i++) {
        expect(s[i], greaterThan(s[i - 1]));
      }
      expect(s, contains(1.0));
    });

    test('reset returns to 100%', () {
      final c = TextScaleCubit()
        ..larger()
        ..larger()
        ..reset();
      expect(c.state, 1.0);
    });
  });
}
