import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Ekran ładowania aplikacji z animowanym logo Metropolitan
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late AnimationController _pulseController;
  late AnimationController _progressController;

  late Animation<double> _backgroundAnimation;
  late Animation<double> _contentAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  void _startSplashSequence() {
    // Animacja tła
    _backgroundController.forward();

    // Animacja zawartości po krótkiej przerwie
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _contentController.forward();
        _pulseController.repeat(reverse: true);
      }
    });

    // Progress bar
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _progressController.forward();
      }
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_backgroundAnimation, _contentAnimation]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withOpacity(_backgroundAnimation.value),
                  AppTheme.backgroundPrimary.withOpacity(
                    _backgroundAnimation.value,
                  ),
                  AppTheme.backgroundSecondary.withOpacity(
                    _backgroundAnimation.value,
                  ),
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _contentAnimation,
                  child: _buildLoadingContent(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingContent() {
    const double logoSize = 160.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo z animacją pulse
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(logoSize * 0.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(logoSize * 0.2),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                    ),
                    padding: EdgeInsets.all(logoSize * 0.1),
                    child: Image.asset(
                      'assets/logos/logo.png',
                      width: logoSize * 0.8,
                      height: logoSize * 0.8,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        SizedBox(height: logoSize * 0.3),

        // Tekst aplikacji
        Column(
          children: [
            Text(
              'METROPOLITAN',
              style: TextStyle(
                fontSize: logoSize * 0.15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: logoSize * 0.02,
                height: 1.1,
              ),
            ),
            SizedBox(height: logoSize * 0.05),
            Text(
              'INVESTMENT',
              style: TextStyle(
                fontSize: logoSize * 0.1,
                fontWeight: FontWeight.w400,
                color: AppTheme.secondaryGold,
                letterSpacing: logoSize * 0.015,
                height: 1.2,
              ),
            ),
            SizedBox(height: logoSize * 0.1),
            Text(
              'Ładowanie...',
              style: TextStyle(
                fontSize: logoSize * 0.08,
                fontWeight: FontWeight.w300,
                color: AppTheme.textSecondary,
                letterSpacing: logoSize * 0.01,
              ),
            ),
          ],
        ),

        SizedBox(height: logoSize * 0.4),

        // Progress indicator
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Container(
              width: logoSize * 0.8,
              height: 3,
              decoration: BoxDecoration(
                color: AppTheme.surfaceInteractive,
                borderRadius: BorderRadius.circular(1.5),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryGold.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Widget do wyświetlania podczas ładowania danych
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool showLogo;
  final double logoSize;

  const LoadingOverlay({
    super.key,
    this.message,
    this.showLogo = true,
    this.logoSize = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundPrimary.withOpacity(0.8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLogo) ...[
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(logoSize * 0.2),
                    gradient: AppTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(logoSize * 0.1),
                  child: Image.asset(
                    'assets/logos/logo.png',
                    width: logoSize * 0.8,
                    height: logoSize * 0.8,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (message != null) ...[
                Text(
                  message!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              // Progress indicator
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: AppTheme.surfaceInteractive,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.secondaryGold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kompaktowy loading indicator dla małych elementów
class MetropolitanMiniLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const MetropolitanMiniLoader({super.key, this.size = 24.0, this.color});

  @override
  State<MetropolitanMiniLoader> createState() => _MetropolitanMiniLoaderState();
}

class _MetropolitanMiniLoaderState extends State<MetropolitanMiniLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * 3.14159,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  widget.color ?? AppTheme.secondaryGold,
                  (widget.color ?? AppTheme.secondaryGold).withOpacity(0.3),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: widget.size * 0.3,
                height: widget.size * 0.3,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundPrimary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
