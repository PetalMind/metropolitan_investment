import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';
import 'client_overview_tab.dart'; // For ClientFormData

/// 🎨 SEKCJA INWESTYCJE - Tab 3
///
/// Zawiera:
/// - Lista wszystkich inwestycji klienta
/// - Interaktywne karty z szczegółami
/// - Podsumowanie portfela
/// - Quick stats per investment
/// - Hero animations i smooth scrolling
/// - Investment performance indicators
class ClientInvestmentsTab extends StatefulWidget {
  final Client? client;
  final ClientFormData formData;
  final Map<String, dynamic>? additionalData;

  const ClientInvestmentsTab({
    super.key,
    this.client,
    required this.formData,
    this.additionalData,
  });

  @override
  State<ClientInvestmentsTab> createState() => _ClientInvestmentsTabState();
}

class _ClientInvestmentsTabState extends State<ClientInvestmentsTab>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  // 🚀 UŻYWAJ ISTNIEJĄCYCH SERWISÓW Z models_and_services.dart
  final InvestorAnalyticsService _investorAnalyticsService =
      InvestorAnalyticsService();

  // Formatowanie kwot z separatorem tysięcy
  String formatAmount(num amount) {
    // Użyj NumberFormat z pakietu intl
    return amount == null
        ? '0'
        : NumberFormat('#,##0', 'pl_PL').format(amount).replaceAll(',', ' ');
  }

  // State
  List<Investment> _investments = [];
  InvestorSummary? _investorSummary;
  bool _isLoading = true;
  String? _errorMessage;

  // Animation
  late AnimationController _loadingController;
  late AnimationController _cardController;

  // Filters
  String _selectedProductType = 'Wszystkie';
  bool _showActiveOnly = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInvestmentData();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _loadingController.repeat();
  }

  Future<void> _loadInvestmentData() async {
    if (widget.client == null) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Brak danych klienta - zapisz najpierw podstawowe informacje';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print(
        '💼 [Investments] Ładowanie inwestycji dla klienta: ${widget.client!.name}',
      );

      // 🚀 KROK 1: Sprawdź czy mamy dane w additionalData (przekazane z enhanced_clients_screen)
      if (widget.additionalData != null) {
        final investorSummaries =
            widget.additionalData!['investorSummaries']
                as Map<String, InvestorSummary>?;
        final clientInvestments =
            widget.additionalData!['clientInvestments']
                as Map<String, List<Investment>>?;

        if (investorSummaries != null &&
            investorSummaries.containsKey(widget.client!.id)) {
          _investorSummary = investorSummaries[widget.client!.id];
          _investments = clientInvestments?[widget.client!.id] ?? [];

          print(
            '✅ [Investments] Używam danych z cache - ${_investments.length} inwestycji',
          );

          setState(() {
            _isLoading = false;
          });

          _cardController.forward();
          return;
        }
      }

      // 🚀 KROK 2: Fallback - pobierz dane bezpośrednio z InvestorAnalyticsService
      print('📡 [Investments] Pobieranie danych z InvestorAnalyticsService...');

      final allInvestors = await _investorAnalyticsService
          .getAllInvestorsForAnalysis(includeInactive: true);

      // Znajdź inwestora dla tego klienta
      _investorSummary = allInvestors.firstWhere(
        (investor) => investor.client.id == widget.client!.id,
        orElse: () => InvestorSummary.fromInvestments(widget.client!, []),
      );

      _investments = _investorSummary?.investments ?? [];

      print(
        '✅ [Investments] Pobrano ${_investments.length} inwestycji z serwisu',
      );

      setState(() {
        _isLoading = false;
      });

      _cardController.forward();
    } catch (e) {
      print('❌ [Investments] Błąd ładowania danych: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Błąd podczas ładowania inwestycji: $e';
      });
    }
  }

  List<Investment> get _filteredInvestments {
    var filtered = _investments;

    // Filter by product type
    if (_selectedProductType != 'Wszystkie') {
      filtered = filtered
          .where((inv) => inv.productType.displayName == _selectedProductType)
          .toList();
    }

    // Filter by active status
    if (_showActiveOnly) {
      filtered = filtered.where((inv) => inv.remainingCapital > 0).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (widget.client == null) {
      return _buildNoClientState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portfolio summary
          if (_investorSummary != null) ...[
            _buildPortfolioSummary(),
            const SizedBox(height: 24),
          ],

          // Filters and controls
          _buildFiltersSection(),
          const SizedBox(height: 24),

          // Investments list
          _buildInvestmentsList(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loadingController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _loadingController.value * 2 * 3.14159,
                child: Icon(
                  Icons.trending_up_rounded,
                  size: 48,
                  color: AppThemePro.accentGold,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Ładowanie inwestycji...',
            style: TextStyle(fontSize: 16, color: AppThemePro.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppThemePro.statusError,
          ),
          const SizedBox(height: 16),
          Text(
            'Błąd ładowania',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppThemePro.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Nieznany błąd',
            style: const TextStyle(
              fontSize: 14,
              color: AppThemePro.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadInvestmentData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Spróbuj ponownie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemePro.accentGold,
              foregroundColor: AppThemePro.backgroundPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoClientState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_rounded,
            size: 64,
            color: AppThemePro.textTertiary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Zapisz klienta najpierw',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppThemePro.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aby wyświetlić inwestycje, najpierw zapisz podstawowe dane klienta',
            style: TextStyle(fontSize: 14, color: AppThemePro.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSummary() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: AppThemePro.elevatedSurfaceDecoration.copyWith(
                gradient: LinearGradient(
                  colors: [
                    AppThemePro.accentGold.withOpacity(0.1),
                    AppThemePro.surfaceCard,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppThemePro.accentGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppThemePro.accentGold,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Portfel inwestycyjny',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppThemePro.textPrimary,
                              ),
                            ),
                            Text(
                              widget.client!.name,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppThemePro.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Portfolio metrics
                  if (_investorSummary != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Łączna kwota',
                            '${_investorSummary!.totalInvestmentAmount.toStringAsFixed(0)} zł',
                            Icons.trending_up_rounded,
                            AppThemePro.statusInfo,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'Pozostały kapitał',
                            '${_investorSummary!.totalRemainingCapital.toStringAsFixed(0)} zł',
                            Icons.account_balance_rounded,
                            AppThemePro.statusSuccess,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Liczba inwestycji',
                            '${_investorSummary!.investmentCount}',
                            Icons.format_list_numbered_rounded,
                            AppThemePro.accentGold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            'ROI',
                            _calculateROI(),
                            Icons.percent_rounded,
                            _getROIColor(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppThemePro.elevatedSurfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtry',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppThemePro.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Product type filter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Typ produktu',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppThemePro.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _selectedProductType,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items:
                          [
                                'Wszystkie',
                                'Obligacje',
                                'Pożyczki',
                                'Udziały',
                                'Apartamenty',
                              ]
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProductType = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Active only filter
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tylko aktywne',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppThemePro.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Switch.adaptive(
                    value: _showActiveOnly,
                    onChanged: (value) {
                      setState(() {
                        _showActiveOnly = value;
                      });
                      HapticFeedback.lightImpact();
                    },
                    activeColor: AppThemePro.accentGold,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentsList() {
    final investments = _filteredInvestments;

    if (investments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.account_balance_rounded,
                size: 48,
                color: AppThemePro.textTertiary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Brak inwestycji',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppThemePro.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedProductType == 'Wszystkie' && !_showActiveOnly
                    ? 'Ten klient nie ma jeszcze żadnych inwestycji'
                    : 'Brak inwestycji spełniających wybrane kryteria',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppThemePro.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inwestycje (${investments.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppThemePro.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        ...investments.asMap().entries.map((entry) {
          final index = entry.key;
          final investment = entry.value;
          return _buildInvestmentCard(investment, index);
        }).toList(),
      ],
    );
  }

  Widget _buildInvestmentCard(Investment investment, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () => _showInvestmentDetails(investment),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppThemePro.elevatedSurfaceDecoration.copyWith(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getProductTypeColor(
                                investment.productType.displayName,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getProductTypeIcon(
                                investment.productType.displayName,
                              ),
                              color: _getProductTypeColor(
                                investment.productType.displayName,
                              ),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  investment.productName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppThemePro.textPrimary,
                                  ),
                                ),
                                Text(
                                  investment.productType.displayName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppThemePro.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildInvestmentStatusBadge(investment),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Financial info
                      Row(
                        children: [
                            Expanded(
                            child: _buildInvestmentMetric(
                              'Kwota inwestycji',
                              '${formatAmount(investment.investmentAmount)} zł',
                              Icons.payments_rounded,
                            ),
                            ),
                            Expanded(
                            child: _buildInvestmentMetric(
                              'Pozostały kapitał',
                              '${formatAmount(investment.remainingCapital)} zł',
                              Icons.account_balance_rounded,
                            ),
                          ),
                        ],
                      ),

                      if (investment.remainingCapital > 0) ...[
                        const SizedBox(height: 12),
                        // Progress bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Wykorzystanie kapitału',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppThemePro.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${((1 - investment.remainingCapital / investment.investmentAmount) * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppThemePro.accentGold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value:
                                  1 -
                                  (investment.remainingCapital /
                                      investment.investmentAmount),
                              backgroundColor: AppThemePro.borderPrimary,
                              valueColor: AlwaysStoppedAnimation(
                                AppThemePro.accentGold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppThemePro.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentMetric(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppThemePro.textSecondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AppThemePro.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppThemePro.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvestmentStatusBadge(Investment investment) {
    final isActive = investment.remainingCapital > 0;
    final color = isActive
        ? AppThemePro.statusSuccess
        : AppThemePro.statusWarning;
    final icon = isActive ? Icons.check_circle : Icons.pause_circle;
    final label = isActive ? 'Aktywna' : 'Zakończona';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProductTypeColor(String productType) {
    switch (productType.toLowerCase()) {
      case 'obligacje':
        return Colors.blue;
      case 'pożyczki':
        return Colors.green;
      case 'udziały':
        return Colors.purple;
      case 'apartamenty':
        return Colors.orange;
      default:
        return AppThemePro.accentGold;
    }
  }

  IconData _getProductTypeIcon(String productType) {
    switch (productType.toLowerCase()) {
      case 'obligacje':
        return Icons.description_rounded;
      case 'pożyczki':
        return Icons.handshake_rounded;
      case 'udziały':
        return Icons.trending_up_rounded;
      case 'apartamenty':
        return Icons.home_rounded;
      default:
        return Icons.account_balance_rounded;
    }
  }

  String _calculateROI() {
    if (_investorSummary == null ||
        _investorSummary!.totalInvestmentAmount == 0) {
      return '0%';
    }

    // Simple ROI calculation - można ulepszyć
    final invested = _investorSummary!.totalInvestmentAmount;
    final remaining = _investorSummary!.totalRemainingCapital;
    final utilized = invested - remaining;

    if (utilized <= 0) return '0%';

    // Zakładamy 5% roczny return (można pobrać z rzeczywistych danych)
    final estimatedReturn = utilized * 0.05;
    final roi = (estimatedReturn / invested) * 100;

    return '${roi.toStringAsFixed(1)}%';
  }

  Color _getROIColor() {
    final roiText = _calculateROI();
    final roi = double.tryParse(roiText.replaceAll('%', '')) ?? 0;

    if (roi > 3) return AppThemePro.statusSuccess;
    if (roi > 0) return AppThemePro.statusWarning;
    return AppThemePro.statusError;
  }

  void _showInvestmentDetails(Investment investment) {
    HapticFeedback.lightImpact();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppThemePro.premiumCardDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getProductTypeIcon(investment.productType.displayName),
                    color: AppThemePro.accentGold,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Szczegóły inwestycji',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppThemePro.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'ID: ${investment.id}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppThemePro.textPrimary,
                ),
              ),
              Text(
                'Typ: ${investment.productType}',
                style: const TextStyle(color: AppThemePro.textSecondary),
              ),

              const SizedBox(height: 16),

              Text(
                'Kwota inwestycji: ${investment.investmentAmount.toStringAsFixed(2)} zł',
                style: const TextStyle(color: AppThemePro.textPrimary),
              ),
              Text(
                'Pozostały kapitał: ${investment.remainingCapital.toStringAsFixed(2)} zł',
                style: const TextStyle(color: AppThemePro.textPrimary),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemePro.accentGold,
                    foregroundColor: AppThemePro.backgroundPrimary,
                  ),
                  child: const Text('Zamknij'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
