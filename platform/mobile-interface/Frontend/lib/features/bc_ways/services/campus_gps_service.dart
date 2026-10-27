import 'dart:math' as math;
import 'dart:ui';

import 'package:geolocator/geolocator.dart' as geo;
import '../models/destination.dart';
import '../models/node.dart';
import '../constants/map_constants.dart';

/// A real-world campus entry point.
///
/// These GPS coordinates are kept OUTSIDE nodes.json.
/// nodes.json remains purely:
///
/// id / type / x / y
class CampusEntry {
  final String nodeId;
  final String label;
  final double latitude;
  final double longitude;

  const CampusEntry({
    required this.nodeId,
    required this.label,
    required this.latitude,
    required this.longitude,
  });
}

class CampusGpsService {
  const CampusGpsService();

  // ---------------------------------------------------------------------------
  // CAMPUS ENTRY GPS REFERENCES
  // ---------------------------------------------------------------------------

  static const CampusEntry mainGate = CampusEntry(
    nodeId: 'main_gate',
    label: 'Main Gate',
    latitude: -25.68312072540506,
    longitude: 28.131238693594774,
  );

  static const CampusEntry mainEntrance = CampusEntry(
    nodeId: 'main_entrance',
    label: 'Main Entrance',
    latitude: -25.683160005214233,
    longitude: 28.131382191761286,
  );

  static const CampusEntry northGate = CampusEntry(
    nodeId: 'north_gate',
    label: 'North Gate',
    latitude: -25.682989591179105,
    longitude: 28.131300384395328,
  );

  static const CampusEntry northEntrance = CampusEntry(
    nodeId: 'north_entrance',
    label: 'North Entrance',
    latitude: -25.683022827978146,
    longitude: 28.131417731026822,
  );

  static const CampusEntry studentParkingEntrance = CampusEntry(
    nodeId: 'student-parking_entrance',
    label: 'Student Parking Entrance',
    latitude: -25.68325138019362,
    longitude: 28.131993722434874,
  );

  // Estimated GPS positions derived from the updated map nodes.
  // Verify these four entry locations during the next campus test.
  static final CampusEntry westEntrance = _entryFromMap(
    'west_entrance',
    'West Entrance',
    379,
    1261,
  );

  static final CampusEntry oostendeMainEntrance = _entryFromMap(
    'oostende-main_gate',
    'Oostende Main Entrance',
    2653,
    1572,
  );

  static final CampusEntry florenvilleMainGate = _entryFromMap(
    'florenville-main_gate',
    'Florenville Main Gate',
    2626,
    1035,
  );

  static final CampusEntry florenvilleMainEntrance = _entryFromMap(
    'florenville-main_entrance',
    'Florenville Main Entrance',
    2546,
    888,
  );

  static final List<CampusEntry> entries = List<CampusEntry>.unmodifiable([
    mainGate,
    mainEntrance,
    northGate,
    northEntrance,
    studentParkingEntrance,
    westEntrance,
    oostendeMainEntrance,
    florenvilleMainGate,
    florenvilleMainEntrance,
  ]);

  static CampusEntry _entryFromMap(
    String nodeId,
    String label,
    double x,
    double y,
  ) {
    // Inverse of toMapOffset, including the current GPS fine offsets.
    // Inputs are the top-left positions of 4 x 4 entrance squares.
    final dx =
        x +
        GraphNode.entranceCentreOffset -
        _xOffset -
        BcWaysMapConstants.gpsOffsetX;
    final dy =
        y +
        GraphNode.entranceCentreOffset -
        _yOffset -
        BcWaysMapConstants.gpsOffsetY;
    final determinant = _xEast * _yNorth - _xNorth * _yEast;

    if (determinant.abs() < 1e-12) {
      throw StateError('GPS/map calibration cannot be inverted.');
    }

    final east = (dx * _yNorth - dy * _xNorth) / determinant;
    final north = (_xEast * dy - _yEast * dx) / determinant;
    final latitudeRadians = _originLatitude * math.pi / 180.0;

    return CampusEntry(
      nodeId: nodeId,
      label: label,
      latitude: _originLatitude + north / _earthRadius * 180.0 / math.pi,
      longitude:
          _originLongitude +
          east / (_earthRadius * math.cos(latitudeRadians)) * 180.0 / math.pi,
    );
  }

  // ---------------------------------------------------------------------------
  // GPS -> SVG CALIBRATION
  // ---------------------------------------------------------------------------
  //
  // These coefficients were calculated from these known matching points:
  //
  // main_gate
  // GPS  -> -25.68312072540506, 28.131238693594774
  // SVG  -> 1287, 1917
  //
  // north_gate
  // GPS  -> -25.682989591179105, 28.131300384395328
  // SVG  -> 1327, 1863
  //
  // north_entrance
  // GPS  -> -25.683022827978146, 28.131417731026822
  // SVG  -> 1370, 1877
  //
  // student-parking_entrance
  // GPS  -> -25.68325138019362, 28.131993722434874
  // SVG  -> 1680, 1985
  //
  // We first convert GPS differences to local east/north metres,
  // then transform those metres into your SVG coordinate space.

  static const double _originLatitude = -25.68209603990679;

  static const double _originLongitude = 28.130735259555863;

