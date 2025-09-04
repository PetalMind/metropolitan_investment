import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../screens/premium_investor_analytics_screen.dart';
import '../screens/calendar_screen_enhanced.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/enhanced_clients_screen.dart';
import '../screens/products_management_screen.dart'; // ✅ POWRÓT: Do oryginalnego ekranu z nowymi serwisami
import '../screens/employees_screen.dart';
import '../screens/product_dashboard_screen.dart';
import '../widgets/auth_wrapper.dart';
import '../widgets/main_layout.dart';
import '../examples/redesigned_dialog_example.dart';
import '../providers/auth_provider.dart';
import '../screens/settings/smtp_settings_screen.dart';
import '../screens/settings_screen_responsive.dart';
import '../screens/settings_demo.dart';
import '../theme/app_theme.dart';

/// Klasa definiująca wszystkie trasy aplikacji
class AppRoutes {
  // === PUBLICZNE TRASY ===
  static const String root = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // === GŁÓWNE SEKCJE ===
  static const String dashboard = '/dashboard';
  static const String investments = '/investments';
  static const String clients = '/clients';
  static const String products = '/products';
  static const String companies = '/companies';
  static const String employees = '/employees';
  static const String investorAnalytics = '/investor-analytics';
  static const String calendar = '/calendar';
  static const String unifiedProducts = '/unified-products';
  static const String productDashboard = '/product-dashboard';

  // === SZCZEGÓŁOWE WIDOKI ===
  static const String investmentDetails = '/investments/:id';
  static const String addInvestment = '/investments/add';
  static const String editInvestment = '/investments/:id/edit';

  static const String clientDetails = '/clients/:id';
  static const String addClient = '/clients/add';
  static const String editClient = '/clients/:id/edit';

  static const String productDetails = '/products/:id';
  static const String addProduct = '/products/add';
  static const String editProduct = '/products/:id/edit';

  static const String companyDetails = '/companies/:id';
  static const String addCompany = '/companies/add';
  static const String editCompany = '/companies/:id/edit';

  static const String employeeDetails = '/employees/:id';
  static const String addEmployee = '/employees/add';
  static const String editEmployee = '/employees/:id/edit';

  // === DODATKOWE FUNKCJONALNOŚCI ===
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String smtpSettings = '/settings/smtp';
  static const String settingsDemo =
      '/settings/demo'; // 🎨 NEW: Settings demo route
  static const String reports = '/reports';
  static const String notifications = '/notifications';
  static const String testDialog = '/test-dialog';

  // === POMOCNICZE METODY ===

  /// Generuje ścieżkę do szczegółów inwestycji
  static String investmentDetailsPath(String id) => '/investments/$id';

  /// Generuje ścieżkę do edycji inwestycji
  static String editInvestmentPath(String id) => '/investments/$id/edit';

  /// Generuje ścieżkę do szczegółów klienta
  static String clientDetailsPath(String id) => '/clients/$id';

  /// Generuje ścieżkę do edycji klienta
  static String editClientPath(String id) => '/clients/$id/edit';

  /// Generuje ścieżkę do szczegółów produktu
  static String productDetailsPath(String id) => '/products/$id';

  /// Generuje ścieżkę do szczegółów spółki
  static String companyDetailsPath(String id) => '/companies/$id';

  /// Generuje ścieżkę do szczegółów pracownika
  static String employeeDetailsPath(String id) => '/employees/$id';

  /// Generuje ścieżkę do demo ustawień
  static String settingsDemoPath() => '/settings/demo';

  /// Lista tras publicznych (dostępnych bez autoryzacji)
  static const List<String> publicRoutes = [
    root,
    login,
    register,
    forgotPassword,
  ];

  /// Sprawdza czy trasa jest publiczna
  static bool isPublicRoute(String route) {
    // Dokładne dopasowanie tras publicznych
    if (route == root ||
        route == login ||
        route == register ||
        route == forgotPassword) {
      return true;
    }
    return false;
  }
}

/// Klasa definiująca elementy nawigacji
class NavigationItem {
  final String route;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String? badge;
  final List<String>? subRoutes;
  final bool requiresPermission;
  final String? permission;

  const NavigationItem({
    required this.route,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badge,
    this.subRoutes,
    this.requiresPermission = false,
    this.permission,
  });

