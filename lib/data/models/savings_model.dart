class SavingsModel {
  final int? id;
  final int userId;
  final String name;
  final String? description;
  final String? category;
  final int targetAmount;
  final String startDate;
  final String? deadline;
  final String createdAt;
  final String updatedAt;

  int currentAmount;

  SavingsModel({
    this.id,
    required this.userId,
    required this.name,
    this.description,
    this.category,
    required this.targetAmount,
    required this.startDate,
    this.deadline,
    required this.createdAt,
    required this.updatedAt,
    this.currentAmount = 0,
  });

  double get progressPercent {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount * 100).clamp(0, 100).toDouble();
  }

  int get remaining => (targetAmount - currentAmount).clamp(0, targetAmount);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'name': name,
    'description': description,
    'category': category,
    'target_amount': targetAmount,
    'start_date': startDate,
    'deadline': deadline,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  factory SavingsModel.fromMap(Map<String, dynamic> map) => SavingsModel(
    id: map['id'] as int,
    userId: map['user_id'] as int,
    name: map['name'] as String,
    description: map['description'] as String?,
    category: map['category'] as String?,
    targetAmount: map['target_amount'] as int,
    startDate: map['start_date'] as String,
    deadline: map['deadline'] as String?,
    createdAt: map['created_at'] as String,
    updatedAt: map['updated_at'] as String,
  );
}

const savingsCategories = [
  'Liburan',
  'Pendidikan',
  'Gadget',
  'Kendaraan',
  'Dana Darurat',
  'Rumah',
  'Lainnya',
];
