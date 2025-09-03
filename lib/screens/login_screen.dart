import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme_professional.dart';
import '../widgets/metropolitan_logo_widget.dart';
import '../config/app_routes.dart';
import '../models_and_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Enhanced animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulsateController;
  late AnimationController _backgroundController;

  // Enhanced animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundShiftAnimation;

  // Enhanced micro-interaction controllers
  late AnimationController _emailFieldController;
  late AnimationController _passwordFieldController;
  late AnimationController _buttonHoverController;

  late Animation<double> _emailFieldFocusAnimation;
  late Animation<double> _passwordFieldFocusAnimation;
  late Animation<double> _buttonHoverAnimation;

  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSavedLoginData();
    _setupFormValidation();
  }

  void _initializeAnimations() {
    // Simplified animation setup to avoid curve issues
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulsateController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    // Micro-interaction controllers
    _emailFieldController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _passwordFieldController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _buttonHoverController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    // Create safe animations with values within [0,1]
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));

    _backgroundShiftAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _emailFieldFocusAnimation = _emailFieldController;

    _passwordFieldFocusAnimation = _passwordFieldController;

    _buttonHoverAnimation = _buttonHoverController;

    // Start basic animations only
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  void _setupFormValidation() {
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  void _validateForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final isValid =
        email.isNotEmpty &&
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email) &&
        password.isNotEmpty &&
        password.length >= 6;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  // Load saved login data if available
  Future<void> _loadSavedLoginData() async {
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

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _pulsateController.dispose();
    _backgroundController.dispose();
    _emailFieldController.dispose();
    _passwordFieldController.dispose();
    _buttonHoverController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (success && mounted) {
      // Success haptic feedback
      HapticFeedback.mediumImpact();
      
      // Play success sound
      await _playLoginSuccessSound();
      
      if (mounted) {
        context.go(AppRoutes.dashboard);
      }
    } else if (mounted) {
      // Error haptic feedback
      HapticFeedback.heavyImpact();
      _showErrorSnackBar(
        authProvider.error ?? 'Wystąpił błąd podczas logowania',
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

  Future<void> _playLoginSuccessSound() async {
    try {
      // Play login success sound using AudioService
      await AudioService.instance.playEmailSuccessSound();
      debugPrint('🔊 Login success sound played');
    } catch (e) {
      debugPrint('⚠️ Could not play login success sound: $e');
    }
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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                transform: GradientRotation(
                  _backgroundShiftAnimation.value * 0.1,
                ),
                colors: [
                  AppThemePro.backgroundPrimary,
                  AppThemePro.primaryDark,
                  AppThemePro.backgroundSecondary,
                ],
              ),
            ),
            child: SafeArea(
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
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Container(
                            decoration: AppThemePro.premiumCardDecoration
                                .copyWith(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 32,
                                      offset: const Offset(0, 16),
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: AppThemePro.accentGold.withOpacity(
                                        0.1,
                                      ),
                                      blurRadius: 64,
                                      offset: const Offset(0, 8),
                                      spreadRadius: -4,
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
                                    const SizedBox(height: 48),
                                    _buildEnhancedLoginForm(),
                                    const SizedBox(height: 32),
                                    _buildPremiumLoginButton(),
                                    const SizedBox(height: 24),
                                    _buildForgotPassword(),
                                    const SizedBox(height: 32),
                                    _buildStylishDivider(),
                                    const SizedBox(height: 32),
                                    _buildRegisterLink(),
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
          );
        },
      ),
    );
  }

  Widget _buildProfessionalHeader() {
    return Column(
      children: [
        const MetropolitanLogoWidget.splash(
          size: 280,
          color: AppThemePro.accentGold,
          animated: false,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildEnhancedLoginForm() {
    return Column(
      children: [
        // Email Field with Micro-interactions
        AnimatedBuilder(
          animation: _emailFieldFocusAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_emailFieldFocusAnimation.value * 0.02),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppThemePro.borderPrimary,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppThemePro.accentGold.withOpacity(
                        _emailFieldFocusAnimation.value * 0.2,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Focus(
                  onFocusChange: (hasFocus) {
                    if (hasFocus) {
                      _emailFieldController.forward();
                    } else {
                      _emailFieldController.reverse();
                    }
                  },
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      color: AppThemePro.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Adres email',
                      hintText: 'twoj@email.com',
                      prefixIcon: Icon(
                        Icons.email_rounded,
                        color: AppThemePro.textSecondary,
                        size: 24,
                      ),
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Podaj adres email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Podaj prawidłowy adres email';
                      }
                      return null;
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        // Password Field with Enhanced Security Visual
        AnimatedBuilder(
          animation: _passwordFieldFocusAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_passwordFieldFocusAnimation.value * 0.02),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppThemePro.borderPrimary,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppThemePro.accentGold.withOpacity(
                        _passwordFieldFocusAnimation.value * 0.2,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Focus(
                  onFocusChange: (hasFocus) {
                    if (hasFocus) {
                      _passwordFieldController.forward();
                    } else {
                      _passwordFieldController.reverse();
                    }
                  },
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: TextStyle(
                      color: AppThemePro.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Hasło',
                      hintText: 'Wprowadź swoje hasło',
                      prefixIcon: Icon(
                        Icons.lock_rounded,
                        color: AppThemePro.textSecondary,
                        size: 24,
                      ),
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Podaj hasło';
                      }
                      if (value.length < 6) {
                        return 'Hasło musi mieć co najmniej 6 znaków';
                      }
                      return null;
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        // Enhanced Remember Me Checkbox
        Row(
          children: [
            Transform.scale(
              scale: 1.2,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                activeColor: AppThemePro.accentGold,
                checkColor: AppThemePro.primaryDark,
                side: BorderSide(color: AppThemePro.borderSecondary, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Zapamiętaj mnie',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppThemePro.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPremiumLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return AnimatedBuilder(
          animation: _buttonHoverAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_buttonHoverAnimation.value * 0.02),
              child: Container(
                width: double.infinity,
                height: 56,
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
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isFormValid
                      ? [
                          BoxShadow(
                            color: AppThemePro.accentGold.withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: AppThemePro.accentGold.withOpacity(0.2),
                            blurRadius: 48,
                            offset: const Offset(0, 6),
                            spreadRadius: -8,
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
                    borderRadius: BorderRadius.circular(16),
                    onTap: (authProvider.isLoading || !_isFormValid)
                        ? null
                        : () {
                            _buttonHoverController.forward().then((_) {
                              _buttonHoverController.reverse();
                            });
                            _handleLogin();
                          },
                    onTapDown: (_) {
                      if (_isFormValid && !authProvider.isLoading) {
                        _buttonHoverController.forward();
                      }
                    },
                    onTapUp: (_) {
                      _buttonHoverController.reverse();
                    },
                    onTapCancel: () {
                      _buttonHoverController.reverse();
                    },
                    child: Container(
                      alignment: Alignment.center,
                      child: authProvider.isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
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
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'ZALOGUJ SIĘ',
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

  Widget _buildForgotPassword() {
    return TextButton(
      onPressed: () {
        HapticFeedback.selectionClick();
        _showForgotPasswordDialog();
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        'Zapomniałeś hasła?',
        style: TextStyle(
          color: AppThemePro.accentGoldMuted,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildStylishDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  AppThemePro.borderSecondary,
                  AppThemePro.accentGold.withOpacity(0.3),
                  AppThemePro.borderSecondary,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Nie masz konta? ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppThemePro.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            context.push(AppRoutes.register);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            'Zarejestruj się',
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

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: AppThemePro.scrimColor,
      builder: (context) => AlertDialog(
        backgroundColor: AppThemePro.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Resetowanie hasła',
          style: TextStyle(
            color: AppThemePro.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Podaj adres email powiązany z Twoim kontem. Wyślemy Ci link do resetowania hasła.',
              style: TextStyle(color: AppThemePro.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: AppThemePro.textPrimary),
              decoration: InputDecoration(
                labelText: 'Adres email',
                prefixIcon: Icon(
                  Icons.email_rounded,
                  color: AppThemePro.textSecondary,
                ),
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
                labelStyle: TextStyle(color: AppThemePro.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Anuluj',
              style: TextStyle(color: AppThemePro.textSecondary),
            ),
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemePro.accentGold,
                  foregroundColor: AppThemePro.primaryDark,
                ),
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                        if (emailController.text.trim().isEmpty) {
                          _showErrorSnackBar('Podaj adres email');
                          return;
                        }

                        final success = await authProvider.resetPassword(
                          emailController.text.trim(),
                        );

                        if (mounted) {
                          Navigator.of(context).pop();
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Link do resetowania hasła został wysłany',
                                  style: TextStyle(
                                    color: AppThemePro.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: AppThemePro.statusSuccess,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          } else {
                            _showErrorSnackBar(
                              authProvider.error ?? 'Wystąpił błąd',
                            );
                          }
                        }
                      },
                child: authProvider.isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppThemePro.primaryDark,
                        ),
                      )
                    : const Text('Wyślij'),
              );
            },
          ),
        ],
      ),
    );
  }
}
