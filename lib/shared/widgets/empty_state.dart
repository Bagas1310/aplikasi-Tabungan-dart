  import 'package:flutter/material.dart';

  import '../../core/constants/app_colors.dart';

  class EmptyState extends StatelessWidget {
    final String message;
    final IconData icon;

    const EmptyState({
      super.key,
      required this.message,
      this.icon = Icons.inbox_rounded,
    });

    @override
    Widget build(BuildContext context) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
