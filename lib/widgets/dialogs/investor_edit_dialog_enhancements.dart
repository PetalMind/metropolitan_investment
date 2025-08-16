import 'package:flutter/material.dart';
import '../../theme/app_theme_professional.dart';

/// 🎨 Rozszerzenia wizualne dla InvestorEditDialog
///
/// Dodatkowe komponenty i efekty wizualne dla profesjonalnego wyglądu:
/// - Animowane przejścia
/// - Responsywny layout
/// - Mikrointerakcje
/// - Efekty hover
/// - Ulepszone loading states

class PremiumDialogDecorations {
  /// Dekoracja dla głównego kontenera z efektem premium
  static BoxDecoration get premiumContainerDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppThemePro.backgroundPrimary,
        AppThemePro.backgroundPrimary.withBlue(8),
        AppThemePro.backgroundSecondary.withOpacity(0.3),
      ],
      stops: const [0.0, 0.7, 1.0],
    ),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: AppThemePro.accentGold.withOpacity(0.25),
      width: 2,
    ),
    boxShadow: [
      // Główny cień
      BoxShadow(
        color: Colors.black.withOpacity(0.5),
        blurRadius: 40,
        offset: const Offset(0, 20),
        spreadRadius: 8,
      ),
      // Złoty blask
      BoxShadow(
        color: AppThemePro.accentGold.withOpacity(0.12),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
      // Wewnętrzny blask
      BoxShadow(
        color: AppThemePro.accentGold.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 4),
        spreadRadius: -2,
      ),
    ],
  );

  /// Gradient dla sekcji header
  static LinearGradient get headerGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppThemePro.backgroundSecondary,
      AppThemePro.primaryMedium.withOpacity(0.8),
      AppThemePro.backgroundSecondary.withBlue(15),
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  /// Gradient dla sekcji footer
  static LinearGradient get footerGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppThemePro.backgroundSecondary.withOpacity(0.95),
      AppThemePro.backgroundSecondary,
      AppThemePro.primaryMedium.withOpacity(0.4),
    ],
    stops: const [0.0, 0.7, 1.0],
  );

  /// Dekoracja dla kart inwestycji z hover effect
  static BoxDecoration getInvestmentCardDecoration({
    bool isHovered = false,
    bool hasChanges = false,
  }) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: hasChanges
          ? [
              AppThemePro.statusWarning.withOpacity(0.05),
              AppThemePro.backgroundSecondary,
              AppThemePro.backgroundSecondary.withBlue(5),
            ]
          : [
              AppThemePro.backgroundSecondary,
              AppThemePro.backgroundSecondary.withBlue(8),
              AppThemePro.backgroundTertiary.withOpacity(0.3),
            ],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: hasChanges
          ? AppThemePro.statusWarning.withOpacity(0.4)
          : isHovered
          ? AppThemePro.accentGold.withOpacity(0.3)
          : AppThemePro.borderPrimary,
      width: hasChanges ? 2 : 1.5,
    ),
    boxShadow: [
      if (isHovered || hasChanges) ...[
        BoxShadow(
          color: hasChanges
              ? AppThemePro.statusWarning.withOpacity(0.2)
              : AppThemePro.accentGold.withOpacity(0.15),
          blurRadius: isHovered ? 16 : 12,
          offset: const Offset(0, 6),
        ),
      ] else ...[
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ],
  );

  /// Dekoracja dla pól input z focus effect
  static InputDecorationTheme getInputDecorationTheme() => InputDecorationTheme(
    filled: true,
    fillColor: AppThemePro.backgroundTertiary.withOpacity(0.6),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppThemePro.borderPrimary,
        width: 1.5,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppThemePro.borderPrimary,
        width: 1.5,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppThemePro.accentGold, width: 2.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppThemePro.statusError, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppThemePro.statusError, width: 2.5),
    ),
    labelStyle: const TextStyle(
      color: AppThemePro.textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    hintStyle: const TextStyle(
      color: AppThemePro.textMuted,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    prefixIconColor: AppThemePro.textSecondary,
    suffixIconColor: AppThemePro.textSecondary,
  );
}

/// Widget animowanego loading indicator dla premium UI
class PremiumLoadingIndicator extends StatefulWidget {
  final bool isLoading;
  final String? text;
  final Color? color;

  const PremiumLoadingIndicator({
    super.key,
    required this.isLoading,
    this.text,
    this.color,
  });

  @override
  State<PremiumLoadingIndicator> createState() =>
      _PremiumLoadingIndicatorState();
}

class _PremiumLoadingIndicatorState extends State<PremiumLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    if (widget.isLoading) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PremiumLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _controller.repeat(reverse: true);
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (widget.color ?? AppThemePro.accentGold).withOpacity(0.2),
                (widget.color ?? AppThemePro.accentGold).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (widget.color ?? AppThemePro.accentGold).withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.color ?? AppThemePro.accentGold,
                  ),
                ),
              ),
              if (widget.text != null) ...[
                const SizedBox(width: 12),
                Text(
                  widget.text!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: widget.color ?? AppThemePro.accentGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Widget z animowanym statusem zmiany
class ChangeStatusIndicator extends StatefulWidget {
  final bool hasChanges;
  final String? changeText;
  final String? noChangeText;

  const ChangeStatusIndicator({
    super.key,
    required this.hasChanges,
    this.changeText,
    this.noChangeText,
  });

  @override
  State<ChangeStatusIndicator> createState() => _ChangeStatusIndicatorState();
}

class _ChangeStatusIndicatorState extends State<ChangeStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    if (widget.hasChanges) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ChangeStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasChanges != oldWidget.hasChanges) {
      if (widget.hasChanges) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_scaleAnimation.value * 0.2),
          child: Opacity(
            opacity: widget.hasChanges ? 1.0 : 0.6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.hasChanges
                      ? [
                          AppThemePro.statusWarning.withOpacity(0.2),
                          AppThemePro.statusWarning.withOpacity(0.1),
                        ]
                      : [
                          AppThemePro.backgroundTertiary.withOpacity(0.6),
                          AppThemePro.backgroundTertiary.withOpacity(0.3),
                        ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.hasChanges
                      ? AppThemePro.statusWarning.withOpacity(0.4)
                      : AppThemePro.borderSecondary,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.hasChanges) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppThemePro.statusWarning,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppThemePro.statusWarning.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: AppThemePro.textMuted,
                    ),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    widget.hasChanges
                        ? (widget.changeText ?? 'ZMIANY OCZEKUJĄ')
                        : (widget.noChangeText ?? 'GOTOWY DO EDYCJI'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: widget.hasChanges
                          ? AppThemePro.statusWarning
                          : AppThemePro.textMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Responsywne breakpoints dla dialog
class DialogBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double ultrawide = 1600;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobile &&
      MediaQuery.of(context).size.width < desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  static double getDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < mobile) return screenWidth * 0.95;
    if (screenWidth < tablet) return screenWidth * 0.9;
    if (screenWidth < desktop) return screenWidth * 0.85;
    if (screenWidth < ultrawide) return 1200;
    return 1400;
  }

  static double getDialogHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (isMobile(context)) return screenHeight * 0.95;
    return screenHeight * 0.92;
  }

  static EdgeInsets getDialogPadding(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.all(16);
    if (isTablet(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.all(32);
  }
}
