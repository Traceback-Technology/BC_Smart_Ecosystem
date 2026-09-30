import 'package:flutter/material.dart';
import 'constants/admin_colours.dart';
import 'dashboard_overview_screen.dart';
import 'live_orders_screen.dart';
import 'inventory_screen.dart';

/// Shell widget providing responsive navigation and scaffolding for the Admin portal.
/// Dynamically toggles between desktop sidebar + header and mobile app bar + bottom nav.
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  // Currently active navigation tab index
  int _selectedIndex = 0;

// Main admin view pages retained via IndexedStack
  final List<Widget> _pages = const [
    DashboardOverviewScreen(),
    LiveOrdersScreen(),
    InventoryScreen(),
  ];

//Main Layout Builder
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768; // Breakpoint checking for mobile view

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: isMobile // Mobile Top App Bar
              ? AppBar(
                  title: const Text('BC WAYS & EATS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  backgroundColor: Theme.of(context).cardColor,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_outlined),
                      onPressed: () {},
                    ),
                  ],
                )
              : null,
          body: Row( //Responsive Main Body Layout
            children: [
              if (!isMobile) _buildSidebar(),
              Expanded(
                child: Column(
                  children: [
                    if (!isMobile) _buildHeader(), // Top Bar Header for Tablet & Desktop screens
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: _pages,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
         
          // Bottom Navigation Bar for Mobile screens
          bottomNavigationBar: isMobile
              ? BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  selectedItemColor: AdminColors.primaryYellow,
                  unselectedItemColor: AdminColors.textGrey,
                  onTap: (index) => setState(() => _selectedIndex = index),
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
                    BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Orders'),
                    BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Inventory'),
                  ],
                )
              : null,
        );
      },
    );
  }

  // ==========================================
  // Desktop Navigation Components
  // ==========================================

  /// Builds the side navigation drawer for desktop and wide screens.
  /// Displays app branding, primary navigation links, and a support section.
  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AdminColors.primaryYellow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('BC', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
              const SizedBox(width: 10),
              RichText(
                text: const TextSpan(
                  text: 'BC WAYS & ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AdminColors.textDark, fontSize: 14),
                  children: [
                    TextSpan(text: 'EATS', style: TextStyle(color: AdminColors.primaryYellow)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildNavItem(0, Icons.grid_view_rounded, 'Dashboard'),
          _buildNavItem(1, Icons.shopping_bag_outlined, 'Live Orders'),
          _buildNavItem(2, Icons.inventory_2_outlined, 'Inventory'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Need Help?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                const Text('Support team is ready to help.', style: TextStyle(color: AdminColors.textGrey, fontSize: 10)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.headset_mic_outlined, size: 14, color: AdminColors.textDark),
                  label: const Text('Support', style: TextStyle(fontSize: 10, color: AdminColors.textDark)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 32),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a clickable navigation item tile for the sidebar.
  /// Highlighted when active based on [index].
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? AdminColors.softYellow : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          leading: Icon(
            icon,
            color: isSelected ? AdminColors.primaryYellow : AdminColors.textGrey,
            size: 18,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isSelected ? AdminColors.textDark : AdminColors.textGrey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          onTap: () => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }

  /// Builds the top header navigation bar for desktop and wide screens.
  ///Includes page title, system notification actions, and admin profile status
  Widget _buildHeader() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Owner Admin Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // User Controls & Actions
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: AdminColors.textGrey),
                onPressed: () {},
              ),
              const VerticalDivider(indent: 16, endIndent: 16),
              const SizedBox(width: 8),
              const CircleAvatar(
                radius: 14,
                backgroundColor: AdminColors.border,
                child: Icon(Icons.person, size: 18, color: AdminColors.textGrey),
              ),
              const SizedBox(width: 8),
              const Text('Thabo M.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}