import 'package:flutter/material.dart';

import '../data/current_meeting_minutes.dart';
import '../data/sample_data.dart';
import '../models/meeting.dart';
import '../theme/sync_up_theme.dart';

/// Single row in the merged “previous meetings” list.
class _PriorHistoryEntry {
  _PriorHistoryEntry._({required this.sortTime, this.meeting})
    : assert(meeting != null);

  factory _PriorHistoryEntry.seed(Meeting m) =>
      _PriorHistoryEntry._(sortTime: m.startTime, meeting: m);

  final DateTime sortTime;
  final Meeting? meeting;
}

List<_PriorHistoryEntry> _mergePriorHistory(List<Meeting> seeds) {
  final out = <_PriorHistoryEntry>[...seeds.map(_PriorHistoryEntry.seed)];
  out.sort((a, b) => b.sortTime.compareTo(a.sortTime));
  return out;
}

/// Left accent colors for list cards (matches slot design).
const List<Color> listCardAccentColors = [
  Color(0xFF0F9FA8), // Blue-teal
  Color(0xFF0E7490), // Deep teal-blue
  Color(0xFF0891B2), // Cyan-blue
  Color(0xFF14B8A6), // Teal
  Color(0xFF06B6D4), // Bright cyan
  Color(0xFF22D3EE), // Light cyan
];

/// Single meeting row widget for meetings lists.
class MeetingListCard extends StatelessWidget {
  final Meeting meeting;
  final int colorIndex;
  final Meeting? currentMeeting;
  final Future<void> Function(Meeting meeting, String status)? onMeetingStatus;

  /// Optional widget before the avatar (e.g. selection checkbox).
  final Widget? leading;

  /// Optional widget at the end of the row (e.g. delete icon).
  final Widget? trailing;

  /// When true, [Meeting.topic] is omitted from the main title (same topic on every row in the list).
  final bool omitTopicInListTitle;

  const MeetingListCard({
    super.key,
    required this.meeting,
    required this.colorIndex,
    this.currentMeeting,
    this.onMeetingStatus,
    this.leading,
    this.trailing,
    this.omitTopicInListTitle = false,
  });

