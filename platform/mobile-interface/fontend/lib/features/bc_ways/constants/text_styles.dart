import 'package:flutter/material.dart';
import 'colors.dart';

/// Text styles used throughout the BC Ways feature.
class AppTextStyles {
  AppTextStyles._();

  // Main screen title
  static const TextStyle screenTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  // Section headings
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  // Titles used on cards
  static const TextStyle cardTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  // Smaller text below titles
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    color: AppColors.grey,
  );

  // General body text
  static const TextStyle body = TextStyle(
    fontSize: 15,
    color: AppColors.grey,
  );

  // Used for "See all"
  static const TextStyle seeAll = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.gold,
  );

  // Bottom navigation labels
  static const TextStyle navigation = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}