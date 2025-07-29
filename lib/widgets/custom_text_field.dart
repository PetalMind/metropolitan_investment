import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final Function()? onTap;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final double borderRadius;
  final Color? fillColor;
  final TextCapitalization textCapitalization;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.borderRadius = 12.0,
    this.fillColor,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  bool _isFocused = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _colorAnimation =
        ColorTween(
          begin: AppTheme.borderSecondary,
          end: AppTheme.secondaryGold,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange(bool hasFocus) {
    setState(() {
      _isFocused = hasFocus;
    });

    if (hasFocus) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.label.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _isFocused
                          ? AppTheme.secondaryGold
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: [
                    if (_isFocused)
                      BoxShadow(
                        color: AppTheme.secondaryGold.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Focus(
                  onFocusChange: _onFocusChange,
                  child: TextFormField(
                    controller: widget.controller,
                    obscureText: widget.obscureText,
                    keyboardType: widget.keyboardType,
                    onChanged: widget.onChanged,
                    onTap: widget.onTap,
                    readOnly: widget.readOnly,
                    maxLines: widget.maxLines,
                    maxLength: widget.maxLength,
                    enabled: widget.enabled,
                    textCapitalization: widget.textCapitalization,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    validator: (value) {
                      final error = widget.validator?.call(value);
                      setState(() {
                        _hasError = error != null;
                      });
                      return error;
                    },
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 16,
                      ),
                      prefixIcon: widget.prefixIcon != null
                          ? Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 12,
                              ),
                              child: Icon(
                                widget.prefixIcon,
                                color: _isFocused
                                    ? AppTheme.secondaryGold
                                    : AppTheme.textTertiary,
                                size: 22,
                              ),
                            )
                          : null,
                      suffixIcon: widget.suffixIcon != null
                          ? Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: widget.suffixIcon,
                            )
                          : null,
                      filled: true,
                      fillColor:
                          widget.fillColor ??
                          (_isFocused
                              ? AppTheme.secondaryGold.withOpacity(0.02)
                              : AppTheme.surfaceInteractive),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          widget.borderRadius,
                        ),
                        borderSide: BorderSide(
                          color: AppTheme.borderSecondary,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          widget.borderRadius,
                        ),
                        borderSide: BorderSide(
                          color: _hasError
                              ? AppTheme.errorColor.withOpacity(0.5)
                              : AppTheme.borderSecondary,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          widget.borderRadius,
                        ),
                        borderSide: BorderSide(
                          color: _hasError
                              ? AppTheme.errorColor
                              : _colorAnimation.value ?? AppTheme.secondaryGold,
                          width: 2.0,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          widget.borderRadius,
                        ),
                        borderSide: const BorderSide(
                          color: AppTheme.errorColor,
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          widget.borderRadius,
                        ),
                        borderSide: const BorderSide(
                          color: AppTheme.errorColor,
                          width: 2.0,
                        ),
                      ),
                      errorStyle: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      counterStyle: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AnimatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const AnimatedTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey[400],
      end: AppTheme.primaryColor,
    ).animate(_controller);

    widget.controller.addListener(_textListener);
  }

  void _textListener() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_textListener);
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange(bool hasFocus) {
    setState(() {
      _isFocused = hasFocus;
    });

    if (hasFocus || _hasText) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Focus(
            onFocusChange: _onFocusChange,
            child: Stack(
              children: [
                TextFormField(
                  controller: widget.controller,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  validator: widget.validator,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: widget.icon != null
                        ? Icon(
                            widget.icon,
                            color: _colorAnimation.value,
                            size: 22,
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _colorAnimation.value ?? AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: _isFocused
                        ? AppTheme.primaryColor.withOpacity(0.02)
                        : Colors.grey[50],
                  ),
                ),
                Positioned(
                  left: widget.icon != null ? 48 : 16,
                  top: _isFocused || _hasText ? 8 : 20,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: _isFocused || _hasText ? 12 : 16,
                      color: _colorAnimation.value ?? Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                    child: Text(widget.label),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
