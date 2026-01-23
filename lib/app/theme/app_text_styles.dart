import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle label = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 13,
  );

  static const TextStyle header = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.02,
  );

  static const TextStyle subtitle = TextStyle(
    color: Colors.white,
    fontSize: 14,
  );

  static const TextStyle link = TextStyle(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w700,
    decoration: TextDecoration.underline,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
}
