
import 'package:flutter/material.dart';
import '../../bc_ways/constants/colors.dart';

// This is the BC Eats menu screen where users can browse the real tuckshop items and filter them using the categories on the left.
class BCEatsMenuScreen extends StatefulWidget {
  const BCEatsMenuScreen({super.key});

  @override
  State<BCEatsMenuScreen> createState() => _BCEatsMenuScreenState();
}

class _BCEatsMenuScreenState extends State<BCEatsMenuScreen> {
  String selectedCategory = 'All Items';
  String searchText = '';

  // I kept the categories on the left because we agreed that the vertical layout is cleaner than having the same categories displayed twice.
  final List<String> categories = [
    'All Items',
    'Daily Specials',
    'Sandwiches',
    'Burgers',
    'Hot Dogs',
    'Chips',
    'Drinks',
    'Extras',
  ];

  // These are the real menu items we are using for the BC Eats prototype.
  // The backend team can later connect this list to the actual database.
  final List<MenuItem> menuItems = [
    MenuItem(
      name: 'Wors Roll Special',
      description: 'Wors roll with chips and a 300ml cold drink',
      price: 62.00,
      category: 'Daily Specials',
      image: 'assets/images/wors_roll_special.png',
    ),
    MenuItem(
      name: 'Hot Dog Special',
      description: 'Hot dog with chips and a 300ml cold drink',
      price: 55.00,
      category: 'Daily Specials',
      image: 'assets/images/hot_dog_special.png',
    ),
    MenuItem(
      name: 'Chicken Wrap',
      description: 'Fresh chicken wrap',
      price: 35.00,
      category: 'Daily Specials',
      image: 'assets/images/chicken_wrap.png',
    ),
    MenuItem(
      name: 'Cheese Toasted Sandwich',
      description: 'Toasted sandwich with cheese',
      price: 25.00,
      category: 'Sandwiches',
      image: 'assets/images/cheese_toastie.png',
    ),
    MenuItem(
      name: 'Chilli Cheese Toasted Sandwich',
      description: 'Toasted sandwich with chilli and cheese',
      price: 28.00,
      category: 'Sandwiches',
      image: 'assets/images/chilli_cheese_toastie.png',
    ),
    MenuItem(
      name: 'Tomato Cheese Toasted Sandwich',
      description: 'Toasted sandwich with tomato and cheese',
      price: 28.00,
      category: 'Sandwiches',
      image: 'assets/images/tomato_cheese_toastie.png',
    ),
    MenuItem(
      name: 'Ham Cheese Toasted Sandwich',
      description: 'Toasted sandwich with ham and cheese',
      price: 32.00,
      category: 'Sandwiches',
      image: 'assets/images/ham_cheese_toastie.png',
    ),
    MenuItem(
      name: 'Ham Cheese Tomato Toasted Sandwich',
      description: 'Toasted sandwich with ham, cheese and tomato',
      price: 35.00,
      category: 'Sandwiches',
      image: 'assets/images/ham_cheese_tomato_toastie.png',
    ),
    MenuItem(
      name: 'Bacon Egg Cheese Toasted Sandwich',
      description: 'Toasted sandwich with bacon, egg and cheese',
      price: 38.00,
      category: 'Sandwiches',
      image: 'assets/images/bacon_egg_cheese_toastie.png',
    ),
    MenuItem(
      name: 'Chicken Mayo Sandwich',
      description: 'Toasted sandwich with chicken mayo',
      price: 35.00,
      category: 'Sandwiches',
      image: 'assets/images/chicken_mayo.png',
    ),
    MenuItem(
      name: 'Chicken Burger',
      description: 'Chicken burger',
      price: 40.00,
      category: 'Burgers',
      image: 'assets/images/chicken_burger.png',
    ),
    MenuItem(
      name: 'Beef Burger',
      description: 'Beef burger',
      price: 40.00,
      category: 'Burgers',
      image: 'assets/images/beef_burger.png',
    ),
    MenuItem(
      name: 'Chicken Hot Dog',
      description: 'Chicken hot dog',
      price: 32.00,
      category: 'Hot Dogs',
      image: 'assets/images/chicken_hot_dog.png',
    ),
    MenuItem(
      name: 'Pork Hot Dog',
      description: 'Pork hot dog',
      price: 32.00,
      category: 'Hot Dogs',
      image: 'assets/images/pork_hot_dog.png',
    ),
    MenuItem(
      name: 'Pork Russian Roll',
      description: 'Russian roll',
      price: 30.00,
      category: 'Hot Dogs',
      image: 'assets/images/pork_russian_roll.png',
    ),
    MenuItem(
      name: 'Medium Chips',
      description: 'Medium portion of chips',
      price: 20.00,
      category: 'Chips',
      image: 'assets/images/chips_medium.png',
    ),
    MenuItem(
      name: 'Large Chips',
      description: 'Large portion of chips',
      price: 28.00,
      category: 'Chips',
      image: 'assets/images/chips_large.png',
    ),
    MenuItem(
      name: 'Russian and Chips',
      description: 'Russian with chips',
      price: 35.00,
      category: 'Chips',
      image: 'assets/images/russian_chips.png',
    ),
    MenuItem(
      name: 'Soft Drink',
      description: '330ml soft drink',
      price: 15.00,
      category: 'Drinks',
      image: 'assets/images/coke.png',
    ),
    MenuItem(
      name: 'Coke',
      description: 'Cold soft drink',
      price: 15.00,
      category: 'Drinks',
      image: 'assets/images/coke.png',
    ),
    MenuItem(
      name: 'Coke Zero',
      description: 'Cold soft drink',
      price: 15.00,
      category: 'Drinks',
      image: 'assets/images/coke_zero.png',
    ),
    MenuItem(
      name: 'Fanta',
      description: 'Cold soft drink',
      price: 15.00,
      category: 'Drinks',
      image: 'assets/images/fanta.png',
    ),
    MenuItem(
      name: 'Sprite',
      description: 'Cold soft drink',
      price: 15.00,
      category: 'Drinks',
      image: 'assets/images/sprite.png',
    ),
    MenuItem(
      name: 'Monster',
      description: 'Energy drink',
      price: 30.00,
      category: 'Drinks',
      image: 'assets/images/monster.png',
    ),
    MenuItem(
      name: 'Red Bull',
      description: 'Energy drink',
      price: 30.00,
      category: 'Drinks',
      image: 'assets/images/red_bull.png',
    ),
    MenuItem(
      name: 'Dragon',
      description: 'Energy drink',
      price: 20.00,
      category: 'Drinks',
      image: 'assets/images/dragon.png',
    ),
    MenuItem(
      name: 'Energade',
      description: 'Sports drink',
      price: 18.00,
      category: 'Drinks',
      image: 'assets/images/energade.png',
    ),
    MenuItem(
      name: 'Still Water',
      description: 'Bottled water',
      price: 15.00,
      category: 'Drinks',
      image: 'assets/images/still_water.png',
    ),
    MenuItem(
      name: 'Sparkling Water',
      description: 'Bottled sparkling water',
      price: 18.00,
      category: 'Drinks',
      image: 'assets/images/sparkling_water.png',
    ),
    MenuItem(
      name: 'Extra Cheese',
      description: 'Add extra cheese',
      price: 8.00,
      category: 'Extras',
      image: 'assets/images/extra_cheese.png',
    ),
    MenuItem(
      name: 'Extra Bacon',
      description: 'Add extra bacon',
      price: 12.00,
      category: 'Extras',
      image: 'assets/images/bacon_slices.png',
    ),
    MenuItem(
      name: 'Fried Egg',
      description: 'Add a fried egg',
      price: 8.00,
      category: 'Extras',
      image: 'assets/images/fried_egg.png',
    ),
    MenuItem(
      name: 'Buttered Bread',
      description: 'Bread with butter',
      price: 12.00,
      category: 'Extras',
      image: 'assets/images/buttered_bread.png',
    ),
  ];

