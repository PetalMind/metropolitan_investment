import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import 'dashboard_screen.dart';
import 'investments_screen.dart';
import 'clients_screen.dart';
import 'products_screen.dart';
import 'companies_screen.dart';
import 'employees_screen.dart';
import 'analytics_screen.dart';
import 'investor_analytics_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isRailExtended = false;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      screen: const DashboardScreen(),
    ),
    NavigationItem(
      icon: MdiIcons.chartLine,
      label: 'Inwestycje',
      screen: const InvestmentsScreen(),
    ),
    NavigationItem(
      icon: Icons.people,
      label: 'Klienci',
      screen: const ClientsScreen(),
    ),
    NavigationItem(
      icon: MdiIcons.packageVariant,
      label: 'Produkty',
      screen: const ProductsScreen(),
    ),
    NavigationItem(
      icon: Icons.business,
      label: 'Spółki',
      screen: const CompaniesScreen(),
    ),
    NavigationItem(
      icon: Icons.person_outline,
      label: 'Pracownicy',
      screen: const EmployeesScreen(),
    ),
    NavigationItem(
      icon: Icons.analytics,
      label: 'Analityka',
      screen: const AnalyticsScreen(),
    ),
    NavigationItem(
      icon: MdiIcons.accountGroup,
      label: 'Inwestorzy',
      screen: const InvestorAnalyticsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            extended: _isRailExtended,
            minExtendedWidth: 200,
            leading: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryGold.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: AppTheme.textOnSecondary,
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
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
            trailing: Expanded(
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
                          _isRailExtended
                              ? Icons.chevron_left
                              : Icons.chevron_right,
                          color: AppTheme.textSecondary,
                        ),
                        tooltip: _isRailExtended ? 'Zwiń menu' : 'Rozwiń menu',
                      ),
                      const SizedBox(height: 8),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'profile':
                                  _showProfileDialog();
                                  break;
                                case 'settings':
                                  _showSettingsDialog();
                                  break;
                                case 'logout':
                                  _showLogoutDialog();
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'profile',
                                child: Container(
                                  color: AppTheme.backgroundModal,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        color: AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            authProvider
                                                    .userProfile
                                                    ?.fullName ??
                                                authProvider
                                                    .user
                                                    ?.displayName ??
                                                'Użytkownik',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            authProvider.user?.email ?? '',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'settings',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.settings,
                                      color: AppTheme.textSecondary,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Ustawienia',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.logout,
                                      color: AppTheme.errorColor,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Wyloguj',
                                      style: TextStyle(
                                        color: AppTheme.errorColor,
                                      ),
                                    ),
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
                                    color: AppTheme.secondaryGold.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person,
                                color: AppTheme.textOnSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            destinations: _navigationItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.icon, color: AppTheme.secondaryGold),
                label: Text(item.label),
              );
            }).toList(),
            backgroundColor: AppTheme.backgroundSecondary,
            selectedIconTheme: const IconThemeData(
              color: AppTheme.secondaryGold,
              size: 28,
            ),
            unselectedIconTheme: const IconThemeData(
              color: AppTheme.textSecondary,
              size: 24,
            ),
            selectedLabelTextStyle: const TextStyle(
              color: AppTheme.secondaryGold,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
            useIndicator: true,
            indicatorColor: AppTheme.secondaryGold.withOpacity(0.2),
          ),
          const VerticalDivider(
            thickness: 1,
            width: 1,
            color: AppTheme.borderSecondary,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _navigationItems[_selectedIndex].screen,
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundModal,
        title: const Text(
          'Profil użytkownika',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userProfile != null) ...[
              _buildProfileItem('Imię i nazwisko', userProfile.fullName),
              _buildProfileItem('Email', userProfile.email),
              if (userProfile.company != null)
                _buildProfileItem('Firma', userProfile.company!),
              if (userProfile.phone != null)
                _buildProfileItem('Telefon', userProfile.phone!),
              _buildProfileItem('Rola', userProfile.role),
            ] else ...[
              const Text(
                'Brak danych profilu',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
            child: const Text('Zamknij'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to profile edit screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryGold,
              foregroundColor: AppTheme.textOnSecondary,
            ),
            child: const Text('Edytuj profil'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundModal,
        title: const Text(
          'Ustawienia',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.palette, color: AppTheme.textSecondary),
              title: const Text(
                'Motyw',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              subtitle: const Text(
                'Ciemny motyw',
                style: TextStyle(color: AppTheme.textTertiary),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.language,
                color: AppTheme.textSecondary,
              ),
              title: const Text(
                'Język',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              subtitle: const Text(
                'Polski',
                style: TextStyle(color: AppTheme.textTertiary),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.notifications,
                color: AppTheme.textSecondary,
              ),
              title: const Text(
                'Powiadomienia',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              subtitle: const Text(
                'Włączone',
                style: TextStyle(color: AppTheme.textTertiary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundModal,
        title: const Text(
          'Wylogowanie',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Czy na pewno chcesz się wylogować?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Get auth provider and sign out
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              await authProvider.signOut();

              if (mounted) {
                // Navigate to login screen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
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
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final Widget screen;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.screen,
  });
}
