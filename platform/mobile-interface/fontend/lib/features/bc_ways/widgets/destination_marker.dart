import 'package:flutter/material.dart';

import '../models/destination.dart';

class DestinationMarker extends StatelessWidget {
  final Destination destination;
  final VoidCallback onTap;

  const DestinationMarker({
    super.key,
    required this.destination,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: destination.position.x - 8,
      top: destination.position.y - 15,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [

            // Label
            Positioned(
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: destination.color,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  destination.name,
                  style: TextStyle(
                    color: destination.color,
                    fontSize: 6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Marker
            Icon(
              Icons.location_on,
              color: destination.color,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}