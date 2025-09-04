import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme_professional.dart';
import 'settings/appearance_settings_tab.dart';
import 'settings/performance_settings_tab.dart';
import 'settings/data_diagnostics_tab.dart';
import 'settings/system_information_tab.dart';
import 'settings/admin_panel_tab.dart';
import 'settings/account_profile_tab.dart';

/// 🎨 Professional Responsive Settings Screen
/// Completely redesigned with premium UX, adaptive layouts, and sophisticated animations
class ResponsiveSettingsScreen extends StatefulWidget {
  const ResponsiveSettingsScreen({super.key});

  @override
  State<ResponsiveSettingsScreen> createState() =>
      _ResponsiveSettingsScreenState();
}

class _ResponsiveSettingsScreenState extends State<ResponsiveSettingsScreen>
    with TickerProviderStateMixin {
  int _selectedTabIndex = 0;
  late AnimationController _animationController;
  late AnimationController _fabController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    _fabController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  List<ResponsiveSettingsTab> get _tabs {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    List<ResponsiveSettingsTab> tabs = [
      ResponsiveSettingsTab(
        id: 'account',
        title: 'Profil użytkownika',
        icon: Icons.person_rounded,
        description: 'Personalizacja konta i preferencje',
        color: AppThemePro.statusInfo,
        content: const AccountProfileTab(),
      ),

      ResponsiveSettingsTab(
        id: 'system',
        title: 'Informacje systemowe',
        icon: Icons.info_rounded,
        description: 'Konfiguracja techniczna i status',
        color: AppThemePro.neutralGray,
        content: const SystemInformationTab(),
      ),
    ];

    if (isAdmin) {
      tabs.add(
        ResponsiveSettingsTab(
          id: 'admin',
          title: 'Panel administratora',
          icon: Icons.admin_panel_settings_rounded,
          description: 'Zarządzanie użytkownikami i rolami',
          color: AppThemePro.lossRed,
          content: const AdminPanelTab(),
          premium: true,
          adminOnly: true,
        ),
      );
    }

    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 1200;
        final isMediumScreen = constraints.maxWidth > 800;
        final isMobile = constraints.maxWidth <= 600;

        return Scaffold(
          backgroundColor: AppThemePro.backgroundPrimary,
          body: FadeTransition(
            opacity: _fadeInAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildResponsiveLayout(
                isWideScreen,
                isMediumScreen,
                isMobile,
              ),
            ),
          ),
          floatingActionButton: isMobile ? _buildFloatingActionButton() : null,
        );
      },
    );
  }

  Widget _buildResponsiveLayout(
    bool isWideScreen,
    bool isMediumScreen,
    bool isMobile,
  ) {
    if (isMobile) {
      return _buildMobileLayout();
    } else if (isMediumScreen) {
      return _buildTabletLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  // === MOBILE LAYOUT ===
  Widget _buildMobileLayout() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final tab = _tabs[index];
              return _buildMobileSettingCard(tab, index);
            }, childCount: _tabs.length),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // === TABLET LAYOUT ===
  Widget _buildTabletLayout() {
    return Column(
      children: [
        _buildResponsiveAppBar(),
        Expanded(
          child: Row(
            children: [
              _buildSideNavigation(width: 280),
              Expanded(child: _buildTabContent()),
            ],
          ),
        ),
      ],
    );
  }

  // === DESKTOP LAYOUT ===
  Widget _buildDesktopLayout() {
    return Column(
      children: [
        _buildResponsiveAppBar(),
        Expanded(
          child: Row(
            children: [
              _buildSideNavigation(width: 320),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  child: _buildTabContent(),
                ),
              ),
              _buildQuickActions(),
            ],
          ),
        ),
      ],
    );
  }

  // === APP BAR COMPONENTS ===
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppThemePro.backgroundPrimary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Ustawienia',
          style: TextStyle(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppThemePro.primaryDark,
                AppThemePro.primaryMedium.withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Icon(
                  Icons.settings_rounded,
                  size: 120,
                  color: AppThemePro.accentGold.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveAppBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppThemePro.backgroundPrimary,
        border: Border(
          bottom: BorderSide(color: AppThemePro.borderPrimary, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppThemePro.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.settings_rounded,
                color: AppThemePro.accentGold,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ustawienia aplikacji',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Personalizuj swoją przestrzeń roboczą',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
                ),
              ],
            ),
            const Spacer(),
            _buildUserAvatar(),
          ],
        ),
      ),
    );
  }

  // === NAVIGATION COMPONENTS ===
  Widget _buildSideNavigation({required double width}) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        border: Border(
          right: BorderSide(color: AppThemePro.borderPrimary, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildNavigationHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tabs.length,
              itemBuilder: (context, index) => _buildNavigationItem(index),
            ),
          ),
          _buildNavigationFooter(),
        ],
      ),
    );
  }

  Widget _buildNavigationHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppThemePro.accentGold.withOpacity(0.1),
                  AppThemePro.accentGoldMuted.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: AppThemePro.accentGold,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Centrum kontroli',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Zarządzaj wszystkimi aspektami aplikacji',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(int index) {
    final tab = _tabs[index];
    final isSelected = index == _selectedTabIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectTab(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? tab.color.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? tab.color.withOpacity(0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? tab.color.withOpacity(0.2)
                        : AppThemePro.surfaceInteractive,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    tab.icon,
                    color: isSelected ? tab.color : AppThemePro.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tab.title,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: isSelected
                                        ? AppThemePro.textPrimary
                                        : AppThemePro.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                            ),
                          ),
                          if (tab.premium)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppThemePro.accentGold,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PRO',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppThemePro.primaryDark,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      if (tab.description.isNotEmpty)
                        Text(
                          tab.description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppThemePro.textMuted,
                                fontSize: 11,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppThemePro.borderPrimary, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildQuickActionButton(
            icon: Icons.logout_rounded,
            label: 'Wyloguj się',
            onTap: () => _logout(),
            color: AppThemePro.lossRed,
          ),
        ],
      ),
    );
  }

  // === MOBILE SPECIFIC COMPONENTS ===
  Widget _buildMobileSettingCard(ResponsiveSettingsTab tab, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _navigateToTab(tab),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppThemePro.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppThemePro.borderPrimary, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tab.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(tab.icon, color: tab.color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tab.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppThemePro.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            if (tab.premium)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppThemePro.accentGold,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'PREMIUM',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppThemePro.primaryDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppThemePro.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppThemePro.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabController,
      child: FloatingActionButton.extended(
        onPressed: () => _showQuickSettings(),
        backgroundColor: AppThemePro.accentGold,
        foregroundColor: AppThemePro.primaryDark,
        icon: const Icon(Icons.tune_rounded),
        label: const Text(
          'Szybkie ustawienia',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // === CONTENT AREA ===
  Widget _buildTabContent() {
    return Container(
      decoration: BoxDecoration(
        color: AppThemePro.backgroundPrimary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(_selectedTabIndex),
            padding: const EdgeInsets.all(24),
            child: _tabs[_selectedTabIndex].content,
          ),
        ),
      ),
    );
  }

  // === QUICK ACTIONS PANEL ===
  Widget _buildQuickActions() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary,
        border: Border(
          left: BorderSide(color: AppThemePro.borderPrimary, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildQuickActionsHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildQuickActionCard('Szybkie akcje', [
                  _buildQuickActionButton(
                    icon: Icons.refresh_rounded,
                    label: 'Odśwież dane',
                    onTap: () => _refreshData(),
                  ),
                  _buildQuickActionButton(
                    icon: Icons.download_rounded,
                    label: 'Eksportuj ustawienia',
                    onTap: () => _exportSettings(),
                  ),
                  _buildQuickActionButton(
                    icon: Icons.upload_rounded,
                    label: 'Importuj ustawienia',
                    onTap: () => _importSettings(),
                  ),
                ]),
                const SizedBox(height: 16),
                _buildQuickActionCard('Skróty klawiszowe', [
                  _buildKeyboardShortcut('Ctrl + S', 'Zapisz ustawienia'),
                  _buildKeyboardShortcut('Ctrl + R', 'Odśwież'),
                  _buildKeyboardShortcut('Ctrl + E', 'Eksportuj'),
                  _buildKeyboardShortcut('Esc', 'Zamknij dialog'),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppThemePro.borderPrimary, width: 1),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.flash_on_rounded, color: AppThemePro.accentGold, size: 32),
          const SizedBox(height: 8),
          Text(
            'Szybkie akcje',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Najczęściej używane funkcje',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: color ?? AppThemePro.textSecondary, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color ?? AppThemePro.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboardShortcut(String shortcut, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppThemePro.surfaceInteractive,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppThemePro.borderSecondary, width: 1),
            ),
            child: Text(
              shortcut,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppThemePro.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  // === UTILITY WIDGETS ===
  Widget _buildUserAvatar() {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppThemePro.accentGold, AppThemePro.accentGoldMuted],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppThemePro.backgroundSecondary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppThemePro.accentGold.withOpacity(0.1),
                  child: Text(
                    (auth.user?.email?.substring(0, 1).toUpperCase() ?? 'U'),
                    style: TextStyle(
                      color: AppThemePro.accentGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.user?.email?.split('@').first ?? 'Użytkownik',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppThemePro.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      auth.isAdmin ? 'Administrator' : 'Użytkownik',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: auth.isAdmin
                            ? AppThemePro.accentGold
                            : AppThemePro.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // === EVENT HANDLERS ===
  void _selectTab(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _navigateToTab(ResponsiveSettingsTab tab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(tab.title),
            backgroundColor: AppThemePro.backgroundPrimary,
          ),
          backgroundColor: AppThemePro.backgroundPrimary,
          body: Padding(padding: const EdgeInsets.all(16), child: tab.content),
        ),
      ),
    );
  }

  void _showQuickSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppThemePro.backgroundSecondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppThemePro.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Szybkie ustawienia',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            // Quick settings content would go here
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showHelp() {
    // Implement help dialog
  }

  void _logout() async {
    await Provider.of<AuthProvider>(context, listen: false).signOut();
  }

  void _refreshData() {
    // Implement data refresh
  }

  void _exportSettings() {
    // Implement settings export
  }

  void _importSettings() {
    // Implement settings import
  }
}

// === TAB MODEL ===
class ResponsiveSettingsTab {
  final String id;
  final String title;
  final IconData icon;
  final String description;
  final Color color;
  final Widget content;
  final bool premium;
  final bool adminOnly;

  const ResponsiveSettingsTab({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.color,
    required this.content,
    this.premium = false,
    this.adminOnly = false,
  });
}

// === TAB CONTENT IMPLEMENTATIONS ===

class CapitalCalculationTab extends StatefulWidget {
  const CapitalCalculationTab({super.key});

  @override
  State<CapitalCalculationTab> createState() => _CapitalCalculationTabState();
}

class _CapitalCalculationTabState extends State<CapitalCalculationTab>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildAnalyticsGrid(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
            _buildCalculationProgress(),
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
            AppThemePro.accentGold.withOpacity(0.1),
            AppThemePro.accentGoldMuted.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.accentGold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemePro.accentGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calculate_rounded,
              color: AppThemePro.accentGold,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Centrum obliczeń kapitału',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Zaawansowane algorytmy finansowe dla analiz kapitału zabezpieczonego nieruchomością',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppThemePro.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildAnalyticsCard(
              'Inwestycje aktywne',
              '2,847',
              Icons.trending_up_rounded,
              AppThemePro.profitGreen,
              '+12.5%',
            ),
            _buildAnalyticsCard(
              'Wymaga aktualizacji',
              '184',
              Icons.update_rounded,
              AppThemePro.statusWarning,
              '6.5%',
            ),
            _buildAnalyticsCard(
              'Kompletność danych',
              '94.2%',
              Icons.analytics_rounded,
              AppThemePro.statusInfo,
              '+2.1%',
            ),
            _buildAnalyticsCard(
              'Poprawność obliczeń',
              '98.7%',
              Icons.verified_rounded,
              AppThemePro.accentGold,
              '+0.3%',
            ),
          ],
        );
      },
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
      decoration: AppThemePro.premiumCardDecoration.copyWith(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.05), color.withOpacity(0.02)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppThemePro.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Sprawdź status',
                  Icons.analytics,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  'Uruchom test',
                  Icons.science,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  'Aktualizuj bazę',
                  Icons.update,
                  Colors.green,
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildActionButton(
                'Sprawdź status',
                Icons.analytics,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildActionButton('Uruchom test', Icons.science, Colors.orange),
              const SizedBox(height: 12),
              _buildActionButton('Aktualizuj bazę', Icons.update, Colors.green),
            ],
          );
        }
      },
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color) {
    return Container(
      height: 80,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationProgress() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline_rounded,
                color: AppThemePro.accentGold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Progress obliczeń',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressItem('Obligacje', 0.87, AppThemePro.bondsBlue),
          const SizedBox(height: 12),
          _buildProgressItem('Udziały', 0.92, AppThemePro.sharesGreen),
          const SizedBox(height: 12),
          _buildProgressItem('Pożyczki', 0.78, AppThemePro.loansOrange),
          const SizedBox(height: 12),
          _buildProgressItem('Apartamenty', 0.95, AppThemePro.realEstateViolet),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemePro.textSecondary,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppThemePro.surfaceInteractive,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
