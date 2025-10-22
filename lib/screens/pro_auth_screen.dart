import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../models_and_services.dart';
import '../widgets/metropolitan_logo_widget.dart';
import '../config/app_routes.dart';
import '../theme/app_theme_professional.dart';

/// 🏛️ **PROFESSIONAL AUTH SCREEN** - Metropolitan Investment
///
/// Ultra-modern, fully responsive authentication experience featuring:
/// • 💎 Premium glassmorphism with financial-grade aesthetics
/// • 🎭 Sophisticated microanimations and transitions
/// • 📱 Fully adaptive responsive design (mobile/tablet/desktop)
/// • 🎨 Corporate elegance with visual appeal
/// • ⚡ Advanced form validation and user feedback
/// • 🔒 Secure authentication with modern UX patterns
class ProAuthScreen extends StatefulWidget {
  const ProAuthScreen({super.key});

  @override
  State<ProAuthScreen> createState() => _ProAuthScreenState();
}

class _ProAuthScreenState extends State<ProAuthScreen>
    with TickerProviderStateMixin {
  // === ANIMATION CONTROLLERS ===
  late AnimationController _pageController;
  late AnimationController _backgroundController;
  late AnimationController _formController;
  late AnimationController _buttonController;

  // === ANIMATIONS ===
  late Animation<double> _pageOpacity;
  late Animation<double> _pageScale;
  late Animation<Offset> _pageSlide;
  late Animation<double> _backgroundRotation;
  late Animation<double> _formOpacity;
  late Animation<Offset> _formSlide;
  late Animation<double> _buttonScale;

  // === FORM STATE ===
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoginMode = true;
  bool _acceptTerms = false;
  bool _rememberMe = false;
  bool _isFormValid = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupFormValidation();
    _loadSavedData();
    
    // Start animations after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pageController.forward();
        _formController.forward();
      }
    });
  }

  void _initializeAnimations() {
    // Page controller
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Background controller
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    // Form controller
    _formController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Button controller
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Setup animations
    _pageOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOut),
    );

    _pageScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOutBack),
    );

    _pageSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOutCubic),
    );

    _backgroundRotation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _formOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeIn),
    );

    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutBack),
    );

    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
  }

  void _setupFormValidation() {
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _firstNameController.addListener(_validateForm);
    _lastNameController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  void _validateForm() {
    if (!mounted) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final isValidEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    final isValidPassword = password.isNotEmpty && password.length >= 6 && password.length <= 128;
    final isValidEmailLength = email.length <= 254;

    bool newFormValid;
    if (_isLoginMode) {
      newFormValid = email.isNotEmpty && isValidEmail && isValidEmailLength && isValidPassword;
    } else {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final confirmPassword = _confirmPasswordController.text;

      newFormValid = firstName.isNotEmpty &&
          firstName.length >= 2 &&
          firstName.length <= 50 &&
          lastName.isNotEmpty &&
          lastName.length >= 2 &&
          lastName.length <= 50 &&
          email.isNotEmpty &&
          isValidEmail &&
          isValidEmailLength &&
          isValidPassword &&
          RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password) &&
          confirmPassword == password &&
          confirmPassword.length <= 128 &&
          _acceptTerms;
    }

    if (_isFormValid != newFormValid) {
      setState(() => _isFormValid = newFormValid);
    }
  }

  Future<void> _loadSavedData() async {
    try {
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
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _handleAuth() async {
    if (!mounted || !_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    _buttonController.forward();

    try {
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

      if (mounted) {
        _buttonController.reverse();

        if (success) {
          HapticFeedback.lightImpact();
          context.go(AppRoutes.dashboard);
        } else {
          HapticFeedback.heavyImpact();
          _showErrorSnackBar(
            authProvider.error ?? 'Wystąpił błąd podczas autoryzacji',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _buttonController.reverse();
        _showErrorSnackBar('Wystąpił nieoczekiwany błąd');
      }
    }
  }

  void _toggleMode() {
    if (!mounted) return;

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
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppThemePro.statusError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundController.dispose();
    _formController.dispose();
    _buttonController.dispose();
    
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
      backgroundColor: AppThemePro.backgroundPrimary,
      body: AnimatedBuilder(
        animation: Listenable.merge([_pageController, _backgroundController]),
        builder: (context, child) {
          return FadeTransition(
            opacity: _pageOpacity,
            child: SlideTransition(
              position: _pageSlide,
              child: ScaleTransition(
                scale: _pageScale,
                child: Stack(
                  children: [
                    // Animated background
                    _buildAnimatedBackground(),
                    
                    // Main content
                    SafeArea(
                      child: _buildMainContent(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: GradientRotation(_backgroundRotation.value * 0.1),
          colors: [
            AppThemePro.backgroundPrimary,
            AppThemePro.primaryMedium.withValues(alpha: 0.3),
            AppThemePro.backgroundSecondary,
            AppThemePro.primaryLight.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _BackgroundPatternPainter(_backgroundRotation.value),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1200;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
        
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: isDesktop
                  ? _buildDesktopLayout()
                  : isTablet
                      ? _buildTabletLayout()
                      : _buildMobileLayout(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Row(
        children: [
          // Left side - Branding
          Expanded(
            flex: 5,
            child: _buildBrandingSection(),
          ),
          
          const SizedBox(width: 80),
          
          // Right side - Form
          Expanded(
            flex: 4,
            child: _buildFormSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          _buildCompactBranding(),
          const SizedBox(height: 60),
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _buildFormSection(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          _buildMobileBranding(),
          const SizedBox(height: 40),
          _buildFormSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBrandingSection() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          const MetropolitanLogoWidget.splash(
            size: 350,
            color: AppThemePro.accentGold,
          ),
          
          const SizedBox(height: 40),
          
          // Main headline
          Text(
            'Profesjonalna Platforma Inwestycyjna',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: AppThemePro.textPrimary,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Subtitle
          Text(
            'Zarządzaj swoimi inwestycjami z najwyższym poziomem bezpieczeństwa i zaawansowanymi narzędziami analitycznymi.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppThemePro.textSecondary,
              height: 1.6,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Feature points
          _buildFeaturePoints(),
        ],
      ),
    );
  }

  Widget _buildCompactBranding() {
    return Column(
      children: [
        const MetropolitanLogoWidget.splash(
          size: 180,
          color: AppThemePro.accentGold,
        ),
        const SizedBox(height: 24),
        Text(
          'Metropolitan Investment',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppThemePro.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Profesjonalna platforma inwestycyjna',
          style: TextStyle(
            fontSize: 14,
            color: AppThemePro.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMobileBranding() {
    return Column(
      children: [
        const MetropolitanLogoWidget.splash(
          size: 100,
          color: AppThemePro.accentGold,
        ),
        const SizedBox(height: 16),
        Text(
          'Metropolitan Investment',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppThemePro.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Profesjonalna platforma inwestycyjna',
          style: TextStyle(
            fontSize: 12,
            color: AppThemePro.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturePoints() {
    final features = [
      {'icon': Icons.security, 'text': 'Bezpieczeństwo na najwyższym poziomie'},
      {'icon': Icons.analytics, 'text': 'Zaawansowane narzędzia analityczne'},
      {'icon': Icons.account_balance, 'text': 'Profesjonalne zarządzanie portfelem'},
      {'icon': Icons.trending_up, 'text': 'Monitoring w czasie rzeczywistym'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppThemePro.accentGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppThemePro.accentGold.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: AppThemePro.accentGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  feature['text'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppThemePro.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFormSection() {
    return AnimatedBuilder(
      animation: _formController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _formOpacity,
          child: SlideTransition(
            position: _formSlide,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppThemePro.surfaceCard.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppThemePro.accentGold.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                        BoxShadow(
                          color: AppThemePro.accentGold.withValues(alpha: 0.1),
                          blurRadius: 40,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFormHeader(),
                          const SizedBox(height: 32),
                          ..._buildFormFields(),
                          const SizedBox(height: 24),
                          _buildActionButton(),
                          if (_isLoginMode) ...[
                            const SizedBox(height: 20),
                            _buildRememberMeAndForgotPassword(),
                          ],
                          const SizedBox(height: 24),
                          _buildModeToggle(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormHeader() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: Column(
        key: ValueKey(_isLoginMode),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _isLoginMode ? 'Witaj ponownie' : 'Utwórz konto',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppThemePro.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isLoginMode
                ? 'Zaloguj się do swojego konta inwestycyjnego'
                : 'Dołącz do platformy inwestycyjnej',
            style: TextStyle(
              fontSize: 14,
              color: AppThemePro.textSecondary,
              height: 1.4,
            ),
          ),
        ],
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
              child: _buildTextField(
                controller: _firstNameController,
                label: 'Imię',
                icon: Icons.person_outline,
                maxLength: 50,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Podaj imię';
                  }
                  if (value.length < 2) {
                    return 'Imię musi mieć co najmniej 2 znaki';
                  }
                  if (value.length > 50) {
                    return 'Imię może mieć maksymalnie 50 znaków';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _lastNameController,
                label: 'Nazwisko',
                icon: Icons.person_outline,
                maxLength: 50,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Podaj nazwisko';
                  }
                  if (value.length < 2) {
                    return 'Nazwisko musi mieć co najmniej 2 znaki';
                  }
                  if (value.length > 50) {
                    return 'Nazwisko może mieć maksymalnie 50 znaków';
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
    fields.addAll([
      _buildTextField(
        controller: _emailController,
        label: 'Adres email',
        hint: 'twoj@email.com',
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        maxLength: 254,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Podaj adres email';
          }
          if (value.length > 254) {
            return 'Adres email może mieć maksymalnie 254 znaki';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Podaj prawidłowy adres email';
          }
          return null;
        },
      ),
      const SizedBox(height: 20),
    ]);

    // Password field
    fields.addAll([
      _buildTextField(
        controller: _passwordController,
        label: 'Hasło',
        hint: _isLoginMode ? 'Wprowadź hasło' : 'Minimum 6 znaków',
        icon: Icons.lock_outlined,
        obscureText: !_showPassword,
        maxLength: 128,
        suffixIcon: IconButton(
          onPressed: () {
            setState(() => _showPassword = !_showPassword);
            HapticFeedback.selectionClick();
          },
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              key: ValueKey(_showPassword),
              color: AppThemePro.accentGold,
            ),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Podaj hasło';
          }
          if (value.length < 6) {
            return 'Hasło musi mieć co najmniej 6 znaków';
          }
          if (value.length > 128) {
            return 'Hasło może mieć maksymalnie 128 znaków';
          }
          if (!_isLoginMode) {
            if (!RegExp(r'^(?=.*[a-z])').hasMatch(value)) {
              return 'Hasło musi zawierać małą literę';
            }
            if (!RegExp(r'^(?=.*[A-Z])').hasMatch(value)) {
              return 'Hasło musi zawierać wielką literę';
            }
            if (!RegExp(r'^(?=.*\d)').hasMatch(value)) {
              return 'Hasło musi zawierać cyfrę';
            }
          }
          return null;
        },
      ),
    ]);

    // Password requirements hint for registration
    if (!_isLoginMode && _passwordController.text.isNotEmpty) {
      fields.addAll([
        const SizedBox(height: 12),
        _buildPasswordRequirements(),
      ]);
    }

    if (!_isLoginMode) {
      fields.addAll([
        const SizedBox(height: 20),
        _buildTextField(
          controller: _confirmPasswordController,
          label: 'Potwierdź hasło',
          hint: 'Powtórz hasło',
          icon: Icons.lock_outlined,
          obscureText: !_showConfirmPassword,
          maxLength: 128,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() => _showConfirmPassword = !_showConfirmPassword);
              HapticFeedback.selectionClick();
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _showConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                key: ValueKey(_showConfirmPassword),
                color: AppThemePro.accentGold,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Potwierdź hasło';
            }
            if (value.length > 128) {
              return 'Hasło może mieć maksymalnie 128 znaków';
            }
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      maxLength: maxLength,
      style: TextStyle(
        color: AppThemePro.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppThemePro.accentGold, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppThemePro.surfaceInteractive.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppThemePro.borderPrimary.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppThemePro.borderPrimary.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppThemePro.accentGold,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppThemePro.statusError,
            width: 1,
          ),
        ),
        labelStyle: TextStyle(
          color: AppThemePro.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: AppThemePro.textTertiary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        counterStyle: TextStyle(
          color: AppThemePro.textTertiary,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemePro.accentGold.withValues(alpha: 0.2),
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
                HapticFeedback.selectionClick();
                setState(() => _acceptTerms = value ?? false);
                _validateForm();
              },
              activeColor: AppThemePro.accentGold,
              checkColor: AppThemePro.primaryDark,
              side: BorderSide(
                color: AppThemePro.accentGold.withValues(alpha: 0.5),
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: 'Akceptuję ',
                style: TextStyle(
                  color: AppThemePro.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                children: [
                  TextSpan(
                    text: 'Regulamin',
                    style: TextStyle(
                      color: AppThemePro.accentGold,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' i '),
                  TextSpan(
                    text: 'Politykę Prywatności',
                    style: TextStyle(
                      color: AppThemePro.accentGold,
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

  Widget _buildActionButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return AnimatedBuilder(
          animation: _buttonController,
          builder: (context, child) {
            return Transform.scale(
              scale: _buttonScale.value,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isFormValid
                        ? [
                            AppThemePro.accentGold,
                            AppThemePro.accentGoldMuted,
                            AppThemePro.accentGoldDark,
                          ]
                        : [
                            AppThemePro.textDisabled,
                            AppThemePro.textMuted,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isFormValid
                      ? [
                          BoxShadow(
                            color: AppThemePro.accentGold.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: (_isFormValid && !authProvider.isLoading) ? _handleAuth : null,
                    child: Container(
                      alignment: Alignment.center,
                      child: authProvider.isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppThemePro.primaryDark,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isLoginMode ? Icons.login : Icons.account_balance_wallet,
                                  color: AppThemePro.primaryDark,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isLoginMode ? 'ZALOGUJ SIĘ' : 'UTWÓRZ KONTO',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: AppThemePro.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRememberMeAndForgotPassword() {
    return Row(
      children: [
        Transform.scale(
          scale: 1.1,
          child: Checkbox(
            value: _rememberMe,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _rememberMe = value ?? false);
            },
            activeColor: AppThemePro.accentGold,
            checkColor: AppThemePro.primaryDark,
            side: BorderSide(
              color: AppThemePro.accentGold.withValues(alpha: 0.5),
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
            color: AppThemePro.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    final password = _passwordController.text;
    final hasMinLength = password.length >= 6;
    final hasLowercase = RegExp(r'^(?=.*[a-z])').hasMatch(password);
    final hasUppercase = RegExp(r'^(?=.*[A-Z])').hasMatch(password);
    final hasDigit = RegExp(r'^(?=.*\d)').hasMatch(password);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemePro.surfaceCard.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemePro.accentGold.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wymagania hasła:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppThemePro.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirementItem('Co najmniej 6 znaków', hasMinLength),
          _buildRequirementItem('Mała litera (a-z)', hasLowercase),
          _buildRequirementItem('Wielka litera (A-Z)', hasUppercase),
          _buildRequirementItem('Cyfra (0-9)', hasDigit),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isMet 
                  ? AppThemePro.accentGold
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isMet 
                    ? AppThemePro.accentGold
                    : AppThemePro.textMuted,
                width: 1.5,
              ),
            ),
            child: isMet
                ? Icon(
                    Icons.check,
                    size: 12,
                    color: AppThemePro.primaryDark,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isMet 
                    ? AppThemePro.accentGold
                    : AppThemePro.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLoginMode ? 'Nie masz konta? ' : 'Masz już konto? ',
          style: TextStyle(
            color: AppThemePro.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        TextButton(
          onPressed: _toggleMode,
          child: Text(
            _isLoginMode ? 'Zarejestruj się' : 'Zaloguj się',
            style: TextStyle(
              color: AppThemePro.accentGold,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for background pattern
class _BackgroundPatternPainter extends CustomPainter {
  final double animationValue;

  _BackgroundPatternPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppThemePro.accentGold.withValues(alpha: 0.015)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final spacing = 100.0;
    final offset = animationValue * spacing * 0.5;

    // Draw grid pattern
    for (double x = -spacing + offset; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = -spacing + offset; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw diagonal lines
    paint.color = AppThemePro.accentGold.withValues(alpha: 0.008);
    for (double x = -150 + offset; x < size.width + 150; x += 150) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BackgroundPatternPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}