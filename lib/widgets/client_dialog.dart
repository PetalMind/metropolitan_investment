import 'package:flutter/material.dart';
import '../models_and_services.dart';

class ClientDialog extends StatelessWidget {
  final Client? client;
  final Function(Client) onSave;
  final VoidCallback? onCancel;

  const ClientDialog({
    super.key,
    this.client,
    required this.onSave,
    this.onCancel,
  });

  static Future<void> show({
    required BuildContext context,
    Client? client,
    required Function(Client) onSave,
    VoidCallback? onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          ClientDialog(client: client, onSave: onSave, onCancel: onCancel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.backgroundModal,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nagłówek
            Row(
              children: [
                Icon(
                  client == null ? Icons.person_add : Icons.edit,
                  color: AppTheme.secondaryGold,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  client == null ? 'Nowy Klient' : 'Edytuj Klienta',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Formularz klienta
            Expanded(
              child: ClientForm(
                client: client,
                onSave: (savedClient) {
                  Navigator.of(context).pop();
                  onSave(savedClient);
                },
                onCancel: onCancel ?? () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
