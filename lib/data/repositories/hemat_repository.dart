import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/hemat_model.dart';

class HematRepository {
  final _db = DatabaseHelper.instance;

  Future<int> getInitialBalance(int userId) async {
    final db = await _db.database;
    final res = await db.query(
      'hemat_wallets',
      columns: ['initial_balance'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (res.isEmpty) return 0;
    return (res.first['initial_balance'] as int?) ?? 0;
  }

  Future<void> setInitialBalance(int userId, int balance) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    await db.insert('hemat_wallets', {
      'user_id': userId,
      'initial_balance': balance,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<HematTransactionModel>> getTransactions(int userId) async {
    final db = await _db.database;
    final res = await db.query(
      'hemat_transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC, id DESC',
    );
    return res.map((e) => HematTransactionModel.fromMap(e)).toList();
  }

  Future<int> insertTransaction(HematTransactionModel tx) async {
    final db = await _db.database;
    return db.insert('hemat_transactions', tx.toMap());
  }

  Future<void> deleteTransaction(int id) async {
    final db = await _db.database;
    await db.delete('hemat_transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<HematSummary> getSummary(int userId) async {
    final db = await _db.database;
    final initial = await getInitialBalance(userId);

    final res = await db.rawQuery(
      '''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'pemasukan' THEN amount ELSE 0 END), 0) as income,
        COALESCE(SUM(CASE WHEN type = 'pengeluaran' THEN amount ELSE 0 END), 0) as expense
      FROM hemat_transactions
      WHERE user_id = ?
      ''',
      [userId],
    );

    final income = (res.first['income'] as int?) ?? 0;
    final expense = (res.first['expense'] as int?) ?? 0;

    return HematSummary(
      initialBalance: initial,
      totalIncome: income,
      totalExpense: expense,
    );
  }
}
