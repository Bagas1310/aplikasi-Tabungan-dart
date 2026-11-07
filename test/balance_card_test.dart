    import 'package:flutter/material.dart';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:fl_chart/fl_chart.dart';
    import 'package:bagasspacxe/core/constants/app_colors.dart';
    import 'package:bagasspacxe/shared/formatters/formatters.dart';

    Widget buildTestChart(List<Map<String, dynamic>> dailyData) {
      const months = [
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

      if (dailyData.isEmpty) {
        return const Center(
          child: Text(
            'Belum ada aktivitas transaksi',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        );
      }

      double maxY = 0;
      for (final row in dailyData) {
        final d = ((row['deposits'] as num?) ?? 0).toDouble();
        if (d > maxY) maxY = d;
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
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.textPrimary.withValues(alpha: 0.9),
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final idx = group.x.toInt();
                if (idx < 0 || idx >= dailyData.length) return null;
                final item = dailyData[idx];
                final dateStr = item['date'] as String? ?? '';
                final parsed = DateTime.tryParse(dateStr);
                final label = parsed != null
                    ? '${parsed.day} ${months[parsed.month - 1]}'
                    : dateStr;
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
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (value != idx.toDouble() ||
                      idx < 0 ||
                      idx >= dailyData.length) {
                    return const SizedBox.shrink();
                  }
                  final dateStr = dailyData[idx]['date'] as String? ?? '';
                  final parsed = DateTime.tryParse(dateStr);
                  final label = parsed != null
                      ? '${parsed.day} ${months[parsed.month - 1]}'
                      : dateStr;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label,
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
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

    void main() {
      testWidgets('Renders empty state when no daily data', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: SizedBox(height: 180, child: buildTestChart([]))),
          ),
        );
        expect(find.text('Belum ada aktivitas transaksi'), findsOneWidget);
      });

      testWidgets('Renders 1 item correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 180,
                child: buildTestChart([
                  {'date': '2026-10-31', 'deposits': 150000, 'withdrawals': 0},
                ]),
              ),
            ),
          ),
        );
        expect(find.text('31 Okt'), findsOneWidget);
      });

      testWidgets('Renders multiple items with specific day and month labels', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 180,
                child: buildTestChart([
                  {'date': '2026-10-25', 'deposits': 50000, 'withdrawals': 0},
                  {'date': '2026-10-28', 'deposits': 100000, 'withdrawals': 0},
                  {'date': '2026-10-29', 'deposits': 75000, 'withdrawals': 0},
                  {'date': '2026-10-30', 'deposits': 200000, 'withdrawals': 0},
                  {'date': '2026-10-31', 'deposits': 150000, 'withdrawals': 0},
                ]),
              ),
            ),
          ),
        );
        expect(find.text('25 Okt'), findsOneWidget);
        expect(find.text('28 Okt'), findsOneWidget);
        expect(find.text('29 Okt'), findsOneWidget);
        expect(find.text('30 Okt'), findsOneWidget);
        expect(find.text('31 Okt'), findsOneWidget);
      });
    }