  // This filters the menu using both the selected category and search text. It means users can search for an item while still staying in a category.
  List<MenuItem> get filteredItems {
    return menuItems.where((item) {
      final matchesCategory = selectedCategory == 'All Items' ||
          item.category == selectedCategory;

      final matchesSearch = item.name
          .toLowerCase()
          .contains(searchText.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The vertical category menu stays on the left side.
                  _buildDesktopCategoryMenu(),

                  Expanded(
                    child: _buildMenuContent(context),
                  ),
                ],
              ),
            ),

            _buildBottomNavigation(context),
          ],
        ),
      ),
    );
  }

  // This is the header for the BC Eats page, including the logo and cart icon. I kept the header simple so that the menu content remains the main focus.
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 105,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: Row(
        children: [
          Image.asset(
            'assets/images/bc_icon.jpg',
            width: 65,
            height: 65,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.restaurant,
                size: 45,
                color: Colors.black,
              );
            },
          ),

          const SizedBox(width: 14),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'BC ',
                      style: TextStyle(
                        color: AppColors.red,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'EATS',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                'Campus Tuckshop',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          const Spacer(),

          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.shopping_cart_outlined,
              size: 30,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // This is the only category menu we are keeping for now. Users can select a category here, and the menu items will update below.
  Widget _buildDesktopCategoryMenu() {
    return Container(
      width: 215,
      color: Theme.of(context).cardColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),

              onTap: () {
                setState(() {
                  selectedCategory = category;
                });
              },

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),

                decoration: BoxDecoration(
                  color: isSelected ? AppColors.red : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Row(
                  children: [
                    Icon(
                      _categoryIcon(category),
                      color: isSelected
                          ? Colors.white
                          : AppColors.yellow,
                      size: 22,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // The content now only has the search bar and menu items. I removed the horizontal category buttons because the vertical menu already handles the categories.
  Widget _buildMenuContent(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(context),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),

            children: [
              Text(
                selectedCategory,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Fresh meals. Fast service. Made for students.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 18),

              if (filteredItems.isEmpty)
                 Padding(
                  padding: EdgeInsets.all(30),

                  child: Center(
                    child: Text(
                    'No menu items found.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  ),
                )
              else
                ...filteredItems.map((item) => _buildMenuCard(context, item)),
            ],
          ),
        ),
      ],
    );
  }

  // The search bar allows users to find food items without scrolling through the entire menu.
  // The search updates immediately whenever the user types something.
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),

      child: TextField(
        onChanged: (value) {
          setState(() {
            searchText = value;
          });
        },

        decoration: InputDecoration(
          hintText: 'Search menu items...',

          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).hintColor,
          ),

          filled: true,
          fillColor: Theme.of(context).cardColor,

          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // Each menu item is displayed as a card with its image, description, price, and Add button.
  // The real menu images help us see how the final BC Eats screen could look.
  Widget _buildMenuCard(BuildContext context, MenuItem item) {
    return Container(
      height: 185,

      margin: const EdgeInsets.only(bottom: 16),

      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          Container(
            width: 145,
            height: 165,

            padding: const EdgeInsets.all(10),

            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),

            child: Image.asset(
              item.image,

              fit: BoxFit.contain,

              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.fastfood_outlined,
                  color: Colors.grey,
                  size: 55,
                );
              },
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  item.name,

                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  item.description,

                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),

                const Spacer(),

                Row(
                  children: [
                    Text(
                      'R${item.price.toStringAsFixed(2)}',

                      style: const TextStyle(
                        color: AppColors.red,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Spacer(),

                    ElevatedButton.icon(
                      onPressed: () {},

                      icon: const Icon(
                        Icons.add,
                        size: 18,
                      ),

                      label: const Text('Add'),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,

                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // This is the bottom navigation bar for the BC Eats screen. The Menu tab is highlighted because the user is currently viewing the menu.
  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      height: 65,

      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,

        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,

        children: [
          _bottomNavItem(
            context,
            Icons.home_outlined,
            'Home',
            false,
          ),

          _bottomNavItem(
            context,
            Icons.restaurant_menu,
            'Menu',
            true,
          ),

          _bottomNavItem(
            context,
            Icons.shopping_bag_outlined,
            'Orders',
            false,
          ),

          _bottomNavItem(
            context,
            Icons.bookmark_border,
            'Saved',
            false,
          ),

          _bottomNavItem(
            context,
            Icons.person_outline,
            'Profile',
            false,
          ),
        ],
      ),
    );
  }

  // This creates each item in the bottom navigation bar. The selected item uses the BC yellow colour to show which page is active.
  Widget _bottomNavItem(
    BuildContext context,
    IconData icon,
    String label,
    bool selected,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        Icon(
          icon,

          color: selected
              ? AppColors.yellow
              : Colors.grey,

          size: 24,
        ),

        const SizedBox(height: 3),

        Text(
          label,

          style: TextStyle(
            color: selected
                ? AppColors.yellow
                : Colors.grey,

            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // These icons make the categories easier to recognise.
  // Each category has its own icon so the vertical menu does not look too plain.
  IconData _categoryIcon(String category) {
    switch (category) {
      case 'All Items':
        return Icons.fastfood;

      case 'Daily Specials':
        return Icons.local_fire_department_outlined;

      case 'Sandwiches':
        return Icons.lunch_dining;

      case 'Burgers':
        return Icons.lunch_dining_outlined;

      case 'Hot Dogs':
        return Icons.fastfood_outlined;

      case 'Chips':
        return Icons.fastfood;

      case 'Drinks':
        return Icons.local_drink_outlined;

      case 'Extras':
        return Icons.add_circle_outline;

      default:
        return Icons.fastfood;
    }
  }
}

// This model represents one food item in the menu. The backend team can later use a similar structure when connecting the database.
class MenuItem {
  final String name;
  final String description;
  final double price;
  final String category;
  final String image;

  const MenuItem({
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.image,
  });
}