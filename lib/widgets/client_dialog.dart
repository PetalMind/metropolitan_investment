import 'package:flutter/material.dart';
import '../models_and_services.dart';
import '../theme/app_theme_professional.dart';
import 'client_form.dart';

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
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        decoration: AppThemePro.premiumCardDecoration.copyWith(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppThemePro.overlayDark,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profesjonalny nagłówek
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppThemePro.primaryDark,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppThemePro.borderPrimary,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppThemePro.accentGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppThemePro.accentGold.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      client == null
                          ? Icons.person_add_rounded
                          : Icons.edit_rounded,
                      color: AppThemePro.accentGold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client == null ? 'Nowy Klient' : 'Edytuj Klienta',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppThemePro.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          client == null
                              ? 'Dodaj nowego klienta do systemu'
                              : 'Modyfikuj dane klienta ${client!.name}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppThemePro.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Przycisk zamknij
                  Container(
                    decoration: BoxDecoration(
                      color: AppThemePro.surfaceInteractive,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppThemePro.borderSecondary,
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppThemePro.textSecondary,
                        size: 20,
                      ),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Zawartość formularza
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: ClientForm(
                  client: client,
                  onSave: (savedClient) {
                    Navigator.of(context).pop();
                    onSave(savedClient);
                  },
                  onCancel: onCancel ?? () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
