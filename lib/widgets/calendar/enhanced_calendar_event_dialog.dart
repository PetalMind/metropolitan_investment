import 'package:flutter/material.dart';

// Lightweight stub dialog for calendar events.
// This file is intentionally minimal: it provides a simple widget so
// `models_and_services.dart` can export it and the app can compile.

class EnhancedCalendarEventDialog extends StatelessWidget {
  final String? title;
  final String? description;

  const EnhancedCalendarEventDialog({Key? key, this.title, this.description}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? 'Event'),
      content: Text(description ?? 'No details.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// For convenience, provide a helper to show the dialog.
Future<void> showEnhancedCalendarEventDialog(BuildContext context,
    {String? title, String? description}) {
  return showDialog(
    context: context,
    builder: (_) => EnhancedCalendarEventDialog(title: title, description: description),
  );
}
