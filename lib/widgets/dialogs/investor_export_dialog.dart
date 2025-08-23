import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';

/// Widget do eksportu danych inwestorów
/// 
/// Pozwala na wybór formatu eksportu (Excel, PDF, Word), 
/// filtrowanie i sortowanie danych przed eksportem.
class InvestorExportDialog extends StatefulWidget {
  final List<InvestorSummary> selectedInvestors;
  final VoidCallback onExportComplete;

  const InvestorExportDialog({
    super.key,
    required this.selectedInvestors,
    required this.onExportComplete,
  });

  @override
  State<InvestorExportDialog> createState() => _InvestorExportDialogState();
}

class _InvestorExportDialogState extends State<InvestorExportDialog> {
  String _exportFormat = 'excel';
  String _sortBy = 'name';
  String _sortOrder = 'asc';
  double _minInvestmentAmount = 0;
  bool _includeContactInfo = true;
  bool _includeInvestmentDetails = true;
  bool _includeFinancialSummary = true;
  
  bool _isLoading = false;
  String? _error;
  ExportResult? _result;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: AppThemePro.backgroundPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(child: _buildContent()),
            if (_result != null) _buildResult(),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.primaryMedium,
            AppThemePro.primaryMedium.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.file_download_outlined,
            color: AppThemePro.textPrimary,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Eksport Danych Inwestorów',
                  style: TextStyle(
                    color: AppThemePro.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Eksportuj ${widget.selectedInvestors.length} inwestorów',
                  style: const TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: AppThemePro.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statystyki wybranych inwestorów
          _buildStatisticsCard(),
          
          const SizedBox(height: 24),
          
          // Ustawienia eksportu
          _buildExportSettings(),
          
          const SizedBox(height: 24),
          
          // Filtrowanie i sortowanie
          _buildFilteringAndSorting(),
          
          const SizedBox(height: 24),
          
          // Zawartość eksportu
          _buildContentOptions(),
          
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppThemePro.statusError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppThemePro.statusError.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppThemePro.statusError),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppThemePro.statusError),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final totalCapital = widget.selectedInvestors
        .fold<double>(0, (sum, investor) => sum + investor.totalRemainingCapital);
    final totalInvestments = widget.selectedInvestors
        .fold<int>(0, (sum, investor) => sum + investor.investmentCount);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemePro.accentGold.withValues(alpha: 0.1),
            AppThemePro.accentGold.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemePro.accentGold.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Podsumowanie Eksportu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Inwestorzy',
                  widget.selectedInvestors.length.toString(),
                  Icons.people_outline,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Inwestycje',
                  totalInvestments.toString(),
                  Icons.account_balance_wallet_outlined,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Łączny Kapitał',
                  '${totalCapital.toStringAsFixed(0)} PLN',
                  Icons.monetization_on_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppThemePro.accentGold, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppThemePro.accentGold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppThemePro.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildExportSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Format Eksportu',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFormatOption(
                'excel',
                'Excel',
                'Microsoft Excel',
                Icons.table_chart_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormatOption(
                'pdf',
                'PDF',
                'Dokument PDF',
                Icons.picture_as_pdf_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormatOption(
                'word',
                'Word',
                'Microsoft Word',
                Icons.description_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormatOption(String value, String title, String subtitle, IconData icon) {
    final isSelected = _exportFormat == value;
    
    return GestureDetector(
      onTap: () => setState(() => _exportFormat = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppThemePro.primaryMedium.withValues(alpha: 0.3)
              : AppThemePro.backgroundSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppThemePro.accentGold
                : AppThemePro.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppThemePro.accentGold
                  : AppThemePro.textMuted,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppThemePro.textPrimary
                    : AppThemePro.textSecondary,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppThemePro.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteringAndSorting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filtrowanie i Sortowanie',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Sortowanie
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: const InputDecoration(
                  labelText: 'Sortuj według',
                  prefixIcon: Icon(Icons.sort_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Nazwy')),
                  DropdownMenuItem(value: 'totalCapital', child: Text('Kapitału')),
                  DropdownMenuItem(value: 'investmentCount', child: Text('Liczby inwestycji')),
                  DropdownMenuItem(value: 'signedDate', child: Text('Daty podpisania')),
                ],
                onChanged: (value) => setState(() => _sortBy = value!),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _sortOrder,
                decoration: const InputDecoration(
                  labelText: 'Kolejność',
                  prefixIcon: Icon(Icons.import_export_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'asc', child: Text('Rosnąco')),
                  DropdownMenuItem(value: 'desc', child: Text('Malejąco')),
                ],
                onChanged: (value) => setState(() => _sortOrder = value!),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Filtr minimalnej kwoty
        TextFormField(
          initialValue: _minInvestmentAmount.toString(),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Minimalna kwota inwestycji (PLN)',
            hintText: '0',
            prefixIcon: Icon(Icons.filter_alt_outlined),
          ),
          onChanged: (value) {
            setState(() {
              _minInvestmentAmount = double.tryParse(value) ?? 0;
            });
          },
        ),
      ],
    );
  }

  Widget _buildContentOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Zawartość Eksportu',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        CheckboxListTile(
          value: _includeContactInfo,
          onChanged: (value) => setState(() => _includeContactInfo = value!),
          title: const Text('Dane kontaktowe'),
          subtitle: const Text('Email, telefon, adres'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        
        CheckboxListTile(
          value: _includeInvestmentDetails,
          onChanged: (value) => setState(() => _includeInvestmentDetails = value!),
          title: const Text('Szczegóły inwestycji'),
          subtitle: const Text('Lista wszystkich inwestycji klienta'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        
        CheckboxListTile(
          value: _includeFinancialSummary,
          onChanged: (value) => setState(() => _includeFinancialSummary = value!),
          title: const Text('Podsumowanie finansowe'),
          subtitle: const Text('Sumy, średnie, statystyki'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildResult() {
    if (_result == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _result!.success
            ? AppThemePro.statusSuccess.withValues(alpha: 0.1)
            : AppThemePro.statusError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _result!.success
              ? AppThemePro.statusSuccess.withValues(alpha: 0.3)
              : AppThemePro.statusError.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _result!.success ? Icons.check_circle_outline : Icons.error_outline,
                color: _result!.success
                    ? AppThemePro.statusSuccess
                    : AppThemePro.statusError,
              ),
              const SizedBox(width: 8),
              Text(
                _result!.success ? 'Eksport zakończony pomyślnie' : 'Błąd eksportu',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _result!.success
                      ? AppThemePro.statusSuccess
                      : AppThemePro.statusError,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_result!.success) ...[
            Text('📄 Plik: ${_result!.filename}'),
            Text('📊 Eksportowano: ${_result!.recordCount} rekordów'),
            Text('💾 Rozmiar: ${_result!.size ?? 'nieznany'} bajtów'),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(_result!.data),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Kopiuj Dane'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemePro.statusSuccess,
                    foregroundColor: AppThemePro.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _result!.data.isNotEmpty ? 
                      _openDownloadUrl(_result!.data) : null,
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Pobierz'),
                ),
              ],
            ),
          ] else ...[
            Text(
              _result!.totalErrors > 0 ? 'Błędów: ${_result!.totalErrors}' : 'Nieznany błąd',
              style: const TextStyle(color: AppThemePro.statusError),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _exportData,
            icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download),
            label: Text(_isLoading ? 'Eksportuję...' : 'Eksportuj'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      // Używaj EmailAndExportService dla wszystkich formatów
      final emailService = EmailAndExportService();

      // Sprawdź dostępność użytkownika - używamy kontekstu Provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final requestedBy = authProvider.user?.uid ?? 'anonymous@metropolitan.pl';

      AdvancedExportResult advancedResult;

      // Dla formatów PDF i Word używamy zaawansowanego eksportu
      if (['pdf', 'word'].contains(_exportFormat)) {
        advancedResult = await emailService.exportInvestorsAdvanced(
          clientIds: widget.selectedInvestors.map((i) => i.client.id).toList(),
          exportFormat: _exportFormat,
          templateType: 'summary',
          options: {
            'includePersonalData': _includeContactInfo,
            'includeInvestmentDetails': _includeInvestmentDetails,
            'includeFinancialSummary': _includeFinancialSummary,
          },
          requestedBy: requestedBy,
        );

        // Konwertuj AdvancedExportResult do ExportResult
        final result = ExportResult(
          success: advancedResult.isSuccessful,
          format: _exportFormat,
          recordCount: widget.selectedInvestors.length,
          totalProcessed: widget.selectedInvestors.length,
          totalErrors: advancedResult.isSuccessful ? 0 : 1,
          executionTimeMs: advancedResult.processingTimeMs,
          exportTitle: 'Eksport inwestorów',
          data: advancedResult.downloadUrl ?? '',
          filename: advancedResult.fileName ?? 'export.$_exportFormat',
          size: advancedResult.fileSize,
        );

        setState(() {
          _result = result;
          _isLoading = false;
        });

        if (result.success && context.mounted) {
          // Pokaż snackbar z opcją pobierania pliku
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Eksport zakończony: ${result.recordCount} rekordów',
              ),
              backgroundColor: AppThemePro.statusSuccess,
              action: advancedResult.downloadUrl != null
                  ? SnackBarAction(
                      label: 'Pobierz',
                      textColor: AppThemePro.textPrimary,
                      onPressed: () =>
                          _copyToClipboard(advancedResult.downloadUrl!),
                    )
                  : null,
            ),
          );
        }
      } else {
        // Dla Excel używamy standardowego eksportu
        final result = await emailService.exportInvestorsData(
          clientIds: widget.selectedInvestors.map((i) => i.client.id).toList(),
          exportFormat: _exportFormat,
          sortBy: _sortBy,
          sortDescending: _sortOrder == 'desc',
          requestedBy: requestedBy,
          includePersonalData: _includeContactInfo,
        );

        setState(() {
          _result = result;
          _isLoading = false;
        });

        if (result.success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Eksport zakończony: ${result.recordCount} rekordów',
              ),
              backgroundColor: AppThemePro.statusSuccess,
            ),
          );
        }
      }

      if (context.mounted) {
        widget.onExportComplete();
      }

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Link skopiowany do schowka'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _openDownloadUrl(String url) {
    // W prawdziwej aplikacji otworzyłbyś URL w przeglądarce
    // Na razie po prostu kopiujemy do schowka
    _copyToClipboard(url);
  }
}
