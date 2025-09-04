import 'package:email_validator/email_validator.dart';

/// 📧 Professional email validation service
/// Enhanced with email_validator package for better validation
class EmailValidationService {
  // Disposable email domains (basic list - can be extended)
  static final Set<String> _disposableDomains = {
    '10minutemail.com',
    'guerrillamail.com',
    'mailinator.com',
    'tempmail.org',
    'throwaway.email',
    'trashmail.com',
    'yopmail.com',
    '33mail.com',
    'dispostable.com',
    'fakemailgenerator.com',
  };

  // Common business email domains
  static final Set<String> _businessDomains = {
    'gmail.com',
    'outlook.com',
    'hotmail.com',
    'yahoo.com',
    'icloud.com',
    'protonmail.com',
    'aol.com',
    'live.com',
    'msn.com',
  };

  /// Validate email address with comprehensive checks
  static EmailValidationResult validateEmail(String email) {
    final trimmedEmail = email.trim().toLowerCase();

    // Basic checks
    if (trimmedEmail.isEmpty) {
      return EmailValidationResult(
        isValid: false,
        error: 'Email address cannot be empty',
        severity: ValidationSeverity.error,
      );
    }

    if (trimmedEmail.length > 254) {
      return EmailValidationResult(
        isValid: false,
        error: 'Email address is too long (max 254 characters)',
        severity: ValidationSeverity.error,
      );
    }

    // Use professional email validator library
    if (!EmailValidator.validate(trimmedEmail)) {
      return EmailValidationResult(
        isValid: false,
        error: 'Invalid email format',
        severity: ValidationSeverity.error,
      );
    }

    // Split email into local and domain parts for additional checks
    final parts = trimmedEmail.split('@');
    if (parts.length != 2) {
      return EmailValidationResult(
        isValid: false,
        error: 'Email must contain exactly one @ symbol',
        severity: ValidationSeverity.error,
      );
    }

    final localPart = parts[0];
    final domainPart = parts[1];

    // Additional custom validations
    final localValidation = _validateLocalPart(localPart);
    if (!localValidation.isValid) {
      return localValidation;
    }

    final domainValidation = _validateDomainPart(domainPart);
    if (!domainValidation.isValid) {
      return domainValidation;
    }

    // Check for disposable email
    if (_disposableDomains.contains(domainPart)) {
      return EmailValidationResult(
        isValid: true,
        warning: 'This appears to be a disposable email address',
        severity: ValidationSeverity.warning,
      );
    }

    // Success
    return EmailValidationResult(
      isValid: true,
      severity: ValidationSeverity.none,
      emailType: _getEmailType(domainPart),
    );
  }

  /// Validate local part of email (before @)
  static EmailValidationResult _validateLocalPart(String localPart) {
    if (localPart.isEmpty) {
      return EmailValidationResult(
        isValid: false,
        error: 'Email local part cannot be empty',
        severity: ValidationSeverity.error,
      );
    }

    if (localPart.length > 64) {
      return EmailValidationResult(
        isValid: false,
        error: 'Email local part is too long (max 64 characters)',
        severity: ValidationSeverity.error,
      );
    }

    // Check for invalid characters in local part
    if (localPart.startsWith('.') || localPart.endsWith('.')) {
      return EmailValidationResult(
        isValid: false,
        error: 'Email local part cannot start or end with a dot',
        severity: ValidationSeverity.error,
      );
    }

    if (localPart.contains('..')) {
      return EmailValidationResult(
        isValid: false,
        error: 'Email local part cannot contain consecutive dots',
        severity: ValidationSeverity.error,
      );
    }

    return EmailValidationResult(
      isValid: true,
      severity: ValidationSeverity.none,
    );
  }

