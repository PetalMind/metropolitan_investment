import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

/// Animowany komponent logo Metropolitan Investment
/// Zapewnia płynne animacje ładowania z efektami wizualnymi
class AnimatedMetropolitanLogo extends StatefulWidget {
  final double size;
  final bool isLoading;
  final bool showText;
  final VoidCallback? onTap;
  final Duration animationDuration;
  final bool enableHoverEffect;
  final LogoVariant variant;

  const AnimatedMetropolitanLogo({
    super.key,
    this.size = 60.0,
    this.isLoading = false,
    this.showText = false,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 800),
    this.enableHoverEffect = true,
    this.variant = LogoVariant.standard,
  });

  @override
  State<AnimatedMetropolitanLogo> createState() =>
      _AnimatedMetropolitanLogoState();
}

class _AnimatedMetropolitanLogoState extends State<AnimatedMetropolitanLogo>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _glowController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startEntryAnimation();
  }

  void _initializeAnimations() {
    // Główny kontroler rotacji
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Kontroler skalowania
    _scaleController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Kontroler fade-in
    _fadeController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Kontroler efektu glow
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Definicje animacji
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void _startEntryAnimation() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _fadeController.forward();
        _scaleController.forward();
      }
    });

    // Efekt glow
    _glowController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(AnimatedMetropolitanLogo oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _rotationController.repeat();
      } else {
        _rotationController.stop();
        _rotationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: widget.enableHoverEffect ? (_) => _onHover(true) : null,
        onExit: widget.enableHoverEffect ? (_) => _onHover(false) : null,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _rotationAnimation,
            _scaleAnimation,
            _fadeAnimation,
            _glowAnimation,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value * (_isHovered ? 1.05 : 1.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: widget.isLoading
                    ? Transform.rotate(
                        angle: _rotationAnimation.value * 2 * 3.14159,
                        child: _buildLogo(),
                      )
                    : _buildLogo(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.size * 0.2),
        boxShadow: [
          // Główny cień
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          // Efekt glow z animacją
          BoxShadow(
            color: AppTheme.secondaryGold.withOpacity(
              _glowAnimation.value * 0.4,
            ),
            blurRadius: 20,
            offset: const Offset(0, 0),
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size * 0.2),
        child: Container(
          decoration: BoxDecoration(gradient: _getLogoGradient()),
          child: _buildLogoContent(),
        ),
      ),
    );
  }

  Widget _buildLogoContent() {
    switch (widget.variant) {
      case LogoVariant.svg:
        return _buildSvgLogo();
      case LogoVariant.icon:
        return _buildIconLogo();
      case LogoVariant.standard:
        return _buildStandardLogo();
    }
  }

  Widget _buildSvgLogo() {
    return Padding(
      padding: EdgeInsets.all(widget.size * 0.1),
      child: SvgPicture.asset(
        'assets/logos/METROPOLITAN_logo_kontra_RGB.svg',
        width: widget.size * 0.8,
        height: widget.size * 0.8,
        colorFilter: const ColorFilter.mode(
          AppTheme.textOnPrimary,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildIconLogo() {
    return Icon(
      Icons.account_balance,
      color: AppTheme.textOnPrimary,
      size: widget.size * 0.5,
    );
  }

  Widget _buildStandardLogo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.account_balance,
          color: AppTheme.textOnPrimary,
          size: widget.size * 0.4,
        ),
        if (widget.showText && widget.size > 40) ...[
          SizedBox(height: widget.size * 0.05),
          Text(
            'M',
            style: TextStyle(
              color: AppTheme.textOnPrimary,
              fontSize: widget.size * 0.2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  LinearGradient _getLogoGradient() {
    switch (widget.variant) {
      case LogoVariant.svg:
        return AppTheme.primaryGradient;
      case LogoVariant.icon:
        return AppTheme.goldGradient;
      case LogoVariant.standard:
        return AppTheme.primaryGradient;
    }
  }

  void _onHover(bool isHovered) {
    if (!widget.enableHoverEffect) return;

    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _scaleController.forward();
    } else {
      _scaleController.reverse();
    }
  }
}

/// Warianty wyświetlania logo
enum LogoVariant {
  standard, // Standardowy z ikoną
  svg, // Z oryginalnym SVG
  icon, // Tylko ikona
}

/// Logo z animacją ładowania dla splash screen
class MetropolitanLoadingLogo extends StatefulWidget {
  final double size;
  final String? subtitle;

  const MetropolitanLoadingLogo({super.key, this.size = 120.0, this.subtitle});

  @override
  State<MetropolitanLoadingLogo> createState() =>
      _MetropolitanLoadingLogoState();
}

class _MetropolitanLoadingLogoState extends State<MetropolitanLoadingLogo>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _textController;

  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _pulseAnimation = _pulseController;

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    _startLoadingAnimation();
  }

  void _startLoadingAnimation() {
    _pulseController.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _textController.forward();
        _progressController.forward();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo z animacją
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.95 + (_pulseAnimation.value * 0.1),
              child: AnimatedMetropolitanLogo(
                size: widget.size,
                variant: LogoVariant.svg,
                isLoading: false,
                enableHoverEffect: false,
              ),
            );
          },
        ),

        SizedBox(height: widget.size * 0.3),

        // Tekst aplikacji
        FadeTransition(
          opacity: _textFadeAnimation,
          child: Column(
            children: [
              Text(
                'METROPOLITAN',
                style: TextStyle(
                  fontSize: widget.size * 0.15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: widget.size * 0.02,
                  height: 1.1,
                ),
              ),
              SizedBox(height: widget.size * 0.05),
              Text(
                'INVESTMENT',
                style: TextStyle(
                  fontSize: widget.size * 0.1,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.secondaryGold,
                  letterSpacing: widget.size * 0.015,
                  height: 1.2,
                ),
              ),
              if (widget.subtitle != null) ...[
                SizedBox(height: widget.size * 0.1),
                Text(
                  widget.subtitle!,
                  style: TextStyle(
                    fontSize: widget.size * 0.08,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.textSecondary,
                    letterSpacing: widget.size * 0.01,
                  ),
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: widget.size * 0.4),

        // Progress indicator
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Container(
              width: widget.size * 0.8,
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

/// Kompaktowy widget logo dla użycia w AppBar i innych miejscach
class MetropolitanBrandLogo extends StatelessWidget {
  final double height;
  final bool showText;
  final Color? textColor;
  final VoidCallback? onTap;

  const MetropolitanBrandLogo({
    super.key,
    this.height = 40.0,
    this.showText = true,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo SVG
          SvgPicture.asset(
            'assets/logos/METROPOLITAN_logo_kontra_RGB.svg',
            height: height,
            colorFilter: ColorFilter.mode(
              textColor ?? AppTheme.textPrimary,
              BlendMode.srcIn,
            ),
          ),

          if (showText) ...[
            SizedBox(width: height * 0.3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'METROPOLITAN',
                  style: TextStyle(
                    fontSize: height * 0.35,
                    fontWeight: FontWeight.w700,
                    color: textColor ?? AppTheme.textPrimary,
                    letterSpacing: height * 0.02,
                    height: 1.0,
                  ),
                ),
                Text(
                  'INVESTMENT',
                  style: TextStyle(
                    fontSize: height * 0.25,
                    fontWeight: FontWeight.w400,
                    color:
                        textColor?.withOpacity(0.8) ?? AppTheme.secondaryGold,
                    letterSpacing: height * 0.015,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
