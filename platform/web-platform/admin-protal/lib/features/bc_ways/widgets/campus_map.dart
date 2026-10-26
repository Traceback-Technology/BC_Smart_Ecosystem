import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/destination.dart';
import '../models/filter_category.dart';
import 'destination_marker.dart';
import 'route_painter.dart';

class CampusMap extends StatefulWidget {
  static const double mapWidth = 3000;
  static const double mapHeight = 3000;

  final TransformationController transformController;
  final List<Offset> routePolyline;
  final Offset? userLocation;
  final List<Destination> pins;
  final Destination? highlightedDestination;
  final List<FilterCategory> categories;
  final void Function(Destination)? onPinTap;

  /// Called when the user actually moves, zooms or rotates the map.
  final VoidCallback? onInteractionUpdate;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;

  /// Visual interpolation only.
  ///
  /// Routing still uses the real filtered GPS position in MapScreen and
  /// NavigationScreen. This duration only controls how smoothly the blue dot
  /// travels from one trusted position to the next.
  final Duration gpsAnimationDuration;
  final Curve gpsAnimationCurve;

  const CampusMap({
    super.key,
    required this.transformController,
    required this.routePolyline,
    required this.userLocation,
    required this.pins,
    required this.highlightedDestination,
    required this.categories,
    this.onPinTap,
    this.onInteractionUpdate,
    this.onInteractionStart,
    this.onInteractionEnd,
    this.gpsAnimationDuration = const Duration(milliseconds: 650),
    this.gpsAnimationCurve = Curves.linear,
  });

  @override
  State<CampusMap> createState() => _CampusMapState();
}

class _CampusMapState extends State<CampusMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _haloOpacity;
  late final Animation<double> _haloScale;

  double _previousGestureRotation = 0.0;

  // ---------------------------------------------------------------------------
  // FIGMA DESTINATION GEOMETRY
  // ---------------------------------------------------------------------------
  // Destination coordinates came from the top-left corner of 10 x 10 squares
  // in Figma, so the true destination point is the centre: x + 5, y + 5.

  static const double _figmaDestinationSquareSize = 10.0;
  static const double _figmaDestinationHalfSize =
      _figmaDestinationSquareSize / 2;

  static const double _destinationMarkerWidth = 180.0;
  static const double _destinationMarkerHeight = 90.0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _haloOpacity = Tween<double>(begin: 0.20, end: 0.75).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _haloScale = Tween<double>(begin: 0.90, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Offset _destinationAnchor(Destination destination) {
    return Offset(
      destination.position.x + _figmaDestinationHalfSize,
      destination.position.y + _figmaDestinationHalfSize,
    );
  }

  double _currentMapRotation() {
    final values = widget.transformController.value.storage;
    return math.atan2(values[1], values[0]);
  }

  void _rotateAroundFocalPoint(Offset focalPoint, double radians) {
    if (radians.abs() < 0.00001) {
      return;
    }

    final current = widget.transformController.value.clone();

    final rotation = Matrix4.identity()
      ..translateByDouble(focalPoint.dx, focalPoint.dy, 0, 1)
      ..rotateZ(radians)
      ..translateByDouble(-focalPoint.dx, -focalPoint.dy, 0, 1);

    rotation.multiply(current);
    widget.transformController.value = rotation;
  }

  Widget _buildUprightDestinationMarker(Destination destination) {
    return AnimatedBuilder(
      animation: widget.transformController,
      builder: (context, child) {
        final mapRotation = _currentMapRotation();

        return Transform.rotate(
          // Cancel only the map rotation. The marker's anchor still travels
          // with the map because the whole marker lives inside InteractiveViewer.
          angle: -mapRotation,

          // The bottom-centre is the exact pin-tip anchor.
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          widget.onPinTap?.call(destination);
        },
        child: AnimatedScale(
          scale: widget.highlightedDestination?.id == destination.id
              ? 1.15
              : 1.0,
          duration: const Duration(milliseconds: 200),

          // Selected markers grow away from the anchor rather than moving it.
          alignment: Alignment.bottomCenter,
          child: DestinationMarker(
            destination: destination,
            color: _colorForCategory(destination.category),
          ),
        ),
      ),
    );
  }

  Widget _buildPositionedDestination(Destination destination) {
    final anchor = _destinationAnchor(destination);

    return Positioned(
      left: anchor.dx - _destinationMarkerWidth / 2,
      top: anchor.dy - _destinationMarkerHeight,
      child: _buildUprightDestinationMarker(destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: InteractiveViewer(
        transformationController: widget.transformController,
        constrained: false,
        minScale: 0.5,
        maxScale: 4.0,
        boundaryMargin: const EdgeInsets.all(500),
        panEnabled: true,
        scaleEnabled: true,
        onInteractionStart: (_) {
          _previousGestureRotation = 0.0;
          widget.onInteractionStart?.call();
        },
        onInteractionUpdate: (details) {
          final moved = details.focalPointDelta.distanceSquared > 0.01;
          final zoomed = (details.scale - 1.0).abs() > 0.001;
          final rotated = details.rotation.abs() > 0.001;

          if (moved || zoomed || rotated) {
            widget.onInteractionUpdate?.call();
          }

          if (details.pointerCount >= 2) {
            final rotationDelta = details.rotation - _previousGestureRotation;

            _previousGestureRotation = details.rotation;

            _rotateAroundFocalPoint(details.localFocalPoint, rotationDelta);
          } else {
            _previousGestureRotation = 0.0;
          }
        },
        onInteractionEnd: (_) {
          _previousGestureRotation = 0.0;
          widget.onInteractionEnd?.call();
        },
        child: SizedBox(
          width: CampusMap.mapWidth,
          height: CampusMap.mapHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: SvgPicture.asset(
                  Theme.of(context).brightness == Brightness.dark
                      ? 'assets/bc_ways/map/campus_2.svg'
                      : 'assets/bc_ways/map/campus.svg',
                  fit: BoxFit.fill,
                ),
              ),

              if (widget.routePolyline.length > 1)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: RoutePainter(widget.routePolyline),
                    ),
                  ),
                ),

              for (final destination in widget.pins)
                _buildPositionedDestination(destination),

              // -----------------------------------------------------------------
              // SMOOTH LIVE GPS DOT
              // -----------------------------------------------------------------
              //
              // The real filtered GPS target can arrive every few hundred
              // milliseconds. AnimatedPositioned renders the movement at Flutter's
              // frame rate, so the dot moves continuously between real fixes.
              //
              // This is visual interpolation only. It does not change routing.
              if (widget.userLocation != null)
                AnimatedPositioned(
                  duration: widget.gpsAnimationDuration,
                  curve: widget.gpsAnimationCurve,
                  left: widget.userLocation!.dx - 27,
                  top: widget.userLocation!.dy - 27,
                  child: _buildLiveLocationMarker(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveLocationMarker() {
    return IgnorePointer(
      child: SizedBox(
        width: 54,
        height: 54,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: _haloOpacity.value,
                  child: Transform.scale(scale: _haloScale.value, child: child),
                );
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF90CAF9),
                ),
              ),
            ),
            Container(
              width: 29,
              height: 29,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            Container(
              width: 19,
              height: 19,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF1976D2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForCategory(String destinationCategory) {
    for (final category in widget.categories) {
      if (category.matchesDestinationCategory(destinationCategory)) {
        return category.color;
      }
    }

    return Theme.of(context).colorScheme.onSurface;
  }
}