  static const double _earthRadius = 6378137.0;

  // Affine calibration coefficients.
  static const double _xEast = 4.73363291;
  static const double _xNorth = -0.01453758;
  static const double _xOffset = 1055.0;

  static const double _yEast = 0.06463142;
  static const double _yNorth = -4.74778265;
  static const double _yOffset = 1389.0;

  /// Stored with a survey so its map coordinates can be reproduced later.
  static Map<String, dynamic> get recordingCalibration => {
    'width': 3000,
    'height': 3000,
    'originLatitude': _originLatitude,
    'originLongitude': _originLongitude,
    'earthRadius': _earthRadius,
    'xEast': _xEast,
    'xNorth': _xNorth,
    'xOffset': _xOffset,
    'yEast': _yEast,
    'yNorth': _yNorth,
    'yOffset': _yOffset,
    'gpsOffsetX': BcWaysMapConstants.gpsOffsetX,
    'gpsOffsetY': BcWaysMapConstants.gpsOffsetY,
  };

  /// Physical distance from the inverse of the existing affine calibration.
  static double mapDistanceMeters(Offset a, Offset b) {
    final d = a - b;
    final determinant = _xEast * _yNorth - _xNorth * _yEast;
    final east = (d.dx * _yNorth - d.dy * _xNorth) / determinant;
    final north = (_xEast * d.dy - _yEast * d.dx) / determinant;
    return math.sqrt(east * east + north * north);
  }

  /// Converts live GPS into your 3000 x 3000 SVG coordinate system.
  Offset toMapOffset(geo.Position gps) {
    final latitudeRadians = _originLatitude * math.pi / 180.0;

    final deltaLatitudeRadians =
        (gps.latitude - _originLatitude) * math.pi / 180.0;

    final deltaLongitudeRadians =
        (gps.longitude - _originLongitude) * math.pi / 180.0;

    final northMeters = deltaLatitudeRadians * _earthRadius;

    final eastMeters =
        deltaLongitudeRadians * _earthRadius * math.cos(latitudeRadians);

    final x =
        eastMeters * _xEast +
        northMeters * _xNorth +
        _xOffset +
        BcWaysMapConstants.gpsOffsetX;

    final y =
        eastMeters * _yEast +
        northMeters * _yNorth +
        _yOffset +
        BcWaysMapConstants.gpsOffsetY;

    return Offset(x, y);
  }

  // ---------------------------------------------------------------------------
  // MAP BOUNDS
  // ---------------------------------------------------------------------------

  bool isInsideMapCanvas(Offset position) {
    return position.dx >= 0 &&
        position.dx <= 3000 &&
        position.dy >= 0 &&
        position.dy <= 3000;
  }

  // ---------------------------------------------------------------------------
  // NEAREST CAMPUS ENTRY
  // ---------------------------------------------------------------------------
  List<CampusEntry> get mainCampusEntries => entries
      .where(
        (entry) =>
            entry.nodeId == 'main_gate' || entry.nodeId == 'main_entrance',
      )
      .toList();

  List<CampusEntry> get northCampusEntries => entries
      .where(
        (entry) =>
            entry.nodeId == 'north_gate' ||
            entry.nodeId == 'north_entrance' ||
            entry.nodeId == 'student-parking_entrance' ||
            entry.nodeId == 'west_entrance' ||
            entry.nodeId == 'oostende-main_gate' ||
            entry.nodeId == 'florenville-main_gate' ||
            entry.nodeId == 'florenville-main_entrance',
      )
      .toList();

  CampusEntry nearestEntry(geo.Position user, {CampusYard? destinationYard}) {
    final List<CampusEntry> candidates;

    if (destinationYard == CampusYard.main) {
      candidates = mainCampusEntries;
    } else if (destinationYard == CampusYard.north) {
      candidates = northCampusEntries;
    } else {
      // No destination selected yet.
      // Use all campus entrances.
      candidates = entries;
    }

    CampusEntry nearest = candidates.first;

    double nearestDistance = distanceToEntry(user, nearest);

    for (final entry in candidates.skip(1)) {
      final distance = distanceToEntry(user, entry);

      if (distance < nearestDistance) {
        nearest = entry;

        nearestDistance = distance;
      }
    }

    return nearest;
  }

  double distanceToEntry(geo.Position user, CampusEntry entry) {
    return geo.Geolocator.distanceBetween(
      user.latitude,
      user.longitude,
      entry.latitude,
      entry.longitude,
    );
  }

  double bearingToEntry(geo.Position user, CampusEntry entry) {
    return geo.Geolocator.bearingBetween(
      user.latitude,
      user.longitude,
      entry.latitude,
      entry.longitude,
    );
  }

  /// Rotation for the navigation arrow.
  ///
  /// When GPS heading is available, the arrow becomes relative
  /// to the user's direction of travel.
  double arrowRotation(geo.Position user, CampusEntry entry) {
    final bearing = bearingToEntry(user, entry);

    final heading = user.heading.isFinite ? user.heading : 0.0;

    double difference = bearing - heading;

    while (difference > 180) {
      difference -= 360;
    }

    while (difference < -180) {
      difference += 360;
    }

    return difference * math.pi / 180;
  }
}
