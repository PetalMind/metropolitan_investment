import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models_and_services.dart';
import '../providers/auth_provider.dart';

/// 🔧 Settings Screen
/// Ekran ustawień aplikacji z zarządzaniem obliczeniami kapitału oraz innymi opcjami
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedTabIndex = 0;

  final List<SettingsTab> _tabs = [
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

/// Placeholder tabs
class ApplicationSettingsTab extends StatelessWidget {
  const ApplicationSettingsTab({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderTab(title: 'Ustawienia aplikacji');
}

class DataSettingsTab extends StatelessWidget {
  const DataSettingsTab({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderTab(title: 'Zarządzanie danymi');
}

class SystemSettingsTab extends StatelessWidget {
  const SystemSettingsTab({super.key});
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderTab(title: 'Informacje systemowe');
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  const _PlaceholderTab({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ta sekcja jest w trakcie rozwoju',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
