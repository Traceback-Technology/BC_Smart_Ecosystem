import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Category filters used on the destination screen.
class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: const [
          CategoryChip(
            text: 'All',
            isSelected: true,
          ),

          SizedBox(width: 12),

          CategoryChip(
            text: 'Buildings',
          ),

          SizedBox(width: 12),

          CategoryChip(
            text: 'Classrooms',
          ),

          SizedBox(width: 12),

          CategoryChip(
            text: 'Offices',
          ),

          SizedBox(width: 12),

          CategoryChip(
            text: 'Parking',
          ),

          SizedBox(width: 12),

          CategoryChip(
            text: 'Cafeteria',
          ),

          SizedBox(width: 12),

          CategoryChip(
            text: 'Residences',
          ),
        ],
      ),
    );
  }
}

/// A single category filter.
class CategoryChip extends StatelessWidget {
  final String text;
  final bool isSelected;

  const CategoryChip({
    super.key,
    required this.text,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isSelected
              ? AppColors.gold
              : AppColors.borderGrey,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}