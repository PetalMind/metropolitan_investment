import 'package:flutter/material.dart';

/// 🎪 Service responsible for managing animations in email editor
/// Extracted from WowEmailEditorScreen for better memory management and organization
class EmailEditorAnimationManager {
  // Animation controllers
  late AnimationController _settingsAnimationController;
  late AnimationController _editorAnimationController;
  late AnimationController _mainScreenController;
  late AnimationController _recipientsAnimationController;

  // Animations
  late Animation<double> _editorBounceAnimation;
  late Animation<double> _screenEntranceAnimation;
  late Animation<Offset> _screenSlideAnimation;

  // State tracking
  bool _isInitialized = false;
  bool _isDisposed = false;

  /// Initialize all animation controllers and animations
  void initializeAnimations(TickerProvider vsync) {
    if (_isInitialized || _isDisposed) return;

    try {
      // Initialize controllers with proper durations
      _settingsAnimationController = AnimationController(
        duration: const Duration(milliseconds: 700),
        vsync: vsync,
      );

      _editorAnimationController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: vsync,
      );

      _mainScreenController = AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: vsync,
      );

      _recipientsAnimationController = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: vsync,
      );

      // Initialize animations
      _editorBounceAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(
          parent: _editorAnimationController,
          curve: Curves.elasticOut,
        ),
      );

      _screenEntranceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _mainScreenController,
          curve: Curves.elasticOut,
        ),
      );

      _screenSlideAnimation =
          Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
            CurvedAnimation(
              parent: _mainScreenController,
              curve: Curves.easeOutBack,
            ),
          );

      _isInitialized = true;

      // Start entrance animation
      _mainScreenController.forward();
    } catch (e) {
      debugPrint('❌ Error initializing animations: $e');
    }
  }

  /// Dispose all animation controllers
  void dispose() {
    if (_isDisposed) return;

    try {
      if (_isInitialized) {
        _settingsAnimationController.dispose();
        _editorAnimationController.dispose();
        _mainScreenController.dispose();
        _recipientsAnimationController.dispose();
      }

      _isDisposed = true;
      debugPrint('✅ Animation controllers disposed successfully');
    } catch (e) {
      debugPrint('❌ Error disposing animations: $e');
    }
  }

  /// Toggle settings collapse animation
  void toggleSettingsCollapse(bool isCollapsed) {
    if (!_isInitialized || _isDisposed) return;

    try {
      if (isCollapsed) {
        _settingsAnimationController.forward();
      } else {
        _settingsAnimationController.reverse();
      }
    } catch (e) {
      debugPrint('❌ Error toggling settings animation: $e');
    }
  }

  /// Toggle recipients collapse animation
  void toggleRecipientsCollapse(bool isCollapsed) {
    if (!_isInitialized || _isDisposed) return;

    try {
      if (isCollapsed) {
        _recipientsAnimationController.forward();
      } else {
        _recipientsAnimationController.reverse();
      }
    } catch (e) {
      debugPrint('❌ Error toggling recipients animation: $e');
    }
  }

  /// Trigger editor expansion animation
  void triggerEditorAnimation() {
    if (!_isInitialized || _isDisposed) return;

    try {
      _editorAnimationController.reset();
      _editorAnimationController.forward();
    } catch (e) {
      debugPrint('❌ Error triggering editor animation: $e');
    }
  }

  /// Get animation builders for UI components
  AnimatedBuilder buildMainScreenAnimations({required Widget child}) {
    if (!_isInitialized) {
      return AnimatedBuilder(
        animation: const AlwaysStoppedAnimation(1.0),
        builder: (context, _) => child,
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _settingsAnimationController,
        _editorAnimationController,
        _mainScreenController,
        _recipientsAnimationController,
      ]),
      builder: (context, _) {
        return FadeTransition(
          opacity: _screenEntranceAnimation,
          child: SlideTransition(position: _screenSlideAnimation, child: child),
        );
      },
    );
  }

  /// Get editor animation builder
  AnimatedBuilder buildEditorAnimation({required Widget child}) {
    if (!_isInitialized) {
      return AnimatedBuilder(
        animation: const AlwaysStoppedAnimation(1.0),
        builder: (context, _) => child,
      );
    }

    return AnimatedBuilder(
      animation: _editorAnimationController,
      builder: (context, _) {
        return Transform.scale(
          scale: _editorBounceAnimation.value,
          child: child,
        );
      },
    );
  }

  /// Get recipients animation builder
  AnimatedBuilder buildRecipientsAnimation({required Widget child}) {
    if (!_isInitialized) {
      return AnimatedBuilder(
        animation: const AlwaysStoppedAnimation(1.0),
        builder: (context, _) => child,
      );
    }

    return AnimatedBuilder(
      animation: _recipientsAnimationController,
      builder: (context, _) => child,
    );
  }

  // Getters for animation states (read-only access)
  bool get isInitialized => _isInitialized;
  bool get isDisposed => _isDisposed;

  // Safe getters for animation controllers (for external listeners if needed)
  AnimationController? get settingsController =>
      _isInitialized && !_isDisposed ? _settingsAnimationController : null;

  AnimationController? get editorController =>
      _isInitialized && !_isDisposed ? _editorAnimationController : null;

  AnimationController? get mainScreenController =>
      _isInitialized && !_isDisposed ? _mainScreenController : null;

  AnimationController? get recipientsController =>
      _isInitialized && !_isDisposed ? _recipientsAnimationController : null;

  /// Reset all animations to initial state
  void resetAllAnimations() {
    if (!_isInitialized || _isDisposed) return;

    try {
      _settingsAnimationController.reset();
      _editorAnimationController.reset();
      _mainScreenController.reset();
      _recipientsAnimationController.reset();

      // Restart main screen animation
      _mainScreenController.forward();
    } catch (e) {
      debugPrint('❌ Error resetting animations: $e');
    }
  }

  /// Check if any animation is currently running
  bool get isAnyAnimationRunning {
    if (!_isInitialized || _isDisposed) return false;

    return _settingsAnimationController.isAnimating ||
        _editorAnimationController.isAnimating ||
        _mainScreenController.isAnimating ||
        _recipientsAnimationController.isAnimating;
  }

  /// Stop all running animations
  void stopAllAnimations() {
    if (!_isInitialized || _isDisposed) return;

    try {
      _settingsAnimationController.stop();
      _editorAnimationController.stop();
      _mainScreenController.stop();
      _recipientsAnimationController.stop();
    } catch (e) {
      debugPrint('❌ Error stopping animations: $e');
    }
  }
}
