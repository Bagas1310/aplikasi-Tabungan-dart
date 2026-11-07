import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/savings_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/savings_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/formatters/formatters.dart';
import '../../../shared/widgets/empty_state.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => TransactionsScreenState();
}

class TransactionsScreenState extends State<TransactionsScreen> {
  final _authRepo = AuthRepository();
  final _savingsRepo = SavingsRepository();
  final _txRepo = TransactionRepository();

  List<TransactionModel> _transactions = [];
  List<SavingsModel> _savings = [];
  int? _selectedSavingsId;
  String? _selectedType;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _authRepo.getCurrentUser();
    if (user == null) return;
    final savings = await _savingsRepo.getSavings(user.id!);
    final transactions = await _txRepo.getByUser(
      user.id!,
      savingsId: _selectedSavingsId,
      type: _selectedType,
    );
    if (!mounted) return;
    setState(() {
      _savings = savings;
      _transactions = transactions;
      _loading = false;
    });
  }

  void refresh() => _loadData();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            bottom: 20,
          ),
          decoration: const BoxDecoration(gradient: AppColors.gradient),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Riwayat Transaksi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Semua transaksi tabungan Anda',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _savingsFilter()),
              const SizedBox(width: 8),
              Expanded(child: _typeFilter()),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _transactions.isEmpty
              ? const EmptyState(
                  message: 'Belum ada transaksi',
                  icon: Icons.receipt_long_outlined,
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _transactions.length,
                    itemBuilder: (_, i) => _txTile(_transactions[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _savingsFilter() {
    return DropdownButtonFormField<int?>(
      initialValue: _selectedSavingsId,
      decoration: InputDecoration(
        labelText: 'Tabungan',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Semua')),
        ..._savings.map(
          (s) => DropdownMenuItem<int?>(
            value: s.id,
            child: Text(s.name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (v) {
        setState(() => _selectedSavingsId = v);
        _loadData();
      },
    );
  }

  Widget _typeFilter() {
    return DropdownButtonFormField<String?>(
      initialValue: _selectedType,
      decoration: InputDecoration(
        labelText: 'Jenis',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
      ),
      items: const [
        DropdownMenuItem<String?>(value: null, child: Text('Semua')),
        DropdownMenuItem<String?>(value: 'setoran', child: Text('Setoran')),
      ],
      onChanged: (v) {
        setState(() => _selectedType = v);
        _loadData();
      },
    );
  }

  Widget _txTile(TransactionModel t) {
    final isDeposit = t.type == 'setoran';
    final date = DateTime.tryParse(t.transactionDate) ?? DateTime.now();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (isDeposit ? AppColors.progress : AppColors.deleteButton)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isDeposit ? AppColors.progress : AppColors.deleteButton,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.savingsName ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${isDeposit ? 'Setoran' : 'Penarikan'} • ${DateFormatter.full(date)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (t.note != null && t.note!.isNotEmpty)
                  Text(
                    t.note!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '${isDeposit ? '+' : '-'} ${CurrencyFormatter.format(t.amount)}',
            style: TextStyle(
              color: isDeposit ? AppColors.progress : AppColors.deleteButton,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