  /// Validate domain part of email (after @)
  static EmailValidationResult _validateDomainPart(String domainPart) {
    if (domainPart.isEmpty) {
      return EmailValidationResult(
        isValid: false,
        error: 'Email domain cannot be empty',
        severity: ValidationSeverity.error,
      );
    }

    if (domainPart.length > 253) {
      return EmailValidationResult(
        isValid: false,
        error: 'Email domain is too long (max 253 characters)',
        severity: ValidationSeverity.error,
      );
    }

    // Check basic domain format
    if (domainPart.startsWith('.') || domainPart.endsWith('.')) {
      return EmailValidationResult(
        isValid: false,
        error: 'Email domain cannot start or end with a dot',
        severity: ValidationSeverity.error,
      );
    }

    if (domainPart.startsWith('-') || domainPart.endsWith('-')) {
      return EmailValidationResult(
        isValid: false,
        error: 'Email domain cannot start or end with a hyphen',
        severity: ValidationSeverity.error,
      );
    }

    if (!domainPart.contains('.')) {
      return EmailValidationResult(
        isValid: false,
        error: 'Email domain must contain at least one dot',
        severity: ValidationSeverity.error,
      );
    }

    // Validate domain parts
    final domainParts = domainPart.split('.');
    for (final part in domainParts) {
      if (part.isEmpty) {
        return EmailValidationResult(
          isValid: false,
          error: 'Email domain contains empty parts',
          severity: ValidationSeverity.error,
        );
      }

      if (part.length > 63) {
        return EmailValidationResult(
          isValid: false,
          error: 'Email domain part is too long (max 63 characters)',
          severity: ValidationSeverity.error,
        );
      }

      if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(part)) {
        return EmailValidationResult(
          isValid: false,
          error: 'Email domain contains invalid characters',
          severity: ValidationSeverity.error,
        );
      }
    }

    // Check TLD
    final tld = domainParts.last;
    if (tld.length < 2) {
      return EmailValidationResult(
        isValid: false,
        error: 'Email domain TLD is too short (min 2 characters)',
        severity: ValidationSeverity.error,
      );
    }

    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(tld)) {
      return EmailValidationResult(
        isValid: false,
        error: 'Email domain TLD can only contain letters',
        severity: ValidationSeverity.error,
      );
    }

    return EmailValidationResult(
      isValid: true,
      severity: ValidationSeverity.none,
    );
  }

  /// Determine email type based on domain
  static EmailType _getEmailType(String domain) {
    if (_businessDomains.contains(domain)) {
      return EmailType.personal;
    }

    // Common business indicators
    if (domain.contains('corp') ||
        domain.contains('company') ||
        domain.contains('business') ||
        domain.contains('enterprise') ||
        !_businessDomains.contains(domain)) {
      return EmailType.business;
    }

    return EmailType.unknown;
  }

  /// Validate multiple emails at once
  static List<EmailValidationResult> validateMultipleEmails(
    List<String> emails,
  ) {
    return emails.map((email) => validateEmail(email)).toList();
  }

  /// Check if email list contains duplicates
  static List<String> findDuplicateEmails(List<String> emails) {
    final seen = <String>{};
    final duplicates = <String>{};

    for (final email in emails) {
      final normalized = email.trim().toLowerCase();
      if (seen.contains(normalized)) {
        duplicates.add(normalized);
      } else {
        seen.add(normalized);
      }
    }

    return duplicates.toList();
  }

  /// Normalize email address
  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  /// Quick validation for UI (returns only true/false)
  static bool isValidEmail(String email) {
    return validateEmail(email).isValid;
  }

  /// Get validation message for UI display
  static String? getValidationMessage(String email) {
    final result = validateEmail(email);
    return result.error ?? result.warning;
  }
}

/// Email validation result with detailed information
class EmailValidationResult {
  final bool isValid;
  final String? error;
  final String? warning;
  final ValidationSeverity severity;
  final EmailType? emailType;

  const EmailValidationResult({
    required this.isValid,
    this.error,
    this.warning,
    required this.severity,
    this.emailType,
  });

  /// Get display message for UI
  String? get displayMessage => error ?? warning;

  /// Check if there are any issues (errors or warnings)
  bool get hasIssues => error != null || warning != null;
}

/// Validation severity levels
enum ValidationSeverity { none, warning, error }

/// Email type classification
enum EmailType { personal, business, disposable, unknown }
