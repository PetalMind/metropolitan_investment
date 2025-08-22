import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme_professional.dart';

class CustomLoadingWidget extends StatefulWidget {
  final String? message;
  final double? progress;
  final bool showProgress;
  final Color? color;

  const CustomLoadingWidget({
    super.key,
    this.message,
    this.progress,
    this.showProgress = false,
    this.color,
  });

  @override
  State<CustomLoadingWidget> createState() => _CustomLoadingWidgetState();
}

class _CustomLoadingWidgetState extends State<CustomLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.color ?? AppThemePro.accentGold;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing circle
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Main loading indicator
              AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: CustomPaint(
                        painter: LoadingRingPainter(
                          progress: widget.showProgress
                              ? (widget.progress ?? 0.0)
                              : null,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Center icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.trending_up,
                  color: AppThemePro.primaryDark,
                  size: 20,
                ),
              ),

              // Progress percentage (if showing progress)
              if (widget.showProgress && widget.progress != null)
                Positioned(
                  bottom: -30,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppThemePro.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppThemePro.borderSecondary,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '${(widget.progress! * 100).toInt()}%',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 32),

          // Loading message
          if (widget.message != null) ...[
            Text(
              widget.message!,
              style: TextStyle(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],

          // Animated dots
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final delay = index * 0.3;
                  final progress = (_rotationController.value + delay) % 1.0;
                  final opacity = (math.sin(progress * math.pi * 2) + 1) / 2;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppThemePro.textTertiary.withOpacity(opacity),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class LoadingRingPainter extends CustomPainter {
  final double? progress;
  final Color color;

  LoadingRingPainter({this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background ring
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress ring
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withOpacity(0.7), color],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    if (progress != null) {
      // Draw specific progress
      final sweepAngle = 2 * math.pi * progress!;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    } else {
      // Draw animated loading ring
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        math.pi, // Half circle
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(LoadingRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class ProgressLoadingWidget extends StatelessWidget {
  final double progress;
  final String message;
  final String? details;

  const ProgressLoadingWidget({
    super.key,
    required this.progress,
    required this.message,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomLoadingWidget(
            progress: progress,
            showProgress: true,
            message: message,
          ),
          if (details != null) ...[
            const SizedBox(height: 16),
            Text(
              details!,
              style: TextStyle(color: AppThemePro.textTertiary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class InvestmentLoadingStages extends StatefulWidget {
  final VoidCallback? onComplete;

  const InvestmentLoadingStages({super.key, this.onComplete});

  @override
  State<InvestmentLoadingStages> createState() =>
      _InvestmentLoadingStagesState();
}

class _InvestmentLoadingStagesState extends State<InvestmentLoadingStages> {
  double _progress = 0.0;
  String _currentStage = 'Inicjalizacja...';
  String _details = '';

  final List<Map<String, String>> _stages = [
    {
      'message': 'Łączenie z bazą danych...',
      'details': 'Nawiązywanie połączenia z Firebase',
    },
    {
      'message': 'Pobieranie danych inwestycji...',
      'details': 'Ładowanie portfolio klientów',
    },
    {
      'message': 'Przetwarzanie informacji...',
      'details': 'Obliczanie statystyk i wskaźników',
    },
    {
      'message': 'Optymalizacja wyświetlania...',
      'details': 'Przygotowywanie interfejsu użytkownika',
    },
    {'message': 'Finalizacja...', 'details': 'Ostatnie przygotowania'},
  ];

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() async {
    for (int i = 0; i < _stages.length; i++) {
      setState(() {
        _currentStage = _stages[i]['message']!;
        _details = _stages[i]['details']!;
      });

      // Simulate loading stages with realistic timing
      for (
        double progress = _progress;
        progress <= (i + 1) / _stages.length;
        progress += 0.02
      ) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (mounted) {
          setState(() {
            _progress = progress.clamp(0.0, 1.0);
          });
        }
      }

      // Ensure we reach exactly the target progress
      setState(() {
        _progress = (i + 1) / _stages.length;
      });

      // Pause between stages
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Complete
    await Future.delayed(const Duration(milliseconds: 300));
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ProgressLoadingWidget(
        progress: _progress,
        message: _currentStage,
        details: _details,
      ),
    );
  }
}
