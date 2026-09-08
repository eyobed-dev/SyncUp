/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Reusable UI component for the find_schedule_slots_view interface.
 */

import 'dart:async';

import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../utils/week_calendar.dart';
import '../models/availability_slot.dart';
import 'package:sync_up/theme/sync_up_colors.dart';

/// Grid showing available slots for booking. Same layout as SlotsView.
/// Only displays the owner's availability blocks (e.g. Consultation, Mentoring, training).
const double _defaultRowHeight = 36.0;
const int _startHour = 8;
const int _endHour = 22;
const List<int> _pinchDurations = [15, 30, 45, 60];

class FindScheduleSlotsView extends StatefulWidget {
  final DateTime weekStart;
  final int slotDurationMinutes;
  final List<AvailabilitySlot> availabilitySlots;
  final int? expandedDayIndex;
  final ValueChanged<int>? onDayTap;
  final VoidCallback? onBack;
  final ValueChanged<AvailabilitySlot>? onSlotSelected;
  final ValueChanged<int>? onSlotDurationChanged;

  const FindScheduleSlotsView({
    super.key,
    required this.weekStart,
    this.slotDurationMinutes = 15,
    this.availabilitySlots = const [],
    this.expandedDayIndex,
    this.onDayTap,
    this.onBack,
    this.onSlotSelected,
    this.onSlotDurationChanged,
  });

  @override
  State<FindScheduleSlotsView> createState() => _FindScheduleSlotsViewState();
}

class _FindScheduleSlotsViewState extends State<FindScheduleSlotsView> {
  double _lastScale = 1.0;
  int _lastStepTime = 0;
  Timer? _pendingTimer;
  int? _pendingDuration;

  @override
  void dispose() {
    _pendingTimer?.cancel();
    super.dispose();
  }

  void _onScaleStart(ScaleStartDetails _) {
    _lastScale = 1.0;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (widget.onSlotDurationChanged == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastStepTime < 280) return;
    final s = d.scale;
    const thresh = 0.09;
    int idx = _pinchDurations.indexOf(widget.slotDurationMinutes);
    if (idx < 0) idx = 0;
    int? nextDuration;
    if (s > _lastScale + thresh && idx > 0) {
      nextDuration = _pinchDurations[idx - 1];
      _lastScale = s;
    } else if (s < _lastScale - thresh && idx < _pinchDurations.length - 1) {
      nextDuration = _pinchDurations[idx + 1];
      _lastScale = s;
    }
    if (nextDuration != null) {
      _lastStepTime = now;
      _pendingDuration = nextDuration;
      _pendingTimer?.cancel();
      _pendingTimer = Timer(const Duration(milliseconds: 40), () {
        _pendingTimer = null;
        final duration = _pendingDuration;
        _pendingDuration = null;
        if (mounted && duration != null) {
          widget.onSlotDurationChanged!(duration);
        }
      });
    }
  }

  int get _totalRows {
    final rows = ((_endHour - _startHour) * 60) ~/ widget.slotDurationMinutes;
    return rows < 1 ? 1 : rows;
  }

