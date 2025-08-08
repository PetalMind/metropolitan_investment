import 'package:flutter/material.dart';
import '../models_and_services.dart';

/// Ulepszony dialog szczegółów inwestora z obsługą mapowania ID
/// Rozwiązuje problem z Excel ID vs Firestore ID
class ImprovedInvestorDetailsDialog extends StatefulWidget {
  final InvestorSummary investor;
  final Function(InvestorSummary)? onUpdateInvestor;

  const ImprovedInvestorDetailsDialog({
    super.key,
    required this.investor,
    this.onUpdateInvestor,
  });

  @override
  State<ImprovedInvestorDetailsDialog> createState() =>
      _ImprovedInvestorDetailsDialogState();
}

class _ImprovedInvestorDetailsDialogState
    extends State<ImprovedInvestorDetailsDialog> {
  late VotingStatus _selectedVotingStatus;
  late String _notes;
  late bool _isLoading;
  String? _errorMessage;

  final InvestorAnalyticsService _analyticsService = InvestorAnalyticsService();
  final ClientIdMappingService _idMappingService = ClientIdMappingService();

  @override
  void initState() {
    super.initState();
    _selectedVotingStatus = widget.investor.client.votingStatus;
    _notes = widget.investor.client.notes;
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildClientInfo(),
            const SizedBox(height: 16),
            _buildVotingStatusSection(),
            const SizedBox(height: 16),
            _buildNotesSection(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorMessage(),
            ],
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.person, color: Theme.of(context).primaryColor, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Szczegóły inwestora',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildClientInfo() {
    final client = widget.investor.client;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              client.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (client.email.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.email, size: 16),
                  const SizedBox(width: 8),
                  Text(client.email),
                ],
              ),
            if (client.phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16),
                  const SizedBox(width: 8),
                  Text(client.phone),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'ID systemu: ${client.id}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status głosowania',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: VotingStatus.values.map((status) {
                final isSelected = _selectedVotingStatus == status;
                return FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getVotingStatusIcon(status),
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : _getVotingStatusColor(status),
                      ),
                      const SizedBox(width: 4),
                      Text(status.displayName),
                    ],
                  ),
                  backgroundColor: _getVotingStatusColor(
                    status,
                  ).withOpacity(0.1),
                  selectedColor: _getVotingStatusColor(status),
                  checkmarkColor: Colors.white,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedVotingStatus = status;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notatki',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: _notes),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Dodaj notatki o kliencie...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _notes = value;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveChanges,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Zapisz'),
        ),
      ],
    );
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print(
        '🔄 [ImprovedModal] Rozpoczynam zapisywanie zmian dla klienta: ${widget.investor.client.id}',
      );
      print('🔄 [ImprovedModal] Nazwa klienta: ${widget.investor.client.name}');
      print(
        '🔄 [ImprovedModal] Nowy status głosowania: $_selectedVotingStatus',
      );

      // Preload mapowanie ID aby uniknąć problemów
      await _idMappingService.preloadMapping();

      // Użyj serwisu analytics z obsługą mapowania ID
      await _analyticsService.updateInvestorDetails(
        widget.investor.client.id,
        votingStatus: _selectedVotingStatus,
        notes: _notes.trim(),
        updateReason: 'Aktualizacja z poprawionego modala inwestora',
      );

      // Utwórz zaktualizowany obiekt klienta
      final updatedClient = widget.investor.client.copyWith(
        votingStatus: _selectedVotingStatus,
        notes: _notes.trim(),
        updatedAt: DateTime.now(),
      );

      // Utwórz zaktualizowany obiekt inwestora
      final updatedInvestor = InvestorSummary(
        client: updatedClient,
        investments: widget.investor.investments,
        totalRemainingCapital: widget.investor.totalRemainingCapital,
        totalSharesValue: widget.investor.totalSharesValue,
        totalValue: widget.investor.totalValue,
        totalInvestmentAmount: widget.investor.totalInvestmentAmount,
        totalRealizedCapital: widget.investor.totalRealizedCapital,
        capitalSecuredByRealEstate: widget.investor.capitalSecuredByRealEstate,
        capitalForRestructuring: widget.investor.capitalForRestructuring,
        investmentCount: widget.investor.investmentCount,
      );

      // Wywołaj callback z zaktualizowanymi danymi
      widget.onUpdateInvestor?.call(updatedInvestor);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Zaktualizowano dane dla ${widget.investor.client.name}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ [ImprovedModal] Błąd zapisu: $e');

      String errorMessage = 'Błąd podczas zapisywania zmian';

      if (e.toString().contains('Cannot find Firestore ID')) {
        errorMessage =
            'Problem z mapowaniem ID klienta. Dane mogą być niespójne.';
      } else if (e.toString().contains('does not exist')) {
        errorMessage =
            'Klient nie istnieje w bazie danych. Może został usunięty.';
      }

      setState(() {
        _errorMessage = errorMessage;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        return Icons.help_outline;
    }
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return Colors.green;
      case VotingStatus.no:
        return Colors.red;
      case VotingStatus.abstain:
        return Colors.orange;
      case VotingStatus.undecided:
        return Colors.grey;
    }
  }
}
