import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/dashboard/product_dashboard_widget.dart';
import '../widgets/metropolitan_loading_system.dart';
import '../theme/app_theme_professional.dart';
import '../models_and_services.dart';
import '../providers/auth_provider.dart';

// RBAC: wspólny tooltip dla braku uprawnień
const String kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

/// 🚀 SCREEN DEMONSTRACYJNY NOWEGO DASHBOARD PRODUKTÓW
/// Nowoczesny ekran pokazujący funkcjonalność ProductDashboardWidget
///
/// ✨ NOWE FUNKCJONALNOŚCI:
/// • 🔍 Szczegóły wybranego produktu/inwestycji
/// • 📅 Dynamiczne terminy i oś czasu
/// • 💰 Poprawione obliczenia statystyk wybranych produktów
/// • 🎯 Integracja z zunifikowanymi serwisami
class ProductDashboardScreen extends StatefulWidget {
  const ProductDashboardScreen({super.key});

  @override
  State<ProductDashboardScreen> createState() => _ProductDashboardScreenState();
}

class _ProductDashboardScreenState extends State<ProductDashboardScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedProductId;
  bool _showDetailsPanel = false;
  bool _isLoading = true;
  
  // RBAC getter
  bool get canEdit => Provider.of<AuthProvider>(context, listen: false).isAdmin;

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  void _simulateLoading() async {
    // Symulacja ładowania danych dashboard
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppThemePro.professionalTheme,
      child: Scaffold(
        backgroundColor: AppThemePro.backgroundPrimary,
        appBar: _buildAppBar(context),
        body: _isLoading 
          ? const Center(
              child: MetropolitanLoadingWidget.financial(
                showProgress: true,
              ),
            )
          : Row(
              children: [
                // Główny dashboard - 70% szerokości
                Expanded(
                  flex: 7,
                  child: ProductDashboardWidget(
                    selectedProductId: _selectedProductId,
                    onProductSelected: (productId) {
                      setState(() {
                        _selectedProductId = productId;
                    _showDetailsPanel = true;
                  });
                },
              ),
            ),

            // Panel szczegółów - 30% szerokości (jeśli aktywny)
            if (_showDetailsPanel && _selectedProductId != null)
              Container(
                width: MediaQuery.of(context).size.width * 0.3,
                decoration: BoxDecoration(
                  color: AppThemePro.backgroundSecondary,
                  border: Border(
                    left: BorderSide(
                      color: AppThemePro.borderSecondary,
                      width: 1,
                    ),
                  ),
                ),
                child: _buildDetailsPanel(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Removed unused avatar animation disposal
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Icon(
            Icons.dashboard_outlined,
            color: AppThemePro.accentGold,
            size: 28,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Metropolitan Investment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppThemePro.textPrimary,
                ),
              ),
              Text(
                'Dashboard Produktów',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppThemePro.accentGold,
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: AppThemePro.backgroundPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      actions: [
        // Przycisk przełączania panelu szczegółów
        if (_selectedProductId != null)
          IconButton(
            onPressed: () {
              setState(() {
                _showDetailsPanel = !_showDetailsPanel;
              });
            },
            icon: Icon(
              _showDetailsPanel ? Icons.close_fullscreen : Icons.open_in_full,
              color: AppThemePro.accentGold,
            ),
            tooltip: _showDetailsPanel ? 'Ukryj szczegóły' : 'Pokaż szczegóły',
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDetailsPanel() {
    return Column(
      children: [
        // Nagłówek panelu szczegółów
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppThemePro.backgroundPrimary,
            border: Border(
              bottom: BorderSide(color: AppThemePro.borderSecondary, width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppThemePro.accentGold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Szczegóły produktu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppThemePro.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showDetailsPanel = false;
                    _selectedProductId = null;
                  });
                },
                icon: Icon(Icons.close, color: AppThemePro.textMuted, size: 20),
                tooltip: 'Zamknij szczegóły',
              ),
            ],
          ),
        ),

        // Zawartość panelu szczegółów
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<Investment?>(
              future: _loadProductDetails(_selectedProductId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || snapshot.data == null) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final investment = snapshot.data!;
                return _buildProductDetails(investment);
              },
            ),
          ),
        ),
      ],
    );
  }

  // Centered logo over animated avatar (breathing effect)

  Widget _buildProductDetails(Investment investment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Podstawowe informacje
        _buildInfoSection('Podstawowe informacje', [
          _buildInfoRow('Nazwa produktu', investment.productName),
          _buildInfoRow('Firma', investment.creditorCompany),
          _buildInfoRow('Typ produktu', investment.productType.displayName),
          _buildInfoRow('Status', _getStatusText(investment.status)),
        ]),

        const SizedBox(height: 24),

        // Informacje finansowe
        _buildInfoSection('Informacje finansowe', [
          _buildInfoRow(
            'Kwota inwestycji',
            '${investment.investmentAmount.toStringAsFixed(2)} zł',
          ),
          _buildInfoRow(
            'Kapitał pozostały',
            '${investment.remainingCapital.toStringAsFixed(2)} zł',
          ),
          _buildInfoRow(
            'Kapitał w restrukturyzacji',
            '${investment.capitalForRestructuring.toStringAsFixed(2)} zł',
          ),
          _buildInfoRow(
            'Kapitał zabezpieczony',
            '${(investment.remainingCapital - investment.capitalForRestructuring).clamp(0, double.infinity).toStringAsFixed(2)} zł',
          ),
        ]),

        const SizedBox(height: 24),

        // 🚀 NOWA SEKCJA: Dynamiczne terminy i oś czasu
        _buildTimelineSection(investment),

        const SizedBox(height: 24),

        // Informacje o kliencie
        _buildInfoSection('Informacje o kliencie', [
          _buildInfoRow('Nazwa klienta', investment.clientName),
          if (investment.additionalInfo['clientType'] != null)
            _buildInfoRow(
              'Typ klienta',
              investment.additionalInfo['clientType'].toString(),
            ),
        ]),
      ],
    );
  }

  Widget _buildTimelineSection(Investment investment) {
    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: AppThemePro.backgroundPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderSecondary, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: AppThemePro.accentGold, size: 20),
              const SizedBox(width: 8),
              Text(
                'Terminy i oś czasu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppThemePro.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dynamiczne terminy
          ..._buildTimelineItems(investment, now),
        ],
      ),
    );
  }

  List<Widget> _buildTimelineItems(Investment investment, DateTime now) {
    final timelineItems = <Widget>[];

    // Data podpisania
    timelineItems.add(
      _buildTimelineItem(
        'Data podpisania',
        investment.signedDate,
        Icons.edit,
        AppThemePro.accentGold,
        now,
      ),
    );

    // Data emisji
    if (investment.issueDate != null) {
      timelineItems.add(
        _buildTimelineItem(
          'Data emisji',
          investment.issueDate!,
          Icons.launch,
          AppThemePro.bondsBlue,
          now,
        ),
      );
    }

    // Data wprowadzenia
    if (investment.entryDate != null) {
      timelineItems.add(
        _buildTimelineItem(
          'Data wprowadzenia',
          investment.entryDate!,
          Icons.input,
          AppThemePro.sharesGreen,
          now,
        ),
      );
    }

    // Data wykupu
    if (investment.redemptionDate != null) {
      final daysToRedemption = investment.redemptionDate!
          .difference(now)
          .inDays;
      final isOverdue = daysToRedemption < 0;
      final isNearDue = daysToRedemption >= 0 && daysToRedemption <= 30;

      Color timelineColor = AppThemePro.statusSuccess;
      if (isOverdue) {
        timelineColor = AppThemePro.statusError;
      } else if (isNearDue) {
        timelineColor = AppThemePro.statusWarning;
      }

      timelineItems.add(
        _buildTimelineItem(
          'Data wykupu',
          investment.redemptionDate!,
          isOverdue ? Icons.error : Icons.event_available,
          timelineColor,
          now,
          showWarning: isOverdue || isNearDue,
        ),
      );
    }

    return timelineItems;
  }

  Widget _buildTimelineItem(
    String label,
    DateTime date,
    IconData icon,
    Color color,
    DateTime now, {
    bool showWarning = false,
  }) {
    final daysDiff = date.difference(now).inDays;
    final isPast = daysDiff < 0;
    final isToday = daysDiff == 0;

    String dateText =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    String statusText = '';

    if (isToday) {
      statusText = ' (Dzisiaj)';
    } else if (isPast) {
      statusText = ' (${daysDiff.abs()} dni temu)';
    } else {
      statusText = ' (Za $daysDiff dni)';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppThemePro.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      dateText,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppThemePro.textMuted,
                      ),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        color: showWarning
                            ? AppThemePro.statusWarning
                            : AppThemePro.textMuted,
                        fontWeight: showWarning
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showWarning)
            Icon(
              Icons.warning_amber_rounded,
              color: AppThemePro.statusWarning,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppThemePro.backgroundPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderSecondary, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppThemePro.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: AppThemePro.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppThemePro.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppThemePro.statusError, size: 48),
          const SizedBox(height: 16),
          Text(
            'Błąd ładowania szczegółów',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppThemePro.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 12, color: AppThemePro.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Metody pomocnicze
  Future<Investment?> _loadProductDetails(String productId) async {
    try {
      final result = await FirebaseFunctionsDataService.getAllInvestments(
        page: 1,
        pageSize: 5000,
      );

      return result.investments.firstWhere(
        (inv) => inv.id == productId,
        orElse: () => throw Exception('Produkt nie znaleziony'),
      );
    } catch (e) {
      return null;
    }
  }

  String _getStatusText(InvestmentStatus status) {
    switch (status) {
      case InvestmentStatus.active:
        return 'Aktywny';
      case InvestmentStatus.inactive:
        return 'Nieaktywny';
      case InvestmentStatus.earlyRedemption:
        return 'Przedterminowy wykup';
      case InvestmentStatus.completed:
        return 'Zakończony';
    }
  }
}
