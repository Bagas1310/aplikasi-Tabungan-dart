import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/savings_model.dart';
import '../../../shared/formatters/formatters.dart';

class SavingsCard extends StatelessWidget {
  final int index;
  final SavingsModel savings;
  final VoidCallback? onTap;

  const SavingsCard({
    super.key,
    required this.index,
    required this.savings,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '$index',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    savings.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${CurrencyFormatter.format(savings.currentAmount)} / ${CurrencyFormatter.format(savings.targetAmount)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: savings.progressPercent / 100,
                            backgroundColor: AppColors.progress.withValues(
                              alpha: 0.15,
                            ),
                            color: AppColors.progress,
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${savings.progressPercent.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: AppColors.progress,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
