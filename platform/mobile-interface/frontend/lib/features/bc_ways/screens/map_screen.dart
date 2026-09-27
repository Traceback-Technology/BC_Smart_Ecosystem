import 'package:flutter/material.dart';

class MapOverlay extends StatefulWidget {
  const MapOverlay({super.key});

  @override
  State<MapOverlay> createState() => _MapOverlayState();
}

class _MapOverlayState extends State<MapOverlay> {
  Offset userLocation = const Offset(180, 320); // simulated current position
  MapPin? selectedPin = MapPin("Cafeteria", const Offset(280, 150), "red");

  // Offset values will eventually be fed by the backend
  final List<MapPin> pins = [
    MapPin("Library", const Offset(80, 200), "teal"),
    MapPin("Cafeteria", const Offset(280, 150), "red"),
    MapPin("Reception", const Offset(180, 100), "amber"),
    MapPin("Main Gate", const Offset(60, 400), "amber"),
  ];

  Color _getColorFromName(String colorName) {
    switch (colorName) {
      case "teal":
        return Colors.teal;
      case "red":
        return Colors.red;
      case "amber":
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ================ LAYER 1: MAP BACKGROUND ================
          // TODO: Replace with real campus map image once asset is ready
          // e.g. Positioned.fill(child: Image.asset("assets/images/campus_map.png", fit: BoxFit.cover))
          Positioned.fill(child: Container(color: Colors.grey[200])),

          // ================ LAYER 2: PINS ================
          // Generated dynamically from the pins list (this is what backend will update)
          ...pins.map(
            (pin) => Positioned(
              left: pin.position.dx,
              top: pin.position.dy,
              child: Icon(
                Icons.location_on,
                color: _getColorFromName(pin.pinColor),
                size: 36,
              ),
            ),
          ),

          // ================ LAYER 3: ROUTE LINE ================
          // Only draws if a destination is currently selected
          if (selectedPin != null)
            Positioned.fill(
              child: CustomPaint(
                painter: RouteLinePainter(userLocation, selectedPin!.position),
              ),
            ),

          // ================ LAYER 4: USER LOCATION DOT ================
          // Moved AFTER the background so it's no longer hidden underneath it
          Positioned(
            left: userLocation.dx - 10,
            top: userLocation.dy - 10,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ),

          // ================ LAYER 5: SELECTED DESTINATION INFO CARD ================
          if (selectedPin != null)
            Positioned(
              top: 100,
              right: 16,
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.restaurant, size: 20),
                      const SizedBox(width: 8),
                      Text(selectedPin!.name),
                      const SizedBox(width: 8),
                      const Text("4 min . 280m"),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
          // ================ LAYER 6-8 COMBINED: HEADER + SEARCH + FILTERS ================
          // These three pieces are now one connected Column instead of three
          // independently-guessed Positioned values — this fixes the overlap issue
          // because Flutter now calculates the actual height itself.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    // ---- Header row: logo, title, bell ----
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          "assets/images/BC_Logo.png",
                          height: 50,
                          fit: BoxFit.contain,
                        ),
                        Column(
                          children: [
                            const Text(
                              "BC WAYS",
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF4B400),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 40,
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4B400),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),
                        Stack(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.notifications_none,
                                size: 28,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 8,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    "3",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ), // spacing instead of a guessed "top" value
                    // ---- Search bar ----
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search destination",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: const Icon(Icons.tune),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ---- Filter chips ----
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Chip(
                            label: const Text("All"),
                            backgroundColor: Colors.amber.shade100,
                          ),
                          const SizedBox(width: 8),
                          const Chip(label: Text("Buildings")),
                          const SizedBox(width: 8),
                          const Chip(label: Text("Classrooms")),
                          const SizedBox(width: 8),
                          const Chip(label: Text("Parking")),
                          const SizedBox(width: 8),
                          const Chip(label: Text("Cafeteria")),
                          const SizedBox(width: 8),
                          const Chip(label: Text("Residences")),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 15,
            bottom: 180,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: "gps",
                  onPressed: () {},
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: "locate",
                  onPressed: () {},
                  child: const Icon(Icons.navigation),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: "layers",
                  onPressed: () {},
                  child: const Icon(Icons.layers),
                ),
              ],
            ),
          ),

          // ================ LAYER 10: BOTTOM NAVIGATION INFO PANEL ================
          // FIX: this was missing its Positioned wrapper, so it wasn't
          // anchored to the bottom of the screen — it would've rendered
          // wherever Stack defaults non-positioned children (top-left).
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_walk),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "4 min",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text("280 m"),
                      SizedBox(height: 5),
                      Text("Via Main Path"),
                      Text(
                        "100% accessible",
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                    onPressed: () {},
                    child: const Text("Start Navigation"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Data model representing a single map pin.
// Backend will eventually supply a list of these with real coordinates.
class MapPin {
  final String name;
  final Offset position;
  final String pinColor;

  MapPin(this.name, this.position, this.pinColor);
}

// Draws a straight line between two points — used for the route line
// from the user's current location to the selected destination pin.
class RouteLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;

  RouteLinePainter(this.start, this.end);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3;
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant RouteLinePainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.end != end;
  }
}
