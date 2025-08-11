import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// Import wszystkich tabów
import 'tabs/overview_tab.dart';
import 'tabs/performance_tab.dart';
import 'tabs/risk_tab.dart';
import 'tabs/employees_tab.dart';
import 'tabs/geographic_tab.dart';
import 'tabs/trends_tab.dart';

/// 🚀 KOMPLETNIE ZREFAKTORYZOWANY ANALYTICS SCREEN
/// Modułowa architektura z pełną funkcjonalnością wszystkich tabów
class AnalyticsScreenComplete extends StatefulWidget {
  const AnalyticsScreenComplete({super.key});

  @override
  State<AnalyticsScreenComplete> createState() =>
      _AnalyticsScreenCompleteState();
}

class _AnalyticsScreenCompleteState extends State<AnalyticsScreenComplete>
    with TickerProviderStateMixin {
  // UI State
  int _selectedTimeRange = 12;
  String _selectedAnalyticsTab = 'overview';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Responsive breakpoints
  bool get _isTablet => MediaQuery.of(context).size.width > 768;

  // Tab definitions
  final _tabs = [
    _TabInfo('overview', 'Przegląd', Icons.dashboard),
    _TabInfo('performance', 'Wydajność', Icons.trending_up),
    _TabInfo('risk', 'Ryzyko', Icons.security),
    _TabInfo('employees', 'Zespół', Icons.people),
    _TabInfo('geographic', 'Geografia', Icons.map),
    _TabInfo('trends', 'Trendy', Icons.timeline),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildTabContent(),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildRefreshFab(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.gradientDecoration,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zaawansowana Analityka',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(color: AppTheme.textOnPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kompleksowa analiza w czasie rzeczywistym z Firebase',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textOnPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isTablet) _buildDesktopControls(),
            ],
          ),
          const SizedBox(height: 24),
          _buildTabBar(),
        ],
      ),
    );
  }

  Widget _buildDesktopControls() {
    return Row(
      children: [
        _buildTimeRangeSelector(),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _exportReport,
          icon: const Icon(Icons.download),
          label: const Text('Eksport'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.surfaceCard,
            foregroundColor: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<int>(
        value: _selectedTimeRange,
        underline: const SizedBox(),
        style: const TextStyle(color: AppTheme.primaryColor),
        dropdownColor: AppTheme.surfaceCard,
        items: const [
          DropdownMenuItem(value: 1, child: Text('1 miesiąc')),
          DropdownMenuItem(value: 3, child: Text('3 miesiące')),
          DropdownMenuItem(value: 6, child: Text('6 miesięcy')),
          DropdownMenuItem(value: 12, child: Text('12 miesięcy')),
          DropdownMenuItem(value: 24, child: Text('24 miesiące')),
          DropdownMenuItem(value: -1, child: Text('Cały okres')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedTimeRange = value);
          }
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _isTablet
          ? Row(
              children: _tabs
                  .map((tab) => Expanded(child: _buildTabButton(tab)))
                  .toList(),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tabs
                    .map((tab) => _buildTabButton(tab, isExpanded: false))
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildTabButton(_TabInfo tab, {bool isExpanded = true}) {
    final isSelected = _selectedAnalyticsTab == tab.id;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isExpanded ? null : 120,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedAnalyticsTab = tab.id),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 12,
              horizontal: isExpanded ? 8 : 16,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tab.icon,
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  tab.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedAnalyticsTab) {
      case 'overview':
        return OverviewTab(selectedTimeRange: _selectedTimeRange);
      case 'performance':
        return PerformanceTab(selectedTimeRange: _selectedTimeRange);
      case 'risk':
        return RiskTab(selectedTimeRange: _selectedTimeRange);
      case 'employees':
        return EmployeesTab(selectedTimeRange: _selectedTimeRange);
      case 'geographic':
        return GeographicTab(selectedTimeRange: _selectedTimeRange);
      case 'trends':
        return TrendsTab(selectedTimeRange: _selectedTimeRange);
      default:
        return OverviewTab(selectedTimeRange: _selectedTimeRange);
    }
  }

  Widget _buildRefreshFab() {
    return FloatingActionButton(
      onPressed: _refreshCurrentTab,
      backgroundColor: AppTheme.primaryColor,
      child: const Icon(Icons.refresh),
    );
  }

  void _refreshCurrentTab() {
    // Trigger refresh for current tab
    setState(() {
      // Force rebuild with new timestamp to trigger refresh
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Odświeżanie danych dla taba: ${_getTabName(_selectedAnalyticsTab)}',
        ),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getTabName(String tabId) {
    final tab = _tabs.firstWhere(
      (tab) => tab.id == tabId,
      orElse: () => _TabInfo(tabId, 'Nieznany', Icons.help),
    );
    return tab.label;
  }

  void _exportReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eksport raportu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Wybierz format eksportu:'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _exportToPDF(),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _exportToExcel(),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Excel'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _exportToCSV(),
                  icon: const Icon(Icons.text_snippet),
                  label: const Text('CSV'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
        ],
      ),
    );
  }

  void _exportToPDF() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eksport do PDF - funkcja w przygotowaniu'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _exportToExcel() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eksport do Excel - funkcja w przygotowaniu'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _exportToCSV() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eksport do CSV - funkcja w przygotowaniu'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}

class _TabInfo {
  final String id;
  final String label;
  final IconData icon;

  const _TabInfo(this.id, this.label, this.icon);
}
