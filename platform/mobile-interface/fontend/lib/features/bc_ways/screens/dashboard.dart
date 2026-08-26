import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


void main() => runApp(const BCSmartApp());

class BCSmartApp extends StatelessWidget {
  const BCSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BC Smart Lifestyle',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: DashboardColors.bgMain, 
      ),
      home: const CampusDashboardPage(), 
    );
  }
}

// --- Reusable Text Style Constants ---
TextStyle get dashboardTextStyle => GoogleFonts.lato(
    textStyle: const TextStyle(
        color: DashboardColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w800));

TextStyle get subtitleTextStyle => GoogleFonts.lato(
    textStyle: const TextStyle(
        color: DashboardColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400));

// --- Reusable Color Constants ---
class DashboardColors {
  static const Color primary = Color(0xFFFFCC00); // The logo yellow
  static const Color bgMain = Color(0xFFF9FAFB); // Light gray background
  static const Color textPrimary = Color(0xFF1F2937); // Dark gray for text
  static const Color textSecondary = Color(0xFF6B7280); // Lighter gray for subtext
  static const Color notificationAlert = Color(0xFFEF4444); // Red for alert

  static const Color waysGradientStart = Color(0xFFF0FDF4); // Very light green/blue tint
  static const Color waysGradientEnd = Color(0xFFFFFFFF);
  static const Color eatsGradientStart = Color(0xFFFEF2F2); // Very light red tint
  static const Color eatsGradientEnd = Color(0xFFFFFFFF);

  static const Color frequentLib = Color(0xFF1E3A8A); // Dark Blue
  static const Color frequentCafe = Color(0xFFB91C1C); // Red
  static const Color frequentSmart = Color(0xFF0369A1); // Blue
  static const Color frequentRecep = Color(0xFFFFD13B); // Yellow
  static const Color frequentGate = Color(0xFF374151); // Gray
}

class CampusDashboardPage extends StatefulWidget {
  const CampusDashboardPage({super.key});

  @override
  State<CampusDashboardPage> createState() => _CampusDashboardPageState();
}

class _CampusDashboardPageState extends State<CampusDashboardPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardColors.bgMain,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Area with Cityscape Background ---
              Stack(
                children: [
                  // Background Cityscape Graphic
                  Positioned(
                    top: 0,
                    right: -20,
                    child: Opacity(
                      opacity: 0.8,
                      child: Image.asset(
                        'assets/images/bg_city.png',
                        height: 160,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  
                  // Top Padding & Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Top Bar: Logo & Bell
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Main Logo Image
                            Image.asset(
                              'assets/images/logo.png',
                              height: 45,
                            ),
                            // Notification Bell
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_none_outlined,
                                      size: 30, color: DashboardColors.textPrimary),
                                  onPressed: () {},
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                        color: DashboardColors.notificationAlert,
                                        shape: BoxShape.circle),
                                    child: const Text('3',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        // Greetings Section
                        Text('Hello, Alex! 👋',
                            style: GoogleFonts.lato(
                                textStyle: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: DashboardColors.textPrimary))),
                        const SizedBox(height: 2),
                        Text('Good morning',
                            style: subtitleTextStyle.copyWith(fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 25),
              
              // --- Main Content Area (Features, Destinations, etc.) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    // Feature Cards (Ways & Eats)
                    Row(
  children: const [
    Expanded(
      child: _FeatureCard(
        title: 'BC WAYS',
        subtitle: 'Navigate Campus',
        gradientStart: DashboardColors.waysGradientStart,
        gradientEnd: DashboardColors.waysGradientEnd,
        borderColor: DashboardColors.primary,
        // CORRECT: Just pass the string path, NOT the Image.asset() widget!
        imageAsset: 'assets/images/ways_map.png', 
        iconData: Icons.arrow_forward,
      ),
    ),
    SizedBox(width: 15),
    Expanded(
      child: _FeatureCard(
        title: 'BC EATS',
        subtitle: 'Order Food',
        gradientStart: DashboardColors.eatsGradientStart,
        gradientEnd: DashboardColors.eatsGradientEnd,
        borderColor: Colors.red,        
        imageAsset: 'assets/images/eats_food.png', 
        iconData: Icons.restaurant,
      ),
    ),
  ],
),
                    const SizedBox(height: 25),
                    
                    // Frequent Destinations
                    const _SectionHeader(title: 'Frequent Destinations'),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: const [
                          _DestinationCard(
                              icon: Icons.local_library_outlined,
                              title: 'Library',
                              time: '3 min',
                              color: DashboardColors.frequentLib),
                          SizedBox(width: 12),
                          _DestinationCard(
                              icon: Icons.restaurant_menu_outlined,
                              title: 'Cafeteria',
                              time: '4 min',
                              color: DashboardColors.frequentCafe),
                          SizedBox(width: 12),
                          _DestinationCard(
                              icon: Icons.cast_for_education_outlined,
                              title: 'Smart Cities',
                              time: '6 min',
                              color: DashboardColors.frequentSmart),
                          SizedBox(width: 12),
                          _DestinationCard(
                              icon: Icons.person_add_alt_1_outlined,
                              title: 'Reception',
                              time: '2 min',
                              color: DashboardColors.frequentRecep),
                          SizedBox(width: 12),
                          _DestinationCard(
                              icon: Icons.door_front_door_outlined,
                              title: 'Main Gate',
                              time: '3 min',
                              color: DashboardColors.frequentGate),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    
                    // Upcoming
                    const _SectionHeader(title: 'Upcoming'),
                    const SizedBox(height: 10),
                    const _UpcomingListItem(
                        icon: Icons.calendar_month_outlined,
                        color: Colors.tealAccent,
                        title: 'Database Systems Lecture',
                        subtitle: 'PSI-204 · 11:00 AM – 12:00 PM',
                        detail: 'Synced with Microsoft Calendar'),
                    const SizedBox(height: 12),
                    const _UpcomingListItem(
                        icon: Icons.airplanemode_on_outlined,
                        color: Colors.amber,
                        title: 'Drone delivery',
                        subtitle: 'Your order is on the way',
                        trailingTime: '10:20 AM',
                        trailingDetail: '30 min',
                        trailingDetailColor: DashboardColors.frequentRecep),
                    const SizedBox(height: 25),
                    
                    // Notifications
                    const _SectionHeader(title: 'Notifications'),
                    const SizedBox(height: 10),
                    const _NotificationListItem(
                      color: DashboardColors.notificationAlert,
                      icon: Icons.report_problem_outlined,
                      title: 'Path blocked ahead',
                      subtitle: 'Rerouting to fastest route',
                      trailingTime: '2 min ago',
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black12, spreadRadius: 1, blurRadius: 10),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined), label: 'Map'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_bag_outlined), label: 'Orders'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.bookmark_outline), label: 'Saved'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: DashboardColors.primary,
            unselectedItemColor: DashboardColors.textSecondary,
            backgroundColor: Colors.white,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: GoogleFonts.lato(
                fontWeight: FontWeight.w800, fontSize: 12),
            unselectedLabelStyle: GoogleFonts.lato(fontSize: 12),
          ),
        ),
      ),
    );
  }
}

