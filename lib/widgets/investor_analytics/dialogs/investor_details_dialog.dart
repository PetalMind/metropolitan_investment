import 'package:flutter/material.dart';
import '../../../models_and_services.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/currency_formatter.dart';

/// Dialog szczegółów inwestora z możliwością edycji
class InvestorDetailsDialog extends StatefulWidget {
  final InvestorSummary investor;
  final InvestorAnalyticsService analyticsService;
  final VoidCallback onUpdate;

  const InvestorDetailsDialog({
    super.key,
    required this.investor,
    required this.analyticsService,
    required this.onUpdate,
  });

  @override
  State<InvestorDetailsDialog> createState() => _InvestorDetailsDialogState();
}

class _InvestorDetailsDialogState extends State<InvestorDetailsDialog> {
  late TextEditingController _notesController;
  late VotingStatus _selectedVotingStatus;
  String _selectedColor = '#FFFFFF';
  List<String> _selectedUnviableInvestments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.investor.client.notes,
    );
    _selectedVotingStatus = widget.investor.client.votingStatus;
    _selectedColor = widget.investor.client.colorCode;
    _selectedUnviableInvestments = List.from(
      widget.investor.client.unviableInvestments,
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      await widget.analyticsService.updateInvestorNotes(
        widget.investor.client.id,
        _notesController.text,
      );

      await widget.analyticsService.updateVotingStatus(
        widget.investor.client.id,
        _selectedVotingStatus,
      );

      await widget.analyticsService.updateInvestorColor(
        widget.investor.client.id,
        _selectedColor,
      );

      await widget.analyticsService.markInvestmentsAsUnviable(
        widget.investor.client.id,
        _selectedUnviableInvestments,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onUpdate();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Zmiany zostały zapisane'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas zapisywania: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.secondaryGold.withOpacity(0.1),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: AppTheme.secondaryGold,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.investor.client.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.investor.client.companyName?.isNotEmpty ??
                            false) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.investor.client.companyName!,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.textSecondary,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.backgroundSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Podsumowanie inwestycji
                    _buildSummaryCard(),
                    const SizedBox(height: 24),

                    // Edycja danych
                    _buildEditSection(),
                    const SizedBox(height: 24),

                    // Lista inwestycji
                    _buildInvestmentsSection(),
                  ],
                ),
              ),
            ),

            // Footer z przyciskami
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppTheme.borderSecondary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Anuluj'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveChanges,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? 'Zapisywanie...' : 'Zapisz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryGold,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.backgroundSecondary, AppTheme.surfaceElevated],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderSecondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Podsumowanie inwestycji',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Łączna wartość',
                  CurrencyFormatter.formatCurrency(
                    widget.investor.totalValue,
                    showDecimals: false,
                  ),
                  Icons.account_balance_wallet,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Liczba inwestycji',
                  '${widget.investor.investmentCount}',
                  Icons.pie_chart,
                  AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Kapitał pozostały',
                  CurrencyFormatter.formatCurrency(
                    widget.investor.totalRemainingCapital,
                    showDecimals: false,
                  ),
                  Icons.monetization_on,
                  AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Wartość udziałów',
                  CurrencyFormatter.formatCurrency(
                    widget.investor.totalSharesValue,
                    showDecimals: false,
                  ),
                  Icons.trending_up,
                  AppTheme.infoColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edycja danych',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Status głosowania
        DropdownButtonFormField<VotingStatus>(
          value: _selectedVotingStatus,
          style: const TextStyle(color: AppTheme.textPrimary),
          dropdownColor: AppTheme.surfaceCard,
          decoration: InputDecoration(
            labelText: 'Status głosowania',
            labelStyle: const TextStyle(color: AppTheme.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderSecondary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderSecondary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.secondaryGold, width: 2),
            ),
          ),
          items: VotingStatus.values
              .map(
                (status) => DropdownMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Icon(
                        _getVotingStatusIcon(status),
                        color: _getVotingStatusColor(status),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status.displayName,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedVotingStatus = value);
            }
          },
        ),

        const SizedBox(height: 16),

        // Notatki
        TextField(
          controller: _notesController,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Notatki',
            labelStyle: const TextStyle(color: AppTheme.textSecondary),
            hintText: 'Dodaj notatki o kliencie...',
            hintStyle: const TextStyle(color: AppTheme.textTertiary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderSecondary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderSecondary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.secondaryGold, width: 2),
            ),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildInvestmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.business_center,
              color: AppTheme.secondaryGold,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Inwestycje (${widget.investor.investments.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.borderSecondary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: widget.investor.investments.isEmpty
              ? const Center(
                  child: Text(
                    'Brak inwestycji',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: widget.investor.investments.length,
                  itemBuilder: (context, index) {
                    final investment = widget.investor.investments[index];
                    final isUnviable = _selectedUnviableInvestments.contains(
                      investment.id,
                    );

                    return Card(
                      color: AppTheme.surfaceCard,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: CheckboxListTile(
                        title: Text(
                          investment.productName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${CurrencyFormatter.formatCurrency(investment.remainingCapital, showDecimals: false)} - ${investment.creditorCompany}',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        value: isUnviable,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedUnviableInvestments.add(investment.id);
                            } else {
                              _selectedUnviableInvestments.remove(
                                investment.id,
                              );
                            }
                          });
                        },
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                (isUnviable
                                        ? AppTheme.warningColor
                                        : AppTheme.successColor)
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isUnviable ? Icons.warning : Icons.check_circle,
                            color: isUnviable
                                ? AppTheme.warningColor
                                : AppTheme.successColor,
                            size: 20,
                          ),
                        ),
                        activeColor: AppTheme.warningColor,
                        checkColor: Colors.white,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  IconData _getVotingStatusIcon(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return Icons.check_circle;
      case VotingStatus.no:
        return Icons.cancel;
      case VotingStatus.abstain:
        return Icons.remove_circle;
      case VotingStatus.undecided:
        return Icons.help;
    }
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return AppTheme.successColor;
      case VotingStatus.no:
        return AppTheme.errorColor;
      case VotingStatus.abstain:
        return AppTheme.warningColor;
      case VotingStatus.undecided:
        return AppTheme.textSecondary;
    }
  }
}
