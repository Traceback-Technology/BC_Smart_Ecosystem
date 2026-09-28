
import 'package:flutter/material.dart';
import '../../bc_ways/constants/colors.dart';

// I used the real menu items and images so the prototype gives the team an idea of how the final page could look.
class BCEatsHomeScreen extends StatelessWidget {
  const BCEatsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: _buildHeader(context),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTuckShopStatus(context),

            const SizedBox(height: 24),

            _buildSection(
              context,
              title: "Today's Specials",
              items: [
                _MenuItem(
                  name: 'Wors Roll Special',
                  description: 'Wors roll, chips and a 300ml cold drink',
                  price: 'R62.00',
                  imagePath: 'assets/images/wors_roll_special.png',
                ),
                _MenuItem(
                  name: 'Hot Dog Special',
                  description: 'Hot dog, chips and a 300ml cold drink',
                  price: 'R47.00',
                  imagePath: 'assets/images/hot_dog_special.png',
                ),
                _MenuItem(
                  name: 'Classic Chicken Wrap',
                  description: 'Classic chicken wrap with chips',
                  price: 'R70.00',
                  imagePath: 'assets/images/chicken_wrap.png',
                ),
              ],
            ),

            _buildSection(
              context,
              title: 'Toasted Sandwiches',
              items: [
                _MenuItem(
                  name: 'Cheese',
                  description: 'Toasted cheese sandwich',
                  price: 'R25.00',
                  imagePath: 'assets/images/cheese_toastie.png',
                ),
                _MenuItem(
                  name: 'Chilli Cheese',
                  description: 'Toasted chilli cheese sandwich',
                  price: 'R27.00',
                  imagePath: 'assets/images/chilli_cheese_toastie.png',
                ),
                _MenuItem(
                  name: 'Tomato and Cheese',
                  description: 'Toasted tomato and cheese sandwich',
                  price: 'R27.00',
                  imagePath: 'assets/images/tomato_cheese_toastie.png',
                ),
                _MenuItem(
                  name: 'Ham and Cheese',
                  description: 'Toasted ham and cheese sandwich',
                  price: 'R32.00',
                  imagePath: 'assets/images/ham_cheese_toastie.png',
                ),
                _MenuItem(
                  name: 'Ham, Cheese and Tomato',
                  description: 'Toasted ham, cheese and tomato sandwich',
                  price: 'R37.00',
                  imagePath: 'assets/images/ham_cheese_tomato_toastie.png',
                ),
                _MenuItem(
                  name: 'Bacon, Egg and Cheese',
                  description: 'Toasted bacon, egg and cheese sandwich',
                  price: 'R42.00',
                  imagePath: 'assets/images/bacon_egg_cheese_toastie.png',
                ),
                _MenuItem(
                  name: 'Chicken Mayo',
                  description: 'Toasted chicken mayo sandwich',
                  price: 'R42.00',
                  imagePath: 'assets/images/chicken_mayo.png',
                ),
              ],
            ),

            _buildSection(
              context,
              title: 'Burgers',
              items: [
                _MenuItem(
                  name: 'Chicken Burger',
                  description: 'Chicken burger',
                  price: 'R52.00',
                  imagePath: 'assets/images/chicken_burger.png',
                ),
                _MenuItem(
                  name: 'Beef Burger',
                  description: 'Beef burger',
                  price: 'R57.00',
                  imagePath: 'assets/images/beef_burger.png',
                ),
              ],
            ),

            _buildSection(
              context,
              title: 'Hot Dogs',
              items: [
                _MenuItem(
                  name: 'Chicken Hot Dog',
                  description: 'Chicken hot dog',
                  price: 'R27.00',
                  imagePath: 'assets/images/chicken_hot_dog.png',
                ),
                _MenuItem(
                  name: 'Pork Hot Dog',
                  description: 'Pork hot dog',
                  price: 'R27.00',
                  imagePath: 'assets/images/pork_hot_dog.png',
                ),
                _MenuItem(
                  name: 'Pork Russian Roll',
                  description: 'Pork Russian roll',
                  price: 'R42.00',
                  imagePath: 'assets/images/pork_russian_roll.png',
                ),
              ],
            ),

