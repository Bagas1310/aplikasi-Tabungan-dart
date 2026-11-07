import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../dashboard/screens/dashboard_screen.dart';
import '../hemat/screens/hemat_screen.dart';
import '../transactions/screens/transactions_screen.dart';
import '../profile/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _dashKey = GlobalKey<DashboardScreenState>();
  final _hematKey = GlobalKey<HematScreenState>();
  final _txKey = GlobalKey<TransactionsScreenState>();
  final _profileKey = GlobalKey<ProfileScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(key: _dashKey),
      HematScreen(key: _hematKey),
      TransactionsScreen(key: _txKey),
      ProfileScreen(key: _profileKey),
    ];
  }

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
    if (index == 0) _dashKey.currentState?.refresh();
    if (index == 1) _hematKey.currentState?.refresh();
    if (index == 2) _txKey.currentState?.refresh();
    if (index == 3) _profileKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.dashboard_rounded, 'Dashboard'),
                _navItem(1, Icons.account_balance_wallet_rounded, 'Hemat'),
                _navItem(2, Icons.receipt_long_rounded, 'Transaksi'),
                _navItem(3, Icons.person_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
