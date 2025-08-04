import 'package:flutter/material.dart';
import '../widgets/animated_logo.dart';
import '../theme/app_theme.dart';

/// AppBar z animowanym logo Metropolitan
/// Wykorzystywane w ekranach bez głównej nawigacji
class MetropolitanAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showLogo;
  final bool centerTitle;
  final Widget? leading;
  final double elevation;
  final VoidCallback? onLogoTap;

  const MetropolitanAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showLogo = true,
    this.centerTitle = true,
    this.leading,
    this.elevation = 4.0,
    this.onLogoTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: elevation,
      centerTitle: centerTitle,
      leading: leading,
      backgroundColor: AppTheme.backgroundSecondary,
      surfaceTintColor: Colors.transparent,
      shadowColor: AppTheme.primaryColor.withOpacity(0.3),
      title: showLogo ? _buildTitleWithLogo() : _buildSimpleTitle(),
      actions: actions,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.backgroundSecondary, AppTheme.backgroundTertiary],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleWithLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedMetropolitanLogo(
          size: 32.0,
          variant: LogoVariant.svg,
          enableHoverEffect: true,
          onTap: onLogoTap,
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleTitle() {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
    );
  }
}

/// Floating Action Button z logo Metropolitan
class MetropolitanFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final bool showLogo;
  final double size;

  const MetropolitanFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.showLogo = false,
    this.size = 56.0,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: AppTheme.textOnPrimary,
      elevation: 8.0,
      child: showLogo
          ? AnimatedMetropolitanLogo(
              size: size * 0.6,
              variant: LogoVariant.svg,
              enableHoverEffect: false,
            )
          : Icon(icon, size: size * 0.5),
    );
  }
}

/// Card header z logo Metropolitan
class MetropolitanCardHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showLogo;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;

  const MetropolitanCardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showLogo = true,
    this.actions,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showLogo) ...[
            AnimatedMetropolitanLogo(
              size: 24.0,
              variant: LogoVariant.svg,
              enableHoverEffect: false,
            ),
            const SizedBox(width: 12),
          ],

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textOnPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: AppTheme.textOnPrimary.withOpacity(0.8),
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

/// Logo watermark dla raportów i wydruków
class MetropolitanWatermark extends StatelessWidget {
  final double opacity;
  final double size;
  final Alignment alignment;

  const MetropolitanWatermark({
    super.key,
    this.opacity = 0.1,
    this.size = 200.0,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Opacity(
          opacity: opacity,
          child: AnimatedMetropolitanLogo(
            size: size,
            variant: LogoVariant.svg,
            enableHoverEffect: false,
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet header z logo
class MetropolitanBottomSheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;
  final bool showLogo;

  const MetropolitanBottomSheetHeader({
    super.key,
    required this.title,
    this.onClose,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 16),

          // Header content
          Row(
            children: [
              if (showLogo) ...[
                AnimatedMetropolitanLogo(
                  size: 28.0,
                  variant: LogoVariant.svg,
                  enableHoverEffect: false,
                ),
                const SizedBox(width: 12),
              ],

              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),

              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close, color: AppTheme.textSecondary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