// --- Specific Widget Definitions ---

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color gradientStart;
  final Color gradientEnd;
  final Color borderColor;
  final String imageAsset;
  final IconData iconData;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.gradientStart,
    required this.gradientEnd,
    required this.borderColor,
    required this.imageAsset,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientEnd],
        ),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, spreadRadius: 0, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          // Local Image Asset positioned to fit beautifully inside the card
          Positioned(
            bottom: 20,
            right: 0,
            left: 0,
            child: Opacity(
              opacity: 0.9,
              child: Image.asset(
                imageAsset,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          // Card Text
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: dashboardTextStyle.copyWith(fontSize: 18)),
                Text(subtitle, style: subtitleTextStyle),
              ],
            ),
          ),
          
          // Action Button Icon
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: borderColor, shape: BoxShape.circle),
              child: Icon(iconData,
                  color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: dashboardTextStyle.copyWith(fontSize: 18)),
        Text('See all',
            style: subtitleTextStyle.copyWith(
                color: Colors.red, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final Color color;

  const _DestinationCard({
    required this.icon,
    required this.title,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(title,
              style: GoogleFonts.lato(
                  textStyle: TextStyle(
                      color: DashboardColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700))),
          Text(time,
              style: GoogleFonts.lato(
                  textStyle: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class _UpcomingListItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? detail;
  final String? trailingTime;
  final String? trailingDetail;
  final Color? trailingDetailColor;

  const _UpcomingListItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.detail,
    this.trailingTime,
    this.trailingDetail,
    this.trailingDetailColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: dashboardTextStyle.copyWith(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                Text(subtitle, style: subtitleTextStyle.copyWith(fontSize: 12)),
                if (detail != null)
                  Text(detail!,
                      style: subtitleTextStyle.copyWith(
                          fontSize: 11, color: Colors.teal)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (trailingTime != null)
                Text(trailingTime!,
                    style: subtitleTextStyle.copyWith(fontSize: 11)),
              if (trailingDetail != null)
                Text(trailingDetail!,
                    style: GoogleFonts.lato(
                        textStyle: TextStyle(
                            color: trailingDetailColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800))),
              Icon(Icons.chevron_right, color: DashboardColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationListItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String trailingTime;

  const _NotificationListItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.trailingTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: dashboardTextStyle.copyWith(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                Text(subtitle, style: subtitleTextStyle.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Text(trailingTime,
              style: subtitleTextStyle.copyWith(
                  fontSize: 11, color: DashboardColors.notificationAlert, fontWeight: FontWeight.w700)),
          Icon(Icons.chevron_right, color: DashboardColors.textSecondary),
        ],
      ),
    );
  }
}