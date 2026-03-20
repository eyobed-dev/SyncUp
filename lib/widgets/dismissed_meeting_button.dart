import 'dart:async';
import 'package:flutter/material.dart';
import '../models/meeting.dart';
import '../theme/sync_up_theme.dart';

/// Compact bar shown when the current meeting card is dismissed.
/// Shows progress bar, animations, and jumping bell when about to end.
class DismissedMeetingButton extends StatefulWidget {
  final Meeting meeting;
  final VoidCallback onTap;

  const DismissedMeetingButton({
    super.key,
    required this.meeting,
    required this.onTap,
  });

  @override
  State<DismissedMeetingButton> createState() => _DismissedMeetingButtonState();
}

class _DismissedMeetingButtonState extends State<DismissedMeetingButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  late AnimationController _bellController;
  late Animation<double> _bellAnimation;
  final ValueNotifier<int> _tickNotifier = ValueNotifier(0);
  Timer? _tickTimer;

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

  String get _remainingCountdown {
    final now = DateTime.now();
    if (now.isAfter(widget.meeting.endTime)) return '0:00';
    final d = widget.meeting.endTime.difference(now);
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  bool get _isOngoing {
    final now = DateTime.now();
    return !now.isBefore(widget.meeting.startTime) &&
        now.isBefore(widget.meeting.endTime);
  }

  bool get _justEnded {
    final now = DateTime.now();
    return now.isAfter(widget.meeting.endTime) &&
        now.difference(widget.meeting.endTime).inMinutes <= 1;
  }

  @override
  Widget build(BuildContext context) {
    final meeting = widget.meeting;
    final showOngoing = _isOngoing || _justEnded;
    final accentColor = _aboutToEnd ? const Color(0xFFDC2626) : SyncUpTheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Material(
        color: _aboutToEnd
            ? const Color(0xFFDC2626).withValues(alpha: 0.08)
            : SyncUpTheme.primaryLight,
        borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(SyncUpTheme.radiusMd),
            child: Stack(
              children: [
                if (showOngoing)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _shimmerAnimation,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _ShimmerPainter(
                            progress: _shimmerAnimation.value,
                            color: accentColor,
                          ),
                        );
                      },
                    ),
                  ),
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, _) {
                        return Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(
                              alpha: showOngoing ? _pulseAnimation.value : 0.6,
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
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, _) {
                              return Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accentColor.withValues(
                                    alpha: _pulseAnimation.value,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withValues(alpha: 0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isOngoing ? 'In progress' : 'Just ended',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: accentColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  meeting.displayLabel,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: SyncUpTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (_aboutToEnd)
                            ValueListenableBuilder<int>(
                              valueListenable: _tickNotifier,
                              builder: (context, _, __) {
                                final countdown = _remainingCountdown;
                                return RepaintBoundary(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedBuilder(
                                        animation: _bellAnimation,
                                        builder: (context, __) {
                                          final t = _bellAnimation.value;
                                          final bounce = 2.0 * (1 - (2 * t - 1).abs());
                                          return Transform.translate(
                                            offset: Offset(0, -bounce * 2),
                                            child: Icon(
                                              Icons.notifications_active,
                                              size: 14,
                                              color: const Color(0xFFDC2626),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 6),
                                      SizedBox(
                                        width: 28,
                                        child: Text(
                                          countdown,
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: const Color(0xFFDC2626),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                                fontFeatures: const [FontFeature.tabularFigures()],
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          else
                            Icon(
                              Icons.expand_less,
                              size: 20,
                              color: accentColor,
                            ),
                        ],
                      ),
                      if (showOngoing) ...[
                        const SizedBox(height: 8),
                        ValueListenableBuilder<int>(
                          valueListenable: _tickNotifier,
                          builder: (context, _, __) {
                            final progress = _progress;
                            final aboutToEnd = _aboutToEnd;
                            return RepaintBoundary(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: SyncUpTheme.divider,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    aboutToEnd ? const Color(0xFFDC2626) : SyncUpTheme.primary,
                                  ),
                                  minHeight: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ShimmerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
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
