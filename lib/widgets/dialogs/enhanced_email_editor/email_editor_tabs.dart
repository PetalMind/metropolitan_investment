import 'package:flutter/material.dart';
import '../../../theme/app_theme_professional.dart';

class EmailEditorTabs extends StatelessWidget {
  final TabController tabController;
  final bool isMobile;
  final bool isSmallScreen;

  const EmailEditorTabs({
    super.key,
    required this.tabController,
    required this.isMobile,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        border: Border(
          bottom: BorderSide(color: AppThemePro.borderPrimary),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: TabBar(
          controller: tabController,
        tabs: [
          _buildTab(
            icon: Icons.edit,
            label: isMobile ? 'Edytor' : 'Edytor wiadomości',
          ),
          _buildTab(
            icon: Icons.settings,
            label: isMobile ? 'Ustawienia' : 'Ustawienia i szablony',
          ),
          _buildTab(
            icon: Icons.preview,
            label: isMobile ? 'Podgląd' : 'Podgląd wiadomości',
          ),
        ],
        labelColor: AppThemePro.accentGold,
        unselectedLabelColor: AppThemePro.textSecondary,
        indicatorColor: AppThemePro.accentGold,
        indicatorWeight: 3.0,
        labelStyle: TextStyle(
          fontSize: isMobile ? 12 : 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: isMobile ? 12 : 14,
          fontWeight: FontWeight.w500,
        ),
        ),
      ),
    );
  }

  Tab _buildTab({required IconData icon, required String label}) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 16 : 18),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            Text(label),
          ] else ...[
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}