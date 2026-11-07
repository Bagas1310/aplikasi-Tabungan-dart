import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/savings_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/repositories/savings_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/formatters/formatters.dart';
import '../../../shared/widgets/coin_illustration.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/rupiah_input.dart';
import '../../../core/validators/validators.dart';
import 'edit_savings_screen.dart';

class ManageSavingsScreen extends StatefulWidget {
  final int savingsId;
  const ManageSavingsScreen({super.key, required this.savingsId});

  @override
  State<ManageSavingsScreen> createState() => _ManageSavingsScreenState();
}

class _ManageSavingsScreenState extends State<ManageSavingsScreen> {
  final _savingsRepo = SavingsRepository();
  final _txRepo = TransactionRepository();

  SavingsModel? _savings;
  List<TransactionModel> _transactions = [];
  int _selectedTab = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final savings = await _savingsRepo.getSavingsById(widget.savingsId);
    final transactions = await _txRepo.getBySavings(widget.savingsId);
    if (!mounted) return;
    setState(() {
      _savings = savings;
      _transactions = transactions;
      _loading = false;
    });
  }

  Future<void> _showAddFund() async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime txDate = DateTime.now();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMod) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Tambah Dana',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                RupiahInput(
                  controller: amountCtrl,
                  label: 'Nominal',
                  validator: Validators.amount,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: txDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setMod(() => txDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.inputBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${txDate.day.toString().padLeft(2, '0')}/${txDate.month.toString().padLeft(2, '0')}/${txDate.year}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (Opsional)',
                    prefixIcon: Icon(Icons.note_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setMod(() => saving = true);
                            final amount = int.parse(
                              amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
                            );
                            final now = DateTime.now().toIso8601String();
                            await _txRepo.insert(
                              TransactionModel(
                                userId: _savings!.userId,
                                savingsId: widget.savingsId,
                                type: 'setoran',
                                amount: amount,
                                note: noteCtrl.text.isEmpty
                                    ? null
                                    : noteCtrl.text,
                                transactionDate: txDate.toIso8601String(),
                                createdAt: now,
                              ),
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            await _loadData();
                          },
                    child: saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteConfirm() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Tabungan'),
        content: Text(
          'Hapus "${_savings?.name}"?\n\nSeluruh riwayat transaksi terkait akan ikut dihapus. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.deleteButton,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _savingsRepo.delete(widget.savingsId);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _savings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final s = _savings!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.gradient),
        ),
        title: const Text('Kelola Tabungan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(s),
          const SizedBox(height: 16),
          _buildMenuCard(),
          const SizedBox(height: 16),
          _buildTabContent(s),
          const SizedBox(height: 16),
          _buildActionButtons(s),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(SavingsModel s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const CoinIllustration(size: 60),
          const SizedBox(height: 12),
          Text(
            s.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${CurrencyFormatter.format(s.currentAmount)} / ${CurrencyFormatter.format(s.targetAmount)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: s.progressPercent / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              color: AppColors.progress,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${s.progressPercent.toStringAsFixed(1)}% tercapai',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard() {
    final menus = [
      ('Tambah Dana', Icons.add_circle_outline, 0),
      ('Riwayat Transaksi', Icons.history_rounded, 1),
      ('Detail Tabungan', Icons.info_outline, 2),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: menus.map((m) {
          final selected = _selectedTab == m.$3;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (m.$3 == 0) {
                  _showAddFund();
                } else {
                  setState(() => _selectedTab = m.$3);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Icon(
                      m.$2,
                      size: 22,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.$1,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(SavingsModel s) {
    if (_selectedTab == 1) return _buildTransactionHistory();
    if (_selectedTab == 2) return _buildDetail(s);
    return const SizedBox();
  }

  Widget _buildTransactionHistory() {
    if (_transactions.isEmpty) {
      return const EmptyState(
        message: 'Belum ada transaksi',
        icon: Icons.receipt_long_outlined,
      );
    }
    return Column(children: _transactions.map((t) => _txTile(t)).toList());
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isDeposit ? AppColors.progress : AppColors.deleteButton)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
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
                  isDeposit ? 'Setoran' : 'Penarikan',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (t.note != null)
                  Text(
                    t.note!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                Text(
                  DateFormatter.full(date),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isDeposit ? '+' : '-'} ${CurrencyFormatter.format(t.amount)}',
            style: TextStyle(
              color: isDeposit ? AppColors.progress : AppColors.deleteButton,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(SavingsModel s) {
    final rows = [
      ('Nama', s.name),
      ('Kategori', s.category ?? '-'),
      ('Target', CurrencyFormatter.format(s.targetAmount)),
      ('Terkumpul', CurrencyFormatter.format(s.currentAmount)),
      ('Sisa Target', CurrencyFormatter.format(s.remaining)),
      ('Tanggal Mulai', s.startDate),
      if (s.deadline != null) ('Tenggat', s.deadline!),
      if (s.description != null && s.description!.isNotEmpty)
        ('Deskripsi', s.description!),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        row.$1,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.$2,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildActionButtons(SavingsModel s) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.editButton,
              foregroundColor: Colors.black87,
            ),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditSavingsScreen(savings: s),
                ),
              );
              if (updated == true) _loadData();
            },
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deleteButton,
              foregroundColor: Colors.white,
            ),
            onPressed: _deleteConfirm,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Hapus'),
          ),
        ),
      ],
    );
  }
}