            _buildSection(
              context,
              title: 'Chips',
              items: [
                _MenuItem(
                  name: 'Medium Chips',
                  description: 'Medium portion of chips',
                  price: 'R17.00',
                  imagePath: 'assets/images/chips_medium.png',
                ),
                _MenuItem(
                  name: 'Large Chips',
                  description: 'Large portion of chips',
                  price: 'R32.00',
                  imagePath: 'assets/images/chips_large.png',
                ),
                _MenuItem(
                  name: 'Russian and Chips',
                  description: 'Russian served with chips',
                  price: 'R50.00',
                  imagePath: 'assets/images/russian_chips.png',
                ),
              ],
            ),

            _buildSection(
              context,
              title: 'Cappuccinos',
              items: [
                _MenuItem(
                  name: 'Handcrafted Cappuccino',
                  description: 'Freshly made cappuccino',
                  price: 'R15.00',
                  imagePath: 'assets/images/cappuccino.png',
                ),
              ],
            ),

            _buildSection(
              context,
              title: 'Extras',
              items: [
                _MenuItem(
                  name: '2 x Cheese',
                  description: 'Extra cheese',
                  price: 'R4.00',
                  imagePath: 'assets/images/extra_cheese.png',
                ),
                _MenuItem(
                  name: 'Fried Egg',
                  description: 'Extra fried egg',
                  price: 'R3.50',
                  imagePath: 'assets/images/fried_egg.png',
                ),
                _MenuItem(
                  name: '2 Slices of Bacon',
                  description: 'Extra bacon',
                  price: 'R10.00',
                  imagePath: 'assets/images/bacon_slices.png',
                ),
                _MenuItem(
                  name: '2 Slices of Buttered Bread',
                  description: 'Extra buttered bread',
                  price: 'R3.00',
                  imagePath: 'assets/images/buttered_bread.png',
                ),
              ],
            ),

            _buildSection(
              context,
              title: 'Soft Drinks',
              items: [
                _MenuItem(
                  name: 'Coke',
                  description: '',
                  price: 'R12.00',
                  imagePath: 'assets/images/coke.png',
                  containImage: true,
                ),
                _MenuItem(
                  name: 'Coke Zero',
                  description: '',
                  price: 'R12.00',
                  imagePath: 'assets/images/coke_zero.png',
                  containImage: true,
                ),
                _MenuItem(
                  name: 'Sprite',
                  description: '',
                  price: 'R12.00',
                  imagePath: 'assets/images/sprite.png',
                  containImage: true,
                ),
                _MenuItem(
                  name: 'Stoney',
                  description: '',
                  price: 'R12.00',
                  imagePath: 'assets/images/stoney.png',
                  containImage: true,
                ),
                _MenuItem(
                  name: "Fanta's",
                  description: '',
                  price: 'R12.00',
                  imagePath: 'assets/images/fanta.png',
                  containImage: true,
                ),
                _MenuItem(
                  name: 'Cream Soda',
                  description: '',
                  price: 'R12.00',
                  imagePath: 'assets/images/cream_soda.png',
                  containImage: true,
                ),
              ],
            ),

            _buildSection(
              context,
              title: 'Energy Drinks',
              items: [
                _MenuItem(
                  name: 'Red Bull',
                  description: '250ml energy drink',
                  price: 'R25.00',
                  imagePath: 'assets/images/red_bull.png',
                  containImage: true,
                ),
                _MenuItem(
                  name: 'Monster',
                  description: '500ml energy drink',
                  price: 'R22.00',
                  imagePath: 'assets/images/monster.png',
                  containImage: true,
                ),
                _MenuItem(
                  name: 'Dragon',
                  description: '500ml energy drink',
                  price: 'R13.00',
                  imagePath: 'assets/images/dragon.png',
                  containImage: true,
                ),
                _MenuItem(
                  name: 'Switch',
                  description: '500ml energy drink',
                  price: 'R13.00',
                  imagePath: 'assets/images/switch.png',
                  containImage: true,
                ),
                _MenuItem(
                  name: 'Energade',
                  description: '500ml energy drink',
                  price: 'R20.00',
                  imagePath: 'assets/images/energade.png',
                  containImage: true,
                ),
              ],
            ),

