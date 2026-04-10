import 'package:flutter/material.dart';

import '../data/current_meeting_minutes.dart';
import '../data/meeting_notes.dart';
import '../data/sample_data.dart';
import '../models/meeting.dart';
import '../theme/sync_up_theme.dart';

/// Single row in the merged “previous meetings” list (seed session or templated note).
class _PriorHistoryEntry {
  _PriorHistoryEntry._({required this.sortTime, this.meeting, this.note})
      : assert((meeting != null) ^ (note != null));

  factory _PriorHistoryEntry.seed(Meeting m) =>
      _PriorHistoryEntry._(sortTime: m.startTime, meeting: m);

  factory _PriorHistoryEntry.note(PastMeetingNote n) =>
      _PriorHistoryEntry._(sortTime: n.when, note: n);

  final DateTime sortTime;
  final Meeting? meeting;
  final PastMeetingNote? note;
}

List<_PriorHistoryEntry> _mergePriorHistory(
  List<Meeting> seeds,
  List<PastMeetingNote> notes,
) {
  final out = <_PriorHistoryEntry>[
    ...seeds.map(_PriorHistoryEntry.seed),
    ...notes.map(_PriorHistoryEntry.note),
  ];
  out.sort((a, b) {
    final c = b.sortTime.compareTo(a.sortTime);
    if (c != 0) return c;
    if (a.meeting != null && b.note != null) return -1;
    if (a.note != null && b.meeting != null) return 1;
    return 0;
  });
  return out;
}

/// Left accent colors for list cards (matches slot design).
const List<Color> listCardAccentColors = [
  Color(0xFF6366F1), // Indigo
  Color(0xFF8B5CF6), // Violet
  Color(0xFF3B82F6), // Blue
  Color(0xFF10B981), // Emerald
  Color(0xFFEC4899), // Pink
  Color(0xFFF59E0B), // Amber
];

