class StreakModel {
  final int? id;
  final int userId;
  final int currentStreak;
  final String lastActivityDate;
  final String createdAt;
  final String updatedAt;

  StreakModel({
    this.id,
    required this.userId,
    required this.currentStreak,
    required this.lastActivityDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'current_streak': currentStreak,
    'last_activity_date': lastActivityDate,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  factory StreakModel.fromMap(Map<String, dynamic> map) => StreakModel(
    id: map['id'] as int,
    userId: map['user_id'] as int,
    currentStreak: map['current_streak'] as int,
    lastActivityDate: map['last_activity_date'] as String,
    createdAt: map['created_at'] as String,
    updatedAt: map['updated_at'] as String,
  );
}
