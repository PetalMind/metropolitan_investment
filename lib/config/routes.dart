import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/investments_screen.dart';
import '../screens/clients_screen.dart';
import '../screens/products_screen.dart';
import '../screens/companies_screen.dart';
import '../screens/employees_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/investor_analytics_screen.dart';
import '../widgets/auth_wrapper.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class AppRoutes {
  static const String root = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String dashboard = '/dashboard';
  static const String investments = '/investments';
  static const String clients = '/clients';
  static const String products = '/products';
  static const String companies = '/companies';
  static const String employees = '/employees';
  static const String analytics = '/analytics';
  static const String investorAnalytics = '/investor-analytics';
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.root,
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isLoggedIn;
      final isLoading = authProvider.isLoading;
      final isInitializing = authProvider.isInitializing;

      // Jeśli ładuje się auth lub inicjalizuje, nie przekierowuj
      if (isLoading || isInitializing) return null;

      // Publiczne ścieżki dostępne bez logowania
      final publicPaths = [AppRoutes.login, AppRoutes.register];

      final isPublicPath = publicPaths.contains(state.matchedLocation);

      // Jeśli użytkownik nie jest zalogowany i nie jest na publicznej ścieżce
      if (!isAuthenticated && !isPublicPath) {
        return AppRoutes.login;
      }

      // Jeśli użytkownik jest zalogowany i jest na publicznej ścieżce
      if (isAuthenticated && isPublicPath) {
        return AppRoutes.main;
      }

      return null;
    },
    routes: [
      // Root route
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => const AuthWrapper(),
      ),

      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main application with shell layout
      ShellRoute(
        builder: (context, state, child) => MainScreenShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.main,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.investments,
            builder: (context, state) => const InvestmentsScreen(),
          ),
          GoRoute(
            path: AppRoutes.clients,
            builder: (context, state) => const ClientsScreen(),
          ),
          GoRoute(
            path: AppRoutes.products,
            builder: (context, state) => const ProductsScreen(),
          ),
          GoRoute(
            path: AppRoutes.companies,
            builder: (context, state) => const CompaniesScreen(),
          ),
          GoRoute(
            path: AppRoutes.employees,
            builder: (context, state) => const EmployeesScreen(),
          ),
          GoRoute(
            path: AppRoutes.analytics,
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: AppRoutes.investorAnalytics,
            builder: (context, state) => const InvestorAnalyticsScreen(),
          ),
        ],
      ),
    ],
  );
}

// Shell wrapper dla głównej aplikacji z nawigacją
class MainScreenShell extends StatelessWidget {
  final Widget child;

  const MainScreenShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MainScreenLayout(content: child);
  }
}

// Nowy layout dla głównego ekranu z nawigacją
class MainScreenLayout extends StatefulWidget {
  final Widget content;

  const MainScreenLayout({super.key, required this.content});

  @override
  State<MainScreenLayout> createState() => _MainScreenLayoutState();
}

class _MainScreenLayoutState extends State<MainScreenLayout> {
  bool _isRailExtended = false;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      route: AppRoutes.dashboard,
    ),
    NavigationItem(
      icon: MdiIcons.chartLine,
      label: 'Inwestycje',
      route: AppRoutes.investments,
    ),
    NavigationItem(
      icon: Icons.people,
      label: 'Klienci',
      route: AppRoutes.clients,
    ),
    NavigationItem(
      icon: MdiIcons.packageVariant,
      label: 'Produkty',
      route: AppRoutes.products,
    ),
    NavigationItem(
      icon: Icons.business,
      label: 'Spółki',
      route: AppRoutes.companies,
    ),
    NavigationItem(
      icon: Icons.person_outline,
      label: 'Pracownicy',
      route: AppRoutes.employees,
    ),
    NavigationItem(
      icon: Icons.analytics,
      label: 'Analityka',
      route: AppRoutes.analytics,
    ),
    NavigationItem(
      icon: MdiIcons.accountGroup,
      label: 'Inwestorzy',
      route: AppRoutes.investorAnalytics,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _getSelectedIndex(currentLocation);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              final route = _navigationItems[index].route;
              context.go(route);
            },
            extended: _isRailExtended,
            minExtendedWidth: 200,
            leading: _buildRailHeader(),
            trailing: _buildRailTrailing(),
            destinations: _navigationItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.icon, color: AppTheme.secondaryGold),
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
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: widget.content),
        ],
      ),
    );
  }

  Widget _buildRailHeader() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance,
            color: AppTheme.textOnPrimary,
            size: 32,
          ),
        ),
        if (_isRailExtended) ...[
          const SizedBox(height: 8),
          Text(
            'Metropolitan\nInvestment',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRailTrailing() {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  setState(() => _isRailExtended = !_isRailExtended);
                },
                icon: Icon(
                  _isRailExtended ? Icons.chevron_left : Icons.chevron_right,
                  color: AppTheme.textSecondary,
                ),
                tooltip: _isRailExtended ? 'Zwiń menu' : 'Rozwiń menu',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.surfaceElevated,
                  foregroundColor: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _buildUserMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserMenu() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'profile':
                _showProfileDialog(context);
                break;
              case 'settings':
                _showSettingsDialog(context);
                break;
              case 'logout':
                _handleLogout(context, authProvider);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  const Icon(Icons.person),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authProvider.userProfile?.fullName ??
                            authProvider.user?.displayName ??
                            'Użytkownik',
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Ustawienia'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Wyloguj'),
                ],
              ),
            ),
          ],
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryGold.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.person, color: AppTheme.textOnSecondary),
          ),
        );
      },
    );
  }

  int _getSelectedIndex(String location) {
    for (int i = 0; i < _navigationItems.length; i++) {
      final route = _navigationItems[i].route;
      if (location.startsWith(route)) {
        return i;
      }
    }
    return 0; // Default to dashboard
  }

  void _showProfileDialog(BuildContext context) {
    // Implementation for profile dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil użytkownika'),
        content: const Text('Funkcja profilu będzie dostępna wkrótce.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    // Implementation for settings dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ustawienia'),
        content: const Text('Funkcja ustawień będzie dostępna wkrótce.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context, AuthProvider authProvider) {
    bool clearRememberMe = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Wylogowanie'),
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
                if (context.mounted) {
                  // Force navigate to login and clear navigation stack
                  context.go(AppRoutes.login);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorPrimary,
                foregroundColor: AppTheme.textOnPrimary,
              ),
              child: const Text('Wyloguj'),
            ),
          ],
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
