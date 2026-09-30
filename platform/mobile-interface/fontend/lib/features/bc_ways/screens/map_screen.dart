import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;

import '../../../shared/widgets/adaptive_map_layout.dart';
import '../../../shared/widgets/campus_logo.dart';
import '../constants/colors.dart';
import '../constants/map_constants.dart';
import '../models/destination.dart';
import '../models/filter_category.dart';
import '../models/path_node.dart';
import '../models/route_result.dart';
import '../services/campus_gps_service.dart';
import '../services/dijkstra_service.dart';
import '../services/graph_service.dart';
import '../services/navigation_service.dart';
import '../widgets/bc_bottom_navigation_bar.dart';
import '../widgets/campus_map.dart';
import 'destination_search_screen.dart';
import 'gps_calibration_screen.dart';
import 'navigation_screen.dart';

class MapScreen extends StatefulWidget {
  final String? initialDestinationQuery;

  const MapScreen({super.key, this.initialDestinationQuery});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  // ===========================================================================
  // SERVICES
  // ===========================================================================

  final GraphService _graphService = GraphService.instance;

  final NavigationService _navigationService = NavigationService();

  final CampusGpsService _gpsService = const CampusGpsService();

  late DijkstraService _dijkstra;

  // ===========================================================================
  // MAP
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

  bool _popularDestinationsExpanded = false;

  /// true:
  /// camera continuously follows the GPS dot.
  ///
  /// false:
  /// GPS still updates, but the user controls
  /// the map camera manually.
  bool _followGps = true;

  // ===========================================================================
  // GPS
  // ===========================================================================

  StreamSubscription<geo.Position>? _gpsSubscription;

  geo.Position? _gpsPosition;

  Offset? _mapPosition;

  /// Actual GPS-derived visible location.
  ///
  /// It may exist beyond the SVG bounds.
  Offset? _lastVisibleMapPosition;

  CampusEntry? _nearestEntry;

  String? _currentStartNodeId;

  bool _onNavigationNetwork = false;

  double _distanceToEntry = 0;

  String? _gpsError;

  // ===========================================================================
  // DESTINATION / ROUTE
  // ===========================================================================

  Destination? _selectedDestination;

  RouteResult _previewRoute = RouteResult.empty;

  // ===========================================================================
  // FILTER
  // ===========================================================================

  String? _selectedCategoryId;

  // ===========================================================================
  // STATE
  // ===========================================================================

  bool _loading = true;

  // ===========================================================================
  // GPS CALIBRATION
  // ===========================================================================

