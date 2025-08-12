import 'package:flutter/material.dart';
import '../models_and_services.dart';

/// 🔧 Capital Calculation Helper Widget
/// Prosty widget do wyświetlania statusu i uruchamiania aktualizacji kapitału
/// w innych częściach aplikacji
class CapitalCalculationHelper extends StatefulWidget {
  final bool showFullInterface;
  final VoidCallback? onUpdateCompleted;

  const CapitalCalculationHelper({
    super.key,
    this.showFullInterface = false,
    this.onUpdateCompleted,
  });

  @override
  State<CapitalCalculationHelper> createState() =>
      _CapitalCalculationHelperState();
}

class _CapitalCalculationHelperState extends State<CapitalCalculationHelper> {
  bool _isLoading = false;
  bool _isUpdating = false;
  CapitalCalculationStatusResult? _status;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final status =
          await FirebaseFunctionsCapitalCalculationService.checkCapitalCalculationStatus();

      if (mounted) {
        setState(() {
          _status = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _runQuickUpdate() async {
    if (!mounted) return;

    setState(() => _isUpdating = true);

    try {
      await FirebaseFunctionsCapitalCalculationService.updateCapitalSecuredByRealEstate(
        batchSize: 250,
        dryRun: false,
      );

      await _checkStatus();
      widget.onUpdateCompleted?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Aktualizacja kapitału zakończona pomyślnie'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Błąd aktualizacji: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_status == null) {
      return const SizedBox();
    }

    if (_status!.statistics.isFullyCalculated) {
      return Card(
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Kapitał zabezpieczony nieruchomością - wszystkie wartości aktualne',
                  style: TextStyle(color: Colors.green),
                ),
              ),
              if (widget.showFullInterface)
                IconButton(
                  onPressed: _checkStatus,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Odśwież',
                ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kapitał zabezpieczony: ${_status!.statistics.needsUpdate} inwestycji wymaga aktualizacji',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.showFullInterface) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Kompletność: ${_status!.statistics.completionRate} • '
                    'Poprawność: ${_status!.statistics.accuracyRate}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  if (_isUpdating)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    ElevatedButton(
                      onPressed: _runQuickUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Aktualizuj teraz'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 🔧 Capital Status Badge
/// Prosty badge do wyświetlania stanu kapitału w kompaktowej formie
class CapitalStatusBadge extends StatelessWidget {
  final int? needsUpdate;
  final String? accuracyRate;
  final VoidCallback? onTap;

  const CapitalStatusBadge({
    super.key,
    this.needsUpdate,
    this.accuracyRate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (needsUpdate == null) return const SizedBox();

    final isUpToDate = needsUpdate == 0;
    final color = isUpToDate ? Colors.green : Colors.orange;
    final icon = isUpToDate ? Icons.check_circle : Icons.warning;
    final text = isUpToDate ? 'OK' : '$needsUpdate';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔧 Capital Calculation Quick Actions
/// Widget z szybkimi akcjami do zarządzania kapitałem
class CapitalCalculationQuickActions extends StatefulWidget {
  final EdgeInsets padding;

  const CapitalCalculationQuickActions({
    super.key,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<CapitalCalculationQuickActions> createState() =>
      _CapitalCalculationQuickActionsState();
}

class _CapitalCalculationQuickActionsState
    extends State<CapitalCalculationQuickActions> {
  bool _isLoading = false;

  Future<void> _showQuickMenu() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Sprawdź status obliczeń'),
              onTap: () => Navigator.pop(context, 'check'),
            ),
            ListTile(
              leading: const Icon(Icons.science),
              title: const Text('Uruchom test (symulacja)'),
              onTap: () => Navigator.pop(context, 'test'),
            ),
            ListTile(
              leading: const Icon(Icons.update),
              title: const Text('Aktualizuj bazę danych'),
              onTap: () => Navigator.pop(context, 'update'),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Zarządzanie zaawansowane'),
              onTap: () => Navigator.pop(context, 'manage'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _handleAction(result);
    }
  }

  Future<void> _handleAction(String action) async {
    setState(() => _isLoading = true);

    try {
      switch (action) {
        case 'check':
          await _checkStatus();
          break;
        case 'test':
          await _runTest();
          break;
        case 'update':
          await _runUpdate();
          break;
        case 'manage':
          await _openManagement();
          break;
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkStatus() async {
    try {
      final status =
          await FirebaseFunctionsCapitalCalculationService.checkCapitalCalculationStatus();

      if (mounted) {
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Zamknij'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _runTest() async {
    try {
      final result =
          await FirebaseFunctionsCapitalCalculationService.updateCapitalSecuredByRealEstate(
            dryRun: true,
            batchSize: 100,
          );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🧪 Wyniki testu'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Przetworzonych: ${result?.processed ?? 0}'),
                Text('Do aktualizacji: ${result?.updated ?? 0}'),
                Text('Błędów: ${result?.errors ?? 0}'),
                Text('Czas: ${result?.executionTimeMs ?? 0}ms'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Zamknij'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd testu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _runUpdate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Potwierdzenie'),
        content: const Text(
          'Czy na pewno chcesz zaktualizować wszystkie wartości w bazie danych? '
          'Ta operacja może potrwać kilka minut.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aktualizuj'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result =
            await FirebaseFunctionsCapitalCalculationService.updateCapitalSecuredByRealEstate(
              dryRun: false,
              batchSize: 500,
            );

        if (mounted) {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Błąd aktualizacji: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _openManagement() async {
    // Nawiguj do pełnego ekranu zarządzania
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CapitalCalculationManagementScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _showQuickMenu,
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.calculate),
        label: const Text('Kapitał'),
        tooltip: 'Zarządzanie obliczaniem kapitału',
      ),
    );
  }
}
