import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme_professional.dart';
import '../providers/auth_provider.dart';

// Import wszystkich tabów
import 'analytics/tabs/overview_tab.dart';
import 'analytics/tabs/performance_tab.dart';
import 'analytics/tabs/risk_tab.dart';
import 'analytics/tabs/employees_tab.dart';
import 'analytics/tabs/geographic_tab.dart';
import 'analytics/tabs/trends_tab.dart';

// RBAC: wspólny tooltip dla braku uprawnień
const String kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

/// 🚀 PROFESSIONAL ANALYTICS SCREEN
/// Completely redesigned with professional theme and modular components
/// Uses AppThemePro for maximum readability and professional appearance
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
  String _selectedAnalyticsTab = 'overview';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // RBAC getter
  bool get canEdit => Provider.of<AuthProvider>(context, listen: false).isAdmin;

  // Responsive breakpoints
  bool get _isTablet => MediaQuery.of(context).size.width > 768;

  // Tab definitions
  final List<_TabInfo> _tabs = [
    _TabInfo('overview', 'Przegląd', Icons.dashboard),
    _TabInfo('performance', 'Wydajność', Icons.trending_up),
    _TabInfo('risk', 'Ryzyko', Icons.warning_amber),
    _TabInfo('employees', 'Pracownicy', Icons.people),
    _TabInfo('geography', 'Geografia', Icons.map),
    _TabInfo('trends', 'Trendy', Icons.analytics),
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
      backgroundColor: AppThemePro.backgroundPrimary,
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppThemePro.primaryDark, AppThemePro.primaryMedium],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                          ?.copyWith(
                            color: AppThemePro.textPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kompleksowa analiza w czasie rzeczywistym z Firebase',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppThemePro.textSecondary,
                        height: 1.5,
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
        Tooltip(
          message: canEdit ? 'Eksportuj raport' : kRbacNoPermissionTooltip,
          child: ElevatedButton.icon(
            onPressed: canEdit ? _exportReport : null,
            icon: Icon(Icons.download, color: canEdit ? AppThemePro.primaryDark : Colors.grey),
            label: Text(
              'Eksport',
              style: TextStyle(color: canEdit ? AppThemePro.primaryDark : Colors.grey),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemePro.accentGold,
              foregroundColor: AppThemePro.primaryDark,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: AppThemePro.elevatedSurfaceDecoration,
      child: DropdownButton<int>(
        value: _selectedTimeRange,
        underline: const SizedBox(),
        style: TextStyle(color: AppThemePro.textPrimary, fontSize: 14),
        dropdownColor: AppThemePro.surfaceCard,
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
      decoration: AppThemePro.elevatedSurfaceDecoration,
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
      duration: const Duration(milliseconds: 300),
      width: isExpanded ? null : 120,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedAnalyticsTab = tab.id),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 16,
              horizontal: isExpanded ? 12 : 16,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppThemePro.accentGold : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? null
                  : Border.all(color: AppThemePro.borderPrimary, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tab.icon,
                  color: isSelected
                      ? AppThemePro.primaryDark
                      : AppThemePro.accentGold,
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  tab.label,
                  style: TextStyle(
                    color: isSelected
                        ? AppThemePro.primaryDark
                        : AppThemePro.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                    letterSpacing: 0.2,
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
    return Tooltip(
      message: canEdit ? 'Odśwież dane' : kRbacNoPermissionTooltip,
      child: FloatingActionButton.extended(
        onPressed: canEdit ? _refreshCurrentTab : null,
        backgroundColor: canEdit ? AppThemePro.accentGold : Colors.grey,
        foregroundColor: AppThemePro.primaryDark,
        elevation: 4,
        icon: const Icon(Icons.refresh),
        label: const Text('Odśwież'),
      ),
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
          style: const TextStyle(color: AppThemePro.textPrimary),
        ),
        backgroundColor: AppThemePro.accentGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        backgroundColor: AppThemePro.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Eksport raportu',
          style: TextStyle(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Wybierz format eksportu:',
              style: TextStyle(color: AppThemePro.textSecondary),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              children: [
                _buildExportButton(
                  'PDF',
                  Icons.picture_as_pdf,
                  AppThemePro.statusError,
                  _exportToPDF,
                ),
                _buildExportButton(
                  'Excel',
                  Icons.table_chart,
                  AppThemePro.statusSuccess,
                  _exportToExcel,
                ),
                _buildExportButton(
                  'CSV',
                  Icons.text_snippet,
                  AppThemePro.statusWarning,
                  _exportToCSV,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Anuluj',
              style: TextStyle(color: AppThemePro.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _exportToPDF() {
    Navigator.of(context).pop();
    _showExportMessage('Eksport do PDF - funkcja w przygotowaniu');
  }

  void _exportToExcel() {
    Navigator.of(context).pop();
    _showExportMessage('Eksport do Excel - funkcja w przygotowaniu');
  }

  void _exportToCSV() {
    Navigator.of(context).pop();
    _showExportMessage('Eksport do CSV - funkcja w przygotowaniu');
  }

  void _showExportMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppThemePro.textPrimary),
        ),
        backgroundColor: AppThemePro.statusInfo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
