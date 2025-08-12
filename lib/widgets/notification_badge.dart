import 'package:flutter/material.dart';

/// Widget badge'a powiadomień z animacjami i profesjonalnym stylingiem
class NotificationBadge extends StatefulWidget {
  final int count;
  final Widget child;
  final bool showZero;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const NotificationBadge({
    Key? key,
    required this.count,
    required this.child,
    this.showZero = false,
    this.size = 16.0,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    if (widget.count > 0) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(NotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.count != oldWidget.count) {
      if (widget.count > 0 && oldWidget.count == 0) {
        // Nowy badge - animacja pojawiania się
        _animationController.forward();
      } else if (widget.count == 0 && oldWidget.count > 0) {
        // Ukrywanie badge'a
        _animationController.reverse();
      } else if (widget.count != oldWidget.count && widget.count > 0) {
        // Aktualizacja liczby - krótka animacja
        _animationController.reset();
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shouldShow = widget.count > 0 || widget.showZero;

    // Kolory na podstawie theme
    final badgeColor =
        widget.backgroundColor ?? const Color(0xFFD4AF37); // Złoty kolor
    final textColor =
        widget.textColor ?? const Color(0xFF1A1A1A); // Ciemny tekst

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (shouldShow)
          Positioned(
            top: -8,
            right: -8,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: widget.size,
                      minHeight: widget.size,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(widget.size / 2),
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.count > 99 ? '99+' : widget.count.toString(),
                        style: TextStyle(
                          color: textColor,
                          fontSize: widget.size * 0.6,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Widget dla ikony z badge'em powiadomień w nawigacji
class NavigationIconWithBadge extends StatelessWidget {
  final IconData icon;
  final int notificationCount;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? selectedColor;

  const NavigationIconWithBadge({
    Key? key,
    required this.icon,
    required this.notificationCount,
    this.isSelected = false,
    this.onTap,
    this.iconColor,
    this.selectedColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD4AF37), width: 1),
              )
            : null,
        child: NotificationBadge(
          count: notificationCount,
          child: Icon(
            icon,
            color: isSelected
                ? (selectedColor ?? const Color(0xFFD4AF37))
                : (iconColor ?? theme.iconTheme.color),
            size: 24,
          ),
        ),
      ),
    );
  }
}
