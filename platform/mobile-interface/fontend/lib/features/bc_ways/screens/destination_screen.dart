import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/destination_header.dart';
import '../widgets/category_chips.dart';
import '../widgets/popular_destinations.dart';
import '../widgets/buildings_section.dart';
import '../widgets/view_on_map_card.dart';
import '../widgets/classrooms_section.dart';
import '../widgets/bottom_navigation.dart';

/// BC Ways destination screen.
///
/// This screen gives students a quick way to find
/// common campus destinations and browse available locations.
class DestinationScreen extends StatelessWidget {
  const DestinationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            
            // Scrollable page content
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // BC Ways header
                    const DestinationHeader(),

                    const SizedBox(height: 20),

                   
                    // Search bar
                   
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
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
                        child: Row(
                          children: [
                            const SizedBox(width: 18),

                            const Icon(
                              Icons.search,
                              size: 30,
                              color: AppColors.grey,
                            ),

                            const SizedBox(width: 14),

                            const Expanded(
                              child: Text(
                                'Search building, classroom or location',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.grey,
                                ),
                              ),
                            ),

                            Container(
                              height: 35,
                              width: 1,
                              color: AppColors.borderGrey,
                            ),

                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.tune,
                                size: 28,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Category filters
                    const CategoryChips(),

                    const SizedBox(height: 30),

                    // Popular campus destinations
                    const PopularDestinations(),

                    const SizedBox(height: 30),

                    // Campus locations
                    const BuildingsSection(),

                    const SizedBox(height: 20),

                    // Open the full campus map
                    const ViewOnMapCard(),

                    const SizedBox(height: 30),

                    // Classroom locations
                    const ClassroomsSection(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Bottom navigation
            const BCBottomNavigation(),
          ],
        ),
      ),
    );
  }
}