import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1769D2);
  static const secondary = Color(0xFF168FD0);
  static const cyan = Color(0xFF28C9D5);
  static const background = Color(0xFFF3F7FC);
  static const card = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF151515);
  static const textSecondary = Color(0xFF6B7280);
  static const progress = Color(0xFF32B8A5);
  static const editButton = Color(0xFFFFC928);
  static const deleteButton = Color(0xFFE53935);
  static const inputBorder = Color(0xFFD5DCE7);

  static const gradient = LinearGradient(
    colors: [primary, secondary, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
