import 'bond.dart';
import 'share.dart';
import 'loan.dart';
import 'product.dart';

/// Enum reprezentujący typy produktów w systemie
enum UnifiedProductType {
  bonds('Obligacje', 'bonds', 'Instrumenty dłużne o stałym oprocentowaniu'),
  shares('Udziały', 'shares', 'Udziały w kapitale spółek'),
  loans('Pożyczki', 'loans', 'Produkty pożyczkowe'),
  apartments('Apartamenty', 'apartments', 'Inwestycje w nieruchomości'),
  other('Inne', 'other', 'Pozostałe produkty inwestycyjne');

  const UnifiedProductType(this.displayName, this.collectionName, this.description);
  
  final String displayName;
  final String collectionName;
  final String description;

  /// Zwraca ikonę dla danego typu produktu
  String get iconPath {
    switch (this) {
      case UnifiedProductType.bonds:
        return 'assets/icons/bonds.svg';
      case UnifiedProductType.shares:
        return 'assets/icons/shares.svg';
      case UnifiedProductType.loans:
        return 'assets/icons/loans.svg';
      case UnifiedProductType.apartments:
        return 'assets/icons/apartments.svg';
      case UnifiedProductType.other:
        return 'assets/icons/other.svg';
    }
  }
}

/// Status produktu w systemie
enum ProductStatus {
  active('Aktywny', 'Produkt jest dostępny'),
  inactive('Nieaktywny', 'Produkt został wycofany'),
  pending('Oczekujący', 'Produkt czeka na aktywację'),
  suspended('Zawieszony', 'Produkt został czasowo zawieszony');

  const ProductStatus(this.displayName, this.description);
  
  final String displayName;
  final String description;
}

/// Zunifikowany interfejs dla wszystkich produktów
abstract class IUnifiedProduct {
  String get id;
  String get name;
  UnifiedProductType get productType;
  double get investmentAmount;
  DateTime get createdAt;
  DateTime get uploadedAt;
  String get sourceFile;
  ProductStatus get status;
  Map<String, dynamic> get additionalInfo;
  
  /// Zwraca wartość całkowitą produktu
  double get totalValue;
  
  /// Zwraca opis produktu
  String get description;
  
  /// Sprawdza czy produkt jest aktywny
  bool get isActive;
  
  /// Konwertuje do mapy do wyświetlenia
  Map<String, dynamic> toDisplayMap();
}

/// Zunifikowana implementacja produktu łącząca wszystkie typy
class UnifiedProduct implements IUnifiedProduct {
  @override
  final String id;
  
  @override
  final String name;
  
  @override
  final UnifiedProductType productType;
  
  @override
  final double investmentAmount;
  
  @override
  final DateTime createdAt;
  
  @override
  final DateTime uploadedAt;
  
  @override
  final String sourceFile;
  
  @override
  final ProductStatus status;
  
  @override
  final Map<String, dynamic> additionalInfo;

  // Dodatkowe pola specyficzne dla różnych typów produktów
  final double? realizedCapital;
  final double? remainingCapital;
  final double? realizedInterest;
  final double? remainingInterest;
  final double? realizedTax;
  final double? remainingTax;
  final double? transferToOtherProduct;
  final int? sharesCount;
  final double? pricePerShare;
  final double? interestRate;
  final DateTime? maturityDate;
  final String? companyName;
  final String? companyId;
  final String? currency;
  
  // Przechowywanie oryginalnego obiektu dla szczegółowych operacji
  final dynamic originalProduct;

  UnifiedProduct({
    required this.id,
    required this.name,
    required this.productType,
    required this.investmentAmount,
    required this.createdAt,
    required this.uploadedAt,
    required this.sourceFile,
    this.status = ProductStatus.active,
    this.additionalInfo = const {},
    this.realizedCapital,
    this.remainingCapital,
    this.realizedInterest,
    this.remainingInterest,
    this.realizedTax,
    this.remainingTax,
    this.transferToOtherProduct,
    this.sharesCount,
    this.pricePerShare,
    this.interestRate,
    this.maturityDate,
    this.companyName,
    this.companyId,
    this.currency,
    this.originalProduct,
  });

