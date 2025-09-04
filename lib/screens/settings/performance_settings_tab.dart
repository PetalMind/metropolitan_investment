import 'package:flutter/material.dart';
import '../../theme/app_theme_professional.dart';

class PerformanceSettingsTab extends StatefulWidget {
  const PerformanceSettingsTab({super.key});

  @override
  State<PerformanceSettingsTab> createState() => _PerformanceSettingsTabState();
}

class _PerformanceSettingsTabState extends State<PerformanceSettingsTab>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Performance metrics
  bool _isLoading = true;
  Map<String, dynamic> _systemMetrics = {};
  Map<String, dynamic> _cacheMetrics = {};
  Map<String, dynamic> _performanceSettings = {};

  // Settings state
  bool _enableCaching = true;
  double _cacheTimeout = 5.0; // minutes
  int _pageSize = 250;
  bool _enablePreloading = true;
  bool _enableOptimizations = true;
  bool _useLazyLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadPerformanceData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  Future<void> _loadPerformanceData() async {
    try {
      // Symulacja ładowania metryk systemowych
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        setState(() {
          _systemMetrics = {
            'memoryUsage': '125 MB',
            'cpuUsage': '12%',
            'networkLatency': '45 ms',
            'cacheHitRate': '87.5%',
            'averageLoadTime': '1.2s',
            'lastOptimization': DateTime.now().subtract(
              const Duration(hours: 2),
            ),
          };

          _cacheMetrics = {
            'totalCacheSize': '45.2 MB',
            'cacheEntries': 847,
            'hitRate': 87.5,
            'missRate': 12.5,
            'expiredEntries': 23,
            'cleanupFrequency': 'Każde 5 minut',
          };

          _performanceSettings = {
            'enableCaching': true,
            'cacheTimeout': 5.0,
            'pageSize': 250,
            'enablePreloading': true,
            'enableOptimizations': true,
            'useLazyLoading': true,
          };

          _enableCaching = _performanceSettings['enableCaching'] ?? true;
          _cacheTimeout = _performanceSettings['cacheTimeout'] ?? 5.0;
          _pageSize = _performanceSettings['pageSize'] ?? 250;
          _enablePreloading = _performanceSettings['enablePreloading'] ?? true;
          _enableOptimizations =
              _performanceSettings['enableOptimizations'] ?? true;
          _useLazyLoading = _performanceSettings['useLazyLoading'] ?? true;

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Błąd podczas ładowania danych wydajności: $e');
      }
    }
  }

  Future<void> _clearCache() async {
    try {
      // Symulacja czyszczenia cache
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        setState(() {
          _cacheMetrics['totalCacheSize'] = '0 MB';
          _cacheMetrics['cacheEntries'] = 0;
          _cacheMetrics['expiredEntries'] = 0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🗑️ Cache został wyczyszczony'),
            backgroundColor: AppThemePro.statusSuccess,
          ),
        );
      }
    } catch (e) {
      _showError('Błąd podczas czyszczenia cache: $e');
    }
  }

  Future<void> _optimizePerformance() async {
    try {
      // Symulacja optymalizacji wydajności
      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted) {
        setState(() {
          _systemMetrics['lastOptimization'] = DateTime.now();
          _cacheMetrics['hitRate'] = 92.1;
          _cacheMetrics['missRate'] = 7.9;
          _systemMetrics['averageLoadTime'] = '0.9s';
          _systemMetrics['cacheHitRate'] = '92.1%';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚡ Optymalizacja wydajności zakończona'),
            backgroundColor: AppThemePro.statusSuccess,
          ),
        );
      }
    } catch (e) {
      _showError('Błąd podczas optymalizacji: $e');
    }
  }

  Future<void> _savePerformanceSettings() async {
    try {
      // Symulacja zapisywania ustawień wydajności
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Ustawienia wydajności zostały zapisane'),
            backgroundColor: AppThemePro.statusSuccess,
          ),
        );
      }
    } catch (e) {
      _showError('Błąd podczas zapisywania ustawień: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppThemePro.statusError,
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppThemePro.accentGold),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSystemMetricsSection(),
            const SizedBox(height: 24),
            _buildCacheManagementSection(),
            const SizedBox(height: 24),
            _buildPerformanceSettingsSection(),
            const SizedBox(height: 24),
            _buildOptimizationSection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
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
            AppThemePro.bondsBlue.withOpacity(0.1),
            AppThemePro.bondsBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.bondsBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemePro.bondsBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.speed_rounded,
              color: AppThemePro.bondsBlue,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wydajność systemu',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Monitorowanie i optymalizacja wydajności aplikacji',
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

  Widget _buildSystemMetricsSection() {
    return _buildPerformanceCard(
      'Metryki systemowe',
      Icons.monitor_rounded,
      AppThemePro.bondsBlue,
      [
        _buildMetricTile(
          'Użycie pamięci',
          _systemMetrics['memoryUsage'] ?? 'N/A',
          Icons.memory_rounded,
          AppThemePro.statusInfo,
        ),
        _buildMetricTile(
          'Obciążenie CPU',
          _systemMetrics['cpuUsage'] ?? 'N/A',
          Icons.developer_board_rounded,
          AppThemePro.statusSuccess,
        ),
        _buildMetricTile(
          'Opóźnienie sieciowe',
          _systemMetrics['networkLatency'] ?? 'N/A',
          Icons.network_check_rounded,
          AppThemePro.statusWarning,
        ),
        _buildMetricTile(
          'Współczynnik trafień cache',
          _systemMetrics['cacheHitRate'] ?? 'N/A',
          Icons.cached_rounded,
          AppThemePro.sharesGreen,
        ),
        _buildMetricTile(
          'Średni czas ładowania',
          _systemMetrics['averageLoadTime'] ?? 'N/A',
          Icons.timer_rounded,
          AppThemePro.accentGold,
        ),
      ],
    );
  }

  Widget _buildCacheManagementSection() {
    return _buildPerformanceCard(
      'Zarządzanie cache',
      Icons.storage_rounded,
      AppThemePro.sharesGreen,
      [
        _buildCacheMetricRow(
          'Rozmiar cache',
          _cacheMetrics['totalCacheSize'] ?? 'N/A',
        ),
        _buildCacheMetricRow(
          'Liczba wpisów',
          '${_cacheMetrics['cacheEntries'] ?? 0}',
        ),
        _buildCacheMetricRow(
          'Współczynnik trafień',
          '${_cacheMetrics['hitRate'] ?? 0}%',
        ),
        _buildCacheMetricRow(
          'Współczynnik błędów',
          '${_cacheMetrics['missRate'] ?? 0}%',
        ),
        _buildCacheMetricRow(
          'Wygasłe wpisy',
          '${_cacheMetrics['expiredEntries'] ?? 0}',
        ),
        _buildCacheMetricRow(
          'Częstotliwość czyszczenia',
          _cacheMetrics['cleanupFrequency'] ?? 'N/A',
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _clearCache,
          icon: const Icon(Icons.clear_all_rounded),
          label: const Text('Wyczyść cache'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppThemePro.statusWarning,
            foregroundColor: AppThemePro.primaryDark,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceSettingsSection() {
    return _buildPerformanceCard(
      'Ustawienia wydajności',
      Icons.tune_rounded,
      AppThemePro.loansOrange,
      [
        _buildSwitchSetting(
          'Włącz cache',
          'Przechowywanie danych w pamięci podręcznej',
          _enableCaching,
          (value) => setState(() => _enableCaching = value),
        ),
        if (_enableCaching) ...[
          const SizedBox(height: 16),
          _buildSliderSetting(
            'Czas życia cache',
            'Czas przechowywania danych w minutach',
            _cacheTimeout,
            1.0,
            30.0,
            (value) => setState(() => _cacheTimeout = value),
            '${_cacheTimeout.round()} min',
          ),
        ],
        const SizedBox(height: 16),
        _buildDropdownSetting('Rozmiar strony', _pageSize, {
          50: '50 wpisów',
          100: '100 wpisów',
          250: '250 wpisów',
          500: '500 wpisów',
          1000: '1000 wpisów',
        }, (value) => setState(() => _pageSize = value!)),
        const SizedBox(height: 16),
        _buildSwitchSetting(
          'Wstępne ładowanie',
          'Ładowanie danych w tle dla lepszej responsywności',
          _enablePreloading,
          (value) => setState(() => _enablePreloading = value),
        ),
        const SizedBox(height: 16),
        _buildSwitchSetting(
          'Optymalizacje',
          'Automatyczne optymalizacje wydajności',
          _enableOptimizations,
          (value) => setState(() => _enableOptimizations = value),
        ),
        const SizedBox(height: 16),
        _buildSwitchSetting(
          'Leniwe ładowanie',
          'Ładowanie widgetów tylko w razie potrzeby',
          _useLazyLoading,
          (value) => setState(() => _useLazyLoading = value),
        ),
      ],
    );
  }

  Widget _buildOptimizationSection() {
    final lastOptimization = _systemMetrics['lastOptimization'] as DateTime?;
    final timeSinceOptimization = lastOptimization != null
        ? DateTime.now().difference(lastOptimization)
        : null;

    return _buildPerformanceCard(
      'Optymalizacja',
      Icons.auto_fix_high_rounded,
      AppThemePro.realEstateViolet,
      [
        if (lastOptimization != null) ...[
          _buildInfoRow(
            'Ostatnia optymalizacja',
            timeSinceOptimization!.inHours > 0
                ? '${timeSinceOptimization.inHours}h ${timeSinceOptimization.inMinutes % 60}m temu'
                : '${timeSinceOptimization.inMinutes}m temu',
            Icons.schedule_rounded,
          ),
          const SizedBox(height: 16),
        ],
        ElevatedButton.icon(
          onPressed: _optimizePerformance,
          icon: const Icon(Icons.auto_fix_high_rounded),
          label: const Text('Uruchom optymalizację'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppThemePro.realEstateViolet,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Optymalizacja może poprawić wydajność poprzez:\n• Czyszczenie nieużywanych danych\n• Reorganizację cache\n• Kompresję danych\n• Optymalizację zapytań',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceInteractive.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.borderSecondary, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemePro.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheMetricRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppThemePro.textSecondary),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppThemePro.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String description,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppThemePro.accentGold,
          activeTrackColor: AppThemePro.accentGold.withOpacity(0.3),
          inactiveThumbColor: AppThemePro.textMuted,
          inactiveTrackColor: AppThemePro.surfaceInteractive,
        ),
      ],
    );
  }

  Widget _buildSliderSetting(
    String title,
    String description,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    String displayValue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              displayValue,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemePro.accentGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppThemePro.accentGold,
            inactiveTrackColor: AppThemePro.surfaceInteractive,
            thumbColor: AppThemePro.accentGold,
            overlayColor: AppThemePro.accentGold.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownSetting(
    String title,
    int value,
    Map<int, String> options,
    ValueChanged<int?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppThemePro.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppThemePro.surfaceInteractive,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppThemePro.borderSecondary, width: 1),
          ),
          child: DropdownButton<int>(
            value: value,
            onChanged: onChanged,
            items: options.entries.map((entry) {
              return DropdownMenuItem<int>(
                value: entry.key,
                child: Text(
                  entry.value,
                  style: const TextStyle(color: AppThemePro.textPrimary),
                ),
              );
            }).toList(),
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: AppThemePro.surfaceCard,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppThemePro.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppThemePro.textSecondary),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return ElevatedButton.icon(
      onPressed: _savePerformanceSettings,
      icon: const Icon(Icons.save_rounded),
      label: const Text('Zapisz ustawienia wydajności'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppThemePro.accentGold,
        foregroundColor: AppThemePro.primaryDark,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size.fromHeight(48),
      ),
    );
  }
}
