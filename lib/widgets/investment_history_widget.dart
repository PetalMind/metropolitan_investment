import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme_professional.dart';
import '../models_and_services.dart';

/// Widget do wyświetlania historii zmian inwestycji
class InvestmentHistoryWidget extends StatefulWidget {
  final String investmentId;
  final String? title;
  final bool isCompact;
  final int? maxEntries;

  const InvestmentHistoryWidget({
    super.key,
    required this.investmentId,
    this.title,
    this.isCompact = false,
    this.maxEntries,
  });

  @override
  State<InvestmentHistoryWidget> createState() =>
      _InvestmentHistoryWidgetState();
}

class _InvestmentHistoryWidgetState extends State<InvestmentHistoryWidget> {
  final InvestmentChangeHistoryService _historyService =
      InvestmentChangeHistoryService();
  List<InvestmentChangeHistory> _history = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final history = await _historyService.getInvestmentHistory(
        widget.investmentId,
      );

      if (mounted) {
        setState(() {
          _history = widget.maxEntries != null
              ? history.take(widget.maxEntries!).toList()
              : history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Błąd podczas ładowania historii: $e';
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

    if (_history.isEmpty) {
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
            Text('Ładowanie historii zmian...'),
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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppThemePro.lossRed),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              if (mounted) {
                _loadHistory();
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
          Icon(Icons.history, color: AppThemePro.textMuted, size: 32),
          const SizedBox(height: 12),
          Text(
            'Brak historii zmian',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppThemePro.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Ta inwestycja nie ma jeszcze żadnych zapisanych zmian.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
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
                Icon(Icons.history, size: 20, color: AppThemePro.accentGold),
                const SizedBox(width: 8),
                Text(
                  widget.title ?? 'Historia zmian (${_history.length})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // History entries
          ...List.generate(_history.length, (index) {
            return _buildCompactHistoryEntry(
              _history[index],
              index == _history.length - 1,
            );
          }),
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
                    color: AppThemePro.accentGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.history,
                    size: 20,
                    color: AppThemePro.accentGold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title ?? 'Historia zmian inwestycji',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppThemePro.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_history.length} ${_getHistoryText(_history.length)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppThemePro.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // History entries
          ...List.generate(_history.length, (index) {
            return _buildDetailedHistoryEntry(
              _history[index],
              index == _history.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCompactHistoryEntry(InvestmentChangeHistory entry, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast
                ? Colors.transparent
                : AppThemePro.borderPrimary.withOpacity(0.3),
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
              DateFormat('dd.MM\nHH:mm').format(entry.changedAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppThemePro.textMuted,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(width: 12),

          // Change icon
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _getChangeTypeColor(entry.changeType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              _getChangeTypeIcon(entry.changeType),
              size: 14,
              color: _getChangeTypeColor(entry.changeType),
            ),
          ),

          const SizedBox(width: 12),

          // Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.changeDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Pokaż główne zmiany kwot w trybie kompaktowym
                if (entry.fieldChanges.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  ...entry.fieldChanges
                      .where((change) => _isAmountField(change.fieldName))
                      .take(2) // Pokaż maksymalnie 2 zmiany kwot w trybie kompaktowym
                      .map((change) => Text(
                            change.changeDescription,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppThemePro.accentGold,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )),
                ],
                const SizedBox(height: 2),
                Text(
                  entry.userName,
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

  Widget _buildDetailedHistoryEntry(
    InvestmentChangeHistory entry,
    bool isLast,
  ) {
    return Container(
      margin: EdgeInsets.only(left: 20, right: 20, bottom: isLast ? 20 : 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getChangeTypeColor(entry.changeType).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date, user, and change type
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getChangeTypeColor(entry.changeType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getChangeTypeIcon(entry.changeType),
                      size: 14,
                      color: _getChangeTypeColor(entry.changeType),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      InvestmentChangeType.fromValue(
                        entry.changeType,
                      ).displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getChangeTypeColor(entry.changeType),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Text(
                DateFormat('dd.MM.yyyy HH:mm').format(entry.changedAt),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Change description
          Text(
            entry.changeDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          // User info
          Row(
            children: [
              Icon(Icons.person, size: 14, color: AppThemePro.textMuted),
              const SizedBox(width: 6),
              Text(
                entry.userName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppThemePro.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${entry.userEmail})',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
              ),
            ],
          ),

          // Field changes (if any)
          if (entry.fieldChanges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppThemePro.surfaceCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Szczegóły zmian:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Pokaż zmiany kwot na początku z wyróżnieniem
                  ...entry.fieldChanges
                      .where((change) => _isAmountField(change.fieldName))
                      .map((change) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppThemePro.accentGold.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppThemePro.accentGold.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet,
                                  size: 14,
                                  color: AppThemePro.accentGold,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    change.changeDescription,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppThemePro.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                  // Pokaż pozostałe zmiany
                  ...entry.fieldChanges
                      .where((change) => !_isAmountField(change.fieldName))
                      .map((change) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${change.changeDescription}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppThemePro.textPrimary,
                              ),
                            ),
                          )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getChangeTypeColor(String changeType) {
    switch (changeType) {
      case 'field_update':
        return AppThemePro.accentGold;
      case 'bulk_update':
        return AppThemePro.profitGreen;
      case 'import':
        return AppThemePro.sharesGreen;
      case 'manual_entry':
        return AppThemePro.bondsBlue;
      case 'system_update':
        return AppThemePro.neutralGray;
      case 'correction':
        return AppThemePro.lossRed;
      default:
        return AppThemePro.textSecondary;
    }
  }

  IconData _getChangeTypeIcon(String changeType) {
    switch (changeType) {
      case 'field_update':
        return Icons.edit;
      case 'bulk_update':
        return Icons.batch_prediction;
      case 'import':
        return Icons.upload_file;
      case 'manual_entry':
        return Icons.create;
      case 'system_update':
        return Icons.system_update;
      case 'correction':
        return Icons.build_circle;
      default:
        return Icons.change_history;
    }
  }

  String _getHistoryText(int count) {
    if (count == 1) return 'wpis';
    if (count >= 2 && count <= 4) return 'wpisy';
    return 'wpisów';
  }

  /// Sprawdza czy pole jest związane z kwotą
  bool _isAmountField(String fieldName) {
    const amountFields = {
      'investmentAmount',
      'paidAmount', 
      'remainingCapital',
      'realizedCapital',
      'realizedInterest',
      'remainingInterest',
      'capitalForRestructuring',
      'capitalSecuredByRealEstate',
      'plannedTax',
      'realizedTax',
      'totalProductAmount',
      'transferToOtherProduct',
    };
    return amountFields.contains(fieldName);
  }
}