  static bool canCancelMeeting(Meeting m) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final meetingDate = DateTime(
      m.startTime.year,
      m.startTime.month,
      m.startTime.day,
    );
    return meetingDate.isAfter(today);
  }

  static void showCancelConfirmation(BuildContext context, Meeting m) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Cancel session?'),
            content: Text(
              'Cancel the session with ${m.participantName} on ${_formatDate(m.startTime)}? This cannot be undone.',
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
                      content: Text(
                        'Session with ${m.participantName} cancelled',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                ),
                child: const Text('Cancel session'),
              ),
            ],
          ),
    );
  }

  static void showPostponeConfirmation(BuildContext context, Meeting m) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Postpone session?'),
            content: Text(
              'Postpone the session with ${m.participantName}? You can reschedule it later.',
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
                      content: Text(
                        'Session with ${m.participantName} postponed',
                      ),
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  static String _formatPastMeetingHeading(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String? _courseLabel(Meeting m) {
    final d = m.discipline?.trim();
    final t = m.topic?.trim();
    final hasD = d != null && d.isNotEmpty;
    final hasT = t != null && t.isNotEmpty;
    if (!hasD && !hasT) return null;
    if (hasD && hasT) return '$d — $t';
    if (hasD) return d;
    return t;
  }

  static String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'on_time':
      case 'on time':
      case 'happened':
        return 'On time';
      case 'late':
        return 'Late';
      case 'postponed':
        return 'Postponed';
      case 'cancelled':
        return 'Cancelled';
      case 'missed':
        return 'Missed';
      default:
        return status;
    }
  }

  static Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'on_time':
      case 'on time':
      case 'happened':
        return const Color(0xFF16A34A);
      case 'late':
        return const Color(0xFFF59E0B);
      case 'postponed':
        return const Color(0xFF2563EB);
      case 'cancelled':
        return const Color(0xFFDC2626);
      case 'missed':
        return const Color(0xFF7C2D12);
      default:
        return SyncUpTheme.textSecondary;
    }
  }

  static Widget _statusChipAction(
    BuildContext context, {
    required String label,
    required String statusValue,
    required String currentStatus,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final normalizedCurrent = currentStatus.trim().toLowerCase();
    final effectiveCurrent = normalizedCurrent.isEmpty ? 'on_time' : normalizedCurrent;
    final isSelected =
        statusValue == 'on_time'
            ? (effectiveCurrent == 'on_time' || effectiveCurrent == 'happened')
            : effectiveCurrent == statusValue;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.transparent,
        foregroundColor: isSelected ? Colors.white : color,
        side: BorderSide(color: color, width: isSelected ? 0 : 1),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        minimumSize: const Size(0, 26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }

  static Widget _statusBanner(BuildContext context, String status) {
    final color = _statusColor(status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        'Status: ${_statusLabel(status)}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static Future<void> showMeetingDetails(
    BuildContext context,
    Meeting m,
  ) async {
    await syncPriorSessionsForBooking(m);
    if (!context.mounted) return;
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: SyncUpTheme.textSecondary,
    );
    final minutesStyleHeading = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: SyncUpTheme.textSecondary,
      letterSpacing: 0.4,
    );
    final seedPriorSessions = priorSessionsForBooking(m);
    final priorHistory = _mergePriorHistory(seedPriorSessions);
    final historyMeetings = priorHistory
        .map((e) => e.meeting)
        .whereType<Meeting>()
        .toList();
    int countStatus(String status) {
      final normalized = status.trim().toLowerCase();
      var count = historyMeetings
          .where((x) {
            final s = (x.meetingStatus ?? '').trim().toLowerCase();
            if (normalized == 'on_time') return s == 'on_time' || s == 'happened';
            return s == normalized;
          })
          .length;
      final currentStatus = (m.meetingStatus ?? '').trim().toLowerCase();
      final isCurrentMatch =
          normalized == 'on_time'
              ? currentStatus == 'on_time' || currentStatus == 'happened'
              : currentStatus == normalized;
      if (isCurrentMatch) {
        count += 1;
      }
      return count;
    }
    final totalMeetings = historyMeetings.length + 1;
    final attendedCount = countStatus('on_time');
    final postponedCount = countStatus('postponed');
    final lateCount = countStatus('late');
    final punctualOrUnmarked = (totalMeetings - postponedCount - lateCount).clamp(0, 9999);
    final profileSummary =
        postponedCount == 0 && lateCount == 0
            ? 'Consistent meeting cadence with no delay or postponement flags.'
            : 'Mostly consistent record with $lateCount late and $postponedCount postponed meeting(s).';
    final isOpenSlot = m.participantName.trim().toLowerCase() == 'open slot';
    final existing = CurrentMeetingMinutesStore.get(m);
    final minutesController = TextEditingController(
      text: existing?.minutes ?? '',
    );
    final deliberationsController = TextEditingController(
      text: existing?.deliberations ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        var isSending = false;
        var priorPanelExpanded = false;
        var priorHistoryIndex = 0;
        var summaryExpanded = false;

        void saveMinutes({required bool showToast}) {
          final minutes = minutesController.text.trim();
          final delib = deliberationsController.text.trim();
          CurrentMeetingMinutesStore.put(
            m,
            minutes: minutes,
            deliberations: delib,
          );
          if (showToast && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Minutes saved.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }

        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            Future<void> doEmail() async {
              if (isSending) return;
              setLocalState(() => isSending = true);
              await Future<void>.delayed(const Duration(milliseconds: 900));
              setLocalState(() => isSending = false);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Email sent to ${m.participantName}.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: (MediaQuery.sizeOf(ctx).width * 0.92).clamp(
                    320.0,
                    720.0,
                  ),
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              m.participantName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: SyncUpTheme.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Material(
                        color: SyncUpTheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: SyncUpTheme.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => setLocalState(
                            () => summaryExpanded = !summaryExpanded,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Meeting summary',
                                        style: minutesStyleHeading,
                                      ),
                                    ),
                                    Text(
                                      '$totalMeetings total',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: SyncUpTheme.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    AnimatedRotation(
                                      turns: summaryExpanded ? 0.5 : 0,
                                      duration: const Duration(milliseconds: 180),
                                      child: const Icon(Icons.expand_more, size: 18),
                                    ),
                                  ],
                                ),
                                if (summaryExpanded) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Attended: $attendedCount · Postponed: $postponedCount · Late: $lateCount',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: SyncUpTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'On track / unmarked: $punctualOrUnmarked',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: SyncUpTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    profileSummary,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: SyncUpTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatTime(m.startTime)} – ${_formatTime(m.endTime)} • ${m.roomLabel}',
                        style: bodyStyle,
                      ),
                      if ((m.meetingStatus ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _statusBanner(ctx, m.meetingStatus!.trim()),
                      ],
                      const SizedBox(height: 12),
                      if (isSending) ...[
                        const LinearProgressIndicator(minHeight: 3),
                        const SizedBox(height: 12),
                      ],
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!isOpenSlot) ...[
                                Text('This session', style: titleStyle),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: SyncUpTheme.border,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if ((m.discipline ?? '').trim().isNotEmpty ||
                                          (m.topic ?? '').trim().isNotEmpty) ...[
                                        Text(
                                          'More information',
                                          style: minutesStyleHeading,
                                        ),
                                        const SizedBox(height: 6),
                                        if ((m.discipline ?? '').trim().isNotEmpty)
                                          Text(
                                            'Discipline: ${m.discipline!.trim()}',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: SyncUpTheme.textPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        if ((m.topic ?? '').trim().isNotEmpty) ...[
                                          if ((m.discipline ?? '').trim().isNotEmpty)
                                            const SizedBox(height: 4),
                                          Text(
                                            'Topic: ${m.topic!.trim()}',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: SyncUpTheme.textPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                      ],
                                      TextField(
                                        controller: minutesController,
                                        enabled: !isSending,
                                        decoration: const InputDecoration(
                                          labelText: 'Minutes',
                                          border: OutlineInputBorder(),
                                          alignLabelWithHint: true,
                                        ),
                                        minLines: 4,
                                        maxLines: 8,
                                      ),
                                      const SizedBox(height: 10),
                                      TextField(
                                        controller: deliberationsController,
                                        enabled: !isSending,
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Deliberations / Decisions',
                                          border: OutlineInputBorder(),
                                          alignLabelWithHint: true,
                                        ),
                                        minLines: 3,
                                        maxLines: 6,
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          TextButton.icon(
                                            onPressed:
                                                isSending
                                                    ? null
                                                    : () => saveMinutes(
                                                      showToast: true,
                                                    ),
                                            icon: const Icon(
                                              Icons.save_outlined,
                                              size: 18,
                                            ),
                                            label: const Text('Save'),
                                          ),
                                          const Spacer(),
                                          FilledButton.icon(
                                            onPressed:
                                                isSending
                                                    ? null
                                                    : () async {
                                                      saveMinutes(
                                                        showToast: false,
                                                      );
                                                      await doEmail();
                                                    },
                                            icon: const Icon(
                                              Icons.send_outlined,
                                              size: 18,
                                            ),
                                            label: Text(
                                              isSending ? 'Sending…' : 'Email',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Text('Open slot', style: titleStyle),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: SyncUpTheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: SyncUpTheme.border,
                                    ),
                                  ),
                                  child: Text(
                                    'This time is available and not yet booked. Minutes can be added after the slot is booked.',
                                    style: bodyStyle,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Material(
                                color: SyncUpTheme.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: SyncUpTheme.border),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                      title: Text(
                                        priorHistory.isEmpty
                                            ? 'No previous meetings'
                                            : '${priorHistory.length} previous meetings',
                                        style: titleStyle,
                                      ),
                                      subtitle:
                                          priorHistory.isEmpty
                                              ? Text(
                                                'Nothing earlier on file for this booking.',
                                                style: bodyStyle?.copyWith(
                                                  fontSize: 13,
                                                ),
                                              )
                                              : Text(
                                                'Newest is #1 · tap to expand and browse by number',
                                                style: bodyStyle?.copyWith(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                      trailing:
                                          priorHistory.isEmpty
                                              ? null
                                              : AnimatedRotation(
                                                turns:
                                                    priorPanelExpanded
                                                        ? 0.5
                                                        : 0,
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                child: Icon(
                                                  Icons.expand_more,
                                                  color:
                                                      SyncUpTheme.textSecondary,
                                                ),
                                              ),
                                      onTap:
                                          priorHistory.isEmpty
                                              ? null
                                              : () => setLocalState(() {
                                                if (!priorPanelExpanded) {
                                                  priorHistoryIndex = 0;
                                                }
                                                priorPanelExpanded =
                                                    !priorPanelExpanded;
                                              }),
                                    ),
                                    if (priorPanelExpanded &&
                                        priorHistory.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          8,
                                          0,
                                          8,
                                          12,
                                        ),
                                        child: Builder(
                                          builder: (context) {
                                            final entry =
                                                priorHistory[priorHistoryIndex];
                                            final n = priorHistory.length;
                                            final canGoNewer =
                                                priorHistoryIndex > 0;
                                            final canGoOlder =
                                                priorHistoryIndex < n - 1;
                                            final heading =
                                                _formatPastMeetingHeading(
                                                  entry.sortTime,
                                                );

                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      tooltip:
                                                          'Newer (lower #)',
                                                      onPressed:
                                                          canGoNewer
                                                              ? () => setLocalState(
                                                                () =>
                                                                    priorHistoryIndex--,
                                                              )
                                                              : null,
                                                      icon: const Icon(
                                                        Icons.chevron_left,
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        children: [
                                                          Text(
                                                            heading,
                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                            style: theme
                                                                .textTheme
                                                                .titleSmall
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  color:
                                                                      SyncUpTheme
                                                                          .textPrimary,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 2,
                                                          ),
                                                          Text(
                                                            '#${priorHistoryIndex + 1} of $n · newest first',
                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                            style: theme
                                                                .textTheme
                                                                .labelSmall
                                                                ?.copyWith(
                                                                  color:
                                                                      SyncUpTheme
                                                                          .textSecondary,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    IconButton(
                                                      tooltip:
                                                          'Older (higher #)',
                                                      onPressed:
                                                          canGoOlder
                                                              ? () => setLocalState(
                                                                () =>
                                                                    priorHistoryIndex++,
                                                              )
                                                              : null,
                                                      icon: const Icon(
                                                        Icons.chevron_right,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                        4,
                                                        0,
                                                        4,
                                                        8,
                                                      ),
                                                  child: SizedBox(
                                                    height: 36,
                                                    child: ListView.separated(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      itemCount: n,
                                                      separatorBuilder:
                                                          (_, __) =>
                                                              const SizedBox(
                                                                width: 6,
                                                              ),
                                                      itemBuilder: (
                                                        context,
                                                        i,
                                                      ) {
                                                        final sel =
                                                            i ==
                                                            priorHistoryIndex;
                                                        final tip =
                                                            _formatPastMeetingHeading(
                                                              priorHistory[i]
                                                                  .sortTime,
                                                            );
                                                        return Tooltip(
                                                          message: tip,
                                                          child: FilterChip(
                                                            label: Text(
                                                              '${i + 1}',
                                                            ),
                                                            selected: sel,
                                                            showCheckmark:
                                                                false,
                                                            visualDensity:
                                                                VisualDensity
                                                                    .compact,
                                                            labelStyle: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  sel
                                                                      ? FontWeight
                                                                          .w800
                                                                      : FontWeight
                                                                          .w600,
                                                              color:
                                                                  sel
                                                                      ? SyncUpTheme
                                                                          .primary
                                                                      : SyncUpTheme
                                                                          .textSecondary,
                                                            ),
                                                            selectedColor:
                                                                SyncUpTheme
                                                                    .primary
                                                                    .withValues(
                                                                      alpha:
                                                                          0.12,
                                                                    ),
                                                            side: BorderSide(
                                                              color:
                                                                  sel
                                                                      ? SyncUpTheme
                                                                          .primary
                                                                      : SyncUpTheme
                                                                          .border,
                                                            ),
                                                            onSelected:
                                                                (
                                                                  _,
                                                                ) => setLocalState(
                                                                  () =>
                                                                      priorHistoryIndex =
                                                                          i,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                if (entry.meeting != null)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      border: Border.all(
                                                        color: SyncUpTheme
                                                            .border
                                                            .withValues(
                                                              alpha: 0.6,
                                                            ),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          '${_formatTime(entry.meeting!.startTime)} – ${_formatTime(entry.meeting!.endTime)}',
                                                          style: bodyStyle,
                                                        ),
                                                        if (_courseLabel(
                                                              entry.meeting!,
                                                            ) !=
                                                            null) ...[
                                                          const SizedBox(
                                                            height: 6,
                                                          ),
                                                          Text(
                                                            _courseLabel(
                                                              entry.meeting!,
                                                            )!,
                                                            style: theme
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      SyncUpTheme
                                                                          .textPrimary,
                                                                ),
                                                          ),
                                                        ],
                                                        if (entry
                                                                    .meeting!
                                                                    .location !=
                                                                null &&
                                                            entry
                                                                .meeting!
                                                                .location!
                                                                .trim()
                                                                .isNotEmpty) ...[
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Text(
                                                            entry
                                                                .meeting!
                                                                .location!
                                                                .trim(),
                                                            style: bodyStyle,
                                                          ),
                                                        ],
                                                        if (entry
                                                                    .meeting!
                                                                    .minutes !=
                                                                null &&
                                                            entry
                                                                .meeting!
                                                                .minutes!
                                                                .trim()
                                                                .isNotEmpty) ...[
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          Text(
                                                            'Minutes',
                                                            style: theme
                                                                .textTheme
                                                                .labelSmall
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  color:
                                                                      SyncUpTheme
                                                                          .textSecondary,
                                                                  letterSpacing:
                                                                      0.4,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Text(
                                                            entry
                                                                .meeting!
                                                                .minutes!
                                                                .trim(),
                                                            style: bodyStyle,
                                                          ),
                                                        ],
                                                        if (entry
                                                                    .meeting!
                                                                    .deliberations !=
                                                                null &&
                                                            entry
                                                                .meeting!
                                                                .deliberations!
                                                                .trim()
                                                                .isNotEmpty) ...[
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                          Text(
                                                            'Decisions',
                                                            style: theme
                                                                .textTheme
                                                                .labelSmall
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  color:
                                                                      SyncUpTheme
                                                                          .textSecondary,
                                                                  letterSpacing:
                                                                      0.4,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Text(
                                                            entry
                                                                .meeting!
                                                                .deliberations!
                                                                .trim(),
                                                            style: bodyStyle,
                                                          ),
                                                        ],
                                                        if ((entry
                                                                    .meeting!
                                                                    .meetingStatus ??
                                                                '')
                                                            .trim()
                                                            .isNotEmpty) ...[
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                          _statusBanner(
                                                            context,
                                                            entry
                                                                .meeting!
                                                                .meetingStatus!
                                                                .trim(),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    minutesController.dispose();
    deliberationsController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = meeting;
    final startTime = m.startTime.toLocal();
    final endTime = m.endTime.toLocal();
    final isOpenSlot = m.participantName.trim().toLowerCase() == 'open slot';
    final now = DateTime.now();
    final isOngoing = !now.isBefore(startTime) && now.isBefore(endTime);
    final justEnded =
        now.isAfter(endTime) && now.difference(endTime).inMinutes <= 1;
    final isCurrent = isOngoing || justEnded;
    final isWarningWindow = isOngoing && endTime.difference(now).inMinutes <= 5;
    final totalSeconds = m.durationMinutes * 60;
    final elapsedSeconds = now.difference(startTime).inSeconds.clamp(0, totalSeconds);
    final progress = totalSeconds <= 0 ? 0.0 : elapsedSeconds / totalSeconds;
    final progressPct = (progress * 100).clamp(0, 100).round();
    final remaining = endTime.difference(now);
    final remainingLabel =
        '${remaining.inMinutes.clamp(0, 999)}:${(remaining.inSeconds % 60).clamp(0, 59).toString().padLeft(2, '0')}';
    final highlight = SyncUpTheme.primary.withValues(alpha: 0.55);
    final pulseOn = now.second.isEven;
    final surface = Colors.white;
    final bookedGradient =
        isOpenSlot
            ? null
            : LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                SyncUpTheme.primaryLight.withValues(alpha: isOngoing ? 0.45 : 0.35),
                SyncUpTheme.primaryLight.withValues(alpha: isOngoing ? 0.2 : 0.14),
                Colors.white,
              ],
              stops: const [0, 0.55, 1],
            );
    final railColor =
        isOpenSlot ? Colors.transparent : SyncUpTheme.primary.withValues(alpha: 0.9);
    final radius = BorderRadius.circular(1);
    final hasLeading = leading != null;
    final hasTrailing = trailing != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color:
                isCurrent
                    ? SyncUpTheme.primary.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08),
            blurRadius: isCurrent ? 8 : 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            gradient: bookedGradient,
            border:
                isCurrent
                    ? Border.all(color: highlight, width: 2)
                    : Border.all(
                      color:
                          isOpenSlot
                              ? SyncUpTheme.border.withValues(alpha: 0.08)
                              : SyncUpTheme.primary.withValues(alpha: 0.18),
                    ),
          ),
          child: Stack(
            children: [
              if (isCurrent)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 900),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            SyncUpTheme.primary.withValues(alpha: 0.06),
                            Colors.transparent,
                          ],
                          stops: pulseOn
                              ? const [0.0, 0.35, 0.7]
                              : const [0.2, 0.55, 0.9],
                        ),
                      ),
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    color: railColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hasLeading ? 6 : 10, 8, 10, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 4),
                      ],
                      if (isOpenSlot)
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: SyncUpTheme.primary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.event_available,
                            size: 16,
                            color: SyncUpTheme.primary,
                          ),
                        )
                      else
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: SyncUpTheme.primary.withValues(alpha: 0.15),
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: SyncUpTheme.primary,
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isOngoing)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            isOngoing
                                                ? SyncUpTheme.primary
                                                : SyncUpTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'In progress',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall?.copyWith(
                                        color:
                                            SyncUpTheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: SyncUpTheme.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: SyncUpTheme.primary
                                              .withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Text(
                                        'LIVE',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall?.copyWith(
                                          color: SyncUpTheme.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Text(
                              m.listTitleLabel(includeTopic: false),
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatTime(startTime)} – ${_formatTime(endTime)}',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isCurrent) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: _statusChipAction(
                                      context,
                                      label: 'On time',
                                      statusValue: 'on_time',
                                      currentStatus: (m.meetingStatus ?? '').trim().toLowerCase(),
                                      color: const Color(0xFF16A34A),
                                      onTap:
                                          onMeetingStatus == null
                                              ? null
                                              : () => onMeetingStatus!(m, 'on_time'),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: _statusChipAction(
                                      context,
                                      label: 'Late',
                                      statusValue: 'late',
                                      currentStatus: (m.meetingStatus ?? '').trim().toLowerCase(),
                                      color: const Color(0xFFF59E0B),
                                      onTap:
                                          onMeetingStatus == null
                                              ? null
                                              : () => onMeetingStatus!(m, 'late'),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: _statusChipAction(
                                      context,
                                      label: 'Postponed',
                                      statusValue: 'postponed',
                                      currentStatus: (m.meetingStatus ?? '').trim().toLowerCase(),
                                      color: const Color(0xFF2563EB),
                                      onTap:
                                          onMeetingStatus == null
                                              ? null
                                              : () => onMeetingStatus!(m, 'postponed'),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: _statusChipAction(
                                      context,
                                      label: 'Missed',
                                      statusValue: 'missed',
                                      currentStatus: (m.meetingStatus ?? '').trim().toLowerCase(),
                                      color: const Color(0xFF7C2D12),
                                      onTap:
                                          onMeetingStatus == null
                                              ? null
                                              : () => onMeetingStatus!(m, 'missed'),
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (canCancelMeeting(m)) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  OutlinedButton(
                                    onPressed:
                                        () =>
                                            showCancelConfirmation(context, m),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFDC2626),
                                      side: const BorderSide(
                                        color: Color(0xFFDC2626),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      minimumSize: const Size(0, 28),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton(
                                    onPressed:
                                        () => showPostponeConfirmation(
                                          context,
                                          m,
                                        ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: SyncUpTheme.primary,
                                      side: const BorderSide(
                                        color: SyncUpTheme.primary,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      minimumSize: const Size(0, 28),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    child: const Text(
                                      'Postpone',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCurrent)
                            SizedBox(
                              width: 86,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: isOngoing ? progress : 1,
                                      minHeight: 3,
                                      backgroundColor: SyncUpTheme.divider,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isWarningWindow
                                            ? const Color(0xFFDC2626)
                                            : SyncUpTheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${isOngoing ? progressPct : 100}%',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: isWarningWindow
                                              ? const Color(0xFFDC2626)
                                              : SyncUpTheme.textSecondary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                        ),
                                      ),
                                      if (isWarningWindow) ...[
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.notifications_active,
                                          size: 12,
                                          color: Color(0xFFDC2626),
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          remainingLabel,
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: const Color(0xFFDC2626),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          if (isCurrent) const SizedBox(width: 2),
                          IconButton(
                            tooltip: 'Session details',
                            onPressed: () => showMeetingDetails(context, m),
                            icon: const Icon(Icons.info_outline, size: 20),
                            visualDensity: VisualDensity.compact,
                          ),
                          if (hasTrailing) trailing!,
                        ],
                      ),
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
    );
  }
}
