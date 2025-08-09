import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../config/app_routes.dart';

/// Główny layout aplikacji z nawigacją boczną
class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isRailExtended = false;
  bool _showQuickActions = false;

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final selectedIndex = MainNavigationItems.getActiveIndex(currentLocation);
    final isTablet = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Row(
        children: [
          // Boczna nawigacja
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              final route = MainNavigationItems.items[index].route;
              context.go(route);
            },
            extended: _isRailExtended,
            minExtendedWidth: 220,
            leading: _buildRailHeader(),
            trailing: _buildRailTrailing(),
            destinations: MainNavigationItems.items.map((item) {
              return NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon ?? item.icon),
                label: Text(item.label),
              );
            }).toList(),
            backgroundColor: AppTheme.backgroundSecondary,
            selectedIconTheme: IconThemeData(
              color: AppTheme.secondaryGold,
              size: 28,
            ),
            unselectedIconTheme: IconThemeData(
              color: AppTheme.textTertiary,
              size: 24,
            ),
            selectedLabelTextStyle: TextStyle(
              color: AppTheme.secondaryGold,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 12,
            ),
            useIndicator: true,
            indicatorColor: AppTheme.secondaryGold.withOpacity(0.1),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),

          // Separator
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: AppTheme.borderSecondary.withOpacity(0.3),
          ),

          // Główna zawartość
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: Container(
                key: ValueKey(currentLocation),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),

      // Floating Action Button dla szybkich akcji
      floatingActionButton: isTablet ? _buildQuickActionsFAB() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Buduje nagłówek nawigacji z logo
  Widget _buildRailHeader() {
    return Column(
      children: [
        const SizedBox(height: 16),

        // Logo aplikacji
        GestureDetector(
          onTap: () => context.go(AppRoutes.dashboard),
          child: Container(
            width: _isRailExtended ? 80.0 : 60.0,
            height: _isRailExtended ? 80.0 : 60.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                (_isRailExtended ? 80.0 : 60.0) * 0.2,
              ),
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: EdgeInsets.all((_isRailExtended ? 80.0 : 60.0) * 0.1),
            child: Image.asset(
              'assets/logos/logo.png',
              width: (_isRailExtended ? 80.0 : 60.0) * 0.8,
              height: (_isRailExtended ? 80.0 : 60.0) * 0.8,
              fit: BoxFit.contain,
            ),
          ),
        ),

        // Nazwa aplikacji (gdy nawigacja rozwinięta)
        if (_isRailExtended) ...[
          const SizedBox(height: 12),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isRailExtended ? 1.0 : 0.0,
            child: Column(
              children: [
                Text(
                  'METROPOLITAN',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1.2,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'INVESTMENT',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.secondaryGold,
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                    letterSpacing: 0.8,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  /// Buduje dolną część nawigacji z kontrolkami
  Widget _buildRailTrailing() {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Przycisk rozwijania nawigacji
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() => _isRailExtended = !_isRailExtended);
                  },
                  icon: Icon(
                    _isRailExtended ? Icons.chevron_left : Icons.chevron_right,
                    color: AppTheme.textSecondary,
                  ),
                  tooltip: _isRailExtended ? 'Zwiń menu' : 'Rozwiń menu',
                ),
              ),

              const SizedBox(height: 12),

              // Menu użytkownika
              _buildUserMenu(),
            ],
          ),
        ),
      ),
    );
  }

  /// Buduje menu użytkownika
  Widget _buildUserMenu() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return PopupMenuButton<String>(
          onSelected: (value) => _handleUserMenuAction(value, authProvider),
          itemBuilder: (context) => [
            // Informacje o użytkowniku
            PopupMenuItem(
              enabled: false,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        _getUserInitial(authProvider),
                        style: const TextStyle(
                          color: AppTheme.textOnPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authProvider.userProfile?.fullName ??
                                authProvider.user?.displayName ??
                                'Użytkownik',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            authProvider.user?.email ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const PopupMenuDivider(),

            // Profil
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline),
                  SizedBox(width: 12),
                  Text('Profil użytkownika'),
                ],
              ),
            ),

            // Ustawienia
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined),
                  SizedBox(width: 12),
                  Text('Ustawienia'),
                ],
              ),
            ),

            // Powiadomienia
            const PopupMenuItem(
              value: 'notifications',
              child: Row(
                children: [
                  Icon(Icons.notifications_outlined),
                  SizedBox(width: 12),
                  Text('Powiadomienia'),
                ],
              ),
            ),

            // Raporty
            const PopupMenuItem(
              value: 'reports',
              child: Row(
                children: [
                  Icon(Icons.assessment_outlined),
                  SizedBox(width: 12),
                  Text('Raporty'),
                ],
              ),
            ),

            const PopupMenuDivider(),

            // Wylogowanie
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: AppTheme.errorColor),
                  const SizedBox(width: 12),
                  Text(
                    'Wyloguj się',
                    style: TextStyle(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryGold.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.person,
              color: AppTheme.textOnSecondary,
              size: 20,
            ),
          ),
        );
      },
    );
  }

  /// Buduje FAB z szybkimi akcjami
  Widget _buildQuickActionsFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Szybkie akcje (gdy rozwinięte)
        if (_showQuickActions) ...[
          FloatingActionButton.small(
            onPressed: () => context.push(AppRoutes.addInvestment),
            heroTag: "add_investment",
            tooltip: 'Dodaj inwestycję',
            backgroundColor: AppTheme.successColor,
            child: const Icon(Icons.add_business),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            onPressed: () => context.push(AppRoutes.addClient),
            heroTag: "add_client",
            tooltip: 'Dodaj klienta',
            backgroundColor: AppTheme.infoColor,
            child: const Icon(Icons.person_add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            onPressed: () => context.go(AppRoutes.reports),
            heroTag: "reports",
            tooltip: 'Raporty',
            backgroundColor: AppTheme.warningColor,
            child: const Icon(Icons.assessment),
          ),
          const SizedBox(height: 16),
        ],

        // Główny FAB
        FloatingActionButton(
          onPressed: () {
            setState(() => _showQuickActions = !_showQuickActions);
          },
          backgroundColor: AppTheme.primaryColor,
          child: AnimatedRotation(
            turns: _showQuickActions ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  /// Obsługuje akcje menu użytkownika
  void _handleUserMenuAction(String action, AuthProvider authProvider) {
    switch (action) {
      case 'profile':
        context.go(AppRoutes.profile);
        break;
      case 'settings':
        context.go(AppRoutes.settings);
        break;
      case 'notifications':
        context.go(AppRoutes.notifications);
        break;
      case 'reports':
        context.go(AppRoutes.reports);
        break;
      case 'logout':
        _showLogoutDialog(authProvider);
        break;
    }
  }

  /// Pokazuje dialog wylogowania
  void _showLogoutDialog(AuthProvider authProvider) {
    bool clearRememberMe = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.backgroundModal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: AppTheme.errorColor),
              const SizedBox(width: 8),
              const Text('Wylogowanie'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Czy na pewno chcesz się wylogować?'),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: clearRememberMe,
                onChanged: (value) {
                  setState(() {
                    clearRememberMe = value ?? false;
                  });
                },
                title: const Text(
                  'Wyczyść zapisane dane logowania',
                  style: TextStyle(fontSize: 14),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: AppTheme.primaryColor,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authProvider.signOut(clearRememberMe: clearRememberMe);
                if (mounted) {
                  context.go(AppRoutes.login);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: AppTheme.textOnPrimary,
              ),
              child: const Text('Wyloguj'),
            ),
          ],
        ),
      ),
    );
  }

  /// Pobiera inicjał użytkownika
  String _getUserInitial(AuthProvider authProvider) {
    final firstName = authProvider.userProfile?.firstName;
    if (firstName != null && firstName.isNotEmpty) {
      return firstName.substring(0, 1).toUpperCase();
    }

    final email = authProvider.user?.email;
    if (email != null && email.isNotEmpty) {
      return email.substring(0, 1).toUpperCase();
    }

    return 'U';
  }
}