  void _openGpsCalibration() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GpsCalibrationScreen()),
    );
  }

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    _cameraAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _cameraAnimationController.addListener(_onCameraAnimationTick);

    _bootstrap();
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();

    _navigationService.dispose();

    _cameraAnimationController.dispose();

    _transformController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // BOOTSTRAP
  // ===========================================================================

  Future<void> _bootstrap() async {
    try {
      await _graphService.load();

      _dijkstra = DijkstraService(_graphService.graph);

      // -----------------------------------------------------------------------
      // OPTIONAL INITIAL DESTINATION
      // -----------------------------------------------------------------------

      final initialDestinationQuery = widget.initialDestinationQuery;

      if (initialDestinationQuery != null &&
          initialDestinationQuery.trim().isNotEmpty) {
        _selectedDestination = _graphService.destinationByName(
          initialDestinationQuery,
        );
      }

      final initialPosition = await _navigationService.startLocationTracking();

      if (!mounted) {
        return;
      }

      _applyGpsPosition(initialPosition);

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
  // LIVE GPS
  // ===========================================================================

  void _applyGpsPosition(geo.Position gps) {
    final mapPosition = _gpsService.toMapOffset(gps);

    final insideSvg = _gpsService.isInsideMapCanvas(mapPosition);

    // Always preserve actual GPS location.
    _lastVisibleMapPosition = mapPosition;

    // -------------------------------------------------------------------------
    // WALKING NETWORK
    // -------------------------------------------------------------------------

    final onNetwork =
        insideSvg && _graphService.isWithinNavigationNetwork(mapPosition);

    // -------------------------------------------------------------------------
    // NEAREST ENTRY
    // -------------------------------------------------------------------------

    final nearestEntry = _gpsService.nearestEntry(
      gps,
      destinationYard: _selectedDestination?.yard,
    );

    // -------------------------------------------------------------------------
    // ROUTING START
    // -------------------------------------------------------------------------

    String? startNodeId;

    if (onNetwork) {
      startNodeId = _graphService.nearestNodeIdTo(mapPosition);
    } else {
      startNodeId = nearestEntry.nodeId;
    }

    // -------------------------------------------------------------------------
    // DISTANCE TO ENTRY
    // -------------------------------------------------------------------------

    final distanceToEntry = onNetwork
        ? 0.0
        : _gpsService.distanceToEntry(gps, nearestEntry);

    // -------------------------------------------------------------------------
    // ROUTE
    // -------------------------------------------------------------------------

    RouteResult route = _previewRoute;

    if (_selectedDestination != null && startNodeId != null) {
      final startChanged = startNodeId != _currentStartNodeId;

      if (startChanged || route.isEmpty) {
        route = _dijkstra.findRoute(
          startNodeId,
          _selectedDestination!.nearestNode,
        );
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _gpsPosition = gps;
      _mapPosition = mapPosition;
      _nearestEntry = nearestEntry;
      _currentStartNodeId = startNodeId;
      _onNavigationNetwork = onNetwork;
      _distanceToEntry = distanceToEntry;
      _previewRoute = route;
      _gpsError = null;
      _loading = false;
    });

    // -------------------------------------------------------------------------
    // SMOOTH GPS CAMERA FOLLOW
    // -------------------------------------------------------------------------

    if (_followGps) {
      _moveCameraToUser(mapPosition);
    }
  }

  // ===========================================================================
  // FILTERS
  // ===========================================================================

  List<Destination> get _visibleDestinations {
    if (_selectedCategoryId == null) {
      return _graphService.destinations;
    }

    FilterCategory? selectedCategory;

    for (final category in _graphService.categories) {
      if (category.id == _selectedCategoryId) {
        selectedCategory = category;
        break;
      }
    }

    if (selectedCategory == null) {
      return _graphService.destinations;
    }

    return _graphService.destinations
        .where(
          (destination) => selectedCategory!.matchesDestinationCategory(
            destination.category,
          ),
        )
        .toList();
  }

  void _selectCategory(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
  }

  // ===========================================================================
  // DESTINATION SEARCH
  // ===========================================================================

  Future<void> _openDestinationSearch() async {
    final selected = await Navigator.of(context).push<Destination>(
      MaterialPageRoute(
        builder: (_) => DestinationSearchScreen(
          destinations: _graphService.destinations,
          categories: _graphService.categories,
          travelInfoFor: _travelInfoFor,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (selected != null) {
      _selectDestination(selected);
    }
  }

  // ===========================================================================
  // DESTINATION
  // ===========================================================================

  void _selectDestination(Destination destination) {
    final gps = _gpsPosition;

    if (gps != null) {
      _nearestEntry = _gpsService.nearestEntry(
        gps,
        destinationYard: destination.yard,
      );

      _distanceToEntry = _gpsService.distanceToEntry(gps, _nearestEntry!);
    }

    final startNodeId = _resolveCurrentStartNode();

    RouteResult route = RouteResult.empty;

    if (startNodeId != null) {
      route = _dijkstra.findRoute(startNodeId, destination.nearestNode);
    }

    setState(() {
      _selectedDestination = destination;
      _previewRoute = route;
    });
  }

  void _clearDestination() {
    setState(() {
      _selectedDestination = null;
      _previewRoute = RouteResult.empty;
    });
  }

  // ===========================================================================
  // CURRENT ROUTING START
  // ===========================================================================

  String? _resolveCurrentStartNode() {
    final position = _mapPosition;

    if (position != null && _onNavigationNetwork) {
      final nearest = _graphService.nearestNodeIdTo(position);

      if (nearest != null) {
        return nearest;
      }
    }

    return _nearestEntry?.nodeId;
  }

  // ===========================================================================
  // START NAVIGATION
  // ===========================================================================

  void _startNavigation() {
    final destination = _selectedDestination;

    if (destination == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NavigationScreen(
          destinationQuery: destination.name,
          initialMapPosition: _lastVisibleMapPosition,
        ),
      ),
    );
  }

  // ===========================================================================
  // TRAVEL INFORMATION
  // ===========================================================================

  DestinationTravelInfo? _travelInfoFor(Destination destination) {
    String? startNodeId;

    double outsideDistance = 0.0;

    if (_onNavigationNetwork && _mapPosition != null) {
      startNodeId = _graphService.nearestNodeIdTo(_mapPosition!);
    } else if (_gpsPosition != null) {
      final entry = _gpsService.nearestEntry(
        _gpsPosition!,
        destinationYard: destination.yard,
      );

      startNodeId = entry.nodeId;

      outsideDistance = _gpsService.distanceToEntry(_gpsPosition!, entry);
    }

    if (startNodeId == null) {
      return null;
    }

    final route = _dijkstra.findRoute(startNodeId, destination.nearestNode);

    if (route.isEmpty) {
      return null;
    }

    final totalDistance = outsideDistance + route.totalDistanceMeters;

    return DestinationTravelInfo(
      distanceMeters: totalDistance,
      minutes: _navigationService.etaMinutes(totalDistance),
    );
  }

  // ===========================================================================
  // QUICK DESTINATIONS
  // ===========================================================================

  List<Destination> get _quickDestinations {
    const preferred = [
      'Library',
      'Cafeteria',
      'Smart Cities',
      'Reception',
      'IOTA',
      'Student Parking',
    ];

    final result = <Destination>[];

    for (final target in preferred) {
      for (final destination in _graphService.destinations) {
        if (destination.name.toLowerCase().contains(target.toLowerCase()) &&
            !result.contains(destination)) {
          result.add(destination);

          break;
        }
      }
    }

    return result;
  }

  // ===========================================================================
  // BOTTOM NAVIGATION
  // ===========================================================================

  void _onBottomNavTap(int index) {
    if (index == 0) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      return;
    }

    if (index == 1) {
      return;
    }

    if (index == 2 || index == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${index == 2 ? 'Orders' : 'Profile'} '
            'is not connected yet.',
          ),
        ),
      );
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: context.cardBg,
      bottomNavigationBar: BcBottomNavigationBar(
        selectedIndex: 1,
        onTap: _onBottomNavTap,
      ),
      body: SafeArea(
        bottom: false,
        child: AdaptiveMapLayout(
          header: [
            _buildTopBar(),
            _buildSearchBar(),
            _buildCategoryFilters(),
            if (_gpsError != null) _buildGpsError(),
            if (_gpsPosition != null && !_onNavigationNetwork)
              _buildOutsideBanner(),
          ],
          map: _buildMap(),
          footer: [
            if (_selectedDestination != null) _buildDestinationPanel(),
            _buildPopularDestinations(),
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
            onPressed: () {
              Navigator.of(context).maybePop();
            },
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
                  'Find Your Destination',
                  style: TextStyle(fontSize: 13, color: context.textSecondary),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none, size: 29),
              Positioned(
                right: -4,
                top: -5,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE31B23),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
      child: InkWell(
        onTap: _openDestinationSearch,
        borderRadius: BorderRadius.circular(18),
        child: IgnorePointer(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search building, classroom or location',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: const Icon(Icons.tune),
              filled: true,
              fillColor: context.cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: context.subtleBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: context.subtleBorder),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // FILTERS
  // ===========================================================================

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 32 + MediaQuery.textScalerOf(context).scale(16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          _categoryChip(id: null, label: 'All'),
          ..._graphService.categories.map(
            (category) => _categoryChip(id: category.id, label: category.label),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip({required String? id, required String label}) {
    final selected = _selectedCategoryId == id;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) {
          _selectCategory(id);
        },
        selectedColor: BcColors.primary.withValues(alpha: 0.12),
        side: BorderSide(
          color: selected ? BcColors.primary : context.subtleBorder,
        ),
      ),
    );
  }

  // ===========================================================================
  // MAP
  // ===========================================================================

  Widget _buildMap() {
    return LayoutBuilder(
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
              routePolyline: _selectedDestination == null
                  ? const []
                  : _previewRoute.path
                        .map((PathNode node) => node.node.position.toOffset())
                        .toList(),
              userLocation: _lastVisibleMapPosition,
              pins: _visibleDestinations,
              highlightedDestination: _selectedDestination,
              categories: _graphService.categories,
              onPinTap: _selectDestination,

              // Only actual movement/zoom/rotation
              // disables GPS following.
              onInteractionUpdate: _stopFollowingGps,
              gpsAnimationDuration: const Duration(milliseconds: 600),

              gpsAnimationCurve: Curves.easeOutCubic,
            ),

            // ---------------------------------------------------------------
            // GPS DEBUG
            // ---------------------------------------------------------------
            if (BcWaysMapConstants.showGpsDebug)
              Positioned(left: 12, top: 12, child: _buildGpsDebugCard()),

            if (!_onNavigationNetwork &&
                _gpsPosition != null &&
                _nearestEntry != null)
              Positioned(top: 14, right: 14, child: _buildEntranceIndicator()),

            // ---------------------------------------------------------------
            // GPS FOLLOW BUTTON
            // ---------------------------------------------------------------
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
                      : 'Follow my location',
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
    );
  }

  // ===========================================================================
  // MAP FOCUS
  // ===========================================================================

  Offset? _mapFocusPosition() {
    final userPosition = _lastVisibleMapPosition;

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
  // SMOOTH MAP CAMERA
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
    Duration duration = const Duration(milliseconds: 650),
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

  Matrix4 _cameraMatrixFor(
    Offset position,
    Size viewport, {
    required double scale,
    required double rotation,
  }) {
    final matrix = Matrix4.identity()
      ..rotateZ(rotation)
      ..scaleByDouble(scale, scale, 1, 1);

    final values = matrix.storage;

    final transformedX = values[0] * position.dx + values[4] * position.dy;

    final transformedY = values[1] * position.dx + values[5] * position.dy;

    values[12] = viewport.width / 2 - transformedX;

    values[13] = viewport.height / 2 - transformedY;

    return matrix;
  }

  void _maybeCenterMap(Size viewportSize, Offset position) {
    if (_hasCenteredMap || viewportSize.isEmpty || !_followGps) {
      return;
    }

    _hasCenteredMap = true;

    final target = _cameraMatrixFor(
      position,
      viewportSize,
      scale: BcWaysMapConstants.defaultScale,
      rotation: 0,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_followGps) {
        return;
      }

      _animateCameraTo(target, duration: const Duration(milliseconds: 750));
    });
  }

  void _moveCameraToUser(Offset position) {
    final size = _mapViewportSize;

    if (size == null || size.isEmpty) {
      return;
    }

    final current = _transformController.value;

    final scale = _matrixScale(current).clamp(0.5, 4.0).toDouble();

    final rotation = _matrixRotation(current);

    final target = _cameraMatrixFor(
      position,
      size,
      scale: scale,
      rotation: rotation,
    );

    _animateCameraTo(target, duration: const Duration(milliseconds: 600));

    _hasCenteredMap = true;
  }

  void _stopFollowingGps() {
    // Stop any automatic movement immediately
    // when the user takes control.
    _cameraAnimationController.stop();

    if (!_followGps) {
      return;
    }

    setState(() {
      _followGps = false;
    });
  }

  void _centerOnUser() {
    final position = _lastVisibleMapPosition;

    if (position == null) {
      return;
    }

    setState(() {
      _followGps = true;
    });

    _moveCameraToUser(position);
  }

  // ===========================================================================
  // SELECTED DESTINATION CARD
  // ===========================================================================

  Widget _buildDestinationPanel() {
    final destination = _selectedDestination!;

    final info = _travelInfoFor(destination);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.subtleBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.directions_walk,
                color: context.readableAccent(BcColors.teal),
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        if (info != null)
                          Text(
                            '${info.minutes} min · '
                            '${_formatDistance(info.distanceMeters)}',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        Text(
                          '100% accessible',
                          style: TextStyle(
                            color: context.readableAccent(BcColors.teal),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _clearDestination,
                tooltip: 'Clear destination',
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: info != null ? _startNavigation : null,
              icon: const Icon(Icons.navigation),
              label: const Text(
                'Start Navigation',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: BcColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // POPULAR DESTINATIONS
  // ===========================================================================

  Widget _buildPopularDestinations() {
    final destinations = _quickDestinations;

    if (destinations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(top: BorderSide(color: context.subtleBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _popularDestinationsExpanded = !_popularDestinationsExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Popular Destinations',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _popularDestinationsExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _popularDestinationsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 14, bottom: 8),
              child: SizedBox(
                height: 70 + MediaQuery.textScalerOf(context).scale(38),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: destinations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return _quickCard(destinations[index]);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickCard(Destination destination) {
    final info = _travelInfoFor(destination);

    final color = _colorForCategory(destination.category);

    return InkWell(
      onTap: () {
        _selectDestination(destination);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72 + MediaQuery.textScalerOf(context).scale(24),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.subtleBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _iconForCategory(destination.category),
              color: color,
              size: 25,
            ),
            const SizedBox(height: 4),
            Text(
              destination.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
            if (info != null) ...[
              const SizedBox(height: 2),
              Text(
                '${info.minutes} min • '
                '${_formatDistance(info.distanceMeters)}',
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CATEGORY
  // ===========================================================================

  Color _colorForCategory(String destinationCategory) {
    for (final category in _graphService.categories) {
      if (category.matchesDestinationCategory(destinationCategory)) {
        return category.color;
      }
    }

    return Theme.of(context).colorScheme.onSurface;
  }

  IconData _iconForCategory(String destinationCategory) {
    for (final category in _graphService.categories) {
      if (category.matchesDestinationCategory(destinationCategory)) {
        return category.icon;
      }
    }

    return Icons.location_on_outlined;
  }

  // ===========================================================================
  // OUTSIDE NETWORK BANNER
  // ===========================================================================

  Widget _buildOutsideBanner() {
    final entry = _nearestEntry;

    if (entry == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 3, 18, 3),
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
  // ENTRANCE INDICATOR
  // ===========================================================================

  Widget _buildEntranceIndicator() {
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
  // GPS ERROR
  // ===========================================================================

  Widget _buildGpsError() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 3, 18, 3),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.bcColors.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_off,
            color: context.bcColors.onErrorContainer,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _gpsError!,
              style: TextStyle(
                color: context.bcColors.onErrorContainer,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // GPS DEBUG
  // ===========================================================================

  Widget _buildGpsDebugCard() {
    final gps = _gpsPosition;

    final map = _mapPosition;

    if (gps == null || map == null) {
      return Container(
        width: 200,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Waiting for GPS...',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openGpsCalibration,
                icon: const Icon(Icons.tune, size: 16, color: Colors.white),
                label: const Text('GPS Calibration'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: Colors.white, width: 1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          height: 1.35,
          fontFamily: 'monospace',
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lat: ${gps.latitude.toStringAsFixed(8)}'),
            Text('Lon: ${gps.longitude.toStringAsFixed(8)}'),
            const SizedBox(height: 3),
            Text('X: ${map.dx.toStringAsFixed(1)}'),
            Text('Y: ${map.dy.toStringAsFixed(1)}'),
            const SizedBox(height: 3),
            Text('Accuracy: ±${gps.accuracy.toStringAsFixed(1)} m'),
            Text('On network: $_onNavigationNetwork'),
            if (_nearestEntry != null) Text('Entry: ${_nearestEntry!.nodeId}'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openGpsCalibration,
                icon: const Icon(Icons.tune, size: 16, color: Colors.white),
                label: const Text('GPS Calibration'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: Colors.white, width: 1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
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
