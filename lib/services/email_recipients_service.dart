import '../models_and_services.dart';
import 'email_editor_service_v2.dart';

/// Compatibility wrapper exposing a recipients-focused API expected by the
/// dialog. Internally uses EmailEditorService (v2) which contains the real
/// logic for recipient management.
class EmailRecipientsService {
  final EmailEditorService _delegate = EmailEditorService();

  Map<String, bool> get recipientEnabled => _delegate.recipientEnabled;
  Map<String, String> get recipientEmails => _delegate.recipientEmails;
  List<String> get additionalEmails => _delegate.additionalEmails;

  /// Whether an additional email address is confirmed (placeholder: always true).
  final Map<String, bool> additionalEmailsConfirmed = {};

  void initializeRecipients(List<InvestorSummary> investors) {
    _delegate.initializeRecipients(investors);
    // Initialize all recipients as enabled and confirmed for additional emails
    for (final investor in investors) {
      final clientId = investor.client.id;
      if (investor.client.email.isNotEmpty) {
        _delegate.recipientEnabled[clientId] = true;
        _delegate.recipientEmails[clientId] = investor.client.email;
      }
    }
  }

  /// Gets the first available recipient ID for preview
  String? getFirstAvailableRecipient(List<InvestorSummary> investors) {
    for (final investor in investors) {
      final clientId = investor.client.id;
      if ((_delegate.recipientEnabled[clientId] ?? false) &&
          investor.client.email.isNotEmpty) {
        return clientId;
      }
    }
    return null;
  }

  /// Gets the count of enabled recipients
  int getEnabledRecipientsCount() {
    final enabledInvestors = _delegate.recipientEnabled.values
        .where((enabled) => enabled)
        .length;
    final confirmedAdditionalEmails = additionalEmailsConfirmed.values
        .where((confirmed) => confirmed)
        .length;
    return enabledInvestors + confirmedAdditionalEmails;
  }

  /// Toggles recipient enabled state
  void toggleRecipient(String clientId, bool enabled) {
    _delegate.recipientEnabled[clientId] = enabled;
  }

  /// Toggles additional email confirmation state
  void toggleAdditionalEmailConfirmation(String email, bool confirmed) {
    additionalEmailsConfirmed[email] = confirmed;
  }

  bool addAdditionalEmail(String email) {
    if (email.isEmpty || !email.contains('@')) {
      return false;
    }
    if (_delegate.additionalEmails.contains(email)) {
      return false;
    }
    _delegate.addAdditionalEmail(email);
    additionalEmailsConfirmed[email] = true;
    return true;
  }

  void removeAdditionalEmail(String email) {
    final idx = _delegate.additionalEmails.indexOf(email);
    if (idx >= 0) _delegate.removeAdditionalEmail(idx);
    additionalEmailsConfirmed.remove(email);
  }

  bool hasValidEmails() => _delegate.hasValidRecipients([]);
}
