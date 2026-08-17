import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Popular destinations shown on the destination screen.
class PopularDestinations extends StatelessWidget {
  const PopularDestinations({super.key});

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
                  'Popular Destinations',
                  overflow: TextOverflow.ellipsis,
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

        // Destinations students can access quickly.
        SizedBox(
          height: 210,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: const [
              DestinationCard(
                icon: Icons.menu_book_outlined,
                iconColor: AppColors.teal,
                title: 'Library',
                time: '3 min',
              ),

              SizedBox(width: 16),

              DestinationCard(
                icon: Icons.restaurant,
                iconColor: AppColors.red,
                title: 'Cafeteria',
                time: '4 min',
              ),

              SizedBox(width: 16),

              DestinationCard(
                icon: Icons.apartment,
                iconColor: AppColors.teal,
                title: 'Smart Cities',
                time: '6 min',
              ),

              SizedBox(width: 16),

              DestinationCard(
                icon: Icons.support_agent,
                iconColor: AppColors.gold,
                title: 'Reception',
                time: '2 min',
              ),

              SizedBox(width: 16),

              DestinationCard(
                icon: Icons.school_outlined,
                iconColor: AppColors.red,
                title: 'Classroom\nIOTA',
                time: '5 min',
              ),

              SizedBox(width: 16),

              DestinationCard(
                icon: Icons.local_parking_outlined,
                iconColor: AppColors.blue,
                title: 'Student\nParking',
                time: '3 min',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Card used for each popular destination.
class DestinationCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String time;

  const DestinationCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.borderGrey,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              icon,
              size: 42,
              color: iconColor,
            ),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),

            Text(
              time,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}