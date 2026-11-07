class HematTransactionModel {
  final int? id;
  final int userId;
  final String type; // 'pemasukan' or 'pengeluaran'
  final int amount;
  final String? category;
  final String? note;
  final String date;
  final String createdAt;

  HematTransactionModel({
    this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.category,
    this.note,
    required this.date,
    required this.createdAt,
  });

  bool get isIncome => type == 'pemasukan';

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'type': type,
    'amount': amount,
    'category': category,
    'note': note,
    'date': date,
    'created_at': createdAt,
  };

  factory HematTransactionModel.fromMap(Map<String, dynamic> map) =>
      HematTransactionModel(
        id: map['id'] as int?,
        userId: map['user_id'] as int,
        type: map['type'] as String,
        amount: map['amount'] as int,
        category: map['category'] as String?,
        note: map['note'] as String?,
        date: map['date'] as String,
        createdAt: map['created_at'] as String,
      );
}

class HematSummary {
  final int initialBalance;
  final int totalIncome;
  final int totalExpense;

  const HematSummary({
    this.initialBalance = 0,
    this.totalIncome = 0,
    this.totalExpense = 0,
  });

  int get currentBalance => initialBalance + totalIncome - totalExpense;
}
