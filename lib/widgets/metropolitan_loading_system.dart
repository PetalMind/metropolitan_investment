import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme_professional.dart';
import 'metropolitan_logo_widget.dart';

/// 🏛️ **Metropolitan Loading System**
///
/// Unified loading system dla całej aplikacji Metropolitan Investment
/// Wykorzystuje brand guidelines i professional animations
///
/// **Typy ładowania:**
/// • 📊 Dane finansowe
/// • 👥 Klienci i inwestorzy
/// • 📈 Analityka i raporty
/// • 🏢 Produkty i portfolio
/// • ⚙️ Konfiguracja i ustawienia
class MetropolitanLoadingSystem {
  /// **Loading steps dla różnych typów danych**
  static const Map<MetropolitanLoadingType, List<String>> _loadingSteps = {
    MetropolitanLoadingType.financial: [
      'Łączenie z bazą danych finansowych...',
      'Pobieranie aktualnych kursów...',
      'Obliczanie wartości portfela...',
      'Synchronizacja transakcji...',
      'Aktualizacja wskaźników...',
      'Finalizacja obliczeń...',
    ],
    MetropolitanLoadingType.clients: [
      'Ładowanie danych klientów...',
      'Weryfikacja statusów inwestorów...',
      'Pobieranie historii inwestycji...',
      'Synchronizacja profili...',
      'Aktualizacja statystyk...',
      'Przygotowywanie widoku...',
    ],
    MetropolitanLoadingType.analytics: [
      'Inicjalizacja modułu analitycznego...',
      'Pobieranie danych historycznych...',
      'Przetwarzanie wskaźników...',
      'Generowanie wykresów...',
      'Obliczanie trendów...',
      'Optymalizacja wyświetlania...',
    ],
    MetropolitanLoadingType.products: [
      'Ładowanie katalogu produktów...',
      'Pobieranie szczegółów inwestycji...',
      'Synchronizacja dostępności...',
      'Aktualizacja cen i warunków...',
      'Weryfikacja uprawnień...',
      'Przygotowywanie oferty...',
    ],
    MetropolitanLoadingType.settings: [
      'Ładowanie konfiguracji...',
      'Weryfikacja uprawnień...',
      'Synchronizacja ustawień...',
      'Aktualizacja profilu...',
      'Sprawdzanie bezpieczeństwa...',
      'Finalizacja zmian...',
    ],
    MetropolitanLoadingType.calendar: [
      'Ładowanie kalendarza...',
      'Pobieranie wydarzeń...',
      'Synchronizacja terminów...',
      'Aktualizacja powiadomień...',
      'Weryfikacja dostępności...',
      'Przygotowywanie widoku...',
    ],
    MetropolitanLoadingType.employees: [
      'Ładowanie danych pracowników...',
      'Weryfikacja uprawnień dostępu...',
      'Pobieranie informacji o rolach...',
      'Synchronizacja kontaktów...',
      'Aktualizacja struktur...',
      'Przygotowywanie interfejsu...',
    ],
  };

  /// **Loading icons dla różnych typów**
  static const Map<MetropolitanLoadingType, String> _loadingIcons = {
    MetropolitanLoadingType.financial: '💰',
    MetropolitanLoadingType.clients: '👥',
    MetropolitanLoadingType.analytics: '📊',
    MetropolitanLoadingType.products: '🏢',
    MetropolitanLoadingType.settings: '⚙️',
    MetropolitanLoadingType.calendar: '📅',
    MetropolitanLoadingType.employees: '👔',
  };
}

/// **Typy ładowania danych**
enum MetropolitanLoadingType {
  financial,
  clients,
  analytics,
  products,
  settings,
  calendar,
  employees,
}

/// **MetropolitanLoadingWidget - Główny widget ładowania**
class MetropolitanLoadingWidget extends StatefulWidget {
  final MetropolitanLoadingType type;
  final String? customMessage;
  final double? progress;
  final bool showProgress;
  final Color? accentColor;
  final MetropolitanLoadingStyle style;
  final Duration stepDuration;

