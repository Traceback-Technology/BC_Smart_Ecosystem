import 'app_data.dart';

class EatsDataService {
  final Map<String, dynamic> _dummyData = {
    "vendorName": "BC Ways & Eats",
    "metrics": {
      "totalOrders": 50,
      "totalSales": 4500.00,
      "averageOrderValue": 37.50
    },
    "products": [
      {
        "productId": "1",
        "productName": "Chicken Pasta",
        "category": "Pasta",
        "productDescription": "Creamy pasta with grilled chicken.",
        "productPrice": 78.00,
        "inStock": true,
        "quantity": 10,
        "threshold": 5
      },
      /** final String productId;
          final String productName;
          final String category;
          final String productDescription;
          final double productPrice;
          final bool inStock;
          final int quantity;
          final int threshold; */
      {
        "productId": "2",
        "productName": "Beef Burger Meal",
        "category": "Combos",
        "productDescription": "Burger, fries & a soft drink.",
        "productPrice": 65.00,
        "inStock": true,
        "quantity": 15,
        "threshold": 2
      },
      {
        "productId": "3",
        "productName": "Chicken Wrap",
        "category": "Wraps",
        "productDescription": "Grilled chicken, lettuce, mayo & cheese in a wrap.",
        "productPrice": 55.00,
        "inStock": true,
        "quantity": 5,
        "threshold": 3
      },
      {
        "productId": "4",
        "productName": "Coke 500ml",
        "category": "Beverages",
        "productDescription": "Refreshing Coca-Cola in a 500ml bottle.",
        "productPrice": 15.00,
        "inStock": true,
        "quantity": 20,
        "threshold": 10
      },
      {
        "productId": "5",
        "productName": "Medium Fries",
        "category": "Sides",
        "productDescription": "Crispy fries with a side of dipping sauce.",
        "productPrice": 17.00,
        "inStock": true,
        "quantity": 30,
        "threshold": 5
      }
    ],
    "incomingOrders":[
      {
        "orderId": "BC1001",
        "customerName": "Sipho Dlamini",
        "time": "2 mins ago", //howlong ago order was placed
        "items": [
          "1x Beef Burger Meal", "1x Coke 500ml"],
        "totalAmount": 80.00,
        "status": "New" //Status can be New, Preparing, Ready, Completed
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