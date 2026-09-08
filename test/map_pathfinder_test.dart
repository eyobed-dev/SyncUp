/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Provides functionality for map_pathfinder_test.dart.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:sync_up/map/services/fit_map_data_service.dart';
import 'package:sync_up/map/services/graph_pathfinder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Campus Map & Graph Pathfinder Tests', () {
    test('FitMapDataService loads and parses room data', () async {
      await FitMapDataService.instance.load();
      expect(FitMapDataService.instance.isLoaded, isTrue);
      expect(FitMapDataService.instance.allRooms.isNotEmpty, isTrue);

      // Verify known room lookup
      final c201 = FitMapDataService.instance.findRoomByLooseString('C201');
      expect(c201, isNotNull);
      expect(c201!.id, equals('C201'));
      expect(c201.floorNo, equals('2'));
      expect(c201.coords.isNotEmpty, isTrue);

      // Verify loose search
      final roomFromText = FitMapDataService.instance.findRoomByLooseString('Office C201');
      expect(roomFromText, isNotNull);
      expect(roomFromText!.id, equals('C201'));

      final roomFromOfficeNumber = FitMapDataService.instance.findRoomByLooseString('Office 312');
      expect(roomFromOfficeNumber, isNotNull);
      expect(roomFromOfficeNumber!.id, equals('L312'));

      final roomFromHyphen = FitMapDataService.instance.findRoomByLooseString('A-112');
      expect(roomFromHyphen, isNotNull);
      expect(roomFromHyphen!.id, equals('A112'));

      // Verify floor 4 room loading and parsing
      final floor4Rooms = FitMapDataService.instance.roomsForFloor('4');
      expect(floor4Rooms.isNotEmpty, isTrue);
      expect(floor4Rooms.length, greaterThanOrEqualTo(25));

      final l401 = FitMapDataService.instance.findRoomByLooseString('L401');
      expect(l401, isNotNull);
      expect(l401!.floorNo, equals('4'));
      expect(l401.isStaircase, isTrue);

      final q403 = FitMapDataService.instance.findRoomByLooseString('Q403');
      expect(q403, isNotNull);
      expect(q403!.floorNo, equals('4'));
      expect(q403.coords.length, greaterThanOrEqualTo(4));

      final r406 = FitMapDataService.instance.findRoomByLooseString('R406');
      expect(r406, isNotNull);
      expect(r406!.floorNo, equals('4'));

      // Verify floor 4 bounds
      final floor4Bounds = FitMapDataService.instance.boundsForFloor('4');
      expect(floor4Bounds.width, greaterThan(0));
      expect(floor4Bounds.height, greaterThan(0));
    });

    test('GraphPathfinder loads graph and calculates shortest path', () async {
      await GraphPathfinder.instance.loadGraph();
      expect(GraphPathfinder.instance.isLoaded, isTrue);

      // Find path between A112 and C201
      final path = GraphPathfinder.instance.findShortestPath('A112', '1', 'C201', '2');
      expect(path, isNotNull);
      expect(path!.path.isNotEmpty, isTrue);
      expect(path.distanceInMeters, greaterThan(0));
      expect(path.estimatedTimeMinutes, greaterThan(0));

      // Verify pathfinding to 4th floor
      final floor4Path = GraphPathfinder.instance.findShortestPath('L301', '3', 'L402', '4');
      expect(floor4Path, isNotNull);
      expect(floor4Path!.floorsInPath.contains('4'), isTrue);
      expect(floor4Path.path.any((n) => n.contains('+4')), isTrue);

      // Verify same-floor routing stays on same floor (avoids unnecessary stair climbing)
      final sameFloorPath = GraphPathfinder.instance.findShortestPath('A104', '1', 'F107', '1');
      expect(sameFloorPath, isNotNull);
      expect(sameFloorPath!.floorsInPath, equals(['1']));
      expect(sameFloorPath.path.every((n) => n.contains('+1')), isTrue);

      // Verify cross-complex navigation (Wing A to Wing L/Q/R)
      final crossComplexPath = GraphPathfinder.instance.findShortestPath('A112', '1', 'L402', '4');
      expect(crossComplexPath, isNotNull);
      expect(crossComplexPath!.path.isNotEmpty, isTrue);

      // Verify instructions generation
      final instructions = GraphPathfinder.instance.generateInstructions(path);
      expect(instructions.isNotEmpty, isTrue);
      expect(instructions.first.stepNumber, equals(1));
    });
  });
}
