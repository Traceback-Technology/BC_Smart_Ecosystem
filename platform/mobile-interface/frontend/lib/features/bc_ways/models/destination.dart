import 'position.dart';
import 'package:flutter/material.dart';

class Destination {
  final String id;
  final String name;
  final String category;
  final Position position;
  final String nearestNode;

  Destination({
    required this.id,
    required this.name,
    required this.category,
    required this.position,
    required this.nearestNode,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json["id"],
      name: json["name"],
      category: json["category"],
      position: Position.fromJson(json["position"]),
      nearestNode: json["nearestNode"]
    );
  }

  Color get color {
    switch (category) {

      // Classrooms
      case "Classroom":
        return const Color(0xFFAF1857);

      // Residences
      case "Residence":
        return const Color.fromARGB(255, 209, 163, 25);

      // Student buildings
      case "Study Room":
      case "Library":
      case "Learning Factory":
      case "Smart City":
      case "Laundry":
      case "Cafeteria":
      case "Tuck Shop":
      case "Student Building":
        return const Color.fromARGB(255, 76, 175, 174);

      // Outdoor
      case "Outdoor Areas":
        return const Color(0xFF7FB36B);

      // Parking
      case "Parking":
        return const Color.fromARGB(255, 124, 124, 124);

      // Other buildings
      case "Office":
      case "Toilets":
      default:
        return const Color(0xFF000000);
    }
  }
}