  const MetropolitanLoadingWidget({
    super.key,
    required this.type,
    this.customMessage,
    this.progress,
    this.showProgress = false,
    this.accentColor,
    this.style = MetropolitanLoadingStyle.full,
    this.stepDuration = const Duration(milliseconds: 1200),
  });

  /// Loading dla pulpitu finansowego
  const MetropolitanLoadingWidget.financial({
    super.key,
    this.customMessage,
    this.progress,
    this.showProgress = true,
    this.accentColor,
    this.stepDuration = const Duration(milliseconds: 1000),
  }) : type = MetropolitanLoadingType.financial,
       style = MetropolitanLoadingStyle.full;

  /// Loading dla klientów
  const MetropolitanLoadingWidget.clients({
    super.key,
    this.customMessage,
    this.progress,
    this.showProgress = false,
    this.accentColor,
    this.stepDuration = const Duration(milliseconds: 1200),
  }) : type = MetropolitanLoadingType.clients,
       style = MetropolitanLoadingStyle.compact;

  /// Loading dla analityki
  const MetropolitanLoadingWidget.analytics({
    super.key,
    this.customMessage,
    this.progress,
    this.showProgress = true,
    this.accentColor,
    this.stepDuration = const Duration(milliseconds: 800),
  }) : type = MetropolitanLoadingType.analytics,
       style = MetropolitanLoadingStyle.full;

  /// Loading dla produktów
  const MetropolitanLoadingWidget.products({
    super.key,
    this.customMessage,
    this.progress,
    this.showProgress = true,
    this.accentColor,
    this.stepDuration = const Duration(milliseconds: 800),
  }) : type = MetropolitanLoadingType.products,
       style = MetropolitanLoadingStyle.full;

  /// Loading dla kalendarza
  const MetropolitanLoadingWidget.calendar({
    super.key,
    this.customMessage,
    this.progress,
    this.showProgress = true,
    this.accentColor,
    this.stepDuration = const Duration(milliseconds: 800),
  }) : type = MetropolitanLoadingType.calendar,
       style = MetropolitanLoadingStyle.full;

  /// Loading dla pracowników
  const MetropolitanLoadingWidget.employees({
    super.key,
    this.customMessage,
    this.progress,
    this.showProgress = true,
    this.accentColor,
    this.stepDuration = const Duration(milliseconds: 800),
  }) : type = MetropolitanLoadingType.employees,
       style = MetropolitanLoadingStyle.full;

  /// Loading dla ustawień
  const MetropolitanLoadingWidget.settings({
    super.key,
    this.customMessage,
    this.progress,
    this.showProgress = true,
    this.accentColor,
    this.stepDuration = const Duration(milliseconds: 800),
  }) : type = MetropolitanLoadingType.settings,
       style = MetropolitanLoadingStyle.full;

  /// Loading kompaktowy
  const MetropolitanLoadingWidget.compact({
    super.key,
    required this.type,
    this.customMessage,
    this.progress,
    this.showProgress = false,
    this.accentColor,
    this.stepDuration = const Duration(milliseconds: 1500),
  }) : style = MetropolitanLoadingStyle.compact;

  @override
  State<MetropolitanLoadingWidget> createState() =>
      _MetropolitanLoadingWidgetState();
}

