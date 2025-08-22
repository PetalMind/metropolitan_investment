import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme_professional.dart';

/// 🏛️ **Metropolitan Investment Logo Widget**
///
/// Profesjonalny widget logo z efektami premium i animacjami
/// Wykorzystuje SVG logo firmy z zaawansowanymi stylami wizualnymi
///
/// **Funkcjonalności:**
/// • 🎨 Dynamiczne kolory (złoty akcent + białe logo)
/// • ✨ Animacje hover i loading
/// • 📱 Responsywny design
/// • 🔧 Konfigurowalny rozmiar
/// • 🌟 Efekty 3D i świecenia
class MetropolitanLogoWidget extends StatefulWidget {
  /// Rozmiar logo (szerokość)
  final double size;

  /// Kolor logo (domyślnie biały)
  final Color? color;

  /// Czy logo ma być animowane
  final bool animated;

  /// Czy logo ma efekt hover
  final bool enableHover;

  /// Callback po kliknięciu
  final VoidCallback? onTap;

  /// Styl wyświetlania
  final MetropolitanLogoStyle style;

  const MetropolitanLogoWidget({
    super.key,
    this.size = 120.0,
    this.color,
    this.animated = false,
    this.enableHover = true,
    this.onTap,
    this.style = MetropolitanLogoStyle.premium,
  });

  /// Logo standardowe dla nawigacji
  const MetropolitanLogoWidget.navigation({
    super.key,
    this.size = 40.0,
    this.color,
    this.animated = false,
    this.enableHover = true,
    this.onTap,
  }) : style = MetropolitanLogoStyle.simple;

  /// Logo duże dla splash screen
  const MetropolitanLogoWidget.splash({
    super.key,
    this.size = 160.0,
    this.color,
    this.animated = true,
    this.enableHover = false,
    this.onTap,
  }) : style = MetropolitanLogoStyle.premium;

  /// Logo kompaktowe dla header
  const MetropolitanLogoWidget.compact({
    super.key,
    this.size = 80.0,
    this.color,
    this.animated = false,
    this.enableHover = true,
    this.onTap,
  }) : style = MetropolitanLogoStyle.minimal;

  @override
  State<MetropolitanLogoWidget> createState() => _MetropolitanLogoWidgetState();
}

