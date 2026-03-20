import 'dart:async';

import 'package:flutter/material.dart';
import '../models/meeting.dart';
import '../data/sample_data.dart';
import '../theme/sync_up_theme.dart';
import '../utils/responsive.dart';

/// Tetris-style view: Y-axis = configurable slots (8:00–22:00), X-axis = days.
/// Meeting blocks stack vertically by time; height = duration.
/// Responsive for mobile, tablet, and desktop.
const double _minTimeColumnWidth = 44.0;
const double _defaultRowHeight = 36.0;
const int _startHour = 8;
const int _endHour = 22;

/// Supported time slot durations for the grid (in minutes).
const List<int> slotDurationOptions = [
  5, 10, 15, 20, 25, 30, 45, 60, 90, 120, 180, 240, 360, 480, 720,
];

/// Slot durations for pinch: 15, 30, 45, 60 min.
const List<int> _pinchDurations = [15, 30, 45, 60];

/// Hue for current day column - Agendrix zen green tint
final Color _currentDayHue = SyncUpTheme.primary.withValues(alpha: 0.06);

/// Left accent colors for white cards (one per meeting for variety)
final List<Color> _blockColors = [
  const Color(0xFF6366F1), // Indigo
  const Color(0xFF8B5CF6), // Violet
  const Color(0xFF3B82F6), // Blue
  const Color(0xFF10B981), // Emerald
  const Color(0xFFEC4899), // Pink
  const Color(0xFFF59E0B), // Amber
];

class SlotsView extends StatefulWidget {
  final DateTime weekStart;
  final int slotDurationMinutes;
  /// When non-null, only this day is shown full-screen. Call [onDayTap] to set.
  final int? expandedDayIndex;
  /// Called when a day header/column is tapped to expand it.
  final ValueChanged<int>? onDayTap;
  /// Called when back is pressed in expanded day view.
  final VoidCallback? onBack;
  /// Called when slot duration changes. Pass new duration in minutes.
  final ValueChanged<int>? onSlotDurationChanged;

  const SlotsView({
    super.key,
    required this.weekStart,
    this.slotDurationMinutes = 15,
    this.expandedDayIndex,
    this.onDayTap,
    this.onBack,
    this.onSlotDurationChanged,
  });

  @override
  State<SlotsView> createState() => _SlotsViewState();
}

class _SlotsViewState extends State<SlotsView> {
  double _lastScale = 1.0;
  int _lastStepTime = 0;
  Timer? _pendingTimer;
  int? _pendingDuration;

