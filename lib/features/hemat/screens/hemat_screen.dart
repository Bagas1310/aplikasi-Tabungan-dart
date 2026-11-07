import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/hemat_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/hemat_repository.dart';
import '../../../shared/formatters/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/rupiah_input.dart';

class HematScreen extends StatefulWidget {
  const HematScreen({super.key});

  @override
  State<HematScreen> createState() => HematScreenState();
}

class HematScreenState extends State<HematScreen> {
  final _authRepo = AuthRepository();
  final _hematRepo = HematRepository();

  int? _userId;
  HematSummary _summary = const HematSummary();
  List<HematTransactionModel> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _authRepo.getCurrentUser();
    if (user == null) return;
    _userId = user.id;

    final summary = await _hematRepo.getSummary(_userId!);
    final transactions = await _hematRepo.getTransactions(_userId!);

    if (!mounted) return;
    setState(() {
      _summary = summary;
      _transactions = transactions;
      _loading = false;
    });
  }

  void refresh() => _loadData();

  Future<void> _showSetInitialBalanceDialog() async {
    final ctrl = TextEditingController(
      text: _summary.initialBalance > 0 ? '${_summary.initialBalance}' : '',
    );

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Atur Saldo Awal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Masukkan jumlah uang yang ingin Anda jadikan saldo awal untuk dikelola.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              RupiahInput(controller: ctrl, label: 'Nominal Saldo Awal'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final raw = ctrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                    final amount = int.tryParse(raw) ?? 0;
                    if (_userId != null) {
                      await _hematRepo.setInitialBalance(_userId!, amount);
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    }
                  },
                  child: const Text('Simpan Saldo Awal'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (updated == true) _loadData();
  }

  Future<void> _showAddTransactionDialog({
    String defaultType = 'pengeluaran',
  }) async {
    String type = defaultType;
    String category = type == 'pengeluaran' ? 'Makanan' : 'Gaji';
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime date = DateTime.now();

    final incomeCategories = [
      'Gaji',
      'Bonus',
      'Transfer',
      'Penjualan',
      'Lainnya',
    ];
    final expenseCategories = [
      'Makanan',
      'Transport',
      'Belanja',
      'Tagihan',
      'Hiburan',
      'Kesehatan',
      'Lainnya',
    ];

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final categories = type == 'pengeluaran'
                ? expenseCategories
                : incomeCategories;
            if (!categories.contains(category)) {
              category = categories.first;
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Catat Transaksi Harian',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                type = 'pengeluaran';
                                category = 'Makanan';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: type == 'pengeluaran'
                                    ? AppColors.deleteButton.withValues(
                                        alpha: 0.12,
                                      )
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: type == 'pengeluaran'
                                      ? AppColors.deleteButton
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 18,
                                    color: type == 'pengeluaran'
                                        ? AppColors.deleteButton
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Pengeluaran',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: type == 'pengeluaran'
                                          ? AppColors.deleteButton
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                type = 'pemasukan';
                                category = 'Gaji';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: type == 'pemasukan'
                                    ? AppColors.progress.withValues(alpha: 0.12)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: type == 'pemasukan'
                                      ? AppColors.progress
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 18,
                                    color: type == 'pemasukan'
                                        ? AppColors.progress
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Pemasukan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: type == 'pemasukan'
                                          ? AppColors.progress
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    RupiahInput(controller: amountCtrl, label: 'Nominal *'),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: categories.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan (Opsional)',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        'Tanggal: ${DateFormatter.full(date)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: const Text(
                        'Ubah',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setModalState(() => date = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final raw = amountCtrl.text.replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          );
                          final amount = int.tryParse(raw) ?? 0;
                          if (amount <= 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Nominal harus lebih dari 0'),
                              ),
                            );
                            return;
                          }
                          if (_userId != null) {
                            final now = DateTime.now().toIso8601String();
                            final tx = HematTransactionModel(
                              userId: _userId!,
                              type: type,
                              amount: amount,
                              category: category,
                              note: noteCtrl.text.trim().isEmpty
                                  ? null
                                  : noteCtrl.text.trim(),
                              date: date.toIso8601String().substring(0, 10),
                              createdAt: now,
                            );
                            await _hematRepo.insertTransaction(tx);
                            if (ctx.mounted) Navigator.pop(ctx, true);
                          }
                        },
                        child: const Text('Simpan Catatan'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (added == true) _loadData();
  }

  Future<void> _deleteItem(HematTransactionModel tx) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: Text(
          'Yakin ingin menghapus catatan ${tx.note ?? tx.category ?? "transaksi ini"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.deleteButton,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && tx.id != null) {
      await _hematRepo.deleteTransaction(tx.id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSummaryCard(),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showAddTransactionDialog(defaultType: 'pemasukan'),
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.progress,
                      size: 20,
                    ),
                    label: const Text(
                      'Pemasukan',
                      style: TextStyle(color: AppColors.progress),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.progress),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showAddTransactionDialog(defaultType: 'pengeluaran'),
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    label: const Text('Pengeluaran'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deleteButton,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Catatan Harian',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${_transactions.length} Catatan',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_transactions.isEmpty)
            const EmptyState(
              message: 'Belum ada catatan transaksi harian.\nYuk catat pemasukan atau pengeluaranmu!',
              icon: Icons.account_balance_wallet_outlined,
            )
          else
            ..._transactions.map((tx) => _buildTransactionItem(tx)),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: const BoxDecoration(gradient: AppColors.gradient),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BAGASSPACXE - Hemat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Atur saldo awal & kendalikan arus kas harian Anda',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final isNegative = _summary.currentBalance < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sisa Saldo Saat Ini',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              InkWell(
                onTap: _showSetInitialBalanceDialog,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _summary.initialBalance > 0
                            ? 'Ubah Saldo Awal'
                            : 'Set Saldo Awal',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(_summary.currentBalance),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isNegative ? AppColors.deleteButton : AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _summaryColumn(
                  label: 'Saldo Awal',
                  value: CurrencyFormatter.format(_summary.initialBalance),
                  color: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: _summaryColumn(
                  label: 'Pemasukan (+)',
                  value: '+${CurrencyFormatter.format(_summary.totalIncome)}',
                  color: AppColors.progress,
                ),
              ),
              Expanded(
                child: _summaryColumn(
                  label: 'Pengeluaran (-)',
                  value: '-${CurrencyFormatter.format(_summary.totalExpense)}',
                  color: AppColors.deleteButton,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryColumn({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTransactionItem(HematTransactionModel tx) {
    final isIncome = tx.isIncome;
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(tx.date);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return Dismissible(
      key: Key('hemat_tx_${tx.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.deleteButton,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await _deleteItem(tx);
        return false;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.inputBorder.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isIncome
                    ? AppColors.progress.withValues(alpha: 0.12)
                    : AppColors.deleteButton.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncome
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: isIncome ? AppColors.progress : AppColors.deleteButton,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.category ?? (isIncome ? 'Pemasukan' : 'Pengeluaran'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (tx.note != null && tx.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      tx.note!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.full(parsedDate),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}${CurrencyFormatter.format(tx.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isIncome ? AppColors.progress : AppColors.deleteButton,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