  /// Sprawdza czy element nawigacji jest aktywny dla danej trasy
  bool isActiveForRoute(String currentRoute) {
    if (currentRoute == route) return true;
    if (subRoutes != null) {
      return subRoutes!.any((subRoute) => currentRoute.startsWith(subRoute));
    }
    return currentRoute.startsWith(route);
  }
}

/// Definicja elementów nawigacji głównej
class MainNavigationItems {
  static final List<NavigationItem> items = [
    NavigationItem(
      route: AppRoutes.dashboard,
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    NavigationItem(
      route: AppRoutes.clients,
      label: 'Klienci',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      subRoutes: [AppRoutes.clients, '/clients/'],
    ),
    NavigationItem(
      route: AppRoutes.products,
      label: 'Produkty',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      subRoutes: [AppRoutes.products, '/products/'],
    ),
    NavigationItem(
      route: AppRoutes.employees,
      label: 'Pracownicy',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      subRoutes: [AppRoutes.employees, '/employees/'],
    ),
    NavigationItem(
      route: AppRoutes.investorAnalytics,
      label: 'Analiza Inwestorów',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.group,
    ),

    NavigationItem(
      route: AppRoutes.calendar,
      label: 'Kalendarz',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
    ),
  ];

  /// Zwraca indeks aktywnego elementu nawigacji
  static int getActiveIndex(String currentRoute) {
    for (int i = 0; i < items.length; i++) {
      if (items[i].isActiveForRoute(currentRoute)) {
        return i;
      }
    }
    return 0; // Domyślnie dashboard
  }

  /// Zwraca aktywny element nawigacji
  static NavigationItem? getActiveItem(String currentRoute) {
    for (final item in items) {
      if (item.isActiveForRoute(currentRoute)) {
        return item;
      }
    }
    return items.first; // Domyślnie dashboard
  }
}

/// Klasa konfigurująca router aplikacji
class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation:
        AppRoutes.root, // Zamiast dashboard - lepiej zacząć od root
    debugLogDiagnostics: true,

    // Funkcja przekierowań na podstawie stanu autoryzacji
    redirect: (BuildContext context, GoRouterState state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isLoggedIn;
      final isLoading = authProvider.isLoading;
      final isInitializing = authProvider.isInitializing;
      final currentLocation = state.matchedLocation;

      // Podczas ładowania nie przekierowuj
      if (isLoading || isInitializing) {
        return null;
      }

      // Sprawdź czy trasa jest publiczna
      final isPublicRoute = AppRoutes.isPublicRoute(currentLocation);

      // Logika przekierowań
      if (!isAuthenticated && !isPublicRoute) {
        // Nie zalogowany użytkownik próbuje dostać się do chronionej sekcji
        return AppRoutes.login;
      }

      if (isAuthenticated && currentLocation == AppRoutes.root) {
        // Zalogowany użytkownik na root - przekieruj do dashboard
        return AppRoutes.dashboard;
      }

      if (isAuthenticated &&
          isPublicRoute &&
          currentLocation != AppRoutes.root) {
        // Zalogowany użytkownik próbuje dostać się do publicznej strony (nie root)
        return AppRoutes.dashboard;
      }

      return null; // Brak przekierowania
    },

    // Obsługa błędów routingu
    errorBuilder: (context, state) => _ErrorPage(
      error: state.error.toString(),
      location: state.matchedLocation,
    ),

    // Definicja tras
    routes: [
      // === ROOT ROUTE ===
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => const AuthWrapper(),
      ),

