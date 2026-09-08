import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/graph_models.dart';
import '../models/map_path.dart';

class GraphPathfinder {
  GraphPathfinder._();
  static final GraphPathfinder instance = GraphPathfinder._();

  final Map<String, List<(String, double)>> _graph = {};
  final Map<String, GraphNode> _nodes = {};
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Future<void> loadGraph() async {
    if (_isLoaded) return;

    try {
      final nodesString = await rootBundle.loadString('assets/graph/nodes.csv');
      final nodesLines = nodesString.split('\n');

      for (int i = 1; i < nodesLines.length; i++) {
        final line = nodesLines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(',');
        if (parts.length >= 3) {
          final id = parts[0].trim();
          final name = parts[1].trim();
          final floor = parts[2].trim();

          _nodes[id] = GraphNode(id: id, name: name, floor: floor);
          _graph[id] = [];
        }
      }

      final edgesString = await rootBundle.loadString('assets/graph/edges.csv');
      final edgesLines = edgesString.split('\n');

      for (int i = 1; i < edgesLines.length; i++) {
        final line = edgesLines[i].trim();
        if (line.isEmpty) continue;

        final parts = line.split(',');
        if (parts.length >= 3) {
          final room1 = parts[0].trim();
          final room2 = parts[2].trim();
          final dist = double.tryParse(parts[1].trim()) ?? 0.0;

          if (dist > 0 && _graph.containsKey(room1) && _graph.containsKey(room2)) {
            // Check if vertical transition between different floors
            final floor1 = room1.contains('__') ? room1.split('__').last : '';
            final floor2 = room2.contains('__') ? room2.split('__').last : '';
            final isVertical = floor1.isNotEmpty && floor2.isNotEmpty && floor1 != floor2;

            // Realistic vertical penalty (stairs/elevator take physical effort & ~30-45s = ~40m walk)
            final effectiveDist = isVertical ? (dist + 0.0020) : dist;

            _graph[room1]!.add((room2, effectiveDist));
            _graph[room2]!.add((room1, effectiveDist));
          }
        }
      }

      _isLoaded = true;
    } catch (e, stack) {
      debugPrint('Error loading FIT map graph: $e\n$stack');
      _isLoaded = false;
      rethrow;
    }
  }

  String _toGraphNodeId(String roomId, String floor) {
    String normalizedFloor = floor.trim();
    if (!normalizedFloor.startsWith('+') && !normalizedFloor.startsWith('-')) {
      normalizedFloor = '+$normalizedFloor';
    }
    return '${roomId.trim().toUpperCase()}__$normalizedFloor';
  }

  GraphNode? getNode(String nodeId) => _nodes[nodeId];

  /// Finds the corresponding graph node id for a room id across known nodes if floor is uncertain
  String? findBestNodeIdForRoom(String roomId, [String? preferredFloor]) {
    final cleanRoom = roomId.trim().toUpperCase();
    if (preferredFloor != null) {
      final test = _toGraphNodeId(cleanRoom, preferredFloor);
      if (_nodes.containsKey(test)) return test;
    }

    // Try all floors
    for (final floor in ['+1', '+2', '+3', '+4', '-1', '-2']) {
      final test = '${cleanRoom}__$floor';
      if (_nodes.containsKey(test)) return test;
    }

    // Search keys that start with roomId
    for (final key in _nodes.keys) {
      if (key.startsWith('${cleanRoom}__')) return key;
    }

    return null;
  }

