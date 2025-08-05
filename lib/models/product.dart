import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductType {
  bonds('Obligacje'),
  shares('Udziały'),
  loans('Pożyczki'),
  apartments('Apartamenty');

  const ProductType(this.displayName);
  final String displayName;
}

class Product {
  final String id;
  final String name;
  final ProductType type;
  final String companyId;
  final String companyName;
  final double? interestRate;
  final DateTime? issueDate;
  final DateTime? maturityDate;
  final int? sharesCount;
  final double? sharePrice;
  final String currency;
  final double? exchangeRate;
  final bool isPrivateIssue;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    required this.type,
    required this.companyId,
    required this.companyName,
    this.interestRate,
    this.issueDate,
    this.maturityDate,
    this.sharesCount,
    this.sharePrice,
    this.currency = 'PLN',
    this.exchangeRate,
    this.isPrivateIssue = false,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      type: ProductType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ProductType.bonds,
      ),
      companyId: data['companyId'] ?? '',
      companyName: data['companyName'] ?? '',
      interestRate: data['interestRate']?.toDouble(),
      issueDate: data['issueDate'] != null
          ? (data['issueDate'] as Timestamp).toDate()
          : null,
      maturityDate: data['maturityDate'] != null
          ? (data['maturityDate'] as Timestamp).toDate()
          : null,
      sharesCount: data['sharesCount'],
      sharePrice: data['sharePrice']?.toDouble(),
      currency: data['currency'] ?? 'PLN',
      exchangeRate: data['exchangeRate']?.toDouble(),
      isPrivateIssue: data['isPrivateIssue'] ?? false,
      metadata: data['metadata'] ?? {},
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  /// Factory dla danych z Firebase Functions (bez Timestamp)
  factory Product.fromMap(Map<String, dynamic> data) {
    return Product(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      type: ProductType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ProductType.bonds,
      ),
      companyId: data['companyId'] ?? '',
      companyName: data['companyName'] ?? '',
      interestRate: data['interestRate']?.toDouble(),
      issueDate: data['issueDate'] != null
          ? DateTime.tryParse(data['issueDate'].toString())
          : null,
      maturityDate: data['maturityDate'] != null
          ? DateTime.tryParse(data['maturityDate'].toString())
          : null,
      sharesCount: data['sharesCount'],
      sharePrice: data['sharePrice']?.toDouble(),
      currency: data['currency'] ?? 'PLN',
      exchangeRate: data['exchangeRate']?.toDouble(),
      isPrivateIssue: data['isPrivateIssue'] ?? false,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type.name,
      'companyId': companyId,
      'companyName': companyName,
      'interestRate': interestRate,
      'issueDate': issueDate != null ? Timestamp.fromDate(issueDate!) : null,
      'maturityDate': maturityDate != null
          ? Timestamp.fromDate(maturityDate!)
          : null,
      'sharesCount': sharesCount,
      'sharePrice': sharePrice,
      'currency': currency,
      'exchangeRate': exchangeRate,
      'isPrivateIssue': isPrivateIssue,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    ProductType? type,
    String? companyId,
    String? companyName,
    double? interestRate,
    DateTime? issueDate,
    DateTime? maturityDate,
    int? sharesCount,
    double? sharePrice,
    String? currency,
    double? exchangeRate,
    bool? isPrivateIssue,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      interestRate: interestRate ?? this.interestRate,
      issueDate: issueDate ?? this.issueDate,
      maturityDate: maturityDate ?? this.maturityDate,
      sharesCount: sharesCount ?? this.sharesCount,
      sharePrice: sharePrice ?? this.sharePrice,
      currency: currency ?? this.currency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      isPrivateIssue: isPrivateIssue ?? this.isPrivateIssue,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
