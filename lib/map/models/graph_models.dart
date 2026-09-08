/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Defines data models and entities for graph_models.
 */

class GraphNode {
  final String id;
  final String name;
  final String floor;

  const GraphNode({
    required this.id,
    required this.name,
    required this.floor,
  });

  /// Extracts the base room code (e.g. 'A112' from 'A112__+1')
  String get roomCode {
    if (id.contains('__')) {
      return id.split('__').first;
    }
    return id;
  }
}

class GraphEdge {
  final String room1;
  final String room2;
  final double distance;

  const GraphEdge({
    required this.room1,
    required this.room2,
    required this.distance,
  });
}

class GraphPathResult {
  final List<String> path; // Sequence of node IDs: "ROOM__+FLOOR"
  final double totalDistance;
  final int numberOfSteps;

  const GraphPathResult({
    required this.path,
    required this.totalDistance,
    required this.numberOfSteps,
  });

  double get distanceInMeters => totalDistance * 20000;

  String get formattedDistance {
    final meters = distanceInMeters;
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  /// List of distinct floors involved in this path in order
  List<String> get floorsInPath {
    final list = <String>[];
    for (final node in path) {
      if (node.contains('__')) {
        final floor = node.split('__').last.replaceAll('+', '');
        if (list.isEmpty || list.last != floor) {
          list.add(floor);
        }
      }
    }
    return list;
  }
}
