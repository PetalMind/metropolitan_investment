import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import '../../utils/download_helper.dart';

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
          maxHeight: MediaQuery.of(context).size.height * 0.9, // Zwiększ maksymalną wysokość
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
            Expanded(child: _buildContent()), // Użyj Expanded zamiast Flexible
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
        mainAxisSize: MainAxisSize.min, // Dodane dla lepszego układu
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
                  '${totalCapital.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} PLN',
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
            Wrap(
              children: [
                Text('📄 Plik: ${_result!.filename}'),
              ],
            ),
            Text('📊 Eksportowano: ${_result!.recordCount} rekordów'),
            Text('💾 Rozmiar: ${_formatFileSize(_result!.size ?? 0)}'),
            const SizedBox(height: 12),
            // Pokaż przyciski tylko dla PDF i Word (nie dla Excel)
            if (_exportFormat != 'excel') ...[
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _copyToClipboard(_result!.data),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Kopiuj'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemePro.statusSuccess,
                      foregroundColor: AppThemePro.textPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _result!.data.isNotEmpty ? 
                        _openDownloadUrl(_result!.data) : null,
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Pobierz'),
                  ),
                ],
              ),
            ] else ...[
              // Dla Excel pokaż przycisk pobierania
              ElevatedButton.icon(
                onPressed: () => _result!.data.isNotEmpty ? 
                    _openDownloadUrl(_result!.data) : null,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Pobierz plik Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemePro.statusSuccess,
                  foregroundColor: AppThemePro.textPrimary,
                ),
              ),
            ],
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

      late AdvancedExportResult advancedResult;

      if (_exportFormat == 'excel') {
        // Dla Excel używamy tylko serwisu po stronie klienta
        final result = await _exportExcelClientSide(requestedBy);
        advancedResult = AdvancedExportResult(
          success: result['success'] ?? false,
          downloadUrl: result['fileData'],
          fileName: result['filename'],
          fileSize: result['fileSize'] ?? 0,
          exportFormat: 'excel',
          errorMessage: result['success'] != true ? 'Błąd eksportu Excel' : null,
          processingTimeMs: result['executionTimeMs'] ?? 0,
          totalRecords: result['recordCount'] ?? 0,
        );
      } else {
        // Dla PDF i Word używamy zaawansowanego eksportu
        advancedResult = await emailService.exportInvestorsAdvanced(
          clientIds: widget.selectedInvestors.map((i) => i.client.id).toList(),
          exportFormat: _exportFormat,
          templateType: 'summary',
          options: {
            'includePersonalData': _includeContactInfo,
            'includeInvestmentDetails': _includeInvestmentDetails,
            'includeFinancialSummary': _includeFinancialSummary,
            'sortBy': _sortBy,
            'sortDescending': _sortOrder == 'desc',
          },
          requestedBy: requestedBy,
        );
      }

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
        // Dla Excel - pokaż tylko komunikat o sukcesie, ale NIE zamykaj dialogu
        if (_exportFormat == 'excel') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Plik Excel ${result.filename} został przygotowany',
              ),
              backgroundColor: AppThemePro.statusSuccess,
              duration: const Duration(seconds: 3),
            ),
          );
          // NIE wywołuj widget.onExportComplete() - zostaw dialog otwarty
        } else {
          // Dla PDF i Word pokaż dialog potwierdzenia pobierania
          _showDownloadConfirmationDialog(result);
        }
      }

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes == 0) return 'nieznany';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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

  /// Eksport Excel po stronie klienta
  Future<Map<String, dynamic>> _exportExcelClientSide(
    String requestedBy,
  ) async {
    try {
      final clientSideService = ClientSideExcelExportService();
      
      // Generuj nazwę pliku w formacie Excel_metropolitan_YYYY-MM-DD.xlsx
      final currentDate = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      final exportTitle = 'Excel_metropolitan_$currentDate';
      
      final result = await clientSideService.generateInvestorsExcel(
        investors: widget.selectedInvestors,
        options: {
          'includePersonalData': _includeContactInfo,
          'includeInvestmentDetails': _includeInvestmentDetails,
          'includeFinancialSummary': _includeFinancialSummary,
          'sortBy': _sortBy,
          'sortDescending': _sortOrder == 'desc',
        },
        exportTitle: exportTitle,
      );

      return result;
    } catch (e) {
      throw Exception('Błąd eksportu Excel po stronie klienta: $e');
    }
  }

  void _openDownloadUrl(String url) {
    // Dla Excel pobierz jako base64 dane z client-side
    if (_exportFormat == 'excel' && _result != null && _result!.data.isNotEmpty) {
      final contentType = _getContentTypeForFormat(_exportFormat);
      downloadBase64File(_result!.data, _result!.filename, contentType).then((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Plik Excel ${_result!.filename} został pobrany'),
              backgroundColor: AppThemePro.statusSuccess,
            ),
          );
          // Zamknij dialog po pomyślnym pobraniu Excel
          widget.onExportComplete();
        }
      }).catchError((e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Błąd pobierania Excel: $e'),
              backgroundColor: AppThemePro.statusError,
            ),
          );
        }
      });
      return;
    }

    // Sprawdź czy to base64 z zaawansowanego eksportu (PDF/Word)
    if (_result != null && 
        ['pdf', 'word'].contains(_exportFormat) && 
        _result!.data.isNotEmpty && 
        !_result!.data.startsWith('http')) {
      
      // To jest base64 data z zaawansowanego eksportu
      final contentType = _getContentTypeForFormat(_exportFormat);
      downloadBase64File(_result!.data, _result!.filename, contentType).then((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('📥 Plik został pobrany')),
          );
        }
      }).catchError((e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Błąd pobierania: $e')),
          );
        }
      });
      return;
    }

    // Jeśli to wygląda jak bezpośredni link (http/https) -> otwórz / pobierz
    final isUrl = url.startsWith('http://') || url.startsWith('https://');

    if (isUrl) {
      downloadFileFromUrl(url, filename: _result?.filename).then((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('📥 Pobieranie rozpoczęte')),
          );
        }
      }).catchError((e) {
        // Fallback: skopiuj do schowka
        _copyToClipboard(url);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Nie udało się automatycznie pobrać pliku. Link skopiowany.')),
          );
        }
      });
      return;
    }

    // Jeśli to nie jest URL, możemy traktować to jako surowe dane (CSV/JSON)
    final filename = _result?.filename ?? 'export.${_exportFormat}';
    downloadRawData(url, filename).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📥 Plik zapisany (tymczasowo) i otwarty')),
        );
      }
    }).catchError((e) {
      // Jeśli nic nie zadziałało, skopiuj zawartość
      _copyToClipboard(url);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udało się zapisać pliku; dane skopiowane do schowka')),
        );
      }
    });
  }

  String _getContentTypeForFormat(String format) {
    switch (format) {
      case 'pdf':
        return 'application/pdf';
      case 'excel':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'word':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  /// Pokazuje dialog potwierdzenia pobierania pliku
  void _showDownloadConfirmationDialog(ExportResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppThemePro.backgroundPrimary,
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppThemePro.statusSuccess,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Eksport Zakończony',
              style: TextStyle(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plik został wygenerowany pomyślnie:',
              style: TextStyle(color: AppThemePro.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppThemePro.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppThemePro.borderPrimary,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getIconForFormat(_exportFormat),
                        color: AppThemePro.accentGold,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.filename,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppThemePro.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rekordów: ${result.recordCount}',
                    style: TextStyle(color: AppThemePro.textMuted),
                  ),
                  if (result.size != null)
                    Text(
                      'Rozmiar: ${_formatFileSize(result.size!)}',
                      style: TextStyle(color: AppThemePro.textMuted),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Czy chcesz pobrać plik teraz?',
              style: TextStyle(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Zamknij dialog potwierdzenia
              // Nie zamykamy dialog eksportu - użytkownik może go zamknąć ręcznie
            },
            child: Text(
              'Później',
              style: TextStyle(color: AppThemePro.textMuted),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop(); // Zamknij dialog potwierdzenia
              _downloadGeneratedFile(result);
              // Dialog eksportu zostanie zamknięty w _downloadGeneratedFile po pomyślnym pobraniu
            },
            icon: const Icon(Icons.download, size: 20),
            label: const Text('Pobierz Teraz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemePro.statusSuccess,
              foregroundColor: AppThemePro.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForFormat(String format) {
    switch (format) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'excel':
        return Icons.table_chart;
      case 'word':
        return Icons.description;
      default:
        return Icons.file_present;
    }
  }

  /// Pobiera wygenerowany plik
  void _downloadGeneratedFile(ExportResult result) {
    try {
      // Dla Excel zawsze pobierz jako base64 z client-side
      if (_exportFormat == 'excel' && result.data.isNotEmpty) {
        final contentType = _getContentTypeForFormat(_exportFormat);
        downloadBase64File(result.data, result.filename, contentType)
            .then((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Plik ${result.filename} został pobrany'),
                    backgroundColor: AppThemePro.statusSuccess,
                  ),
                );
                // Wywołaj callback po pomyślnym pobraniu
                widget.onExportComplete();
              }
            })
            .catchError((e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Błąd pobierania Excel: $e'),
                    backgroundColor: AppThemePro.statusError,
                  ),
                );
              }
            });
      } else if (['pdf', 'word'].contains(_exportFormat) &&
          result.data.isNotEmpty) {
        // Pobierz plik binarny z base64 (PDF/Word)
        final contentType = _getContentTypeForFormat(_exportFormat);
        downloadBase64File(result.data, result.filename, contentType).then((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Plik ${result.filename} został pobrany'),
                backgroundColor: AppThemePro.statusSuccess,
              ),
            );
            // Wywołaj callback po pomyślnym pobraniu
            widget.onExportComplete();
          }
        }).catchError((e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Błąd pobierania: $e'),
                backgroundColor: AppThemePro.statusError,
              ),
            );
          }
        });
      } else {
        // Pobierz jako raw data (CSV/JSON - fallback)
        downloadRawData(result.data, result.filename).then((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Plik ${result.filename} został pobrany'),
                backgroundColor: AppThemePro.statusSuccess,
              ),
            );
            // Wywołaj callback po pomyślnym pobraniu
            widget.onExportComplete();
          }
        }).catchError((e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Błąd pobierania: $e'),
                backgroundColor: AppThemePro.statusError,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Błąd pobierania pliku: $e'),
            backgroundColor: AppThemePro.statusError,
          ),
        );
      }
    }
  }
}