  /// Factory method dla Bond
  factory UnifiedProduct.fromBond(Bond bond) {
    return UnifiedProduct(
      id: bond.id,
      name: bond.productType.isNotEmpty ? bond.productType : 'Obligacja ${bond.id}',
      productType: UnifiedProductType.bonds,
      investmentAmount: bond.investmentAmount,
      createdAt: bond.createdAt,
      uploadedAt: bond.uploadedAt,
      sourceFile: bond.sourceFile,
      additionalInfo: bond.additionalInfo,
      realizedCapital: bond.realizedCapital,
      remainingCapital: bond.remainingCapital,
      realizedInterest: bond.realizedInterest,
      remainingInterest: bond.remainingInterest,
      realizedTax: bond.realizedTax,
      remainingTax: bond.remainingTax,
      transferToOtherProduct: bond.transferToOtherProduct,
      originalProduct: bond,
    );
  }

  /// Factory method dla Share
  factory UnifiedProduct.fromShare(Share share) {
    return UnifiedProduct(
      id: share.id,
      name: share.productType.isNotEmpty ? share.productType : 'Udział ${share.id}',
      productType: UnifiedProductType.shares,
      investmentAmount: share.investmentAmount,
      createdAt: share.createdAt,
      uploadedAt: share.uploadedAt,
      sourceFile: share.sourceFile,
      additionalInfo: share.additionalInfo,
      sharesCount: share.sharesCount,
      pricePerShare: share.pricePerShare,
      originalProduct: share,
    );
  }

  /// Factory method dla Loan
  factory UnifiedProduct.fromLoan(Loan loan) {
    return UnifiedProduct(
      id: loan.id,
      name: loan.productType.isNotEmpty ? loan.productType : 'Pożyczka ${loan.id}',
      productType: UnifiedProductType.loans,
      investmentAmount: loan.investmentAmount,
      createdAt: loan.createdAt,
      uploadedAt: loan.uploadedAt,
      sourceFile: loan.sourceFile,
      additionalInfo: loan.additionalInfo,
      originalProduct: loan,
    );
  }

  /// Factory method dla Product
  factory UnifiedProduct.fromProduct(Product product) {
    UnifiedProductType type;
    switch (product.type) {
      case ProductType.bonds:
        type = UnifiedProductType.bonds;
        break;
      case ProductType.shares:
        type = UnifiedProductType.shares;
        break;
      case ProductType.loans:
        type = UnifiedProductType.loans;
        break;
      case ProductType.apartments:
        type = UnifiedProductType.apartments;
        break;
    }

    return UnifiedProduct(
      id: product.id,
      name: product.name,
      productType: type,
      investmentAmount: 0.0, // Product nie ma investment amount
      createdAt: product.createdAt,
      uploadedAt: product.updatedAt,
      sourceFile: 'product_collection',
      status: product.isActive ? ProductStatus.active : ProductStatus.inactive,
      additionalInfo: product.metadata,
      interestRate: product.interestRate,
      maturityDate: product.maturityDate,
      companyName: product.companyName,
      companyId: product.companyId,
      sharesCount: product.sharesCount,
      pricePerShare: product.sharePrice,
      currency: product.currency,
      originalProduct: product,
    );
  }

  @override
  double get totalValue {
    switch (productType) {
      case UnifiedProductType.bonds:
        return remainingCapital ?? investmentAmount;
      case UnifiedProductType.shares:
        return investmentAmount;
      case UnifiedProductType.loans:
        return investmentAmount;
      case UnifiedProductType.apartments:
        return investmentAmount;
      case UnifiedProductType.other:
        return investmentAmount;
    }
  }

  @override
  String get description {
    switch (productType) {
      case UnifiedProductType.bonds:
        final parts = <String>[];
        if (realizedCapital != null && realizedCapital! > 0) {
          parts.add('Zrealizowany kapitał: ${realizedCapital!.toStringAsFixed(2)} PLN');
        }
        if (remainingCapital != null && remainingCapital! > 0) {
          parts.add('Pozostały kapitał: ${remainingCapital!.toStringAsFixed(2)} PLN');
        }
        if (interestRate != null) {
          parts.add('Oprocentowanie: ${interestRate!.toStringAsFixed(2)}%');
        }
        return parts.isNotEmpty ? parts.join(' • ') : 'Obligacja bez szczegółów';
        
      case UnifiedProductType.shares:
        final parts = <String>[];
        if (sharesCount != null && sharesCount! > 0) {
          parts.add('Liczba udziałów: $sharesCount');
        }
        if (pricePerShare != null && pricePerShare! > 0) {
          parts.add('Cena za udział: ${pricePerShare!.toStringAsFixed(2)} PLN');
        }
        if (companyName != null && companyName!.isNotEmpty) {
          parts.add('Spółka: $companyName');
        }
        return parts.isNotEmpty ? parts.join(' • ') : 'Udział bez szczegółów';
        
      case UnifiedProductType.loans:
        final parts = <String>[];
        if (interestRate != null) {
          parts.add('Oprocentowanie: ${interestRate!.toStringAsFixed(2)}%');
        }
        if (maturityDate != null) {
          parts.add('Termin spłaty: ${maturityDate!.toString().split(' ')[0]}');
        }
        return parts.isNotEmpty ? parts.join(' • ') : 'Pożyczka bez szczegółów';
        
      default:
        return productType.description;
    }
  }

