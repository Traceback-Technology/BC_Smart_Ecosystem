import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Shows the locations currently listed in this section.
class BuildingsSection extends StatelessWidget {
  const BuildingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Buildings',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
              ),

              const Text(
                'See all',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const BuildingTile(
          icon: Icons.support_agent,
          iconColor: AppColors.gold,
          title: 'Reception',
          subtitle: 'Main administration & enquiries',
          time: '2 min',
          distance: '150 m',
        ),

        const BuildingTile(
          icon: Icons.menu_book_outlined,
          iconColor: AppColors.teal,
          title: 'Library',
          subtitle: 'Study resources & quiet areas',
          time: '3 min',
          distance: '220 m',
        ),

        const BuildingTile(
          icon: Icons.restaurant,
          iconColor: AppColors.red,
          title: 'Cafeteria',
          subtitle: 'Food, drinks & student meals',
          time: '4 min',
          distance: '280 m',
        ),

        const BuildingTile(
          icon: Icons.apartment,
          iconColor: AppColors.teal,
          title: 'Smart Cities',
          subtitle: 'Innovation & technology hub',
          time: '6 min',
          distance: '420 m',
        ),
      ],
    );
  }
}

/// Card used for each location in the section.
class BuildingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final String distance;

  const BuildingTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 6,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderGrey,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 34,
            color: iconColor,
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                distance,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(width: 10),

          const Icon(
            Icons.chevron_right,
            color: AppColors.grey,
          ),
        ],
      ),
    );
  }
}