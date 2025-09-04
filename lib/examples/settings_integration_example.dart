import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_routes.dart';
import '../theme/app_theme_professional.dart';

/// 🎯 Quick Integration Example
/// Shows how to use the new responsive settings screen in your app
class SettingsIntegrationExample extends StatelessWidget {
  const SettingsIntegrationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemePro.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Settings Integration Example'),
        backgroundColor: AppThemePro.backgroundPrimary,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hero section
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppThemePro.accentGold.withOpacity(0.1),
                      AppThemePro.accentGoldMuted.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppThemePro.accentGold.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.settings_rounded,
                      size: 64,
                      color: AppThemePro.accentGold,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'New Responsive Settings',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppThemePro.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Experience the amazing responsive design with professional animations and premium UX',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppThemePro.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Action buttons
              _buildActionButton(
                context,
                'Open Responsive Settings',
                'Navigate to the new settings screen',
                Icons.settings_rounded,
                AppThemePro.accentGold,
                () => context.go(AppRoutes.settings),
              ),
              
              const SizedBox(height: 16),
              
              _buildActionButton(
                context,
                'View Settings Demo',
                'See the complete showcase with examples',
                Icons.play_circle_filled_rounded,
                AppThemePro.statusInfo,
                () => context.goToSettingsDemo(),
              ),
              
              const SizedBox(height: 24),
              
              // Integration info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppThemePro.premiumCardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.integration_instructions_rounded,
                          color: AppThemePro.statusSuccess,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Integration Complete!',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppThemePro.statusSuccess,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The responsive settings screen has been successfully integrated into your app routes. Your old settings route now uses the new ResponsiveSettingsScreen with:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppThemePro.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildFeatureList([
                      'Full responsive design (mobile, tablet, desktop)',
                      'Professional AppTheme Pro integration',
                      'Smooth animations and transitions',
                      'Premium visual hierarchy',
                      'Touch-friendly mobile interface',
                      'Keyboard shortcuts for desktop',
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withOpacity(0.3), width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: color.withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeatureList(List<String> features) {
    return features.map((feature) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppThemePro.statusSuccess,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                fontSize: 12,
                color: AppThemePro.textMuted,
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }
}

/// 🎯 How to Use in Your App:
/// 
/// 1. The route /settings now uses ResponsiveSettingsScreen automatically
/// 2. Navigate using: context.go(AppRoutes.settings)
/// 3. For demo: context.goToSettingsDemo()
/// 4. All existing navigation will work with the new responsive design!
/// 
/// Example usage in your widgets:
/// ```dart
/// IconButton(
///   onPressed: () => context.go(AppRoutes.settings),
///   icon: Icon(Icons.settings),
/// )
/// ```