  @override
  bool get isActive => status == ProductStatus.active;

  @override
  Map<String, dynamic> toDisplayMap() {
    return {
      'id': id,
      'name': name,
      'type': productType.displayName,
      'typeEnum': productType,
      'investmentAmount': investmentAmount,
      'totalValue': totalValue,
      'description': description,
      'status': status.displayName,
      'statusEnum': status,
      'createdAt': createdAt,
      'uploadedAt': uploadedAt,
      'sourceFile': sourceFile,
      'isActive': isActive,
      'companyName': companyName,
      'interestRate': interestRate,
      'maturityDate': maturityDate,
      'sharesCount': sharesCount,
      'pricePerShare': pricePerShare,
      'realizedCapital': realizedCapital,
      'remainingCapital': remainingCapital,
      'realizedInterest': realizedInterest,
      'remainingInterest': remainingInterest,
      'currency': currency ?? 'PLN',
    };
  }

  /// Zwraca szczegółowe informacje o produkcie w formie listy
  List<MapEntry<String, String>> get detailsList {
    final details = <MapEntry<String, String>>[];
    
    details.add(MapEntry('Typ produktu', productType.displayName));
    details.add(MapEntry('Kwota inwestycji', '${investmentAmount.toStringAsFixed(2)} PLN'));
    details.add(MapEntry('Wartość całkowita', '${totalValue.toStringAsFixed(2)} PLN'));
    details.add(MapEntry('Status', status.displayName));
    details.add(MapEntry('Data utworzenia', createdAt.toString().split(' ')[0]));
    details.add(MapEntry('Źródło danych', sourceFile));

    // Dodaj szczegóły specyficzne dla typu produktu
    switch (productType) {
      case UnifiedProductType.bonds:
        if (realizedCapital != null && realizedCapital! > 0) {
          details.add(MapEntry('Zrealizowany kapitał', '${realizedCapital!.toStringAsFixed(2)} PLN'));
        }
        if (remainingCapital != null && remainingCapital! > 0) {
          details.add(MapEntry('Pozostały kapitał', '${remainingCapital!.toStringAsFixed(2)} PLN'));
        }
        if (realizedInterest != null && realizedInterest! > 0) {
          details.add(MapEntry('Zrealizowane odsetki', '${realizedInterest!.toStringAsFixed(2)} PLN'));
        }
        if (remainingInterest != null && remainingInterest! > 0) {
          details.add(MapEntry('Pozostałe odsetki', '${remainingInterest!.toStringAsFixed(2)} PLN'));
        }
        break;
        
      case UnifiedProductType.shares:
        if (sharesCount != null && sharesCount! > 0) {
          details.add(MapEntry('Liczba udziałów', sharesCount.toString()));
        }
        if (pricePerShare != null && pricePerShare! > 0) {
          details.add(MapEntry('Cena za udział', '${pricePerShare!.toStringAsFixed(2)} PLN'));
        }
        break;
        
      default:
        break;
    }

    if (companyName != null && companyName!.isNotEmpty) {
      details.add(MapEntry('Spółka', companyName!));
    }
    
    if (interestRate != null) {
      details.add(MapEntry('Oprocentowanie', '${interestRate!.toStringAsFixed(2)}%'));
    }
    
    if (maturityDate != null) {
      details.add(MapEntry('Data zapadalności', maturityDate.toString().split(' ')[0]));
    }

    return details;
  }

