import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'investments_screen.dart';
import 'clients_screen.dart';
import 'products_screen.dart';
import 'companies_screen.dart';
import 'employees_screen.dart';
import 'analytics_screen.dart';

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
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                if (_isRailExtended) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Cosmopolitan\nInvestment',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.primaryColor,
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
                        ),
                        tooltip: _isRailExtended ? 'Zwiń menu' : 'Rozwiń menu',
                      ),
                      const SizedBox(height: 8),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'settings':
                              _showSettingsDialog();
                              break;
                            case 'logout':
                              _showLogoutDialog();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
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
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.person,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            destinations: _navigationItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.icon, color: AppTheme.primaryColor),
                label: Text(item.label),
              );
            }).toList(),
            backgroundColor: Colors.grey[50],
            selectedIconTheme: IconThemeData(
              color: AppTheme.primaryColor,
              size: 28,
            ),
            unselectedIconTheme: IconThemeData(
              color: Colors.grey[600],
              size: 24,
            ),
            selectedLabelTextStyle: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            useIndicator: true,
            indicatorColor: AppTheme.primaryColor.withOpacity(0.1),
          ),
          const VerticalDivider(thickness: 1, width: 1),
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

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ustawienia'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.palette),
              title: Text('Motyw'),
              subtitle: Text('Jasny motyw'),
            ),
            ListTile(
              leading: Icon(Icons.language),
              title: Text('Język'),
              subtitle: Text('Polski'),
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Powiadomienia'),
              subtitle: Text('Włączone'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
        title: const Text('Wylogowanie'),
        content: const Text('Czy na pewno chcesz się wylogować?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implement logout logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wylogowano pomyślnie')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
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
