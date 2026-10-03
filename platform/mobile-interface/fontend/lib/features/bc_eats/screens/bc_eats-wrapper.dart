import 'package:flutter/material.dart';

// Import the connected screens
import 'bc_eats_home_screen.dart';
import 'bc_eats_menu_screen.dart';
import 'orders.dart';

class BCEatsWrapper extends StatefulWidget {
  const BCEatsWrapper({super.key});

  @override
  State<BCEatsWrapper> createState() => _BCEatsWrapperState();
}

class _BCEatsWrapperState extends State<BCEatsWrapper> {
  int _currentIndex = 0;

  // The list of screens that the BottomNavigationBar will switch between.
  // Update the class names here if Dzanga named her screens differently.
  final List<Widget> _screens = [
    const BCEatsHomeScreen(), // Index 0: Home
    const BCEatsMenuScreen(), // Index 1: Menu
    const OrdersScreen(),     // Index 2: Jimmy's Orders Flow
    const Center(child: Text('Saved Screen placeholder')),   // Index 3
    const Center(child: Text('Profile Screen placeholder')), // Index 4
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      // IndexedStack keeps all screens alive in memory so they don't lose their state (like cart items) when switching tabs.
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: cardColor,
        selectedItemColor: const Color(0xFFFFC107), // Warning yellow
        unselectedItemColor: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_outline), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}