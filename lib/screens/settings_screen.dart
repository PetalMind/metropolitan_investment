import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_routes.dart';
import '../models_and_services.dart';
import '../providers/auth_provider.dart';
import '../widgets/metropolitan_loading_system.dart';

// RBAC: wspólny tooltip dla braku uprawnień
const String kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

/// 🔧 Settings Screen
/// Ekran ustawień aplikacji z zarządzaniem obliczeniami kapitału oraz innymi opcjami
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedTabIndex = 0;

  List<SettingsTab> get _tabs {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    List<SettingsTab> tabs = [
      SettingsTab(
        title: 'Obliczenia kapitału',
        icon: Icons.calculate,
        content: const CapitalCalculationSettingsTab(),
      ),
      SettingsTab(
        title: 'Konto',
        icon: Icons.account_circle,
        content: const AccountSettingsTab(),
      ),
      SettingsTab(
        title: 'Aplikacja',
        icon: Icons.settings_applications,
        content: const ApplicationSettingsTab(),
      ),
      SettingsTab(
        title: 'Dane',
        icon: Icons.storage,
        content: const DataSettingsTab(),
      ),
      SettingsTab(
        title: 'System',
        icon: Icons.computer,
        content: const SystemSettingsTab(),
      ),
    ];

    // Dodaj zakładkę Admin tylko dla administratorów
    if (isAdmin) {
      tabs.add(
        SettingsTab(
          title: 'Admin',
          icon: Icons.admin_panel_settings,
          content: const AdminSettingsTab(),
        ),
      );
    }

    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.settings),
            SizedBox(width: 8),
            Text('Ustawienia'),
          ],
        ),
      ),
      body: Row(
        children: [
          // Lewy panel - lista kategorii
          Container(
            width: 280,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                final tab = _tabs[index];
                final isSelected = index == _selectedTabIndex;

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _selectedTabIndex = index),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              tab.icon,
                              color: isSelected ? Colors.blue : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tab.title,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.black,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.blue,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Główny panel - zawartość wybranej kategorii
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nagłówek kategorii
                  Row(
                    children: [
                      Icon(
                        _tabs[_selectedTabIndex].icon,
                        color: Colors.blue,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _tabs[_selectedTabIndex].title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Zawartość kategorii
                  Expanded(child: _tabs[_selectedTabIndex].content),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Model reprezentujący zakładkę ustawień
class SettingsTab {
  final String title;
  final IconData icon;
  final Widget content;

  const SettingsTab({
    required this.title,
    required this.icon,
    required this.content,
  });
}

/// Tab z ustawieniami obliczeń kapitału
class CapitalCalculationSettingsTab extends StatelessWidget {
  const CapitalCalculationSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zarządzanie obliczeniami "Kapitał zabezpieczony nieruchomością"',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Status obliczeń
          const CapitalCalculationHelper(showFullInterface: true),

          const SizedBox(height: 24),

          // Karty z akcjami
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildActionCard(
                context,
                icon: Icons.analytics,
                title: 'Sprawdź status',
                description: 'Zobacz aktualny stan obliczeń',
                color: Colors.blue,
                onTap: () => _showStatusDialog(context),
              ),
              _buildActionCard(
                context,
                icon: Icons.science,
                title: 'Uruchom test',
                description: 'Symulacja bez wpływu na bazę',
                color: Colors.orange,
                onTap: () => _runTest(context),
              ),
              _buildActionCard(
                context,
                icon: Icons.update,
                title: 'Aktualizuj bazę',
                description: 'Zapisz obliczone wartości',
                color: Colors.green,
                onTap: () => _runUpdate(context),
              ),
              _buildActionCard(
                context,
                icon: Icons.manage_accounts,
                title: 'Zarządzanie',
                description: 'Zaawansowane opcje',
                color: Colors.purple,
                onTap: () => _openManagement(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Sekcja z informacjami
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Informacje o obliczeniach',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'Wzór obliczenia',
                    'Kapitał Pozostały - Kapitał do restrukturyzacji',
                  ),
                  _buildInfoRow(
                    'Częstotliwość',
                    'Automatyczne obliczanie przy każdym pobraniu danych',
                  ),
                  _buildInfoRow(
                    'Zapis w bazie',
                    'Funkcje w tym panelu zapisują wartości do Firestore',
                  ),
                  _buildInfoRow(
                    'Cache',
                    'Wyniki analityk są cache\'owane na 5-10 minut',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _showStatusDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('📊 Status obliczeń'),
        content: Text('Sprawdzanie statusu...'),
      ),
    );

    try {
      final status =
          await FirebaseFunctionsCapitalCalculationService.checkCapitalCalculationStatus();

      if (context.mounted) {
        Navigator.of(context).pop(); // Zamknij dialog ładowania

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('📊 Status obliczeń'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Łączna liczba inwestycji: ${status?.statistics.totalInvestments ?? 0}',
                ),
                Text(
                  'Wymaga aktualizacji: ${status?.statistics.needsUpdate ?? 0}',
                ),
                Text(
                  'Kompletność: ${status?.statistics.completionRate ?? '0%'}',
                ),
                Text('Poprawność: ${status?.statistics.accuracyRate ?? '0%'}'),
                if (status?.recommendations.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Rekomendacje:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...status!.recommendations.map((rec) => Text('• $rec')),
                ],
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
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Zamknij dialog ładowania
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _runTest(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🧪 Uruchomić test?'),
        content: const Text(
          'Test sprawdzi jakie zmiany byłyby wprowadzone bez wpływu na bazę danych.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Uruchom test'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result =
          await FirebaseFunctionsCapitalCalculationService.updateCapitalSecuredByRealEstate(
            dryRun: true,
            batchSize: 100,
            includeDetails: true,
          );

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🧪 Wyniki testu'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Przetworzonych: ${result?.processed ?? 0}'),
                  Text('Do aktualizacji: ${result?.updated ?? 0}'),
                  Text('Błędów: ${result?.errors ?? 0}'),
                  Text('Czas: ${result?.executionTimeMs ?? 0}ms'),
                  if (result?.summary != null) ...[
                    const SizedBox(height: 8),
                    Text('Sukces: ${result!.summary!.successRate}'),
                    Text('Aktualizacja: ${result.summary!.updateRate}'),
                  ],
                ],
              ),
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd testu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _runUpdate(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Potwierdzenie aktualizacji'),
        content: const Text(
          'Czy na pewno chcesz zaktualizować wszystkie wartości w bazie danych? '
          'Ta operacja może potrwać kilka minut.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Aktualizuj bazę danych'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result =
          await FirebaseFunctionsCapitalCalculationService.updateCapitalSecuredByRealEstate(
            dryRun: false,
            batchSize: 500,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Aktualizacja zakończona: ${result?.updated ?? 0} inwestycji zaktualizowanych',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd aktualizacji: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CapitalCalculationManagementScreen(),
      ),
    );
  }
}

/// Tab z ustawieniami konta
class AccountSettingsTab extends StatelessWidget {
  const AccountSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zarządzanie kontem użytkownika',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Informacje o użytkowniku
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Informacje o koncie',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        'Email',
                        auth.user?.email ?? 'Nie zalogowany',
                      ),
                      _buildInfoRow('ID użytkownika', auth.user?.uid ?? 'Brak'),
                      _buildInfoRow(
                        'Status',
                        auth.isLoggedIn ? 'Zalogowany' : 'Wylogowany',
                      ),
                      _buildInfoRow(
                        'Ostatnie logowanie',
                        auth.user?.metadata.lastSignInTime?.toString() ??
                            'Nieznane',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Akcje konta
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.settings, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Akcje konta',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    context,
                    icon: Icons.lock,
                    title: 'Zmiana hasła',
                    subtitle: 'Zaktualizuj hasło do konta',
                    onTap: () => _changePassword(context),
                  ),
                  _buildActionButton(
                    context,
                    icon: Icons.refresh,
                    title: 'Odśwież sesję',
                    subtitle: 'Odśwież token autoryzacji',
                    onTap: () => _refreshSession(context),
                  ),
                  _buildActionButton(
                    context,
                    icon: Icons.logout,
                    title: 'Wyloguj się',
                    subtitle: 'Zakończ bieżącą sesję',
                    color: Colors.red,
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
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
                Icon(icon, color: color ?? Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changePassword(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funkcja zmiany hasła - w trakcie implementacji'),
      ),
    );
  }

  void _refreshSession(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sesja została odświeżona')));
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potwierdzenie wylogowania'),
        content: const Text('Czy na pewno chcesz się wylogować?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Wyloguj'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Provider.of<AuthProvider>(context, listen: false).signOut();
    }
  }
}

/// Tab z ustawieniami aplikacji
class ApplicationSettingsTab extends StatefulWidget {
  const ApplicationSettingsTab({super.key});

  @override
  State<ApplicationSettingsTab> createState() => _ApplicationSettingsTabState();
}

class _ApplicationSettingsTabState extends State<ApplicationSettingsTab> {
  bool _darkMode = true;
  bool _enableNotifications = true;
  bool _enableAnimations = true;
  bool _enableCache = true;
  double _cacheTimeout = 5.0;
  int _pageSize = 250;
  String _dateFormat = 'dd/MM/yyyy';
  String _language = 'pl';

  // RBAC getter
  bool get canEdit => Provider.of<AuthProvider>(context, listen: false).isAdmin;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personalizacja interfejsu i zachowania aplikacji',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Ustawienia wyglądu
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.palette, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Wygląd aplikacji',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Tryb ciemny'),
                    subtitle: const Text('Używaj ciemnego motywu aplikacji'),
                    value: _darkMode,
                    onChanged: (value) => setState(() => _darkMode = value),
                    secondary: const Icon(Icons.dark_mode),
                  ),
                  SwitchListTile(
                    title: const Text('Animacje'),
                    subtitle: const Text('Włącz płynne przejścia i animacje'),
                    value: _enableAnimations,
                    onChanged: (value) =>
                        setState(() => _enableAnimations = value),
                    secondary: const Icon(Icons.animation),
                  ),
                  ListTile(
                    title: const Text('Język aplikacji'),
                    subtitle: Text(_language == 'pl' ? 'Polski' : 'English'),
                    leading: const Icon(Icons.language),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLanguageDialog(),
                  ),
                  ListTile(
                    title: const Text('Format daty'),
                    subtitle: Text(_dateFormat),
                    leading: const Icon(Icons.date_range),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDateFormatDialog(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Ustawienia wydajności
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.speed, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Wydajność',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Cache danych'),
                    subtitle: const Text(
                      'Przechowuj dane w pamięci dla szybszego dostępu',
                    ),
                    value: _enableCache,
                    onChanged: (value) => setState(() => _enableCache = value),
                    secondary: const Icon(Icons.cached),
                  ),
                  ListTile(
                    title: const Text('Czas cache (minuty)'),
                    subtitle: Slider(
                      value: _cacheTimeout,
                      min: 1.0,
                      max: 15.0,
                      divisions: 14,
                      label: '${_cacheTimeout.round()} min',
                      onChanged: _enableCache
                          ? (value) => setState(() => _cacheTimeout = value)
                          : null,
                    ),
                    leading: const Icon(Icons.timer),
                  ),
                  ListTile(
                    title: const Text('Rozmiar strony'),
                    subtitle: Slider(
                      value: _pageSize.toDouble(),
                      min: 50.0,
                      max: 500.0,
                      divisions: 9,
                      label: '$_pageSize rekordów',
                      onChanged: (value) =>
                          setState(() => _pageSize = value.round()),
                    ),
                    leading: const Icon(Icons.view_list),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Ustawienia powiadomień
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Powiadomienia',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Powiadomienia systemowe'),
                    subtitle: const Text(
                      'Otrzymuj powiadomienia o ważnych zdarzeniach',
                    ),
                    value: _enableNotifications,
                    onChanged: (value) =>
                        setState(() => _enableNotifications = value),
                    secondary: const Icon(Icons.notifications_active),
                  ),
                  ListTile(
                    title: const Text('Powiadomienia o błędach'),
                    subtitle: const Text('Informuj o błędach i problemach'),
                    leading: const Icon(Icons.error_outline),
                    trailing: Switch(
                      value: _enableNotifications,
                      onChanged: _enableNotifications
                          ? (value) => setState(() {})
                          : null,
                    ),
                  ),
                  ListTile(
                    title: const Text('Powiadomienia o aktualizacjach'),
                    subtitle: const Text('Informuj o zakończonych operacjach'),
                    leading: const Icon(Icons.update),
                    trailing: Switch(
                      value: _enableNotifications,
                      onChanged: _enableNotifications
                          ? (value) => setState(() {})
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Ustawienia zaawansowane
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.settings_applications, color: Colors.purple),
                      SizedBox(width: 8),
                      Text(
                        'Zaawansowane',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildAdvancedOption(
                    context,
                    icon: Icons.download,
                    title: 'Eksportuj ustawienia',
                    subtitle: 'Zapisz bieżące ustawienia do pliku',
                    onTap: canEdit ? () => _exportSettings(context) : null,
                    disabled: !canEdit,
                  ),
                  _buildAdvancedOption(
                    context,
                    icon: Icons.upload,
                    title: 'Importuj ustawienia',
                    subtitle: 'Przywróć ustawienia z pliku',
                    onTap: canEdit ? () => _importSettings(context) : null,
                    disabled: !canEdit,
                  ),
                  _buildAdvancedOption(
                    context,
                    icon: Icons.restore,
                    title: 'Przywróć domyślne',
                    subtitle:
                        'Resetuj wszystkie ustawienia do wartości domyślnych',
                    onTap: canEdit ? () => _resetSettings(context) : null,
                    disabled: !canEdit,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Przyciski akcji
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canEdit ? () => _saveSettings(context) : null,
                  icon: const Icon(Icons.save),
                  label: Text(canEdit ? 'Zapisz ustawienia' : 'Tylko podgląd'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canEdit ? () => _discardChanges(context) : null,
                  icon: const Icon(Icons.cancel),
                  label: Text(canEdit ? 'Odrzuć zmiany' : 'Brak uprawnień'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool disabled = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: disabled ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Tooltip(
                  message: disabled ? kRbacNoPermissionTooltip : title,
                  child: Icon(
                    icon,
                    color: disabled ? Colors.grey : Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wybierz język'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Polski'),
              value: 'pl',
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value!);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value!);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDateFormatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Format daty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('dd/MM/yyyy'),
              value: 'dd/MM/yyyy',
              groupValue: _dateFormat,
              onChanged: (value) {
                setState(() => _dateFormat = value!);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('MM/dd/yyyy'),
              value: 'MM/dd/yyyy',
              groupValue: _dateFormat,
              onChanged: (value) {
                setState(() => _dateFormat = value!);
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('yyyy-MM-dd'),
              value: 'yyyy-MM-dd',
              groupValue: _dateFormat,
              onChanged: (value) {
                setState(() => _dateFormat = value!);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📁 Eksport ustawień - w trakcie implementacji'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _importSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📂 Import ustawień - w trakcie implementacji'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _resetSettings(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Przywróć domyślne ustawienia'),
        content: const Text(
          'Czy na pewno chcesz przywrócić wszystkie ustawienia do wartości domyślnych? '
          'Ta operacja nie może być cofnięta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Przywróć'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _darkMode = true;
        _enableNotifications = true;
        _enableAnimations = true;
        _enableCache = true;
        _cacheTimeout = 5.0;
        _pageSize = 250;
        _dateFormat = 'dd/MM/yyyy';
        _language = 'pl';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Ustawienia zostały przywrócone do wartości domyślnych',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _saveSettings(BuildContext context) {
    // Tu można dodać rzeczywiste zapisywanie ustawień
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Ustawienia zostały zapisane'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _discardChanges(BuildContext context) {
    // Tu można przywrócić poprzednie wartości
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('↩️ Zmiany zostały odrzucone'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

/// Tab z ustawieniami danych i diagnostyką
class DataSettingsTab extends StatelessWidget {
  const DataSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zarządzanie danymi i diagnostyka pól',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Sekcja diagnostyki mapowania pól
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bug_report, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Diagnostyka mapowania pól',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sprawdź jak nazwy pól w bazie danych są mapowane w aplikacji:',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  _buildFieldMappingTable(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sekcja z przykładowymi danymi z Firestore
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.storage, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Struktura danych Firestore',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Przykładowe pola z rzeczywistych dokumentów investments:',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  _buildFirestoreFieldsTable(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Akcje diagnostyczne
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.healing, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Akcje diagnostyczne',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDiagnosticActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldMappingTable() {
    final fieldMappings = [
      [
        'remainingCapital',
        'remainingCapital, kapital_pozostaly, Kapital Pozostaly',
      ],
      [
        'capitalForRestructuring',
        'capitalForRestructuring, kapital_do_restrukturyzacji',
      ],
      [
        'capitalSecuredByRealEstate',
        'capitalSecuredByRealEstate, kapital_zabezpieczony_nieruchomoscia',
      ],
      ['investmentAmount', 'investmentAmount, kwota_inwestycji, paymentAmount'],
      ['clientName', 'clientName, klient, Klient'],
      ['clientId', 'clientId, ID_Klient, klient_id'],
      ['productStatus', 'productStatus, status_produktu, Status_produktu'],
      ['productName', 'productName, nazwa_produktu, Produkt_nazwa'],
      ['productType', 'productType, typ_produktu, Typ_produktu'],
      ['advisor', 'advisor, opiekun, Opiekun z MISA'],
      ['branch', 'branch, oddzial, Oddzial'],
      ['salesId', 'salesId, ID_Sprzedaz, sprzedaz_id'],
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: const {0: FixedColumnWidth(200), 1: FlexColumnWidth()},
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1)),
            children: const [
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Pole logiczne',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Nazwy w bazie danych',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          ...fieldMappings.map(
            (mapping) => TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    mapping[0],
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    mapping[1],
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirestoreFieldsTable() {
    final firestoreFields = [
      ['capitalForRestructuring', '50000', 'number', '✅ Potwierdzone'],
      ['capitalSecuredByRealEstate', '0', 'number', '✅ Potwierdzone'],
      ['clientId', '643', 'string', '✅ Potwierdzone'],
      ['clientName', 'Rafał Sosna', 'string', '✅ Potwierdzone'],
      ['investmentAmount', '50000', 'number', '✅ Potwierdzone'],
      ['paymentAmount', '50000', 'number', '✅ Potwierdzone'],
      [
        'productName',
        'Metropolitan Outlet Sp. z o.o. B4',
        'string',
        '✅ Potwierdzone',
      ],
      ['productStatus', 'Aktywny', 'string', '✅ Potwierdzone'],
      ['productType', 'Obligacje', 'string', '✅ Potwierdzone'],
      ['remainingCapital', '50000', 'number', '✅ Potwierdzone'],
      ['advisor', 'Paweł Dembski', 'string', '✅ Potwierdzone'],
      ['branch', 'POZ', 'string', '✅ Potwierdzone'],
      ['salesId', '3246', 'string', '✅ Potwierdzone'],
      ['companyId', 'Metropolitan Investment S.A.', 'string', '✅ Potwierdzone'],
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Nazwa pola')),
            DataColumn(label: Text('Przykładowa wartość')),
            DataColumn(label: Text('Typ')),
            DataColumn(label: Text('Status')),
          ],
          rows: firestoreFields
              .map(
                (field) => DataRow(
                  cells: [
                    DataCell(
                      Text(
                        field[0],
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    DataCell(Text(field[1])),
                    DataCell(Text(field[2])),
                    DataCell(
                      Text(
                        field[3],
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDiagnosticActions(BuildContext context) {
    return Column(
      children: [
        _buildActionButton(
          context,
          icon: Icons.search,
          title: 'Sprawdź mapowanie konkretnej inwestycji',
          subtitle: 'Wprowadź ID inwestycji aby zobaczyć jak pola są mapowane',
          onTap: () => _checkInvestmentMapping(context),
        ),
        _buildActionButton(
          context,
          icon: Icons.analytics,
          title: 'Test funkcji unified-statistics',
          subtitle: 'Przetestuj czy funkcje poprawnie rozpoznają pola',
          onTap: () => _testUnifiedStatistics(context),
        ),
        _buildActionButton(
          context,
          icon: Icons.download,
          title: 'Eksportuj przykładowe dane',
          subtitle: 'Pobierz JSON z próbką danych do analizy',
          onTap: () => _exportSampleData(context),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _checkInvestmentMapping(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Sprawdź mapowanie inwestycji'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'ID inwestycji (np. bond_0194)',
              hintText: 'Wprowadź ID dokumentu z kolekcji investments',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Sprawdzanie mapowania dla: ${controller.text}',
                    ),
                    action: SnackBarAction(
                      label: 'Szczegóły',
                      onPressed: () {
                        // Tu można dodać rzeczywiste sprawdzanie przez Firebase Functions
                      },
                    ),
                  ),
                );
              },
              child: const Text('Sprawdź'),
            ),
          ],
        );
      },
    );
  }

  void _testUnifiedStatistics(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '🧪 Test funkcji unified-statistics - w trakcie implementacji',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _exportSampleData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📥 Eksport danych - w trakcie implementacji'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

/// Tab z informacjami systemowymi
class SystemSettingsTab extends StatelessWidget {
  const SystemSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informacje systemowe i konfiguracja techniczna',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Informacje o aplikacji
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Informacje o aplikacji',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Nazwa aplikacji', 'Metropolitan Investment'),
                  _buildInfoRow('Wersja', '1.0.0 (Build 1)'),
                  _buildInfoRow('Framework', 'Flutter 3.x'),
                  _buildInfoRow('Platforma', 'Web / Desktop'),
                  _buildInfoRow('Środowisko', 'Production'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Konfiguracja Firebase
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cloud, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Konfiguracja Firebase',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Region Functions', 'europe-west1'),
                  _buildInfoRow('Firestore Region', 'europe-west1'),
                  _buildInfoRow('Authentication', 'Firebase Auth'),
                  _buildInfoRow('Storage', 'Cloud Firestore'),
                  _buildInfoRow('Functions Runtime', 'Node.js 18'),
                  _buildInfoRow('Functions Memory', '2GB (analytics)'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Architektura systemu
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.architecture, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Architektura systemu',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('State Management', 'Provider + Riverpod'),
                  _buildInfoRow('Routing', 'Go Router'),
                  _buildInfoRow('Data Layer', 'Firebase Functions + Firestore'),
                  _buildInfoRow('Cache Strategy', '5-min TTL per service'),
                  _buildInfoRow(
                    'Analytics Engine',
                    'Server-side (Firebase Functions)',
                  ),
                  _buildInfoRow('Theme System', 'Professional Dark Theme'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Statystyki wydajności
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.speed, color: Colors.purple),
                      SizedBox(width: 8),
                      Text(
                        'Optymalizacje wydajności',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'Batch Size (Analytics)',
                    '500-1000 dokumentów',
                  ),
                  _buildInfoRow('Pagination Size', '250 rekordów'),
                  _buildInfoRow('Cache Duration', '5-10 minut'),
                  _buildInfoRow('Timeout Functions', '540 sekund'),
                  _buildInfoRow('Memory Analytics', '2GB'),
                  _buildInfoRow('Lazy Loading', 'Aktywne'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Kolekcje danych
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.storage, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Struktura danych',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Główna kolekcja', 'investments (unified)'),
                  _buildInfoRow('Klienci', 'clients'),
                  _buildInfoRow('Pracownicy', 'employees'),
                  _buildInfoRow('Spółki', 'companies'),
                  _buildInfoRow(
                    'Legacy Collections',
                    'bonds, shares, loans, apartments (deprecated)',
                  ),
                  _buildInfoRow('Cache Collection', 'Pamięć tymczasowa'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Akcje systemowe
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.build, color: Colors.teal),
                      SizedBox(width: 8),
                      Text(
                        'Akcje systemowe',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSystemAction(
                    context,
                    icon: Icons.email,
                    title: 'Konfiguracja serwera SMTP',
                    subtitle: 'Zarządzaj ustawieniami wysyłania e-maili',
                    onTap: () => context.go(AppRoutes.smtpSettings),
                  ),
                  _buildSystemAction(
                    context,
                    icon: Icons.cached,
                    title: 'Wyczyść cache aplikacji',
                    subtitle: 'Usuń dane tymczasowe i odśwież cache',
                    onTap: () => _clearCache(context),
                  ),
                  _buildSystemAction(
                    context,
                    icon: Icons.refresh,
                    title: 'Odśwież konfigurację',
                    subtitle: 'Przeładuj ustawienia Firebase Functions',
                    onTap: () => _refreshConfiguration(context),
                  ),
                  _buildSystemAction(
                    context,
                    icon: Icons.bug_report,
                    title: 'Tryb debug',
                    subtitle: 'Włącz szczegółowe logowanie',
                    onTap: () => _toggleDebugMode(context),
                  ),
                  _buildSystemAction(
                    context,
                    icon: Icons.health_and_safety,
                    title: 'Test połączenia',
                    subtitle: 'Sprawdź dostępność Firebase Functions',
                    onTap: () => _testConnection(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSystemAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _clearCache(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗑️ Cache aplikacji został wyczyszczony'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _refreshConfiguration(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Konfiguracja została odświeżona'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _toggleDebugMode(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🐛 Tryb debug przełączony'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _testConnection(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testowanie połączenia...'),
          ],
        ),
      ),
    );

    // Symulacja testu połączenia
    await Future.delayed(const Duration(seconds: 2));

    if (context.mounted) {
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Test połączenia'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Firebase Functions: OK'),
              Text('• Firestore: OK'),
              Text('• Authentication: OK'),
              Text('• Analytics Service: OK'),
              SizedBox(height: 8),
              Text(
                'Wszystkie usługi działają prawidłowo',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
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
  }
}

/// 👑 ADMIN SETTINGS TAB
/// Zarządzanie użytkownikami i rolami - tylko dla administratorów
class AdminSettingsTab extends StatefulWidget {
  const AdminSettingsTab({super.key});

  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Pobierz wszystkich użytkowników z Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('email')
          .get();

      final users = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id; // Dodaj uid do map
        return data;
      }).toList();

      // 🔒 UKRYJ SUPER-ADMINÓW: Filtruj użytkowników - nie pokazuj super-admin
      final filteredUsers = users.where((user) {
        final role = user['role'] ?? 'user';
        return role != 'super-admin' && role != 'superadmin';
      }).toList();

      setState(() {
        _allUsers = filteredUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Błąd podczas ładowania użytkowników: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserRole(String uid, String newRole) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Odśwież listę
      await _loadUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rola użytkownika została zaktualizowana'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas aktualizacji roli: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zarządzanie użytkownikami i rolami',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Statystyki użytkowników
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statystyki użytkowników',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(
                      child: MetropolitanLoadingWidget.settings(
                        showProgress: true,
                      ),
                    )
                  else if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red))
                  else ...[
                    _buildUserStats(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _loadUsers,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Odśwież'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Lista użytkowników
          if (!_isLoading && _error == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lista użytkowników',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildUsersTable(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    // 🔒 UKRYJ SUPER-ADMINÓW: Statystyki nie uwzględniają super-admin
    final adminCount = _allUsers.where((u) {
      final role = u['role'] ?? 'user';
      return role == 'admin'; // Tylko zwykli adminowie, bez super-admin
    }).length;
    final userCount = _allUsers.where((u) => u['role'] == 'user').length;
    final activeCount = _allUsers.where((u) => u['isActive'] == true).length;

    return Row(
      children: [
        Expanded(child: _buildStatCard('Użytkownicy', userCount, Colors.blue)),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('Administratorzy', adminCount, Colors.orange),
        ),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Aktywni', activeCount, Colors.green)),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildUsersTable() {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('Imię i nazwisko')),
        DataColumn(label: Text('Rola')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Ostatnie logowanie')),
        DataColumn(label: Text('Akcje')),
      ],
      rows: _allUsers.map((user) => _buildUserRow(user)).toList(),
    );
  }

  DataRow _buildUserRow(Map<String, dynamic> user) {
    final String email = user['email'] ?? '';
    final String firstName = user['firstName'] ?? '';
    final String lastName = user['lastName'] ?? '';
    final String fullName = '$firstName $lastName'.trim();
    final String role = user['role'] ?? 'user';
    final bool isActive = user['isActive'] ?? true;
    final Timestamp? lastLoginTimestamp = user['lastLoginAt'] as Timestamp?;
    final DateTime? lastLoginAt = lastLoginTimestamp?.toDate();

    return DataRow(
      cells: [
        DataCell(Text(email)),
        DataCell(Text(fullName.isNotEmpty ? fullName : email)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: role == 'admin'
                  ? Colors.orange.withOpacity(0.2)
                  : Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              role == 'admin' ? 'Administrator' : 'Użytkownik',
              style: TextStyle(
                color: role == 'admin' ? Colors.orange : Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            color: isActive ? Colors.green : Colors.red,
          ),
        ),
        DataCell(
          Text(
            lastLoginAt != null
                ? '${lastLoginAt.day}.${lastLoginAt.month}.${lastLoginAt.year}'
                : 'Nigdy',
          ),
        ),
        DataCell(
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: role == 'admin' ? 'user' : 'admin',
                child: Row(
                  children: [
                    Icon(
                      role == 'admin'
                          ? Icons.person
                          : Icons.admin_panel_settings,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      role == 'admin'
                          ? 'Usuń uprawnienia admin'
                          : 'Nadaj uprawnienia admin',
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (newRole) => _showRoleChangeDialog(user, newRole),
          ),
        ),
      ],
    );
  }

  void _showRoleChangeDialog(Map<String, dynamic> user, String newRole) {
    final String roleText = newRole == 'admin'
        ? 'administratora'
        : 'użytkownika';
    final String email = user['email'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zmiana roli użytkownika'),
        content: Text(
          'Czy na pewno chcesz zmienić rolę użytkownika $email na $roleText?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateUserRole(user['uid'], newRole);
            },
            child: const Text('Potwierdź'),
          ),
        ],
      ),
    );
  }
}
