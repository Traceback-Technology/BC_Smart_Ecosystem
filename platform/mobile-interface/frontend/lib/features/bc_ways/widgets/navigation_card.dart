import 'package:flutter/material.dart';

import '../models/destination.dart';

class NavigationCard extends StatelessWidget {
  final Destination destination;
  final double distance;

  const NavigationCard({
    super.key,
    required this.destination,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final walkingMinutes = (distance / 80).ceil();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black26,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            destination.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [

              const Icon(Icons.straighten),

              const SizedBox(width: 10),

              Text(
                "${distance.toStringAsFixed(0)} m",
                style: const TextStyle(fontSize: 18),
              ),

            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [

              const Icon(Icons.directions_walk),

              const SizedBox(width: 10),

              Text(
                "$walkingMinutes min walk",
                style: const TextStyle(fontSize: 18),
              ),

            ],
          ),
        ],
      ),
    );
  }
}