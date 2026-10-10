import 'app_data.dart';

class EatsDataService {
  final Map<String, dynamic> _dummyData = {
    "vendorName": "BC Ways & Eats",
    "products": [
      {
        "productId": "1",
        "productName": "Chicken Pasta",
        "productDescription": "Creamy pasta with grilled chicken.",
        "productPrice": 78.00,
        "quantity": 10
      },
      {
        "productId": "2",
        "productName": "Beef Burger Meal",
        "productDescription": "Burger, fries & a soft drink.",
        "productPrice": 65.00,
        "quantity": 15
      },
      {
        "productId": "3",
        "productName": "Chicken Wrap",
        "productDescription": "Grilled chicken, lettuce, mayo & cheese in a wrap.",
        "productPrice": 55.00,
        "quantity": 5
      },
      {
        "productId": "4",
        "productName": "Coke 500ml",
        "productDescription": "Refreshing Coca-Cola in a 500ml bottle.",
        "productPrice": 15.00,
        "quantity": 20
      },
      {
        "productId": "5",
        "productName": "Medium Fries",
        "productDescription": "Crispy fries with a side of dipping sauce.",
        "productPrice": 17.00,
        "quantity": 30
      }
    ]
  };

  Future<VendorData> fetchVendorData() async {
    // Simulate a network delay
    await Future.delayed(const Duration(milliseconds: 300));

    //TODO: Replace this with actual API call to fetch data from backend
    return VendorData.fromJson(_dummyData);
  }
}