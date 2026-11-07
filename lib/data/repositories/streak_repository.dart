import '../database/database_helper.dart';
import '../models/streak_model.dart';

class StreakRepository {
  final _db = DatabaseHelper.instance;

  Future<StreakModel?> getStreak(int userId) async {
    final db = await _db.database;
    final results = await db.query(
      'streaks',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (results.isEmpty) return null;
    return StreakModel.fromMap(results.first);
  }

  Future<void> updateStreak(int userId) async {
    final db = await _db.database;
    final now = DateTime.now();
    final today = now.toIso8601String().substring(0, 10);

    await db.transaction((txn) async {
      final results = await txn.query(
        'streaks',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (results.isEmpty) {
        await txn.insert('streaks', {
          'user_id': userId,
          'current_streak': 1,
          'last_activity_date': today,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
        return;
      }

      final existing = StreakModel.fromMap(results.first);
      final lastDate = DateTime.parse(existing.lastActivityDate);
      final daysDiff = now.difference(lastDate).inDays;

      if (daysDiff == 0) return;

      final newStreak = daysDiff == 1 ? existing.currentStreak + 1 : 1;

      await txn.update(
        'streaks',
        {
          'current_streak': newStreak,
          'last_activity_date': today,
          'updated_at': now.toIso8601String(),
        },
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    });
  }

  Future<bool> isStreakActiveToday(int userId) async {
    final streak = await getStreak(userId);
    if (streak == null) return false;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return streak.lastActivityDate == today;
  }
}
