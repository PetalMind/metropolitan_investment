import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Premium loading widget z animacjami zgodny z motywem aplikacji
class PremiumLoadingWidget extends StatefulWidget {
  final String? message;
  final Color? primaryColor;
  final Color? secondaryColor;
  final double size;

  const PremiumLoadingWidget({
    super.key,
    this.message,
    this.primaryColor,
    this.secondaryColor,
    this.size = 60.0,
  });

  @override
  State<PremiumLoadingWidget> createState() => _PremiumLoadingWidgetState();
}

class _PremiumLoadingWidgetState extends State<PremiumLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Loading indicator z animacjami
            AnimatedBuilder(
              animation: Listenable.merge([
                _rotationAnimation,
                _pulseAnimation,
              ]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value * 2 * math.pi,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.primaryColor ?? AppTheme.secondaryGold,
                            widget.secondaryColor ?? AppTheme.secondaryCopper,
                            widget.primaryColor ?? AppTheme.secondaryGold,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(widget.size / 2),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (widget.primaryColor ?? AppTheme.secondaryGold)
                                    .withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Wewnętrzny krąg z gradientem
                          Center(
                            child: Container(
                              width: widget.size * 0.6,
                              height: widget.size * 0.6,
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundPrimary,
                                borderRadius: BorderRadius.circular(
                                  widget.size * 0.3,
                                ),
                                border: Border.all(
                                  color:
                                      (widget.primaryColor ??
                                              AppTheme.secondaryGold)
                                          .withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            if (widget.message != null) ...[
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  widget.message!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              // Animowane kropki w tekście
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final dots = List.generate(3, (index) {
                    final delay = index * 0.3;
                    final progress = (_pulseController.value + delay) % 1.0;
                    final opacity = progress < 0.5
                        ? progress * 2
                        : (1.0 - progress) * 2;

                    return Text(
                      '•',
                      style: TextStyle(
                        color: AppTheme.secondaryGold.withOpacity(
                          opacity.clamp(0.2, 1.0),
                        ),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  });

                  return Row(mainAxisSize: MainAxisSize.min, children: dots);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