class _MetropolitanLogoWidgetState extends State<MetropolitanLogoWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _glowController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.animated) {
      _startAnimations();
    }
  }

  void _initializeAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _scaleAnimation = _scaleController;

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _rotationController.repeat();
    _glowController.repeat(reverse: true);
  }

  void _onHoverEnter() {
    if (!widget.enableHover) return;
    // Removed hover animations
  }

  void _onHoverExit() {
    if (!widget.enableHover) return;
    // Removed hover animations
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoColor = widget.color ?? AppThemePro.textPrimary;

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => _onHoverEnter(),
        onExit: (_) => _onHoverExit(),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _rotationAnimation,
            _scaleAnimation,
            _glowAnimation,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_scaleAnimation.value * 0.05),
              child: Transform.rotate(
                angle: widget.animated ? _rotationAnimation.value * 0.1 : 0,
                child: _buildLogoContainer(logoColor),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogoContainer(Color logoColor) {
    switch (widget.style) {
      case MetropolitanLogoStyle.premium:
        return _buildPremiumLogo(logoColor);
      case MetropolitanLogoStyle.simple:
        return _buildSimpleLogo(logoColor);
      case MetropolitanLogoStyle.minimal:
        return _buildMinimalLogo(logoColor);
    }
  }

  Widget _buildPremiumLogo(Color logoColor) {
    // Tylko złote SVG logo bez ramek i animacji
    return SizedBox(
      width: widget.size,
      height:
          widget.size * 0.53, // Zachowaj proporcje SVG (84.17/159.77 ≈ 0.53)
      child: _buildSvgLogo(AppThemePro.accentGold, widget.size),
    );
  }

  Widget _buildSimpleLogo(Color logoColor) {
    return Container(
      width: widget.size,
      height: widget.size * 0.75,
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemePro.borderPrimary, width: 1),
      ),
      child: Center(child: _buildSvgLogo(logoColor, widget.size * 0.7)),
    );
  }

  Widget _buildMinimalLogo(Color logoColor) {
    return SizedBox(
      width: widget.size,
      height: widget.size * 0.75,
      child: _buildSvgLogo(logoColor, widget.size),
    );
  }

  Widget _buildSvgLogo(Color color, double size) {
    // Bezpośredni SVG string z usuniętym tłem
    const String svgString = '''
<svg width="159.77333" height="84.173332" viewBox="0 0 159.77333 84.173332" xmlns="http://www.w3.org/2000/svg">
  <g id="logo-content">
    <!-- Main METROPOLITAN text -->
    <path
      d="m 162.859,267.559 -22.386,-29.84 h -2.555 l -21.891,29.941 v -49.972 h -12.961 v 68.726 h 14.922 l 21.504,-29.551 21.5,29.551 h 14.828 v -68.726 h -12.961 z m 96.012,-49.766 h -51.445 c 0,22.871 0,45.848 0,68.719 h 51.445 v -12.567 h -38.582 v -15.804 h 37.207 v -12.078 h -37.207 v -15.516 h 38.582 z m 51.434,56.937 h -21.793 v 11.782 c 19.836,0 36.625,0 56.554,0 V 274.73 H 323.27 V 217.793 H 310.305 Z M 433.52,217.793 h -15.418 l -20.028,22.969 h -12.469 v -22.969 h -12.96 v 68.816 c 10.902,0 21.8,-0.097 32.695,-0.097 16.199,-0.098 24.742,-10.895 24.742,-22.778 0,-9.425 -4.32,-18.949 -17.379,-21.597 l 20.817,-23.469 z m -47.915,56.641 v 0 -21.985 h 19.735 c 8.246,0 11.781,5.492 11.781,10.992 0,5.493 -3.633,10.993 -11.781,10.993 z m 140.387,-22.676 c -0.191,-17.77 -11.094,-35.543 -35.242,-35.543 -24.152,0 -35.348,17.379 -35.348,35.441 0,18.071 11.586,36.231 35.348,36.231 23.66,0 35.445,-18.16 35.242,-36.129 z m -57.824,-0.293 v 0 c 0.297,-11.289 6.379,-23.371 22.582,-23.371 16.199,0 22.289,12.176 22.48,23.469 0.2,11.582 -6.281,24.542 -22.48,24.542 -16.203,0 -22.879,-13.054 -22.582,-24.64 z m 119.379,-13.457 h -19.442 v -20.215 h -12.96 v 68.719 c 10.8,0 21.601,0.097 32.402,0.097 33.582,0 33.676,-48.601 0,-48.601 z m -19.442,11.879 v 0 h 19.442 c 16.594,0 16.492,24.351 0,24.351 h -19.442 z m 140.586,1.871 c -0.195,-17.77 -11.089,-35.543 -35.242,-35.543 -24.156,0 -35.347,17.379 -35.347,35.441 0,18.071 11.586,36.231 35.347,36.231 23.66,0 35.442,-18.16 35.242,-36.129 z m -57.824,-0.293 v 0 c 0.297,-11.289 6.379,-23.371 22.582,-23.371 16.199,0 22.285,12.176 22.485,23.469 0.195,11.582 -6.286,24.542 -22.485,24.542 -16.203,0 -22.879,-13.054 -22.582,-24.64 z m 99.942,35.047 v -56.746 h 35.343 v -11.973 h -48.304 v 68.719 z m 64.199,-68.719 v 68.719 h 12.863 v -68.719 z m 65.578,56.937 h -21.797 v 11.782 c 19.836,0 36.625,0 56.559,0 V 274.73 h -21.793 v -56.937 h -12.969 z m 111.031,-43.98 h -35.929 l -5.891,-12.957 h -14.039 l 30.828,68.719 h 14.137 l 30.837,-68.719 h -14.142 z m -17.965,41.328 v 0 l -12.757,-29.254 h 25.527 z m 108.588,14.531 h 12.95 v -68.816 h -8.05 v -0.105 l -36.13,46.437 v -46.332 h -12.96 v 68.719 h 10.51 l 33.68,-42.606 v 42.703"
      fill="currentColor"
      transform="matrix(0.13333333,0,0,-0.13333333,0,84.173333)" />
    
    <!-- "Investment" subtitle -->
    <g fill="currentColor" transform="matrix(0.13333333,0,0,-0.13333333,0,84.173333)">
      <path d="m 351.273,152.938 h 5.54 v -49.032 h -5.54 v 49.032" />
      <path d="m 383.828,140.117 h 5.391 v -6.301 c 2.383,3.918 6.164,7.075 12.398,7.075 8.754,0 13.867,-5.883 13.867,-14.504 v -22.481 h -5.394 v 21.153 c 0,6.726 -3.641,10.925 -10.016,10.925 -6.23,0 -10.855,-4.55 -10.855,-11.343 v -20.735 h -5.391 v 36.211" />
      <path d="m 434.984,140.117 h 5.954 l 12.187,-30.047 12.258,30.047 h 5.812 l -15.761,-36.488 h -4.758 l -15.692,36.488" />
      <path d="m 517.109,124.148 c -0.629,6.586 -4.414,12.188 -11.558,12.188 -6.231,0 -10.996,-5.184 -11.766,-12.188 z m -10.578,-16.386 c 4.973,0 8.477,2.031 11.418,5.113 l 3.36,-3.016 c -3.637,-4.062 -8.051,-6.793 -14.918,-6.793 -9.946,0 -18.067,7.633 -18.067,18.914 0,10.5 7.356,18.911 17.367,18.911 10.715,0 16.883,-8.547 16.883,-19.196 0,-0.488 0,-1.05 -0.074,-1.89 h -28.715 c 0.77,-7.629 6.375,-12.043 12.746,-12.043" />
      <path d="m 543.422,108.531 2.73,3.852 c 3.922,-2.942 8.266,-4.621 12.539,-4.621 4.34,0 7.493,2.242 7.493,5.742 v 0.141 c 0,3.64 -4.27,5.043 -9.036,6.371 -5.671,1.613 -11.976,3.574 -11.976,10.226 v 0.141 c 0,6.234 5.183,10.367 12.328,10.367 4.414,0 9.316,-1.543 13.027,-3.996 l -2.449,-4.063 c -3.367,2.172 -7.219,3.5 -10.719,3.5 -4.273,0 -7.004,-2.238 -7.004,-5.246 v -0.144 c 0,-3.43 4.485,-4.758 9.317,-6.235 5.601,-1.679 11.629,-3.851 11.629,-10.359 v -0.144 c 0,-6.864 -5.676,-10.852 -12.891,-10.852 -5.183,0 -10.926,2.031 -14.988,5.32" />
      <path d="m 596.633,113.504 v 21.848 h -5.043 v 4.765 h 5.043 v 10.926 h 5.39 v -10.926 h 11.489 v -4.765 h -11.489 v -21.145 c 0,-4.414 2.45,-6.027 6.094,-6.027 1.821,0 3.363,0.351 5.254,1.261 v -4.625 c -1.891,-0.976 -3.922,-1.539 -6.516,-1.539 -5.808,0 -10.222,2.871 -10.222,10.227" />
      <path d="m 638.297,140.117 h 5.391 v -6.094 c 2.382,3.571 5.605,6.868 11.699,6.868 5.879,0 9.668,-3.157 11.633,-7.219 2.585,3.996 6.433,7.219 12.742,7.219 8.332,0 13.449,-5.606 13.449,-14.571 v -22.414 h -5.391 v 21.153 c 0,7.004 -3.507,10.925 -9.386,10.925 -5.469,0 -10.016,-4.058 -10.016,-11.207 v -20.871 h -5.324 v 21.289 c 0,6.797 -3.574,10.789 -9.317,10.789 -5.742,0 -10.089,-4.761 -10.089,-11.418 v -20.66 h -5.391 v 36.211" />
      <path d="m 743.297,124.148 c -0.637,6.586 -4.414,12.188 -11.563,12.188 -6.23,0 -10.996,-5.184 -11.765,-12.188 z m -10.574,-16.386 c 4.968,0 8.472,2.031 11.414,5.113 l 3.359,-3.016 c -3.644,-4.062 -8.058,-6.793 -14.922,-6.793 -9.941,0 -18.066,7.633 -18.066,18.914 0,10.5 7.351,18.911 17.375,18.911 10.711,0 16.875,-8.547 16.875,-19.196 0,-0.488 0,-1.05 -0.07,-1.89 h -28.719 c 0.769,-7.629 6.375,-12.043 12.754,-12.043" />
      <path d="m 771.488,140.117 h 5.391 v -6.301 c 2.383,3.918 6.164,7.075 12.394,7.075 8.758,0 13.868,-5.883 13.868,-14.504 v -22.481 h -5.391 v 21.153 c 0,6.726 -3.645,10.925 -10.02,10.925 -6.23,0 -10.851,-4.55 -10.851,-11.343 v -20.735 h -5.391 v 36.211" />
      <path d="m 830.074,113.504 v 21.848 h -5.039 v 4.765 h 5.039 v 10.926 h 5.399 v -10.926 h 11.488 v -4.765 h -11.488 v -21.145 c 0,-4.414 2.453,-6.027 6.093,-6.027 1.817,0 3.36,0.351 5.247,1.261 v -4.625 c -1.887,-0.976 -3.918,-1.539 -6.504,-1.539 -5.821,0 -10.235,2.871 -10.235,10.227" />
    </g>
    
    <!-- Architectural columns icon -->
    <g fill="currentColor" transform="matrix(0.13333333,0,0,-0.13333333,0,84.173333)">
      <path d="m 513.23,363.922 h 32.723 V 487.16 L 513.23,514.227 V 363.922" />
      <path d="m 566.406,363.922 h 32.727 V 498.414 L 566.406,480.047 V 363.922" />
      <path d="m 619.586,363.922 h 32.727 V 528.266 L 619.586,509.895 V 363.922" />
    </g>
  </g>
</svg>
''';

    return SvgPicture.string(
      svgString,
      width: size,
      height: size * 0.5268, // Maintain original aspect ratio
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// Style wyświetlania logo
enum MetropolitanLogoStyle {
  /// Pełny premium style z efektami
  premium,

  /// Prosty style z lekkim kontenerem
  simple,

  /// Minimalistyczny - tylko SVG
  minimal,
}

/// **Extension Methods** dla łatwego użycia
extension MetropolitanLogoExtensions on Widget {
  /// Owiń widget w Metropolitan branding container
  Widget withMetropolitanBranding({
    EdgeInsets? padding,
    Color? backgroundColor,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppThemePro.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemePro.borderPrimary, width: 1),
      ),
      child: this,
    );
  }
}
