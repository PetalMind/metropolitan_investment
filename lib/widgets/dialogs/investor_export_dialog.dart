import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';

/// Widget do eksportu danych inwestorów
/// 
/// Pozwala na wybór formatu eksportu (CSV, JSON, Excel), 
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
  String _exportFormat = 'csv';
  String _sortBy = 'name';
  String _sortOrder = 'asc';
  double _minInvestmentAmount = 0;
  bool _includeContactInfo = true;
  bool _includeInvestmentDetails = true;
  bool _includeFinancialSummary = true;
  
  bool _isLoading = false;
  String? _error;
  ExportResult? _result;

  final _emailAndExportService = EmailAndExportService();

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
            AppTheme.primaryAccent,
            AppTheme.primaryAccent.withOpacity(0.8),
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
            color: Colors.white,
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
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Eksportuj ${widget.selectedInvestors.length} inwestorów',
                  style: const TextStyle(
                    color: Colors.white70,
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
              color: Colors.white,
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
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red[700]),
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
            AppTheme.secondaryGold.withOpacity(0.1),
            AppTheme.secondaryGold.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondaryGold.withOpacity(0.3)),
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
        Icon(icon, color: AppTheme.secondaryGold, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryGold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
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
                'csv',
                'CSV',
                'Arkusz kalkulacyjny',
                Icons.table_chart_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormatOption(
                'json',
                'JSON',
                'Dane strukturalne',
                Icons.code_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormatOption(
                'excel',
                'Excel',
                'Microsoft Excel',
                Icons.description_outlined,
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
          color: isSelected ? AppTheme.primaryAccent.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryAccent : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryAccent : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryAccent : Colors.grey[800],
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
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
        color: _result!.success ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _result!.success ? Colors.green[300]! : Colors.red[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _result!.success ? Icons.check_circle_outline : Icons.error_outline,
                color: _result!.success ? Colors.green[700] : Colors.red[700],
              ),
              const SizedBox(width: 8),
              Text(
                _result!.success ? 'Eksport zakończony pomyślnie' : 'Błąd eksportu',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _result!.success ? Colors.green[700] : Colors.red[700],
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
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
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
              style: TextStyle(color: Colors.red[700]),
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
        color: Colors.grey[50],
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
      final result = await _emailAndExportService.exportInvestorsData(
        clientIds: widget.selectedInvestors.map((i) => i.client.id).toList(),
        exportFormat: _exportFormat,
        sortBy: _sortBy,
        sortDescending: _sortOrder == 'desc',
        requestedBy: 'system@metropolitan.pl', // Tymczasowo
        includePersonalData: _includeContactInfo,
      );

      setState(() {
        _result = result;
        _isLoading = false;
      });

      if (result.success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Eksport zakończony: ${result.recordCount} rekordów'),
            backgroundColor: Colors.green[700],
          ),
        );
        
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
