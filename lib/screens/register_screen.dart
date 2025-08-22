import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme_professional.dart';
import '../widgets/metropolitan_logo_widget.dart';
import '../config/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Enhanced animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _staggerController;
  late AnimationController _backgroundController;

  // Enhanced animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundShiftAnimation;

  // Field animations for staggered entrance
  late List<Animation<double>> _fieldAnimations;
  late List<Animation<Offset>> _fieldSlideAnimations;

  // Button animation
  late AnimationController _buttonController;
  late Animation<double> _buttonScaleAnimation;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupFormValidation();
  }

  void _initializeAnimations() {
    // Main controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Main animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
        );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _backgroundShiftAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _buttonScaleAnimation = _buttonController;

    // Staggered field animations
    _fieldAnimations = List.generate(7, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            index * 0.1,
            0.7 + (index * 0.1),
            curve: Curves.easeOutQuart,
          ),
        ),
      );
    });

    _fieldSlideAnimations = List.generate(7, (index) {
      return Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            index * 0.1,
            0.7 + (index * 0.1),
            curve: Curves.easeOutBack,
          ),
        ),
      );
    });

    // Start animations with delays
    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeController.forward();
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      _slideController.forward();
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      _scaleController.forward();
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      _staggerController.forward();
    });

    _backgroundController.repeat();
  }

  void _setupFormValidation() {
    final controllers = [
      _firstNameController,
      _lastNameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
    ];

    for (final controller in controllers) {
      controller.addListener(_validateForm);
    }
  }

  void _validateForm() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final isValid =
        firstName.isNotEmpty &&
        firstName.length >= 2 &&
        lastName.isNotEmpty &&
        lastName.length >= 2 &&
        email.isNotEmpty &&
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email) &&
        password.isNotEmpty &&
        password.length >= 6 &&
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password) &&
        confirmPassword == password &&
        _acceptTerms;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _staggerController.dispose();
    _backgroundController.dispose();
    _buttonController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      _showErrorSnackBar('Musisz zaakceptować regulamin');
      return;
    }

    // Haptic feedback
    HapticFeedback.lightImpact();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );

    if (success && mounted) {
      // Success haptic feedback
      HapticFeedback.mediumImpact();
      context.go(AppRoutes.dashboard);
    } else if (mounted) {
      // Error haptic feedback
      HapticFeedback.heavyImpact();
      _showErrorSnackBar(
        authProvider.error ?? 'Wystąpił błąd podczas rejestracji',
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: AppThemePro.textPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: AppThemePro.textPrimary,
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
        elevation: 8,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemePro.backgroundPrimary,
      body: AnimatedBuilder(
        animation: _backgroundShiftAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                transform: GradientRotation(
                  _backgroundShiftAnimation.value * 0.15,
                ),
                colors: [
                  AppThemePro.backgroundPrimary,
                  AppThemePro.primaryDark,
                  AppThemePro.backgroundSecondary,
                  AppThemePro.primaryMedium,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildProfessionalAppBar(),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16.0,
                        ),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 450,
                                ),
                                child: Container(
                                  decoration: AppThemePro.premiumCardDecoration
                                      .copyWith(
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.5,
                                            ),
                                            blurRadius: 40,
                                            offset: const Offset(0, 20),
                                            spreadRadius: 0,
                                          ),
                                          BoxShadow(
                                            color: AppThemePro.accentGold
                                                .withOpacity(0.15),
                                            blurRadius: 80,
                                            offset: const Offset(0, 10),
                                            spreadRadius: -8,
                                          ),
                                        ],
                                      ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(40.0),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildProfessionalHeader(),
                                          const SizedBox(height: 40),
                                          _buildEnhancedRegistrationForm(),
                                          const SizedBox(height: 32),
                                          _buildTermsAndConditions(),
                                          const SizedBox(height: 32),
                                          _buildPremiumRegisterButton(),
                                          const SizedBox(height: 24),
                                          _buildLoginLink(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfessionalAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppThemePro.surfaceInteractive,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppThemePro.borderPrimary, width: 1),
            ),
            child: IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppThemePro.textSecondary,
                size: 20,
              ),
              style: IconButton.styleFrom(padding: const EdgeInsets.all(12)),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppThemePro.backgroundTertiary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppThemePro.borderPrimary, width: 1),
            ),
            child: Text(
              'Rejestracja',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppThemePro.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 56), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildProfessionalHeader() {
    return Column(
      children: [
        const MetropolitanLogoWidget.splash(
          size: 130,
          color: AppThemePro.accentGold,
          animated: false,
        ),
        const SizedBox(height: 24),
        Text(
          'Utwórz konto',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: AppThemePro.backgroundTertiary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppThemePro.borderPrimary, width: 1),
          ),
          child: Text(
            'Dołącz do ekskluzywnej platformy inwestycyjnej',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppThemePro.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedRegistrationForm() {
    return Column(
      children: [
        // First Name and Last Name Row
        Row(
          children: [
            Expanded(
              child: _buildAnimatedFormField(
                0,
                controller: _firstNameController,
                label: 'Imię',
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Podaj imię';
                  }
                  if (value.length < 2) {
                    return 'Imię musi mieć co najmniej 2 znaki';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAnimatedFormField(
                1,
                controller: _lastNameController,
                label: 'Nazwisko',
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Podaj nazwisko';
                  }
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

        // Email Field
        _buildAnimatedFormField(
          2,
          controller: _emailController,
          label: 'Adres email',
          hint: 'twoj@email.com',
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Podaj adres email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Podaj prawidłowy adres email';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Password Field
        _buildAnimatedFormField(
          3,
          controller: _passwordController,
          label: 'Hasło',
          hint: 'Minimum 6 znaków',
          icon: Icons.lock_rounded,
          obscureText: !_isPasswordVisible,
          suffixIcon: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isPasswordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                key: ValueKey(_isPasswordVisible),
                color: AppThemePro.textSecondary,
                size: 24,
              ),
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Podaj hasło';
            }
            if (value.length < 6) {
              return 'Hasło musi mieć co najmniej 6 znaków';
            }
            if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
              return 'Hasło musi zawierać małą literę, wielką literę i cyfrę';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Confirm Password Field
        _buildAnimatedFormField(
          4,
          controller: _confirmPasswordController,
          label: 'Potwierdź hasło',
          hint: 'Powtórz hasło',
          icon: Icons.lock_rounded,
          obscureText: !_isConfirmPasswordVisible,
          suffixIcon: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isConfirmPasswordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                key: ValueKey(_isConfirmPasswordVisible),
                color: AppThemePro.textSecondary,
                size: 24,
              ),
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Potwierdź hasło';
            }
            if (value != _passwordController.text) {
              return 'Hasła nie są identyczne';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAnimatedFormField(
    int index, {
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
    return AnimatedBuilder(
      animation: _fieldAnimations[index],
      builder: (context, child) {
        return FadeTransition(
          opacity: _fieldAnimations[index],
          child: SlideTransition(
            position: _fieldSlideAnimations[index],
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppThemePro.borderPrimary, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppThemePro.accentGold.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                textCapitalization:
                    textCapitalization ?? TextCapitalization.none,
                obscureText: obscureText,
                style: TextStyle(
                  color: AppThemePro.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  prefixIcon: Icon(
                    icon,
                    color: AppThemePro.textSecondary,
                    size: 24,
                  ),
                  suffixIcon: suffixIcon,
                  filled: true,
                  fillColor: AppThemePro.surfaceInteractive,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppThemePro.accentGold,
                      width: 2,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: AppThemePro.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  hintStyle: TextStyle(
                    color: AppThemePro.textMuted,
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                ),
                validator: validator,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermsAndConditions() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppThemePro.backgroundTertiary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppThemePro.borderPrimary, width: 1),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.scale(
                    scale: 1.3,
                    child: Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      activeColor: AppThemePro.accentGold,
                      checkColor: AppThemePro.primaryDark,
                      side: BorderSide(
                        color: AppThemePro.borderSecondary,
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppThemePro.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: 'Regulamin',
                            style: TextStyle(
                              color: AppThemePro.accentGold,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: AppThemePro.accentGold,
                            ),
                          ),
                          const TextSpan(text: ' i '),
                          TextSpan(
                            text: 'Politykę Prywatności',
                            style: TextStyle(
                              color: AppThemePro.accentGold,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: AppThemePro.accentGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumRegisterButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return AnimatedBuilder(
          animation: _buttonScaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_buttonScaleAnimation.value * 0.05),
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isFormValid
                        ? [
                            AppThemePro.accentGold,
                            AppThemePro.accentGoldMuted,
                            AppThemePro.accentGoldDark,
                          ]
                        : [
                            AppThemePro.textDisabled,
                            AppThemePro.textMuted,
                            AppThemePro.textDisabled,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _isFormValid
                      ? [
                          BoxShadow(
                            color: AppThemePro.accentGold.withOpacity(0.5),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                          BoxShadow(
                            color: AppThemePro.accentGold.withOpacity(0.3),
                            blurRadius: 64,
                            offset: const Offset(0, 8),
                            spreadRadius: -12,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: (authProvider.isLoading || !_isFormValid)
                        ? null
                        : () {
                            _buttonController.forward().then((_) {
                              _buttonController.reverse();
                            });
                            _handleRegister();
                          },
                    onTapDown: (_) {
                      if (_isFormValid && !authProvider.isLoading) {
                        _buttonController.forward();
                      }
                    },
                    onTapUp: (_) {
                      _buttonController.reverse();
                    },
                    onTapCancel: () {
                      _buttonController.reverse();
                    },
                    child: Container(
                      alignment: Alignment.center,
                      child: authProvider.isLoading
                          ? SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                color: AppThemePro.primaryDark,
                                strokeWidth: 3,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: AppThemePro.primaryDark,
                                  size: 26,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'UTWÓRZ KONTO',
                                  style: TextStyle(
                                    fontSize: 17,
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

  Widget _buildLoginLink() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Masz już konto? ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppThemePro.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Zaloguj się',
              style: TextStyle(
                color: AppThemePro.accentGold,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
