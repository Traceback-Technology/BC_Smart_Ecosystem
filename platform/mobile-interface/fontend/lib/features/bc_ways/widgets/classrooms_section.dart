import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Shows the classrooms on the destination screen.
class ClassroomsSection extends StatelessWidget {
  const ClassroomsSection({super.key});

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
                  'Classrooms',
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

        const ClassroomTile(
          title: 'Classroom IOTA',
          subtitle: 'Block A • Ground Floor',
          time: '5 min',
        ),

        const ClassroomTile(
          title: 'Classroom SIGMA',
          subtitle: 'Block B • First Floor',
          time: '4 min',
        ),

        const ClassroomTile(
          title: 'Classroom ALPHA',
          subtitle: 'Engineering Building',
          time: '6 min',
        ),
      ],
    );
  }
}

/// Card used for each classroom.
class ClassroomTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;

  const ClassroomTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
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
          const Icon(
            Icons.school_outlined,
            color: AppColors.red,
            size: 34,
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
                style: const TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 4),

              const Icon(
                Icons.chevron_right,
                color: AppColors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }
}