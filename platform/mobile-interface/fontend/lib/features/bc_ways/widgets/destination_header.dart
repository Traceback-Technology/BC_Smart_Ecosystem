import 'package:flutter/material.dart';
import '../constants/colors.dart';

// Header for the BC Ways destination screen.

// Keeps the branding, page title and notification
// together at the top of the screen.
class DestinationHeader extends StatelessWidget {
  const DestinationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 18,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button
          const Icon(
            Icons.arrow_back,
            size: 30,
            color: AppColors.black,
          ),

          const SizedBox(width: 18),

          // Belgium Campus icon
          Image.asset(
            'assets/images/bc_icon.jpg',
            width: 60,
            height: 60,
          ),

          const SizedBox(width: 16),

          // BC Ways title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'BC ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                      ),
                      TextSpan(
                        text: 'WAYS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 2),

                const Text(
                  'Find Your Destination',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Notification icon
          Stack(
            children: [
              const Icon(
                Icons.notifications_none,
                size: 30,
                color: AppColors.black,
              ),

              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '2',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}