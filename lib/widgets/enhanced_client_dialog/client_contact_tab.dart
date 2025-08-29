import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme_professional.dart';
import '../../models/client.dart';
import 'client_overview_tab.dart'; // For ClientFormData

/// 🎨 SEKCJA KONTAKT - Tab 2
///
/// Zawiera:
/// - Email z walidacją i podglądem
/// - Telefon z formatowaniem i weryfikacją
/// - Adres z geocoding (opcjonalnie)
/// - Dodatkowe pola kontaktowe
/// - Real-time validation
/// - Auto-format phone numbers
class ClientContactTab extends StatefulWidget {
  final ClientFormData formData;
  final VoidCallback onDataChanged;

  const ClientContactTab({
    super.key,
    required this.formData,
    required this.onDataChanged,
  });

  @override
  State<ClientContactTab> createState() => _ClientContactTabState();
}

class _ClientContactTabState extends State<ClientContactTab>
    with AutomaticKeepAliveClientMixin {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Focus nodes for better UX
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();

  // Validation states
  bool _isEmailValid = true;
  bool _isPhoneValid = true;
  String? _emailError;
  String? _phoneError;

  // 🎯 CONTACT PREFERENCES STATE
  ContactPreference _selectedContactMethod = ContactPreference.email;
  CommunicationLanguage _selectedLanguage = CommunicationLanguage.polish;
  bool _isUpdatingPreferences = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupValidation();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _emailController.text = widget.formData.email;
    _phoneController.text = widget.formData.phone;
    _addressController.text = widget.formData.address;

    // 🎯 INITIALIZE CONTACT PREFERENCES
    _selectedContactMethod = widget.formData.contactPreferences.primary;
    _selectedLanguage = widget.formData.contactPreferences.language;

    // Listen to changes
    _emailController.addListener(_onEmailChanged);
    _phoneController.addListener(_onPhoneChanged);
    _addressController.addListener(_onAddressChanged);
  }

  void _setupValidation() {
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _validateEmail();
      }
    });

    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus) {
        _validatePhone();
      }
    });
  }

  void _onEmailChanged() {
    widget.formData.email = _emailController.text;
    widget.onDataChanged();

    // Real-time validation for email
    if (_emailController.text.isNotEmpty) {
      _validateEmail();
    } else {
      setState(() {
        _isEmailValid = true;
        _emailError = null;
      });
    }
  }

  void _onPhoneChanged() {
    // Auto-format phone number
    final text = _phoneController.text;
    final formatted = _formatPhoneNumber(text);

    if (formatted != text) {
      final selection = _phoneController.selection;
      _phoneController.text = formatted;
      _phoneController.selection = TextSelection.collapsed(
        offset: selection.baseOffset + (formatted.length - text.length),
      );
    }

    widget.formData.phone = _phoneController.text;
    widget.onDataChanged();

    // Real-time validation for phone
    if (_phoneController.text.isNotEmpty) {
      _validatePhone();
    } else {
      setState(() {
        _isPhoneValid = true;
        _phoneError = null;
      });
    }
  }

  void _onAddressChanged() {
    widget.formData.address = _addressController.text;
    widget.onDataChanged();
  }

  String _formatPhoneNumber(String input) {
    // Remove all non-digits
    String digits = input.replaceAll(RegExp(r'\D'), '');

    // Limit to 11 digits (Polish format: +48 XXX XXX XXX)
    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }

    // Format Polish phone numbers
    if (digits.length >= 9) {
      if (digits.startsWith('48') && digits.length == 11) {
        // International format: +48 XXX XXX XXX
        return '+48 ${digits.substring(2, 5)} ${digits.substring(5, 8)} ${digits.substring(8)}';
      } else if (digits.length == 9) {
        // National format: XXX XXX XXX
        return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
      }
    }

    return digits;
  }

  void _validateEmail() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _isEmailValid = true;
        _emailError = null;
      });
      return;
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    final isValid = emailRegex.hasMatch(email);

    setState(() {
      _isEmailValid = isValid;
      _emailError = isValid ? null : 'Nieprawidłowy format adresu email';
    });
  }

  void _validatePhone() {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() {
        _isPhoneValid = true;
        _phoneError = null;
      });
      return;
    }

    // Check if phone number has valid format
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    bool isValid = false;

    if (digits.length == 9) {
      // Polish national format
      isValid = true;
    } else if (digits.length == 11 && digits.startsWith('48')) {
      // Polish international format
      isValid = true;
    }

    setState(() {
      _isPhoneValid = isValid;
      _phoneError = isValid ? null : 'Nieprawidłowy format numeru telefonu';
    });
  }

  String? _validateEmailField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email nie jest wymagany
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Nieprawidłowy format adresu email';
    }

    return null;
  }

  String? _validatePhoneField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Telefon nie jest wymagany
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 9) {
      return null; // Polish national format
    } else if (digits.length == 11 && digits.startsWith('48')) {
      return null; // Polish international format
    }

    return 'Nieprawidłowy format numeru telefonu';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email section
          _buildEmailSection(),
          const SizedBox(height: 24),

          // Phone section
          _buildPhoneSection(),
          const SizedBox(height: 24),

          // Address section
          _buildAddressSection(),
          const SizedBox(height: 24),

          // Contact preferences
          _buildContactPreferencesSection(),
        ],
      ),
    );
  }

  Widget _buildEmailSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: AppThemePro.elevatedSurfaceDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'Adres email',
                    Icons.email_rounded,
                    'Podstawowy adres do komunikacji',
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Adres email',
                      hintText: 'nazwa@przykład.pl',
                      prefixIcon: const Icon(Icons.email_outlined),
                      suffixIcon: _buildEmailValidationIcon(),
                      helperText:
                          'Opcjonalny - używany do komunikacji i raportów',
                      errorText: _emailError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppThemePro.borderPrimary,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _isEmailValid
                              ? AppThemePro.borderPrimary
                              : AppThemePro.statusError,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _isEmailValid
                              ? AppThemePro.accentGold
                              : AppThemePro.statusError,
                          width: 2,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: _validateEmailField,
                  ),

                  if (_emailController.text.isNotEmpty && _isEmailValid) ...[
                    const SizedBox(height: 12),
                    _buildEmailPreview(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhoneSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: AppThemePro.elevatedSurfaceDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'Numer telefonu',
                    Icons.phone_rounded,
                    'Kontakt telefoniczny z formatowaniem PL',
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Numer telefonu',
                      hintText: '123 456 789 lub +48 123 456 789',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      suffixIcon: _buildPhoneValidationIcon(),
                      helperText: 'Automatyczne formatowanie numeru polskiego',
                      errorText: _phoneError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppThemePro.borderPrimary,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _isPhoneValid
                              ? AppThemePro.borderPrimary
                              : AppThemePro.statusError,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _isPhoneValid
                              ? AppThemePro.accentGold
                              : AppThemePro.statusError,
                          width: 2,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: _validatePhoneField,
                  ),

                  if (_phoneController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildPhoneActions(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: AppThemePro.elevatedSurfaceDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'Adres zamieszkania',
                    Icons.location_on_rounded,
                    'Pełny adres do korespondencji',
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _addressController,
                    focusNode: _addressFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Adres',
                      hintText: 'ul. Przykładowa 123, 00-000 Warszawa',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      helperText: 'Pełny adres z kodem pocztowym i miastem',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppThemePro.borderPrimary,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppThemePro.borderPrimary,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppThemePro.accentGold,
                          width: 2,
                        ),
                      ),
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactPreferencesSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: AppThemePro.elevatedSurfaceDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'Preferencje kontaktu',
                    Icons.settings_phone_rounded,
                    'Ustawienia komunikacji z klientem',
                  ),
                  const SizedBox(height: 20),

                  // Contact method preferences
                  _buildContactMethodSelector(),

                  const SizedBox(height: 16),

                  // Communication language
                  _buildLanguageSelector(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmailValidationIcon() {
    if (_emailController.text.isEmpty) return const SizedBox.shrink();

    return Icon(
      _isEmailValid ? Icons.check_circle : Icons.error,
      color: _isEmailValid
          ? AppThemePro.statusSuccess
          : AppThemePro.statusError,
    );
  }

  Widget _buildPhoneValidationIcon() {
    if (_phoneController.text.isEmpty) return const SizedBox.shrink();

    return Icon(
      _isPhoneValid ? Icons.check_circle : Icons.error,
      color: _isPhoneValid
          ? AppThemePro.statusSuccess
          : AppThemePro.statusError,
    );
  }

  Widget _buildEmailPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemePro.statusSuccess.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppThemePro.statusSuccess.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.mark_email_read_rounded,
            color: AppThemePro.statusSuccess,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Email prawidłowy - gotowy do wysyłki raportów',
            style: TextStyle(
              fontSize: 12,
              color: AppThemePro.statusSuccess,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneActions() {
    return Row(
      children: [
        if (_isPhoneValid) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppThemePro.statusSuccess.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppThemePro.statusSuccess.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.phone_enabled_rounded,
                    color: AppThemePro.statusSuccess,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Numer prawidłowy',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppThemePro.statusSuccess,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _makePhoneCall(),
            icon: const Icon(Icons.phone),
            style: IconButton.styleFrom(
              backgroundColor: AppThemePro.accentGold.withOpacity(0.1),
              foregroundColor: AppThemePro.accentGold,
            ),
            tooltip: 'Zadzwoń',
          ),
        ],
      ],
    );
  }

  Widget _buildContactMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Preferowana metoda kontaktu',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppThemePro.textPrimary,
              ),
            ),
            if (_isUpdatingPreferences) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppThemePro.accentGold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ContactPreference.values
              .where((method) => method != ContactPreference.none)
              .map((method) {
                final isSelected = _selectedContactMethod == method;
                return _buildContactMethodChip(method, isSelected);
              })
              .toList(),
        ),
      ],
    );
  }

  Widget _buildContactMethodChip(ContactPreference method, bool isSelected) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getContactMethodIcon(method), size: 16),
          const SizedBox(width: 6),
          Text(_getContactMethodDisplayName(method)),
        ],
      ),
      selected: isSelected,
      onSelected: _isUpdatingPreferences
          ? null
          : (selected) => _updateContactMethod(method),
      selectedColor: AppThemePro.accentGold.withOpacity(0.2),
      checkmarkColor: AppThemePro.accentGold,
      backgroundColor: AppThemePro.surfaceCard,
      side: BorderSide(
        color: isSelected
            ? AppThemePro.accentGold
            : AppThemePro.borderPrimary.withOpacity(0.3),
        width: 1,
      ),
      elevation: isSelected ? 2 : 0,
      pressElevation: 4,
    );
  }

  Widget _buildLanguageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Język komunikacji',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppThemePro.textPrimary,
              ),
            ),
            if (_isUpdatingPreferences) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppThemePro.accentGold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CommunicationLanguage.values.map((language) {
            final isSelected = _selectedLanguage == language;
            return _buildLanguageChip(language, isSelected);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLanguageChip(CommunicationLanguage language, bool isSelected) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getLanguageIcon(language), size: 16),
          const SizedBox(width: 6),
          Text(_getLanguageDisplayName(language)),
        ],
      ),
      selected: isSelected,
      onSelected: _isUpdatingPreferences 
          ? null 
          : (selected) => _updateLanguage(language),
      selectedColor: AppThemePro.accentGold.withOpacity(0.2),
      checkmarkColor: AppThemePro.accentGold,
      backgroundColor: AppThemePro.surfaceCard,
      side: BorderSide(
        color: isSelected 
            ? AppThemePro.accentGold 
            : AppThemePro.borderPrimary.withOpacity(0.3),
        width: 1,
      ),
      elevation: isSelected ? 2 : 0,
      pressElevation: 4,
    );
  }
  Widget _buildPreferenceChip(String label, IconData icon, bool isSelected) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
      selected: isSelected,
      onSelected: (selected) {
        // TODO: Implement preference selection
        HapticFeedback.lightImpact();
      },
      selectedColor: AppThemePro.accentGold.withOpacity(0.2),
      checkmarkColor: AppThemePro.accentGold,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppThemePro.accentGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppThemePro.accentGold.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: AppThemePro.accentGold, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppThemePro.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppThemePro.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _makePhoneCall() {
    // TODO: Implement phone call functionality
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📞 Dzwonię na numer ${_phoneController.text}'),
        backgroundColor: AppThemePro.accentGold,
      ),
    );
  }

  // 🎯 CONTACT PREFERENCES METHODS

  void _updateContactMethod(ContactPreference method) async {
    if (_selectedContactMethod == method) return;

    setState(() {
      _isUpdatingPreferences = true;
      _selectedContactMethod = method;
    });

    try {
      // Update form data
      widget.formData.contactPreferences = ContactPreferences(
        primary: method,
        secondary: widget.formData.contactPreferences.secondary,
        language: _selectedLanguage,
        allowMarketing: widget.formData.contactPreferences.allowMarketing,
        allowNotifications:
            widget.formData.contactPreferences.allowNotifications,
        availableHours: widget.formData.contactPreferences.availableHours,
        notes: widget.formData.contactPreferences.notes,
      );

      widget.onDataChanged();

      // 🔥 UPDATE FIREBASE (if client exists)
      if (widget.formData.additionalInfo.containsKey('clientId')) {
        final clientId = widget.formData.additionalInfo['clientId'] as String;
        await _updatePreferencesInFirebase(clientId);
      }

      HapticFeedback.lightImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Zaktualizowano preferencje kontaktu: ${_getContactMethodDisplayName(method)}',
            ),
            backgroundColor: AppThemePro.statusSuccess,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ [ContactTab] Błąd podczas aktualizacji preferencji: $e');

      // Revert state on error
      setState(() {
        _selectedContactMethod = widget.formData.contactPreferences.primary;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Błąd podczas aktualizacji preferencji: $e'),
            backgroundColor: AppThemePro.statusError,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPreferences = false;
        });
      }
    }
  }

  void _updateLanguage(CommunicationLanguage language) async {
    if (_selectedLanguage == language) return;

    setState(() {
      _isUpdatingPreferences = true;
      _selectedLanguage = language;
    });

    try {
      // Update form data
      widget.formData.contactPreferences = ContactPreferences(
        primary: _selectedContactMethod,
        secondary: widget.formData.contactPreferences.secondary,
        language: language,
        allowMarketing: widget.formData.contactPreferences.allowMarketing,
        allowNotifications:
            widget.formData.contactPreferences.allowNotifications,
        availableHours: widget.formData.contactPreferences.availableHours,
        notes: widget.formData.contactPreferences.notes,
      );

      widget.onDataChanged();

      // 🔥 UPDATE FIREBASE (if client exists)
      if (widget.formData.additionalInfo.containsKey('clientId')) {
        final clientId = widget.formData.additionalInfo['clientId'] as String;
        await _updatePreferencesInFirebase(clientId);
      }

      HapticFeedback.lightImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Zaktualizowano język komunikacji: ${_getLanguageDisplayName(language)}',
            ),
            backgroundColor: AppThemePro.statusSuccess,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ [ContactTab] Błąd podczas aktualizacji języka: $e');

      // Revert state on error
      setState(() {
        _selectedLanguage = widget.formData.contactPreferences.language;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Błąd podczas aktualizacji języka: $e'),
            backgroundColor: AppThemePro.statusError,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPreferences = false;
        });
      }
    }
  }

  Future<void> _updatePreferencesInFirebase(String clientId) async {
    try {
      await FirebaseFirestore.instance
          .collection('clients')
          .doc(clientId)
          .update({
            'contactPreferences': widget.formData.contactPreferences
                .toFirestore(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print(
        '✅ [ContactTab] Zaktualizowano preferencje kontaktu w Firebase dla klienta: $clientId',
      );
    } catch (e) {
      print(
        '❌ [ContactTab] Błąd Firebase podczas aktualizacji preferencji: $e',
      );
      rethrow;
    }
  }

  String _getContactMethodDisplayName(ContactPreference method) {
    switch (method) {
      case ContactPreference.email:
        return 'Email';
      case ContactPreference.phone:
        return 'Telefon';
      case ContactPreference.sms:
        return 'SMS';
      case ContactPreference.postal:
        return 'Poczta tradycyjna';
      case ContactPreference.none:
        return 'Brak kontaktu';
    }
  }

  String _getLanguageDisplayName(CommunicationLanguage language) {
    switch (language) {
      case CommunicationLanguage.polish:
        return 'Polski';
      case CommunicationLanguage.english:
        return 'Angielski';
      case CommunicationLanguage.german:
        return 'Niemiecki';
      case CommunicationLanguage.french:
        return 'Francuski';
    }
  }

  IconData _getContactMethodIcon(ContactPreference method) {
    switch (method) {
      case ContactPreference.email:
        return Icons.email_rounded;
      case ContactPreference.phone:
        return Icons.phone_rounded;
      case ContactPreference.sms:
        return Icons.sms_rounded;
      case ContactPreference.postal:
        return Icons.local_post_office_rounded;
      case ContactPreference.none:
        return Icons.do_not_disturb_rounded;
    }
  }

  IconData _getLanguageIcon(CommunicationLanguage language) {
    switch (language) {
      case CommunicationLanguage.polish:
        return Icons.language_rounded;
      case CommunicationLanguage.english:
        return Icons.translate_rounded;
      case CommunicationLanguage.german:
        return Icons.translate_rounded;
      case CommunicationLanguage.french:
        return Icons.translate_rounded;
    }
  }
}
