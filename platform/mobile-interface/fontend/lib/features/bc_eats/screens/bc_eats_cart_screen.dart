import 'package:flutter/material.dart';
import '../../bc_ways/constants/colors.dart';

// This is the BC Eats cart screen where users review their selected food before checkout..
class BCEatsCartScreen extends StatefulWidget {
  const BCEatsCartScreen({super.key});

  @override
  State<BCEatsCartScreen> createState() => _BCEatsCartScreenState();
}

class _BCEatsCartScreenState extends State<BCEatsCartScreen> {
  // Temporary cart items for the prototype. The backend team can later replace this with real cart data.
  final List<CartItemData> cartItems = [
    CartItemData(
      name: 'Wors Roll Special',
      description: 'Wors roll with chips and a cold drink',
      price: 62.00,
      quantity: 1,
      image: 'assets/images/wors_roll_special.png',
    ),
    CartItemData(
      name: 'Chicken Wrap',
      description: 'Fresh chicken wrap',
      price: 35.00,
      quantity: 1,
      image: 'assets/images/chicken_wrap.png',
    ),
    CartItemData(
      name: 'Coca-Cola',
      description: '330ml soft drink',
      price: 15.00,
      quantity: 1,
      image: 'assets/images/coke.png',
    ),
  ];

  // Temporary values until the backend team provides the official fees.
  final double serviceFee = 5.00;
  final double deliveryFee = 15.00;

  String deliveryLocation = 'Main Campus';
  String deliveryTime = '20–30 min';
  String specialInstructions = '';

  double get subtotal {
    // We calculate the subtotal locally for now.
    return cartItems.fold(
      0,
      (total, item) => total + (item.price * item.quantity),
    );
  }

  double get total {
    // The final total will later use the official backend fee rules.
    return subtotal + serviceFee + deliveryFee;
  }

