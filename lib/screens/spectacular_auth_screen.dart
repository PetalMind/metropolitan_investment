import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../models_and_services.dart';
import '../widgets/metropolitan_logo_widget.dart';
import '../config/app_routes.dart';
import '../services/audio_service.dart';

/// 🌟 **SPECTACULAR AUTH SCREEN** - Metropolitan Investment
///
/// Ultra-premium authentication experience with:
/// • 🎨 Glassmorphism & particle system
/// • 🌊 Fluid 3D animations & morphing shapes
/// • ⚡ Progressive disclosure UI flow
/// • 🎯 Advanced micro-interactions
/// • 📱 Responsive design with haptic feedback
/// • 🎪 WOW factor with investment-themed visuals
class SpectacularAuthScreen extends StatefulWidget {
  const SpectacularAuthScreen({super.key});

  @override
  State<SpectacularAuthScreen> createState() => _SpectacularAuthScreenState();
}

class _SpectacularAuthScreenState extends State<SpectacularAuthScreen>
    with TickerProviderStateMixin {
  // === ANIMATION CONTROLLERS ===
  late AnimationController _masterController;
  late AnimationController _particlesController;
  late AnimationController _morphController;
  late AnimationController _uiController;
  late AnimationController _logoController;
  late AnimationController _formController;
  late AnimationController _successController;

  // === MASTER ANIMATIONS ===
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleInAnimation;
  late Animation<Offset> _slideUpAnimation;

  // === MORPHING SHAPES ===
  late Animation<double> _shapeMorphAnimation;
  late Animation<double> _shapeRotationAnimation;

  // === UI FLOW ANIMATIONS ===
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _formOpacityAnimation;
  late Animation<Offset> _formSlideAnimation;

  // === SUCCESS ANIMATIONS ===
  late Animation<double> _successScaleAnimation;
  late Animation<double> _successOpacityAnimation;

  // === FORM STATE ===
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;
  bool _rememberMe = false;
  bool _isFormValid = false;
  bool _showSuccess = false;

  // === PARTICLES SYSTEM ===
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeParticles();
    _setupFormValidation();
    _loadSavedData();
  }

  void _initializeAnimations() {
    // Master controller for overall timing
    _masterController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Particles animation
    _particlesController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Morphing shapes
    _morphController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    // UI flow controllers
    _uiController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _formController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Master animations
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _masterController, curve: Curves.easeOut),
    );

    _scaleInAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _masterController, curve: Curves.elasticOut),
    );

    _slideUpAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _masterController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Morphing animations
    _shapeMorphAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _morphController, curve: Curves.easeInOut),
    );

    _shapeRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _morphController, curve: Curves.linear));

    // UI flow animations
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _formOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _formController, curve: Curves.easeIn));

    _formSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _formController, curve: Curves.easeOutBack),
        );

    // Success animations
    _successScaleAnimation = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    _successOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeIn),
    );

    // Start master animation
    _masterController.forward().then((_) {
      _logoController.forward().then((_) {
        _formController.forward();
      });
    });
  }

  void _initializeParticles() {
    for (int i = 0; i < 50; i++) {
      _particles.add(Particle.random(_random));
    }
  }

  void _setupFormValidation() {
    final controllers = [
      _emailController,
      _passwordController,
      if (!_isLoginMode) ...[
        _firstNameController,
        _lastNameController,
        _confirmPasswordController,
      ],
    ];

    for (final controller in controllers) {
      controller.addListener(_validateForm);
    }
  }

  void _validateForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final isValidEmail = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(email);
    final isValidPassword = password.isNotEmpty && password.length >= 6;

    if (_isLoginMode) {
      _isFormValid = email.isNotEmpty && isValidEmail && isValidPassword;
    } else {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final confirmPassword = _confirmPasswordController.text;

      _isFormValid =
          firstName.isNotEmpty &&
          firstName.length >= 2 &&
          lastName.isNotEmpty &&
          lastName.length >= 2 &&
          email.isNotEmpty &&
          isValidEmail &&
          isValidPassword &&
          RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password) &&
          confirmPassword == password &&
          _acceptTerms;
    }

    setState(() {});
  }

  Future<void> _loadSavedData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final savedData = await authProvider.getSavedLoginData();

    if (mounted) {
      setState(() {
        _rememberMe = savedData['rememberMe'] ?? false;
        final lastEmail = savedData['lastEmail'];
        if (lastEmail != null && _rememberMe) {
          _emailController.text = lastEmail;
        }
      });
    }
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    // Play button click sound
    AudioService.instance.playButtonClickSound();
    
    HapticFeedback.heavyImpact();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success;
    if (_isLoginMode) {
      success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
        rememberMe: _rememberMe,
      );
    } else {
      success = await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );
    }

    if (success && mounted) {
      HapticFeedback.mediumImpact();
      setState(() => _showSuccess = true);
      _successController.forward();

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        context.go(AppRoutes.dashboard);
      }
    } else if (mounted) {
      HapticFeedback.vibrate();
      _showErrorSnackBar(
        authProvider.error ?? 'Wystąpił błąd podczas autoryzacji',
      );
    }
  }

  void _toggleMode() {
    // Play button click sound
    AudioService.instance.playButtonClickSound();
    
    HapticFeedback.selectionClick();
    setState(() {
      _isLoginMode = !_isLoginMode;
      _acceptTerms = false;
      _isFormValid = false;
    });
    _validateForm();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.textOnPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: AppTheme.textOnPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 12,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _masterController.dispose();
    _particlesController.dispose();
    _morphController.dispose();
    _uiController.dispose();
    _logoController.dispose();
    _formController.dispose();
    _successController.dispose();

    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Stack(
        children: [
          // Animated particle background
          _buildParticleBackground(),

          // Morphing shapes background
          _buildMorphingShapes(),

          // Main content
          FadeTransition(
            opacity: _fadeInAnimation,
            child: SlideTransition(
              position: _slideUpAnimation,
              child: ScaleTransition(
                scale: _scaleInAnimation,
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // Animated logo
                        _buildAnimatedLogo(),

                        const SizedBox(height: 60),

                        // Glassmorphism form container
                        _buildGlassmorphismForm(),

                        const SizedBox(height: 40),

                        // Mode toggle
                        _buildModeToggle(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Success overlay
          if (_showSuccess) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  Widget _buildParticleBackground() {
    return AnimatedBuilder(
      animation: _particlesController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_particles, _particlesController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildMorphingShapes() {
    return AnimatedBuilder(
      animation: _morphController,
      builder: (context, child) {
        return CustomPaint(
          painter: MorphingShapesPainter(
            _shapeMorphAnimation.value,
            _shapeRotationAnimation.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildAnimatedLogo() {
    return ScaleTransition(
      scale: _logoScaleAnimation,
      child: Column(
        children: [
          // Premium logo with glow effect
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryGold.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const MetropolitanLogoWidget.splash(
              size: 200,
              color: AppTheme.secondaryGold,
            ),
          ),

          const SizedBox(height: 24),

          // Animated tagline
          AnimatedBuilder(
            animation: _logoController,
            builder: (context, child) {
              return Opacity(
                opacity: _logoController.value,
                child: Column(
                  children: [
                    Text(
                      'Metropolitan Investment',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.secondaryGold.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _isLoginMode
                            ? 'Witaj w świecie profesjonalnych inwestycji'
                            : 'Dołącz do elitarnej platformy inwestycyjnej',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphismForm() {
    return FadeTransition(
      opacity: _formOpacityAnimation,
      child: SlideTransition(
        position: _formSlideAnimation,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.secondaryGold.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Form title
                      Text(
                        _isLoginMode ? 'Logowanie' : 'Rejestracja',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 32),

                      // Dynamic form fields
                      ..._buildFormFields(),

                      const SizedBox(height: 24),

                      // Premium login button
                      _buildPremiumButton(),

                      // Additional options
                      if (_isLoginMode) ...[
                        const SizedBox(height: 20),
                        _buildRememberMeAndForgotPassword(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormFields() {
    final fields = <Widget>[];

    if (!_isLoginMode) {
      // Name fields for registration
      fields.addAll([
        Row(
          children: [
            Expanded(
              child: _buildPremiumTextField(
                controller: _firstNameController,
                label: 'Imię',
                icon: Icons.person_outline,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Podaj imię';
                  if (value.length < 2) {
                    return 'Imię musi mieć co najmniej 2 znaki';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildPremiumTextField(
                controller: _lastNameController,
                label: 'Nazwisko',
                icon: Icons.person_outline,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Podaj nazwisko';
                  if (value.length < 2) {
                    return 'Nazwisko musi mieć co najmniej 2 znaki';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ]);
    }

    // Email field
    fields.add(
      _buildPremiumTextField(
        controller: _emailController,
        label: 'Adres email',
        hint: 'twoj@email.com',
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Podaj adres email';
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Podaj prawidłowy adres email';
          }
          return null;
        },
      ),
    );

    fields.add(const SizedBox(height: 20));

    // Password field
    fields.add(
      _buildPremiumTextField(
        controller: _passwordController,
        label: 'Hasło',
        hint: _isLoginMode ? 'Wprowadź hasło' : 'Minimum 6 znaków',
        icon: Icons.lock_outlined,
        obscureText: !_isPasswordVisible,
        suffixIcon: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              key: ValueKey(_isPasswordVisible),
              color: AppTheme.textSecondary,
            ),
          ),
          onPressed: () {
            AudioService.instance.playButtonClickSound();
            HapticFeedback.selectionClick();
            setState(() => _isPasswordVisible = !_isPasswordVisible);
          },
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Podaj hasło';
          if (value.length < 6) return 'Hasło musi mieć co najmniej 6 znaków';
          if (!_isLoginMode &&
              !RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
            return 'Hasło musi zawierać małą literę, wielką literę i cyfrę';
          }
          return null;
        },
      ),
    );

    if (!_isLoginMode) {
      fields.addAll([
        const SizedBox(height: 20),
        _buildPremiumTextField(
          controller: _confirmPasswordController,
          label: 'Potwierdź hasło',
          hint: 'Powtórz hasło',
          icon: Icons.lock_outlined,
          obscureText: !_isConfirmPasswordVisible,
          suffixIcon: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isConfirmPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
                key: ValueKey(_isConfirmPasswordVisible),
                color: AppTheme.textSecondary,
              ),
            ),
            onPressed: () {
              AudioService.instance.playButtonClickSound();
              HapticFeedback.selectionClick();
              setState(
                () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
              );
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Potwierdź hasło';
            if (value != _passwordController.text) {
              return 'Hasła nie są identyczne';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        _buildTermsAndConditions(),
      ]);
    }

    return fields;
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization? textCapitalization,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.secondaryGold.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryGold.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization ?? TextCapitalization.none,
        obscureText: obscureText,
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.secondaryGold),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: AppTheme.surfaceCard.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppTheme.secondaryGold, width: 2),
          ),
          labelStyle: TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(color: AppTheme.textTertiary),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.secondaryGold.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: _acceptTerms,
              onChanged: (value) {
                AudioService.instance.playButtonClickSound();
                HapticFeedback.selectionClick();
                setState(() => _acceptTerms = value ?? false);
                _validateForm();
              },
              activeColor: AppTheme.secondaryGold,
              checkColor: AppTheme.textOnSecondary,
              side: BorderSide(
                color: AppTheme.secondaryGold.withValues(alpha: 0.5),
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: 'Akceptuję ',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: 'Regulamin',
                    style: TextStyle(
                      color: AppTheme.secondaryGold,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' i '),
                  TextSpan(
                    text: 'Politykę Prywatności',
                    style: TextStyle(
                      color: AppTheme.secondaryGold,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isFormValid
                  ? [
                      AppTheme.secondaryGold,
                      AppTheme.secondaryCopper,
                      AppTheme.secondaryAmber,
                    ]
                  : [AppTheme.textDisabled, AppTheme.textTertiary],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: _isFormValid
                ? [
                    BoxShadow(
                      color: AppTheme.secondaryGold.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: (_isFormValid && !authProvider.isLoading)
                  ? _handleAuth
                  : null,
              child: Container(
                alignment: Alignment.center,
                child: authProvider.isLoading
                    ? SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: AppTheme.textOnSecondary,
                          strokeWidth: 3,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isLoginMode
                                ? Icons.login
                                : Icons.account_balance_wallet,
                            color: AppTheme.textOnSecondary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isLoginMode ? 'ZALOGUJ SIĘ' : 'UTWÓRZ KONTO',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: AppTheme.textOnSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRememberMeAndForgotPassword() {
    return Row(
      children: [
        Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: _rememberMe,
            onChanged: (value) {
              AudioService.instance.playButtonClickSound();
              HapticFeedback.selectionClick();
              setState(() => _rememberMe = value ?? false);
            },
            activeColor: AppTheme.secondaryGold,
            checkColor: AppTheme.textOnSecondary,
            side: BorderSide(
              color: AppTheme.secondaryGold.withValues(alpha: 0.5),
              width: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Text(
          'Zapamiętaj mnie',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            AudioService.instance.playButtonClickSound();
            HapticFeedback.selectionClick();
            // TODO: Implement forgot password
          },
          child: Text(
            'Zapomniałeś hasła?',
            style: TextStyle(
              color: AppTheme.secondaryGold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLoginMode ? 'Nie masz konta? ' : 'Masz już konto? ',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: _toggleMode,
          child: Text(
            _isLoginMode ? 'Zarejestruj się' : 'Zaloguj się',
            style: TextStyle(
              color: AppTheme.secondaryGold,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: AppTheme.backgroundPrimary.withValues(alpha: 0.9),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(
          child: ScaleTransition(
            scale: _successScaleAnimation,
            child: FadeTransition(
              opacity: _successOpacityAnimation,
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.secondaryGold.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryGold.withValues(alpha: 0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 80,
                      color: AppTheme.successPrimary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Sukces!',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isLoginMode
                          ? 'Logowanie zakończone pomyślnie'
                          : 'Konto zostało utworzone',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 🎨 **PARTICLE SYSTEM** - Investment-themed floating particles
class Particle {
  double x, y;
  double vx, vy;
  double size;
  Color color;
  double opacity;
  String symbol; // Investment symbols: $, €, £, ¥, stock symbols

  Particle.random(math.Random random)
    : x = random.nextDouble() * 400,
      y = random.nextDouble() * 800,
      vx = (random.nextDouble() - 0.5) * 0.5,
      vy = (random.nextDouble() - 0.5) * 0.5,
      size = random.nextDouble() * 20 + 10,
      color = [
        const Color(0xFFFFD700), // Gold
        const Color(0xFFF4D03F), // Copper
        const Color(0xFFE6B800), // Amber
        const Color(0xFF00D7AA), // Gain green
        const Color(0xFF2196F3), // Info blue
      ][random.nextInt(5)],
      opacity = random.nextDouble() * 0.6 + 0.2,
      symbol = [
        '\$',
        '€',
        '£',
        '¥',
        '📈',
        '📊',
        '💰',
        '🏛️',
      ][random.nextInt(8)];

  void update(double deltaTime) {
    x += vx * deltaTime;
    y += vy * deltaTime;

    // Wrap around screen
    if (x < -50) x = 450;
    if (x > 450) x = -50;
    if (y < -50) y = 850;
    if (y > 850) y = -50;
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      particle.update(1);

      paint.color = particle.color.withValues(alpha: particle.opacity);

      // Draw particle with glow
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // Draw symbol
      final textPainter = TextPainter(
        text: TextSpan(
          text: particle.symbol,
          style: TextStyle(
            color: particle.color.withValues(alpha: particle.opacity * 1.5),
            fontSize: particle.size * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          particle.x - textPainter.width / 2,
          particle.y - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

/// 🎭 **MORPHING SHAPES** - Abstract investment visualizations
class MorphingShapesPainter extends CustomPainter {
  final double morphValue;
  final double rotationValue;

  MorphingShapesPainter(this.morphValue, this.rotationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.secondaryGold.withValues(alpha: 0.05);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotationValue);

    // Draw morphing investment chart shapes
    final path = Path();

    // Create organic, flowing shapes that represent market movements
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi / 3) + morphValue * math.pi;
      final radius = 150 + math.sin(morphValue * 2 * math.pi + i) * 50;

      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);

    // Draw secondary shapes
    paint.color = AppTheme.secondaryCopper.withValues(alpha: 0.03);
    canvas.rotate(math.pi / 3);

    final path2 = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * 2 * math.pi / 4) + morphValue * math.pi * 1.5;
      final radius = 100 + math.cos(morphValue * 2 * math.pi + i) * 30;

      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;

      if (i == 0) {
        path2.moveTo(x, y);
      } else {
        path2.lineTo(x, y);
      }
    }

    path2.close();
    canvas.drawPath(path2, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(MorphingShapesPainter oldDelegate) =>
      oldDelegate.morphValue != morphValue ||
      oldDelegate.rotationValue != rotationValue;
}
