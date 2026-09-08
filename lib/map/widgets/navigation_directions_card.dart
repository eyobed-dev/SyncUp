/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Reusable UI component for the navigation_directions_card interface.
 */

import 'package:flutter/material.dart';
import '../../theme/sync_up_colors.dart';
import '../models/graph_models.dart';
import '../models/map_path.dart';

class NavigationDirectionsCard extends StatefulWidget {
  final GraphPathResult pathResult;
  final List<NavigationInstruction> instructions;
  final String startRoomTitle;
  final String destinationRoomTitle;
  final VoidCallback onClear;
  final ValueChanged<String>? onFloorSelected;
  final String? currentFloor;

  const NavigationDirectionsCard({
    super.key,
    required this.pathResult,
    required this.instructions,
    required this.startRoomTitle,
    required this.destinationRoomTitle,
    required this.onClear,
    this.onFloorSelected,
    this.currentFloor,
  });

  @override
  State<NavigationDirectionsCard> createState() => _NavigationDirectionsCardState();
}

class _NavigationDirectionsCardState extends State<NavigationDirectionsCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Summary Bar
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.directions_walk_rounded,
                      color: Color(0xFF0D9488),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.pathResult.formattedDistance,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.startRoomTitle} → ${widget.destinationRoomTitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: colors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() => _isExpanded = !_isExpanded);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: colors.textSecondary,
                    onPressed: widget.onClear,
                  ),
                ],
              ),
            ),

            // Multi-Floor Route Stepper Bar
            if (widget.pathResult.floorsInPath.length > 1) ...[
              Padding(
                padding: const EdgeInsets.only(left: 14.0, right: 14.0, bottom: 10.0),
                child: Row(
                  children: [
                    Text(
                      'Floors in route: ',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (int i = 0; i < widget.pathResult.floorsInPath.length; i++) ...[
                              if (i > 0)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 13,
                                    color: colors.textSecondary.withValues(alpha: 0.6),
                                  ),
                                ),
                              InkWell(
                                onTap: () => widget.onFloorSelected?.call(widget.pathResult.floorsInPath[i]),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: widget.currentFloor == widget.pathResult.floorsInPath[i]
                                        ? const Color(0xFF0D9488)
                                        : colors.background,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: widget.currentFloor == widget.pathResult.floorsInPath[i]
                                          ? const Color(0xFF0D9488)
                                          : colors.border,
                                    ),
                                  ),
                                  child: Text(
                                    '${widget.pathResult.floorsInPath[i]}F',
                                    style: TextStyle(
                                      color: widget.currentFloor == widget.pathResult.floorsInPath[i]
                                          ? Colors.white
                                          : colors.textPrimary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Expandable Step-by-Step Instructions
            if (_isExpanded) ...[
              Divider(height: 1, thickness: 1, color: colors.border),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  shrinkWrap: true,
                  itemCount: widget.instructions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final instruction = widget.instructions[index];
                    return InkWell(
                      onTap: () {
                        if (instruction.floor.isNotEmpty) {
                          widget.onFloorSelected?.call(instruction.floor);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: colors.background,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                instruction.icon,
                                size: 14,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                instruction.text,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 12.5,
                                  fontWeight: index == 0 ||
                                          index == widget.instructions.length - 1
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (instruction.floor.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Floor ${instruction.floor}',
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
