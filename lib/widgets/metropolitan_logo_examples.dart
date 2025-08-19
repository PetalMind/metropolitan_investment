import 'package:flutter/material.dart';
import '../widgets/metropolitan_logo_widget.dart';
import '../theme/app_theme_professional.dart';

/// **Przykłady użycia MetropolitanLogoWidget**
/// 
/// Demonstracja różnych wariantów i stylów logo
class MetropolitanLogoExamples extends StatelessWidget {
  const MetropolitanLogoExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemePro.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Metropolitan Logo Examples'),
        backgroundColor: AppThemePro.backgroundSecondary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Premium Logo (Splash Screen)',
              const MetropolitanLogoWidget.splash(),
            ),
            
            _buildSection(
              'Navigation Logo',
              Row(
                children: [
                  const MetropolitanLogoWidget.navigation(
                    onTap: null, // Przykład bez callback
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Metropolitan Investment',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppThemePro.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            _buildSection(
              'Compact Logo',
              const MetropolitanLogoWidget.compact(),
            ),
            
            _buildSection(
              'Custom Sized Logo',
              const MetropolitanLogoWidget(
                size: 200,
                animated: true,
                style: MetropolitanLogoStyle.premium,
              ),
            ),
            
            _buildSection(
              'Different Colors',
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MetropolitanLogoWidget.navigation(
                    color: AppThemePro.accentGold,
                  ),
                  MetropolitanLogoWidget.navigation(
                    color: AppThemePro.textPrimary,
                  ),
                  MetropolitanLogoWidget.navigation(
                    color: AppThemePro.statusSuccess,
                  ),
                  MetropolitanLogoWidget.navigation(
                    color: AppThemePro.statusInfo,
                  ),
                ],
              ),
            ),
            
            _buildSection(
              'With Metropolitan Branding',
              const MetropolitanLogoWidget.compact().withMetropolitanBranding(
                padding: const EdgeInsets.all(24),
              ),
            ),
            
            _buildSection(
              'Interactive Logo with Callback',
              MetropolitanLogoWidget.compact(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Metropolitan Investment Logo clicked!'),
                      backgroundColor: AppThemePro.accentGold,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppThemePro.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppThemePro.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppThemePro.borderPrimary,
                width: 1,
              ),
            ),
            child: Center(child: content),
          ),
        ],
      ),
    );
  }
}

/// **Widget demonstracyjny dla głównego layoutu**
/// 
/// Pokazuje jak użyć logo w prawdziwej aplikacji
class AppBarWithMetropolitanLogo extends StatelessWidget 
    implements PreferredSizeWidget {
  
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onLogoTap;

  const AppBarWithMetropolitanLogo({
    super.key,
    required this.title,
    this.actions,
    this.onLogoTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppThemePro.backgroundSecondary,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: MetropolitanLogoWidget.navigation(
          onTap: onLogoTap ?? () {
            // Domyślnie nawiguj do home
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppThemePro.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