  // Add scroll controllers for smooth scrolling
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _pendingTimer?.cancel();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _onScaleStart(ScaleStartDetails _) {
    _lastScale = 1.0;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (widget.onSlotDurationChanged == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastStepTime < 280) return; // Cooldown – short for responsiveness
    final s = d.scale;
    const thresh = 0.09; // Lower = easier to trigger, smoother feel
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

  int _getEndHour(List<Meeting> meetings) {
    if (meetings.isEmpty) return _endHour;
    int latest = _startHour * 60;
    for (final m in meetings) {
      final e = m.endTime.hour * 60 + m.endTime.minute;
      if (e > latest) latest = e;
    }
    return ((latest + 59) ~/ 60).clamp(_startHour + 1, 24);
  }

  int _totalRows(int endHour) {
    final rows = ((endHour - _startHour) * 60) ~/ widget.slotDurationMinutes;
    return rows < 1 ? 1 : rows;
  }

  @override
  Widget build(BuildContext context) {
    final monday = DateTime(widget.weekStart.year, widget.weekStart.month, widget.weekStart.day)
        .subtract(Duration(days: widget.weekStart.weekday - 1));
    final meetings = getSampleMeetings(monday);
    final endHour = _getEndHour(meetings);
    final totalRows = _totalRows(endHour);
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final isExpanded = widget.expandedDayIndex != null;

    return Column(
      children: [
        // Back bar when day is expanded
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
                      tooltip: 'Back to calendar',
                    ),
                    Expanded(
                      child: Text(
                        _formatExpandedDayTitle(monday, widget.expandedDayIndex!),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
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
        // Header row: empty | Mon | Tue | ... (hidden when expanded - back bar shows day)
        if (!isExpanded)
          LayoutBuilder(
            builder: (context, constraints) {
              final timeW = _minTimeColumnWidth;
              final dayW = (constraints.maxWidth - timeW) / 7;
              final todayDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
              final mondayDate = DateTime(monday.year, monday.month, monday.day);
              int? currentDayIndex;
              for (var i = 0; i < 7; i++) {
                if (mondayDate.add(Duration(days: i)) == todayDate) {
                  currentDayIndex = i;
                  break;
                }
              }
              return SizedBox(
                height: 32,
                child: Row(
                  children: [
                    SizedBox(width: timeW),
                    ...List.generate(7, (i) {
                      final cell = Container(
                        width: dayW,
                        color: currentDayIndex == i ? _currentDayHue : null,
                        child: Center(
                          child: Text(
                            dayNames[i],
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF334155),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                      if (widget.onDayTap != null) {
                        return GestureDetector(
                          onTap: () => widget.onDayTap!(i),
                          behavior: HitTestBehavior.opaque,
                          child: cell,
                        );
                      }
                      return cell;
                    }),
                  ],
                ),
              );
            },
          ),
        if (!isExpanded) const Divider(height: 1),
        // Grid with smooth scrolling
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
              final totalContentHeight = totalRows * _defaultRowHeight;

              // Calculate if horizontal scrolling is needed
              final needsHorizontalScroll = totalContentWidth > constraints.maxWidth;

              return GestureDetector(
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                behavior: HitTestBehavior.translucent,
                // Use a single ScrollView with proper physics for smooth scrolling
                child: Scrollbar(
                  controller: _verticalScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _verticalScrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: needsHorizontalScroll
                        ? Scrollbar(
                            controller: _horizontalScrollController,
                            thumbVisibility: true,
                            notificationPredicate: (notification) {
                              // Only handle horizontal scroll notifications
                              return notification.depth == 1;
                            },
                            child: SingleChildScrollView(
                              controller: _horizontalScrollController,
                              scrollDirection: Axis.horizontal,
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              child: SizedBox(
                                width: totalContentWidth,
                                height: totalContentHeight,
                                child: RepaintBoundary(
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      _buildGrid(
                                        context,
                                        monday,
                                        timeColumnWidth: timeColumnWidth,
                                        dayColumnWidth: dayColumnWidth,
                                        rowHeight: _defaultRowHeight,
                                        dayCount: dayCount,
                                        totalRows: totalRows,
                                        endHour: endHour,
                                        expandedDayIndex: widget.expandedDayIndex,
                                        onDayTap: widget.onDayTap,
                                      ),
                                      ..._buildMeetingBlocks(
                                        meetings,
                                        monday,
                                        timeColumnWidth: timeColumnWidth,
                                        dayColumnWidth: dayColumnWidth,
                                        rowHeight: _defaultRowHeight,
                                        dayCount: dayCount,
                                        endHour: endHour,
                                        expandedDayIndex: widget.expandedDayIndex,
                                      ),
                                      _buildCurrentTimeLine(
                                        timeColumnWidth: timeColumnWidth,
                                        dayColumnWidth: dayColumnWidth,
                                        rowHeight: _defaultRowHeight,
                                        dayCount: dayCount,
                                        endHour: endHour,
                                        totalRows: totalRows,
                                        expandedDayIndex: widget.expandedDayIndex,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SizedBox(
                            width: totalContentWidth,
                            height: totalContentHeight,
                            child: RepaintBoundary(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  _buildGrid(
                                    context,
                                    monday,
                                    timeColumnWidth: timeColumnWidth,
                                    dayColumnWidth: dayColumnWidth,
                                    rowHeight: _defaultRowHeight,
                                    dayCount: dayCount,
                                    totalRows: totalRows,
                                    endHour: endHour,
                                    expandedDayIndex: widget.expandedDayIndex,
                                    onDayTap: widget.onDayTap,
                                  ),
                                  ..._buildMeetingBlocks(
                                    meetings,
                                    monday,
                                    timeColumnWidth: timeColumnWidth,
                                    dayColumnWidth: dayColumnWidth,
                                    rowHeight: _defaultRowHeight,
                                    dayCount: dayCount,
                                    endHour: endHour,
                                    expandedDayIndex: widget.expandedDayIndex,
                                  ),
                                  _buildCurrentTimeLine(
                                    timeColumnWidth: timeColumnWidth,
                                    dayColumnWidth: dayColumnWidth,
                                    rowHeight: _defaultRowHeight,
                                    dayCount: dayCount,
                                    endHour: endHour,
                                    totalRows: totalRows,
                                    expandedDayIndex: widget.expandedDayIndex,
                                  ),
                                ],
                              ),
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

  String _formatExpandedDayTitle(DateTime monday, int dayIndex) {
    final day = monday.add(Duration(days: dayIndex));
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${names[dayIndex]} ${day.day}/${day.month}';
  }

  int? _getCurrentDayIndex(DateTime monday) {
    final todayDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final mondayDate = DateTime(monday.year, monday.month, monday.day);
    for (var i = 0; i < 7; i++) {
      if (mondayDate.add(Duration(days: i)) == todayDate) return i;
    }
    return null;
  }

  Widget _buildGrid(
    BuildContext context,
    DateTime monday, {
    required double timeColumnWidth,
    required double dayColumnWidth,
    required double rowHeight,
    required int dayCount,
    required int totalRows,
    required int endHour,
    int? expandedDayIndex,
    ValueChanged<int>? onDayTap,
  }) {
    final currentDayIndex = _getCurrentDayIndex(monday);
    final indices = expandedDayIndex != null ? [expandedDayIndex] : List.generate(7, (i) => i);
    return Column(
      children: List.generate(totalRows, (rowIndex) {
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
              SizedBox(
                width: timeColumnWidth,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        timeStr,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF475569),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
              ...indices.map((i) {
                final cell = Container(
                  width: dayColumnWidth,
                  decoration: BoxDecoration(
                    color: currentDayIndex == i ? _currentDayHue : null,
                    border: Border(
                      right: BorderSide(color: SyncUpTheme.border),
                      bottom: BorderSide(color: SyncUpTheme.border),
                    ),
                  ),
                );
                if (onDayTap != null && expandedDayIndex == null) {
                  return GestureDetector(
                    onTap: () => onDayTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: cell,
                  );
                }
                return cell;
              }),
            ],
          ),
        );
      }),
    );
  }

  List<Widget> _buildMeetingBlocks(
    List<Meeting> meetings,
    DateTime monday, {
    required double timeColumnWidth,
    required double dayColumnWidth,
    required double rowHeight,
    required int dayCount,
    required int endHour,
    int? expandedDayIndex,
  }) {
    final mondayDate = DateTime(monday.year, monday.month, monday.day);
    return meetings.map((m) {
      final meetingDate = DateTime(m.startTime.year, m.startTime.month, m.startTime.day);
      var dayIndex = meetingDate.difference(mondayDate).inDays;
      if (dayIndex < 0 || dayIndex > 6) return const SizedBox.shrink();
      if (expandedDayIndex != null) {
        if (dayIndex != expandedDayIndex) return const SizedBox.shrink();
        dayIndex = 0; // single column
      }

      final minutesFromMidnight = m.startTime.hour * 60 + m.startTime.minute;
      final gridStartMinutes = _startHour * 60;
      final offsetMinutes = minutesFromMidnight - gridStartMinutes;
      if (offsetMinutes < 0) return const SizedBox.shrink();

      final top = (offsetMinutes / widget.slotDurationMinutes) * rowHeight;
      final slotCount = (m.durationMinutes / widget.slotDurationMinutes).ceil();
      final height = slotCount * rowHeight;

      final left = timeColumnWidth + dayIndex * dayColumnWidth;

      final colorIndex = m.id.hashCode.abs() % _blockColors.length;
      return Positioned(
        left: left + 2,
        top: top + 2,
        width: dayColumnWidth - 4,
        height: height - 4,
        child: _MeetingBlock(
          meeting: m,
          blockWidth: dayColumnWidth - 4,
          blockHeight: height - 4,
          blockColor: _blockColors[colorIndex],
        ),
      );
    }).toList();
  }

  Widget _buildCurrentTimeLine({
    required double timeColumnWidth,
    required double dayColumnWidth,
    required double rowHeight,
    required int dayCount,
    required int endHour,
    required int totalRows,
    int? expandedDayIndex,
  }) {
    final now = DateTime.now();
    final minutesFromMidnight = now.hour * 60 + now.minute;
    final gridStartMinutes = _startHour * 60;
    final gridEndMinutes = endHour * 60;
    final offsetMinutes = minutesFromMidnight - gridStartMinutes;
    if (offsetMinutes < 0 || minutesFromMidnight >= gridEndMinutes) {
      return const SizedBox.shrink();
    }

    final monday = DateTime(widget.weekStart.year, widget.weekStart.month, widget.weekStart.day)
        .subtract(Duration(days: widget.weekStart.weekday - 1));
    final todayDate = DateTime(now.year, now.month, now.day);
    final mondayDate = DateTime(monday.year, monday.month, monday.day);
    int? currentDayIndex;
    for (var i = 0; i < 7; i++) {
      if (mondayDate.add(Duration(days: i)) == todayDate) {
        currentDayIndex = i;
        break;
      }
    }
    if (currentDayIndex == null) return const SizedBox.shrink();
    if (expandedDayIndex != null && currentDayIndex != expandedDayIndex) {
      return const SizedBox.shrink();
    }

    final top = (offsetMinutes / widget.slotDurationMinutes) * rowHeight;
    final isExpanded = expandedDayIndex != null;
    final lineLeft = isExpanded ? 0.0 : timeColumnWidth + currentDayIndex * dayColumnWidth;
    final lineWidth = isExpanded ? (timeColumnWidth + dayColumnWidth) : dayColumnWidth;

    return Positioned(
      left: lineLeft,
      top: top - 1,
      child: IgnorePointer(
        child: SizedBox(
          width: lineWidth,
          height: 2,
          child: Container(
            decoration: BoxDecoration(
              color: SyncUpTheme.zenGreen,
              boxShadow: [
                BoxShadow(
                  color: SyncUpTheme.zenGreen.withValues(alpha: 0.4),
                  blurRadius: 2,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MeetingBlock extends StatefulWidget {
  final Meeting meeting;
  final double blockWidth;
  final double blockHeight;
  final Color blockColor;

  const _MeetingBlock({
    required this.meeting,
    required this.blockWidth,
    required this.blockHeight,
    required this.blockColor,
  });

  @override
  State<_MeetingBlock> createState() => _MeetingBlockState();
}

class _MeetingBlockState extends State<_MeetingBlock> {
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _showOverlay(BuildContext context) {
    _removeOverlay();
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => _MeetingDetailModal(
        meeting: widget.meeting,
        blockColor: widget.blockColor,
        position: pos,
        blockSize: size,
        onClose: _removeOverlay,
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final meeting = widget.meeting;
    final accentColor = widget.blockColor;
    final h = widget.blockHeight;
    final w = widget.blockWidth;
    const barWidth = 4.0;
    const padding = 4.0;
    final contentH = h - 4;
    final contentW = w - barWidth - padding * 2;

    // Height-based content: show more when space allows
    final hasDetails = meeting.discipline != null || meeting.topic != null;
    final hasLocation = meeting.location != null;
    final showDetails = contentH >= 28 && hasDetails;
    final showDetails2Lines = contentH >= 48 && hasDetails;
    final showLocation = contentH >= 62 && hasLocation;

    // Font sizes: scale with available height
    final nameFontSize = contentH < 24 ? 9.0 : (contentH < 36 ? 10.0 : 11.0);
    final detailFontSize = contentH < 40 ? 9.0 : 10.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_overlayEntry != null) {
            _removeOverlay();
          } else {
            _showOverlay(context);
          }
        },
        borderRadius: BorderRadius.circular(2),
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
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
                  color: accentColor,
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
                            meeting.participantName,
                            style: TextStyle(
                              color: const Color(0xFF0F172A),
                              fontSize: nameFontSize,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          if (showDetails) ...[
                            SizedBox(height: contentH < 36 ? 0 : 1),
                            Text(
                              [
                                if (meeting.discipline != null) meeting.discipline,
                                if (meeting.topic != null) meeting.topic,
                              ].join(' – '),
                              style: TextStyle(
                                color: const Color(0xFF334155),
                                fontSize: detailFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: showDetails2Lines ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (showLocation) ...[
                            SizedBox(height: contentH < 56 ? 0 : 1),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 10, color: SyncUpTheme.textSecondary),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    meeting.location!,
                                    style: TextStyle(
                                      color: SyncUpTheme.textSecondary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
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

class _MeetingDetailModal extends StatelessWidget {
  final Meeting meeting;
  final Color blockColor;
  final Offset position;
  final Size blockSize;
  final VoidCallback onClose;

  const _MeetingDetailModal({
    required this.meeting,
    required this.blockColor,
    required this.position,
    required this.blockSize,
    required this.onClose,
  });

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    const modalWidth = 260.0;
    const modalHeight = 180.0;
    final screenSize = MediaQuery.of(context).size;
    final showAbove = position.dy + blockSize.height + modalHeight > screenSize.height - 16;
    final top = showAbove ? position.dy - modalHeight - 8 : position.dy + blockSize.height + 8;
    final left = position.dx.clamp(8.0, screenSize.width - modalWidth - 8);

    return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
          behavior: HitTestBehavior.opaque,
          child: Container(color: Colors.transparent),
        ),
        Positioned(
          left: left,
          top: top.clamp(8.0, screenSize.height - modalHeight - 8),
          child: Material(
            elevation: 0,
            borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
            color: Colors.transparent,
            child: Container(
              width: modalWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SyncUpTheme.surface,
                borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
                border: Border.all(color: SyncUpTheme.zenGreen.withValues(alpha: 0.15)),
                boxShadow: SyncUpTheme.modalShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: SyncUpTheme.zenGreen,
                        child: Text(
                          meeting.participantName.isNotEmpty
                              ? meeting.participantName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meeting.participantName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: SyncUpTheme.textPrimary,
                                  ),
                            ),
                            if (meeting.discipline != null || meeting.topic != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                [if (meeting.discipline != null) meeting.discipline, if (meeting.topic != null) meeting.topic].join(' – '),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: SyncUpTheme.zenGreen,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '${_formatTime(meeting.startTime)} – ${_formatTime(meeting.endTime)} • ${meeting.durationMinutes} min',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: SyncUpTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (meeting.location != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: SyncUpTheme.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            meeting.location!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: SyncUpTheme.textSecondary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}