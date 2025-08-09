import 'package:flutter/material.dart';
import '../../models/calendar/calendar_event.dart';

class CalendarEventList extends StatelessWidget {
  final List<CalendarEvent> events;
  final ValueChanged<CalendarEvent>? onEventTap;
  final bool compact;

  const CalendarEventList({
    super.key,
    required this.events,
    this.onEventTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Brak wydarzeń',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (context, index) =>
          compact ? const SizedBox(height: 4) : const Divider(height: 1),
      itemBuilder: (context, index) {
        final event = events[index];
        return compact
            ? _buildCompactEventCard(context, event)
            : _buildFullEventCard(context, event);
      },
    );
  }

  Widget _buildCompactEventCard(BuildContext context, CalendarEvent event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      elevation: 1,
      child: ListTile(
        dense: true,
        leading: Container(
          width: 4,
          height: double.infinity,
          color: Color(event.category.colorValue),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatEventTime(event),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: _buildEventStatusIcon(event),
        onTap: () => onEventTap?.call(event),
      ),
    );
  }

  Widget _buildFullEventCard(BuildContext context, CalendarEvent event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => onEventTap?.call(event),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(event.category.colorValue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.category.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(event.category.colorValue),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildEventStatusIcon(event),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                event.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (event.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  event.description!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatEventTime(event),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  if (event.location != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              if (event.participants.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${event.participants.length} uczestników',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventStatusIcon(CalendarEvent event) {
    IconData icon;
    Color color;

    switch (event.status) {
      case CalendarEventStatus.confirmed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case CalendarEventStatus.tentative:
        icon = Icons.help_outline;
        color = Colors.orange;
        break;
      case CalendarEventStatus.cancelled:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case CalendarEventStatus.pending:
        icon = Icons.schedule;
        color = Colors.blue;
        break;
    }

    return Icon(icon, size: 16, color: color);
  }

  String _formatEventTime(CalendarEvent event) {
    if (event.isAllDay) {
      return 'Cały dzień';
    }

    final startTime =
        '${event.startDate.hour.toString().padLeft(2, '0')}:${event.startDate.minute.toString().padLeft(2, '0')}';
    final endTime =
        '${event.endDate.hour.toString().padLeft(2, '0')}:${event.endDate.minute.toString().padLeft(2, '0')}';

    if (event.startDate.day == event.endDate.day) {
      return '$startTime - $endTime';
    } else {
      return '$startTime - ${event.endDate.day}/${event.endDate.month} $endTime';
    }
  }
}
