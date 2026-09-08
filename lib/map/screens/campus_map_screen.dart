/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Primary application view for the campus_map_screen.
 */

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/sync_up_colors.dart';
import '../../utils/responsive.dart';
import '../models/fit_room.dart';
import '../models/graph_models.dart';
import '../models/map_path.dart';
import '../services/fit_map_data_service.dart';
import '../services/graph_pathfinder.dart';
import '../widgets/building_map_painter.dart';
import '../widgets/floor_selector.dart';
import '../widgets/navigation_directions_card.dart';
import '../widgets/room_details_sheet.dart';
import '../widgets/room_search_bar.dart';
import '../theme/fit_map_theme.dart';

class CampusMapScreen extends StatefulWidget {
  final String? initialRoomId;
  final String? initialFloor;
  final String? initialStartRoomId;
  final bool autoNavigate;

  const CampusMapScreen({
    super.key,
    this.initialRoomId,
    this.initialFloor,
    this.initialStartRoomId,
    this.autoNavigate = false,
  });

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController = TransformationController();
  late final AnimationController _pulseController;

  bool _isLoading = true;
  String _selectedFloor = '1';
  FitRoom? _selectedRoom;
  FitRoom? _startRoom;
  FitRoom? _destinationRoom;

  GraphPathResult? _currentPathResult;
  List<NavigationInstruction> _navigationInstructions = [];
  double _currentZoom = 1.0;
  bool _showLegend = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _transformController.addListener(_onTransformChanged);
    _initData();
  }

  void _onTransformChanged() {
    final zoom = _transformController.value.getMaxScaleOnAxis();
    if ((zoom - _currentZoom).abs() > 0.05) {
      setState(() {
        _currentZoom = zoom;
      });
    }
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      FitMapDataService.instance.load(),
      GraphPathfinder.instance.loadGraph(),
    ]);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // Process initial room if provided
    if (widget.initialRoomId != null) {
      final room = FitMapDataService.instance.findRoomByLooseString(widget.initialRoomId);
      if (room != null) {
        _selectRoom(room, autoCenter: true);
        if (widget.autoNavigate) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _setDestination(room);
            }
          });
        }
      } else {
        final numMatch = RegExp(r'\b([1-4])[0-9]{2}\b').firstMatch(widget.initialRoomId!);
        if (numMatch != null) {
          setState(() {
            _selectedFloor = numMatch.group(1)!;
          });
        } else if (widget.initialFloor != null) {
          setState(() {
            _selectedFloor = widget.initialFloor!;
          });
        }
      }
    } else if (widget.initialFloor != null) {
      setState(() {
        _selectedFloor = widget.initialFloor!;
      });
    }

    // Process initial start room or default to A101
    final startRoomQuery = widget.initialStartRoomId ?? 'A101';
    final start = FitMapDataService.instance.findRoomByLooseString(startRoomQuery);
    if (start != null) {
      _startRoom = start;
      if (_destinationRoom != null) {
        _calculateRoute();
      }
    }
  }

  void _selectRoom(FitRoom room, {bool autoCenter = true}) {
    setState(() {
      _selectedRoom = room;
      _selectedFloor = room.floorNo;
    });

    if (autoCenter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerOnPoint(room.center);
      });
    }
  }

  void _centerOnPoint(Offset point) {
    if (point == Offset.zero) return;

    const targetZoom = 1.6;
    final size = MediaQuery.of(context).size;
    final viewCenterX = size.width / 2;
    final viewCenterY = size.height / 2;

    final translationX = viewCenterX - (point.dx * targetZoom);
    final translationY = viewCenterY - (point.dy * targetZoom);

    final matrix = Matrix4.diagonal3Values(targetZoom, targetZoom, 1.0)
      ..setTranslationRaw(translationX, translationY, 0.0);

    _transformController.value = matrix;
  }

  void _resetZoom() {
    _centerOnFloor(_selectedFloor);
  }

  void _centerOnFloor(String floorNo) {
    final bounds = FitMapDataService.instance.boundsForFloor(floorNo);
    final size = MediaQuery.of(context).size;

    final scaleX = size.width / bounds.width;
    final scaleY = size.height / bounds.height;
    final scale = (math.min(scaleX, scaleY) * 0.82).clamp(0.4, 2.5);

    final viewCenterX = size.width / 2;
    final viewCenterY = size.height / 2;
    final boundsCenterX = bounds.center.dx;
    final boundsCenterY = bounds.center.dy;

    final tx = viewCenterX - (boundsCenterX * scale);
    final ty = viewCenterY - (boundsCenterY * scale);

    final matrix = Matrix4.diagonal3Values(scale, scale, 1.0)
      ..setTranslationRaw(tx, ty, 0.0);

    _transformController.value = matrix;
  }

  void _handleMapTap(TapUpDetails details) {
    final tapPosition = _transformController.toScene(details.localPosition);
    final rooms = FitMapDataService.instance.roomsForFloor(_selectedFloor);

    FitRoom? tappedRoom;
    for (final room in rooms) {
      if (room.coords.length < 3) continue;
      if (_isPointInsidePolygon(tapPosition, room.coords)) {
        tappedRoom = room;
        break;
      }
    }

    if (tappedRoom != null) {
      _selectRoom(tappedRoom, autoCenter: false);
    } else {
      setState(() {
        _selectedRoom = null;
      });
    }
  }

  bool _isPointInsidePolygon(Offset point, List<Offset> polygon) {
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if (((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy)) &&
          (point.dx <
              (polygon[j].dx - polygon[i].dx) *
                      (point.dy - polygon[i].dy) /
                      (polygon[j].dy - polygon[i].dy) +
                  polygon[i].dx)) {
        inside = !inside;
      }
    }
    return inside;
  }

  void _setDestination(FitRoom room) {
    setState(() {
      _destinationRoom = room;
      _selectedRoom = null;
    });

    // Default start room if none set: Corridor A101 or Entrance on Ground Floor
    _startRoom ??= FitMapDataService.instance.findRoomByLooseString('A101') ??
        FitMapDataService.instance.findRoomByLooseString('A109') ??
        FitMapDataService.instance.findRoomByLooseString('A001') ??
        FitMapDataService.instance.allRooms.firstOrNull;

    _calculateRoute();
  }

  void _setStartRoom(FitRoom room) {
    setState(() {
      _startRoom = room;
      _selectedRoom = null;
    });

    if (_destinationRoom != null) {
      _calculateRoute();
    }
  }

  void _calculateRoute() {
    if (_startRoom == null || _destinationRoom == null) return;

    final result = GraphPathfinder.instance.findShortestPath(
      _startRoom!.id,
      _startRoom!.floorNo,
      _destinationRoom!.id,
      _destinationRoom!.floorNo,
    );

    if (result != null) {
      final instructions = GraphPathfinder.instance.generateInstructions(result);
      setState(() {
        _currentPathResult = result;
        _navigationInstructions = instructions;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No path found between ${_startRoom!.id} and ${_destinationRoom!.id}',
          ),
        ),
      );
    }
  }

  void _clearRoute() {
    setState(() {
      _destinationRoom = null;
      _currentPathResult = null;
      _navigationInstructions = [];
    });
  }

  List<MapPath> _buildPathsForCurrentFloor() {
    if (_currentPathResult == null) return const [];

    final segments = <List<Offset>>[];
    List<Offset> currentSegment = [];

    for (final nodeId in _currentPathResult!.path) {
      if (!nodeId.contains('__')) continue;
      final parts = nodeId.split('__');
      final roomCode = parts.first;
      final floor = parts.last.replaceAll('+', '');

      if (floor == _selectedFloor) {
        final room = FitMapDataService.instance.getRoomById(roomCode);
        if (room != null && room.center != Offset.zero) {
          currentSegment.add(room.center);
        }
      } else {
        // Path left the current floor: close contiguous segment
        if (currentSegment.length >= 2) {
          segments.add(List.of(currentSegment));
        }
        currentSegment.clear();
      }
    }
    if (currentSegment.length >= 2) {
      segments.add(List.of(currentSegment));
    }

    return segments.map((pts) => MapPath.navigation(points: pts)).toList();
  }

  List<FloorTransitionMarker> _buildTransitionsForCurrentFloor() {
    if (_currentPathResult == null || _currentPathResult!.path.length < 2) return const [];

    final transitions = <FloorTransitionMarker>[];
    final path = _currentPathResult!.path;

    for (int i = 0; i < path.length; i++) {
      final currNode = path[i];
      if (!currNode.contains('__')) continue;
      final currParts = currNode.split('__');
      final currRoomCode = currParts.first;
      final currFloor = currParts.last.replaceAll('+', '');

      if (currFloor != _selectedFloor) continue;

      // Check if moving to a next node on a different floor (Exit transition)
      if (i + 1 < path.length) {
        final nextNode = path[i + 1];
        if (nextNode.contains('__')) {
          final nextFloor = nextNode.split('__').last.replaceAll('+', '');
          if (nextFloor != _selectedFloor) {
            final room = FitMapDataService.instance.getRoomById(currRoomCode);
            if (room != null && room.center != Offset.zero) {
              final nextNum = int.tryParse(nextFloor) ?? 0;
              final currNum = int.tryParse(currFloor) ?? 0;
              final isUp = nextNum > currNum;
              transitions.add(
                FloorTransitionMarker(
                  position: room.center,
                  label: isUp ? '↑ ${nextFloor}F' : '↓ ${nextFloor}F',
                  targetFloor: nextFloor,
                  isUp: isUp,
                  roomId: currRoomCode,
                ),
              );
            }
          }
        }
      }

      // Check if arriving from a previous node on a different floor (Entry transition)
      if (i > 0) {
        final prevNode = path[i - 1];
        if (prevNode.contains('__')) {
          final prevFloor = prevNode.split('__').last.replaceAll('+', '');
          if (prevFloor != _selectedFloor) {
            final room = FitMapDataService.instance.getRoomById(currRoomCode);
            if (room != null && room.center != Offset.zero) {
              final prevNum = int.tryParse(prevFloor) ?? 0;
              final currNum = int.tryParse(currFloor) ?? 0;
              final isUp = currNum > prevNum;
              transitions.add(
                FloorTransitionMarker(
                  position: room.center,
                  label: isUp ? '↑ from ${prevFloor}F' : '↓ from ${prevFloor}F',
                  targetFloor: prevFloor,
                  isUp: isUp,
                  roomId: currRoomCode,
                ),
              );
            }
          }
        }
      }
    }

    return transitions;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Responsive.isTabletOrLarger(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: colors.primary),
              const SizedBox(height: 16),
              Text(
                'Loading BUT FIT Campus Maps...',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final rooms = FitMapDataService.instance.roomsForFloor(_selectedFloor);
    final bounds = FitMapDataService.instance.boundsForFloor(_selectedFloor);
    final paths = _buildPathsForCurrentFloor();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Interactive Map Area
          Positioned.fill(
            child: GestureDetector(
              onTapUp: _handleMapTap,
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.3,
                maxScale: 6.0,
                boundaryMargin: const EdgeInsets.all(500),
                constrained: false,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: Size(
                        math.max(800.0, bounds.width + bounds.left + 100),
                        math.max(1100.0, bounds.height + bounds.top + 100),
                      ),
                      painter: BuildingMapPainter(
                        rooms: rooms,
                        footprints: FitMapDataService.instance.footprints,
                        buildingLetters: FitMapDataService.instance.buildingLetters,
                        streetLabels: FitMapDataService.instance.streetLabels,
                        selectedRoomId: _selectedRoom?.id,
                        startRoomId: _startRoom?.floorNo == _selectedFloor ? _startRoom?.id : null,
                        destinationRoomId:
                            _destinationRoom?.floorNo == _selectedFloor ? _destinationRoom?.id : null,
                        pulseValue: _pulseController.value,
                        paths: paths,
                        transitionMarkers: _buildTransitionsForCurrentFloor(),
                        isDarkMode: isDark,
                        currentZoom: _currentZoom,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Top Header & Search Bars
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (Navigator.canPop(context)) ...[
                  Container(
                    height: 48,
                    width: 48,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: colors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RoomSearchBar(
                        hintText: 'Starting point (e.g. A109) or Current Location',
                        prefixIcon: Icon(Icons.location_on, color: colors.primary, size: 20),
                        initialValue: widget.initialStartRoomId ?? 'A101',
                        onRoomSelected: (room) {
                          _setStartRoom(room);
                        },
                        onClear: () {
                          setState(() {
                            _startRoom = null;
                            _clearRoute();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      RoomSearchBar(
                        hintText: 'Search room, lab, or office...',
                        prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary, size: 20),
                        initialValue: widget.initialRoomId,
                        onRoomSelected: (room) => _selectRoom(room, autoCenter: true),
                        onClear: () {
                          setState(() => _selectedRoom = null);
                          _clearRoute();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Color Guide / Legend Button
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: _showLegend ? colors.primary.withValues(alpha: 0.15) : colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _showLegend ? colors.primary : colors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.palette_outlined,
                          color: _showLegend ? colors.primary : colors.textSecondary,
                          size: 20,
                        ),
                        tooltip: 'Campus Color Guide',
                        onPressed: () {
                          setState(() => _showLegend = !_showLegend);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Reset Zoom Button
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.center_focus_strong_rounded,
                          color: colors.textSecondary,
                          size: 20,
                        ),
                        tooltip: 'Recenter Map',
                        onPressed: _resetZoom,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Floor Selector
          Positioned(
            right: 16,
            bottom: _selectedRoom != null || _currentPathResult != null
                ? (isDesktop ? 220 : 260)
                : (isDesktop ? 40 : 30),
            child: FloorSelector(
              selectedFloor: _selectedFloor,
              onFloorChanged: (newFloor) {
                setState(() => _selectedFloor = newFloor);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _selectedRoom == null && _currentPathResult == null) {
                    _centerOnFloor(newFloor);
                  }
                });
              },
            ),
          ),

          // Navigation Instructions Card (when routing is active)
          if (_currentPathResult != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: NavigationDirectionsCard(
                pathResult: _currentPathResult!,
                instructions: _navigationInstructions,
                startRoomTitle: _startRoom?.title ?? _startRoom?.id ?? 'Start',
                destinationRoomTitle:
                    _destinationRoom?.title ?? _destinationRoom?.id ?? 'Destination',
                onClear: _clearRoute,
                currentFloor: _selectedFloor,
                onFloorSelected: (f) {
                  setState(() => _selectedFloor = f);
                  _centerOnFloor(f);
                },
              ),
            ),

          // Room Details Bottom Sheet (when room is tapped)
          if (_selectedRoom != null && _currentPathResult == null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 450 : double.infinity,
                ),
                child: RoomDetailsSheet(
                  room: _selectedRoom!,
                  onNavigateHere: () => _setDestination(_selectedRoom!),
                  onSetAsStart: () => _setStartRoom(_selectedRoom!),
                  onClose: () {
                    setState(() => _selectedRoom = null);
                  },
                ),
              ),
            ),

          // Campus Color Legend (when toggled on)
          if (_showLegend && _selectedRoom == null && _currentPathResult == null)
            Positioned(
              left: 16,
              bottom: isDesktop ? 30 : 20,
              child: _buildLegendCard(colors, isDark, isDesktop),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendCard(dynamic colors, bool isDark, bool isDesktop) {
    return Container(
      width: isDesktop ? 310 : 270,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E293B) : Colors.white).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A9E0).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.palette_rounded,
                  color: Color(0xFF00A9E0),
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'FIT VUT Campus Colors',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _showLegend = false),
                child: Icon(Icons.close, size: 17, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _legendItem(FitMapTheme.lectureBlue, 'Lecture Halls & Labs', isDark),
          _legendItem(FitMapTheme.officeYellow, 'Classrooms & Offices', isDark),
          _legendItem(FitMapTheme.departmentOrange, 'Departments & Staff', isDark),
          _legendItem(FitMapTheme.toiletsGreen, 'Restrooms (WC)', isDark),
          _legendItem(FitMapTheme.corridorGray, 'Corridors & Respirium', isDark),
          _legendItem(FitMapTheme.stairsDarkGray, 'Staircases & Elevators', isDark),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black.withValues(alpha: 0.3), width: 0.8),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
