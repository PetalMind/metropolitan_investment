import 'package:cloud_firestore/cloud_firestore.dart';

/// Model historii wysłanych emaili
/// 
/// Przechowuje kompletną informację o każdym wysłanym mailu,
/// umożliwiając śledzenie komunikacji z klientami i audyt.
class EmailHistory {
  final String id;
  final String senderEmail;
  final String senderName;
  final List<EmailRecipient> recipients;
  final String subject;
  final String htmlContent;
  final String plainTextContent;
  final EmailType emailType;
  final EmailTemplate template;
  final bool includeInvestmentDetails;
  final DateTime sentAt;
  final EmailStatus status;
  final String? messageId;
  final String? errorMessage;
  final int executionTimeMs;
  final Map<String, dynamic>? metadata;

  const EmailHistory({
    required this.id,
    required this.senderEmail,
    required this.senderName,
    required this.recipients,
    required this.subject,
    required this.htmlContent,
    required this.plainTextContent,
    required this.emailType,
    required this.template,
    required this.includeInvestmentDetails,
    required this.sentAt,
    required this.status,
    this.messageId,
    this.errorMessage,
    required this.executionTimeMs,
    this.metadata,
  });

  /// Tworzy EmailHistory z danych Firestore
  factory EmailHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return EmailHistory(
      id: doc.id,
      senderEmail: data['senderEmail'] ?? '',
      senderName: data['senderName'] ?? '',
      recipients: (data['recipients'] as List<dynamic>?)
          ?.map((r) => EmailRecipient.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      subject: data['subject'] ?? '',
      htmlContent: data['htmlContent'] ?? '',
      plainTextContent: data['plainTextContent'] ?? '',
      emailType: EmailType.values.firstWhere(
        (e) => e.name == data['emailType'],
        orElse: () => EmailType.individual,
      ),
      template: EmailTemplate.values.firstWhere(
        (e) => e.name == data['template'],
        orElse: () => EmailTemplate.custom,
      ),
      includeInvestmentDetails: data['includeInvestmentDetails'] ?? false,
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: EmailStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => EmailStatus.failed,
      ),
      messageId: data['messageId'],
      errorMessage: data['errorMessage'],
      executionTimeMs: data['executionTimeMs'] ?? 0,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Konwertuje EmailHistory do Map dla Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'senderEmail': senderEmail,
      'senderName': senderName,
      'recipients': recipients.map((r) => r.toJson()).toList(),
      'subject': subject,
      'htmlContent': htmlContent,
      'plainTextContent': plainTextContent,
      'emailType': emailType.name,
      'template': template.name,
      'includeInvestmentDetails': includeInvestmentDetails,
      'sentAt': Timestamp.fromDate(sentAt),
      'status': status.name,
      if (messageId != null) 'messageId': messageId,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'executionTimeMs': executionTimeMs,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Tworzy kopię z nowymi wartościami
  EmailHistory copyWith({
    String? id,
    String? senderEmail,
    String? senderName,
    List<EmailRecipient>? recipients,
    String? subject,
    String? htmlContent,
    String? plainTextContent,
    EmailType? emailType,
    EmailTemplate? template,
    bool? includeInvestmentDetails,
    DateTime? sentAt,
    EmailStatus? status,
    String? messageId,
    String? errorMessage,
    int? executionTimeMs,
    Map<String, dynamic>? metadata,
  }) {
    return EmailHistory(
      id: id ?? this.id,
      senderEmail: senderEmail ?? this.senderEmail,
      senderName: senderName ?? this.senderName,
      recipients: recipients ?? this.recipients,
      subject: subject ?? this.subject,
      htmlContent: htmlContent ?? this.htmlContent,
      plainTextContent: plainTextContent ?? this.plainTextContent,
      emailType: emailType ?? this.emailType,
      template: template ?? this.template,
      includeInvestmentDetails: includeInvestmentDetails ?? this.includeInvestmentDetails,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      messageId: messageId ?? this.messageId,
      errorMessage: errorMessage ?? this.errorMessage,
      executionTimeMs: executionTimeMs ?? this.executionTimeMs,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Formatowane podsumowanie dla UI
  String get formattedSummary {
    final recipientCount = recipients.length;
    final successCount = recipients.where((r) => r.deliveryStatus == DeliveryStatus.delivered).length;
    
    return '''
Temat: $subject
Odbiorcy: $successCount/$recipientCount pomyślnie
Wysłano: ${sentAt.toLocal().toString().split('.')[0]}
Nadawca: $senderName <$senderEmail>
Typ: ${emailType.displayName}
Szablon: ${template.displayName}
Status: ${status.displayName}
${errorMessage != null ? 'Błąd: $errorMessage' : ''}
Czas wykonania: ${executionTimeMs}ms
'''.trim();
  }
}

/// Model odbiorcy emaila
class EmailRecipient {
  final String clientId;
  final String clientName;
  final String emailAddress;
  final bool isCustomEmail;
  final DeliveryStatus deliveryStatus;
  final String? deliveryError;
  final DateTime? deliveredAt;
  final String? messageId;

  const EmailRecipient({
    required this.clientId,
    required this.clientName,
    required this.emailAddress,
    required this.isCustomEmail,
    required this.deliveryStatus,
    this.deliveryError,
    this.deliveredAt,
    this.messageId,
  });

  factory EmailRecipient.fromJson(Map<String, dynamic> json) {
    return EmailRecipient(
      clientId: json['clientId'] ?? '',
      clientName: json['clientName'] ?? '',
      emailAddress: json['emailAddress'] ?? '',
      isCustomEmail: json['isCustomEmail'] ?? false,
      deliveryStatus: DeliveryStatus.values.firstWhere(
        (e) => e.name == json['deliveryStatus'],
        orElse: () => DeliveryStatus.pending,
      ),
      deliveryError: json['deliveryError'],
      deliveredAt: json['deliveredAt'] != null 
          ? (json['deliveredAt'] as Timestamp).toDate()
          : null,
      messageId: json['messageId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'emailAddress': emailAddress,
      'isCustomEmail': isCustomEmail,
      'deliveryStatus': deliveryStatus.name,
      if (deliveryError != null) 'deliveryError': deliveryError,
      if (deliveredAt != null) 'deliveredAt': Timestamp.fromDate(deliveredAt!),
      if (messageId != null) 'messageId': messageId,
    };
  }

  EmailRecipient copyWith({
    String? clientId,
    String? clientName,
    String? emailAddress,
    bool? isCustomEmail,
    DeliveryStatus? deliveryStatus,
    String? deliveryError,
    DateTime? deliveredAt,
    String? messageId,
  }) {
    return EmailRecipient(
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      emailAddress: emailAddress ?? this.emailAddress,
      isCustomEmail: isCustomEmail ?? this.isCustomEmail,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      deliveryError: deliveryError ?? this.deliveryError,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      messageId: messageId ?? this.messageId,
    );
  }
}

/// Typ emaila
enum EmailType {
  individual('Pojedynczy'),
  batch('Grupowy'),
  newsletter('Newsletter'),
  notification('Powiadomienie');

  const EmailType(this.displayName);
  final String displayName;
}

/// Szablon emaila
enum EmailTemplate {
  custom('Niestandardowy'),
  summary('Podsumowanie'),
  detailed('Szczegółowy'),
  reminder('Przypomnienie'),
  notification('Powiadomienie');

  const EmailTemplate(this.displayName);
  final String displayName;
}

/// Status emaila
enum EmailStatus {
  pending('Oczekujący'),
  sending('Wysyłanie'),
  sent('Wysłany'),
  failed('Nieudany'),
  partiallyFailed('Częściowo nieudany');

  const EmailStatus(this.displayName);
  final String displayName;
}

/// Status doręczenia dla odbiorcy
enum DeliveryStatus {
  pending('Oczekujący'),
  delivered('Doręczony'),
  failed('Nieudany'),
  bounced('Zwrócony'),
  spam('Spam');

  const DeliveryStatus(this.displayName);
  final String displayName;
}