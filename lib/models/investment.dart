import 'package:cloud_firestore/cloud_firestore.dart';
import 'product.dart';

enum InvestmentStatus {
  active('Aktywny'),
  inactive('Nieaktywny'),
  earlyRedemption('Wykup wczesniejszy'),
  completed('Zakończony');

  const InvestmentStatus(this.displayName);
  final String displayName;
}

enum MarketType {
  primary('Rynek pierwotny'),
  secondary('Rynek wtórny'),
  clientRedemption('Odkup od Klienta');

  const MarketType(this.displayName);
  final String displayName;
}

class Investment {
  final String id;
  final String clientId;
  final String clientName;
  final String employeeId;
  final String employeeFirstName;
  final String employeeLastName;
  final String branchCode;
  final InvestmentStatus status;
  final bool isAllocated;
  final MarketType marketType;
  final DateTime signedDate;
  final DateTime? entryDate;
  final DateTime? exitDate;
  final String proposalId;
  final ProductType productType;
  final String productName;
  final String creditorCompany;
  final String companyId;
  final DateTime? issueDate;
  final DateTime? redemptionDate;
  final int? sharesCount;
  final double investmentAmount;
  final double paidAmount;
  final double realizedCapital;
  final double realizedInterest;
  final double transferToOtherProduct;
  final double remainingCapital;
  final double remainingInterest;
  final double plannedTax;
  final double realizedTax;
  final String currency;
  final double? exchangeRate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> additionalInfo;

  Investment({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.employeeId,
    required this.employeeFirstName,
    required this.employeeLastName,
    required this.branchCode,
    required this.status,
    this.isAllocated = false,
    required this.marketType,
    required this.signedDate,
    this.entryDate,
    this.exitDate,
    required this.proposalId,
    required this.productType,
    required this.productName,
    required this.creditorCompany,
    required this.companyId,
    this.issueDate,
    this.redemptionDate,
    this.sharesCount,
    required this.investmentAmount,
    required this.paidAmount,
    this.realizedCapital = 0.0,
    this.realizedInterest = 0.0,
    this.transferToOtherProduct = 0.0,
    this.remainingCapital = 0.0,
    this.remainingInterest = 0.0,
    this.plannedTax = 0.0,
    this.realizedTax = 0.0,
    this.currency = 'PLN',
    this.exchangeRate,
    required this.createdAt,
    required this.updatedAt,
    this.additionalInfo = const {},
  });

  String get employeeFullName => '$employeeFirstName $employeeLastName';

  double get totalRealized => realizedCapital + realizedInterest;
  double get totalRemaining => remainingCapital + remainingInterest;
  double get totalValue => totalRealized + totalRemaining;
  double get profitLoss => totalValue - investmentAmount;
  double get profitLossPercentage =>
      investmentAmount > 0 ? (profitLoss / investmentAmount) * 100 : 0.0;

