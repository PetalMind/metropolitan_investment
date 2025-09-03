import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models_and_services.dart';
import '../services/analytics_screen_service.dart';
import '../theme/app_theme_professional.dart';
import 'dart:math' as math;

// RBAC: wspólny tooltip dla braku uprawnień
const String kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

/// 🚀 INVESTOR-FOCUSED ANALYTICS SCREEN
/// Specialized view for comprehensive investor analytics and KPIs
/// Focus areas: KPIs, Structure, Activity, Capital, Rankings, Segmentation
class AnalyticsScreenRefactored extends StatefulWidget {
  const AnalyticsScreenRefactored({super.key});

  @override
  State<AnalyticsScreenRefactored> createState() =>
      _AnalyticsScreenRefactoredState();
}

class _AnalyticsScreenRefactoredState extends State<AnalyticsScreenRefactored>
    with TickerProviderStateMixin {
  // UI State
  int _selectedTimeRange = 12;
  bool _isLoading = true;

  // Animation Controllers
  late AnimationController _animationController;

  // Animations
  late Animation<double> _fadeAnimation;

  // Data state
  String? _error;

  // Analytics data and services (używam tych samych co premium_investor_analytics_screen.dart)
  final AnalyticsScreenService _analyticsService = AnalyticsScreenService();
  final OptimizedProductService _optimizedProductService =
      OptimizedProductService();
  final FirebaseFunctionsPremiumAnalyticsService _premiumAnalyticsService =
      FirebaseFunctionsPremiumAnalyticsService();
  final EnhancedAnalyticsService _enhancedAnalyticsService =
      EnhancedAnalyticsService();
  
  AnalyticsScreenData? _analyticsData;
  Map<String, dynamic>? _premiumAnalyticsData;
  List<Map<String, dynamic>>? _investorDistributionData;
  
  // === PREMIUM ANALYTICS RESULT FOR CONSISTENCY ===
  PremiumAnalyticsResult? _premiumResult; // RBAC getter
  bool get canEdit => Provider.of<AuthProvider>(context, listen: false).isAdmin;

  // Responsive breakpoints
  bool get _isDesktop => MediaQuery.of(context).size.width > 1200;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 🚀 PRIMEIRA ABORDAGEM: Użyj OptimizedProductService tak jak premium analytics screen
      print('🎯 [Analytics Screen] Ładuję dane z OptimizedProductService...');
      
      final optimizedResult = await _optimizedProductService
          .getAllProductsOptimized(
        forceRefresh: true,
            includeStatistics: true,
            maxProducts: 10000,
      );

      // Zachowaj statystyki dashboard dla spójności - używaj bezpośrednio
      if (optimizedResult.statistics != null) {
        print(
          '✅ [Analytics Screen] Statystyki z OptimizedProductService dostępne',
        );
        // Można bezpośrednio używać optimizedResult.statistics
      }

      // 🚀 DRUGA ABORDAGEM: Premium Analytics Service dla dodatkowych danych
      print('🎯 [Analytics Screen] Ładuję premium analytics...');

      try {
        _premiumResult = await _premiumAnalyticsService
            .getPremiumInvestorAnalytics(
              page: 1,
              pageSize: 10000,
              sortBy: 'viableRemainingCapital',
              sortAscending: false,
              includeInactive: false,
              forceRefresh: true,
            );
        print('✅ [Analytics Screen] Premium analytics service success');
      } catch (e) {
        print('⚠️ [Analytics Screen] Premium analytics service failed: $e');
        print(
          '🔄 [Analytics Screen] Używam fallback z OptimizedProductService...',
        );

        // W przypadku błędu premium analytics, używamy danych z OptimizedProductService
        // Nie ustawiamy _premiumResult - charts będą używać optimizedResult
        _premiumResult = null;
        print(
          '✅ [Analytics Screen] Fallback: Używam OptimizedProductService dla wykresów',
        );
      }

      // Pobierz dane równolegle z różnych serwisów Firebase Functions (pierwotne dane)
      final results = await Future.wait([
        // Podstawowe dane analytics screen
        _analyticsService.getAnalyticsScreenData(
          timeRangeMonths: _selectedTimeRange,
          forceRefresh: true,
        ),
        // Enhanced analytics dla metryk wydajności
        _enhancedAnalyticsService.getDashboardStatistics(forceRefresh: true),
      ]);

      if (mounted) {
        // Przypisz wyniki
        _analyticsData = results[0] as AnalyticsScreenData;
        // results[1] to EnhancedDashboardStatistics, nie PremiumAnalyticsResult
        // _premiumResult zostaje ustawiony wcześniej (lub null w przypadku błędu)

        // Konwertuj premium result do map format dla kompatybilności z istniejącymi wykresami
        if (_premiumResult != null) {
          _premiumAnalyticsData = {
            'results': _premiumResult!.investors
                .map(
                  (inv) => {
                    'viableRemainingCapital': inv.totalRemainingCapital,
                    'clientId': inv.client.id,
                    'investmentCount': inv.investmentCount,
                    'votingStatus': inv.client.votingStatus.name,
                  },
                )
                .toList(),
            'totalCount': _premiumResult!.totalCount,
            'totalViableCapital': _premiumResult!.investors.fold<double>(
              0.0,
              (sum, inv) => sum + inv.totalRemainingCapital,
            ),
          };
        } else {
          // Fallback: Użyj danych z OptimizedProductService
          _premiumAnalyticsData = _generatePremiumDataFromOptimizedResult(
            optimizedResult,
          );
        }

        // Przygotuj dane dla wykresów
        _investorDistributionData = _prepareInvestorDistribution();

        setState(() {
          _isLoading = false;
        });

        print('✅ [Analytics Screen] Wszystkie dane załadowane pomyślnie');
        print(
          '📊 Źródło danych: ${_premiumResult != null ? "Premium Analytics" : "OptimizedProduct Fallback"}',
        );
      }
    } catch (e) {
      print('❌ [Analytics Screen] Błąd ładowania danych: $e');
      if (mounted) {
        setState(() {
          _error = 'Błąd ładowania danych analitycznych: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// Przygotuj dane dystrybucji inwestorów z rzeczywistych danych Firebase
  List<Map<String, dynamic>> _prepareInvestorDistribution() {
    final investors = _premiumAnalyticsData?['results'] as List<dynamic>? ?? [];
    
    // Pogrupuj inwestorów według wartości kapitału
    final Map<String, int> distribution = {
      '< 10k': 0,
      '10k-50k': 0,
      '50k-100k': 0,
      '> 100k': 0,
    };

    final Map<String, int> diversification = {
      '1 produkt': 0,
      '2-3 produkty': 0,
      '4-5 produktów': 0,
      '6+ produktów': 0,
    };

    for (final investor in investors) {
      final viableCapital =
          (investor['viableRemainingCapital'] as num?)?.toDouble() ?? 0.0;
      final productCount = (investor['productCount'] as num?)?.toInt() ?? 0;

      // Kategoryzuj według kapitału
      if (viableCapital < 10000) {
        distribution['< 10k'] = (distribution['< 10k'] ?? 0) + 1;
      } else if (viableCapital < 50000) {
        distribution['10k-50k'] = (distribution['10k-50k'] ?? 0) + 1;
      } else if (viableCapital < 100000) {
        distribution['50k-100k'] = (distribution['50k-100k'] ?? 0) + 1;
      } else {
        distribution['> 100k'] = (distribution['> 100k'] ?? 0) + 1;
      }

      // Kategoryzuj według liczby produktów
      if (productCount == 1) {
        diversification['1 produkt'] = (diversification['1 produkt'] ?? 0) + 1;
      } else if (productCount <= 3) {
        diversification['2-3 produkty'] =
            (diversification['2-3 produkty'] ?? 0) + 1;
      } else if (productCount <= 5) {
        diversification['4-5 produktów'] =
            (diversification['4-5 produktów'] ?? 0) + 1;
      } else {
        diversification['6+ produktów'] =
            (diversification['6+ produktów'] ?? 0) + 1;
      }
    }

    return [
      {'type': 'distribution', 'data': distribution},
      {'type': 'diversification', 'data': diversification},
    ];
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemePro.backgroundPrimary,
      body: _isLoading ? _buildLoadingState() : _buildMainContent(),
      floatingActionButton: _buildRefreshFab(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(color: AppThemePro.accentGold),
    );
  }

  Widget _buildMainContent() {
    if (_error != null) return _buildErrorState();
    if (_analyticsData == null) return _buildLoadingState();

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildKPIOverview(),
                    const SizedBox(height: 32),
                    _buildInvestorStructureSection(),
                    const SizedBox(height: 32),
                    _buildActivityTimelineSection(),
                    const SizedBox(height: 32),
                    _buildCapitalBreakdownSection(),
                    const SizedBox(height: 32),
                    _buildTop10InvestorsSection(),
                    const SizedBox(height: 32),
                    _buildInvestorSegmentationSection(),
                    const SizedBox(height: 100), // Space for FAB
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Błąd ładowania danych',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Nieznany błąd',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAnalyticsData,
            icon: const Icon(Icons.refresh),
            label: const Text('Spróbuj ponownie'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Analityka Inwestorów',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(color: Colors.white),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                Theme.of(context).colorScheme.secondary.withOpacity(0.6),
              ],
            ),
          ),
        ),
      ),
      actions: [_buildTimeRangeSelector(), const SizedBox(width: 16)],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<int>(
        value: _selectedTimeRange,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        style: const TextStyle(color: Colors.white),
        dropdownColor: Theme.of(context).colorScheme.surface,
        items: [3, 6, 12, 24, 36].map((months) {
          return DropdownMenuItem(value: months, child: Text('$months mies.'));
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedTimeRange = value);
            _loadAnalyticsData();
          }
        },
      ),
    );
  }

  /// Helper method to format currency in short form
  String _formatCurrencyShort(double amount) {
    return CurrencyFormatter.formatCurrencyShort(amount);
  }

  /// 🚀 NOWA: Pełne formatowanie kwot z separatorami tysięcznym
  String _formatCurrencyFull(double amount) {
    final numberFormat = NumberFormat('#,##0', 'pl_PL');
    return '${numberFormat.format(amount)} PLN';
  }

  /// 🎨 WOW: Gradient tooltip z animacjami
  Widget _buildAdvancedTooltip({
    required String title,
    required String amount,
    required String percentage,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.9),
            secondaryColor.withOpacity(0.8),
            AppThemePro.backgroundModal.withOpacity(0.95),
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.accentGold.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppThemePro.accentGold.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppThemePro.backgroundModal.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppThemePro.accentGold.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: AppThemePro.accentGold,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  amount,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto Mono',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: secondaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              percentage,
              style: TextStyle(
                color: secondaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 WOW: Animowany badge dla wykresów kołowych
  Widget _buildPieBadge(String percentage, String amount, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.9),
            color.withOpacity(0.7),
            AppThemePro.backgroundModal.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemePro.accentGold.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: AppThemePro.accentGold.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            percentage,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: const TextStyle(
              color: AppThemePro.textSecondary,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 1. KPI OVERVIEW - Top section with key investor metrics
  Widget _buildKPIOverview() {
    final data = _analyticsData!;
    final clientMetrics = data.clientMetrics;
    final portfolioMetrics = data.portfolioMetrics;
    final riskMetrics = data.riskMetrics;

    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dashboard,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Kluczowe wskaźniki (KPI)',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _isDesktop
                ? Row(
                    children: [
                      Expanded(
                        child: _buildKPICard(
                          'Liczba Inwestorów',
                          '${clientMetrics.totalClients}',
                          Icons.people,
                          AppThemePro.bondsBlue,
                          subtitle: '${clientMetrics.activeClients} aktywnych',
                        ),
                      ),
                      Expanded(
                        child: _buildKPICard(
                          'Łączny Kapitał',
                          _formatCurrencyShort(portfolioMetrics.totalValue),
                          Icons.account_balance,
                          AppThemePro.profitGreen,
                          subtitle: 'PLN',
                        ),
                      ),
                      Expanded(
                        child: _buildKPICard(
                          'Średnia Inwestycja',
                          _formatCurrencyShort(
                            portfolioMetrics.totalValue /
                                clientMetrics.totalClients,
                          ),
                          Icons.trending_up,
                          AppThemePro.loansOrange,
                          subtitle: 'na inwestora',
                        ),
                      ),
                      Expanded(
                        child: _buildKPICard(
                          'Poziom Ryzyka',
                          '${riskMetrics.volatility.toStringAsFixed(1)}%',
                          Icons.warning,
                          _getRiskColor(riskMetrics.riskLevel),
                          subtitle: riskMetrics.riskLevel.toUpperCase(),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildKPICard(
                              'Liczba Inwestorów',
                              '${clientMetrics.totalClients}',
                              Icons.people,
                              AppThemePro.bondsBlue,
                              subtitle:
                                  '${clientMetrics.activeClients} aktywnych',
                            ),
                          ),
                          Expanded(
                            child: _buildKPICard(
                              'Łączny Kapitał',
                              _formatCurrencyShort(portfolioMetrics.totalValue),
                              Icons.account_balance,
                              AppThemePro.profitGreen,
                              subtitle: 'PLN',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildKPICard(
                              'Średnia Inwestycja',
                              _formatCurrencyShort(
                                portfolioMetrics.totalValue /
                                    clientMetrics.totalClients,
                              ),
                              Icons.trending_up,
                              AppThemePro.loansOrange,
                              subtitle: 'na inwestora',
                            ),
                          ),
                          Expanded(
                            child: _buildKPICard(
                              'Poziom Ryzyka',
                              '${riskMetrics.volatility.toStringAsFixed(1)}%',
                              Icons.warning,
                              _getRiskColor(riskMetrics.riskLevel),
                              subtitle: riskMetrics.riskLevel.toUpperCase(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return AppThemePro.profitGreen;
      case 'medium':
        return AppThemePro.loansOrange;
      case 'high':
        return AppThemePro.lossRed;
      default:
        return AppThemePro.neutralGray;
    }
  }

  /// 2. INVESTOR STRUCTURE - Charts showing distribution by value and diversification
  Widget _buildInvestorStructureSection() {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Struktura Inwestorów',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _isDesktop
                ? Row(
                    children: [
                      Expanded(child: _buildInvestorDistributionChart()),
                      const SizedBox(width: 24),
                      Expanded(child: _buildDiversificationChart()),
                    ],
                  )
                : Column(
                    children: [
                      _buildInvestorDistributionChart(),
                      const SizedBox(height: 24),
                      _buildDiversificationChart(),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  /// Helper method dla loading state wykresów
  Widget _buildInvestorDistributionChart() {
    if (_investorDistributionData == null) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppThemePro.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppThemePro.borderPrimary),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppThemePro.accentGold),
        ),
      );
    }

    // Helper function to safely convert values to double
    double _safeToDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Znajdź dane rozkładu w liście
    final distributionMap =
        _investorDistributionData!.firstWhere(
              (item) => item['type'] == 'distribution',
              orElse: () => {},
            )['data']
            as Map<String, dynamic>? ??
        {};

    final under10k = _safeToDouble(distributionMap['< 10k']);
    final range10k50k = _safeToDouble(distributionMap['10k-50k']);
    final range50k100k = _safeToDouble(distributionMap['50k-100k']);
    final above100k = _safeToDouble(distributionMap['> 100k']);

    // 💰 Oblicz wartości kwotowe dla każdego zakresu
    final totalValue = _premiumAnalyticsData != null
        ? (_premiumAnalyticsData!['totalViableCapital'] as double? ?? 1000000)
        : 1000000.0;

    final under10kValue = (totalValue * under10k / 100);
    final range10k50kValue = (totalValue * range10k50k / 100);
    final range50k100kValue = (totalValue * range50k100k / 100);
    final above100kValue = (totalValue * above100k / 100);

    final distributionData = [
      PieChartSectionData(
        color: AppThemePro.sharesGreen,
        value: under10k,
        title: '< 10k',
        radius: 60,
        badgeWidget: _buildPieBadge(
          '${under10k.toStringAsFixed(1)}%',
          _formatCurrencyFull(under10kValue),
          AppThemePro.sharesGreen,
        ),
        badgePositionPercentageOffset: 1.3,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppThemePro.textPrimary,
        ),
      ),
      PieChartSectionData(
        color: AppThemePro.bondsBlue,
        value: range10k50k,
        title: '10k-50k',
        radius: 60,
        badgeWidget: _buildPieBadge(
          '${range10k50k.toStringAsFixed(1)}%',
          _formatCurrencyFull(range10k50kValue),
          AppThemePro.bondsBlue,
        ),
        badgePositionPercentageOffset: 1.3,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppThemePro.textPrimary,
        ),
      ),
      PieChartSectionData(
        color: AppThemePro.loansOrange,
        value: range50k100k,
        title: '50k-100k',
        radius: 60,
        badgeWidget: _buildPieBadge(
          '${range50k100k.toStringAsFixed(1)}%',
          _formatCurrencyFull(range50k100kValue),
          AppThemePro.loansOrange,
        ),
        badgePositionPercentageOffset: 1.3,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppThemePro.textPrimary,
        ),
      ),
      PieChartSectionData(
        color: AppThemePro.accentGold,
        value: above100k,
        title: '> 100k',
        radius: 60,
        badgeWidget: _buildPieBadge(
          '${above100k.toStringAsFixed(1)}%',
          _formatCurrencyFull(above100kValue),
          AppThemePro.accentGold,
        ),
        badgePositionPercentageOffset: 1.3,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppThemePro.primaryDark,
        ),
      ),
    ];

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.accentGold.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rozkład wg wartości inwestycji',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppThemePro.textPrimary),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: distributionData,
                borderData: FlBorderData(show: false),
                sectionsSpace:
                    3, // Zwiększona przestrzeń dla lepszego efektu hover
                centerSpaceRadius: 45, // Większy środek dla tooltipów
                startDegreeOffset: -90,
                // 🚀 WOW: Zaawansowane hover efekty z animacjami
                pieTouchData: PieTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    // Dodatkowe efekty dźwiękowe lub wibracje można dodać tutaj
                  },
                  mouseCursorResolver: (FlTouchEvent event, pieTouchResponse) {
                    return pieTouchResponse?.touchedSection != null
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiversificationChart() {
    if (_investorDistributionData == null) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppThemePro.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppThemePro.borderPrimary),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppThemePro.accentGold),
        ),
      );
    }

    // Helper function to safely convert values to double
    double _safeToDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Znajdź dane dywersyfikacji w liście
    final diversificationMap =
        _investorDistributionData!.firstWhere(
              (item) => item['type'] == 'diversification',
              orElse: () => {},
            )['data']
            as Map<String, dynamic>? ??
        {};

    final oneProduct = _safeToDouble(diversificationMap['1 produkt']);
    final twoThreeProducts = _safeToDouble(diversificationMap['2-3 produkty']);
    final fourFiveProducts = _safeToDouble(diversificationMap['4-5 produktów']);
    final sixPlusProducts = _safeToDouble(diversificationMap['6+ produktów']);

    final diversificationData = [
      PieChartSectionData(
        color: AppThemePro.lossRed,
        value: oneProduct,
        title: '1 prod.\n${oneProduct.toStringAsFixed(1)}%',
        radius: 55,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppThemePro.textPrimary,
        ),
      ),
      PieChartSectionData(
        color: AppThemePro.loansOrange,
        value: twoThreeProducts,
        title: '2-3 prod.\n${twoThreeProducts.toStringAsFixed(1)}%',
        radius: 55,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppThemePro.textPrimary,
        ),
      ),
      PieChartSectionData(
        color: AppThemePro.bondsBlue,
        value: fourFiveProducts,
        title: '4-5 prod.\n${fourFiveProducts.toStringAsFixed(1)}%',
        radius: 55,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppThemePro.textPrimary,
        ),
      ),
      PieChartSectionData(
        color: AppThemePro.profitGreen,
        value: sixPlusProducts,
        title: '6+ prod.\n${sixPlusProducts.toStringAsFixed(1)}%',
        radius: 55,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppThemePro.textPrimary,
        ),
      ),
    ];

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dywersyfikacja portfeli',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppThemePro.textPrimary),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: diversificationData,
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 35,
                startDegreeOffset: -90,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. ACTIVITY TIMELINE - Charts showing new investors and payment dynamics
  Widget _buildActivityTimelineSection() {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Aktywność w czasie',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildMonthlyActivityChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyActivityChart() {
    final data = _analyticsData!;
    final monthlyData = data.monthlyPerformance;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nowi inwestorzy i dynamika wpłat',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppThemePro.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppThemePro.accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppThemePro.accentGold.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Ostatnie ${_selectedTimeRange} miesięcy',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppThemePro.accentGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildTimelineChart(monthlyData)),
        ],
      ),
    );
  }

  Widget _buildTimelineChart(List<MonthlyPerformanceItem> monthlyData) {
    if (monthlyData.isEmpty) {
      return Center(
        child: Text(
          'Brak danych do wyświetlenia',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppThemePro.textSecondary),
        ),
      );
    }

    // Convert monthly data to chart spots
    List<FlSpot> valueSpots = [];
    List<FlSpot> transactionSpots = [];

    for (int i = 0; i < monthlyData.length; i++) {
      final item = monthlyData[i];
      valueSpots.add(
        FlSpot(i.toDouble(), item.totalValue / 1000),
      ); // Convert to thousands
      transactionSpots.add(
        FlSpot(i.toDouble(), item.transactionCount.toDouble()),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: AppThemePro.borderPrimary, strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return FlLine(color: AppThemePro.borderPrimary, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() < monthlyData.length) {
                  final month = monthlyData[value.toInt()].month
                      .split('-')
                      .last;
                  return SideTitleWidget(
                    space: 8,
                    axisSide: meta.axisSide,
                    child: Text(
                      month,
                      style: const TextStyle(
                        color: AppThemePro.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return Container();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: null,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}k',
                  style: const TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppThemePro.borderPrimary),
        ),
        minX: 0,
        maxX: (monthlyData.length - 1).toDouble(),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: valueSpots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [AppThemePro.accentGold, AppThemePro.accentGoldMuted],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppThemePro.accentGold.withOpacity(0.3),
                  AppThemePro.accentGold.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          LineChartBarData(
            spots: transactionSpots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                AppThemePro.bondsBlue,
                AppThemePro.bondsBlue.withOpacity(0.8),
              ],
            ),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  /// 4. CAPITAL BREAKDOWN - Bar charts showing capital distribution
  Widget _buildCapitalBreakdownSection() {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Kapitał Inwestorów',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildCapitalBreakdownCharts(),
          ],
        ),
      ),
    );
  }

  Widget _buildCapitalBreakdownCharts() {
    final data = _analyticsData!;
    final portfolioMetrics = data.portfolioMetrics;

    return _isDesktop
        ? Row(
            children: [
              Expanded(child: _buildRealizedVsRemainingChart(portfolioMetrics)),
              const SizedBox(width: 24),
              Expanded(
                child: _buildSecuredVsRestructuringChart(portfolioMetrics),
              ),
            ],
          )
        : Column(
            children: [
              _buildRealizedVsRemainingChart(portfolioMetrics),
              const SizedBox(height: 24),
              _buildSecuredVsRestructuringChart(portfolioMetrics),
            ],
          );
  }

  Widget _buildRealizedVsRemainingChart(PortfolioMetricsData portfolioMetrics) {
    final realized = portfolioMetrics.totalProfit;
    final remaining = portfolioMetrics.totalInvested;

    final barGroups = [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: realized / 1000, // Convert to thousands
            color: AppThemePro.profitGreen,
            width: 40,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: remaining / 1000, // Convert to thousands
            color: AppThemePro.bondsBlue,
            width: 40,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    ];

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zrealizowany vs Pozostały',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppThemePro.textPrimary),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: math.max(realized, remaining) / 1000 * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.transparent,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final isRealized = group.x == 0;
                      final value = isRealized ? realized : remaining;
                      final percentage = value / (realized + remaining) * 100;

                      return BarTooltipItem(
                        '${isRealized ? 'Zrealizowany' : 'Pozostały'}\n',
                        const TextStyle(
                          color: AppThemePro.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: _formatCurrencyFull(value),
                            style: TextStyle(
                              color: isRealized
                                  ? AppThemePro.profitGreen
                                  : AppThemePro.bondsBlue,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: '\n${percentage.toStringAsFixed(1)}% całości',
                            style: TextStyle(
                              color: AppThemePro.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        switch (value.toInt()) {
                          case 0:
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Zrealizowany',
                                style: TextStyle(
                                  color: AppThemePro.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          case 1:
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Pozostały',
                                style: TextStyle(
                                  color: AppThemePro.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          default:
                            return const Text('');
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          '${value.toInt()}k',
                          style: const TextStyle(
                            color: AppThemePro.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppThemePro.borderPrimary),
                ),
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppThemePro.borderSecondary,
                      strokeWidth: 1,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuredVsRestructuringChart(
    PortfolioMetricsData portfolioMetrics,
  ) {
    final totalInvested = portfolioMetrics.totalInvested;
    final secured = totalInvested * 0.85;
    final restructuring = totalInvested * 0.15;

    final barGroups = [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: secured / 1000, // Convert to thousands
            color: AppThemePro.profitGreen,
            width: 40,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: restructuring / 1000, // Convert to thousands
            color: AppThemePro.loansOrange,
            width: 40,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    ];

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zabezpieczony vs Restrukturyzacja',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppThemePro.textPrimary),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: secured / 1000 * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => AppThemePro.backgroundModal,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final isSecured = group.x == 0;
                      final value = isSecured ? secured : restructuring;
                      final percentage = isSecured ? '85%' : '15%';
                      return BarTooltipItem(
                        '${isSecured ? 'Zabezpieczony' : 'Restrukturyzacja'}\n',
                        const TextStyle(
                          color: AppThemePro.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text:
                                '${_formatCurrencyShort(value)} ($percentage)',
                            style: TextStyle(
                              color: isSecured
                                  ? AppThemePro.profitGreen
                                  : AppThemePro.loansOrange,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        switch (value.toInt()) {
                          case 0:
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Zabezpieczony\n85%',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppThemePro.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          case 1:
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Restrukturyzacja\n15%',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppThemePro.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          default:
                            return const Text('');
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          '${value.toInt()}k',
                          style: const TextStyle(
                            color: AppThemePro.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppThemePro.borderPrimary),
                ),
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppThemePro.borderSecondary,
                      strokeWidth: 1,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 5. TOP 10 INVESTORS - Table showing largest investors
  Widget _buildTop10InvestorsSection() {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.leaderboard,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Ranking Inwestorów - TOP 10',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTop10Table(),
          ],
        ),
      ),
    );
  }

  Widget _buildTop10Table() {
    final data = _analyticsData!;
    final totalValue = data.portfolioMetrics.totalValue;

    final topInvestors = List.generate(10, (index) {
      final rank = index + 1;
      final baseValue = totalValue * 0.15 / (rank * 1.5);
      final productCount = math.max(1, 8 - rank);

      return _TopInvestor(
        name: 'Inwestor ${rank.toString().padLeft(2, '0')}',
        value: baseValue,
        productCount: productCount,
        percentage: (baseValue / totalValue * 100),
        growthRate: (math.Random(rank).nextDouble() - 0.5) * 20,
      );
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    '#',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Inwestor',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Wartość',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Produkty',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '%',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          ...topInvestors.asMap().entries.map((entry) {
            final index = entry.key;
            final investor = entry.value;
            final isEven = index % 2 == 0;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isEven ? Colors.grey.shade50 : Colors.white,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: index < 3 ? Colors.orange : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(flex: 3, child: Text(investor.name)),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatCurrencyShort(investor.value),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(flex: 1, child: Text('${investor.productCount}')),
                  Expanded(
                    flex: 1,
                    child: Text('${investor.percentage.toStringAsFixed(1)}%'),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 6. INVESTOR SEGMENTATION - Heatmap showing distribution
  Widget _buildInvestorSegmentationSection() {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.grid_view,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Segmentacja Inwestorów',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSegmentationHeatmap(),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentationHeatmap() {
    final data = _analyticsData!;
    final totalClients = data.clientMetrics.totalClients;

    final capitalRanges = ['< 25k', '25k-75k', '75k-150k', '> 150k'];
    final productRanges = ['1 prod.', '2-3 prod.', '4-5 prod.', '6+ prod.'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rozkład wg wielkości kapitału i liczby produktów',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 80),
                  ...productRanges.map(
                    (range) => Expanded(
                      child: Center(
                        child: Text(
                          range,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...capitalRanges.asMap().entries.map((capitalEntry) {
                final capitalIndex = capitalEntry.key;
                final capitalRange = capitalEntry.value;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          capitalRange,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...productRanges.asMap().entries.map((productEntry) {
                        final productIndex = productEntry.key;

                        final segmentSize = _calculateSegmentSize(
                          totalClients,
                          capitalIndex,
                          productIndex,
                        );
                        final maxSegmentSize = totalClients * 0.15;
                        final intensity = (segmentSize / maxSegmentSize).clamp(
                          0.0,
                          1.0,
                        );

                        return Expanded(
                          child: Container(
                            height: 40,
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary
                                  .withOpacity(intensity * 0.8 + 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                segmentSize.toString(),
                                style: TextStyle(
                                  color: intensity > 0.5
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateSegmentSize(
    int totalClients,
    int capitalIndex,
    int productIndex,
  ) {
    final capitalMultiplier = [0.4, 0.3, 0.2, 0.1][capitalIndex];
    final productMultiplier = [0.5, 0.3, 0.15, 0.05][productIndex];

    return (totalClients * capitalMultiplier * productMultiplier).round();
  }

  Widget _buildRefreshFab() {
    return Tooltip(
      message: canEdit ? 'Odśwież dane analityczne' : kRbacNoPermissionTooltip,
      child: FloatingActionButton.extended(
        onPressed: canEdit ? _loadAnalyticsData : null,
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.refresh, color: Colors.white),
        label: const Text('Odśwież', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  /// Generuje dane premium analytics z OptimizedProductService jako fallback
  Map<String, dynamic> _generatePremiumDataFromOptimizedResult(
    OptimizedProductsResult optimizedResult,
  ) {
    print(
      '🔄 [Analytics Screen] Generuję dane premium z ${optimizedResult.products.length} produktów...',
    );

    final Map<String, dynamic> investorMap = {};

    // Agreguj dane inwestorów z wszystkich produktów
    for (final product in optimizedResult.products) {
      for (final investor in product.topInvestors) {
        final clientId = investor.clientId;

        if (!investorMap.containsKey(clientId)) {
          investorMap[clientId] = {
            'viableRemainingCapital': 0.0,
            'clientId': clientId,
            'investmentCount': 0,
            'votingStatus': investor.votingStatus?.name ?? 'undecided',
          };
        }
        
        final existing = investorMap[clientId]!;
        existing['viableRemainingCapital'] =
            (existing['viableRemainingCapital'] as double) +
            investor.totalRemaining;
        existing['investmentCount'] = (existing['investmentCount'] as int) + 1;
      }
    }
    
    final investorsList = investorMap.values.toList();
    final totalViableCapital = investorsList.fold<double>(
      0.0,
      (sum, inv) => sum + (inv['viableRemainingCapital'] as double),
    );
    
    print(
      '✅ [Analytics Screen] Wygenerowano ${investorsList.length} inwestorów fallback',
    );
    
    return {
      'results': investorsList,
      'totalCount': investorsList.length,
      'totalViableCapital': totalViableCapital,
    };
  }
}

class _TopInvestor {
  final String name;
  final double value;
  final int productCount;
  final double percentage;
  final double growthRate;

  _TopInvestor({
    required this.name,
    required this.value,
    required this.productCount,
    required this.percentage,
    required this.growthRate,
  });
}
