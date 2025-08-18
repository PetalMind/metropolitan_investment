import 'package:flutter/material.dart';
import '../services/calendar_notification_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme_professional.dart';
import 'notification_badge.dart';

/// 🚀 ENHANCED Navigation Badge z real-time aktualizacjami
/// Używa StreamBuilder do automatycznego odświeżania badge'ów
class EnhancedNavigationBadge extends StatelessWidget {
  final Widget child;
  final String route;
  final bool showBadge;

  const EnhancedNavigationBadge({
    super.key,
    required this.child,
    required this.route,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBadge || route != '/calendar') {
      // Dla innych tras zwróć zwykły child
      return child;
    }

    // Dla kalendarza użyj StreamBuilder z real-time aktualizacjami
    return StreamBuilder<int>(
      stream: CalendarNotificationService().notificationStream,
      initialData: NotificationService().getNotificationsForRoute(route),
      builder: (context, snapshot) {
        final notificationCount = snapshot.data ?? 0;
        
        if (notificationCount == 0) {
          return child;
        }

        return AnimatedNotificationBadge(
          count: notificationCount,
          child: child,
        );
      },
    );
  }
}

/// Widget badge'a z ulepszonymi animacjami
class AnimatedNotificationBadge extends StatefulWidget {
  final int count;
  final Widget child;

  const AnimatedNotificationBadge({
    super.key,
    required this.count,
    required this.child,
  });

  @override
  State<AnimatedNotificationBadge> createState() => _AnimatedNotificationBadgeState();
}

class _AnimatedNotificationBadgeState extends State<AnimatedNotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));

    // Uruchom animację przy pojawieniu się
    _pulseController.forward();
    
    // Ciągły puls dla wysokiej liczby powiadomień
    if (widget.count > 3) {
      _startPulseAnimation();
    }
  }

  void _startPulseAnimation() {
    _pulseController.repeat(reverse: true);
  }

  void _stopPulseAnimation() {
    _pulseController.stop();
    _pulseController.forward();
  }

  @override
  void didUpdateWidget(AnimatedNotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.count != oldWidget.count) {
      if (widget.count > 3 && oldWidget.count <= 3) {
        _startPulseAnimation();
      } else if (widget.count <= 3 && oldWidget.count > 3) {
        _stopPulseAnimation();
      }
      
      // Animacja przy zmianie liczby
      _pulseController.reset();
      _pulseController.forward();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          top: -8,
          right: -8,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppThemePro.accentGold.withValues(alpha: 0.4),
                        blurRadius: 8 * _pulseAnimation.value,
                        spreadRadius: 2 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                  child: _buildBadgeContent(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeContent() {
    Color badgeColor;
    Color textColor = AppThemePro.primaryDark;
    
    // Kolorowanie na podstawie liczby powiadomień
    if (widget.count >= 5) {
      badgeColor = AppThemePro.statusError; // Czerwony dla dużej liczby
      textColor = Colors.white;
    } else if (widget.count >= 3) {
      badgeColor = AppThemePro.statusWarning; // Pomarańczowy dla średniej liczby
      textColor = AppThemePro.primaryDark;
    } else {
      badgeColor = AppThemePro.accentGold; // Złoty dla małej liczby
      textColor = AppThemePro.primaryDark;
    }

    return Container(
      constraints: const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemePro.backgroundPrimary,
          width: 2,
        ),
      ),
      child: Text(
        widget.count > 99 ? '99+' : widget.count.toString(),
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          height: 1.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Factory method dla łatwego użycia w nawigacji
class NavigationBadgeFactory {
  static Widget wrapWithBadge({
    required Widget child,
    required String route,
    bool animated = true,
  }) {
    if (animated) {
      return EnhancedNavigationBadge(
        route: route,
        child: child,
      );
    } else {
      // Fallback do standardowego badge'a
      final notificationCount = NotificationService().getNotificationsForRoute(route);
      return NotificationBadge(
        count: notificationCount,
        child: child,
      );
    }
  }
}