class _MetropolitanLoadingWidgetState extends State<MetropolitanLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  int _currentStepIndex = 0;
  String _currentMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startLoadingSequence();
  }

  void _initializeAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Start animations
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
    _shimmerController.repeat();
  }

  void _startLoadingSequence() {
    final steps = MetropolitanLoadingSystem._loadingSteps[widget.type] ?? [];
    if (steps.isEmpty) return;

    setState(() {
      _currentMessage = steps[0];
    });

    // Cycle through loading steps
    Timer.periodic(widget.stepDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentStepIndex = (_currentStepIndex + 1) % steps.length;
        _currentMessage = steps[_currentStepIndex];
      });
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor ?? AppThemePro.accentGold;
    final icon = MetropolitanLoadingSystem._loadingIcons[widget.type] ?? '🏛️';

    switch (widget.style) {
      case MetropolitanLoadingStyle.full:
        return _buildFullLoading(accentColor, icon);
      case MetropolitanLoadingStyle.compact:
        return _buildCompactLoading(accentColor, icon);
      case MetropolitanLoadingStyle.minimal:
        return _buildMinimalLoading(accentColor, icon);
    }
  }

  Widget _buildFullLoading(Color accentColor, String icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo section
          Container(
            margin: const EdgeInsets.only(bottom: 32),
            child: const MetropolitanLogoWidget(
              size: 100,
              animated: true,
              style: MetropolitanLogoStyle.premium,
            ),
          ),

          // Loading indicator
          _buildLoadingIndicator(accentColor, icon, size: 80),

          const SizedBox(height: 32),

          // Progress bar (if enabled)
          if (widget.showProgress && widget.progress != null)
            _buildProgressBar(accentColor),

          const SizedBox(height: 24),

          // Loading message
          _buildLoadingMessage(),

          const SizedBox(height: 16),

          // Loading dots animation
          _buildLoadingDots(),
        ],
      ),
    );
  }

  Widget _buildCompactLoading(Color accentColor, String icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLoadingIndicator(accentColor, icon, size: 40),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLoadingMessage(compact: true),
                const SizedBox(height: 8),
                _buildLoadingDots(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalLoading(Color accentColor, String icon) {
    return Center(child: _buildLoadingIndicator(accentColor, icon, size: 24));
  }

  Widget _buildLoadingIndicator(
    Color accentColor,
    String icon, {
    required double size,
  }) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),

                // Inner progress circle
                Container(
                  width: size * 0.8,
                  height: size * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withOpacity(0.8),
                        accentColor.withOpacity(0.4),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(icon, style: TextStyle(fontSize: size * 0.3)),
                  ),
                ),

                // Shimmer effect
                AnimatedBuilder(
                  animation: _shimmerAnimation,
                  builder: (context, child) {
                    return Positioned.fill(
                      child: ClipOval(
                        child: Transform.translate(
                          offset: Offset(size * _shimmerAnimation.value, 0),
                          child: Container(
                            width: size * 0.3,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  accentColor.withOpacity(0.4),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(Color accentColor) {
    return Container(
      width: 200,
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: AppThemePro.surfaceInteractive,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widget.progress ?? 0.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [accentColor, accentColor.withOpacity(0.7)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingMessage({bool compact = false}) {
    final message = widget.customMessage ?? _currentMessage;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        message,
        key: ValueKey(message),
        style: TextStyle(
          fontSize: compact ? 14 : 16,
          fontWeight: FontWeight.w500,
          color: AppThemePro.textSecondary,
        ),
        textAlign: compact ? TextAlign.left : TextAlign.center,
        maxLines: compact ? 2 : 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final progress = (_rotationAnimation.value + delay) % 1.0;
            final opacity = (math.sin(progress * math.pi * 2) + 1) / 2;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppThemePro.textTertiary.withOpacity(opacity),
              ),
            );
          }),
        );
      },
    );
  }
}

/// **Style wyświetlania loading**
enum MetropolitanLoadingStyle {
  /// Pełny ekran z logo i animacjami
  full,

  /// Kompaktowy w rzędzie z tekstem
  compact,

  /// Minimalny - tylko spinner
  minimal,
}

/// **Helper Extension dla łatwego używania**
extension MetropolitanLoadingExtensions on Widget {
  /// Owiń widget w loading overlay
  Widget withMetropolitanLoading({
    required bool isLoading,
    MetropolitanLoadingType type = MetropolitanLoadingType.financial,
    String? message,
    MetropolitanLoadingStyle style = MetropolitanLoadingStyle.full,
  }) {
    return Stack(
      children: [
        this,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: AppThemePro.backgroundPrimary.withOpacity(0.8),
              child: Center(
                child: MetropolitanLoadingWidget(
                  type: type,
                  customMessage: message,
                  style: style,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
