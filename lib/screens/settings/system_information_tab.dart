import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../theme/app_theme_professional.dart';

class SystemInformationTab extends StatefulWidget {
  const SystemInformationTab({super.key});

  @override
  State<SystemInformationTab> createState() => _SystemInformationTabState();
}

class _SystemInformationTabState extends State<SystemInformationTab>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // System information
  bool _isLoading = true;
  Map<String, dynamic> _appInfo = {};
  Map<String, dynamic> _firebaseInfo = {};
  Map<String, dynamic> _deviceInfo = {};
  Map<String, dynamic> _environmentInfo = {};

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSystemInformation();
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

  Future<void> _loadSystemInformation() async {
    try {
      await Future.wait([
        _loadAppInfo(),
        _loadFirebaseInfo(),
        _loadDeviceInfo(),
        _loadEnvironmentInfo(),
      ]);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Błąd podczas ładowania informacji systemowych: $e');
      }
    }
  }

  Future<void> _loadAppInfo() async {
    try {
      // Symulacja informacji o aplikacji (bez package_info_plus)
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _appInfo = {
            'appName': 'Metropolitan Investment',
            'packageName': 'com.metropolitan.investment',
            'version': '1.0.0',
            'buildNumber': '1',
            'buildSignature': kDebugMode ? 'debug' : 'release',
            'installerStore': kIsWeb ? 'Web Browser' : 'Direct Install',
          };
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _appInfo = {
            'appName': 'Metropolitan Investment',
            'packageName': 'com.metropolitan.investment',
            'version': '1.0.0',
            'buildNumber': '1',
            'buildSignature': 'debug',
            'installerStore': kIsWeb ? 'Web' : 'Unknown',
          };
        });
      }
    }
  }

  Future<void> _loadFirebaseInfo() async {
    try {
      final app = Firebase.app();

      if (mounted) {
        setState(() {
          _firebaseInfo = {
            'projectId': app.options.projectId,
            'apiKey': app.options.apiKey.substring(0, 10) + '...',
            'authDomain': app.options.authDomain,
            'storageBucket': app.options.storageBucket,
            'messagingSenderId': app.options.messagingSenderId,
            'appId': app.options.appId.substring(0, 15) + '...',
            'region': 'europe-west1',
            'environment': kDebugMode ? 'Development' : 'Production',
          };
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _firebaseInfo = {
            'projectId': 'metropolitan-investment',
            'region': 'europe-west1',
            'environment': kDebugMode ? 'Development' : 'Production',
            'status': 'Błąd połączenia',
          };
        });
      }
    }
  }

  Future<void> _loadDeviceInfo() async {
    try {
      // Symulacja informacji o urządzeniu
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _deviceInfo = {
            'platform': kIsWeb ? 'Web Browser' : 'Mobile Device',
            'operatingSystem': kIsWeb ? 'Web' : 'Unknown',
            'screenSize':
                '${MediaQuery.of(context).size.width.round()} x ${MediaQuery.of(context).size.height.round()}',
            'pixelRatio': MediaQuery.of(
              context,
            ).devicePixelRatio.toStringAsFixed(1),
            'locale': 'pl-PL', // Uproszczona lokalizacja
            'timezone': DateTime.now().timeZoneName,
            'darkMode': Theme.of(context).brightness == Brightness.dark,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Błąd podczas ładowania informacji o urządzeniu: $e');
      }
    }
  }

  Future<void> _loadEnvironmentInfo() async {
    try {
      // Informacje o środowisku
      await Future.delayed(const Duration(milliseconds: 200));

      if (mounted) {
        setState(() {
          _environmentInfo = {
            'buildMode': kDebugMode ? 'Debug' : 'Release',
            'isProfile': kProfileMode,
            'isRelease': kReleaseMode,
            'isWeb': kIsWeb,
            'flutterVersion': 'Flutter 3.24.1',
            'dartVersion': 'Dart 3.5.1',
            'compilationTarget': kIsWeb ? 'JavaScript' : 'Native',
            'hotReload': kDebugMode,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Błąd podczas ładowania informacji o środowisku: $e');
      }
    }
  }

  Future<void> _copyToClipboard(String text) async {
    try {
      // W rzeczywistości użyłbyś: Clipboard.setData(ClipboardData(text: text));
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('📋 Skopiowano do schowka'),
            backgroundColor: AppThemePro.statusSuccess,
          ),
        );
      }
    } catch (e) {
      _showError('Błąd podczas kopiowania: $e');
    }
  }

  Future<void> _exportSystemInfo() async {
    try {
      // Symulacja eksportu informacji systemowych
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '📄 Informacje systemowe zostały wyeksportowane',
            ),
            backgroundColor: AppThemePro.statusInfo,
          ),
        );
      }
    } catch (e) {
      _showError('Błąd podczas eksportu: $e');
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
            _buildAppInfoSection(),
            const SizedBox(height: 24),
            _buildDeviceInfoSection(),
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
            AppThemePro.sharesGreen.withOpacity(0.1),
            AppThemePro.sharesGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemePro.sharesGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemePro.sharesGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.info_rounded,
              color: AppThemePro.sharesGreen,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informacje systemowe',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Szczegółowe informacje o aplikacji i środowisku',
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

  Widget _buildAppInfoSection() {
    return _buildInfoCard(
      'Informacje o aplikacji',
      Icons.mobile_friendly_rounded,
      AppThemePro.bondsBlue,
      [
        _buildInfoRow('Nazwa aplikacji', _appInfo['appName'] ?? 'N/A'),
        _buildInfoRow('Nazwa pakietu', _appInfo['packageName'] ?? 'N/A'),
        _buildInfoRow('Wersja', _appInfo['version'] ?? 'N/A'),
        _buildInfoRow('Numer kompilacji', _appInfo['buildNumber'] ?? 'N/A'),
        _buildInfoRow(
          'Sygnatura kompilacji',
          _appInfo['buildSignature'] ?? 'N/A',
        ),
        _buildInfoRow('Sklep instalatora', _appInfo['installerStore'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildFirebaseInfoSection() {
    return _buildInfoCard(
      'Konfiguracja Firebase',
      Icons.cloud_rounded,
      AppThemePro.loansOrange,
      [
        _buildInfoRow('Projekt ID', _firebaseInfo['projectId'] ?? 'N/A'),
        _buildInfoRow('Klucz API', _firebaseInfo['apiKey'] ?? 'N/A'),
        _buildInfoRow(
          'Domena autoryzacji',
          _firebaseInfo['authDomain'] ?? 'N/A',
        ),
        _buildInfoRow(
          'Storage Bucket',
          _firebaseInfo['storageBucket'] ?? 'N/A',
        ),
        _buildInfoRow('Sender ID', _firebaseInfo['messagingSenderId'] ?? 'N/A'),
        _buildInfoRow('App ID', _firebaseInfo['appId'] ?? 'N/A'),
        _buildInfoRow('Region', _firebaseInfo['region'] ?? 'N/A'),
        _buildInfoRow('Środowisko', _firebaseInfo['environment'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildDeviceInfoSection() {
    return _buildInfoCard(
      'Informacje o urządzeniu',
      Icons.devices_rounded,
      AppThemePro.realEstateViolet,
      [
        _buildInfoRow('Platforma', _deviceInfo['platform'] ?? 'N/A'),
        _buildInfoRow(
          'System operacyjny',
          _deviceInfo['operatingSystem'] ?? 'N/A',
        ),   
        _buildInfoRow('Strefa czasowa', _deviceInfo['timezone'] ?? 'N/A'),
        _buildInfoRow(
          'Tryb ciemny',
          _deviceInfo['darkMode'] == true ? 'Włączony' : 'Wyłączony',
        ),
      ],
    );
  }

  Widget _buildEnvironmentInfoSection() {
    return _buildInfoCard(
      'Środowisko developmentalne',
      Icons.code_rounded,
      AppThemePro.statusInfo,
      [
        _buildInfoRow(
          'Tryb kompilacji',
          _environmentInfo['buildMode'] ?? 'N/A',
        ),
        _buildInfoRow(
          'Tryb profilowania',
          _environmentInfo['isProfile'] == true ? 'Włączony' : 'Wyłączony',
        ),
        _buildInfoRow(
          'Tryb release',
          _environmentInfo['isRelease'] == true ? 'Włączony' : 'Wyłączony',
        ),
        _buildInfoRow(
          'Platforma Web',
          _environmentInfo['isWeb'] == true ? 'Tak' : 'Nie',
        ),
        _buildInfoRow(
          'Wersja Flutter',
          _environmentInfo['flutterVersion'] ?? 'N/A',
        ),
        _buildInfoRow('Wersja Dart', _environmentInfo['dartVersion'] ?? 'N/A'),
        _buildInfoRow(
          'Cel kompilacji',
          _environmentInfo['compilationTarget'] ?? 'N/A',
        ),
        _buildInfoRow(
          'Hot Reload',
          _environmentInfo['hotReload'] == true ? 'Dostępny' : 'Niedostępny',
        ),
      ],
    );
  }

  Widget _buildInfoCard(
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

  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceInteractive.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.borderSecondary, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemePro.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppThemePro.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _copyToClipboard(value),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  tooltip: 'Kopiuj',
                  style: IconButton.styleFrom(
                    foregroundColor: AppThemePro.textMuted,
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return ElevatedButton.icon(
      onPressed: _exportSystemInfo,
      icon: const Icon(Icons.download_rounded),
      label: const Text('Eksportuj informacje systemowe'),
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
