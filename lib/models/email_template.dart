import 'package:cloud_firestore/cloud_firestore.dart';

class EmailTemplateModel {
  final String id;
  final String name;
  final String subject;
  final String content;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final EmailTemplateCategory category;
  final List<String> placeholders;
  final bool includeInvestmentDetails;
  final bool isActive;
  final Map<String, dynamic> metadata;

  EmailTemplateModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.content,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.category = EmailTemplateCategory.general,
    this.placeholders = const [],
    this.includeInvestmentDetails = true,
    this.isActive = true,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'content': content,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'category': category.name,
      'placeholders': placeholders,
      'includeInvestmentDetails': includeInvestmentDetails,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  /// Konwertuje do Map dla Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'subject': subject,
      'content': content,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'category': category.name,
      'placeholders': placeholders,
      'includeInvestmentDetails': includeInvestmentDetails,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  factory EmailTemplateModel.fromJson(Map<String, dynamic> json) {
    return EmailTemplateModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      subject: json['subject'] ?? '',
      content: json['content'] ?? json['htmlContent'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] ?? 0),
      createdBy: json['createdBy'] ?? '',
      category: EmailTemplateCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => EmailTemplateCategory.general,
      ),
      placeholders: List<String>.from(json['placeholders'] ?? []),
      includeInvestmentDetails: json['includeInvestmentDetails'] ?? true,
      isActive: json['isActive'] ?? true,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Tworzy EmailTemplateModel z Firestore DocumentSnapshot
  factory EmailTemplateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmailTemplateModel(
      id: doc.id,
      name: data['name'] ?? '',
      subject: data['subject'] ?? '',
      content: data['content'] ?? data['htmlContent'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      category: EmailTemplateCategory.values.firstWhere(
        (c) => c.name == data['category'],
        orElse: () => EmailTemplateCategory.general,
      ),
      placeholders: List<String>.from(data['placeholders'] ?? []),
      includeInvestmentDetails: data['includeInvestmentDetails'] ?? true,
      isActive: data['isActive'] ?? true,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  EmailTemplateModel copyWith({
    String? id,
    String? name,
    String? subject,
    String? content,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    EmailTemplateCategory? category,
    List<String>? placeholders,
    bool? includeInvestmentDetails,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return EmailTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      category: category ?? this.category,
      placeholders: placeholders ?? this.placeholders,
      includeInvestmentDetails: includeInvestmentDetails ?? this.includeInvestmentDetails,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Pobiera wszystkie placeholders z treści i tematu
  List<String> extractPlaceholders() {
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    final Set<String> found = {};
    
    // Szukaj w temacie
    final subjectMatches = regex.allMatches(subject);
    for (final match in subjectMatches) {
      if (match.group(1) != null) {
        found.add('{{${match.group(1)}}}');
      }
    }

    // Szukaj w treści
    final contentMatches = regex.allMatches(content);
    for (final match in contentMatches) {
      if (match.group(1) != null) {
        found.add('{{${match.group(1)}}}');
      }
    }

    return found.toList()..sort();
  }

  /// Zastępuje placeholders rzeczywistymi wartościami
  EmailTemplateModel renderWithData(Map<String, String> values) {
    String renderedSubject = subject;
    String renderedContent = content;
    
    // Zamień placeholders w temacie
    values.forEach((placeholder, value) {
      renderedSubject = renderedSubject.replaceAll(placeholder, value);
    });

    // Zamień placeholders w treści
    values.forEach((placeholder, value) {
      renderedContent = renderedContent.replaceAll(placeholder, value);
    });

    return copyWith(
      subject: renderedSubject,
      content: renderedContent,
    );
  }

  /// Renderuje szablon dla konkretnego inwestora
  String renderForInvestor(dynamic investor) {
    String rendered = content;
    
    // Podstawowe placeholders z danych inwestora
    if (investor != null) {
      // Klient
      if (investor.client != null) {
        rendered = rendered.replaceAll('{{client_name}}', investor.client.name ?? '');
        rendered = rendered.replaceAll('{{client_email}}', investor.client.email ?? '');
        rendered = rendered.replaceAll('{{client_phone}}', investor.client.phoneNumber ?? '');
      }
      
      // Wartości inwestycyjne
      rendered = rendered.replaceAll('{{total_investment}}', investor.totalInvestmentAmount?.toStringAsFixed(2) ?? '0.00');
      rendered = rendered.replaceAll('{{remaining_capital}}', investor.totalRemainingCapital?.toStringAsFixed(2) ?? '0.00');
      rendered = rendered.replaceAll('{{total_value}}', investor.totalValue?.toStringAsFixed(2) ?? '0.00');
      rendered = rendered.replaceAll('{{secured_capital}}', investor.capitalSecuredByRealEstate?.toStringAsFixed(2) ?? '0.00');
      rendered = rendered.replaceAll('{{investment_count}}', investor.investmentCount?.toString() ?? '0');
    }
    
    // Domyślne wartości
    rendered = rendered.replaceAll('{{company_name}}', 'Metropolitan Investment');
    rendered = rendered.replaceAll('{{current_date}}', DateTime.now().toString().split(' ')[0]);
    
    return rendered;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmailTemplateModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EmailTemplateModel(id: $id, name: $name, subject: $subject, category: $category)';
  }
}

/// 📂 KATEGORIE SZABLONÓW EMAIL
enum EmailTemplateCategory {
  general('Ogólne', 'Standardowe szablony komunikacji'),
  investment('Inwestycje', 'Szablony dotyczące inwestycji i portfeli'),
  marketing('Marketing', 'Szablony promocyjne i marketingowe'),
  notification('Powiadomienia', 'Szablony powiadomień systemowych'),
  report('Raporty', 'Szablony raportów okresowych'),
  welcome('Powitalne', 'Szablony powitalnych wiadomości'),
  reminder('Przypomnienia', 'Szablony przypomnień i terminów');

  const EmailTemplateCategory(this.displayName, this.description);
  
  final String displayName;
  final String description;

  /// Pobiera ikonę kategorii
  String get icon {
    switch (this) {
      case EmailTemplateCategory.general:
        return '📧';
      case EmailTemplateCategory.investment:
        return '💰';
      case EmailTemplateCategory.marketing:
        return '📢';
      case EmailTemplateCategory.notification:
        return '🔔';
      case EmailTemplateCategory.report:
        return '📊';
      case EmailTemplateCategory.welcome:
        return '👋';
      case EmailTemplateCategory.reminder:
        return '⏰';
    }
  }
}