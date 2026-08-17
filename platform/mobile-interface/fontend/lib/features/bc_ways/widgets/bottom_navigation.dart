import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Bottom navigation used on the BC Ways destination screen.
class BCBottomNavigation extends StatelessWidget {
  const BCBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          BottomNavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            selected: false,
          ),

          BottomNavItem(
            icon: Icons.map,
            label: 'Map',
            selected: true,
          ),

          BottomNavItem(
            icon: Icons.shopping_bag_outlined,
            label: 'Orders',
            selected: false,
          ),

          BottomNavItem(
            icon: Icons.bookmark_border,
            label: 'Saved',
            selected: false,
          ),

          BottomNavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            selected: false,
          ),
        ],
      ),
    );
  }
}

/// One item in the bottom navigation.
class BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const BottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final Color colour =
        selected ? AppColors.gold : AppColors.grey;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 28,
          color: colour,
        ),

        const SizedBox(height: 6),

        Text(
          label,
          style: TextStyle(
            color: colour,
            fontSize: 14,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}