import 'package:flutter/material.dart';

import '../models/meeting.dart';
import '../theme/sync_up_theme.dart';

/// Left accent colors for list cards (matches slot design).
const List<Color> listCardAccentColors = [
  Color(0xFF6366F1), // Indigo
  Color(0xFF8B5CF6), // Violet
  Color(0xFF3B82F6), // Blue
  Color(0xFF10B981), // Emerald
  Color(0xFFEC4899), // Pink
  Color(0xFFF59E0B), // Amber
];

/// Single meeting row — same layout as the List tab ([CalendarView] day list).
class MeetingListCard extends StatelessWidget {
  final Meeting meeting;
  final int colorIndex;
  final Meeting? currentMeeting;
  /// Optional widget before the avatar (e.g. selection checkbox).
  final Widget? leading;
  /// Optional widget at the end of the row (e.g. delete icon).
  final Widget? trailing;

  const MeetingListCard({
    super.key,
    required this.meeting,
    required this.colorIndex,
    this.currentMeeting,
    this.leading,
    this.trailing,
  });

  static bool canCancelMeeting(Meeting m) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final meetingDate = DateTime(m.startTime.year, m.startTime.month, m.startTime.day);
    return meetingDate.isAfter(today);
  }

  static void showCancelConfirmation(BuildContext context, Meeting m) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel meeting?'),
        content: Text(
          'Cancel the meeting with ${m.participantName} on ${_formatDate(m.startTime)}? This cannot be undone.',
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Meeting with ${m.participantName} cancelled'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Cancel meeting'),
          ),
        ],
      ),
    );
  }

  static void showPostponeConfirmation(BuildContext context, Meeting m) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Postpone meeting?'),
        content: Text(
          'Postpone the meeting with ${m.participantName}? You can reschedule it later.',
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Meeting with ${m.participantName} postponed'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Postpone'),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final m = meeting;
    final accentColor = listCardAccentColors[colorIndex % listCardAccentColors.length];
    final isCurrent = currentMeeting?.id == m.id;
    final now = DateTime.now();
    final isOngoing =
        isCurrent && !now.isBefore(m.startTime) && now.isBefore(m.endTime);
    final highlight = SyncUpTheme.primary.withValues(alpha: 0.4);
    final hasLeading = leading != null;
    final hasTrailing = trailing != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
          top: isCurrent ? BorderSide(color: highlight, width: 1.5) : BorderSide.none,
          right: isCurrent ? BorderSide(color: highlight, width: 1.5) : BorderSide.none,
          bottom: isCurrent ? BorderSide(color: highlight, width: 1.5) : BorderSide.none,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrent
                ? SyncUpTheme.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: isCurrent ? 8 : 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(hasLeading ? 6 : 10, 8, 10, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 4),
            ],
            CircleAvatar(
              radius: 14,
              backgroundColor: accentColor,
              child: Text(
                m.participantName.isNotEmpty ? m.participantName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCurrent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOngoing ? SyncUpTheme.primary : SyncUpTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOngoing ? 'In progress' : 'Just ended',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: isOngoing
                                      ? SyncUpTheme.primary
                                      : SyncUpTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    m.displayLabel,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      '${_formatTime(m.startTime)} – ${_formatTime(m.endTime)}',
                      if (m.location != null) m.location!,
                    ].join(' • '),
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (canCancelMeeting(m)) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => showCancelConfirmation(context, m),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFDC2626)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(0, 28),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton(
                          onPressed: () => showPostponeConfirmation(context, m),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SyncUpTheme.primary,
                            side: const BorderSide(color: SyncUpTheme.primary),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(0, 28),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text('Postpone', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (hasTrailing) ...[
              const SizedBox(width: 8),
              Align(
                alignment: Alignment.topRight,
                child: trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
