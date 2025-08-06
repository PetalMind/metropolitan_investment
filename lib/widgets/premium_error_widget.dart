import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Premium error widget z animacjami zgodny z motywem aplikacji
class PremiumErrorWidget extends StatefulWidget {
  final String error;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final IconData? errorIcon;
  final bool showDetails;

  const PremiumErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.retryButtonText,
    this.errorIcon,
    this.showDetails = false,
  });

  @override
  State<PremiumErrorWidget> createState() => _PremiumErrorWidgetState();
}

class _PremiumErrorWidgetState extends State<PremiumErrorWidget>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _fadeController;
  late AnimationController _shakeController;

  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;

  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _bounceController.forward();
      }
    });
  }

  void _playShakeAnimation() {
    _shakeController.reset();
    _shakeController.forward();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _fadeController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.errorBackground,
                AppTheme.errorBackground.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.errorPrimary.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.errorPrimary.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animowana ikona błędu
              ScaleTransition(
                scale: _bounceAnimation,
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    final shakeOffset = Offset(
                      _shakeAnimation.value *
                          8 *
                          (1 - _shakeAnimation.value) *
                          ((_shakeAnimation.value * 6).floor() % 2 == 0
                              ? 1
                              : -1),
                      0,
                    );

                    return Transform.translate(
                      offset: shakeOffset,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.errorPrimary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: AppTheme.errorPrimary.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          widget.errorIcon ?? Icons.error_outline,
                          size: 40,
                          color: AppTheme.errorPrimary,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Tytuł błędu
              Text(
                'Wystąpił błąd',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Podstawowy opis błędu
              Text(
                _getSimplifiedErrorMessage(),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),

              if (widget.showDetails || _showDetails) ...[
                const SizedBox(height: 16),

                // Szczegółowy błąd
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundPrimary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.errorPrimary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.bug_report,
                            size: 16,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Szczegóły błędu:',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.textTertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        widget.error,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Przyciski akcji
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  if (widget.onRetry != null)
                    ElevatedButton.icon(
                      onPressed: () {
                        _playShakeAnimation();
                        widget.onRetry!();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(widget.retryButtonText ?? 'Spróbuj ponownie'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryGold,
                        foregroundColor: AppTheme.textOnSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),

                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showDetails = !_showDetails;
                      });
                    },
                    icon: Icon(
                      _showDetails ? Icons.visibility_off : Icons.visibility,
                    ),
                    label: Text(
                      _showDetails ? 'Ukryj szczegóły' : 'Pokaż szczegóły',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: BorderSide(
                        color: AppTheme.textSecondary.withOpacity(0.3),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Wskazówki dla użytkownika
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSecondary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: AppTheme.secondaryAmber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sprawdź połączenie z internetem lub skontaktuj się z administratorem',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSimplifiedErrorMessage() {
    // Uproszczenie błędów dla użytkownika
    final errorLower = widget.error.toLowerCase();

    if (errorLower.contains('network') ||
        errorLower.contains('internet') ||
        errorLower.contains('connection')) {
      return 'Problem z połączeniem internetowym';
    }

    if (errorLower.contains('permission') ||
        errorLower.contains('unauthorized')) {
      return 'Brak uprawnień do wykonania operacji';
    }

    if (errorLower.contains('timeout')) {
      return 'Przekroczono limit czasu operacji';
    }

    if (errorLower.contains('not found') || errorLower.contains('404')) {
      return 'Nie znaleziono żądanych danych';
    }

    if (errorLower.contains('server') || errorLower.contains('500')) {
      return 'Problem z serwerem';
    }

    // Domyślny komunikat
    return 'Nie udało się wykonać operacji';
  }
}
