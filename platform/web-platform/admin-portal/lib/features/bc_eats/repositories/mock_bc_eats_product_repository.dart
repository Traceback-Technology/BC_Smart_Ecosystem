import '../models/bc_eats_product.dart';
import 'bc_eats_product_repository.dart';

/// Temporary development product source.
///
/// These values come from the current BC Eats Menu prototype only so that
/// the frontend can work before the real backend is connected.
///
/// In production, product names, prices and availability must come from the
/// tuckshop admin/backend.
class MockBcEatsProductRepository implements BcEatsProductRepository {
  MockBcEatsProductRepository._();

  static final MockBcEatsProductRepository instance =
      MockBcEatsProductRepository._();

  final List<BcEatsProduct> _products = const [
    BcEatsProduct(
      id: 'wors-roll-special',
      name: 'Wors Roll Special',
      description: 'Wors roll with chips and a 300ml cold drink',
      price: 62.00,
      category: 'Daily Specials',
      imagePath: 'assets/images/wors_roll_special.png',
    ),
    BcEatsProduct(
      id: 'hot-dog-special',
      name: 'Hot Dog Special',
      description: 'Hot dog with chips and a 300ml cold drink',
      price: 55.00,
      category: 'Daily Specials',
      imagePath: 'assets/images/hot_dog_special.png',
    ),
    BcEatsProduct(
      id: 'chicken-wrap',
      name: 'Chicken Wrap',
      description: 'Fresh chicken wrap',
      price: 35.00,
      category: 'Daily Specials',
      imagePath: 'assets/images/chicken_wrap.png',
    ),
    BcEatsProduct(
      id: 'cheese-toasted-sandwich',
      name: 'Cheese Toasted Sandwich',
      description: 'Toasted sandwich with cheese',
      price: 25.00,
      category: 'Sandwiches',
      imagePath: 'assets/images/cheese_toastie.png',
    ),
    BcEatsProduct(
      id: 'chilli-cheese-toasted-sandwich',
      name: 'Chilli Cheese Toasted Sandwich',
      description: 'Toasted sandwich with chilli and cheese',
      price: 28.00,
      category: 'Sandwiches',
      imagePath: 'assets/images/chilli_cheese_toastie.png',
    ),
    BcEatsProduct(
      id: 'tomato-cheese-toasted-sandwich',
      name: 'Tomato Cheese Toasted Sandwich',
      description: 'Toasted sandwich with tomato and cheese',
      price: 28.00,
      category: 'Sandwiches',
      imagePath: 'assets/images/tomato_cheese_toastie.png',
    ),
    BcEatsProduct(
      id: 'ham-cheese-toasted-sandwich',
      name: 'Ham Cheese Toasted Sandwich',
      description: 'Toasted sandwich with ham and cheese',
      price: 32.00,
      category: 'Sandwiches',
      imagePath: 'assets/images/ham_cheese_toastie.png',
    ),
    BcEatsProduct(
      id: 'ham-cheese-tomato-toasted-sandwich',
      name: 'Ham Cheese Tomato Toasted Sandwich',
      description: 'Toasted sandwich with ham, cheese and tomato',
      price: 35.00,
      category: 'Sandwiches',
      imagePath: 'assets/images/ham_cheese_tomato_toastie.png',
    ),
    BcEatsProduct(
      id: 'bacon-egg-cheese-toasted-sandwich',
      name: 'Bacon Egg Cheese Toasted Sandwich',
      description: 'Toasted sandwich with bacon, egg and cheese',
      price: 38.00,
      category: 'Sandwiches',
      imagePath: 'assets/images/bacon_egg_cheese_toastie.png',
    ),
    BcEatsProduct(
      id: 'chicken-mayo-sandwich',
      name: 'Chicken Mayo Sandwich',
      description: 'Toasted sandwich with chicken mayo',
      price: 35.00,
      category: 'Sandwiches',
      imagePath: 'assets/images/chicken_mayo.png',
    ),
    BcEatsProduct(
      id: 'chicken-burger',
      name: 'Chicken Burger',
      description: 'Chicken burger',
      price: 40.00,
      category: 'Burgers',
      imagePath: 'assets/images/chicken_burger.png',
    ),
    BcEatsProduct(
      id: 'beef-burger',
      name: 'Beef Burger',
      description: 'Beef burger',
      price: 40.00,
      category: 'Burgers',
      imagePath: 'assets/images/beef_burger.png',
    ),
    BcEatsProduct(
      id: 'chicken-hot-dog',
      name: 'Chicken Hot Dog',
      description: 'Chicken hot dog',
      price: 32.00,
      category: 'Hot Dogs',
      imagePath: 'assets/images/chicken_hot_dog.png',
    ),
    BcEatsProduct(
      id: 'pork-hot-dog',
      name: 'Pork Hot Dog',
      description: 'Pork hot dog',
      price: 32.00,
      category: 'Hot Dogs',
      imagePath: 'assets/images/pork_hot_dog.png',
    ),
    BcEatsProduct(
      id: 'pork-russian-roll',
      name: 'Pork Russian Roll',
      description: 'Russian roll',
      price: 30.00,
      category: 'Hot Dogs',
      imagePath: 'assets/images/pork_russian_roll.png',
    ),
    BcEatsProduct(
      id: 'medium-chips',
      name: 'Medium Chips',
      description: 'Medium portion of chips',
      price: 20.00,
      category: 'Chips',
      imagePath: 'assets/images/chips_medium.png',
    ),
    BcEatsProduct(
      id: 'large-chips',
      name: 'Large Chips',
      description: 'Large portion of chips',
      price: 28.00,
      category: 'Chips',
      imagePath: 'assets/images/chips_large.png',
    ),
    BcEatsProduct(
      id: 'russian-and-chips',
      name: 'Russian and Chips',
      description: 'Russian with chips',
      price: 35.00,
      category: 'Chips',
      imagePath: 'assets/images/russian_chips.png',
    ),
    BcEatsProduct(
      id: 'soft-drink',
      name: 'Soft Drink',
      description: '330ml soft drink',
      price: 15.00,
      category: 'Drinks',
      imagePath: 'assets/images/coke.png',
    ),
    BcEatsProduct(
      id: 'coke',
      name: 'Coke',
      description: 'Cold soft drink',
      price: 15.00,
      category: 'Drinks',
      imagePath: 'assets/images/coke.png',
    ),
    BcEatsProduct(
      id: 'coke-zero',
      name: 'Coke Zero',
      description: 'Cold soft drink',
      price: 15.00,
      category: 'Drinks',
      imagePath: 'assets/images/coke_zero.png',
    ),
    BcEatsProduct(
      id: 'fanta',
      name: 'Fanta',
      description: 'Cold soft drink',
      price: 15.00,
      category: 'Drinks',
      imagePath: 'assets/images/fanta.png',
    ),
    BcEatsProduct(
      id: 'sprite',
      name: 'Sprite',
      description: 'Cold soft drink',
      price: 15.00,
      category: 'Drinks',
      imagePath: 'assets/images/sprite.png',
    ),
    BcEatsProduct(
      id: 'monster',
      name: 'Monster',
      description: 'Energy drink',
      price: 30.00,
      category: 'Drinks',
      imagePath: 'assets/images/monster.png',
    ),
    BcEatsProduct(
      id: 'red-bull',
      name: 'Red Bull',
      description: 'Energy drink',
      price: 30.00,
      category: 'Drinks',
      imagePath: 'assets/images/red_bull.png',
    ),
    BcEatsProduct(
      id: 'dragon',
      name: 'Dragon',
      description: 'Energy drink',
      price: 20.00,
      category: 'Drinks',
      imagePath: 'assets/images/dragon.png',
    ),
    BcEatsProduct(
      id: 'energade',
      name: 'Energade',
      description: 'Sports drink',
      price: 18.00,
      category: 'Drinks',
      imagePath: 'assets/images/energade.png',
    ),
    BcEatsProduct(
      id: 'still-water',
      name: 'Still Water',
      description: 'Bottled water',
      price: 15.00,
      category: 'Drinks',
      imagePath: 'assets/images/still_water.png',
    ),
    BcEatsProduct(
      id: 'sparkling-water',
      name: 'Sparkling Water',
      description: 'Bottled sparkling water',
      price: 18.00,
      category: 'Drinks',
      imagePath: 'assets/images/sparkling_water.png',
    ),
    BcEatsProduct(
      id: 'extra-cheese',
      name: 'Extra Cheese',
      description: 'Add extra cheese',
      price: 8.00,
      category: 'Extras',
      imagePath: 'assets/images/extra_cheese.png',
    ),
    BcEatsProduct(
      id: 'extra-bacon',
      name: 'Extra Bacon',
      description: 'Add extra bacon',
      price: 12.00,
      category: 'Extras',
      imagePath: 'assets/images/bacon_slices.png',
    ),
    BcEatsProduct(
      id: 'fried-egg',
      name: 'Fried Egg',
      description: 'Add a fried egg',
      price: 8.00,
      category: 'Extras',
      imagePath: 'assets/images/fried_egg.png',
    ),
    BcEatsProduct(
      id: 'buttered-bread',
      name: 'Buttered Bread',
      description: 'Bread with butter',
      price: 12.00,
      category: 'Extras',
      imagePath: 'assets/images/buttered_bread.png',
    ),
  ];

  @override
  Future<List<BcEatsProduct>> fetchProducts() async {
    return List<BcEatsProduct>.unmodifiable(_products);
  }

  @override
  Future<BcEatsProduct?> findProductById(String productId) async {
    for (final product in _products) {
      if (product.id == productId) {
        return product;
      }
    }

    return null;
  }
}
