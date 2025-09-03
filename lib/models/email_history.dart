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
  final String plainTextContent;
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
    required this.plainTextContent,
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
    
    // Check if this is a Firebase Functions record (has 'operation' and 'results' fields)
    if (data.containsKey('operation') && data.containsKey('results')) {
      return _fromFirebaseFunctionsRecord(doc.id, data);
    }

    // Standard Dart app record
    return EmailHistory(
      id: doc.id,
      senderEmail: data['senderEmail'] ?? '',
      senderName: data['senderName'] ?? '',
      recipients: (data['recipients'] as List<dynamic>?)
          ?.map((r) => EmailRecipient.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      subject: data['subject'] ?? '',
      plainTextContent: data['plainTextContent'] ?? '',
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

  /// Creates EmailHistory from Firebase Functions record format
  static EmailHistory _fromFirebaseFunctionsRecord(
    String id,
    Map<String, dynamic> data,
  ) {
    final results = data['results'] as List<dynamic>? ?? [];
    final recipients = <EmailRecipient>[];

    // Convert Firebase Functions results to EmailRecipient objects
    for (final result in results) {
      final resultData = result as Map<String, dynamic>;

      // Generate clientId for recipients
      String clientId;
      final email = resultData['recipientEmail'] ?? '';

      if (resultData['recipientType'] == 'additional') {
        // For additional emails, use a consistent hash-based ID
        clientId = 'additional_${email.hashCode.abs()}';
      } else {
        // For investor recipients, try to use a more meaningful ID
        // In the future, this could be enhanced to do actual client lookup
        clientId = 'fb_investor_${email.hashCode.abs()}';
      }

      recipients.add(
        EmailRecipient(
          clientId: clientId,
          clientName: resultData['recipientName'] ?? '',
          emailAddress: email,
          isCustomEmail: resultData['recipientType'] == 'additional',
          deliveryStatus: (resultData['success'] == true)
              ? DeliveryStatus.delivered
              : DeliveryStatus.failed,
          deliveryError: resultData['error'],
          deliveredAt: (resultData['success'] == true)
              ? (data['sentAt'] as Timestamp?)?.toDate()
              : null,
          messageId: resultData['messageId'],
        ),
      );
    }

    // Determine overall status
    final successful = data['successful'] as int? ?? 0;
    final failed = data['failed'] as int? ?? 0;
    final total = successful + failed;

    EmailStatus status;
    if (successful == 0) {
      status = EmailStatus.failed;
    } else if (failed == 0) {
      status = EmailStatus.sent;
    } else {
      status = EmailStatus.partiallyFailed;
    }

    return EmailHistory(
      id: id,
      senderEmail: data['senderEmail'] ?? '',
      senderName: data['senderName'] ?? '',
      recipients: recipients,
      subject: data['subject'] ?? '',
      plainTextContent: '', // Firebase Functions don't save plain text
      includeInvestmentDetails: data['includeInvestmentDetails'] ?? false,
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: status,
      messageId: null, // Firebase Functions don't save a single messageId
      errorMessage: failed > 0
          ? 'Niektóre emaile nie zostały dostarczone'
          : null,
      executionTimeMs: data['executionTimeMs'] ?? 0,
      metadata: {
        'source': 'firebase_functions',
        'operation': data['operation'],
        'totalRecipients': total,
        'successfulDeliveries': successful,
        'failedDeliveries': failed,
        'investorCount': data['investorCount'] ?? 0,
        'additionalEmailCount': data['additionalEmailCount'] ?? 0,
      },
    );
  }

  /// Konwertuje EmailHistory do Map dla Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'senderEmail': senderEmail,
      'senderName': senderName,
      'recipients': recipients.map((r) => r.toJson()).toList(),
      'subject': subject,
      'plainTextContent': plainTextContent,
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
    String? plainTextContent,
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
      plainTextContent: plainTextContent ?? this.plainTextContent,
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