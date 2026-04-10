import 'dart:async';
import 'package:flutter/material.dart';
import '../models/meeting.dart';
import '../theme/sync_up_theme.dart';

/// Card shown when a meeting is currently ongoing.
/// Displays meeting info, a progress animation, and Missed/Late/Ontime buttons.
class CurrentMeetingCard extends StatefulWidget {
  final Meeting meeting;
  final Color accentColor;
  final VoidCallback? onMissed;
  final VoidCallback? onOntime;
  final VoidCallback? onLate;
  final VoidCallback? onDismiss;

  const CurrentMeetingCard({
    super.key,
    required this.meeting,
    this.accentColor = SyncUpTheme.primary,
    this.onMissed,
    this.onOntime,
    this.onLate,
    this.onDismiss,
  });

  @override
  State<CurrentMeetingCard> createState() => _CurrentMeetingCardState();
}

class _CurrentMeetingCardState extends State<CurrentMeetingCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  late AnimationController _bellController;
  late Animation<double> _bellAnimation;
  final ValueNotifier<int> _tickNotifier = ValueNotifier(0);
  Timer? _tickTimer;
  _MeetingPunctuality? _selectedPunctuality;
  bool _isCollapsing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _bellController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _bellAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bellController, curve: Curves.easeInOut),
    );

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _tickNotifier.value++;
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _tickNotifier.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _bellController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  double get _progress {
    final now = DateTime.now();
    if (now.isBefore(widget.meeting.startTime)) return 0;
    if (now.isAfter(widget.meeting.endTime)) return 1;
    final elapsed = now.difference(widget.meeting.startTime).inSeconds;
    final total = widget.meeting.durationMinutes * 60;
    return elapsed / total;
  }

  bool get _aboutToEnd {
    final now = DateTime.now();
    if (now.isAfter(widget.meeting.endTime)) return false;
    final remaining = widget.meeting.endTime.difference(now).inMinutes;
    return remaining <= 5;
  }

  /// Remaining time as "M:SS" when meeting is about to end.
  String get _remainingCountdown {
    final now = DateTime.now();
    if (now.isAfter(widget.meeting.endTime)) return '0:00';
    final d = widget.meeting.endTime.difference(now);
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final meeting = widget.meeting;
    final now = DateTime.now();
    final isOngoing =
        !now.isBefore(meeting.startTime) && now.isBefore(meeting.endTime);
    final justEnded =
        now.isAfter(meeting.endTime) &&
        now.difference(meeting.endTime).inMinutes <= 1;

    final borderColor =
        _aboutToEnd ? const Color(0xFFDC2626) : widget.accentColor;

    Future<void> selectAndCollapse(_MeetingPunctuality p) async {
      if (_isCollapsing) return;
      setState(() {
        _selectedPunctuality = p;
        _isCollapsing = true;
      });

      switch (p) {
        case _MeetingPunctuality.ontime:
          widget.onOntime?.call();
          break;
        case _MeetingPunctuality.late:
          widget.onLate?.call();
          break;
        case _MeetingPunctuality.missed:
          widget.onMissed?.call();
          break;
      }

      // Briefly show the selected color, then collapse like the X button.
      await Future<void>.delayed(const Duration(milliseconds: 140));
      if (!mounted) return;
      widget.onDismiss?.call();
    }

    const green = Color(0xFF16A34A);
    const yellow = Color(0xFFF59E0B);
    const red = Color(0xFFDC2626);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: SyncUpTheme.surface,
        borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
        border: Border.all(
          color: borderColor.withValues(alpha: isOngoing ? 0.6 : 0.3),
          width: isOngoing ? 1.5 : 1,
        ),
        boxShadow: [
          ...SyncUpTheme.cardShadow,
          if (isOngoing)
            BoxShadow(
              color: (_aboutToEnd
                      ? const Color(0xFFDC2626)
                      : widget.accentColor)
                  .withValues(alpha: 0.12),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
        child: Stack(
          children: [
            if (isOngoing)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _shimmerAnimation,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _ShimmerPainter(
                        progress: _shimmerAnimation.value,
                        color: widget.accentColor,
                      ),
                    );
                  },
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        final barColor =
                            _aboutToEnd
                                ? const Color(0xFFDC2626)
                                : widget.accentColor;
                        return Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: barColor.withValues(
                              alpha: isOngoing ? _pulseAnimation.value : 0.6,
                            ),
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(SyncUpTheme.radiusMd),
                            ),
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      if (isOngoing) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: widget.accentColor
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              AnimatedBuilder(
                                                animation: _pulseAnimation,
                                                builder: (context, _) {
                                                  return Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: widget.accentColor
                                                          .withValues(
                                                            alpha:
                                                                _pulseAnimation
                                                                    .value,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: widget
                                                              .accentColor
                                                              .withValues(
                                                                alpha: 0.5,
                                                              ),
                                                          blurRadius: 4,
                                                          spreadRadius: 0,
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'In progress',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: widget.accentColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 11,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ] else if (justEnded) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: SyncUpTheme.textSecondary
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'Just ended',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelSmall?.copyWith(
                                              color: SyncUpTheme.textSecondary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(
                                        '${_formatTime(meeting.startTime)} – ${_formatTime(meeting.endTime)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.copyWith(
                                          color: SyncUpTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (widget.onDismiss != null)
                                  IconButton(
                                    onPressed: widget.onDismiss,
                                    icon: Icon(
                                      Icons.close,
                                      size: 20,
                                      color: SyncUpTheme.textSecondary,
                                    ),
                                    style: IconButton.styleFrom(
                                      padding: const EdgeInsets.all(4),
                                      minimumSize: const Size(32, 32),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    tooltip: 'Dismiss',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              meeting.displayLabel,
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall?.copyWith(
                                color: SyncUpTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (meeting.location != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: SyncUpTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      meeting.location!,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color: SyncUpTheme.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (isOngoing) ...[
                              const SizedBox(height: 10),
                              ValueListenableBuilder<int>(
                                valueListenable: _tickNotifier,
                                builder: (context, _, __) {
                                  final progress = _progress;
                                  final aboutToEnd = _aboutToEnd;
                                  final countdown = _remainingCountdown;
                                  final pct = (progress * 100).clamp(0, 100).round();
                                  final pctStyle = Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: aboutToEnd
                                            ? const Color(0xFFDC2626)
                                            : SyncUpTheme.textSecondary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      );
                                  return RepaintBoundary(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              backgroundColor:
                                                  SyncUpTheme.divider,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    aboutToEnd
                                                        ? const Color(
                                                          0xFFDC2626,
                                                        )
                                                        : widget.accentColor,
                                                  ),
                                              minHeight: 3,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 40,
                                          child: Text(
                                            '$pct%',
                                            textAlign: TextAlign.right,
                                            style: pctStyle,
                                          ),
                                        ),
                                        if (aboutToEnd) ...[
                                          const SizedBox(width: 8),
                                          AnimatedBuilder(
                                            animation: _bellAnimation,
                                            builder: (context, _) {
                                              final t = _bellAnimation.value;
                                              final bounce =
                                                  2.0 * (1 - (2 * t - 1).abs());
                                              return Transform.translate(
                                                offset: Offset(0, -bounce * 2),
                                                child: Icon(
                                                  Icons.notifications_active,
                                                  size: 16,
                                                  color: const Color(
                                                    0xFFDC2626,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 6),
                                          SizedBox(
                                            width: 32,
                                            child: Text(
                                              countdown,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelSmall?.copyWith(
                                                color: const Color(0xFFDC2626),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                                fontFeatures: const [
                                                  FontFeature.tabularFigures(),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ] else if (justEnded) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: 1,
                                        backgroundColor: SyncUpTheme.divider,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          SyncUpTheme.textSecondary,
                                        ),
                                        minHeight: 3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      '100%',
                                      textAlign: TextAlign.right,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: SyncUpTheme.textSecondary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
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
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isCollapsing
                              ? null
                              : () => selectAndCollapse(
                                    _MeetingPunctuality.missed,
                                  ),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Missed'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor:
                                _selectedPunctuality == _MeetingPunctuality.missed
                                    ? red
                                    : Colors.transparent,
                            foregroundColor:
                                _selectedPunctuality == _MeetingPunctuality.missed
                                    ? Colors.white
                                    : red,
                            side: BorderSide(
                              color: red,
                              width: _selectedPunctuality ==
                                      _MeetingPunctuality.missed
                                  ? 0
                                  : 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isCollapsing
                              ? null
                              : () => selectAndCollapse(
                                    _MeetingPunctuality.late,
                                  ),
                          icon: const Icon(Icons.schedule, size: 16),
                          label: const Text('Late'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor:
                                _selectedPunctuality == _MeetingPunctuality.late
                                    ? yellow
                                    : Colors.transparent,
                            foregroundColor:
                                _selectedPunctuality == _MeetingPunctuality.late
                                    ? Colors.white
                                    : yellow,
                            side: BorderSide(
                              color: yellow,
                              width:
                                  _selectedPunctuality == _MeetingPunctuality.late
                                      ? 0
                                      : 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isCollapsing
                              ? null
                              : () => selectAndCollapse(
                                    _MeetingPunctuality.ontime,
                                  ),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Ontime'),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                _selectedPunctuality == _MeetingPunctuality.ontime
                                    ? green
                                    : SyncUpTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _MeetingPunctuality { ontime, late, missed }

/// Draws a subtle shimmer sweep across the card.
class _ShimmerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ShimmerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment(-1 + progress * 2, 0),
            end: Alignment(-0.5 + progress * 2, 0),
            colors: [
              color.withValues(alpha: 0),
              color.withValues(alpha: 0.04),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