            _buildSection(
              context,
              title: 'Water',
              items: [
                _MenuItem(
                  name: 'Still Water',
                  description: '500ml still water',
                  price: 'R10.00',
                  imagePath: 'assets/images/still_water.png',
                  containImage: true,
                ),
                _MenuItem(
                  name: 'Sparkling Water',
                  description: '500ml sparkling water',
                  price: 'R10.00',
                  imagePath: 'assets/images/sparkling_water.png',
                  containImage: true,
                ),
                _MenuItem(
                  name: 'Pump Water',
                  description: '750ml water',
                  price: 'R15.00',
                  imagePath: 'assets/images/pump_water.png',
                  containImage: true,
                ),
                _MenuItem(
                  name: 'Flavoured Water',
                  description: '500ml flavoured water',
                  price: 'R15.00',
                  imagePath: 'assets/images/flavoured_water.png',
                  containImage: true,
                ),
              ],
            ),

            _buildSection(
              context,
              title: 'Ice Tea',
              items: [
                _MenuItem(
                  name: 'Ice Tea',
                  description: '500ml ice tea',
                  price: 'R15.00',
                  imagePath: 'assets/images/ice_tea.png',
                  containImage: true,
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // This header keeps the BC Eats branding at the top and gives users access to their profile.
  
  PreferredSizeWidget _buildHeader(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      surfaceTintColor: Theme.of(context).appBarTheme.backgroundColor,
      automaticallyImplyLeading: false,
      toolbarHeight: 88,
      titleSpacing: 20,
      title: Row(
        children: [
          Image.asset(
            'assets/images/bc_icon.jpg',
            width: 58,
            height: 58,
            fit: BoxFit.contain,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: 'BC ',
                        style: TextStyle(color: AppColors.red),
                      ),
                      TextSpan(
                        text: 'EATS',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Campus Tuckshop',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.red,
            child: const Icon(
              Icons.person,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // This shows whether the tuckshop is open and when it closes. We can later connect these hours to backend data instead of keeping them fixed here.
  Widget _buildTuckShopStatus(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 13,
            color: AppColors.green,
          ),
          const SizedBox(width: 7),
          Text(
            'Open now',
            style: TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '• Closes 16:30',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  // Each section groups similar food items, such as burgers, drinks, or toasted sandwiches. The horizontal cards make it possible to browse items without making the homepage too long.
  Widget _buildSection(BuildContext context, {
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                'See all',
                style: TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 285,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildFoodCard(context, items[index]);
            },
          ),
        ),

        const SizedBox(height: 28),
      ],
    );
  }

  // This is the reusable food card used throughout the homepage. It displays the image, name, description, price, and an add button for the item.
  Widget _buildFoodCard(BuildContext context, _MenuItem item) {
    return Container(
      width: 205,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            child: Container(
              height: 125,
              width: double.infinity,
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                item.imagePath,
                fit: item.containImage ? BoxFit.contain : BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.fastfood,
                    color: AppColors.red,
                    size: 48,
                  );
                },
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (item.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 10, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.price,
                  style: TextStyle(
                    color: AppColors.red,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // This bottom navigation gives the user access to the main parts of the app. The Home tab is highlighted because this is the homepage.
  Widget _buildBottomNavigationBar(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Theme.of(context).cardColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              color: Theme.of(context).cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tuck Shop Hours',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Mon–Thu: 08:30–16:30  •  Fri: 08:30–16:00',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                  const Text(
                    'Sat & Public Holidays: 10:00–14:00',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kitchen closes 15 minutes before the shop.',
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: Theme.of(context).dividerColor,
            ),

            SizedBox(
              height: 68,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavigationItem(
                    context,
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: true,
                  ),
                  _buildNavigationItem(
                    context,
                    icon: Icons.map_outlined,
                    label: 'Map',
                  ),
                  _buildNavigationItem(
                    context,
                    icon: Icons.shopping_bag_outlined,
                    label: 'Orders',
                  ),
                  _buildNavigationItem(
                    context,
                    icon: Icons.bookmark_border,
                    label: 'Saved',
                  ),
                  _buildNavigationItem(
                    context,
                    icon: Icons.person_outline,
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // This creates one reusable item for the bottom navigation bar. The selected state changes the colour so users know which page they are on.
  Widget _buildNavigationItem(BuildContext context, {
    required IconData icon,
    required String label,
    bool selected = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: selected ? AppColors.yellow : Colors.grey.shade700,
          size: 25,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.yellow : Colors.grey.shade700,
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// This small model keeps the food information together so each card can reuse the same structure. The backend team can later replace this mock data with information from the database.
class _MenuItem {
  final String name;
  final String description;
  final String price;
  final String imagePath;
  final bool containImage;

  _MenuItem({
    required this.name,
    required this.description,
    required this.price,
    required this.imagePath,
    this.containImage = false,
  });
}