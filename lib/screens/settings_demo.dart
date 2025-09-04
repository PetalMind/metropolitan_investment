import 'package:flutter/material.dart';
import '../theme/app_theme_professional.dart';
import 'settings_screen_responsive.dart';

/// 🚀 Demo Application for Responsive Settings Screen
/// Showcases the amazing responsive design and sophisticated animations
class SettingsDemoApp extends StatelessWidget {
  const SettingsDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metropolitan Investment - Settings Demo',
      theme: AppThemePro.professionalTheme,
      home: const SettingsDemoScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SettingsDemoScreen extends StatefulWidget {
  const SettingsDemoScreen({super.key});

  @override
  State<SettingsDemoScreen> createState() => _SettingsDemoScreenState();
}

class _SettingsDemoScreenState extends State<SettingsDemoScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late Animation<double> _heroOpacity;
  late Animation<Offset> _heroSlide;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _heroOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
    );

    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _heroController, curve: Curves.easeOutBack),
        );

    _heroController.forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemePro.backgroundPrimary,
      body: Column(
        children: [
          _buildHeroSection(),
          Expanded(child: const ResponsiveSettingsScreen()),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppThemePro.primaryDark,
            AppThemePro.primaryMedium,
            AppThemePro.accentGold.withOpacity(0.1),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(child: CustomPaint(painter: HeroPatternPainter())),

          // Content
          FadeTransition(
            opacity: _heroOpacity,
            child: SlideTransition(
              position: _heroSlide,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppThemePro.accentGold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppThemePro.accentGold.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.settings_rounded,
                            color: AppThemePro.accentGold,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Responsive Settings Demo',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: AppThemePro.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sophisticated responsive design • Premium animations • Professional UX',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppThemePro.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureHighlights(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHighlights() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        return Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildFeatureBadge('📱 Mobile First', isCompact: !isWide),
            _buildFeatureBadge('💻 Desktop Optimized', isCompact: !isWide),
            _buildFeatureBadge('🎨 AppTheme Pro', isCompact: !isWide),
            _buildFeatureBadge('⚡ Smooth Animations', isCompact: !isWide),
            _buildFeatureBadge('🎯 Premium UX', isCompact: !isWide),
          ],
        );
      },
    );
  }

  Widget _buildFeatureBadge(String text, {bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCompact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: AppThemePro.backgroundSecondary.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppThemePro.accentGold.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemePro.accentGold.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppThemePro.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Custom painter for the hero section background pattern
class HeroPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppThemePro.accentGold.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw geometric pattern
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Draw subtle diamond pattern
        final path = Path()
          ..moveTo(x + spacing / 2, y)
          ..lineTo(x + spacing, y + spacing / 2)
          ..lineTo(x + spacing / 2, y + spacing)
          ..lineTo(x, y + spacing / 2)
          ..close();

        canvas.drawPath(path, paint);
      }
    }

    // Draw flowing curves
    final curvePaint = Paint()
      ..color = AppThemePro.accentGold.withOpacity(0.03)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.1,
      size.width * 0.5,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width,
      size.height * 0.2,
    );

    canvas.drawPath(path, curvePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// 🎯 Usage Instructions Widget
class SettingsUsageInstructions extends StatelessWidget {
  const SettingsUsageInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: AppThemePro.premiumCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: AppThemePro.accentGold,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'How to Use This Amazing Settings Screen',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppThemePro.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildInstructionStep(
            context,
            '1',
            'Import the screen',
            "import '../screens/settings_screen_responsive.dart';",
            'Add this import to your main app file or router configuration',
          ),

          _buildInstructionStep(
            context,
            '2',
            'Use in your app',
            'ResponsiveSettingsScreen()',
            'Simply instantiate the widget - it handles all responsive logic automatically',
          ),

          _buildInstructionStep(
            context,
            '3',
            'Customize theme',
            'Apply AppThemePro.professionalTheme to your MaterialApp',
            'The screen is designed to work seamlessly with the professional theme system',
          ),

          _buildInstructionStep(
            context,
            '4',
            'Test responsiveness',
            'Resize your window or test on different devices',
            'Watch the layout adapt beautifully from mobile to desktop',
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemePro.accentGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppThemePro.accentGold.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: AppThemePro.accentGold,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Key Features',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppThemePro.accentGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFeatureList([
                  'Fully responsive design (mobile, tablet, desktop)',
                  'Sophisticated animations and micro-interactions',
                  'Professional AppTheme Pro integration',
                  'Premium visual hierarchy with gold accents',
                  'Smooth transitions and state management',
                  'Touch-friendly interactions on mobile',
                  'Keyboard shortcuts on desktop',
                  'RBAC support for admin features',
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(
    BuildContext context,
    String number,
    String title,
    String code,
    String description,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppThemePro.accentGold,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppThemePro.primaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppThemePro.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppThemePro.surfaceInteractive,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppThemePro.borderSecondary,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    code,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemePro.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppThemePro.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList(List<String> features) {
    return Builder(
      builder: (context) => Column(
        children: features
            .map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppThemePro.accentGold,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppThemePro.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// 🚀 Run this demo to see the responsive settings in action
void main() {
  runApp(const SettingsDemoApp());
}
