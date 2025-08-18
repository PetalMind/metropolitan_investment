import 'package:flutter/material.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import '../investment_history_widget.dart';

/// Dialog do edycji całkowitego kapitału pozostałego produktu
/// 
/// Funkcjonalności:
/// - Edycja kwoty całkowitego kapitału pozostałego
/// - Historia zmian kapitału
/// - Proporcjonalne skalowanie wszystkich inwestorów
/// - Walidacja i potwierdzenie zmian
class TotalCapitalEditDialog extends StatefulWidget {
  final UnifiedProduct product;
  final double currentTotalCapital;
  final List<Investment> investments;
  final VoidCallback? onChanged;

  const TotalCapitalEditDialog({
    super.key,
    required this.product,
    required this.currentTotalCapital,
    required this.investments,
    this.onChanged,
  });

  @override
  State<TotalCapitalEditDialog> createState() => _TotalCapitalEditDialogState();
}

class _TotalCapitalEditDialogState extends State<TotalCapitalEditDialog> {
  late TextEditingController _capitalController;
  bool _isLoading = false;
  bool _hasChanges = false;
  double _newCapital = 0.0;
  double _scalingFactor = 1.0;
  double _totalInvestmentAmount = 0.0; // Suma inwestycji (nie zmienia się)
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _capitalController = TextEditingController(
      text: widget.currentTotalCapital.toStringAsFixed(2),
    );
    _newCapital = widget.currentTotalCapital;
    
    // Oblicz całkowitą sumę inwestycji (pierwotnych kwot)
    _totalInvestmentAmount = widget.investments.fold(
      0.0,
      (sum, investment) => sum + investment.investmentAmount,
    );
    
    debugPrint('📊 [TotalCapitalEditDialog] Inicjalizacja:');
    debugPrint('   - Kapitał pozostały: ${widget.currentTotalCapital}');
    debugPrint('   - Suma inwestycji: $_totalInvestmentAmount');
    
