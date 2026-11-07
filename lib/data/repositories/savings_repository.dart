import '../database/database_helper.dart';
import '../models/savings_model.dart';

class SavingsRepository {
  final _db = DatabaseHelper.instance;

  Future<List<SavingsModel>> getSavings(int userId) async {
    final db = await _db.database;
    final rows = await db.query(
      'savings',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    final savings = rows.map((r) => SavingsModel.fromMap(r)).toList();

    for (final s in savings) {
      s.currentAmount = await _calcBalance(db, s.id!);
    }
    return savings;
  }

  Future<int> _calcBalance(dynamic db, int savingsId) async {
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(
        SUM(CASE WHEN type = 'setoran' THEN amount ELSE -amount END), 0
      ) as balance FROM transactions WHERE savings_id = ?
    ''',
      [savingsId],
    );
    final balance = (result.first['balance'] as int?) ?? 0;
    return balance < 0 ? 0 : balance;
  }

  Future<SavingsModel> getSavingsById(int id) async {
    final db = await _db.database;
    final rows = await db.query('savings', where: 'id = ?', whereArgs: [id]);
    final s = SavingsModel.fromMap(rows.first);
    s.currentAmount = await _calcBalance(db, s.id!);
    return s;
  }

  Future<int> insert(SavingsModel savings) async {
    final db = await _db.database;
    final id = await db.insert('savings', savings.toMap());
    return id;
  }

  Future<void> update(SavingsModel savings) async {
    final db = await _db.database;
    await db.update(
      'savings',
      savings.toMap(),
      where: 'id = ?',
      whereArgs: [savings.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete(
        'transactions',
        where: 'savings_id = ?',
        whereArgs: [id],
      );
      await txn.delete('savings', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<int> getTotalBalance(int userId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(
        SUM(CASE WHEN t.type = 'setoran' THEN t.amount ELSE -t.amount END), 0
      ) as total
      FROM transactions t
      INNER JOIN savings s ON t.savings_id = s.id
      WHERE s.user_id = ?
    ''',
      [userId],
    );
    final total = (result.first['total'] as int?) ?? 0;
    return total < 0 ? 0 : total;
  }

  Future<int> getActiveSavingsCount(int userId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM savings WHERE user_id = ?',
      [userId],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
