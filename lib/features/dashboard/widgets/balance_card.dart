import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/formatters/formatters.dart';

class BalanceCard extends StatelessWidget {
  final int totalBalance;
  final int activeSavings;
  final List<Map<String, dynamic>> dailyData;

  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.activeSavings,
    required this.dailyData,
  });

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Ags',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Saldo',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(totalBalance),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$activeSavings tabungan aktif',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 180, child: _buildChart()),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    final parsed = DateTime.tryParse(dateStr);
    if (parsed != null && parsed.month >= 1 && parsed.month <= 12) {
      return '${parsed.day} ${_months[parsed.month - 1]}';
    }
    return dateStr;
  }

  Widget _buildChart() {
    if (dailyData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 36,
              color: AppColors.inputBorder,
            ),
            SizedBox(height: 8),
            Text(
              'Belum ada aktivitas transaksi',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    double maxY = 0;
    for (final row in dailyData) {
      final v = ((row['deposits'] as num?) ?? 0).toDouble();
      if (v > maxY) maxY = v;
    }
    if (maxY == 0) maxY = 100000;
    final effectiveMaxY = maxY * 1.25;

    final barWidth = dailyData.length == 1
        ? 24.0
        : dailyData.length <= 3
        ? 20.0
        : 14.0;

    return BarChart(
      BarChartData(
        maxY: effectiveMaxY,
        minY: 0,
        alignment: BarChartAlignment.center,
        groupsSpace: 4,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) =>
                AppColors.textPrimary.withValues(alpha: 0.9),
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final idx = group.x.toInt();
              if (idx < 0 || idx >= dailyData.length) return null;
              final dateStr = dailyData[idx]['date'] as String? ?? '';
              final label = _formatDate(dateStr);
              final amount = rod.toY.toInt();
              return BarTooltipItem(
                '$label\n${CurrencyFormatter.format(amount)}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              );
            },
          ),
        ),
        barGroups: List.generate(dailyData.length, (i) {
          final deposit = ((dailyData[i]['deposits'] as num?) ?? 0).toDouble();
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: deposit,
                width: barWidth,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(5),
                ),
                gradient: const LinearGradient(
                  colors: [AppColors.secondary, AppColors.primary],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: effectiveMaxY,
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (value != idx.toDouble() ||
                    idx < 0 ||
                    idx >= dailyData.length) {
                  return const SizedBox.shrink();
                }
                final dateStr = dailyData[idx]['date'] as String? ?? '';
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _formatDate(dateStr),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: effectiveMaxY / 3,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.inputBorder.withValues(alpha: 0.4),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