  @override
  Widget build(BuildContext context) {
    final weekSunday = startOfWeekSunday(
      DateTime(widget.weekStart.year, widget.weekStart.month, widget.weekStart.day),
    );
    final dayNames = dayShortNamesSunFirst;
    final isExpanded = widget.expandedDayIndex != null;

    return Column(
      children: [
        if (isExpanded) ...[
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: widget.onBack,
                      tooltip: 'Back to week',
                    ),
                    Expanded(
                      child: Text(
                        _formatExpandedDayTitle(weekSunday, widget.expandedDayIndex!),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
        ],
        if (!isExpanded)
          LayoutBuilder(
            builder: (context, constraints) {
              final timeW = Responsive.value(
                context,
                mobile: 44.0,
                tablet: 48.0,
                desktop: 52.0,
              );
              final todayDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
              final weekSundayDate = DateTime(weekSunday.year, weekSunday.month, weekSunday.day);
              int? currentDayIndex;
              for (var i = 0; i < 7; i++) {
                if (weekSundayDate.add(Duration(days: i)) == todayDate) {
                  currentDayIndex = i;
                  break;
                }
              }
              return SizedBox(
                height: 32,
                child: Row(
                  children: [
                    ...List.generate(7, (i) {
                      final cell = Container(
                        width: double.infinity,
                        color: currentDayIndex == i
                            ? context.colors.primary.withValues(alpha: 0.06)
                            : null,
                        child: Center(
                          child: Text(
                            dayNames[i],
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: context.colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      );
                      return Expanded(
                        child: GestureDetector(
                          onTap: widget.onDayTap != null ? () => widget.onDayTap!(i) : null,
                          behavior: HitTestBehavior.opaque,
                          child: cell,
                        ),
                      );
                    }),
                    SizedBox(width: timeW),
                  ],
                ),
              );
            },
          ),
        if (!isExpanded) const Divider(height: 1),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final timeColumnWidth = Responsive.value(
                context,
                mobile: 44.0,
                tablet: 48.0,
                desktop: 52.0,
              );
              final dayCount = isExpanded ? 1 : 7;
              final dayColumnWidth = (constraints.maxWidth - timeColumnWidth) / dayCount;
              final totalContentWidth = constraints.maxWidth;
              final totalContentHeight = _totalRows * _defaultRowHeight;

              return GestureDetector(
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                behavior: HitTestBehavior.translucent,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: totalContentWidth > constraints.maxWidth
                        ? const AlwaysScrollableScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: totalContentWidth,
                      height: totalContentHeight,
                      child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildGrid(
                          context,
                          weekSunday,
                          timeColumnWidth: timeColumnWidth,
                          dayColumnWidth: dayColumnWidth,
                          rowHeight: _defaultRowHeight,
                          dayCount: dayCount,
                        ),
                        ..._buildAvailabilityBlocks(
                          weekSunday,
                          timeColumnWidth: timeColumnWidth,
                          dayColumnWidth: dayColumnWidth,
                          rowHeight: _defaultRowHeight,
                          dayCount: dayCount,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            },
          ),
        ),
      ],
    );
  }

  String _formatExpandedDayTitle(DateTime weekSunday, int dayIndex) {
    final day = weekSunday.add(Duration(days: dayIndex));
    return '${dayLongNamesSunFirst[dayIndex]} ${day.day}/${day.month}';
  }

  int? _getCurrentDayIndex(DateTime weekSunday) {
    final todayDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final weekSundayDate = DateTime(weekSunday.year, weekSunday.month, weekSunday.day);
    for (var i = 0; i < 7; i++) {
      if (weekSundayDate.add(Duration(days: i)) == todayDate) return i;
    }
    return null;
  }

  Widget _buildGrid(
    BuildContext context,
    DateTime weekSunday, {
    required double timeColumnWidth,
    required double dayColumnWidth,
    required double rowHeight,
    required int dayCount,
  }) {
    final currentDayIndex = _getCurrentDayIndex(weekSunday);
    final indices = widget.expandedDayIndex != null
        ? [widget.expandedDayIndex!]
        : List.generate(7, (i) => i);

    return Column(
      children: List.generate(_totalRows, (rowIndex) {
        final minutesFromStart = rowIndex * widget.slotDurationMinutes;
        final hour = _startHour + (minutesFromStart ~/ 60);
        final min = minutesFromStart % 60;
        final timeStr =
            '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';

        return SizedBox(
          height: rowHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...indices.map((i) {
                final currentDayHue = context.colors.primary.withValues(alpha: 0.06);
                final cell = Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: currentDayIndex == i ? currentDayHue : null,
                    border: Border(
                      right: BorderSide(color: context.colors.border),
                      bottom: BorderSide(color: context.colors.border),
                    ),
                  ),
                );
                return Expanded(
                  child: GestureDetector(
                    onTap: widget.onDayTap != null && widget.expandedDayIndex == null
                        ? () => widget.onDayTap!(i)
                        : null,
                    behavior: HitTestBehavior.opaque,
                    child: cell,
                  ),
                );
              }),
              SizedBox(
                width: timeColumnWidth,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        timeStr,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: context.colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  List<Widget> _buildAvailabilityBlocks(
    DateTime weekSunday, {
    required double timeColumnWidth,
    required double dayColumnWidth,
    required double rowHeight,
    required int dayCount,
  }) {
    final weekSundayDate = DateTime(weekSunday.year, weekSunday.month, weekSunday.day);

    return widget.availabilitySlots.map((slot) {
      final slotDate = DateTime(slot.startTime.year, slot.startTime.month, slot.startTime.day);
      var dayIndex = slotDate.difference(weekSundayDate).inDays;
      if (dayIndex < 0 || dayIndex > 6) return const SizedBox.shrink();
      if (widget.expandedDayIndex != null) {
        if (dayIndex != widget.expandedDayIndex) return const SizedBox.shrink();
        dayIndex = 0;
      }

      final minutesFromMidnight = slot.startTime.hour * 60 + slot.startTime.minute;
      final gridStartMinutes = _startHour * 60;
      final offsetMinutes = minutesFromMidnight - gridStartMinutes;
      if (offsetMinutes < 0) return const SizedBox.shrink();

      final top = (offsetMinutes / widget.slotDurationMinutes) * rowHeight;
      final slotCount = (slot.durationMinutes / widget.slotDurationMinutes).ceil();
      final height = slotCount * rowHeight;

      final left = dayIndex * dayColumnWidth;

      return Positioned(
        left: left + 2,
        top: top + 2,
        width: dayColumnWidth - 4,
        height: height - 4,
        child: _AvailabilityBlock(
          slot: slot,
          blockWidth: dayColumnWidth - 4,
          blockHeight: height - 4,
          onTap: widget.onSlotSelected != null ? () => widget.onSlotSelected!(slot) : null,
        ),
      );
    }).toList();
  }
}

class _AvailabilityBlock extends StatelessWidget {
  final AvailabilitySlot slot;
  final double blockWidth;
  final double blockHeight;
  final VoidCallback? onTap;

  const _AvailabilityBlock({
    required this.slot,
    required this.blockWidth,
    required this.blockHeight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const barWidth = 4.0;
    const padding = 4.0;
    final contentH = blockHeight - 4;
    final contentW = blockWidth - barWidth - padding * 2;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: Container(
          width: blockWidth,
          height: blockHeight,
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: context.colors.primary.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: barWidth,
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 2, padding, 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: contentW,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slot.title,
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: contentH < 24 ? 9.0 : (contentH < 36 ? 10.0 : 11.0),
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          if (contentH >= 28)
                            Text(
                              '${slot.durationMinutes} min'
                                  '${slot.location != null ? ' • ${slot.location}' : ''}'
                                  '${(slot.meetingLink ?? '').trim().isNotEmpty ? ' • online' : ''}',
                              style: TextStyle(
                                color: context.colors.textSecondary,
                                fontSize: contentH < 40 ? 8.0 : 9.0,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