  int get totalItems {
    return cartItems.fold(
      0,
      (total, item) => total + item.quantity,
    );
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
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  _buildCartTitle(context),
                  SizedBox(height: 18),
                  if (cartItems.isEmpty)
                    _buildEmptyCart(context)
                  else ...[
                    ...cartItems.map((item) => _buildCartItem(context, item)),
                    SizedBox(height: 8),
                    _buildSpecialInstructions(context),
                    SizedBox(height: 20),
                    _buildOrderSummary(context),
                    SizedBox(height: 16),
                    _buildDeliveryCard(context),
                    SizedBox(height: 20),
                    _buildCheckoutButtons(context),
                  ],
                ],
              ),
            ),
            _buildBottomNavigation(context),
          ],
        ),
      ),
    );
  }

  // This header shows the BC Eats branding, a back button, and the number of items in the cart. The back navigation can be connected when all the screens are integrated.
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 105,
      padding: EdgeInsets.symmetric(horizontal: 24),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              // Navigation will be connected when the screens are integrated.
            },
            icon: Icon(
              Icons.arrow_back,
              size: 30,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(width: 4),
          Image.asset(
            'assets/images/bc_icon.jpg',
            width: 58,
            height: 58,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.restaurant,
                size: 42,
                color: Theme.of(context).colorScheme.onSurface,
              );
            },
          ),
          SizedBox(width: 12),
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
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'EATS',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 25,
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
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 30,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              if (totalItems > 0)
                Positioned(
                  right: -8,
                  top: -10,
                  child: Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$totalItems',
                      style: TextStyle(
                        color: Theme.of(context).cardColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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

  // This section shows the cart title and gives the user an option to clear everything. Clearing the cart currently only changes the local prototype data.
  Widget _buildCartTitle(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Your Cart ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: '($totalItems)',
                      style: TextStyle(
                        color: AppColors.red,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Review your items before checkout.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        if (cartItems.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                // This clears the local prototype cart.
                cartItems.clear();
              });
            },
            icon: Icon(
              Icons.delete_outline,
              color: AppColors.red,
            ),
            label: Text(
              'Clear Cart',
              style: TextStyle(color: AppColors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
      ],
    );
  }

  // This reusable card displays each selected item, its quantity, and the quantity controls.
  // The backend can later connect these actions to the real cart and stock information.
  Widget _buildCartItem(BuildContext context, CartItemData item) {
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 105,
            height: 125,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset(
              item.image,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.fastfood_outlined,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  size: 45,
                );
              },
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          // This removes the item from the local cart.
                          cartItems.remove(item);
                        });
                      },
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppColors.red,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'R${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.red,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    _buildQuantityControls(item),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControls(CartItemData item) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                // The quantity currently changes only in local state.
                if (item.quantity > 1) {
                  item.quantity--;
                }
              });
            },
            icon: Icon(Icons.remove, size: 18),
            padding: EdgeInsets.symmetric(horizontal: 8),
            constraints: BoxConstraints(),
          ),
          Text(
            '${item.quantity}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                // The backend team can later handle quantity validation.
                item.quantity++;
              });
            },
            icon: Icon(
              Icons.add,
              size: 18,
              color: AppColors.red,
            ),
            padding: EdgeInsets.symmetric(horizontal: 8),
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // Users can add special instructions here, such as requests about their order.
  
  Widget _buildSpecialInstructions(BuildContext context) {
    return InkWell(
      onTap: _showSpecialInstructionsDialog,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Color(0xFFFFE8E8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: AppColors.red,
                size: 26,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Special Instructions',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    specialInstructions.isEmpty
                        ? 'Add any notes (optional)'
                        : specialInstructions,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 28),
          ],
        ),
      ),
    );
  }

  Future<void> _showSpecialInstructionsDialog() async {
    final controller = TextEditingController(
      text: specialInstructions,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Special Instructions'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Add a note for the tuckshop...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // This note is stored locally until order integration exists.
                  specialInstructions = controller.text.trim();
                });
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  // This summary shows the subtotal, service fee, delivery fee, and final total.
  // The fees are temporary values for the prototype and can later come from the backend.
  Widget _buildOrderSummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Summary',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _summaryRow(
                'Subtotal ($totalItems items)',
                subtotal,
              ),
              SizedBox(height: 12),
              _summaryRow('Service Fee', serviceFee),
              SizedBox(height: 12),
              _summaryRow('Delivery Fee', deliveryFee),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'R${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 16,
          ),
        ),
        Text(
          'R${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // This card lets users see and change where their order should be delivered.
  // The available locations are mock options for now, but the flow shows how it could work.
  Widget _buildDeliveryCard(BuildContext context) {
    return InkWell(
      onTap: _showDeliveryLocationDialog,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Color(0xFFE3FAF1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delivery_dining,
                color: AppColors.green,
                size: 28,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deliver to: $deliveryLocation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '$deliveryTime  •  R${deliveryFee.toStringAsFixed(2)} delivery fee',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Change',
              style: TextStyle(
                color: AppColors.red,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.red,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeliveryLocationDialog() async {
    final locations = [
      'Main Campus',
      'Pickup at Tuckshop',
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Choose delivery location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: locations.map((location) {
              return ListTile(
                title: Text(location),
                trailing: location == deliveryLocation
                    ? Icon(
                        Icons.check,
                        color: AppColors.red,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    // This only updates the prototype screen for now.
                    deliveryLocation = location;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // These buttons demonstrate the checkout and scheduling actions.
  // The real payment and order scheduling process will be connected later by the backend team.
  Widget _buildCheckoutButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () {
              // The backend/payment team will connect the real checkout flow.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Checkout integration will be connected later.',
                  ),
                ),
              );
            },
            icon: Icon(Icons.arrow_forward, color: Colors.black),
            label: Text(
              'Proceed to Checkout',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Scheduling will be connected once the order flow is ready.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Scheduling will be added later.'),
                ),
              );
            },
            icon: Icon(
              Icons.calendar_month_outlined,
              color: AppColors.yellow,
            ),
            label: Text(
              'Schedule',
              style: TextStyle(
                color: AppColors.yellow,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 18),
              side: BorderSide(color: AppColors.yellow),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // This is the empty-cart state shown when the user removes all their items. It gives the user a simple message instead of leaving the page blank.
  Widget _buildEmptyCart(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 70),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 75,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add something delicious from BC Eats.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // This bottom navigation keeps the main app sections visible from the cart screen.
  // Orders is highlighted here because the user is currently reviewing an order.
  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _bottomNavItem(context, Icons.home_outlined, 'Home', false),
          _bottomNavItem(context, Icons.restaurant_menu, 'Menu', false),
          _bottomNavItem(context, Icons.shopping_bag, 'Orders', true),
          _bottomNavItem(context, Icons.bookmark_border, 'Saved', false),
          _bottomNavItem(context, Icons.person_outline, 'Profile', false),
        ],
      ),
    );
  }

  // This creates one reusable item for the bottom navigation bar.
  // The selected state changes the colour so the active section is easy to identify.
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
          color: selected ? AppColors.yellow : Theme.of(context).hintColor,
          size: 24,
        ),
        SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.yellow : Theme.of(context).hintColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// This is a small local model for the cart prototype. The backend team can later replace it with the real cart model.
class CartItemData {
  final String name;
  final String description;
  final double price;
  final String image;
  int quantity;

  CartItemData({
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.image,
  });
}