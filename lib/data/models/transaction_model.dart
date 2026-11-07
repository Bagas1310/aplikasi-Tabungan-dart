class TransactionModel {
  final int? id;
  final int userId;
  final int savingsId;
  final String type; // 'setoran' or 'penarikan'
  final int amount;
  final String? note;
  final String transactionDate;
  final String createdAt;

  String? savingsName;

  TransactionModel({
    this.id,
    required this.userId,
    required this.savingsId,
    required this.type,
    required this.amount,
    this.note,
    required this.transactionDate,
    required this.createdAt,
    this.savingsName,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'savings_id': savingsId,
    'type': type,
    'amount': amount,
    'note': note,
    'transaction_date': transactionDate,
    'created_at': createdAt,
  };

  factory TransactionModel.fromMap(Map<String, dynamic> map) =>
      TransactionModel(
        id: map['id'] as int,
        userId: map['user_id'] as int,
        savingsId: map['savings_id'] as int,
        type: map['type'] as String,
        amount: map['amount'] as int,
        note: map['note'] as String?,
        transactionDate: map['transaction_date'] as String,
        createdAt: map['created_at'] as String,
        savingsName: map['savings_name'] as String?,
      );
}
