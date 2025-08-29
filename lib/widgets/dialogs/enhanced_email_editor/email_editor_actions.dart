import 'package:flutter/material.dart';
import '../../../theme/app_theme_professional.dart';
import '../../../models_and_services.dart';

class EmailEditorActions extends StatelessWidget {
  final bool isMobile;
  final bool isSmallScreen;
  final bool isLoading;
  final bool hasValidEmails;
  final String? error;
  final List<EmailSendResult>? results;
  final VoidCallback onSend;
  final VoidCallback onInsertVoting;
  final VoidCallback onInsertInvestmentTable;
  final VoidCallback onClear;

  const EmailEditorActions({
    super.key,
    required this.isMobile,
    required this.isSmallScreen,
    required this.isLoading,
    required this.hasValidEmails,
    required this.error,
    required this.results,
    required this.onSend,
    required this.onInsertVoting,
    required this.onInsertInvestmentTable,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        border: Border(
          top: BorderSide(color: AppThemePro.borderPrimary),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error display
          if (error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppThemePro.statusError.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppThemePro.statusError),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppThemePro.statusError,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: AppThemePro.statusError,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Results display
          if (results != null && results!.isNotEmpty) ...[
            _buildResultsSection(),
            const SizedBox(height: 12),
          ],

          // Action buttons
          if (isMobile)
            _buildMobileActions(context)
          else
            _buildDesktopActions(context),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    final successful = results!.where((r) => r.success).length;
    final failed = results!.length - successful;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: failed == 0
            ? AppThemePro.statusSuccess.withOpacity(0.1)
            : AppThemePro.statusWarning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: failed == 0 ? AppThemePro.statusSuccess : AppThemePro.statusWarning,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                failed == 0 ? Icons.check_circle : Icons.warning,
                color: failed == 0 ? AppThemePro.statusSuccess : AppThemePro.statusWarning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Wyniki wysyłania:',
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Wysłano: $successful, Błędy: $failed',
            style: TextStyle(
              color: AppThemePro.textSecondary,
              fontSize: 14,
            ),
          ),
          if (failed > 0) ...[
            const SizedBox(height: 8),
            const Text(
              'Szczegóły błędów:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            ...results!
                .where((r) => !r.success)
                .take(3)
                .map((r) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Text(
                        '• ${r.clientName}: ${r.error ?? "Nieznany błąd"}',
                        style: TextStyle(
                          color: AppThemePro.statusError,
                          fontSize: 11,
                        ),
                      ),
                    )),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileActions(BuildContext context) {
    return Column(
      children: [
        // Primary action
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: hasValidEmails && !isLoading ? onSend : null,
            icon: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppThemePro.textPrimary,
                      ),
                    ),
                  )
                : const Icon(Icons.send, size: 18),
            label: Text(isLoading ? 'Wysyłanie...' : 'Wyślij emaile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemePro.accentGold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Secondary actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onInsertVoting,
                icon: const Icon(Icons.how_to_vote, size: 16),
                label: const Text('Głosowanie'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppThemePro.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onInsertInvestmentTable,
                icon: const Icon(Icons.table_chart, size: 16),
                label: const Text('Tabela'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppThemePro.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onClear,
          icon: const Icon(Icons.clear, size: 16),
          label: const Text('Wyczyść editor'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppThemePro.statusError,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopActions(BuildContext context) {
    return Row(
      children: [
        // Quick insert buttons
        ElevatedButton.icon(
          onPressed: isLoading ? null : onInsertVoting,
          icon: const Icon(Icons.how_to_vote, size: 16),
          label: const Text('Wstaw głosowanie'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: isLoading ? null : onInsertInvestmentTable,
          icon: const Icon(Icons.table_chart, size: 16),
          label: const Text('Wstaw tabelę'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onClear,
          icon: const Icon(Icons.clear, size: 16),
          label: const Text('Wyczyść'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppThemePro.statusError,
          ),
        ),
        const Spacer(),
        // Primary send button
        ElevatedButton.icon(
          onPressed: hasValidEmails && !isLoading ? onSend : null,
          icon: isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
              : const Icon(Icons.send, size: 18),
          label: Text(isLoading ? 'Wysyłanie...' : 'Wyślij emaile'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppThemePro.accentGold,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}