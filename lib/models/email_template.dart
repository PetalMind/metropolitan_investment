class EmailTemplateModel {
  final String id;
  final String name;
  final String subject;
  final String content;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  EmailTemplateModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.content,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
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
    );
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
    return 'EmailTemplateModel(id: $id, name: $name, subject: $subject)';
  }
}