  UnifiedProduct copyWith({
    String? id,
    String? name,
    UnifiedProductType? productType,
    double? investmentAmount,
    DateTime? createdAt,
    DateTime? uploadedAt,
    String? sourceFile,
    ProductStatus? status,
    Map<String, dynamic>? additionalInfo,
    double? realizedCapital,
    double? remainingCapital,
    double? realizedInterest,
    double? remainingInterest,
    double? realizedTax,
    double? remainingTax,
    double? transferToOtherProduct,
    int? sharesCount,
    double? pricePerShare,
    double? interestRate,
    DateTime? maturityDate,
    String? companyName,
    String? companyId,
    String? currency,
  }) {
    return UnifiedProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      productType: productType ?? this.productType,
      investmentAmount: investmentAmount ?? this.investmentAmount,
      createdAt: createdAt ?? this.createdAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      sourceFile: sourceFile ?? this.sourceFile,
      status: status ?? this.status,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      realizedCapital: realizedCapital ?? this.realizedCapital,
      remainingCapital: remainingCapital ?? this.remainingCapital,
      realizedInterest: realizedInterest ?? this.realizedInterest,
      remainingInterest: remainingInterest ?? this.remainingInterest,
      realizedTax: realizedTax ?? this.realizedTax,
      remainingTax: remainingTax ?? this.remainingTax,
      transferToOtherProduct: transferToOtherProduct ?? this.transferToOtherProduct,
      sharesCount: sharesCount ?? this.sharesCount,
      pricePerShare: pricePerShare ?? this.pricePerShare,
      interestRate: interestRate ?? this.interestRate,
      maturityDate: maturityDate ?? this.maturityDate,
      companyName: companyName ?? this.companyName,
      companyId: companyId ?? this.companyId,
      currency: currency ?? this.currency,
      originalProduct: originalProduct,
    );
  }
}

/// Klasa do filtrowania i sortowania produktów
class ProductFilterCriteria {
  final List<UnifiedProductType>? productTypes;
  final List<ProductStatus>? statuses;
  final double? minInvestmentAmount;
  final double? maxInvestmentAmount;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final String? searchText;
  final String? companyName;
  final double? minInterestRate;
  final double? maxInterestRate;

  const ProductFilterCriteria({
    this.productTypes,
    this.statuses,
    this.minInvestmentAmount,
    this.maxInvestmentAmount,
    this.createdAfter,
    this.createdBefore,
    this.searchText,
    this.companyName,
    this.minInterestRate,
    this.maxInterestRate,
  });

  bool matches(UnifiedProduct product) {
    if (productTypes != null && !productTypes!.contains(product.productType)) {
      return false;
    }
    
    if (statuses != null && !statuses!.contains(product.status)) {
      return false;
    }
    
    if (minInvestmentAmount != null && product.investmentAmount < minInvestmentAmount!) {
      return false;
    }
    
    if (maxInvestmentAmount != null && product.investmentAmount > maxInvestmentAmount!) {
      return false;
    }
    
    if (createdAfter != null && product.createdAt.isBefore(createdAfter!)) {
      return false;
    }
    
    if (createdBefore != null && product.createdAt.isAfter(createdBefore!)) {
      return false;
    }
    
    if (searchText != null && searchText!.isNotEmpty) {
      final searchLower = searchText!.toLowerCase();
      if (!product.name.toLowerCase().contains(searchLower) &&
          !product.description.toLowerCase().contains(searchLower) &&
          (product.companyName?.toLowerCase().contains(searchLower) != true)) {
        return false;
      }
    }
    
    if (companyName != null && companyName!.isNotEmpty) {
      if (product.companyName?.toLowerCase() != companyName!.toLowerCase()) {
        return false;
      }
    }
    
    if (minInterestRate != null && 
        (product.interestRate == null || product.interestRate! < minInterestRate!)) {
      return false;
    }
    
    if (maxInterestRate != null && 
        (product.interestRate == null || product.interestRate! > maxInterestRate!)) {
      return false;
    }
    
    return true;
  }
}

/// Enum do sortowania produktów
enum ProductSortField {
  name('Nazwa'),
  type('Typ produktu'),
  investmentAmount('Kwota inwestycji'),
  totalValue('Wartość całkowita'),
  createdAt('Data utworzenia'),
  uploadedAt('Data aktualizacji'),
  status('Status'),
  companyName('Nazwa spółki'),
  interestRate('Oprocentowanie');

  const ProductSortField(this.displayName);
  final String displayName;
}

/// Kierunek sortowania
enum SortDirection {
  ascending('Rosnąco'),
  descending('Malejąco');

  const SortDirection(this.displayName);
  final String displayName;
}