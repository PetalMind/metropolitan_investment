import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/investment_service.dart';
import '../services/client_service.dart';
import '../models/product.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final InvestmentService _investmentService = InvestmentService();
  final ClientService _clientService = ClientService();

  Map<String, dynamic>? _investmentSummary;
  Map<String, dynamic>? _clientStats;
  List<Map<String, dynamic>> _topProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      final summary = await _investmentService.getInvestmentSummary();
      final clientStats = await _clientService.getClientStats();
      final topProducts = await _getTopProducts();

      setState(() {
        _investmentSummary = summary;
        _clientStats = clientStats;
        _topProducts = topProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd podczas ładowania analityki: $e')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _getTopProducts() async {
    final summary = await _investmentService.getInvestmentSummary();
    final amountByProduct =
        summary['amountByProduct'] as Map<ProductType, double>? ?? {};

    final topProducts = amountByProduct.entries
        .map((e) => {'name': _getProductTypeName(e.key), 'amount': e.value})
        .toList();

    topProducts.sort(
      (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
    );
    return topProducts.take(4).toList();
  }

  String _getProductTypeName(ProductType type) {
    switch (type) {
      case ProductType.bonds:
        return 'Obligacje';
      case ProductType.shares:
        return 'Udziały';
      case ProductType.apartments:
        return 'Apartamenty';
      default:
        return 'Inne';
    }
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eksport raportu - funkcja w przygotowaniu'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.gradientDecoration,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analityka i Raporty',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Zaawansowana analiza inwestycji z Firebase',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _exportReport,
                  icon: const Icon(Icons.download),
                  label: const Text('Eksport Raportu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildAnalyticsCard(
                                'Całkowita wartość portfela',
                                _formatCurrency(
                                  _investmentSummary?['totalAmount'] ?? 0,
                                ),
                                Icons.account_balance_wallet,
                                AppTheme.primaryColor,
                                '+${((_investmentSummary?['totalPaid'] ?? 0) / (_investmentSummary?['totalAmount'] ?? 1) * 100).toStringAsFixed(1)}%',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildAnalyticsCard(
                                'Średnia inwestycja',
                                _formatCurrency(
                                  _investmentSummary?['averageInvestment'] ?? 0,
                                ),
                                Icons.trending_up,
                                AppTheme.successColor,
                                'Średnia',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildAnalyticsCard(
                                'Liczba aktywnych inwestycji',
                                '${_investmentSummary?['totalCount'] ?? 0}',
                                Icons.bar_chart,
                                AppTheme.infoColor,
                                'Całkowita',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: AppTheme.cardDecoration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rozkład inwestycji według statusu',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 20),
                              SizedBox(height: 300, child: _buildStatusChart()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: AppTheme.cardDecoration,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Top produkty',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineSmall,
                                    ),
                                    const SizedBox(height: 16),
                                    ..._topProducts.map(
                                      (product) => _buildTopProductItem(
                                        product['name'],
                                        _formatCurrency(product['amount']),
                                        product['amount'] /
                                            (_topProducts.isNotEmpty
                                                ? _topProducts.first['amount']
                                                : 1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: AppTheme.cardDecoration,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Statystyki klientów',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineSmall,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildStatItem(
                                      'Całkowita liczba klientów',
                                      '${_clientStats?['totalCount'] ?? 0}',
                                      Icons.people,
                                    ),
                                    _buildStatItem(
                                      'Klienci z emailem',
                                      '${_clientStats?['withEmail'] ?? 0}',
                                      Icons.email,
                                    ),
                                    _buildStatItem(
                                      'Klienci z telefonem',
                                      '${_clientStats?['withPhone'] ?? 0}',
                                      Icons.phone,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            change,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.successColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChart() {
    if (_investmentSummary == null) return const SizedBox();

    final byStatus = _investmentSummary!['byStatus'] as Map? ?? {};

    if (byStatus.isEmpty) {
      return const Center(child: Text('Brak danych do wyświetlenia'));
    }

    return PieChart(
      PieChartData(
        sections: byStatus.entries.map((entry) {
          final color = _getStatusColor(entry.key.toString());
          return PieChartSectionData(
            color: color,
            value: entry.value.toDouble(),
            title: '${entry.value}',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'InvestmentStatus.active':
        return AppTheme.successColor;
      case 'InvestmentStatus.inactive':
        return AppTheme.errorColor;
      case 'InvestmentStatus.earlyRedemption':
        return AppTheme.warningColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  Widget _buildTopProductItem(String name, String amount, double percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                amount,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0 PLN';
    final amount = value is double
        ? value
        : double.tryParse(value.toString()) ?? 0;
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M PLN';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K PLN';
    }
    return '${amount.toStringAsFixed(0)} PLN';
  }
}
