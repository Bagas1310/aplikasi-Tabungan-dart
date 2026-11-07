import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/savings_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/savings_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/streak_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/streak_widget.dart';
import '../widgets/balance_card.dart';
import '../widgets/savings_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final _authRepo = AuthRepository();
  final _savingsRepo = SavingsRepository();
  final _txRepo = TransactionRepository();
  final _streakRepo = StreakRepository();

  UserModel? _user;
  List<SavingsModel> _savings = [];
  int _totalBalance = 0;
  int _activeSavings = 0;
  List<Map<String, dynamic>> _monthlyData = [];
  int _streakDays = 0;
  bool _isStreakActive = false;
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
    final total = await _savingsRepo.getTotalBalance(user.id!);
    final count = await _savingsRepo.getActiveSavingsCount(user.id!);
    final daily = await _txRepo.getDailyAggregation(user.id!, limit: 7);
    final streak = await _streakRepo.getStreak(user.id!);
    final isActive = await _streakRepo.isStreakActiveToday(user.id!);
    if (!mounted) return;
    setState(() {
      _user = user;
      _savings = savings;
      _totalBalance = total;
      _activeSavings = count;
      _monthlyData = daily;
      _streakDays = streak?.currentStreak ?? 0;
      _isStreakActive = isActive;
      _loading = false;
    });
  }

  void refresh() => _loadData();

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
            child: BalanceCard(
              totalBalance: _totalBalance,
              activeSavings: _activeSavings,
              dailyData: _monthlyData,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Tabungan Saya',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_savings.isEmpty)
            const EmptyState(
              message: 'Belum ada tabungan.\nMulai dengan menambah tujuan tabungan baru!',
              icon: Icons.savings_outlined,
            )
          else
            ..._savings.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: SavingsCard(
                  index: entry.key + 1,
                  savings: entry.value,
                  onTap: () async {
                    await Navigator.pushNamed(
                      context,
                      '/manage',
                      arguments: entry.value.id,
                    );
                    _loadData();
                  },
                ),
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.pushNamed(
                  context,
                  '/add-savings',
                  arguments: _user?.id,
                );
                _loadData();
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah Tabungan'),
            ),
          ),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BAGASSPACXE - My Tabungan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Selamat datang, ${_user?.name ?? ''}!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          StreakWidget(streakDays: _streakDays, isActiveToday: _isStreakActive),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tidak ada notifikasi baru')),
              );
            },
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}
