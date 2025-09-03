import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme_professional.dart';
import '../models_and_services.dart';

/// Widget do wyświetlania historii wysłanych emaili dla konkretnego klienta
class EmailHistoryWidget extends StatefulWidget {
  final String clientId;
  final String? title;
  final bool isCompact;
  final int? maxEntries;

  const EmailHistoryWidget({
    super.key,
    required this.clientId,
    this.title,
    this.isCompact = false,
    this.maxEntries,
  });

  @override
  State<EmailHistoryWidget> createState() => _EmailHistoryWidgetState();
}

class _EmailHistoryWidgetState extends State<EmailHistoryWidget> {
  final EmailHistoryService _emailHistoryService = EmailHistoryService();
  List<EmailHistory> _emailHistory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmailHistory();
  }

  Future<void> _loadEmailHistory() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final history = await _emailHistoryService.getEmailHistoryForClient(
        widget.clientId,
      );

      if (mounted) {
        setState(() {
          _emailHistory = widget.maxEntries != null
              ? history.take(widget.maxEntries!).toList()
              : history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Błąd podczas ładowania historii emaili: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_emailHistory.isEmpty) {
      return _buildEmptyState();
    }

    return widget.isCompact ? _buildCompactView() : _buildDetailedView();
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Ładowanie historii emaili...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: AppThemePro.lossRed, size: 32),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppThemePro.lossRed,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              if (mounted) {
                _loadEmailHistory();
              }
            },
            child: const Text('Spróbuj ponownie'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.email_outlined, color: AppThemePro.textMuted, size: 32),
          const SizedBox(height: 12),
          Text(
            'Brak historii emaili',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppThemePro.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ten klient nie otrzymał jeszcze żadnych emaili.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppThemePro.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView() {
    return Container(
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.email, size: 20, color: AppThemePro.accentGold),
                const SizedBox(width: 8),
                Text(
                  widget.title ?? 'Historia emaili (${_emailHistory.length})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Email entries - limit height and make scrollable for compact view
          if (_emailHistory.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 200, // Limit height for compact view
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _emailHistory.length,
                itemBuilder: (context, index) {
                  return _buildCompactEmailEntry(
                    _emailHistory[index],
                    index == _emailHistory.length - 1,
                  );
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Brak historii emaili',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailedView() {
    return Container(
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemePro.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppThemePro.accentGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.email,
                    size: 24,
                    color: AppThemePro.accentGold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title ?? 'Historia emaili',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppThemePro.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_emailHistory.length} ${_getEmailText(_emailHistory.length)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppThemePro.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Email entries - wrapped in Expanded and ListView to prevent overflow
          Expanded(
            child: _emailHistory.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Brak historii emaili dla tego klienta',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppThemePro.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _emailHistory.length,
                    itemBuilder: (context, index) {
                      return _buildDetailedEmailEntry(
                        _emailHistory[index],
                        index == _emailHistory.length - 1,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactEmailEntry(EmailHistory email, bool isLast) {
    final recipientForClient = email.recipients
        .firstWhere(
          (r) => r.clientId == widget.clientId,
          orElse: () => email.recipients.first,
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast
                ? Colors.transparent
                : AppThemePro.borderPrimary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Date and time
          SizedBox(
            width: 60,
            child: Text(
              DateFormat('dd.MM\nHH:mm').format(email.sentAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppThemePro.textMuted,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: 12),

          // Status icon
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _getStatusColor(email.status, recipientForClient.deliveryStatus).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              _getStatusIcon(email.status, recipientForClient.deliveryStatus),
              size: 14,
              color: _getStatusColor(email.status, recipientForClient.deliveryStatus),
            ),
          ),

          const SizedBox(width: 12),

          // Email details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email.subject,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: _getStatusColor(email.status, recipientForClient.deliveryStatus).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        recipientForClient.deliveryStatus.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(email.status, recipientForClient.deliveryStatus),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Od: ${email.senderName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedEmailEntry(EmailHistory email, bool isLast) {
    final recipientForClient = email.recipients
        .firstWhere(
          (r) => r.clientId == widget.clientId,
          orElse: () => email.recipients.first,
        );

    return Container(
      margin: EdgeInsets.only(left: 20, right: 20, bottom: isLast ? 20 : 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(email.status, recipientForClient.deliveryStatus).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(email.status, recipientForClient.deliveryStatus).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(email.status, recipientForClient.deliveryStatus),
                      size: 14,
                      color: _getStatusColor(email.status, recipientForClient.deliveryStatus),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      recipientForClient.deliveryStatus.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(email.status, recipientForClient.deliveryStatus),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Text(
                DateFormat('dd.MM.yyyy HH:mm').format(email.sentAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppThemePro.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Subject
          Text(
            email.subject,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          // Email details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppThemePro.surfaceCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Tytuł', '${email.subject} <${email.subject}>'),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Odbiorca',
                  '${recipientForClient.clientName} <${recipientForClient.emailAddress}>',
                ),
                if (email.includeInvestmentDetails) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('Szczegóły inwestycji', 'Dołączone'),
                ],
                if (recipientForClient.deliveryError != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('Błąd doręczenia', recipientForClient.deliveryError!, isError: true),
                ],
                if (email.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('Błąd wysyłania', email.errorMessage!, isError: true),
                ],
              
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppThemePro.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isError ? AppThemePro.lossRed : AppThemePro.textPrimary,
              fontWeight: isError ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(EmailStatus emailStatus, DeliveryStatus deliveryStatus) {
    if (emailStatus == EmailStatus.failed) {
      return AppThemePro.lossRed;
    }

    switch (deliveryStatus) {
      case DeliveryStatus.delivered:
        return AppThemePro.profitGreen;
      case DeliveryStatus.pending:
        return AppThemePro.accentGold;
      case DeliveryStatus.failed:
      case DeliveryStatus.bounced:
        return AppThemePro.lossRed;
      case DeliveryStatus.spam:
        return AppThemePro.neutralGray;
    }
  }

  IconData _getStatusIcon(EmailStatus emailStatus, DeliveryStatus deliveryStatus) {
    if (emailStatus == EmailStatus.failed) {
      return Icons.error;
    }

    switch (deliveryStatus) {
      case DeliveryStatus.delivered:
        return Icons.check_circle;
      case DeliveryStatus.pending:
        return Icons.access_time;
      case DeliveryStatus.failed:
        return Icons.error;
      case DeliveryStatus.bounced:
        return Icons.reply;
      case DeliveryStatus.spam:
        return Icons.report;
    }
  }

  String _getEmailText(int count) {
    if (count == 1) return 'email';
    if (count >= 2 && count <= 4) return 'emaile';
    return 'emaili';
  }
}