      // === PUBLICZNE TRASY ===
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const LoginScreen()),
      ),

      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) =>
            _buildPageWithTransition(context, state, const RegisterScreen()),
      ),

      // === GŁÓWNE SEKCJE (z Shell Layout) ===
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const ProductDashboardScreen(),
            ),
          ),

          // === KLIENCI ===
          GoRoute(
            path: AppRoutes.clients,
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const EnhancedClientsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                pageBuilder: (context, state) => _buildPageWithTransition(
                  context,
                  state,
                  const AddClientScreen(),
                ),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _buildPageWithTransition(
                  context,
                  state,
                  ClientDetailsScreen(clientId: state.pathParameters['id']!),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (context, state) => _buildPageWithTransition(
                      context,
                      state,
                      EditClientScreen(clientId: state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // === PRODUKTY ===
          GoRoute(
            path: AppRoutes.products,
            pageBuilder: (context, state) {
              // 🚀 NOWY REFACTORED SCREEN z ProductManagementService
              // Uwaga: Nowy ekran nie wymaga tych parametrów (ma własne wyszukiwanie)
              return _buildPageWithTransition(
                context,
                state,
                const ProductsManagementScreen(),
              );
            },
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _buildPageWithTransition(
                  context,
                  state,
                  ProductDetailsScreen(productId: state.pathParameters['id']!),
                ),
              ),
            ],
          ),

          // === PRACOWNICY ===
          GoRoute(
            path: AppRoutes.employees,
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const EmployeesScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _buildPageWithTransition(
                  context,
                  state,
                  EmployeeDetailsScreen(
                    employeeId: state.pathParameters['id']!,
                  ),
                ),
              ),
            ],
          ),

   

          GoRoute(
            path: AppRoutes.investorAnalytics,
            pageBuilder: (context, state) {
              final searchQuery = state.uri.queryParameters['search'];
              return _buildPageWithTransition(
                context,
                state,
                PremiumInvestorAnalyticsScreen(initialSearchQuery: searchQuery),
              );
            },
          ),

          // === KALENDARZ ===
          GoRoute(
            path: AppRoutes.calendar,
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const CalendarScreenEnhanced(),
            ),
          ),

          // === DODATKOWE SEKCJE ===
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) =>
                _buildPageWithTransition(context, state, const ProfileScreen()),
          ),

          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const ResponsiveSettingsScreen(), // 🎨 NEW: Amazing responsive settings!
            ),
            routes: [
              GoRoute(
                path: 'smtp',
                pageBuilder: (context, state) => _buildPageWithTransition(
                  context,
                  state,
                  const SmtpSettingsScreen(),
                ),
              ),
              GoRoute(
                path: 'demo',
                pageBuilder: (context, state) => _buildPageWithTransition(
                  context,
                  state,
                  const SettingsDemoScreen(), // 🚀 Settings showcase demo
                ),
              ),
            ],
          ),

          GoRoute(
            path: AppRoutes.reports,
            pageBuilder: (context, state) =>
                _buildPageWithTransition(context, state, const ReportsScreen()),
          ),

          GoRoute(
            path: AppRoutes.notifications,
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const NotificationsScreen(),
            ),
          ),

          // === TEST DIALOG ===
          GoRoute(
            path: AppRoutes.testDialog,
            pageBuilder: (context, state) => _buildPageWithTransition(
              context,
              state,
              const RedesignedDialogExample(),
            ),
          ),
        ],
      ),
    ],
  );

  /// Getter dla routera
  static GoRouter get router => _router;

  /// Buduje stronę z animacją przejścia
  static Page<void> _buildPageWithTransition(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide transition from right
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 200),
    );
  }
}

/// Strona błędu routingu
class _ErrorPage extends StatelessWidget {
  final String error;
  final String location;

