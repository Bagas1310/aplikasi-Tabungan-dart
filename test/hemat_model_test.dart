  import 'package:flutter_test/flutter_test.dart';
  import 'package:bagasspacxe/data/models/hemat_model.dart';

  void main() {
    group('HematModel calculations & tests', () {
      test('HematSummary currentBalance calculated accurately', () {
        const summary = HematSummary(
          initialBalance: 1000000,
          totalIncome: 500000,
          totalExpense: 300000,
        );
        expect(summary.currentBalance, 1200000);
      });

      test(
        'HematSummary with zero initial balance and expenses can be negative',
        () {
          const summary = HematSummary(
            initialBalance: 0,
            totalIncome: 100000,
            totalExpense: 250000,
          );
          expect(summary.currentBalance, -150000);
        },
      );

      test('HematTransactionModel fromMap and toMap serialize correctly', () {
        final tx = HematTransactionModel(
          id: 1,
          userId: 10,
          type: 'pengeluaran',
          amount: 50000,
          category: 'Makanan',
          note: 'Beli makan siang',
          date: '2026-10-29',
          createdAt: '2026-10-29T12:00:00.000',
        );

        final map = tx.toMap();
        expect(map['id'], 1);
        expect(map['user_id'], 10);
        expect(map['type'], 'pengeluaran');
        expect(map['amount'], 50000);
        expect(map['category'], 'Makanan');

        final fromMap = HematTransactionModel.fromMap(map);
        expect(fromMap.id, 1);
        expect(fromMap.userId, 10);
        expect(fromMap.isIncome, false);
        expect(fromMap.amount, 50000);
      });
    });
  }
