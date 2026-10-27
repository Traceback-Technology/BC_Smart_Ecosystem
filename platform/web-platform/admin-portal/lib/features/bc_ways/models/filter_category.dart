import 'package:flutter/material.dart';

/// A top-level filter chip (e.g. "Classrooms") shown on the map/search
/// screens. Groups one or more of the finer-grained `category` strings
/// used in destinations.json, loaded from categories.json.
class FilterCategory {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final List<String> matches;

  const FilterCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.matches,
  });

  bool matchesDestinationCategory(String category) => matches.contains(category);

  /// Parses one categories.json entry. Every field falls back to something
  /// sane if it's missing or null, so a hand-edited or partially-filled
  /// categories.json can't crash the app with a cast error — it just
  /// renders with defaults for whatever wasn't provided.
  factory FilterCategory.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?) ?? (json['label'] as String?) ?? 'unknown';
    return FilterCategory(
      id: id,
      label: (json['label'] as String?) ?? id,
      icon: _iconFor(json['icon'] as String?),
      color: _colorFor(json['color'] as String?),
      matches: ((json['matches'] ?? json['rawCategories']) as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  static IconData _iconFor(String? name) {
    switch (name) {
      case 'business':
      case 'domain':
        return Icons.business;
      case 'school':
        return Icons.school;
      case 'badge':
        return Icons.badge;
      case 'local_parking':
        return Icons.local_parking;
      case 'restaurant':
        return Icons.restaurant;
      case 'apartment':
        return Icons.apartment;
      case 'apps':
        return Icons.apps;
      default:
        return Icons.place;
    }
  }

  static Color _colorFor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFFF5A623); // default brand accent
    final v = hex.replaceFirst('#', '');
    final parsed = int.tryParse('FF$v', radix: 16);
    return parsed == null ? const Color(0xFFF5A623) : Color(parsed);
  }
}
