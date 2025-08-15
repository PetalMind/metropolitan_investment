import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models_and_services.dart';
import '../services/firebase_functions_products_service.dart' as fb;
import '../services/unified_product_service.dart' as unified;
import '../adapters/product_statistics_adapter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/premium_loading_widget.dart';
import '../widgets/premium_error_widget.dart';
import '../widgets/product_card_widget.dart';
import '../widgets/product_stats_widget.dart';
import '../widgets/product_filter_widget.dart';
import '../widgets/dialogs/product_details_dialog.dart';
import '../widgets/dialogs/enhanced_investor_email_dialog.dart';

// 🧩 Import serwisów zarządzania produktami
import '../services/product_management_service.dart';
import '../services/cache_management_service.dart';

// 🧩 Enum dla trybu widoku (kopiowane z oryginalnego ekranu)
enum ViewMode { grid, list }

/// 🚀 NOWY: Ekran zarządzania produktami z ProductManagementService
///
/// Zachowuje DOKŁADNIE tę samą funkcjonalność co stary ekran ale używa:
/// - ProductManagementService jako central hub
/// - CacheManagementService dla zarządzania cache
/// - Wszystkie te same widgety i UI co oryginalny ekran
/// - Te same parametry i funkcjonalności
class ProductsManagementScreenAdvanced extends StatefulWidget {
  // ✅ ZACHOWANE: Wszystkie parametry z oryginalnego ekranu
  final String? highlightedProductId;
  final String? highlightedInvestmentId;
  final String? initialSearchProductName;
  final String? initialSearchProductType;
  final String? initialSearchClientId;
  final String? initialSearchClientName;

  const ProductsManagementScreenAdvanced({
    super.key,
    this.highlightedProductId,
    this.highlightedInvestmentId,
    this.initialSearchProductName,
    this.initialSearchProductType,
    this.initialSearchClientId,
    this.initialSearchClientName,
  });

  @override
  State<ProductsManagementScreenAdvanced> createState() =>
      _ProductsManagementScreenAdvancedState();
}