/// Single meeting row widget for meetings lists.
class MeetingListCard extends StatelessWidget {
  final Meeting meeting;
  final int colorIndex;
  final Meeting? currentMeeting;
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
    this.leading,
    this.trailing,
    this.omitTopicInListTitle = false,
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
                  content: Text('Session with ${m.participantName} cancelled'),
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
      builder: (ctx) => AlertDialog(
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
                  content: Text('Session with ${m.participantName} postponed'),
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

  static String _formatPastMeetingHeading(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static Future<void> showMeetingDetails(BuildContext context, Meeting m) async {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(color: SyncUpTheme.textSecondary);
    final pastNotes = getPastMeetingNotes(m);
    final seedPriorSessions = priorSessionsForBooking(m);
    final priorHistory = _mergePriorHistory(seedPriorSessions, pastNotes);
    final isOpenSlot = m.participantName.trim().toLowerCase() == 'open slot';
    final existing = CurrentMeetingMinutesStore.get(m);
    final minutesController = TextEditingController(text: existing?.minutes ?? '');
    final deliberationsController = TextEditingController(
      text: existing?.deliberations ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        var isSending = false;
        var priorPanelExpanded = false;
        var priorHistoryIndex = 0;

        void saveMinutes({required bool showToast}) {
          final minutes = minutesController.text.trim();
          final delib = deliberationsController.text.trim();
          CurrentMeetingMinutesStore.put(m, minutes: minutes, deliberations: delib);
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
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: (MediaQuery.sizeOf(ctx).width * 0.92).clamp(320.0, 720.0),
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
                      Text(
                        '${_formatTime(m.startTime)} – ${_formatTime(m.endTime)} • ${m.roomLabel}'
                        '${m.topic != null && m.topic!.trim().isNotEmpty ? ' • ${m.topic}' : ''}',
                        style: bodyStyle,
                      ),
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
                                    border: Border.all(color: SyncUpTheme.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
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
                                          labelText: 'Deliberations / Decisions',
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
                                            onPressed: isSending
                                                ? null
                                                : () => saveMinutes(showToast: true),
                                            icon: const Icon(Icons.save_outlined, size: 18),
                                            label: const Text('Save'),
                                          ),
                                          const Spacer(),
                                          FilledButton.icon(
                                            onPressed: isSending
                                                ? null
                                                : () async {
                                                    saveMinutes(showToast: false);
                                                    await doEmail();
                                                  },
                                            icon: const Icon(Icons.send_outlined, size: 18),
                                            label: Text(isSending ? 'Sending…' : 'Email'),
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
                                    border: Border.all(color: SyncUpTheme.border),
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
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      title: Text(
                                        priorHistory.isEmpty
                                            ? 'No previous meetings'
                                            : '${priorHistory.length} previous meetings',
                                        style: titleStyle,
                                      ),
                                      subtitle: priorHistory.isEmpty
                                          ? Text(
                                              'Nothing earlier on file for this booking.',
                                              style: bodyStyle?.copyWith(fontSize: 13),
                                            )
                                          : Text(
                                              'Newest is #1 · tap to expand and browse by number',
                                              style: bodyStyle?.copyWith(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                      trailing: priorHistory.isEmpty
                                          ? null
                                          : AnimatedRotation(
                                              turns: priorPanelExpanded ? 0.5 : 0,
                                              duration: const Duration(milliseconds: 200),
                                              child: Icon(
                                                Icons.expand_more,
                                                color: SyncUpTheme.textSecondary,
                                              ),
                                            ),
                                      onTap: priorHistory.isEmpty
                                          ? null
                                          : () => setLocalState(() {
                                                if (!priorPanelExpanded) {
                                                  priorHistoryIndex = 0;
                                                }
                                                priorPanelExpanded = !priorPanelExpanded;
                                              }),
                                    ),
                                    if (priorPanelExpanded && priorHistory.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                                        child: Builder(
                                          builder: (context) {
                                            final entry = priorHistory[priorHistoryIndex];
                                            final n = priorHistory.length;
                                            final canGoNewer = priorHistoryIndex > 0;
                                            final canGoOlder = priorHistoryIndex < n - 1;
                                            final heading = entry.meeting != null
                                                ? _formatPastMeetingHeading(entry.meeting!.startTime)
                                                : _formatPastMeetingHeading(entry.note!.when);

                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      tooltip: 'Newer (lower #)',
                                                      onPressed: canGoNewer
                                                          ? () => setLocalState(
                                                                () => priorHistoryIndex--,
                                                              )
                                                          : null,
                                                      icon: const Icon(Icons.chevron_left),
                                                    ),
                                                    Expanded(
                                                      child: Column(
                                                        children: [
                                                          Text(
                                                            heading,
                                                            textAlign: TextAlign.center,
                                                            style: theme.textTheme.titleSmall
                                                                ?.copyWith(
                                                              fontWeight: FontWeight.w800,
                                                              color: SyncUpTheme.textPrimary,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            '#${priorHistoryIndex + 1} of $n · newest first',
                                                            textAlign: TextAlign.center,
                                                            style: theme.textTheme.labelSmall
                                                                ?.copyWith(
                                                              color: SyncUpTheme.textSecondary,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    IconButton(
                                                      tooltip: 'Older (higher #)',
                                                      onPressed: canGoOlder
                                                          ? () => setLocalState(
                                                                () => priorHistoryIndex++,
                                                              )
                                                          : null,
                                                      icon: const Icon(Icons.chevron_right),
                                                    ),
                                                  ],
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                                                  child: SizedBox(
                                                    height: 36,
                                                    child: ListView.separated(
                                                      scrollDirection: Axis.horizontal,
                                                      itemCount: n,
                                                      separatorBuilder: (_, __) =>
                                                          const SizedBox(width: 6),
                                                      itemBuilder: (context, i) {
                                                        final sel = i == priorHistoryIndex;
                                                        final tip =
                                                            _formatPastMeetingHeading(
                                                          priorHistory[i].sortTime,
                                                        );
                                                        return Tooltip(
                                                          message: tip,
                                                          child: FilterChip(
                                                            label: Text('${i + 1}'),
                                                            selected: sel,
                                                            showCheckmark: false,
                                                            visualDensity: VisualDensity.compact,
                                                            labelStyle: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: sel
                                                                  ? FontWeight.w800
                                                                  : FontWeight.w600,
                                                              color: sel
                                                                  ? SyncUpTheme.primary
                                                                  : SyncUpTheme.textSecondary,
                                                            ),
                                                            selectedColor: SyncUpTheme.primary
                                                                .withValues(alpha: 0.12),
                                                            side: BorderSide(
                                                              color: sel
                                                                  ? SyncUpTheme.primary
                                                                  : SyncUpTheme.border,
                                                            ),
                                                            onSelected: (_) => setLocalState(
                                                              () => priorHistoryIndex = i,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                if (entry.meeting != null)
                                                  Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(
                                                        color: SyncUpTheme.border.withValues(
                                                          alpha: 0.6,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          '${_formatTime(entry.meeting!.startTime)} – ${_formatTime(entry.meeting!.endTime)}',
                                                          style: bodyStyle,
                                                        ),
                                                        if (bookingCourseLabel(entry.meeting!) !=
                                                            null) ...[
                                                          const SizedBox(height: 6),
                                                          Text(
                                                            bookingCourseLabel(entry.meeting!)!,
                                                            style: theme.textTheme.bodyMedium
                                                                ?.copyWith(
                                                              fontWeight: FontWeight.w600,
                                                              color: SyncUpTheme.textPrimary,
                                                            ),
                                                          ),
                                                        ],
                                                        if (entry.meeting!.location != null &&
                                                            entry.meeting!.location!
                                                                .trim()
                                                                .isNotEmpty) ...[
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            entry.meeting!.location!.trim(),
                                                            style: bodyStyle,
                                                          ),
                                                        ],
                                                        if (entry.meeting!.minutes != null &&
                                                            entry.meeting!.minutes!.trim().isNotEmpty) ...[
                                                          const SizedBox(height: 12),
                                                          Text(
                                                            'Minutes',
                                                            style: theme.textTheme.labelSmall?.copyWith(
                                                              fontWeight: FontWeight.w800,
                                                              color: SyncUpTheme.textSecondary,
                                                              letterSpacing: 0.4,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            entry.meeting!.minutes!.trim(),
                                                            style: bodyStyle,
                                                          ),
                                                        ],
                                                        if (entry.meeting!.deliberations != null &&
                                                            entry
                                                                .meeting!.deliberations!.trim()
                                                                .isNotEmpty) ...[
                                                          const SizedBox(height: 10),
                                                          Text(
                                                            'Decisions',
                                                            style: theme.textTheme.labelSmall?.copyWith(
                                                              fontWeight: FontWeight.w800,
                                                              color: SyncUpTheme.textSecondary,
                                                              letterSpacing: 0.4,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            entry.meeting!.deliberations!.trim(),
                                                            style: bodyStyle,
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  )
                                                else
                                                  Builder(
                                                    builder: (context) {
                                                      final p = entry.note!;
                                                      return Container(
                                                        padding: const EdgeInsets.all(12),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(10),
                                                          border: Border.all(
                                                            color: SyncUpTheme.border.withValues(
                                                              alpha: 0.6,
                                                            ),
                                                          ),
                                                        ),
                                                        constraints: const BoxConstraints(
                                                          maxHeight: 280,
                                                        ),
                                                        child: SingleChildScrollView(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment.stretch,
                                                            children: [
                                                              Text(
                                                                'Summary',
                                                                style: Theme.of(context)
                                                                    .textTheme
                                                                    .labelSmall
                                                                    ?.copyWith(
                                                                      fontWeight: FontWeight.w800,
                                                                      color: SyncUpTheme
                                                                          .textSecondary,
                                                                      letterSpacing: 0.4,
                                                                    ),
                                                              ),
                                                              const SizedBox(height: 6),
                                                              Text(
                                                                '${p.discussions.length} discussion points · ${p.todos.length} follow-ups',
                                                                style: bodyStyle,
                                                              ),
                                                              const SizedBox(height: 14),
                                                              Align(
                                                                alignment: Alignment.centerLeft,
                                                                child: Text(
                                                                  'Discussion',
                                                                  style: titleStyle,
                                                                ),
                                                              ),
                                                              const SizedBox(height: 6),
                                                              _DetailsBullets(items: p.discussions),
                                                              const SizedBox(height: 12),
                                                              Align(
                                                                alignment: Alignment.centerLeft,
                                                                child: Text(
                                                                  'Follow-ups',
                                                                  style: titleStyle,
                                                                ),
                                                              ),
                                                              const SizedBox(height: 6),
                                                              _DetailsCheckItems(items: p.todos),
                                                              if ((p.notes ?? '').trim().isNotEmpty) ...[
                                                                const SizedBox(height: 12),
                                                                Align(
                                                                  alignment: Alignment.centerLeft,
                                                                  child: Text(
                                                                    'Notes',
                                                                    style: titleStyle,
                                                                  ),
                                                                ),
                                                                const SizedBox(height: 6),
                                                                Container(
                                                                  width: double.infinity,
                                                                  padding: const EdgeInsets.all(10),
                                                                  decoration: BoxDecoration(
                                                                    color: SyncUpTheme.surface,
                                                                    borderRadius:
                                                                        BorderRadius.circular(8),
                                                                    border: Border.all(
                                                                      color: SyncUpTheme.border,
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    p.notes!.trim(),
                                                                    style: bodyStyle,
                                                                  ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
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
    final accentColor = listCardAccentColors[colorIndex % listCardAccentColors.length];
    final isOpenSlot = m.participantName.trim().toLowerCase() == 'open slot';
    final isCurrent = currentMeeting?.id == m.id;
    final now = DateTime.now();
    final isOngoing =
        isCurrent && !now.isBefore(m.startTime) && now.isBefore(m.endTime);
    final highlight = SyncUpTheme.primary.withValues(alpha: 0.55);
    final surface = isOpenSlot
        ? Colors.white
        : (isOngoing ? SyncUpTheme.primary.withValues(alpha: 0.05) : Colors.white);
    final radius = BorderRadius.circular(1);
    final hasLeading = leading != null;
    final hasTrailing = trailing != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
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
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            border: isCurrent ? Border.all(color: highlight, width: 2) : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  Container(width: 4, color: isOpenSlot ? Colors.transparent : accentColor),
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
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.add,
                                size: 16,
                                color: SyncUpTheme.textSecondary,
                              ),
                            )
                          else
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: accentColor,
                              child: Text(
                                m.participantName.isNotEmpty
                                    ? m.participantName[0].toUpperCase()
                                    : '?',
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
                                            color: isOngoing
                                                ? SyncUpTheme.primary
                                                : SyncUpTheme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isOngoing ? 'In progress' : 'Just ended',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: isOngoing
                                                    ? SyncUpTheme.primary
                                                    : SyncUpTheme.textSecondary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 10,
                                              ),
                                        ),
                                        if (isOngoing) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: SyncUpTheme.primary
                                                  .withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(999),
                                              border: Border.all(
                                                color: SyncUpTheme.primary
                                                    .withValues(alpha: 0.35),
                                              ),
                                            ),
                                            child: Text(
                                              'LIVE',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: SyncUpTheme.primary,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 10,
                                                    letterSpacing: 0.6,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                Text(
                                  omitTopicInListTitle
                                      ? m.listTitleLabel(includeTopic: false)
                                      : m.displayLabel,
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
                                  '${_formatTime(m.startTime)} – ${_formatTime(m.endTime)}',
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (canCancelMeeting(m)) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      OutlinedButton(
                                        onPressed: () =>
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
                                        onPressed: () =>
                                            showPostponeConfirmation(context, m),
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
        ),
      ),
    );
  }
}

class _DetailsBullets extends StatelessWidget {
  final List<String> items;
  const _DetailsBullets({required this.items});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: SyncUpTheme.textPrimary,
          height: 1.4,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final t in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(child: Text(t, style: style)),
              ],
            ),
          ),
      ],
    );
  }
}

class _DetailsCheckItems extends StatelessWidget {
  final List<String> items;
  const _DetailsCheckItems({required this.items});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: SyncUpTheme.textPrimary,
          height: 1.4,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final t in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: SyncUpTheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(t, style: style)),
              ],
            ),
          ),
      ],
    );
  }
}
