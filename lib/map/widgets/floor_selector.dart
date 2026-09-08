/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Reusable UI component for the floor_selector interface.
 */

import 'package:flutter/material.dart';
import '../../theme/sync_up_colors.dart';

class FloorSelector extends StatelessWidget {
  final String selectedFloor;
  final ValueChanged<String> onFloorChanged;
  final bool isVertical;

  const FloorSelector({
    super.key,
    required this.selectedFloor,
    required this.onFloorChanged,
    this.isVertical = true,
  });

  static const List<({String floor, String label, String fullTitle})> floors = [
    (floor: '4', label: '4F', fullTitle: '4th Floor'),
    (floor: '3', label: '3F', fullTitle: '3rd Floor'),
    (floor: '2', label: '2F', fullTitle: '2nd Floor'),
    (floor: '1', label: '1F', fullTitle: '1st Floor (Ground)'),
    (floor: '-1', label: '-1', fullTitle: 'Basement -1'),
    (floor: '-2', label: '-2', fullTitle: 'Basement -2'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final children = floors.map((f) {
      final isSelected = selectedFloor == f.floor;
      return Padding(
        padding: const EdgeInsets.all(2.0),
        child: Tooltip(
          message: f.fullTitle,
          child: InkWell(
            onTap: () => onFloorChanged(f.floor),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? colors.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                f.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: isVertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: children,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: children.reversed.toList(),
            ),
    );
  }
}