class _ProductsManagementScreenAdvancedState
    extends State<ProductsManagementScreenAdvanced>
    with TickerProviderStateMixin {
  // 🚀 NOWE SERWISY: Używamy nowych centralnych serwisów
  late final ProductManagementService _productManagementService;
  late final CacheManagementService _cacheManagementService;
  late final FirebaseFunctionsProductInvestorsService _productInvestorsService;

  // ✅ ZACHOWANE: Te same animacje co w oryginalnym ekranie
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // ✅ ZACHOWANE: Dokładnie ten sam stan co w oryginalnym ekranie
  List<UnifiedProduct> _allProducts = [];
  List<UnifiedProduct> _filteredProducts = [];
  List<DeduplicatedProduct> _deduplicatedProducts = [];
  List<DeduplicatedProduct> _filteredDeduplicatedProducts = [];
  List<OptimizedProduct> _optimizedProducts = [];
  List<OptimizedProduct> _filteredOptimizedProducts = [];
  fb.ProductStatistics? _statistics;
  UnifiedProductsMetadata? _metadata;
  OptimizedProductsResult? _optimizedResult;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  // ✅ ZACHOWANE: Te same kontrolery i filtry
  final TextEditingController _searchController = TextEditingController();
  ProductFilterCriteria _filterCriteria = const ProductFilterCriteria();
  ProductSortField _sortField = ProductSortField.createdAt;
  SortDirection _sortDirection = SortDirection.descending;

  // ✅ ZACHOWANE: Te same opcje wyświetlania
  bool _showFilters = false;
  bool _showStatistics = true;
  ViewMode _viewMode = ViewMode.list;
  bool _showDeduplicatedView = true;
  bool _useOptimizedMode = true; // Domyślnie używaj ProductManagementService

  // ✅ ZACHOWANE: Email functionality
  bool _isSelectionMode = false;
  Set<String> _selectedProductIds = <String>{};

  // ✅ ZACHOWANE: Te same gettery
  List<DeduplicatedProduct> get _selectedProducts {
    return _filteredDeduplicatedProducts
        .where((product) => _selectedProductIds.contains(product.id))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _loadInitialData();
    _setupSearchListener();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ ZACHOWANE: Te sama logika opóźnienia
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _handleRouteParameters();
      }
    });
  }

  /// ✅ ZACHOWANE: Ta sama metoda debugowania
  void _debugProductsLoaded() {
    if (kDebugMode) {
      print(
        '📊 [ProductsManagementScreenAdvanced] DEBUG - Załadowano produkty:',
      );
      for (final product in _allProducts.take(5)) {
        print('  - ${product.name} (${product.productType.displayName})');
        print('    ID: ${product.id}');
        print('    Company: ${product.companyName}');
        print('    Total Value: ${product.totalValue}');
        print('    Investment Amount: ${product.investmentAmount}');
        print('    Remaining Capital: ${product.remainingCapital}');
        print('    Interest Rate: ${product.interestRate}');
        print('    Status: ${product.status.displayName}');
        print('    Created: ${product.createdAt}');
        print('    Investment Amount: ${product.investmentAmount}');
        print('    Has Additional Info: ${product.additionalInfo != null}');
        if (product.additionalInfo != null) {
          print(
            '    Additional Info Keys: ${product.additionalInfo!.keys.toList()}',
          );
        }
        print('---');
      }
    }
  }

  /// ✅ ZACHOWANE: Ta sama metoda obsługi parametrów URL
  void _handleRouteParameters() {
    final state = GoRouterState.of(context);
    final productName =
        widget.initialSearchProductName ??
        state.uri.queryParameters['productName'];
    final productType =
        widget.initialSearchProductType ??
        state.uri.queryParameters['productType'];
    final clientId =
        widget.initialSearchClientId ?? state.uri.queryParameters['clientId'];
    final clientName =
        widget.initialSearchClientName ??
        state.uri.queryParameters['clientName'];

    final investmentIdFromUrl = state.uri.queryParameters['investmentId'];

    if (kDebugMode) {
      print('🔍 [ProductsManagementScreenAdvanced] Parametry z URL/Widget:');
      print('🔍 highlightedProductId: ${widget.highlightedProductId}');
      print('🔍 highlightedInvestmentId: ${widget.highlightedInvestmentId}');
      print('🔍 investmentId z URL: $investmentIdFromUrl');
      print('🔍 productName: $productName');
      print('🔍 productType: $productType');
      print('🔍 clientId: $clientId');
      print('🔍 clientName: $clientName');
    }

    if (investmentIdFromUrl != null && investmentIdFromUrl.isNotEmpty) {
      _findAndShowProductForInvestment(investmentIdFromUrl);
      return;
    }

    if (widget.highlightedProductId != null ||
        widget.highlightedInvestmentId != null) {
      _highlightSpecificProduct();
      return;
    }

    if (productName != null && productName.isNotEmpty) {
      _searchController.text = productName;
      _applyFiltersAndSearch();
    }

    if (clientName != null && clientName.isNotEmpty) {
      _searchController.text = clientName;
      _applyFiltersAndSearch();
    }
  }

  /// ✅ ZACHOWANE: Ta sama metoda wyszukiwania inwestycji
  Future<void> _findAndShowProductForInvestment(String investmentId) async {
    if (kDebugMode) {
      print(
        '🔍 [ProductsManagementScreenAdvanced] Szukam produktu dla inwestycji: $investmentId',
      );
    }

    if (_isLoading) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return _isLoading;
      });
    }

    try {
      if (kDebugMode) {
        print('🔍 Wyszukuję inwestycję w Firebase...');
      }

      final investmentDoc = await FirebaseFirestore.instance
          .collection('investments')
          .doc(investmentId)
          .get();

      if (investmentDoc.exists) {
        final data = investmentDoc.data() as Map<String, dynamic>;
        final productId = data['productId'] as String?;

        if (productId != null) {
          // 🚀 NOWE: Użyj ProductManagementService do wyszukania produktu
          final searchResult = await _productManagementService.searchProducts(
            query: productId,
            useOptimizedMode: _useOptimizedMode,
          );

          if (searchResult.products.isNotEmpty) {
            final targetProduct = searchResult.products.first;
            _showOptimizedProductDetails(targetProduct, null);
          } else if (searchResult.deduplicatedProducts.isNotEmpty) {
            // Po prostu użyj pierwszego produktu regularnego
            if (_allProducts.isNotEmpty) {
              final unifiedProduct = _allProducts.first;
              _showProductDetails(unifiedProduct);
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Błąd wyszukiwania inwestycji: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nie znaleziono inwestycji: $investmentId'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  /// ✅ ZACHOWANE: Ta sama metoda podświetlania produktu
  void _highlightSpecificProduct() async {
    if (_allProducts.isEmpty) {
      if (kDebugMode) {
        print(
          '⚠️ Produkty nie są jeszcze załadowane - ustaw flagę do późniejszego użycia',
        );
      }
      return;
    }

    UnifiedProduct? targetProduct;

    if (widget.highlightedProductId != null) {
      targetProduct = _allProducts.firstWhere(
        (product) => product.id == widget.highlightedProductId,
        orElse: () => _allProducts.first,
      );

      if (targetProduct.id != widget.highlightedProductId) {
        if (kDebugMode) {
          print(
            '⚠️ Nie znaleziono produktu o ID: ${widget.highlightedProductId}',
          );
        }
        targetProduct = null;
      }
    }

    if (targetProduct == null && widget.highlightedInvestmentId != null) {
      if (kDebugMode) {
        print(
          '🔍 Szukam produktu po ID inwestycji: ${widget.highlightedInvestmentId}',
        );
      }

      for (final product in _allProducts) {
        // Sprawdź w oryginalnym obiekcie
        if (product.id == widget.highlightedInvestmentId) {
          targetProduct = product;
          break;
        }

        // Sprawdź w additionalInfo
        if (product.additionalInfo != null) {
          final additionalInfo = product.additionalInfo!;
          if (additionalInfo.containsKey('investmentIds')) {
            final investmentIds = additionalInfo['investmentIds'];
            if (investmentIds is List &&
                investmentIds.contains(widget.highlightedInvestmentId)) {
              targetProduct = product;
              break;
            }
          }
        }
      }
    }

    if (targetProduct != null) {
      setState(() {
        _searchController.clear();
        _filteredProducts = [targetProduct!];
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        _showProductDetails(targetProduct!);
      });
    }
  }

  /// 🚀 NOWE: Inicjalizacja serwisów - używamy ProductManagementService
  void _initializeServices() {
    _productManagementService = ProductManagementService();
    _cacheManagementService = CacheManagementService();
    _productInvestorsService = FirebaseFunctionsProductInvestorsService();
  }

  /// ✅ ZACHOWANE: Te same animacje
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
  }

  /// ✅ ZACHOWANE: Ten sam listener wyszukiwania
  void _setupSearchListener() {
    _searchController.addListener(() {
      _applyFiltersAndSearch();
    });
  }

  /// 🚀 NOWE: Ładowanie danych przez ProductManagementService
  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (kDebugMode) {
        print(
          '🚀 [ProductsManagementScreenAdvanced] Ładowanie danych przez ProductManagementService...',
        );
      }

      // 🚀 UŻYJ PRODUCTMANAGEMENTSERVICE
      final data = await _productManagementService.loadProductsData(
        sortField: _sortField,
        sortDirection: _sortDirection,
        showDeduplicatedView: _showDeduplicatedView,
        useOptimizedMode: _useOptimizedMode,
      );

      if (mounted) {
        setState(() {
          // Konwertuj dane z ProductManagementService na format zgodny ze starym ekranem
          _optimizedProducts = data.optimizedProducts;
          _filteredOptimizedProducts = data.optimizedProducts;
          _deduplicatedProducts = data.deduplicatedProducts;
          _filteredDeduplicatedProducts = data.deduplicatedProducts;

          // Konwertuj OptimizedProduct na UnifiedProduct dla kompatybilności
          _allProducts = data.optimizedProducts
              .map(_convertOptimizedToUnified)
              .toList();
          _filteredProducts = _allProducts;

          // Konwertuj statystyki jeśli dostępne
          if (data.globalStatistics != null) {
            _statistics = _convertGlobalStatsToFBStats(data.globalStatistics!);
          }

          _optimizedResult = OptimizedProductsResult(
            products: data.optimizedProducts,
            statistics: data.globalStatistics,
            totalProducts: data.optimizedProducts.length,
            hasMore: false,
          );

          _isLoading = false;
        });

        _applyFiltersAndSearch();
        _startAnimations();
        _debugProductsLoaded();

        if (widget.highlightedProductId != null ||
            widget.highlightedInvestmentId != null) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _highlightSpecificProduct();
          });
        }

        if (kDebugMode) {
          print(
            '✅ [ProductsManagementScreenAdvanced] Załadowano ${data.optimizedProducts.length} produktów',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ProductsManagementScreenAdvanced] Błąd ładowania: $e');
      }

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// 🚀 NOWE: Konwersja OptimizedProduct na UnifiedProduct
  UnifiedProduct _convertOptimizedToUnified(OptimizedProduct opt) {
    return UnifiedProduct(
      id: opt.id,
      name: opt.name,
      productType: opt.productType,
      companyId: opt.companyId,
      companyName: opt.companyName,
      totalValue: opt.totalValue,
      investmentAmount:
          opt.totalValue, // Używamy totalValue jako investmentAmount
      remainingCapital: opt.totalRemainingCapital,
      clientCount: opt.uniqueInvestors,
      status: opt.status,
      interestRate: opt.interestRate,
      createdAt: opt.earliestInvestmentDate,
      maturityDate: null, // OptimizedProduct może nie mieć maturityDate
      additionalInfo: opt.metadata,
    );
  }

  /// 🚀 NOWE: Konwersja GlobalProductStatistics na fb.ProductStatistics
  fb.ProductStatistics _convertGlobalStatsToFBStats(
    GlobalProductStatistics global,
  ) {
    return fb.ProductStatistics(
      totalProducts: global.totalProducts,
      totalValue: global.totalValue,
      totalInvestments: global.totalInvestments,
      uniqueInvestors: global.uniqueInvestors,
      averageInvestment: global.averageInvestment,
      typeDistribution: _convertTypeDistribution(global.typeDistribution),
      monthlyGrowth: 0.0, // Nie dostępne w GlobalProductStatistics
      topPerformers: [], // Nie dostępne w GlobalProductStatistics
    );
  }

  /// ✅ ZACHOWANE: Ta sama konwersja dystrybucji typów
  Map<UnifiedProductType, int> _convertTypeDistribution(
    Map<String, int> typeDistribution,
  ) {
    final Map<UnifiedProductType, int> result = {};
    for (final entry in typeDistribution.entries) {
      final type = _mapStringToUnifiedProductType(entry.key);
      if (type != null) {
        result[type] = entry.value;
      }
    }
    return result;
  }

  /// ✅ ZACHOWANE: To samo mapowanie typów
  UnifiedProductType? _mapStringToUnifiedProductType(String type) {
    switch (type.toLowerCase()) {
      case 'bonds':
      case 'obligacje':
        return UnifiedProductType.bonds;
      case 'shares':
      case 'akcje':
        return UnifiedProductType.shares;
      case 'loans':
      case 'pożyczki':
        return UnifiedProductType.loans;
      case 'apartments':
      case 'mieszkania':
        return UnifiedProductType.apartments;
      default:
        return null;
    }
  }

  /// ✅ ZACHOWANE: Te same animacje
  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  /// 🚀 NOWE: Odświeżanie przez ProductManagementService + opcjonalne cache management
  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    HapticFeedback.mediumImpact();

    try {
      // 🧹 Opcjonalnie wyczyść cache przed odświeżeniem
      if (kDebugMode) {
        print(
          '🔄 [ProductsManagementScreenAdvanced] Odświeżanie przez ProductManagementService...',
        );
      }

      await _productManagementService.refreshCache();
      await _loadInitialData();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Błąd odświeżania: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd odświeżania: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // ✅ ZACHOWANE: Wszystkie metody filtrowania i sortowania pozostają identyczne
  // (kontynuacja w następnym kroku...)

  /// ✅ ZACHOWANE: Ta sama metoda filtrowania i wyszukiwania
  void _applyFiltersAndSearch() {
    if (kDebugMode) {
      print(
        '🔄 [ProductsManagementScreenAdvanced] Aplikuję filtry i wyszukiwanie...',
      );
    }

    if (_useOptimizedMode) {
      _applyFiltersAndSearchForOptimizedProducts();
    } else if (_showDeduplicatedView) {
      _applyFiltersAndSearchForDeduplicatedProducts();
    } else {
      _applyFiltersAndSearchForRegularProducts();
    }
  }

  /// 🚀 NOWE: Filtrowanie dla OptimizedProduct (identyczne jak w oryginalnym ekranie)
  void _applyFiltersAndSearchForOptimizedProducts() {
    List<OptimizedProduct> filtered = List.from(_optimizedProducts);

    final searchText = _searchController.text.trim();
    if (searchText.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(searchText.toLowerCase()) ||
            product.companyName.toLowerCase().contains(
              searchText.toLowerCase(),
            ) ||
            product.productType.displayName.toLowerCase().contains(
              searchText.toLowerCase(),
            );
      }).toList();
    }

    // Aplikuj filtry z ProductFilterCriteria
    if (_filterCriteria.productTypes != null &&
        _filterCriteria.productTypes!.isNotEmpty) {
      filtered = filtered.where((product) {
        return _filterCriteria.productTypes!.contains(product.productType);
      }).toList();
    }

    if (_filterCriteria.statuses != null &&
        _filterCriteria.statuses!.isNotEmpty) {
      filtered = filtered.where((product) {
        return _filterCriteria.statuses!.contains(product.status);
      }).toList();
    }

    if (_filterCriteria.companyName != null &&
        _filterCriteria.companyName!.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.companyName.toLowerCase().contains(
          _filterCriteria.companyName!.toLowerCase(),
        );
      }).toList();
    }

    if (_filterCriteria.minInvestmentAmount != null) {
      filtered = filtered.where((product) {
        return product.totalValue >= _filterCriteria.minInvestmentAmount!;
      }).toList();
    }

    if (_filterCriteria.maxInvestmentAmount != null) {
      filtered = filtered.where((product) {
        return product.totalValue <= _filterCriteria.maxInvestmentAmount!;
      }).toList();
    }

    if (_filterCriteria.minInterestRate != null) {
      filtered = filtered.where((product) {
        return (product.interestRate ?? 0.0) >=
            _filterCriteria.minInterestRate!;
      }).toList();
    }

    if (_filterCriteria.maxInterestRate != null) {
      filtered = filtered.where((product) {
        return (product.interestRate ?? 0.0) <=
            _filterCriteria.maxInterestRate!;
      }).toList();
    }

    if (_filterCriteria.createdAfter != null) {
      filtered = filtered.where((product) {
        return product.earliestInvestmentDate.isAfter(
          _filterCriteria.createdAfter!,
        );
      }).toList();
    }

    if (_filterCriteria.createdBefore != null) {
      filtered = filtered.where((product) {
        return product.earliestInvestmentDate.isBefore(
          _filterCriteria.createdBefore!,
        );
      }).toList();
    }

    _sortOptimizedProducts(filtered);

    setState(() {
      _filteredOptimizedProducts = filtered;
    });
  }

  /// 🚀 NOWE: Sortowanie OptimizedProduct
  void _sortOptimizedProducts(List<OptimizedProduct> products) {
    products.sort((a, b) {
      dynamic valueA, valueB;

      switch (_sortField) {
        case ProductSortField.name:
          valueA = a.name;
          valueB = b.name;
          break;
        case ProductSortField.totalValue:
          valueA = a.totalValue;
          valueB = b.totalValue;
          break;
        case ProductSortField.investmentAmount:
          valueA = a.totalValue;
          valueB = b.totalValue;
          break;
        case ProductSortField.createdAt:
          valueA = a.earliestInvestmentDate;
          valueB = b.earliestInvestmentDate;
          break;
        case ProductSortField.type:
          valueA = a.productType.displayName;
          valueB = b.productType.displayName;
          break;
        case ProductSortField.companyName:
          valueA = a.companyName;
          valueB = b.companyName;
          break;
        case ProductSortField.interestRate:
          valueA = a.interestRate ?? 0.0;
          valueB = b.interestRate ?? 0.0;
          break;
        default:
          valueA = a.name;
          valueB = b.name;
      }

      int comparison;
      if (valueA is String && valueB is String) {
        comparison = valueA.compareTo(valueB);
      } else if (valueA is num && valueB is num) {
        comparison = valueA.compareTo(valueB);
      } else if (valueA is DateTime && valueB is DateTime) {
        comparison = valueA.compareTo(valueB);
      } else {
        comparison = valueA.toString().compareTo(valueB.toString());
      }

      return _sortDirection == SortDirection.ascending
          ? comparison
          : -comparison;
    });
  }

  /// ✅ ZACHOWANE: Filtrowanie dla DeduplicatedProduct (kopiowane z oryginału)
  void _applyFiltersAndSearchForDeduplicatedProducts() {
    List<DeduplicatedProduct> filtered = List.from(_deduplicatedProducts);

    final searchText = _searchController.text.trim();
    if (searchText.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(searchText.toLowerCase()) ||
            product.companyName.toLowerCase().contains(
              searchText.toLowerCase(),
            ) ||
            product.productType.displayName.toLowerCase().contains(
              searchText.toLowerCase(),
            );
      }).toList();
    }

    // Aplikuj filtry z ProductFilterCriteria
    if (_filterCriteria.productTypes != null &&
        _filterCriteria.productTypes!.isNotEmpty) {
      filtered = filtered.where((product) {
        return _filterCriteria.productTypes!.contains(product.productType);
      }).toList();
    }

    if (_filterCriteria.statuses != null &&
        _filterCriteria.statuses!.isNotEmpty) {
      filtered = filtered.where((product) {
        return _filterCriteria.statuses!.contains(product.status);
      }).toList();
    }

    if (_filterCriteria.companyName != null &&
        _filterCriteria.companyName!.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.companyName.toLowerCase().contains(
          _filterCriteria.companyName!.toLowerCase(),
        );
      }).toList();
    }

    if (_filterCriteria.minInvestmentAmount != null) {
      filtered = filtered.where((product) {
        return product.totalValue >= _filterCriteria.minInvestmentAmount!;
      }).toList();
    }

    if (_filterCriteria.maxInvestmentAmount != null) {
      filtered = filtered.where((product) {
        return product.totalValue <= _filterCriteria.maxInvestmentAmount!;
      }).toList();
    }

    // Sortowanie deduplikowanych produktów
    filtered.sort((a, b) {
      dynamic valueA, valueB;

      switch (_sortField) {
        case ProductSortField.name:
          valueA = a.name;
          valueB = b.name;
          break;
        case ProductSortField.totalValue:
          valueA = a.totalValue;
          valueB = b.totalValue;
          break;
        case ProductSortField.investmentAmount:
          valueA = a.totalValue;
          valueB = b.totalValue;
          break;
        case ProductSortField.createdAt:
          valueA = a.earliestInvestmentDate;
          valueB = b.earliestInvestmentDate;
          break;
        case ProductSortField.type:
          valueA = a.productType.displayName;
          valueB = b.productType.displayName;
          break;
        case ProductSortField.companyName:
          valueA = a.companyName;
          valueB = b.companyName;
          break;
        case ProductSortField.interestRate:
          valueA = a.interestRate ?? 0.0;
          valueB = b.interestRate ?? 0.0;
          break;
        default:
          valueA = a.name;
          valueB = b.name;
      }

      int comparison;
      if (valueA is String && valueB is String) {
        comparison = valueA.compareTo(valueB);
      } else if (valueA is num && valueB is num) {
        comparison = valueA.compareTo(valueB);
      } else if (valueA is DateTime && valueB is DateTime) {
        comparison = valueA.compareTo(valueB);
      } else {
        comparison = valueA.toString().compareTo(valueB.toString());
      }

      return _sortDirection == SortDirection.ascending
          ? comparison
          : -comparison;
    });

    setState(() {
      _filteredDeduplicatedProducts = filtered;
    });
  }

  /// ✅ ZACHOWANE: Filtrowanie dla UnifiedProduct (kopiowane z oryginału)
  void _applyFiltersAndSearchForRegularProducts() {
    List<UnifiedProduct> filtered = List.from(_allProducts);

    final searchText = _searchController.text.trim();
    if (searchText.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(searchText.toLowerCase()) ||
            (product.companyName?.toLowerCase().contains(
                  searchText.toLowerCase(),
                ) ??
                false) ||
            product.productType.displayName.toLowerCase().contains(
              searchText.toLowerCase(),
            );
      }).toList();
    }

    // Zastosuj filtry
    filtered = filtered.where(_filterCriteria.matches).toList();

    // Zastosuj sortowanie
    _sortProducts(filtered);

    setState(() {
      _filteredProducts = filtered;
    });
  }

  /// ✅ ZACHOWANE: Sortowanie UnifiedProduct (kopiowane z oryginału)
  void _sortProducts(List<UnifiedProduct> products) {
    products.sort((a, b) {
      dynamic valueA, valueB;

      switch (_sortField) {
        case ProductSortField.name:
          valueA = a.name;
          valueB = b.name;
          break;
        case ProductSortField.totalValue:
          valueA = a.investmentAmount;
          valueB = b.investmentAmount;
          break;
        case ProductSortField.investmentAmount:
          valueA = a.investmentAmount;
          valueB = b.investmentAmount;
          break;
        case ProductSortField.createdAt:
          valueA = a.createdAt;
          valueB = b.createdAt;
          break;
        case ProductSortField.type:
          valueA = a.productType.displayName;
          valueB = b.productType.displayName;
          break;
        case ProductSortField.companyName:
          valueA = a.companyName ?? '';
          valueB = b.companyName ?? '';
          break;
        case ProductSortField.interestRate:
          valueA = a.interestRate ?? 0.0;
          valueB = b.interestRate ?? 0.0;
          break;
        default:
          valueA = a.name;
          valueB = b.name;
      }

      int comparison;
      if (valueA is String && valueB is String) {
        comparison = valueA.compareTo(valueB);
      } else if (valueA is num && valueB is num) {
        comparison = valueA.compareTo(valueB);
      } else if (valueA is DateTime && valueB is DateTime) {
        comparison = valueA.compareTo(valueB);
      } else {
        comparison = valueA.toString().compareTo(valueB.toString());
      }

      return _sortDirection == SortDirection.ascending
          ? comparison
          : -comparison;
    });
  }

  /// ✅ ZACHOWANE: Callback filtrów (identyczne z oryginału)
  void _onFilterChanged(ProductFilterCriteria criteria) {
    setState(() {
      _filterCriteria = criteria;
    });
    _applyFiltersAndSearch();
  }

  /// ✅ ZACHOWANE: Callback sortowania (identyczne z oryginału)
  void _onSortChanged(ProductSortField field, SortDirection direction) {
    setState(() {
      _sortField = field;
      _sortDirection = direction;
    });
    _applyFiltersAndSearch();
  }

  /// ✅ ZACHOWANE: Przełączanie trybu widoku
  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == ViewMode.list ? ViewMode.grid : ViewMode.list;
    });
    HapticFeedback.lightImpact();
  }

  /// 🚀 NOWE: Metody wyświetlania szczegółów (używające tych samych widgetów)
  void _showProductDetails(UnifiedProduct product) {
    if (kDebugMode) {
      print(
        '📱 [ProductsManagementScreenAdvanced] Pokazuję szczegóły produktu:',
      );
      print('  - Nazwa: "${product.name}"');
      print('  - Typ: ${product.productType.displayName}');
      print('  - ID: ${product.id}');
    }

    showDialog(
      context: context,
      builder: (context) => EnhancedProductDetailsDialog(
        product: product,
        onShowInvestors: () => _showProductInvestors(product),
      ),
    );
  }

  /// 🚀 NOWE: Szczegóły OptimizedProduct (konwertowane na UnifiedProduct)
  void _showOptimizedProductDetails(
    OptimizedProduct product,
    String? highlightInvestmentId,
  ) {
    if (kDebugMode) {
      print(
        '📱 [ProductsManagementScreenAdvanced] Pokazuję szczegóły zoptymalizowanego produktu:',
      );
      print('  - Nazwa: "${product.name}"');
      print('  - Typ: ${product.productType.displayName}');
      print('  - ID: ${product.id}');
      print('  - Highlight Investment ID: $highlightInvestmentId');
    }

    // Konwertuj OptimizedProduct na UnifiedProduct dla kompatybilności
    final unifiedProduct = _convertOptimizedToUnified(product);

    showDialog(
      context: context,
      builder: (context) => EnhancedProductDetailsDialog(
        product: unifiedProduct,
        onShowInvestors: () => _showProductInvestors(unifiedProduct),
      ),
    );
  }

  /// ✅ ZACHOWANE: Wyświetlanie inwestorów (identyczne z oryginału)
  void _showProductInvestors(UnifiedProduct product) async {
    try {
      final result = await _productInvestorsService.getProductInvestors(
        productId: product.id,
        productName: product.name,
      );

      if (result.investors.isEmpty) {
        _showEmptyInvestorsDialog(product, result);
      } else {
        _showInvestorsResultDialog(product, result);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Błąd pobierania inwestorów: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd pobierania inwestorów: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  /// ✅ ZACHOWANE: Dialog pustych inwestorów (identyczne z oryginału)
  void _showEmptyInvestorsDialog(
    UnifiedProduct product,
    ProductInvestorsResult result,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.warningColor),
            const SizedBox(width: 8),
            const Text('Brak inwestorów'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Produkt: ${product.name}'),
            const SizedBox(height: 8),
            const Text('Ten produkt nie ma jeszcze przypisanych inwestorów.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warningColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statystyki produktu:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Łączna wartość: ${_formatCurrency(product.investmentAmount)}',
                  ),
                  Text('• Typ: ${product.productType.displayName}'),
                  Text('• Firma: ${product.companyName ?? 'Nieznana'}'),
                  if (product.interestRate != null)
                    Text(
                      '• Oprocentowanie: ${product.interestRate!.toStringAsFixed(2)}%',
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  /// ✅ ZACHOWANE: Dialog z inwestorami (identyczne z oryginału)
  void _showInvestorsResultDialog(
    UnifiedProduct product,
    ProductInvestorsResult result,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.people, color: AppTheme.primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inwestorzy produktu',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Statistyki
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.premiumCardDecoration,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Inwestorzy',
                      '${result.investors.length}',
                      Icons.people,
                    ),
                    _buildStatItem(
                      'Łączna wartość',
                      _formatCurrency(result.statistics.totalCapital),
                      Icons.attach_money,
                    ),
                    _buildStatItem(
                      'Średnia inwestycja',
                      _formatCurrency(result.statistics.averageCapital),
                      Icons.trending_up,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lista inwestorów
              Expanded(
                child: ListView.builder(
                  itemCount: result.investors.length,
                  itemBuilder: (context, index) {
                    final investor = result.investors[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            investor.client.name.isNotEmpty
                                ? investor.client.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(investor.client.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inwestycja: ${_formatCurrency(investor.totalInvestmentAmount)}',
                            ),
                            if (investor.client.email.isNotEmpty)
                              Text('Email: ${investor.client.email}'),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${investor.investments.length} inwestycji',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              investor.client.votingStatus.displayName,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: _getVotingStatusColor(
                                      investor.client.votingStatus,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ ZACHOWANE: Pomocnicze metody formatowania
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M zł';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k zł';
    } else {
      return '${value.toStringAsFixed(0)} zł';
    }
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return Colors.green;
      case VotingStatus.no:
        return Colors.red;
      case VotingStatus.abstain:
        return Colors.orange;
      case VotingStatus.undecided:
        return AppTheme.textSecondary;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
