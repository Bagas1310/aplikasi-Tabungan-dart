import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import 'streak_repository.dart';

class TransactionRepository {
  final _db = DatabaseHelper.instance;
  final _streakRepo = StreakRepository();

  Future<int> insert(TransactionModel transaction) async {
    final db = await _db.database;
    final id = await db.insert('transactions', transaction.toMap());
    if (transaction.type == 'setoran') {
      await _streakRepo.updateStreak(transaction.userId);
    }
    return id;
  }

  Future<List<TransactionModel>> getBySavings(int savingsId) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT t.*, s.name as savings_name
      FROM transactions t
      INNER JOIN savings s ON t.savings_id = s.id
      WHERE t.savings_id = ?
      ORDER BY t.transaction_date DESC, t.id DESC
    ''',
      [savingsId],
    );
    return rows.map((r) => TransactionModel.fromMap(r)).toList();
  }

  Future<List<TransactionModel>> getByUser(
    int userId, {
    int? savingsId,
    String? type,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _db.database;
    var where = 't.user_id = ?';
    final args = <dynamic>[userId];

    if (savingsId != null) {
      where += ' AND t.savings_id = ?';
      args.add(savingsId);
    }
    if (type != null && type.isNotEmpty) {
      where += ' AND t.type = ?';
      args.add(type);
    }
    if (from != null) {
      where += ' AND t.transaction_date >= ?';
      args.add(from.toIso8601String().substring(0, 10));
    }
    if (to != null) {
      where += ' AND t.transaction_date <= ?';
      args.add('${to.toIso8601String().substring(0, 10)}T23:59:59');
    }

    final rows = await db.rawQuery('''
      SELECT t.*, s.name as savings_name
      FROM transactions t
      INNER JOIN savings s ON t.savings_id = s.id
      WHERE $where
      ORDER BY t.transaction_date DESC, t.id DESC
    ''', args);
    return rows.map((r) => TransactionModel.fromMap(r)).toList();
  }

  Future<List<Map<String, dynamic>>> getMonthlyAggregation(
    int userId,
    int year,
  ) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT 
        CAST(strftime('%m', t.transaction_date) AS INTEGER) as month,
        SUM(CASE WHEN t.type = 'setoran' THEN t.amount ELSE 0 END) as deposits,
        SUM(CASE WHEN t.type = 'penarikan' THEN t.amount ELSE 0 END) as withdrawals
      FROM transactions t
      INNER JOIN savings s ON t.savings_id = s.id
      WHERE s.user_id = ? AND strftime('%Y', t.transaction_date) = ?
      GROUP BY month
      ORDER BY month
    ''',
      [userId, year.toString()],
    );
    return rows;
  }

  Future<List<Map<String, dynamic>>> getDailyAggregation(
    int userId, {
    int limit = 7,
  }) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT 
        substr(t.transaction_date, 1, 10) as date,
        SUM(CASE WHEN t.type = 'setoran' THEN t.amount ELSE 0 END) as deposits,
        SUM(CASE WHEN t.type = 'penarikan' THEN t.amount ELSE 0 END) as withdrawals
      FROM transactions t
      INNER JOIN savings s ON t.savings_id = s.id
      WHERE s.user_id = ?
      GROUP BY date
      ORDER BY date DESC
      LIMIT ?
    ''',
      [userId, limit],
    );
    return rows.reversed.toList();
  }
}
