import 'package:flutter/material.dart';

class StreakWidget extends StatelessWidget {
  final int streakDays;
  final bool isActiveToday;

  const StreakWidget({
    super.key,
    required this.streakDays,
    required this.isActiveToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🔥',
            style: TextStyle(
              fontSize: 20,
              color: isActiveToday
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$streakDays',
            style: TextStyle(
              color: isActiveToday
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            'hari',
            style: TextStyle(
              color: isActiveToday
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
