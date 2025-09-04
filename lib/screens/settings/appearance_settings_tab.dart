import 'package:flutter/material.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';

class AppearanceSettingsTab extends StatefulWidget {
  const AppearanceSettingsTab({super.key});

  @override
  State<AppearanceSettingsTab> createState() => _AppearanceSettingsTabState();
}

class _AppearanceSettingsTabState extends State<AppearanceSettingsTab>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // User preferences state
  bool _enableAnimations = true;
  bool _enableSounds = false;
  double _animationSpeed = 1.0;
  String _language = 'pl';
  String _dateFormat = 'dd/MM/yyyy';
  String _numberFormat = 'pl';
  String _theme = 'professional';

  bool _isLoading = true;
  bool _isSaving = false;
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeAndLoadPreferences();
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

  Future<void> _initializeAndLoadPreferences() async {
    try {
      // Simulate preference loading since UserPreferencesService isn't implemented yet
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadUserPreferences();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Błąd podczas inicjalizacji: $e');
      }
    }
  }

  Future<void> _loadUserPreferences() async {
    try {
      // Symulacja ładowania preferencji użytkownika (można rozszerzyć)
      // Do implementacji: ładowanie z Firestore lub SharedPreferences
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _enableAnimations = true;
          _enableSounds = false;
          _animationSpeed = 1.0;
          _language = 'pl';
          _dateFormat = 'dd/MM/yyyy';
          _numberFormat = 'pl';
          _theme = 'professional';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Błąd podczas ładowania preferencji: $e');
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);

    try {
      // Symulacja zapisywania preferencji
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Preferencje zostały zapisane'),
            backgroundColor: AppThemePro.statusSuccess,
          ),
        );
      }
    } catch (e) {
      _showError('Błąd podczas zapisywania: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
            _buildThemeSection(),
            const SizedBox(height: 24),
            _buildLanguageSection(),
            const SizedBox(height: 24),
            _buildAnimationSection(),
            const SizedBox(height: 24),
            _buildFormatSection(),
            const SizedBox(height: 24),
            _buildAudioSection(),
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
            AppThemePro.realEstateViolet.withOpacity(0.1),
            AppThemePro.realEstateViolet.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.realEstateViolet.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemePro.realEstateViolet.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.palette_rounded,
              color: AppThemePro.realEstateViolet,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personalizacja wyglądu',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dostosuj interfejs aplikacji do swoich preferencji',
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

  Widget _buildThemeSection() {
    return _buildSettingsCard(
      'Motyw aplikacji',
      Icons.brush_rounded,
      AppThemePro.realEstateViolet,
      [
        _buildRadioTile(
          'Profesjonalny ciemny',
          'professional',
          _theme,
          (value) => setState(() => _theme = value!),
          'Dedykowany dla analiz finansowych',
        ),
        _buildRadioTile(
          'Klasyczny',
          'classic',
          _theme,
          (value) => setState(() => _theme = value!),
          'Tradycyjny interfejs biznesowy',
        ),
        _buildRadioTile(
          'Wysokiego kontrastu',
          'high_contrast',
          _theme,
          (value) => setState(() => _theme = value!),
          'Zwiększona czytelność',
        ),
      ],
    );
  }

  Widget _buildLanguageSection() {
    return _buildSettingsCard(
      'Język i lokalizacja',
      Icons.language_rounded,
      AppThemePro.statusInfo,
      [
        _buildDropdownSetting('Język interfejsu', _language, {
          'pl': 'Polski',
          'en': 'English',
          'de': 'Deutsch',
        }, (value) => setState(() => _language = value!)),
        _buildDropdownSetting('Format daty', _dateFormat, {
          'dd/MM/yyyy': 'DD/MM/RRRR (31/12/2024)',
          'MM/dd/yyyy': 'MM/DD/RRRR (12/31/2024)',
          'yyyy-MM-dd': 'RRRR-MM-DD (2024-12-31)',
          'dd.MM.yyyy': 'DD.MM.RRRR (31.12.2024)',
        }, (value) => setState(() => _dateFormat = value!)),
        _buildDropdownSetting(
          'Format liczb',
          _numberFormat,
          {
            'pl': 'Polski (1 234,56 zł)',
            'en': 'Angielski (1,234.56 PLN)',
            'de': 'Niemiecki (1.234,56 PLN)',
          },
          (value) => setState(() => _numberFormat = value!),
        ),
      ],
    );
  }

  Widget _buildAnimationSection() {
    return _buildSettingsCard(
      'Animacje i przejścia',
      Icons.animation_rounded,
      AppThemePro.sharesGreen,
      [
        _buildSwitchSetting(
          'Włącz animacje',
          'Płynne przejścia między ekranami',
          _enableAnimations,
          (value) => setState(() => _enableAnimations = value),
        ),
        if (_enableAnimations) ...[
          const SizedBox(height: 16),
          _buildSliderSetting(
            'Szybkość animacji',
            'Kontroluje tempo przejść i efektów',
            _animationSpeed,
            0.5,
            2.0,
            (value) => setState(() => _animationSpeed = value),
            '${(_animationSpeed * 100).round()}%',
          ),
        ],
      ],
    );
  }

  Widget _buildFormatSection() {
    return _buildSettingsCard(
      'Formatowanie danych',
      Icons.format_list_numbered_rounded,
      AppThemePro.bondsBlue,
      [
        _buildInfoTile(
          'Waluta domyślna',
          'PLN (Polski złoty)',
          Icons.attach_money_rounded,
        ),
        _buildInfoTile(
          'Strefa czasowa',
          'Europe/Warsaw (UTC+1)',
          Icons.schedule_rounded,
        ),
        _buildInfoTile(
          'Format procentowy',
          '12,34% (z przecinkiem)',
          Icons.percent_rounded,
        ),
      ],
    );
  }

  Widget _buildAudioSection() {
    return _buildSettingsCard(
      'Efekty dźwiękowe',
      Icons.volume_up_rounded,
      AppThemePro.loansOrange,
      [
        _buildSwitchSetting(
          'Dźwięki systemowe',
          'Sygnały audio dla powiadomień i akcji',
          _enableSounds,
          (value) => setState(() => _enableSounds = value),
        ),
        if (_enableSounds) ...[
          const SizedBox(height: 16),
          _buildActionTile(
            'Test dźwięku',
            'Odtwórz przykładowy sygnał',
            Icons.play_circle_rounded,
            () => _testSound(),
          ),
        ],
      ],
    );
  }

  Widget _buildSettingsCard(
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

  Widget _buildRadioTile(
    String title,
    String value,
    String groupValue,
    ValueChanged<String?> onChanged,
    String description,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile<String>(
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppThemePro.textPrimary),
        ),
        subtitle: Text(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
        ),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: AppThemePro.accentGold,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String value,
    Map<String, String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
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
            child: DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              items: options.entries.map((entry) {
                return DropdownMenuItem<String>(
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
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String description,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
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
      ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
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
              divisions: 15,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
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
          Icon(icon, color: AppThemePro.textSecondary, size: 20),
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppThemePro.accentGold, size: 20),
                const SizedBox(width: 12),
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
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppThemePro.textMuted,
                        ),
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
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _savePreferences,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppThemePro.primaryDark,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_isSaving ? 'Zapisywanie...' : 'Zapisz ustawienia'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemePro.accentGold,
              foregroundColor: AppThemePro.primaryDark,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _loadUserPreferences,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Przywróć'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _testSound() async {
    try {
      // Użyj DashboardAudioService do testowania dźwięku
      final audioService = DashboardAudioService();
      await audioService.initialize();
      await audioService.playNotificationSound();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔊 Test dźwięku odtworzony'),
            backgroundColor: AppThemePro.statusSuccess,
          ),
        );
      }
    } catch (e) {
      _showError('Błąd podczas testowania dźwięku: $e');
    }
  }
}