    // Dodaj listener do kontrolera
    _capitalController.addListener(_onCapitalChanged);
  }

  @override
  void dispose() {
    _capitalController.removeListener(_onCapitalChanged);
    _capitalController.dispose();
    super.dispose();
  }

  void _onCapitalChanged() {
    // Wyczyść tekst z formatowania i sparsuj
    final text = _capitalController.text
        .replaceAll(' ', '')
        .replaceAll(',', '.')
        .replaceAll('PLN', '')
        .trim();
    
    debugPrint('🔍 [TotalCapitalEditDialog] Parsing text: "$text"');
    
    final newValue = double.tryParse(text);
    
    if (newValue != null && newValue >= 0) {
      debugPrint('✅ [TotalCapitalEditDialog] Parsed value: $newValue');
      
      // 🚫 WALIDACJA: Kapitał pozostały nie może być większy niż suma inwestycji
      String? validationError;
      if (newValue > _totalInvestmentAmount) {
        validationError = 'Kapitał pozostały (${CurrencyFormatter.formatCurrency(newValue)}) nie może być większy niż suma inwestycji (${CurrencyFormatter.formatCurrency(_totalInvestmentAmount)})';
      }
      
      setState(() {
        _newCapital = newValue;
        _validationError = validationError;
        _hasChanges = (newValue - widget.currentTotalCapital).abs() > 0.01 && validationError == null;
        _scalingFactor = widget.currentTotalCapital != 0 
            ? newValue / widget.currentTotalCapital 
            : 1.0;
            
        debugPrint('📊 [TotalCapitalEditDialog] State updated:');
        debugPrint('   - New capital: $_newCapital');
        debugPrint('   - Validation error: $_validationError');
        debugPrint('   - Has changes: $_hasChanges');
        debugPrint('   - Scaling factor: $_scalingFactor');
      });
    } else {
      debugPrint('❌ [TotalCapitalEditDialog] Failed to parse: "$text"');
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges || _validationError != null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // ⭐ NOWA LOGIKA: Używamy scaleRemainingCapitalOnly (bez zmiany investmentAmount)
      final editService = InvestorEditService();
      
      // Użyj funkcji skalowania TYLKO kapitału pozostałego z InvestorEditService
      final scalingResult = await editService.scaleRemainingCapitalOnly(
        product: widget.product,
        newTotalRemainingCapital: _newCapital,
        originalTotalRemainingCapital: widget.currentTotalCapital,
        reason: 'Skalowanie kapitału pozostałego (bez zmiany sumy inwestycji): ${CurrencyFormatter.formatCurrency(widget.currentTotalCapital)} → ${CurrencyFormatter.formatCurrency(_newCapital)}',
      );

      if (!scalingResult.success) {
        throw Exception(scalingResult.message);
      }

      // Wyczyść cache przed wywołaniem callback
      final modalService = UnifiedProductModalService();
      await modalService.clearProductCache(widget.product.id);
      
      debugPrint('🔄 [TotalCapitalEditDialog] Kapitał pozostały został przeskalowany (investmentAmount NIEZMIENIONY)');

      if (widget.onChanged != null) {
        widget.onChanged!();
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kapitał pozostały został zaktualizowany (${scalingResult.affectedInvestments} inwestycji). Suma inwestycji pozostała niezmieniona.'),
            backgroundColor: AppThemePro.statusSuccess,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [TotalCapitalEditDialog] Error saving changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas zapisywania: $e'),
            backgroundColor: AppThemePro.statusError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: AppThemePro.backgroundSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppThemePro.borderPrimary,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    // Tab bar
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppThemePro.borderPrimary,
                            width: 1,
                          ),
                        ),
                      ),
                      child: TabBar(
                        labelColor: AppThemePro.accentGold,
                        unselectedLabelColor: AppThemePro.textSecondary,
                        indicatorColor: AppThemePro.accentGold,
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.edit, size: 20),
                            text: 'Edycja kapitału',
                          ),
                          Tab(
                            icon: Icon(Icons.history, size: 20),
                            text: 'Historia zmian',
                          ),
                        ],
                      ),
                    ),
                    
                    // Tab content
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildEditTab(),
                          _buildHistoryTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer
            _buildFooter(),
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
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [
            AppThemePro.accentGold.withValues(alpha: 0.1),
            AppThemePro.backgroundSecondary,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppThemePro.accentGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_wallet,
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
                  'Edycja kapitału pozostałego',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.product.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemePro.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: AppThemePro.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current vs New Value
          _buildCurrentVsNewSection(),
          
          const SizedBox(height: 24),
          
          // Edit Field
          _buildEditField(),
          
          const SizedBox(height: 24),
          
          // Scaling Preview
          if (_hasChanges && _validationError == null) _buildScalingPreview(),
          
          const SizedBox(height: 24),
          
          // Warning
          _buildWarningSection(),
        ],
      ),
    );
  }

  Widget _buildCurrentVsNewSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemePro.borderSecondary,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Kapitał pozostały - główne porównanie
          Row(
            children: [
              Expanded(
                child: _buildValueCard(
                  'Obecny kapitał pozostały',
                  widget.currentTotalCapital,
                  Icons.account_balance,
                  AppThemePro.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.arrow_forward,
                color: AppThemePro.accentGold,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildValueCard(
                  'Nowy kapitał pozostały',
                  _newCapital,
                  Icons.account_balance_wallet,
                  _hasChanges && _validationError == null ? AppThemePro.accentGold : 
                  _validationError != null ? AppThemePro.statusError : AppThemePro.textSecondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Suma inwestycji - pozostaje niezmieniona
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemePro.statusInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppThemePro.statusInfo.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock,
                  color: AppThemePro.statusInfo,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suma inwestycji (NIEZMIENIONA)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppThemePro.statusInfo,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatCurrency(_totalInvestmentAmount),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppThemePro.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard(String title, double value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.formatCurrency(value),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildEditField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nowa kwota kapitału pozostałego',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _capitalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppThemePro.backgroundSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _validationError != null ? AppThemePro.statusError : AppThemePro.borderPrimary,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _validationError != null ? AppThemePro.statusError : AppThemePro.accentGold, 
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppThemePro.statusError, width: 2),
            ),
            prefixIcon: Icon(
              Icons.edit,
              color: _validationError != null ? AppThemePro.statusError : AppThemePro.accentGold,
            ),
            suffixText: 'PLN',
            suffixStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppThemePro.textSecondary,
            ),
            hintText: 'Wprowadź nową kwotę...',
            errorText: _validationError,
            errorMaxLines: 3,
          ),
        ),
        
        // 📊 INFORMACJA O SUMIE INWESTYCJI
        if (_totalInvestmentAmount > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppThemePro.backgroundTertiary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppThemePro.borderSecondary,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppThemePro.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Maksymalna kwota kapitału pozostałego: ${CurrencyFormatter.formatCurrency(_totalInvestmentAmount)} (suma inwestycji)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScalingPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.accentGold.withValues(alpha: 0.05),
            AppThemePro.accentGold.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemePro.accentGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.transform,
                color: AppThemePro.accentGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Podgląd skalowania kapitału pozostałego',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppThemePro.accentGold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Współczynnik skalowania: ${(_scalingFactor * 100).toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tylko kapitał pozostały zostanie przeskalowany proporcjonalnie',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppThemePro.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.investments.length} inwestycji zostanie zaktualizowanych',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppThemePro.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          
          // 🚫 WAŻNA INFORMACJA: Suma inwestycji pozostaje niezmieniona
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppThemePro.statusInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppThemePro.statusInfo.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock,
                  color: AppThemePro.statusInfo,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ Suma inwestycji pozostanie NIEZMIENIONA (${CurrencyFormatter.formatCurrency(_totalInvestmentAmount)})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.statusInfo,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.statusWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemePro.statusWarning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: AppThemePro.statusWarning,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Uwaga: Zmiana kapitału pozostałego wpłynie proporcjonalnie na kapitał pozostały wszystkich inwestycji w tym produkcie. Suma inwestycji (pierwotne kwoty) pozostanie niezmieniona. Operacja jest nieodwracalna.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppThemePro.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: InvestmentHistoryWidget(
        investmentId: widget.product.id,
        maxEntries: 20,
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppThemePro.borderPrimary,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppThemePro.borderPrimary),
              ),
              child: Text(
                'Anuluj',
                style: TextStyle(color: AppThemePro.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _hasChanges && !_isLoading && _validationError == null ? _saveChanges : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _validationError != null ? AppThemePro.statusError : AppThemePro.accentGold,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _validationError != null ? 'Błąd walidacji' : 'Zapisz zmiany',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}