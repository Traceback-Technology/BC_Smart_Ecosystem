import 'position.dart';

enum CampusYard {
  main,
  north,
}

class Destination {
  final String id;
  final String name;
  final String category;
  final Position position;
  final String nearestNode;
  final CampusYard yard;

  const Destination({
    required this.id,
    required this.name,
    required this.category,
    required this.position,
    required this.nearestNode,
    required this.yard,
  });

  factory Destination.fromJson(
    Map<String, dynamic> json,
  ) {
    return Destination(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      position: Position.fromJson(
        json['position']
            as Map<String, dynamic>,
      ),
      nearestNode:
          json['nearestNode'] as String,
      yard: _yardFromJson(
        json['yard'] as String,
      ),
    );
  }

  static CampusYard _yardFromJson(
    String value,
  ) {
    switch (value.toLowerCase()) {
      case 'main':
        return CampusYard.main;

      case 'north':
        return CampusYard.north;

      default:
        throw FormatException(
          'Unknown campus yard: $value',
        );
    }
  }
}