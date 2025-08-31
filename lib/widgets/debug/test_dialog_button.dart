import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme_professional.dart';

/// **PRZYCISK TESTOWY DO NOWEGO DIALOGU**
/// 
/// Floating Action Button który można dodać do dowolnego ekranu
/// do szybkiego testowania nowego dialogu email
class TestDialogButton extends StatelessWidget {
  final bool showInDebugMode;
  
  const TestDialogButton({
    super.key,
    this.showInDebugMode = true,
  });

  @override
  Widget build(BuildContext context) {
    // Pokaż tylko w trybie debug (jeśli włączone)
    if (showInDebugMode && !_isDebugMode()) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton.extended(
        onPressed: () => context.go('/test-dialog'),
        backgroundColor: AppThemePro.accentGold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.email_outlined),
        label: const Text(
          'Test Dialog',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        tooltip: 'Otwórz nowy dialog edytora email',
      ),
    );
  }
  
  bool _isDebugMode() {
    bool debugMode = false;
    assert(debugMode = true);
    return debugMode;
  }
}

/// **WIDGET DEBUGOWY - BANNER TESTOWY**
/// 
/// Banner na górze ekranu informujący o dostępności testowego dialogu
class TestDialogBanner extends StatelessWidget {
  const TestDialogBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!_isDebugMode()) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppThemePro.statusInfo.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.science_outlined,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Tryb deweloperski: Nowy dialog email dostępny do testowania',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.go('/test-dialog'),
            child: const Text(
              'Testuj',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  bool _isDebugMode() {
    bool debugMode = false;
    assert(debugMode = true);
    return debugMode;
  }
}