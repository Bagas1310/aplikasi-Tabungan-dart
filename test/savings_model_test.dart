import 'package:flutter_test/flutter_test.dart';
import 'package:bagasspacxe/data/models/savings_model.dart';

void main() {
  group('SavingsModel calculations', () {
    SavingsModel make({required int target, int current = 0}) {
      final s = SavingsModel(
        userId: 1,
        name: 'Test',
        targetAmount: target,
        startDate: '2024-01-01',
        createdAt: '2024-01-01',
        updatedAt: '2024-01-01',
      );
      s.currentAmount = current;
      return s;
    }

    test('progress percent clamped to 0-100', () {
      expect(make(target: 1000, current: 500).progressPercent, 50.0);
      expect(make(target: 1000, current: 1000).progressPercent, 100.0);
      expect(make(target: 1000, current: 1500).progressPercent, 100.0);
      expect(make(target: 1000, current: 0).progressPercent, 0.0);
    });

    test('remaining never negative', () {
      expect(make(target: 1000, current: 500).remaining, 500);
      expect(make(target: 1000, current: 1000).remaining, 0);
      expect(make(target: 1000, current: 1500).remaining, 0);
    });

    test('zero target does not crash', () {
      final s = make(target: 0, current: 0);
      expect(s.progressPercent, 0.0);
    });
  });
}
