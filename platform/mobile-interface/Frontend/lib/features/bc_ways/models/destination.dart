import 'position.dart';

enum CampusYard { main, north }

class Destination {
  final String id;
  final String name;
  final String category;
  final Position position;
  final String nearestNode;
  final List<String> additionalEntranceNodes;

  List<String> get entranceNodeIds =>
      List<String>.unmodifiable([nearestNode, ...additionalEntranceNodes]);
  final CampusYard yard;

  const Destination({
    required this.id,
    required this.name,
    required this.category,
    required this.position,
    required this.nearestNode,
    this.additionalEntranceNodes = const [],
    required this.yard,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    final entrances = _parseEntrances(json['nearestNode']);
    return Destination(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      position: Position.fromJson(json['position'] as Map<String, dynamic>),
      nearestNode: entrances.first,
      additionalEntranceNodes: List<String>.unmodifiable(entrances.skip(1)),
      yard: _yardFromJson(json['yard'] as String),
    );
  }

  static List<String> _parseEntrances(dynamic value) {
    final List<dynamic> values;
    if (value is String) {
      values = [value];
    } else if (value is List) {
      values = value;
    } else {
      throw const FormatException(
        'nearestNode must be a node ID or a non-empty list of node IDs.',
      );
    }

    if (values.isEmpty ||
        values.any((item) => item is! String || item.trim().isEmpty)) {
      throw const FormatException(
        'nearestNode must contain non-empty node IDs.',
      );
    }

    return values.cast<String>().map((id) => id.trim()).toSet().toList();
  }

  static CampusYard _yardFromJson(String value) {
    switch (value.toLowerCase()) {
      case 'main':
        return CampusYard.main;

      case 'north':
        return CampusYard.north;

      default:
        throw FormatException('Unknown campus yard: $value');
    }
  }
}
