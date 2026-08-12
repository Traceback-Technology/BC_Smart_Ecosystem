import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../models/node.dart';
import '../services/dijkstra_service.dart';
import '../services/graph_service.dart';
import '../services/json_service.dart';
import '../widgets/campus_map.dart';
import '../models/edge.dart';
import '../models/graph.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final JsonService jsonService = JsonService();

  List<Destination> destinations = [];
  List<Node> route = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  late Graph graph;
  late List<Node> nodes;
  late List<Edge> edges;

  Future<void> loadData() async {
    nodes = await jsonService.loadNodes();
    edges = await jsonService.loadEdges();
    destinations = await jsonService.loadDestinations();

    graph = GraphService().buildGraph(nodes, edges);

    route = DijkstraService().shortestPath(
      graph,
      "psi_entrance",
      "main-library_entrance",
    );

    print("Route contains ${route.length} nodes");

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: CampusMap(
        destinations: destinations,
        route: route,
        onDestinationTap: navigateTo,
      ),
    );
  }

  void navigateTo(Destination destination) {
  setState(() {
    route = DijkstraService().shortestPath(
      graph,
      "main_gate",
      destination.nearestNode,
    );
  });
}
}