  const _ErrorPage({required this.error, required this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.premiumCardDecoration.copyWith(
            border: Border.all(
              color: AppTheme.errorColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text(
                'Błąd Nawigacji',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nie można znaleźć strony: $location',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Szczegóły błędu:\n$error',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.dashboard),
                    icon: const Icon(Icons.home),
                    label: const Text('Powrót do Dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.textOnPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Wstecz'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rozszerzenia dla GoRouter
extension AppRouterExtensions on GoRouter {
  /// Nawiguje do szczegółów inwestycji
  void goToInvestmentDetails(String id) {
    go(AppRoutes.investmentDetailsPath(id));
  }

  /// Nawiguje do edycji inwestycji
  void goToEditInvestment(String id) {
    go(AppRoutes.editInvestmentPath(id));
  }

  /// Nawiguje do szczegółów klienta
  void goToClientDetails(String id) {
    go(AppRoutes.clientDetailsPath(id));
  }

  /// Nawiguje do edycji klienta
  void goToEditClient(String id) {
    go(AppRoutes.editClientPath(id));
  }

  /// Nawiguje do szczegółów produktu
  void goToProductDetails(String id) {
    go(AppRoutes.productDetailsPath(id));
  }

  /// Nawiguje do szczegółów spółki
  void goToCompanyDetails(String id) {
    go(AppRoutes.companyDetailsPath(id));
  }

  /// Nawiguje do szczegółów pracownika
  void goToEmployeeDetails(String id) {
    go(AppRoutes.employeeDetailsPath(id));
  }

  /// Nawiguje do demo ustawień
  void goToSettingsDemo() {
    go(AppRoutes.settingsDemoPath());
  }
}

/// Rozszerzenia dla BuildContext
extension BuildContextRouterExtensions on BuildContext {
  /// Nawiguje do szczegółów inwestycji
  void goToInvestmentDetails(String id) {
    go(AppRoutes.investmentDetailsPath(id));
  }

  /// Nawiguje do edycji inwestycji
  void goToEditInvestment(String id) {
    go(AppRoutes.editInvestmentPath(id));
  }

  /// Nawiguje do szczegółów klienta
  void goToClientDetails(String id) {
    go(AppRoutes.clientDetailsPath(id));
  }

  /// Nawiguje do edycji klienta
  void goToEditClient(String id) {
    go(AppRoutes.editClientPath(id));
  }

  /// Nawiguje do demo ustawień  
  void goToSettingsDemo() {
    go(AppRoutes.settingsDemoPath());
  }

  /// Sprawdza czy jesteśmy na danej trasie
  bool isCurrentRoute(String route) {
    final currentRoute = GoRouterState.of(this).matchedLocation;
    return currentRoute == route;
  }

  /// Sprawdza czy jesteśmy w sekcji (uwzględnia sub-routes)
  bool isInSection(String baseRoute) {
    final currentRoute = GoRouterState.of(this).matchedLocation;
    return currentRoute.startsWith(baseRoute);
  }
}

/// Placeholder screens (do implementacji)
class AddInvestmentScreen extends StatelessWidget {
  const AddInvestmentScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderScreen(title: 'Dodaj Inwestycję');
}

class EditInvestmentScreen extends StatelessWidget {
  final String investmentId;
  const EditInvestmentScreen({super.key, required this.investmentId});
  @override
  Widget build(BuildContext context) =>
      _PlaceholderScreen(title: 'Edytuj Inwestycję #$investmentId');
}

class InvestmentDetailsScreen extends StatelessWidget {
  final String investmentId;
  const InvestmentDetailsScreen({super.key, required this.investmentId});
  @override
  Widget build(BuildContext context) =>
      _PlaceholderScreen(title: 'Szczegóły Inwestycji #$investmentId');
}

class AddClientScreen extends StatelessWidget {
  const AddClientScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderScreen(title: 'Dodaj Klienta');
}

class EditClientScreen extends StatelessWidget {
  final String clientId;
  const EditClientScreen({super.key, required this.clientId});
  @override
  Widget build(BuildContext context) =>
      _PlaceholderScreen(title: 'Edytuj Klienta #$clientId');
}

class ClientDetailsScreen extends StatelessWidget {
  final String clientId;
  const ClientDetailsScreen({super.key, required this.clientId});
  @override
  Widget build(BuildContext context) =>
      _PlaceholderScreen(title: 'Szczegóły Klienta #$clientId');
}

class ProductDetailsScreen extends StatelessWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});
  @override
  Widget build(BuildContext context) =>
      _PlaceholderScreen(title: 'Szczegóły Produktu #$productId');
}

class CompanyDetailsScreen extends StatelessWidget {
  final String companyId;
  const CompanyDetailsScreen({super.key, required this.companyId});
  @override
  Widget build(BuildContext context) =>
      _PlaceholderScreen(title: 'Szczegóły Spółki #$companyId');
}

class EmployeeDetailsScreen extends StatelessWidget {
  final String employeeId;
  const EmployeeDetailsScreen({super.key, required this.employeeId});
  @override
  Widget build(BuildContext context) =>
      _PlaceholderScreen(title: 'Szczegóły Pracownika #$employeeId');
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderScreen(title: 'Profil Użytkownika');
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderScreen(title: 'Raporty');
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderScreen(title: 'Powiadomienia');
}

/// Placeholder dla ekranów w rozwoju
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: AppTheme.premiumCardDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction, size: 64, color: AppTheme.warningColor),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ta sekcja jest w trakcie rozwoju',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Wstecz'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
