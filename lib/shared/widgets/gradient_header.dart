import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class GradientHeader extends StatelessWidget {
  final double height;
  final Widget? child;

  const GradientHeader({super.key, this.height = 280, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(gradient: AppColors.gradient),
      child: SafeArea(child: child ?? const SizedBox()),
    );
  }
}
