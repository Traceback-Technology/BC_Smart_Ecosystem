import 'package:flutter/material.dart';

import '../constants/bc_eats_colors.dart';
import 'bc_eats_home_screen.dart';
import 'bc_eats_menu_screen.dart';
import 'orders.dart';

class BCEatsShell extends StatefulWidget {
  const BCEatsShell({super.key});

  @override
  State<BCEatsShell> createState() => _BCEatsShellState();
}

class _BCEatsShellState extends State<BCEatsShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    BCEatsHomeScreen(showBottomNavigation: false),
    BCEatsMenuScreen(showBottomNavigation: false),
    OrdersScreen(showBottomNavigation: false),
  ];

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: theme.colorScheme.surface,
        selectedItemColor: BcEatsColors.yellow,
        unselectedItemColor: theme.colorScheme.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
        ],
      ),
    );
  }
}
