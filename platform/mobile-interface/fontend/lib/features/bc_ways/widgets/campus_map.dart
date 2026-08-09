import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/destination.dart';
import 'destination_marker.dart';
import '../models/node.dart';
import 'route_painter.dart';

class CampusMap extends StatelessWidget {
  final List<Destination> destinations;
  final List<Node> route;
  final Function(Destination) onDestinationTap;

  const CampusMap({
    super.key,
    required this.destinations,
    required this.route,
    required this.onDestinationTap,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      constrained: false,
      minScale: 0.5,
      maxScale: 6,
      child: SizedBox(
        width: 3000,
        height: 3000,
        child: Stack(
          children: [

            // SVG Map
            Positioned.fill(
              child: SvgPicture.asset(
                "assets/bc_ways/map/campus.svg",
                fit: BoxFit.fill,
              ),
            ),

            Positioned.fill(
              child: CustomPaint(
                painter: RoutePainter(route),
              ),
            ),

            ...destinations.map((destination) {

              return DestinationMarker(
                destination: destination,
                onTap: () => onDestinationTap(destination),
              );

            }),

            // Route Layer

            // Destination Layer

            // Current Location

            // Labels

          ],
        ),
      ),
    );
  }
}