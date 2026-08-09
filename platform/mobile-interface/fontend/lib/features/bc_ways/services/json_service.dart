import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/destination.dart';
import '../models/edge.dart';
import '../models/node.dart';

class JsonService {

  Future<List<Node>> loadNodes() async {

    final jsonString =
        await rootBundle.loadString("assets/data/nodes.json");

    final List<dynamic> jsonData = json.decode(jsonString);

    return jsonData
        .map((item) => Node.fromJson(item))
        .toList();
  }

  Future<List<Edge>> loadEdges() async {

    final jsonString =
        await rootBundle.loadString("assets/data/edges.json");

    final List<dynamic> jsonData = json.decode(jsonString);

    return jsonData
        .map((item) => Edge.fromJson(item))
        .toList();
  }

  Future<List<Destination>> loadDestinations() async {

    final jsonString =
        await rootBundle.loadString("assets/data/destinations.json");

    final List<dynamic> jsonData = json.decode(jsonString);

    return jsonData
        .map((item) => Destination.fromJson(item))
        .toList();
  }
}