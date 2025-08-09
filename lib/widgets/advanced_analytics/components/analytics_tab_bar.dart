import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// 🎯 ANALYTICS TAB BAR COMPONENT
/// Responsive tab bar for analytics sections
class AnalyticsTabBar extends StatelessWidget {
  final String selectedTab;
  final Function(String) onTabChanged;
  final bool isTablet;

  const AnalyticsTabBar({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    this.isTablet = false,
  });

  static const List<AnalyticsTab> _tabs = [
    AnalyticsTab(id: 'overview', label: 'Przegląd', icon: Icons.dashboard),
    AnalyticsTab(id: 'performance', label: 'Wydajność', icon: Icons.trending_up),
    AnalyticsTab(id: 'risk', label: 'Ryzyko', icon: Icons.security),
    AnalyticsTab(id: 'employees', label: 'Pracownicy', icon: Icons.people),
    AnalyticsTab(id: 'geographic', label: 'Geografia', icon: Icons.map),
    AnalyticsTab(id: 'trends', label: 'Trendy', icon: Icons.timeline),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: _tabs.map((tab) => Expanded(
        child: _buildTabButton(tab),
      )).toList(),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tabs.map((tab) => _buildTabButton(tab, isExpanded: false)).toList(),
      ),
    );
  }

  Widget _buildTabButton(AnalyticsTab tab, {bool isExpanded = true}) {
    final isSelected = selectedTab == tab.id;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isExpanded ? null : 120,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTabChanged(tab.id),
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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    tab.icon,
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tab.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnalyticsTab {
  final String id;
  final String label;
  final IconData icon;

  const AnalyticsTab({
    required this.id,
    required this.label,
    required this.icon,
  });
}