import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;

import '../../../shared/widgets/adaptive_map_layout.dart';
import '../../../shared/widgets/campus_logo.dart';
import '../constants/colors.dart';
import '../constants/map_constants.dart';
import '../models/destination.dart';
import '../models/route_result.dart';
import '../services/campus_gps_service.dart';
import '../services/campus_navigation_geometry.dart';
import '../services/dijkstra_service.dart';
import '../services/graph_service.dart';
import '../services/navigation_service.dart';
import '../services/route_history_service.dart';
import '../services/route_follow_service.dart';
import '../widgets/bc_bottom_navigation_bar.dart';
import '../widgets/campus_map.dart';
import '../widgets/map_status_overlay.dart';
import '../widgets/navigation_card.dart';
import '../../bc_eats/widgets/notification_bell.dart';

class NavigationScreen extends StatefulWidget {
  final String destinationQuery;

  /// Kept for compatibility with older callers.
  ///
  /// Actual routing begins from live GPS.
  final String? startNodeId;

  /// Current visible GPS position supplied
  /// by MapScreen.
  final Offset? initialMapPosition;

  const NavigationScreen({
    super.key,
    required this.destinationQuery,
    this.startNodeId,
    this.initialMapPosition,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with TickerProviderStateMixin {
  // ===========================================================================
  // SERVICES
  // ===========================================================================

  final GraphService _graphService = GraphService.instance;

  final NavigationService _navigationService = NavigationService();

  final CampusGpsService _gpsService = const CampusGpsService();

  late DijkstraService _dijkstra;
  late final RouteFollowService _routeFollower;

  // ===========================================================================
  // MAP / CAMERA
  // ===========================================================================

  final TransformationController _transformController =
      TransformationController();

  late final AnimationController _cameraAnimationController;

  double _cameraFromScale = 1.0;
  double _cameraToScale = 1.0;

  double _cameraFromRotation = 0.0;
  double _cameraRotationDelta = 0.0;

  double _cameraFromX = 0.0;
  double _cameraToX = 0.0;

  double _cameraFromY = 0.0;
  double _cameraToY = 0.0;

  bool _hasCenteredMap = false;

  Size? _mapViewportSize;

  /// Active Navigation starts in automatic
  /// GPS/route-follow mode.
  bool _followGps = true;

  // ===========================================================================
  // GPS
  // ===========================================================================

  StreamSubscription<geo.Position>? _gpsSubscription;

  geo.Position? _gpsPosition;

  Offset? _lastVisibleMapPosition;

  CampusEntry? _nearestEntry;

  bool _onNavigationNetwork = false;
  final CampusBoundaryTracker _campusBoundary = CampusBoundaryTracker();
  bool _insideCampus = false;
  bool get _insideOffPath => _insideCampus && !_onNavigationNetwork;

  double _distanceToEntry = 0;

  String? _gpsError;

  // ===========================================================================
  // DESTINATION / ROUTE
  // ===========================================================================

  Destination? _destination;

  RouteResult _route = RouteResult.empty;

  // ===========================================================================
  // STATE
  // ===========================================================================

  bool _loading = true;

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _routeFollower = RouteFollowService(
      vsync: this,
      onChanged: () {
        if (!mounted || !_routeFollower.active) return;
        setState(() {
          _route = _routeFollower.route;
          _lastVisibleMapPosition = _routeFollower.position;
        });
      },
    );

    _cameraAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _cameraAnimationController.addListener(_onCameraAnimationTick);

    // Keep the existing GPS dot visible while
    // the Navigation screen starts.
    _lastVisibleMapPosition = widget.initialMapPosition;

    _bootstrap();
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();

    _navigationService.dispose();

    _routeFollower.dispose();
    _cameraAnimationController.dispose();

    _transformController.dispose();

    // Leaving before arrival (back button, bottom nav) ends the route as
    // cancelled. A no-op if it was already completed or cancelled.
    unawaited(RouteHistoryService.instance.markCancelled());

    super.dispose();
  }

  // ===========================================================================
  // BOOTSTRAP
  // ===========================================================================

  Future<void> _bootstrap() async {
    try {
      await _graphService.load();

      _dijkstra = DijkstraService(_graphService.graph);

      if (!mounted) {
        return;
      }

      _destination = _graphService.destinationByName(widget.destinationQuery);

      if (_destination == null) {
        setState(() {
          _loading = false;
        });

        return;
      }

      final initialGps = await _navigationService.startLocationTracking();

      if (!mounted) {
        return;
      }

      _applyGpsPosition(initialGps);

      _gpsSubscription = _navigationService.locationStream.listen(
        _applyGpsPosition,
        onError: (error) {
          if (!mounted) {
            return;
          }

          setState(() {
            _gpsError = error.toString();
            _loading = false;
          });
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _gpsError = error.toString();
        _loading = false;
      });
    }
  }

  // ===========================================================================
  // GPS UPDATE
  // ===========================================================================

  void _applyGpsPosition(geo.Position gps) {
    if (!mounted) {
      return;
    }
    final destination = _destination;
    if (destination == null) {
      return;
    }
    final raw = _gpsService.toMapOffset(gps);
    final insideCanvas = _gpsService.isInsideMapCanvas(raw);
    final insideCampus = _campusBoundary.update(raw, accuracy: gps.accuracy);
    if (!insideCanvas) {
      _routeFollower.reset();
    }
    final following =
        insideCanvas &&
        _routeFollower.updateToAny(
          _graphService.graph,
          raw,
          destination.entranceNodeIds,
          accuracy: gps.accuracy,
          timestamp: gps.timestamp,
        );
    final nearestEntry = _gpsService.nearestEntry(
      gps,
      destinationYard: destination.yard,
    );
    // Campus membership and path matching are independent states.
    final String? startNodeId = following
        ? _graphService.nearestNodeIdTo(raw)
        : insideCampus
        ? null
        : nearestEntry.nodeId;
    final distanceToEntry = following || insideCampus
        ? 0.0
        : _gpsService.distanceToEntry(gps, nearestEntry);
    RouteResult route = RouteResult.empty;
    if (following) {
      route = _routeFollower.route;
    } else if (!insideCampus && startNodeId != null) {
      route = _dijkstra.findRouteToAny(
        startNodeId,
        destination.entranceNodeIds,
      );
    }
    final visible = following ? _routeFollower.position ?? raw : raw;
    setState(() {
      _gpsPosition = gps;

      _lastVisibleMapPosition = visible;
      _nearestEntry = nearestEntry;
      _insideCampus = insideCampus;
      _onNavigationNetwork = following;
      _distanceToEntry = distanceToEntry;
      _route = route;
      _gpsError = null;
      _loading = false;
    });

    // Save completion using the current navigation arrival rules.
    if (_routeFollower.hasArrived) {
      unawaited(RouteHistoryService.instance.markCompleted());
    }

    if (_followGps) {
      _moveNavigationCamera(_routeFollower.targetPosition ?? visible);
    }
  }

  // ===========================================================================
  // END NAVIGATION
  // ===========================================================================

  void _endNavigation() {
    _gpsSubscription?.cancel();

    unawaited(RouteHistoryService.instance.markCancelled());

    unawaited(_navigationService.stopLocationTracking());

    Navigator.of(context).maybePop();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------------------------------
    // LOADING
    // -------------------------------------------------------------------------

    if (_loading) {
      return Scaffold(
        backgroundColor: context.cardBg,
        bottomNavigationBar: const BcBottomNavigationBar(selectedIndex: 1),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopBar(),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // DESTINATION NOT FOUND
    // -------------------------------------------------------------------------

    if (_destination == null) {
      return Scaffold(
        backgroundColor: context.cardBg,
        bottomNavigationBar: const BcBottomNavigationBar(selectedIndex: 1),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Center(
                  child: Text(
                    'Destination not found.',
                    style: TextStyle(color: context.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // GPS ERROR
    // -------------------------------------------------------------------------

    if (_gpsError != null && _lastVisibleMapPosition == null) {
      return Scaffold(
        backgroundColor: context.cardBg,
        bottomNavigationBar: const BcBottomNavigationBar(selectedIndex: 1),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_off,
                          size: 42,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Unable to get your location.',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _gpsError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // NO ROUTE
    // -------------------------------------------------------------------------

    if (_route.isEmpty && !_insideOffPath) {
      return Scaffold(
        backgroundColor: context.cardBg,
        bottomNavigationBar: const BcBottomNavigationBar(selectedIndex: 1),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No campus route could be calculated '
                      'for ${_destination!.name}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // ROUTE INFORMATION
    // -------------------------------------------------------------------------

    final routeRemaining = _route.totalDistanceMeters;

    final totalRemaining = routeRemaining + _distanceToEntry;

    final eta = _navigationService.etaMinutes(totalRemaining);

    final arrival = TimeOfDay.fromDateTime(
      DateTime.now().add(Duration(minutes: eta)),
    );

    final instruction = _currentInstruction();

    final routePoints = _route.path
        .map((pathNode) => pathNode.node.position.toOffset())
        .toList();

    // -------------------------------------------------------------------------
    // ACTIVE NAVIGATION
    // -------------------------------------------------------------------------

    return Scaffold(
      backgroundColor: context.cardBg,
      bottomNavigationBar: const BcBottomNavigationBar(selectedIndex: 1),
      body: SafeArea(
        bottom: false,
        child: AdaptiveMapLayout(
          header: [_buildTopBar()],
          map: LayoutBuilder(
            builder: (context, constraints) {
              _mapViewportSize = constraints.biggest;

              final focus = _mapFocusPosition();

              if (focus != null) {
                _maybeCenterMap(constraints.biggest, focus);
              }

              return Stack(
                children: [
                  CampusMap(
                    transformController: _transformController,

                    routePolyline: routePoints,

                    userLocation: _visibleUserPosition(),

                    pins: _graphService.destinations,

                    highlightedDestination: _destination,

                    categories: _graphService.categories,

                    // Only actual map movement
                    // pauses automatic navigation.
                    onInteractionUpdate: _stopFollowingGps,
                    gpsAnimationDuration: _routeFollower.active
                        ? Duration.zero
                        : const Duration(milliseconds: 600),

                    gpsAnimationCurve: Curves.easeOutCubic,
                  ),

                  MapStatusOverlay(
                    viewportHeight: constraints.maxHeight,
                    pinnedChildren: [
                      if (!_insideCampus &&
                          !_onNavigationNetwork &&
                          _nearestEntry != null)
                        _buildOutsideBanner(),

                      if (!_insideCampus &&
                          !_onNavigationNetwork &&
                          _gpsPosition != null &&
                          _nearestEntry != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: _buildEntranceIndicator(),
                        ),
                    ],
                    children: [
                      if (_insideOffPath)
                        Material(
                          color: context.cardBg.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Return to the nearby path',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Navigation to ${_destination!.name} will resume '
                                  'when your position reconnects to a path.',
                                  textAlign: TextAlign.center,
                                ),
                                TextButton(
                                  onPressed: _endNavigation,
                                  child: const Text('End navigation'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        NavigationCard(
                          instruction: instruction,
                          destinationName: _destination!.name,
                          etaMinutes: eta,
                          remainingMeters: totalRemaining,
                          arrival: arrival,
                          onExit: _endNavigation,
                        ),
                    ],
                  ),

                  // -----------------------------------------------------------
                  // FOLLOW GPS
                  // -----------------------------------------------------------
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: Material(
                      elevation: 4,
                      color: context.cardBg,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: _followGps
                            ? 'Following your location'
                            : 'Resume navigation follow',
                        onPressed: _centerOnUser,
                        icon: Icon(
                          _followGps ? Icons.gps_fixed : Icons.my_location,
                          color: BcColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          footer: [
            if (_insideOffPath)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Distance and ETA will update when you rejoin a path.',
                ),
              )
            else
              _buildBottomSummary(totalRemaining, eta, arrival),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP BAR
  // ===========================================================================

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 18, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: _endNavigation,
            icon: const Icon(Icons.arrow_back, size: 28),
          ),
          const CampusLogo(width: 30, height: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'BC',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: BcColors.primary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'WAYS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Active Navigation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: context.textSecondary),
                ),
              ],
            ),
          ),
          const NotificationBell(),
        ],
      ),
    );
  }

  // ===========================================================================
  // CURRENT INSTRUCTION
  // ===========================================================================

  NavInstruction _currentInstruction() {
    if (_insideOffPath) {
      return const NavInstruction(
        type: TurnType.straight,
        label: 'Return to the nearby path',
        distanceMetersToTurn: 0,
      );
    }
    if (!_onNavigationNetwork && _nearestEntry != null) {
      return NavInstruction(
        type: TurnType.straight,
        label: 'Head to ${_nearestEntry!.label}',
        distanceMetersToTurn: _distanceToEntry,
      );
    }
    if (_routeFollower.hasArrived) {
      return const NavInstruction(
        type: TurnType.arrive,
        label: 'You have arrived',
        distanceMetersToTurn: 0,
      );
    }
    if (!_routeFollower.latestFixMatched) {
      return NavInstruction(
        type: TurnType.straight,
        label: 'Checking your position...',
        distanceMetersToTurn: _route.totalDistanceMeters,
      );
    }
    // A one-node route alone does not prove physical arrival.
    if (_route.path.length <= 1) {
      return NavInstruction(
        type: TurnType.straight,
        label: 'Continue to destination',
        distanceMetersToTurn: _routeFollower.distanceToGoal,
      );
    }
    return _navigationService.currentInstruction(_route, 0);
  }

  // ===========================================================================
  // VISIBLE GPS
  // ===========================================================================

  Offset? _visibleUserPosition() {
    return _lastVisibleMapPosition;
  }

  // ===========================================================================
  // MAP FOCUS
  // ===========================================================================

  Offset? _mapFocusPosition() {
    final userPosition = _visibleUserPosition();

    if (userPosition != null) {
      return userPosition;
    }

    final entry = _nearestEntry;

    if (entry == null) {
      return null;
    }

    return _graphService.graph.nodesById[entry.nodeId]?.position.toOffset();
  }

  // ===========================================================================
  // NAVIGATION DIRECTION
  // ===========================================================================

  double? _navigationRotationFor(Offset userPosition) {
    if (!_onNavigationNetwork || !_routeFollower.active) {
      return null;
    }

    return _routeFollower.cameraRotation;
  }
  // ===========================================================================
  // SMOOTH CAMERA HELPERS
  // ===========================================================================

  double _matrixScale(Matrix4 matrix) {
    final values = matrix.storage;

    final scale = math.sqrt(values[0] * values[0] + values[1] * values[1]);

    if (!scale.isFinite || scale <= 0) {
      return BcWaysMapConstants.defaultScale;
    }

    return scale;
  }

  double _matrixRotation(Matrix4 matrix) {
    final values = matrix.storage;

    return math.atan2(values[1], values[0]);
  }

  double _lerp(double from, double to, double amount) {
    return from + (to - from) * amount;
  }

  double _shortestRotationDelta(double from, double to) {
    // Ensures e.g. 359° -> 1°
    // turns only 2°.
    return math.atan2(math.sin(to - from), math.cos(to - from));
  }

  void _onCameraAnimationTick() {
    final t = Curves.easeOutCubic.transform(_cameraAnimationController.value);

    final scale = _lerp(_cameraFromScale, _cameraToScale, t);

    final rotation = _cameraFromRotation + _cameraRotationDelta * t;

    final x = _lerp(_cameraFromX, _cameraToX, t);

    final y = _lerp(_cameraFromY, _cameraToY, t);

    _transformController.value = Matrix4.identity()
      ..translateByDouble(x, y, 0, 1)
      ..rotateZ(rotation)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _animateCameraTo(
    Matrix4 target, {
    Duration duration = const Duration(milliseconds: 700),
  }) {
    final current = _transformController.value.clone();

    _cameraAnimationController.stop();

    _cameraFromScale = _matrixScale(current);

    _cameraToScale = _matrixScale(target);

    _cameraFromRotation = _matrixRotation(current);

    final targetRotation = _matrixRotation(target);

    _cameraRotationDelta = _shortestRotationDelta(
      _cameraFromRotation,
      targetRotation,
    );

    _cameraFromX = current.storage[12];

    _cameraToX = target.storage[12];

    _cameraFromY = current.storage[13];

    _cameraToY = target.storage[13];

    _cameraAnimationController.duration = duration;

    _cameraAnimationController
      ..reset()
      ..forward();
  }

  double _currentMapScale() {
    return _matrixScale(_transformController.value).clamp(0.5, 4.0).toDouble();
  }

  double _currentMapRotation() {
    return _matrixRotation(_transformController.value);
  }

  Matrix4 _navigationCameraMatrix(
    Offset userPosition, {
    required double scale,
    required double rotation,
  }) {
    final size = _mapViewportSize;

    if (size == null || size.isEmpty) {
      return _transformController.value.clone();
    }

    final matrix = Matrix4.identity()
      ..rotateZ(rotation)
      ..scaleByDouble(scale, scale, 1, 1);

    final values = matrix.storage;

    final transformedX =
        values[0] * userPosition.dx + values[4] * userPosition.dy;

    final transformedY =
        values[1] * userPosition.dx + values[5] * userPosition.dy;

    values[12] = size.width / 2 - transformedX;

    values[13] = size.height / 2 - transformedY;

    return matrix;
  }

  // ===========================================================================
  // ACTIVE NAVIGATION CAMERA
  // ===========================================================================

  void _moveNavigationCamera(
    Offset userPosition, {
    bool useDefaultScale = false,
  }) {
    final size = _mapViewportSize;

    if (size == null || size.isEmpty) {
      return;
    }

    final scale = useDefaultScale
        ? BcWaysMapConstants.defaultScale
        : _currentMapScale();

    final rotation =
        _navigationRotationFor(userPosition) ?? _currentMapRotation();

    final target = _navigationCameraMatrix(
      userPosition,
      scale: scale,
      rotation: rotation,
    );

    _animateCameraTo(
      target,

      // Smooth but still responsive while walking.
      duration: const Duration(milliseconds: 700),
    );

    _hasCenteredMap = true;
  }

  // ===========================================================================
  // INITIAL NAVIGATION CAMERA
  // ===========================================================================

  void _maybeCenterMap(Size viewportSize, Offset position) {
    if (_hasCenteredMap || viewportSize.isEmpty || !_followGps) {
      return;
    }

    _hasCenteredMap = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_followGps) {
        return;
      }

      _moveNavigationCamera(position, useDefaultScale: true);
    });
  }

  // ===========================================================================
  // MANUAL INTERACTION
  // ===========================================================================

  void _stopFollowingGps() {
    // Stop automatic movement immediately
    // when the user takes over.
    _cameraAnimationController.stop();

    if (!_followGps) {
      return;
    }

    setState(() {
      _followGps = false;
    });
  }

  // ===========================================================================
  // GPS FOLLOW BUTTON
  // ===========================================================================

  void _centerOnUser() {
    final position = _visibleUserPosition();

    if (position == null) {
      return;
    }

    setState(() {
      _followGps = true;
    });

    // Smoothly return to the user AND
    // smoothly restore route-up rotation.
    _moveNavigationCamera(position);
  }

  // ===========================================================================
  // OUTSIDE WALKING NETWORK BANNER
  // ===========================================================================

  Widget _buildOutsideBanner() {
    if (_insideCampus) {
      return const SizedBox.shrink();
    }
    final entry = _nearestEntry;

    if (entry == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: context.bcColors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.directions_walk,
            color: context.bcColors.onPrimaryContainer,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Head towards ${entry.label} • '
              '${_formatDistance(_distanceToEntry)}',
              style: TextStyle(
                color: context.bcColors.onPrimaryContainer,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FLOATING ENTRANCE INDICATOR
  // ===========================================================================

  Widget _buildEntranceIndicator() {
    if (_insideCampus) {
      return const SizedBox.shrink();
    }
    final gps = _gpsPosition;

    final entry = _nearestEntry;

    if (gps == null || entry == null) {
      return const SizedBox.shrink();
    }

    final rotation = _gpsService.arrowRotation(gps, entry);

    final turns = rotation / (2 * 3.141592653589793);

    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardBg.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: BcColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: AnimatedRotation(
              turns: turns,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: const Icon(
                Icons.navigation,
                color: BcColors.primary,
                size: 27,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${_formatDistance(_distanceToEntry)} away',
                  maxLines: 1,
                  style: TextStyle(color: context.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BOTTOM SUMMARY
  // ===========================================================================

  Widget _buildBottomSummary(double remaining, int eta, TimeOfDay arrival) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 9, 18, 9),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(top: BorderSide(color: context.subtleBorder)),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_walk, color: BcColors.primary, size: 21),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_formatDistance(remaining)} remaining'
              '  •  $eta min'
              '  •  Arrive ${arrival.format(context)}',
              style: TextStyle(
                color: context.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }

    return '${meters.round()} m';
  }
}
