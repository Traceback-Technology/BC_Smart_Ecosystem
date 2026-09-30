import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../models/destination.dart';
import '../models/filter_category.dart';

/// A BC Ways destination marker.
///
/// The marker's BOTTOM-CENTRE is its exact geographic/map anchor.
///
/// CampusMap places this bottom-centre point directly on the centre
/// of the corresponding 10 x 10 Figma destination square.
class DestinationMarker extends StatelessWidget {
  static const double markerWidth = 180.0;
  static const double markerHeight = 90.0;

  final Destination destination;
  final Color color;
  final bool emphasized;

  const DestinationMarker({
    super.key,
    required this.destination,
    required this.color,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final double pinSize = emphasized ? 42.0 : 30.0;

    // Material's location_on glyph uses a 24 x 24 design grid,
    // but the visible tip ends around y = 22 rather than y = 24.
    //
    // That leaves approximately 2 / 24 of the icon size below
    // the visible tip.
    //
    // Moving the Icon box down by this amount makes the VISIBLE
    // tip land exactly on this widget's bottom-centre anchor.
    final double pinTipCorrection = pinSize / 12.0;

    return SizedBox(
      width: markerWidth,
      height: markerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // ===============================================================
          // LABEL
          // ===============================================================
          Positioned(
            // Keep approximately the same visual gap between
            // the label and the visible top of the pin.
            bottom: pinSize + 4 - pinTipCorrection,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: color, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  destination.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: context.readableAccent(color),
                  ),
                ),
              ),
            ),
          ),

          // ===============================================================
          // PIN
          // ===============================================================
          //
          // The visible tip of this pin is deliberately aligned
          // with the BOTTOM-CENTRE of the 180 x 90 marker widget.
          //
          // That point is the only rotation/scaling anchor used
          // by CampusMap.
          Positioned(
            bottom: -pinTipCorrection,
            child: Icon(Icons.location_on, color: color, size: pinSize),
          ),
        ],
      ),
    );
  }
}

/// Resolves a destination's raw category to the colour of its
/// corresponding filter category.
Color colorForCategory(String category, List<FilterCategory> categories) {
  for (final c in categories) {
    if (c.matchesDestinationCategory(category)) {
      return c.color;
    }
  }

  return const Color(0xFFF5A623);
}