  factory Investment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Investment(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      employeeId: data['employeeId'] ?? '',
      employeeFirstName: data['employeeFirstName'] ?? '',
      employeeLastName: data['employeeLastName'] ?? '',
      branchCode: data['branchCode'] ?? '',
      status: InvestmentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => InvestmentStatus.active,
      ),
      isAllocated: data['isAllocated'] ?? false,
      marketType: MarketType.values.firstWhere(
        (e) => e.name == data['marketType'],
        orElse: () => MarketType.primary,
      ),
      signedDate: (data['signedDate'] as Timestamp).toDate(),
      entryDate: data['entryDate'] != null
          ? (data['entryDate'] as Timestamp).toDate()
          : null,
      exitDate: data['exitDate'] != null
          ? (data['exitDate'] as Timestamp).toDate()
          : null,
      proposalId: data['proposalId'] ?? '',
      productType: ProductType.values.firstWhere(
        (e) => e.name == data['productType'],
        orElse: () => ProductType.bonds,
      ),
      productName: data['productName'] ?? '',
      creditorCompany: data['creditorCompany'] ?? '',
      companyId: data['companyId'] ?? '',
      issueDate: data['issueDate'] != null
          ? (data['issueDate'] as Timestamp).toDate()
          : null,
      redemptionDate: data['redemptionDate'] != null
          ? (data['redemptionDate'] as Timestamp).toDate()
          : null,
      sharesCount: data['sharesCount'],
      investmentAmount: data['investmentAmount']?.toDouble() ?? 0.0,
      paidAmount: data['paidAmount']?.toDouble() ?? 0.0,
      realizedCapital: data['realizedCapital']?.toDouble() ?? 0.0,
      realizedInterest: data['realizedInterest']?.toDouble() ?? 0.0,
      transferToOtherProduct: data['transferToOtherProduct']?.toDouble() ?? 0.0,
      remainingCapital: data['remainingCapital']?.toDouble() ?? 0.0,
      remainingInterest: data['remainingInterest']?.toDouble() ?? 0.0,
      plannedTax: data['plannedTax']?.toDouble() ?? 0.0,
      realizedTax: data['realizedTax']?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'PLN',
      exchangeRate: data['exchangeRate']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      additionalInfo: data['additionalInfo'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'employeeId': employeeId,
      'employeeFirstName': employeeFirstName,
      'employeeLastName': employeeLastName,
      'branchCode': branchCode,
      'status': status.name,
      'isAllocated': isAllocated,
      'marketType': marketType.name,
      'signedDate': Timestamp.fromDate(signedDate),
      'entryDate': entryDate != null ? Timestamp.fromDate(entryDate!) : null,
      'exitDate': exitDate != null ? Timestamp.fromDate(exitDate!) : null,
      'proposalId': proposalId,
      'productType': productType.name,
      'productName': productName,
      'creditorCompany': creditorCompany,
      'companyId': companyId,
      'issueDate': issueDate != null ? Timestamp.fromDate(issueDate!) : null,
      'redemptionDate': redemptionDate != null
          ? Timestamp.fromDate(redemptionDate!)
          : null,
      'sharesCount': sharesCount,
      'investmentAmount': investmentAmount,
      'paidAmount': paidAmount,
      'realizedCapital': realizedCapital,
      'realizedInterest': realizedInterest,
      'transferToOtherProduct': transferToOtherProduct,
      'remainingCapital': remainingCapital,
      'remainingInterest': remainingInterest,
      'plannedTax': plannedTax,
      'realizedTax': realizedTax,
      'currency': currency,
      'exchangeRate': exchangeRate,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'additionalInfo': additionalInfo,
    };
  }

  Investment copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? employeeId,
    String? employeeFirstName,
    String? employeeLastName,
    String? branchCode,
    InvestmentStatus? status,
    bool? isAllocated,
    MarketType? marketType,
    DateTime? signedDate,
    DateTime? entryDate,
    DateTime? exitDate,
    String? proposalId,
    ProductType? productType,
    String? productName,
    String? creditorCompany,
    String? companyId,
    DateTime? issueDate,
    DateTime? redemptionDate,
    int? sharesCount,
    double? investmentAmount,
    double? paidAmount,
    double? realizedCapital,
    double? realizedInterest,
    double? transferToOtherProduct,
    double? remainingCapital,
    double? remainingInterest,
    double? plannedTax,
    double? realizedTax,
    String? currency,
    double? exchangeRate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Investment(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      employeeId: employeeId ?? this.employeeId,
      employeeFirstName: employeeFirstName ?? this.employeeFirstName,
      employeeLastName: employeeLastName ?? this.employeeLastName,
      branchCode: branchCode ?? this.branchCode,
      status: status ?? this.status,
      isAllocated: isAllocated ?? this.isAllocated,
      marketType: marketType ?? this.marketType,
      signedDate: signedDate ?? this.signedDate,
      entryDate: entryDate ?? this.entryDate,
      exitDate: exitDate ?? this.exitDate,
      proposalId: proposalId ?? this.proposalId,
      productType: productType ?? this.productType,
      productName: productName ?? this.productName,
      creditorCompany: creditorCompany ?? this.creditorCompany,
      companyId: companyId ?? this.companyId,
      issueDate: issueDate ?? this.issueDate,
      redemptionDate: redemptionDate ?? this.redemptionDate,
      sharesCount: sharesCount ?? this.sharesCount,
      investmentAmount: investmentAmount ?? this.investmentAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      realizedCapital: realizedCapital ?? this.realizedCapital,
      realizedInterest: realizedInterest ?? this.realizedInterest,
      transferToOtherProduct:
          transferToOtherProduct ?? this.transferToOtherProduct,
      remainingCapital: remainingCapital ?? this.remainingCapital,
      remainingInterest: remainingInterest ?? this.remainingInterest,
      plannedTax: plannedTax ?? this.plannedTax,
      realizedTax: realizedTax ?? this.realizedTax,
      currency: currency ?? this.currency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}