  GraphPathResult? findShortestPath(
    String startRoomId,
    String startFloor,
    String endRoomId,
    String endFloor,
  ) {
    if (!_isLoaded) return null;

    final startNodeId = findBestNodeIdForRoom(startRoomId, startFloor);
    final endNodeId = findBestNodeIdForRoom(endRoomId, endFloor);

    if (startNodeId == null || !_graph.containsKey(startNodeId)) {
      debugPrint('Start node not found in graph: $startRoomId (floor $startFloor)');
      return null;
    }

    if (endNodeId == null || !_graph.containsKey(endNodeId)) {
      debugPrint('End node not found in graph: $endRoomId (floor $endFloor)');
      return null;
    }

    final distances = <String, double>{};
    final previous = <String, String?>{};
    final unvisited = <String>{};

    for (final nodeId in _graph.keys) {
      distances[nodeId] = double.infinity;
      previous[nodeId] = null;
      unvisited.add(nodeId);
    }

    distances[startNodeId] = 0.0;

    while (unvisited.isNotEmpty) {
      String? currentNode;
      double minDist = double.infinity;

      for (final node in unvisited) {
        final dist = distances[node]!;
        if (dist < minDist) {
          minDist = dist;
          currentNode = node;
        }
      }

      if (currentNode == null || minDist == double.infinity) break;
      if (currentNode == endNodeId) break;

      unvisited.remove(currentNode);

      for (final (neighbor, weight) in _graph[currentNode]!) {
        if (!unvisited.contains(neighbor)) continue;

        final alt = distances[currentNode]! + weight;
        if (alt < distances[neighbor]!) {
          distances[neighbor] = alt;
          previous[neighbor] = currentNode;
        }
      }
    }

    if (distances[endNodeId] == double.infinity) {
      debugPrint('No path found from $startNodeId to $endNodeId');
      return null;
    }

    final path = <String>[];
    String? current = endNodeId;

    while (current != null) {
      path.insert(0, current);
      current = previous[current];
    }

    if (path.isEmpty || path.first != startNodeId) {
      return null;
    }

    final totalDistance = distances[endNodeId]!;

    return GraphPathResult(
      path: path,
      totalDistance: totalDistance,
      numberOfSteps: path.length - 1,
    );
  }

  List<NavigationInstruction> generateInstructions(GraphPathResult result) {
    final instructions = <NavigationInstruction>[];
    if (result.path.isEmpty) return instructions;

    int step = 1;
    String? currentFloor;

    for (int i = 0; i < result.path.length; i++) {
      final nodeId = result.path[i];
      final node = _nodes[nodeId];
      final roomName = node?.name ?? nodeId;
      final floor = node?.floor.replaceAll('+', '') ?? '';

      if (i == 0) {
        currentFloor = floor;
        instructions.add(
          NavigationInstruction(
            stepNumber: step++,
            text: 'Start at $roomName (Floor $floor)',
            icon: Icons.my_location,
            floor: floor,
            targetRoomId: node?.roomCode,
          ),
        );
        continue;
      }

      final prevNodeId = result.path[i - 1];
      final prevNode = _nodes[prevNodeId];
      final prevFloor = prevNode?.floor.replaceAll('+', '') ?? '';

      // Check if floor changed (stairs or elevator transition)
      if (floor != prevFloor && currentFloor != floor) {
        currentFloor = floor;
        final isElevator = roomName.toLowerCase().contains('elevator') ||
            (prevNode?.name.toLowerCase().contains('elevator') ?? false);
        final isStairs = roomName.toLowerCase().contains('stair') ||
            (prevNode?.name.toLowerCase().contains('stair') ?? false);

        instructions.add(
          NavigationInstruction(
            stepNumber: step++,
            text: isElevator
                ? 'Take elevator to Floor $floor'
                : (isStairs ? 'Take stairs to Floor $floor' : 'Proceed to Floor $floor'),
            icon: isElevator ? Icons.elevator : Icons.stairs,
            floor: floor,
            targetRoomId: node?.roomCode,
          ),
        );
        continue;
      }

      // Check if final destination
      if (i == result.path.length - 1) {
        instructions.add(
          NavigationInstruction(
            stepNumber: step++,
            text: 'Arrive at $roomName (Floor $floor)',
            icon: Icons.location_on,
            floor: floor,
            targetRoomId: node?.roomCode,
          ),
        );
        continue;
      }

      // Major waypoint / corridor transition
      final isCorridor = roomName.toLowerCase().contains('corridor');
      if (!isCorridor) {
        instructions.add(
          NavigationInstruction(
            stepNumber: step++,
            text: 'Pass through $roomName',
            icon: Icons.directions_walk,
            floor: floor,
            targetRoomId: node?.roomCode,
          ),
        );
      }
    }

    return instructions;
  }
}
