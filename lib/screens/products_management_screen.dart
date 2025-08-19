import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models_and_services.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_functions_products_service.dart' as fb;
import '../services/unified_product_service.dart' as unified;
import '../services/optimized_product_service.dart'; // 🚀 NOWY IMPORT
import '../services/product_management_service.dart'; // 🚀 NOWY: Centralny serwis zarządzania
import '../services/cache_management_service.dart'; // 🚀 NOWY: Zarządzanie cache
import '../services/unified_investor_count_service.dart'; // 🚀 NOWY: Serwis liczby inwestorów
import '../adapters/product_statistics_adapter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/premium_loading_widget.dart';
import '../widgets/premium_error_widget.dart';
import '../widgets/product_card_widget.dart';
import '../widgets/product_stats_widget.dart';
import '../widgets/product_filter_widget.dart';
import '../widgets/metropolitan_loading_system.dart';
import '../widgets/dialogs/product_details_dialog.dart';
import '../widgets/dialogs/enhanced_investor_email_dialog.dart';
import '../widgets/common/synchronized_product_values_widget.dart'; // 🚀 NOWY: Zsynchronizowane wartości

// RBAC: wspólny tooltip dla braku uprawnień
const String kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

/// Ekran zarządzania produktami pobieranymi z kolekcji 'investments'
/// Wykorzystuje FirebaseFunctionsProductsService do server-side przetwarzania danych
class ProductsManagementScreen extends StatefulWidget {
  // Parametry do wyróżnienia konkretnego produktu lub inwestycji
  final String? highlightedProductId;
  final String? highlightedInvestmentId;

  // Parametry do początkowego wyszukiwania (fallback)
  final String? initialSearchProductName;
  final String? initialSearchProductType;
  final String? initialSearchClientId;
  final String? initialSearchClientName;

  const ProductsManagementScreen({
    super.key,
    this.highlightedProductId,
    this.highlightedInvestmentId,
    this.initialSearchProductName,
    this.initialSearchProductType,
    this.initialSearchClientId,
    this.initialSearchClientName,
  });

  @override
  State<ProductsManagementScreen> createState() =>
      _ProductsManagementScreenState();
}

class _ProductsManagementScreenState extends State<ProductsManagementScreen>
    with TickerProviderStateMixin {
  late final FirebaseFunctionsProductsService _productService;
  late final UltraPreciseProductInvestorsService
  _ultraPreciseInvestorsService; // 🚀 NOWY: Ultra-precyzyjny serwis
  late final DeduplicatedProductService _deduplicatedProductService;
  late final OptimizedProductService _optimizedProductService; // 🚀 NOWY SERWIS
  late final ProductManagementService
  _productManagementService; // 🚀 NOWY: Centralny serwis
  late final CacheManagementService
  _cacheManagementService; // 🚀 NOWY: Zarządzanie cache
  late final AnalyticsMigrationService
  _analyticsMigrationService; // 🚀 NOWY: Serwis migracji analityki
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // Stan ekranu
  List<UnifiedProduct> _allProducts = [];
  List<UnifiedProduct> _filteredProducts = [];
  List<DeduplicatedProduct> _deduplicatedProducts = [];
  List<DeduplicatedProduct> _filteredDeduplicatedProducts = [];
  List<OptimizedProduct> _optimizedProducts = []; // 🚀 NOWY STAN
  List<OptimizedProduct> _filteredOptimizedProducts = []; // 🚀 NOWY STAN
  fb.ProductStatistics? _statistics;
  UnifiedProductsMetadata? _metadata;
  OptimizedProductsResult? _optimizedResult; // 🚀 NOWY REZULTAT
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  // RBAC getter
  bool get canEdit => Provider.of<AuthProvider>(context, listen: false).isAdmin;

  // Kontrolery wyszukiwania i filtrowania
  final TextEditingController _searchController = TextEditingController();
  ProductFilterCriteria _filterCriteria = const ProductFilterCriteria();
  ProductSortField _sortField = ProductSortField.createdAt;
  SortDirection _sortDirection = SortDirection.descending;

  // Kontrola wyświetlania
  bool _showFilters = false;
  bool _showStatistics = true;
  ViewMode _viewMode = ViewMode.list;
  bool _showDeduplicatedView = true; // Domyślnie pokazuj deduplikowane produkty
  bool _useOptimizedMode =
      true; // 🚀 NOWA FLAGA - używaj zoptymalizowanego trybu
  bool _useProductManagementService =
      false; // 🚀 NOWA FLAGA - używaj centralnego serwisu

  // Email functionality
  bool _isSelectionMode = false;
  Set<String> _selectedProductIds = <String>{};

  // Gettery dla wybranych produktów
  List<DeduplicatedProduct> get _selectedProducts {
    return _filteredDeduplicatedProducts
        .where((product) => _selectedProductIds.contains(product.id))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _initializeService();
    _initializeAnimations();
    _loadInitialData();
    _setupSearchListener();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Opóźnienie żeby dane zostały załadowane przed obsługą parametrów
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _handleRouteParameters();
      }
    });
  }

  /// Debugowanie - wypisz informacje o produktach po załadowaniu
  void _debugProductsLoaded() {
    if (kDebugMode) {
      print('📊 [ProductsManagementScreen] DEBUG - Załadowano produkty:');
      for (final product in _allProducts.take(5)) {
        print('📊 [ProductsManagementScreen] - ${product.id}: ${product.name}');
        print(
          '📊 [ProductsManagementScreen]   - Typ: ${product.productType} (${product.productType.displayName})',
        );
        print(
          '📊 [ProductsManagementScreen]   - Collection: ${product.productType.collectionName}',
        );
        print(
          '📊 [ProductsManagementScreen]   originalProduct: ${product.originalProduct?.runtimeType}',
        );
        if (product.originalProduct is Investment) {
          final inv = product.originalProduct as Investment;
          print('📊 [ProductsManagementScreen]   investmentId: ${inv.id}');
          print(
            '📊 [ProductsManagementScreen]   - Original Investment Type: ${inv.productType} (${inv.productType.runtimeType})',
          );
        }
      }
    }
  }

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

    // 🎯 NOWY: Obsługa parametru investmentId z URL
    final investmentIdFromUrl = state.uri.queryParameters['investmentId'];

    print('🔍 [ProductsManagementScreen] Parametry z URL/Widget:');
    print(
      '🔍 [ProductsManagementScreen] highlightedProductId: ${widget.highlightedProductId}',
    );
    print(
      '🔍 [ProductsManagementScreen] highlightedInvestmentId: ${widget.highlightedInvestmentId}',
    );
    print(
      '🔍 [ProductsManagementScreen] investmentId z URL: $investmentIdFromUrl',
    );
    print('🔍 [ProductsManagementScreen] productName: $productName');
    print('🔍 [ProductsManagementScreen] productType: $productType');
    print('🔍 [ProductsManagementScreen] clientId: $clientId');
    print('🔍 [ProductsManagementScreen] clientName: $clientName');

    // 🎯 PRIORYTET: Jeśli mamy investmentId z URL, użyj go
    if (investmentIdFromUrl != null && investmentIdFromUrl.isNotEmpty) {
      print(
        '🎯 [ProductsManagementScreen] Znaleziono investmentId z URL, szukam produktu...',
      );
      _findAndShowProductForInvestment(investmentIdFromUrl);
      return;
    }

    // Jeśli mamy konkretne ID produktu lub inwestycji, wyróżnij go
    if (widget.highlightedProductId != null ||
        widget.highlightedInvestmentId != null) {
      print(
        '🎯 [ProductsManagementScreen] Wyróżniam konkretny produkt/inwestycję',
      );
      _highlightSpecificProduct();
      return;
    }

    // Obsługa wyszukiwania po nazwie produktu (fallback)
    if (productName != null && productName.isNotEmpty) {
      print(
        '🔍 [ProductsManagementScreen] Ustawianie wyszukiwania: $productName',
      );
      _searchController.text = productName;
      _applyFiltersAndSearch();
    }

    // Obsługa wyszukiwania po nazwie klienta (fallback)
    if (clientName != null && clientName.isNotEmpty) {
      print(
        '🔍 [ProductsManagementScreen] Wyszukiwanie po kliencie: $clientName',
      );
      _searchController.text = clientName;
      _applyFiltersAndSearch();
    }

    // TODO: Dodać obsługę filtrowania po productType
    if (productType != null && productType.isNotEmpty) {
      print('🔍 [ProductsManagementScreen] Typ produktu: $productType');
      // Wymagałoby rozszerzenia ProductFilterCriteria o typ produktu
      // setState(() {
      //   _filterCriteria = _filterCriteria.copyWith(
      //     productTypes: [ProductType.fromString(productType)],
      //   );
      // });
      // _applyFiltersAndSearch();
    }
  }

  /// 🎯 NOWA METODA: Znajdź i pokaż produkt dla konkretnej inwestycji
  Future<void> _findAndShowProductForInvestment(String investmentId) async {
    print(
      '🔍 [ProductsManagementScreen] Szukam produktu dla inwestycji: $investmentId',
    );

    // Poczekaj aż dane zostaną załadowane
    if (_isLoading) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return _isLoading;
      });
    }

    // 🆕 KROK 1: Znajdź samą inwestycję w Firebase, aby uzyskać informacje o produkcie
    try {
      print('🔍 [ProductsManagementScreen] Wyszukuję inwestycję w Firebase...');
      final investmentDoc = await FirebaseFirestore.instance
          .collection('investments')
          .doc(investmentId)
          .get();

      if (investmentDoc.exists) {
        final investmentData = investmentDoc.data()!;
        final productName = investmentData['productName'] ?? '';
        final companyId = investmentData['companyId'] ?? '';
        final productType = investmentData['productType'] ?? '';

        print('🔍 [ProductsManagementScreen] Znaleziono inwestycję:');
        print('  - Product Name: $productName');
        print('  - Company ID: $companyId');
        print('  - Product Type: $productType');
        print('  - Investment ID: $investmentId');

        // KROK 2: Szukaj produktu na podstawie nazwy produktu i firmy
        bool foundProduct = false;

        // Szukaj w deduplikowanych produktach
        if (_deduplicatedProducts.isNotEmpty) {
          for (final product in _deduplicatedProducts) {
            bool nameMatches =
                product.name.trim().toLowerCase() ==
                productName.trim().toLowerCase();
            bool companyMatches =
                product.companyId == companyId ||
                product.companyName == companyId;

            if (nameMatches && companyMatches) {
              print(
                '✅ [ProductsManagementScreen] Znaleziono deduplikowany produkt: ${product.name}',
              );

              _searchController.text = product.name;
              _applyFiltersAndSearch();

              Future.delayed(const Duration(milliseconds: 500), () {
                _showDeduplicatedProductDetails(product);
              });
              foundProduct = true;
              return;
            }
          }
        }

        // Szukaj w zoptymalizowanych produktach
        if (_useOptimizedMode &&
            _optimizedProducts.isNotEmpty &&
            !foundProduct) {
          for (final product in _optimizedProducts) {
            bool nameMatches =
                product.name.trim().toLowerCase() ==
                productName.trim().toLowerCase();
            bool companyMatches =
                product.companyId == companyId ||
                product.companyName == companyId;

            if (nameMatches && companyMatches) {
              print(
                '✅ [ProductsManagementScreen] Znaleziono zoptymalizowany produkt: ${product.name}',
              );

              _searchController.text = product.name;
              _applyFiltersAndSearch();

              Future.delayed(const Duration(milliseconds: 500), () {
                _showOptimizedProductDetails(product, investmentId);
              });
              foundProduct = true;
              return;
            }
          }
        }

        // Szukaj w standardowych produktach
        if (!foundProduct) {
          for (final product in _allProducts) {
            bool nameMatches =
                product.name.trim().toLowerCase() ==
                productName.trim().toLowerCase();
            bool companyMatches =
                (product.companyId != null && product.companyId == companyId) ||
                (product.companyName != null &&
                    product.companyName == companyId);

            if (nameMatches && companyMatches) {
              print(
                '✅ [ProductsManagementScreen] Znaleziono standardowy produkt: ${product.name}',
              );

              _searchController.text = product.name;
              _applyFiltersAndSearch();

              Future.delayed(const Duration(milliseconds: 500), () {
                _showProductDetails(product);
              });
              foundProduct = true;
              return;
            }
          }
        }

        if (!foundProduct) {
          print(
            '❌ [ProductsManagementScreen] Nie znaleziono produktu dla inwestycji: $investmentId, chociaż w firebase jest prawidłowy zapis w \'investments\'',
          );
          print(
            '📊 [ProductsManagementScreen] Nazwa produktu: "$productName", Firma: "$companyId"',
          );
          print('📊 [ProductsManagementScreen] Dostępne produkty:');

          if (_deduplicatedProducts.isNotEmpty) {
            print('  Deduplikowane (${_deduplicatedProducts.length}):');
            for (int i = 0; i < 10 && i < _deduplicatedProducts.length; i++) {
              final p = _deduplicatedProducts[i];
              print(
                '    - "${p.name}" | "${p.companyId}" | "${p.companyName}"',
              );
            }
          }

          if (_optimizedProducts.isNotEmpty) {
            print('  Zoptymalizowane (${_optimizedProducts.length}):');
            for (int i = 0; i < 10 && i < _optimizedProducts.length; i++) {
              final p = _optimizedProducts[i];
              print(
                '    - "${p.name}" | "${p.companyId}" | "${p.companyName}"',
              );
            }
          }

          // Pokazuj komunikat o nieznalezieniu
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Produkt "$productName" nie został znaleziony w załadowanych danych',
                ),
                backgroundColor: Colors.orange,
                action: SnackBarAction(
                  label: 'Odśwież',
                  onPressed: () => _loadInitialData(),
                ),
              ),
            );
          }
        }
      } else {
        print(
          '❌ [ProductsManagementScreen] Inwestycja $investmentId nie istnieje w Firebase',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Inwestycja $investmentId nie została znaleziona'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print(
        '❌ [ProductsManagementScreen] Błąd podczas wyszukiwania inwestycji: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas wyszukiwania: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Wyróżnia konkretny produkt na podstawie ID produktu lub inwestycji
  void _highlightSpecificProduct() async {
    if (_allProducts.isEmpty) {
      print(
        '🎯 [ProductsManagementScreen] Produkty jeszcze nie załadowane, czekam...',
      );
      // Jeśli produkty nie są jeszcze załadowane, ustaw flagę do późniejszego użycia
      return;
    }

    UnifiedProduct? targetProduct;

    // Szukaj po ID produktu
    if (widget.highlightedProductId != null) {
      targetProduct = _allProducts.firstWhere(
        (product) => product.id == widget.highlightedProductId,
        orElse: () => _allProducts.first,
      );

      if (targetProduct.id != widget.highlightedProductId) {
        print(
          '❌ [ProductsManagementScreen] Nie znaleziono produktu o ID: ${widget.highlightedProductId}',
        );
        targetProduct = null;
      } else {
        print(
          '✅ [ProductsManagementScreen] Znaleziono produkt: ${targetProduct.name}',
        );
      }
    }

    // Szukaj po ID inwestycji (w oryginalnym obiekcie lub additionalInfo)
    if (targetProduct == null && widget.highlightedInvestmentId != null) {
      print(
        '🔍 [ProductsManagementScreen] Szukam produktu dla inwestycji: ${widget.highlightedInvestmentId}',
      );

      for (final product in _allProducts) {
        bool found = false;

        // Sprawdź czy oryginalny produkt to Investment
        if (product.originalProduct is Investment) {
          final investment = product.originalProduct as Investment;
          if (investment.id == widget.highlightedInvestmentId) {
            targetProduct = product;
            found = true;
            print(
              '✅ [ProductsManagementScreen] Znaleziono produkt dla inwestycji (Investment): ${product.name}',
            );
          }
        }
        // Sprawdź czy oryginalny produkt to Map z Firebase Functions
        else if (product.originalProduct is Map<String, dynamic>) {
          final originalData = product.originalProduct as Map<String, dynamic>;
          if (originalData['id'] == widget.highlightedInvestmentId ||
              originalData['investment_id'] == widget.highlightedInvestmentId) {
            targetProduct = product;
            found = true;
            print(
              '✅ [ProductsManagementScreen] Znaleziono produkt dla inwestycji (Map): ${product.name}',
            );
          }
        }

        // Sprawdź w additionalInfo jako backup
        if (!found &&
            (product.additionalInfo['investmentId'] ==
                    widget.highlightedInvestmentId ||
                product.additionalInfo['id'] ==
                    widget.highlightedInvestmentId)) {
          targetProduct = product;
          found = true;
          print(
            '✅ [ProductsManagementScreen] Znaleziono produkt w additionalInfo: ${product.name}',
          );
        }

        // Sprawdź ID produktu jako backup (może to być to samo ID)
        if (!found && product.id == widget.highlightedInvestmentId) {
          targetProduct = product;
          found = true;
          print(
            '✅ [ProductsManagementScreen] Znaleziono produkt po ID produktu: ${product.name}',
          );
        }

        if (found) break;
      }

      if (targetProduct == null) {
        print(
          '❌ [ProductsManagementScreen] Nie znaleziono produktu dla inwestycji: ${widget.highlightedInvestmentId}',
        );

        // Dodaj debug informacje o dostępnych produktach
        print('🔍 [ProductsManagementScreen] Dostępne produkty (pierwsze 5):');
        for (int i = 0; i < _allProducts.length && i < 5; i++) {
          final p = _allProducts[i];
          if (p.originalProduct is Investment) {
            final inv = p.originalProduct as Investment;
            print('  - [${i}] Investment ID: ${inv.id}, Name: ${p.name}');
          } else if (p.originalProduct is Map<String, dynamic>) {
            final data = p.originalProduct as Map<String, dynamic>;
            print(
              '  - [${i}] Server Data ID: ${data['id']}, ClientID: ${data['clientId']}, Name: ${p.name}',
            );
          } else {
            print('  - [${i}] UnifiedProduct ID: ${p.id}, Name: ${p.name}');
          }
        }
      }
    }

    if (targetProduct != null) {
      // Wyczyść filtry i wyszukiwanie aby pokazać tylko ten produkt
      setState(() {
        _searchController.text = '';
        _filteredProducts = [targetProduct!];
      });

      // Automatycznie otwórz szczegóły tego produktu po krótkim opóżnieniu
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showProductDetails(targetProduct!);
        }
      });
    } else if (widget.initialSearchProductName != null &&
        widget.initialSearchProductName!.isNotEmpty) {
      // Fallback: wyszukaj po nazwie produktu
      print(
        '🔍 [ProductsManagementScreen] Fallback: szukam po nazwie: ${widget.initialSearchProductName}',
      );

      final productsByName = _allProducts
          .where(
            (product) => product.name.toLowerCase().contains(
              widget.initialSearchProductName!.toLowerCase(),
            ),
          )
          .toList();

      if (productsByName.isNotEmpty) {
        print(
          '✅ [ProductsManagementScreen] Znaleziono ${productsByName.length} produktów po nazwie',
        );
        setState(() {
          _searchController.text = widget.initialSearchProductName!;
          _filteredProducts = productsByName;
        });

        // Jeśli znaleziono tylko jeden produkt, otwórz jego szczegóły
        if (productsByName.length == 1) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _showProductDetails(productsByName.first);
            }
          });
        }
      }
    }
  }

  void _initializeService() {
    _productService = FirebaseFunctionsProductsService();
    _ultraPreciseInvestorsService =
        UltraPreciseProductInvestorsService(); // 🚀 NOWY: Ultra-precyzyjny serwis
    _deduplicatedProductService = DeduplicatedProductService();
    _optimizedProductService = OptimizedProductService(); // 🚀 NOWY SERWIS
    _productManagementService =
        ProductManagementService(); // 🚀 NOWY: Centralny serwis
    _cacheManagementService =
        CacheManagementService(); // 🚀 NOWY: Zarządzanie cache
    _analyticsMigrationService =
        AnalyticsMigrationService(); // 🚀 NOWY: Serwis migracji analityki
  }

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

  void _setupSearchListener() {
    _searchController.addListener(() {
      _applyFiltersAndSearch();
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      if (kDebugMode) {
        print('🔄 [ProductsManagementScreen] Rozpoczynam ładowanie danych...');
      }

      // 🚀 NOWE: Wyczyść cache liczby inwestorów przed załadowaniem danych
      try {
        final investorCountService = UnifiedInvestorCountService();
        investorCountService.clearAllCache();
        debugPrint(
          '✅ [ProductsManagement] Cache liczby inwestorów wyczyszczony przy starcie',
        );
      } catch (e) {
        debugPrint(
          '⚠️ [ProductsManagement] Błąd czyszczenia cache przy starcie: $e',
        );
      }

      // 🚀 NOWE: Tryb wyboru serwisu
      if (_useProductManagementService) {
        await _loadDataWithProductManagementService();
      } else if (_useOptimizedMode) {
        await _loadOptimizedData();
      } else {
        await _loadLegacyData();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ProductsManagementScreen] Błąd podczas ładowania: $e');
      }

      // Fallback: Spróbuj legacy mode jeśli optimized nie działa
      if (_useOptimizedMode) {
        if (kDebugMode) {
          print('🔄 [ProductsManagementScreen] Fallback do legacy mode...');
        }
        try {
          setState(() {
            _useOptimizedMode = false;
          });
          await _loadLegacyData();
        } catch (fallbackError) {
          if (mounted) {
            setState(() {
              _error = 'Błąd podczas ładowania produktów: $fallbackError';
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Błąd podczas ładowania produktów: $e';
            _isLoading = false;
          });
        }
      }
    }
  }

  /// 🚀 NOWA METODA: Szybkie ładowanie z OptimizedProductService
  Future<void> _loadOptimizedData() async {
    if (kDebugMode) {
      print('⚡ [ProductsManagementScreen] Używam OptimizedProductService...');
    }

    final stopwatch = Stopwatch()..start();

    // Jedno wywołanie dla wszystkich produktów
    final optimizedResult = await _optimizedProductService
        .getAllProductsOptimized(forceRefresh: false, includeStatistics: true);

    stopwatch.stop();

    if (mounted) {
      setState(() {
        _optimizedProducts = optimizedResult.products;
        _filteredOptimizedProducts = List.from(optimizedResult.products);
        _optimizedResult = optimizedResult;

        // Konwertuj OptimizedProduct na DeduplicatedProduct dla kompatybilności
        _deduplicatedProducts = optimizedResult.products
            .map((opt) => _convertOptimizedToDeduplicatedProduct(opt))
            .toList();
        _filteredDeduplicatedProducts = List.from(_deduplicatedProducts);

        // Utwórz statystyki z OptimizedProductsResult
        if (optimizedResult.statistics != null) {
          // Konwertuj GlobalProductStatistics na unified.ProductStatistics
          // a potem na fb.ProductStatistics przez adapter
          _statistics = _convertGlobalStatsToFBStatsViAdapter(
            optimizedResult.statistics!,
          );
        }

        _isLoading = false;
      });

      _applyFiltersAndSearch();
      _startAnimations();

      if (kDebugMode) {
        print(
          '✅ [ProductsManagementScreen] OptimizedProductService: ${optimizedResult.products.length} produktów w ${stopwatch.elapsedMilliseconds}ms (cache: ${optimizedResult.fromCache})',
        );
      }

      // Sprawdź czy trzeba wyróżnić konkretny produkt
      if (widget.highlightedProductId != null ||
          widget.highlightedInvestmentId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _highlightSpecificProduct();
          }
        });
      }
    }
  }

  /// � NOWA METODA: Ładowanie danych przez ProductManagementService
  Future<void> _loadDataWithProductManagementService() async {
    if (kDebugMode) {
      print('🎯 [ProductsManagementScreen] Używam ProductManagementService...');
    }

    final stopwatch = Stopwatch()..start();

    try {
      // Używaj centralnego serwisu zarządzania produktami
      final productData = await _productManagementService.loadProductsData(
        useOptimizedMode: _useOptimizedMode,
        sortField: _sortField,
        sortDirection: _sortDirection,
        showDeduplicatedView: _showDeduplicatedView,
      );

      stopwatch.stop();

      if (mounted) {
        setState(() {
          _allProducts = productData.allProducts;
          _optimizedProducts = productData.optimizedProducts;
          _deduplicatedProducts = productData.deduplicatedProducts;

          // Filtrowane kopie
          _filteredProducts = List.from(_allProducts);
          _filteredOptimizedProducts = List.from(_optimizedProducts);
          _filteredDeduplicatedProducts = List.from(_deduplicatedProducts);

          // Statystyki
          if (productData.statistics != null) {
            _statistics = productData.statistics;
          }

          // Metadane
          if (productData.metadata != null) {
            _metadata = productData.metadata;
          }

          // Zoptymalizowane wyniki
          _optimizedResult = productData.optimizedResult;

          _isLoading = false;
        });

        _applyFiltersAndSearch();
        _startAnimations();

        if (kDebugMode) {
          print(
            '✅ [ProductsManagementScreen] ProductManagementService: ${productData.allProducts.length} produktów w ${stopwatch.elapsedMilliseconds}ms',
          );
        }

        // Sprawdź czy trzeba wyróżnić konkretny produkt
        if (widget.highlightedProductId != null ||
            widget.highlightedInvestmentId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _handleRouteParameters();
            }
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ProductsManagementScreen] Błąd ProductManagementService: $e');
      }

      if (mounted) {
        setState(() {
          _error = 'Błąd ładowania danych: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// �🔄 LEGACY METODA: Stare ładowanie dla fallback
  Future<void> _loadLegacyData() async {
    if (kDebugMode) {
      print('🔄 [ProductsManagementScreen] Używam legacy loading...');
    }

    // TEST: Sprawdź połączenie z Firebase Functions
    if (kDebugMode) {
      print(
        '🔄 [ProductsManagementScreen] Testowanie Firebase Functions (z fallback)...',
      );
      try {
        await _productService.testDirectFirestoreAccess();
        await _productService.testConnection();
      } catch (e) {
        if (kDebugMode) {
          print(
            '❌ [ProductsManagementScreen] Test połączenia nieudany (będzie używany fallback): $e',
          );
        }
      }
    }

    // Pobierz produkty, statystyki i deduplikowane produkty równolegle
    final results = await Future.wait([
      _productService.getUnifiedProducts(
        pageSize: 1000,
        sortBy: _sortField.name,
        sortAscending: _sortDirection == SortDirection.ascending,
      ),
      _showDeduplicatedView
          ? _deduplicatedProductService.getDeduplicatedProductStatistics().then(
              (stats) => ProductStatisticsAdapter.adaptFromUnifiedToFB(stats),
            )
          : _productService.getProductStatistics(),
      _deduplicatedProductService.getAllUniqueProducts(),
    ]);

    final productsResult = results[0] as UnifiedProductsResult;
    final statistics = results[1] as fb.ProductStatistics;
    final deduplicatedProducts = results[2] as List<DeduplicatedProduct>;

    if (mounted) {
      setState(() {
        _allProducts = productsResult.products;
        _filteredProducts = List.from(_allProducts);
        _deduplicatedProducts = deduplicatedProducts;
        _filteredDeduplicatedProducts = List.from(deduplicatedProducts);
        _statistics = statistics;
        _metadata = productsResult.metadata;
        _isLoading = false;
      });

      _applyFiltersAndSearch();
      _startAnimations();

      // Debugowanie - wypisz informacje o produktach
      _debugProductsLoaded();

      // Sprawdź czy trzeba wyróżnić konkretny produkt
      if (widget.highlightedProductId != null ||
          widget.highlightedInvestmentId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _highlightSpecificProduct();
          }
        });
      }

      if (kDebugMode) {
        print(
          '📊 [ProductsManagementScreen] Legacy: Załadowano ${_allProducts.length} produktów, cache używany: ${_metadata?.cacheUsed ?? false}',
        );
      }
    }
  }

  /// Odświeża statystyki po przełączeniu trybu wyświetlania
  Future<void> _refreshStatistics() async {
    if (_statistics == null) return;

    try {
      fb.ProductStatistics newStats;

      if (_useOptimizedMode && _optimizedResult?.statistics != null) {
        // Użyj statystyk z OptimizedProductsResult
        newStats = _convertGlobalStatsToFBStatsViAdapter(
          _optimizedResult!.statistics!,
        );
      } else if (_showDeduplicatedView) {
        newStats = await _deduplicatedProductService
            .getDeduplicatedProductStatistics()
            .then(
              (stats) => ProductStatisticsAdapter.adaptFromUnifiedToFB(stats),
            );
      } else {
        newStats = await _productService.getProductStatistics();
      }

      if (mounted) {
        setState(() {
          _statistics = newStats;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ProductsManagementScreen] Błąd odświeżania statystyk: $e');
      }
    }
  }

  /// 🚀 NOWA METODA: Konwertuje OptimizedProduct na DeduplicatedProduct
  DeduplicatedProduct _convertOptimizedToDeduplicatedProduct(
    OptimizedProduct opt,
  ) {
    return DeduplicatedProduct(
      id: opt.id,
      name: opt.name,
      productType: opt.productType,
      companyId: opt.companyId,
      companyName: opt.companyName,
      totalValue: opt.totalValue,
      totalRemainingCapital: opt.totalRemainingCapital,
      totalInvestments: opt.totalInvestments,
      uniqueInvestors: opt.uniqueInvestors,
      actualInvestorCount: opt.actualInvestorCount,
      averageInvestment: opt.averageInvestment,
      earliestInvestmentDate: opt.earliestInvestmentDate,
      latestInvestmentDate: opt.latestInvestmentDate,
      status: opt.status,
      interestRate: opt.interestRate,
      maturityDate: null, // OptimizedProduct może nie mieć maturityDate
      originalInvestmentIds:
          [], // OptimizedProduct nie przechowuje tej informacji
      metadata: opt.metadata,
    );
  }

  /// 🚀 NOWA METODA: Konwertuje GlobalProductStatistics na fb.ProductStatistics przez adapter
  fb.ProductStatistics _convertGlobalStatsToFBStatsViAdapter(
    GlobalProductStatistics global,
  ) {
    // Najpierw konwertuj GlobalProductStatistics na unified.ProductStatistics
    final unifiedStats = unified.ProductStatistics(
      totalProducts: global.totalProducts,
      activeProducts:
          global.totalProducts, // Aproximacja - nie mamy tej informacji
      inactiveProducts: 0, // Aproximacja - nie mamy tej informacji
      totalInvestmentAmount:
          global.totalValue, // Używamy totalValue jako aproximacja
      totalValue: global.totalValue,
      averageInvestmentAmount: global.averageValuePerProduct, // Aproximacja
      averageValue: global.averageValuePerProduct,
      typeDistribution: _convertTypeDistribution(
        global.productTypeDistribution,
      ),
      statusDistribution: const {
        ProductStatus.active: 1,
      }, // Domyślne - nie mamy tej informacji
      mostValuableType:
          UnifiedProductType.bonds, // Domyślne - nie mamy tej informacji
    );

    // Potem użyj adaptera do konwersji na fb.ProductStatistics
    return ProductStatisticsAdapter.adaptFromUnifiedToFB(unifiedStats);
  }

  /// Konwertuje Map<String, int> na Map<UnifiedProductType, int>
  Map<UnifiedProductType, int> _convertTypeDistribution(
    Map<String, int> typeDistribution,
  ) {
    final Map<UnifiedProductType, int> result = {};

    for (final entry in typeDistribution.entries) {
      final unifiedType = _mapStringToUnifiedProductType(entry.key);
      if (unifiedType != null) {
        result[unifiedType] = entry.value;
      }
    }

    return result;
  }

  /// Mapuje string na UnifiedProductType
  UnifiedProductType? _mapStringToUnifiedProductType(String type) {
    switch (type.toLowerCase()) {
      case 'bonds':
      case 'obligacje':
        return UnifiedProductType.bonds;
      case 'shares':
      case 'akcje':
        return UnifiedProductType.shares;
      case 'loans':
      case 'pozyczki':
        return UnifiedProductType.loans;
      case 'apartments':
      case 'mieszkania':
        return UnifiedProductType.apartments;
      case 'other':
      case 'inne':
        return UnifiedProductType.other;
      default:
        return UnifiedProductType.bonds; // Domyślne
    }
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _slideController.forward();
      }
    });
  }

  Future<void> _refreshData() async {
    if (_isRefreshing || !mounted) return;

    if (mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }

    // Dodaj efekt wibracji dla lepszego UX
    HapticFeedback.mediumImpact();

    try {
      // 🚀 NOWE: Wyczyść cache liczby inwestorów przy każdym odświeżaniu
      try {
        final investorCountService = UnifiedInvestorCountService();
        investorCountService.clearAllCache();
        debugPrint(
          '✅ [ProductsManagement] Cache liczby inwestorów wyczyszczony przy odświeżaniu',
        );
      } catch (e) {
        debugPrint('⚠️ [ProductsManagement] Błąd czyszczenia cache: $e');
      }

      if (_useProductManagementService) {
        // 🚀 NOWE: Odśwież przez ProductManagementService
        await _productManagementService.refreshCache();
        await _loadDataWithProductManagementService();
      } else if (_useOptimizedMode) {
        // 🚀 NOWE: Odśwież cache w OptimizedProductService
        await _optimizedProductService.refreshProducts();
        await _loadOptimizedData();
      } else {
        // Legacy: Odśwież cache na serwerze
        await _productService.refreshCache();
        await _loadLegacyData();
      }

      if (kDebugMode) {
        print(
          '🔄 [ProductsManagementScreen] Dane odświeżone (mode: ${_useOptimizedMode ? "optimized" : "legacy"})',
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

  void _applyFiltersAndSearch() {
    if (kDebugMode) {
      print(
        '🔄 [ProductsManagement] _applyFiltersAndSearch wywołane: showDeduplicated=$_showDeduplicatedView, useOptimized=$_useOptimizedMode',
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

  /// 🚀 NOWA METODA: Filtrowanie dla zoptymalizowanych produktów
  void _applyFiltersAndSearchForOptimizedProducts() {
    List<OptimizedProduct> filtered = List.from(_optimizedProducts);

    // Zastosuj wyszukiwanie tekstowe
    final searchText = _searchController.text.trim();
    if (searchText.isNotEmpty) {
      final searchLower = searchText.toLowerCase();
      if (kDebugMode) {
        print(
          '🔍 [ProductsManagementScreen] Wyszukiwanie zoptymalizowanych produktów: "$searchLower"',
        );
      }

      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(searchLower) ||
            product.companyName.toLowerCase().contains(searchLower) ||
            product.productType.displayName.toLowerCase().contains(searchLower);
      }).toList();

      if (kDebugMode) {
        print(
          '🔍 [ProductsManagementScreen] Znaleziono ${filtered.length} z ${_optimizedProducts.length} zoptymalizowanych produktów',
        );
      }
    }

    // Aplikuj filtry podobnie jak dla deduplikowanych produktów
    if (kDebugMode) {
      print(
        '🔧 [ProductsManagement] Aplikowanie filtrów do zoptymalizowanych produktów...',
      );
    }

    if (_filterCriteria.productTypes != null &&
        _filterCriteria.productTypes!.isNotEmpty) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        return _filterCriteria.productTypes!.contains(product.productType);
      }).toList();
      if (kDebugMode) {
        print(
          '🔧 [ProductsManagement] Filtr typów: $beforeCount → ${filtered.length}',
        );
      }
    }

    if (_filterCriteria.statuses != null &&
        _filterCriteria.statuses!.isNotEmpty) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        return _filterCriteria.statuses!.contains(product.status);
      }).toList();
      if (kDebugMode) {
        print(
          '🔧 [ProductsManagement] Filtr statusów: $beforeCount → ${filtered.length}',
        );
      }
    }

    if (_filterCriteria.companyName != null &&
        _filterCriteria.companyName!.isNotEmpty) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        return product.companyName.toLowerCase().contains(
          _filterCriteria.companyName!.toLowerCase(),
        );
      }).toList();
      if (kDebugMode) {
        print(
          '🔧 [ProductsManagement] Filtr firmy: $beforeCount → ${filtered.length}',
        );
      }
    }

    if (_filterCriteria.minInvestmentAmount != null) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        return product.averageInvestment >=
            _filterCriteria.minInvestmentAmount!;
      }).toList();
      if (kDebugMode) {
        print(
          '🔧 [ProductsManagement] Filtr min kwoty: $beforeCount → ${filtered.length}',
        );
      }
    }

    if (_filterCriteria.maxInvestmentAmount != null) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        return product.averageInvestment <=
            _filterCriteria.maxInvestmentAmount!;
      }).toList();
      if (kDebugMode) {
        print(
          '🔧 [ProductsManagement] Filtr max kwoty: $beforeCount → ${filtered.length}',
        );
      }
    }

    if (_filterCriteria.minInterestRate != null) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        final rate = product.interestRate;
        return rate >= _filterCriteria.minInterestRate!;
      }).toList();
      if (kDebugMode) {
        print(
          '🔧 [ProductsManagement] Filtr min oprocentowania: $beforeCount → ${filtered.length}',
        );
      }
    }

    if (_filterCriteria.maxInterestRate != null) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        final rate = product.interestRate;
        return rate <= _filterCriteria.maxInterestRate!;
      }).toList();
      if (kDebugMode) {
        print(
          '🔧 [ProductsManagement] Filtr max oprocentowania: $beforeCount → ${filtered.length}',
        );
      }
    }

    if (_filterCriteria.createdAfter != null) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        return product.earliestInvestmentDate.isAfter(
              _filterCriteria.createdAfter!,
            ) ||
            product.earliestInvestmentDate.isAtSameMomentAs(
              _filterCriteria.createdAfter!,
            );
      }).toList();
      if (kDebugMode) {
        print(
          '🔧 [ProductsManagement] Filtr daty początkowej: $beforeCount → ${filtered.length}',
        );
      }
    }

    if (_filterCriteria.createdBefore != null) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        return product.latestInvestmentDate.isBefore(
              _filterCriteria.createdBefore!,
            ) ||
            product.latestInvestmentDate.isAtSameMomentAs(
              _filterCriteria.createdBefore!,
            );
      }).toList();
      if (kDebugMode) {
        print(
          '🔧 [ProductsManagement] Filtr daty końcowej: $beforeCount → ${filtered.length}',
        );
      }
    }

    if (kDebugMode) {
      print(
        '🔧 [ProductsManagement] Filtry zastosowane (optimized): ${_optimizedProducts.length} → ${filtered.length}',
      );
    }

    // Sortowanie zoptymalizowanych produktów
    _sortOptimizedProducts(filtered);

    setState(() {
      _filteredOptimizedProducts = filtered;
      // Synchronizuj z deduplikowanymi dla kompatybilności
      _filteredDeduplicatedProducts = filtered
          .map((opt) => _convertOptimizedToDeduplicatedProduct(opt))
          .toList();
    });

    if (kDebugMode) {
      print(
        '🔄 [ProductsManagement] Sortowanie zoptymalizowanych produktów zakończone, znaleziono: ${_filteredOptimizedProducts.length}',
      );
    }
  }

  /// 🚀 NOWA METODA: Sortowanie zoptymalizowanych produktów
  void _sortOptimizedProducts(List<OptimizedProduct> products) {
    if (kDebugMode) {
      print(
        '🔄 [ProductsManagement] Sortowanie ${products.length} zoptymalizowanych produktów po: ${_sortField.displayName} (${_sortDirection.displayName})',
      );
    }

    products.sort((a, b) {
      int comparison;

      switch (_sortField) {
        case ProductSortField.name:
          comparison = a.name.compareTo(b.name);
          break;
        case ProductSortField.type:
          comparison = a.productType.collectionName.compareTo(
            b.productType.collectionName,
          );
          break;
        case ProductSortField.investmentAmount:
          comparison = a.averageInvestment.compareTo(b.averageInvestment);
          break;
        case ProductSortField.totalValue:
          comparison = a.totalValue.compareTo(b.totalValue);
          break;
        case ProductSortField.createdAt:
          comparison = a.earliestInvestmentDate.compareTo(
            b.earliestInvestmentDate,
          );
          break;
        case ProductSortField.uploadedAt:
          comparison = a.latestInvestmentDate.compareTo(b.latestInvestmentDate);
          break;
        case ProductSortField.status:
          comparison = a.status.displayName.compareTo(b.status.displayName);
          break;
        case ProductSortField.companyName:
          comparison = a.companyName.compareTo(b.companyName);
          break;
        case ProductSortField.interestRate:
          comparison = a.interestRate.compareTo(b.interestRate);
          break;
      }

      return _sortDirection == SortDirection.ascending
          ? comparison
          : -comparison;
    });

    if (kDebugMode) {
      print(
        '🔄 [ProductsManagement] Sortowanie zoptymalizowanych produktów zakończone',
      );
    }
  }

  void _applyFiltersAndSearchForRegularProducts() {
    List<UnifiedProduct> filtered = List.from(_allProducts);

    // Zastosuj wyszukiwanie tekstowe
    final searchText = _searchController.text.trim();
    if (searchText.isNotEmpty) {
      final searchLower = searchText.toLowerCase();
      print(
        '🔍 [ProductsManagementScreen] Wyszukiwanie produktów: "$searchLower"',
      );

      filtered = filtered.where((product) {
        // Podstawowe pola
        bool matches =
            product.name.toLowerCase().contains(searchLower) ||
            product.description.toLowerCase().contains(searchLower) ||
            product.productType.displayName.toLowerCase().contains(
              searchLower,
            ) ||
            (product.companyName?.toLowerCase().contains(searchLower) ?? false);

        // Dodatkowe wyszukiwanie w additionalInfo z polskimi nazwami pól
        if (!matches && product.additionalInfo.isNotEmpty) {
          for (final entry in product.additionalInfo.entries) {
            final key = entry.key.toString().toLowerCase();
            final value = entry.value.toString().toLowerCase();

            // Sprawdź polskie klucze które mogą zawierać nazwy produktów
            if ((key.contains('nazwa') ||
                    key.contains('produkt_nazwa') ||
                    key.contains('klient') ||
                    key.contains('wierzyciel_spolka') ||
                    key.contains('pozyczkobiorca') ||
                    key.contains('product') ||
                    key.contains('name')) &&
                value.contains(searchLower)) {
              matches = true;
              print(
                '🔍 [ProductsManagementScreen] Znaleziono w additionalInfo[$key]: $value',
              );
              break;
            }

            // Sprawdź też inne wartości
            if (value.contains(searchLower)) {
              matches = true;
              print('🔍 [ProductsManagementScreen] Znaleziono wartość: $value');
              break;
            }
          }
        }

        // Sprawdź też ID produktu
        if (!matches && product.id.toLowerCase().contains(searchLower)) {
          matches = true;
        }

        // Sprawdź specyficzne pola dla Bond
        if (!matches && product.originalProduct is Bond) {
          final bond = product.originalProduct as Bond;
          if ((bond.productName?.toLowerCase().contains(searchLower) ??
                  false) ||
              (bond.clientName?.toLowerCase().contains(searchLower) ?? false) ||
              (bond.companyId?.toLowerCase().contains(searchLower) ?? false) ||
              (bond.advisor?.toLowerCase().contains(searchLower) ?? false)) {
            matches = true;
          }
        }

        // Sprawdź specyficzne pola dla Loan
        if (!matches && product.originalProduct is Loan) {
          final loan = product.originalProduct as Loan;
          if ((loan.borrower?.toLowerCase().contains(searchLower) ?? false) ||
              (loan.creditorCompany?.toLowerCase().contains(searchLower) ??
                  false) ||
              (loan.loanNumber?.toLowerCase().contains(searchLower) ?? false)) {
            matches = true;
          }
        }

        if (matches) {
          print(
            '🔍 [ProductsManagementScreen] Dopasowanie produktu: ${product.name}',
          );
        }

        return matches;
      }).toList();

      print(
        '🔍 [ProductsManagementScreen] Znaleziono ${filtered.length} z ${_allProducts.length} produktów',
      );
    }

    // Zastosuj filtry
    filtered = filtered.where(_filterCriteria.matches).toList();

    // Zastosuj sortowanie
    _sortProducts(filtered);

    setState(() {
      _filteredProducts = filtered;
    });
  }

  void _applyFiltersAndSearchForDeduplicatedProducts() {
    List<DeduplicatedProduct> filtered = List.from(_deduplicatedProducts);

    // Zastosuj wyszukiwanie tekstowe
    final searchText = _searchController.text.trim();
    if (searchText.isNotEmpty) {
      final searchLower = searchText.toLowerCase();
      print(
        '🔍 [ProductsManagementScreen] Wyszukiwanie deduplikowanych produktów: "$searchLower"',
      );

      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(searchLower) ||
            product.companyName.toLowerCase().contains(searchLower) ||
            product.productType.displayName.toLowerCase().contains(searchLower);
      }).toList();

      print(
        '🔍 [ProductsManagementScreen] Znaleziono ${filtered.length} z ${_deduplicatedProducts.length} deduplikowanych produktów',
      );
    }

    // Aplikuj filtry z ProductFilterCriteria
    print(
      '🔧 [ProductsManagement] Aplikowanie filtrów do deduplikowanych produktów...',
    );
    print(
      '🔧 [ProductsManagement] Filtry - typy: ${_filterCriteria.productTypes?.map((t) => t.displayName).join(", ")}',
    );
    print(
      '🔧 [ProductsManagement] Filtry - statusy: ${_filterCriteria.statuses?.map((s) => s.displayName).join(", ")}',
    );
    print(
      '🔧 [ProductsManagement] Filtry - firma: "${_filterCriteria.companyName}"',
    );
    print(
      '🔧 [ProductsManagement] Filtry - kwoty: ${_filterCriteria.minInvestmentAmount}-${_filterCriteria.maxInvestmentAmount}',
    );

    if (_filterCriteria.productTypes != null &&
        _filterCriteria.productTypes!.isNotEmpty) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        // Porównuj bezpośrednio UnifiedProductType z UnifiedProductType
        final matches = _filterCriteria.productTypes!.contains(
          product.productType,
        );
        if (!matches) {
          print(
            '🔧 [ProductsManagement] Filtrowanie - odrzucam "${product.name}" (${product.productType.displayName}) - nie pasuje do ${_filterCriteria.productTypes!.map((t) => t.displayName).join(", ")}',
          );
        } else {
          print(
            '🔧 [ProductsManagement] Filtrowanie - akceptuję "${product.name}" (${product.productType.displayName})',
          );
        }
        return matches;
      }).toList();
      print(
        '🔧 [ProductsManagement] Filtr typów: ${beforeCount} → ${filtered.length}',
      );
    }

    if (_filterCriteria.statuses != null &&
        _filterCriteria.statuses!.isNotEmpty) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        final matches = _filterCriteria.statuses!.contains(product.status);
        return matches;
      }).toList();
      print(
        '🔧 [ProductsManagement] Filtr statusów: ${beforeCount} → ${filtered.length}',
      );
    }

    if (_filterCriteria.companyName != null &&
        _filterCriteria.companyName!.isNotEmpty) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        final matches = product.companyName.toLowerCase().contains(
          _filterCriteria.companyName!.toLowerCase(),
        );
        return matches;
      }).toList();
      print(
        '🔧 [ProductsManagement] Filtr firmy: ${beforeCount} → ${filtered.length}',
      );
    }

    if (_filterCriteria.minInvestmentAmount != null) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        final matches =
            product.averageInvestment >= _filterCriteria.minInvestmentAmount!;
        return matches;
      }).toList();
      print(
        '🔧 [ProductsManagement] Filtr min kwoty: ${beforeCount} → ${filtered.length}',
      );
    }

    if (_filterCriteria.maxInvestmentAmount != null) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        final matches =
            product.averageInvestment <= _filterCriteria.maxInvestmentAmount!;
        return matches;
      }).toList();
      print(
        '🔧 [ProductsManagement] Filtr max kwoty: ${beforeCount} → ${filtered.length}',
      );
    }

    if (_filterCriteria.minInterestRate != null) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        final rate = product.interestRate ?? 0.0;
        final matches = rate >= _filterCriteria.minInterestRate!;
        return matches;
      }).toList();
      print(
        '🔧 [ProductsManagement] Filtr min oprocentowania: ${beforeCount} → ${filtered.length}',
      );
    }

    if (_filterCriteria.maxInterestRate != null) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        final rate = product.interestRate ?? 0.0;
        final matches = rate <= _filterCriteria.maxInterestRate!;
        return matches;
      }).toList();
      print(
        '🔧 [ProductsManagement] Filtr max oprocentowania: ${beforeCount} → ${filtered.length}',
      );
    }

    if (_filterCriteria.createdAfter != null) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        final matches =
            product.earliestInvestmentDate.isAfter(
              _filterCriteria.createdAfter!,
            ) ||
            product.earliestInvestmentDate.isAtSameMomentAs(
              _filterCriteria.createdAfter!,
            );
        return matches;
      }).toList();
      print(
        '🔧 [ProductsManagement] Filtr daty początkowej: ${beforeCount} → ${filtered.length}',
      );
    }

    if (_filterCriteria.createdBefore != null) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        final matches =
            product.latestInvestmentDate.isBefore(
              _filterCriteria.createdBefore!,
            ) ||
            product.latestInvestmentDate.isAtSameMomentAs(
              _filterCriteria.createdBefore!,
            );
        return matches;
      }).toList();
      print(
        '🔧 [ProductsManagement] Filtr daty końcowej: ${beforeCount} → ${filtered.length}',
      );
    }

    print(
      '🔧 [ProductsManagement] Filtry zastosowane: ${_deduplicatedProducts.length} → ${filtered.length}',
    );

    print(
      '🔄 [ProductsManagement] Sortowanie ${filtered.length} deduplikowanych produktów po: ${_sortField.displayName} (${_sortDirection.displayName})',
    );

    // Debug: wypisz pierwsze 3 produkty przed sortowaniem
    if (filtered.length > 0) {
      print('🔧 [ProductsManagement] PRZED sortowaniem:');
      for (int i = 0; i < filtered.length && i < 3; i++) {
        final product = filtered[i];
        print(
          '🔧 [ProductsManagement]   ${i + 1}. ${product.name} - ${product.productType.displayName} (${product.productType.collectionName})',
        );
      }
    }

    // Sortowanie deduplikowanych produktów
    filtered.sort((a, b) {
      int comparison;

      switch (_sortField) {
        case ProductSortField.name:
          comparison = a.name.compareTo(b.name);
          break;
        case ProductSortField.type:
          // Użyj collectionName dla bardziej stabilnego sortowania deduplikowanych
          comparison = a.productType.collectionName.compareTo(
            b.productType.collectionName,
          );
          break;
        case ProductSortField.investmentAmount:
          comparison = a.averageInvestment.compareTo(b.averageInvestment);
          break;
        case ProductSortField.totalValue:
          comparison = a.totalValue.compareTo(b.totalValue);
          break;
        case ProductSortField.createdAt:
          comparison = a.earliestInvestmentDate.compareTo(
            b.earliestInvestmentDate,
          );
          break;
        case ProductSortField.uploadedAt:
          comparison = a.latestInvestmentDate.compareTo(b.latestInvestmentDate);
          break;
        case ProductSortField.status:
          comparison = a.status.displayName.compareTo(b.status.displayName);
          break;
        case ProductSortField.companyName:
          comparison = a.companyName.compareTo(b.companyName);
          break;
        case ProductSortField.interestRate:
          final aRate = a.interestRate ?? 0.0;
          final bRate = b.interestRate ?? 0.0;
          comparison = aRate.compareTo(bRate);
          break;
      }

      int result = _sortDirection == SortDirection.ascending
          ? comparison
          : -comparison;

      if (_sortField == ProductSortField.type) {
        print(
          '🔧 [ProductsManagement] Porównywanie DEDUPLIKOWANE "${a.name}" (${a.productType.collectionName}/${a.productType.displayName}) vs "${b.name}" (${b.productType.collectionName}/${b.productType.displayName}) = $comparison (result: $result)',
        );
      }

      return result;
    });

    setState(() {
      _filteredDeduplicatedProducts = filtered;
    });

    print(
      '🔄 [ProductsManagement] Sortowanie deduplikowanych produktów zakończone, znaleziono: ${_filteredDeduplicatedProducts.length}',
    );
  }

  void _sortProducts(List<UnifiedProduct> products) {
    print(
      '🔄 [ProductsManagement] Sortowanie ${products.length} zwykłych produktów po: ${_sortField.displayName} (${_sortDirection.displayName})',
    );

    products.sort((a, b) {
      int comparison;

      switch (_sortField) {
        case ProductSortField.name:
          comparison = a.name.compareTo(b.name);
          break;
        case ProductSortField.type:
          // Użyj collectionName dla bardziej stabilnego sortowania zwykłych produktów
          comparison = a.productType.collectionName.compareTo(
            b.productType.collectionName,
          );
          break;
        case ProductSortField.investmentAmount:
          comparison = a.investmentAmount.compareTo(b.investmentAmount);
          break;
        case ProductSortField.totalValue:
          comparison = a.totalValue.compareTo(b.totalValue);
          break;
        case ProductSortField.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case ProductSortField.uploadedAt:
          comparison = a.uploadedAt.compareTo(b.uploadedAt);
          break;
        case ProductSortField.status:
          comparison = a.status.displayName.compareTo(b.status.displayName);
          break;
        case ProductSortField.companyName:
          comparison = (a.companyName ?? '').compareTo(b.companyName ?? '');
          break;
        case ProductSortField.interestRate:
          comparison = (a.interestRate ?? 0.0).compareTo(b.interestRate ?? 0.0);
          break;
      }

      int result = _sortDirection == SortDirection.ascending
          ? comparison
          : -comparison;

      if (_sortField == ProductSortField.type) {
        print(
          '🔧 [ProductsManagement] Porównywanie ZWYKLE "${a.name}" (${a.productType.collectionName}/${a.productType.displayName}) vs "${b.name}" (${b.productType.collectionName}/${b.productType.displayName}) = $comparison (result: $result)',
        );
      }

      return result;
    });

    print('🔄 [ProductsManagement] Sortowanie zakończone');
  }

  void _onFilterChanged(ProductFilterCriteria criteria) {
    print('🔧 [ProductsManagement] _onFilterChanged wywołane');
    print(
      '🔧 [ProductsManagement] Nowe kryteria: productTypes=${criteria.productTypes?.map((t) => t.displayName).join(", ")}, statuses=${criteria.statuses?.map((s) => s.displayName).join(", ")}',
    );
    print(
      '🔧 [ProductsManagement] Firma: "${criteria.companyName}", kwoty: ${criteria.minInvestmentAmount}-${criteria.maxInvestmentAmount}',
    );
    print(
      '🔧 [ProductsManagement] Poprzednie kryteria: productTypes=${_filterCriteria.productTypes?.map((t) => t.displayName).join(", ")}, statuses=${_filterCriteria.statuses?.map((s) => s.displayName).join(", ")}',
    );
    setState(() {
      _filterCriteria = criteria;
    });
    print(
      '🔧 [ProductsManagement] setState zakończone, wywołuję _applyFiltersAndSearch',
    );
    _applyFiltersAndSearch();
  }

  void _onSortChanged(ProductSortField field, SortDirection direction) {
    print(
      '🔄 [ProductsManagement] Sortowanie zmienione na: ${field.displayName} (${direction.displayName})',
    );
    print(
      '🔄 [ProductsManagement] Poprzednie sortowanie: ${_sortField.displayName} (${_sortDirection.displayName})',
    );
    setState(() {
      _sortField = field;
      _sortDirection = direction;
    });
    print(
      '🔄 [ProductsManagement] setState zakończone, wywołuję _applyFiltersAndSearch',
    );
    _applyFiltersAndSearch();
  }

  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
    });
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          if (_showStatistics && _statistics != null) _buildStatisticsSection(),
          _buildSearchAndFilters(),
          if (_isLoading)
            SliverFillRemaining(
              child: const Center(
                child: MetropolitanLoadingWidget.products(showProgress: true),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: PremiumErrorWidget(
                error: _error!,
                onRetry: _loadInitialData,
              ),
            )
          else
            _buildProductsList(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.backgroundPrimary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      _isSelectionMode
                          ? 'Wybrano produktów: ${_selectedProducts.length}'
                          : 'Zarządzanie Produktami',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppTheme.textOnPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      _showDeduplicatedView
                          ? '${_filteredDeduplicatedProducts.length} z ${_deduplicatedProducts.length} unikalnych produktów'
                          : '${_filteredProducts.length} z ${_allProducts.length} produktów',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textOnPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        // Email functionality w trybie selekcji
        if (_isSelectionMode) ...[
          IconButton(
            icon: Icon(
              Icons.email,
              color: _selectedProducts.isNotEmpty
                  ? AppTheme.secondaryGold
                  : AppTheme.textSecondary,
            ),
            onPressed: _selectedProducts.isNotEmpty ? _showEmailDialog : null,
            tooltip: 'Wyślij email do wybranych (${_selectedProducts.length})',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.secondaryGold),
            onPressed: () {
              setState(() {
                _isSelectionMode = false;
                _selectedProductIds.clear();
              });
            },
            tooltip: 'Anuluj selekcję',
          ),
        ] else ...[
          // Przycisk rozpoczęcia selekcji email
          IconButton(
            icon: const Icon(Icons.email, color: AppTheme.secondaryGold),
            onPressed: () {
              setState(() {
                _isSelectionMode = true;
              });
            },
            tooltip: 'Wybierz produkty do email',
          ),
        ],

        // Przełącznik deduplikacji
        IconButton(
          icon: Icon(
            _showDeduplicatedView ? Icons.filter_vintage : Icons.all_inclusive,
            color: AppTheme.secondaryGold,
          ),
          onPressed: () async {
            setState(() {
              _showDeduplicatedView = !_showDeduplicatedView;
              _applyFiltersAndSearch();
            });
            HapticFeedback.lightImpact();

            // 🚀 NOWE: Wyczyść cache liczby inwestorów po przełączeniu trybu
            try {
              final investorCountService = UnifiedInvestorCountService();
              investorCountService.clearAllCache();
              debugPrint(
                '✅ [ProductsManagement] Cache liczby inwestorów wyczyszczony',
              );
            } catch (e) {
              debugPrint('⚠️ [ProductsManagement] Błąd czyszczenia cache: $e');
            }

            // Odśwież statystyki po przełączeniu trybu
            await _refreshStatistics();
          },
          tooltip: _showDeduplicatedView
              ? 'Pokaż wszystkie inwestycje'
              : 'Pokaż produkty unikalne',
        ),
        IconButton(
          icon: Icon(
            _showStatistics ? Icons.analytics_outlined : Icons.analytics,
            color: AppTheme.secondaryGold,
          ),
          onPressed: () {
            setState(() {
              _showStatistics = !_showStatistics;
            });
            HapticFeedback.lightImpact();
          },
          tooltip: _showStatistics ? 'Ukryj statystyki' : 'Pokaż statystyki',
        ),
        IconButton(
          icon: Icon(
            _viewMode == ViewMode.grid ? Icons.view_list : Icons.grid_view,
            color: AppTheme.secondaryGold,
          ),
          onPressed: _toggleViewMode,
          tooltip: 'Zmień widok',
        ),
        IconButton(
          icon: Icon(
            _isRefreshing ? Icons.hourglass_empty : Icons.refresh,
            color: AppTheme.secondaryGold,
          ),
          onPressed: _isRefreshing ? null : _refreshData,
          tooltip: 'Odśwież dane',
        ),
        // 🚀 NOWY: Globalne zarządzanie cache
        if (_useProductManagementService)
          PopupMenuButton<String>(
            icon: Icon(Icons.storage, color: AppTheme.primaryColor),
            tooltip: 'Zarządzanie cache',
            onSelected: (String value) async {
              switch (value) {
                case 'clear_all':
                  await _cacheManagementService.clearAllCaches();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache wyczyszczony')),
                  );
                  break;
                case 'smart_refresh':
                  await _cacheManagementService.smartRefresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Smart refresh wykonany')),
                  );
                  break;
                case 'preload':
                  await _cacheManagementService.preloadCache();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache przeładowany')),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Wyczyść wszystkie cache'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'smart_refresh',
                child: Row(
                  children: [
                    Icon(Icons.auto_fix_high),
                    SizedBox(width: 8),
                    Text('Smart refresh'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'preload',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Przeładuj cache'),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ProductStatsWidget(
              statistics: ProductStatisticsAdapter.adaptToUnified(_statistics!),
              animationController: _fadeController,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              // Pasek wyszukiwania
              Container(
                decoration: AppTheme.premiumCardDecoration,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Wyszukaj produkty...',
                    hintStyle: TextStyle(color: AppTheme.textTertiary),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.secondaryGold,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppTheme.textTertiary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : IconButton(
                            icon: Icon(
                              _showFilters
                                  ? Icons.filter_list
                                  : Icons.filter_list_outlined,
                              color: AppTheme.secondaryGold,
                            ),
                            onPressed: () {
                              setState(() {
                                _showFilters = !_showFilters;
                              });
                              HapticFeedback.lightImpact();
                            },
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),

              // Panel filtrów
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _showFilters ? null : 0,
                child: _showFilters
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ProductFilterWidget(
                          initialCriteria: _filterCriteria,
                          initialSortField: _sortField,
                          initialSortDirection: _sortDirection,
                          onFilterChanged: _onFilterChanged,
                          onSortChanged: _onSortChanged,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    if (_showDeduplicatedView) {
      return _buildDeduplicatedProductsList();
    } else {
      return _buildRegularProductsList();
    }
  }

  Widget _buildRegularProductsList() {
    if (_filteredProducts.isEmpty) {
      return SliverFillRemaining(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _buildEmptyState(),
        ),
      );
    }

    if (_viewMode == ViewMode.grid) {
      return _buildGridView();
    } else {
      return _buildListView();
    }
  }

  Widget _buildDeduplicatedProductsList() {
    if (_filteredDeduplicatedProducts.isEmpty) {
      return SliverFillRemaining(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _buildEmptyState(),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        key: ValueKey(
          'deduplicated_list_${_sortField.name}_${_sortDirection.name}',
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = _filteredDeduplicatedProducts[index];
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildDeduplicatedProductCard(product, index),
            ),
          );
        }, childCount: _filteredDeduplicatedProducts.length),
      ),
    );
  }

  Widget _buildGridView() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        key: ValueKey('grid_view_${_sortField.name}_${_sortDirection.name}'),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ProductCardWidget(
                product: _filteredProducts[index],
                viewMode: _viewMode,
                onTap: () => _showProductDetails(_filteredProducts[index]),
              ),
            ),
          );
        }, childCount: _filteredProducts.length),
      ),
    );
  }

  Widget _buildListView() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        key: ValueKey('regular_list_${_sortField.name}_${_sortDirection.name}'),
        delegate: SliverChildBuilderDelegate((context, index) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ProductCardWidget(
                  product: _filteredProducts[index],
                  viewMode: _viewMode,
                  onTap: () => _showProductDetails(_filteredProducts[index]),
                ),
              ),
            ),
          );
        }, childCount: _filteredProducts.length),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchController.text.isNotEmpty;
    final hasFilters =
        _filterCriteria.productTypes != null ||
        _filterCriteria.statuses != null ||
        _filterCriteria.minInvestmentAmount != null ||
        _filterCriteria.maxInvestmentAmount != null;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 60,
                color: AppTheme.secondaryGold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasSearch || hasFilters
                  ? 'Brak produktów spełniających kryteria'
                  : 'Brak produktów w systemie',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              hasSearch || hasFilters
                  ? 'Spróbuj zmienić filtry lub wyszukiwaną frazę'
                  : 'Dodaj pierwszy produkt do systemu',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (hasSearch || hasFilters) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _filterCriteria = const ProductFilterCriteria();
                    _showFilters = false;
                  });
                  _applyFiltersAndSearch();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Wyczyść filtry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryGold,
                  foregroundColor: AppTheme.textOnSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Tooltip(
      message: canEdit ? 'Dodaj Produkt' : kRbacNoPermissionTooltip,
      child: FloatingActionButton.extended(
        onPressed: canEdit ? _showAddProductDialog : null,
        backgroundColor: canEdit ? AppTheme.secondaryGold : Colors.grey,
        foregroundColor: AppTheme.textOnSecondary,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj Produkt'),
        elevation: 8,
      ),
    );
  }

  Widget _buildDeduplicatedProductCard(DeduplicatedProduct product, int index) {
    final isSelected = _selectedProductIds.contains(product.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: isSelected
          ? AppTheme.premiumCardDecoration.copyWith(
              border: Border.all(color: AppTheme.secondaryGold, width: 2),
            )
          : AppTheme.premiumCardDecoration,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedProductIds.remove(product.id);
              } else {
                _selectedProductIds.add(product.id);
              }
            });
          } else {
            _showDeduplicatedProductDetails(product);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Checkbox w trybie selekcji
                  if (_isSelectionMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedProductIds.add(product.id);
                          } else {
                            _selectedProductIds.remove(product.id);
                          }
                        });
                      },
                      activeColor: AppTheme.secondaryGold,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: product.productType.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: product.productType.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      product.productType.displayName,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: product.productType.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (product.hasDuplicates)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.warningColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${product.totalInvestments} inwestycji',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.warningColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                product.companyName,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatColumnWithSyncWidget(
                      'Łączna wartość',
                      product,
                      'totalRemainingCapitalShort',
                      Icons.account_balance_wallet,
                    ),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      'Inwestorów',
                      '${product.investorCount}', // ⭐ Używa getter z DeduplicatedProduct
                      Icons.people,
                    ),
                  ),
                  Expanded(
                    child: _buildStatColumnWithSyncWidget(
                      'Pozostały kapitał',
                      product,
                      'totalRemainingCapitalShort',
                      Icons.trending_up,
                    ),
                  ),
                ],
              ),
              if (product.hasDuplicates) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.warningColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.content_copy,
                        size: 16,
                        color: AppTheme.warningColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Liczenie inwestorów:\n'
                          '• Rzeczywista liczba (Firebase): ${product.actualInvestorCount}\n'
                          '• Lokalna deduplikacja: ${product.uniqueInvestors}\n'
                          '• Duplikacja: ${(product.duplicationRatio * 100).toStringAsFixed(1)}% (${product.totalInvestments - product.uniqueInvestors} duplikatów)',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.warningColor,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.secondaryGold, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 🚀 NOWY: Widget statystyk z zsynchronizowanymi wartościami z modalu
  Widget _buildStatColumnWithSyncWidget(
    String label,
    DeduplicatedProduct product,
    String valueType,
    IconData icon,
  ) {
    // Konwertuj DeduplicatedProduct na UnifiedProduct dla kompatybilności
    final unifiedProduct = _convertDeduplicatedToUnified(product);

    return Column(
      children: [
        Icon(icon, color: AppTheme.secondaryGold, size: 20),
        const SizedBox(height: 4),
        SynchronizedProductValuesWidget(
          product: unifiedProduct,
          valueType: valueType,
          textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          valueColor: AppTheme.textPrimary,
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showDeduplicatedProductDetails(DeduplicatedProduct product) {
    print(
      '🔍 [ProductsManagement] Pokazywanie szczegółów deduplikowanego produktu:',
    );
    print('  - Nazwa: "${product.name}"');
    print('  - Typ: ${product.productType.displayName}');
    print('  - ID: ${product.id}');
    print('  - Wartość: ${product.totalValue}');

    // Konwertujemy DeduplicatedProduct na UnifiedProduct
    final unifiedProduct = _convertDeduplicatedToUnified(product);

    print(
      '✅ [ProductsManagement] Konwersja zakończona, wywołuję EnhancedProductDetailsDialog',
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        print('🎯 [ProductsManagement] Builder dialogu wywołany');
        return EnhancedProductDetailsDialog(
          product: unifiedProduct,
          onShowInvestors: () => _showProductInvestors(unifiedProduct),
        );
      },
    );
  }

  /// Konwertuje DeduplicatedProduct na UnifiedProduct
  UnifiedProduct _convertDeduplicatedToUnified(DeduplicatedProduct deduped) {
    return UnifiedProduct(
      id: deduped.id,
      name: deduped.name,
      productType: deduped.productType,
      investmentAmount: deduped.totalValue,
      createdAt: deduped.earliestInvestmentDate,
      uploadedAt: deduped.latestInvestmentDate,
      sourceFile: 'Deduplikowane z ${deduped.totalInvestments} inwestycji',
      status: deduped.status,
      companyName: deduped.companyName,
      companyId: deduped.companyId,
      maturityDate: deduped.maturityDate,
      interestRate: deduped.interestRate,
      remainingCapital: deduped.totalRemainingCapital,
      currency: 'PLN',
      originalProduct: deduped,
      additionalInfo: {
        'isDeduplicated': true,
        'totalInvestments': deduped.totalInvestments,
        'uniqueInvestors':
            deduped.investorCount, // ⭐ ZMIENIONE: używa nowego getter
        'totalInvestors':
            deduped.investorCount, // ⭐ NOWE: dodatkowe pole dla kompatybilności
        'averageInvestment': deduped.averageInvestment,
        'duplicationRatio': deduped.duplicationRatio,
        'hasDuplicates': deduped.hasDuplicates,
        'capitalReturnPercentage': deduped.capitalReturnPercentage,
        'originalInvestmentIds': deduped.originalInvestmentIds,
        'deduplication_stats': {
          'earliestDate': deduped.earliestInvestmentDate.toIso8601String(),
          'latestDate': deduped.latestInvestmentDate.toIso8601String(),
          'dateRange': deduped.latestInvestmentDate
              .difference(deduped.earliestInvestmentDate)
              .inDays,
        },
        ...deduped.metadata,
      },
    );
  }

  void _showProductDetails(UnifiedProduct product) {
    print(
      '🔍 [ProductsManagement] Pokazywanie szczegółów normalnego produktu:',
    );
    print('  - Nazwa: "${product.name}"');
    print('  - Typ: ${product.productType.displayName}');
    print('  - ID: ${product.id}');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        print('🎯 [ProductsManagement] Builder normalnego dialogu wywołany');
        return EnhancedProductDetailsDialog(
          product: product,
          onShowInvestors: () => _showProductInvestors(product),
        );
      },
    );
  }

  /// 🎯 NOWA METODA: Pokaż szczegóły zoptymalizowanego produktu
  void _showOptimizedProductDetails(
    OptimizedProduct product,
    String? highlightInvestmentId,
  ) {
    print(
      '🔍 [ProductsManagement] Pokazywanie szczegółów zoptymalizowanego produktu:',
    );
    print('  - Nazwa: "${product.name}"');
    print('  - Typ: ${product.productType.displayName}');
    print('  - ID: ${product.id}');
    print('  - Highlight Investment ID: $highlightInvestmentId');

    // Konwertuj OptimizedProduct na UnifiedProduct dla kompatybilności
    final unifiedProduct = UnifiedProduct(
      id: product.id,
      name: product.name,
      productType: product.productType,
      investmentAmount: product.totalValue,
      remainingCapital: product.totalRemainingCapital,
      createdAt: product.earliestInvestmentDate,
      uploadedAt: product.latestInvestmentDate,
      sourceFile: 'Zoptymalizowany produkt',
      status: product.status,
      companyName: product.companyName,
      companyId: product.companyId,
      interestRate: product.interestRate > 0 ? product.interestRate : null,
      currency: 'PLN',
      additionalInfo: {
        'isOptimized': true,
        'totalInvestments': product.totalInvestments,
        'uniqueInvestors': product.uniqueInvestors,
        'actualInvestorCount': product.actualInvestorCount,
        'averageInvestment': product.averageInvestment,
        'highlightInvestmentId': highlightInvestmentId,
        ...product.metadata,
      },
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        print(
          '🎯 [ProductsManagement] Builder zoptymalizowanego dialogu wywołany',
        );
        return EnhancedProductDetailsDialog(
          product: unifiedProduct,
          onShowInvestors: () => _showProductInvestors(unifiedProduct),
        );
      },
    );
  }

  /// Pokazuje inwestorów dla danego produktu
  /// 🚀 ZAKTUALIZOWANE: Używa ultra-precyzyjnego serwisu
  void _showProductInvestors(UnifiedProduct product) async {
    try {
      // Zamknij dialog szczegółów produktu
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Pokaż loading dialog tylko jeśli widget jest still mounted
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const PremiumLoadingWidget(message: 'Wyszukiwanie inwestorów...'),
      );

      // 🚀 UŻYJ ULTRA-PRECYZYJNEGO SERWISU z productId jeśli dostępne
      late UltraPreciseProductInvestorsResult ultraResult;

      // Sprawdź czy produkt ma zunifikowane ID
      final productId = product.id;
      if (productId.contains('_') &&
          (productId.startsWith('apartment_') ||
              productId.startsWith('bond_') ||
              productId.startsWith('loan_') ||
              productId.startsWith('share_'))) {
        if (kDebugMode) {
          print(
            '🎯 [ProductsManagement] Używam ultra-precyzyjnego serwisu z productId: $productId',
          );
        }
        ultraResult = await _ultraPreciseInvestorsService.getByProductId(
          productId,
        );
      } else {
        if (kDebugMode) {
          print(
            '🎯 [ProductsManagement] Używam ultra-precyzyjnego serwisu z productName: ${product.name}',
          );
        }
        ultraResult = await _ultraPreciseInvestorsService.getByProductName(
          product.name,
        );
      }

      // Zamknij loading dialog tylko jeśli widget jest still mounted
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Sprawdź mounted przed kolejnymi operacjami UI
      if (!mounted) return;

      if (ultraResult.isSuccess) {
        // Pokaż wyniki z ultra-precyzyjnego serwisu
        _showUltraPreciseInvestorsResultDialog(product, ultraResult);
      } else if (ultraResult.isEmpty) {
        // Pokaż dialog braku inwestorów
        _showEmptyUltraPreciseInvestorsDialog(product, ultraResult);
      } else {
        // Błąd - fallback na stary serwis
        if (kDebugMode) {
          print(
            '⚠️ [ProductsManagement] Ultra-precyzyjny serwis failed, fallback na stary: ${ultraResult.error}',
          );
        }
        await _showProductInvestorsLegacyFallback(product);
      }
    } catch (e) {
      // Zamknij loading dialog jeśli jest otwarty i widget jest mounted
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (kDebugMode) {
        print(
          '❌ [ProductsManagementScreen] Błąd podczas wyszukiwania inwestycji: $e',
        );
      }

      // Fallback na stary serwis tylko jeśli widget jest mounted
      if (mounted) {
        await _showProductInvestorsLegacyFallback(product);
      }
    }
  }

  /// 🚀 NOWA METODA: Pokaż wyniki z ultra-precyzyjnego serwisu
  void _showUltraPreciseInvestorsResultDialog(
    UnifiedProduct product,
    UltraPreciseProductInvestorsResult result,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        title: Row(
          children: [
            Icon(Icons.group, color: AppTheme.secondaryGold),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Inwestorzy produktu (${result.totalCount})',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
              ),
            ),
            // 🚀 Badge ultra-precyzyjny
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.secondaryGold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.secondaryGold.withOpacity(0.3),
                ),
              ),
              child: Text(
                'ULTRA-PRECISE',
                style: TextStyle(
                  color: AppTheme.secondaryGold,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informacje o produkcie
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundPrimary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceCard),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 ${product.name}',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip('Strategia', result.searchStrategy),
                        const SizedBox(width: 8),
                        _buildInfoChip('Czas', '${result.executionTime}ms'),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          'Cache',
                          result.fromCache ? 'TAK' : 'NIE',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                          'Kapitał',
                          '${(result.statistics.totalCapital / 1000).toStringAsFixed(0)}K PLN',
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          'Mapowanie',
                          '${result.mappingStats.successPercentage.toStringAsFixed(1)}%',
                        ),
                      ],
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
                      color: AppTheme.backgroundSecondary,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.secondaryGold.withOpacity(
                            0.2,
                          ),
                          child: Text(
                            investor.client.name.isNotEmpty
                                ? investor.client.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: AppTheme.secondaryGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          investor.client.name,
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inwestycji: ${investor.investmentCount}',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                            Text(
                              'Kapitał: ${(investor.totalRemainingCapital / 1000).toStringAsFixed(0)}K PLN',
                              style: TextStyle(color: AppTheme.secondaryGold),
                            ),
                          ],
                        ),
                        trailing: investor.client.isActive
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : Icon(Icons.warning, color: Colors.orange),
                        onTap: () {
                          // TODO: Pokaż szczegóły inwestora
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Zamknij',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  /// 🚀 NOWA METODA: Pokaż dialog braku inwestorów (ultra-precyzyjny)
  void _showEmptyUltraPreciseInvestorsDialog(
    UnifiedProduct product,
    UltraPreciseProductInvestorsResult result,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.secondaryGold),
            const SizedBox(width: 8),
            Text(
              'Brak inwestorów',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nie znaleziono inwestorów dla produktu:',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundPrimary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.surfaceCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 ${product.name}',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '🔍 Strategia: ${result.searchStrategy}',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  Text(
                    '⏱️ Czas wyszukiwania: ${result.executionTime}ms',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  Text(
                    '🎯 Klucz wyszukiwania: ${result.searchKey}',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Zamknij',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔄 LEGACY FALLBACK: Używa starego serwisu w przypadku błędu
  Future<void> _showProductInvestorsLegacyFallback(
    UnifiedProduct product,
  ) async {
    try {
      // Sprawdź mounted przed pokazaniem dialoga
      if (!mounted) return;

      // Pokaż loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const PremiumLoadingWidget(message: 'Fallback wyszukiwanie...'),
      );

      final ultraResult = await _ultraPreciseInvestorsService.getByProductName(
        product.name,
        forceRefresh: true, // Wymuś odświeżenie w fallback
      );

      // Sprawdź mounted po asynchronicznym wywołaniu
      if (!mounted) return;

      // Konwertuj na standardowy wynik
      final result = ProductInvestorsResult(
        investors: ultraResult.investors,
        totalCount: ultraResult.totalCount,
        statistics: ProductInvestorsStatistics(
          totalCapital: ultraResult.statistics.totalCapital,
          totalInvestments: ultraResult.statistics.totalInvestments,
          averageCapital: ultraResult.statistics.averageCapital,
          activeInvestors: ultraResult.totalCount,
        ),
        searchStrategy: 'legacy_fallback_ultra_precise',
        productName: product.name,
        productType: product.productType.name,
        executionTime: ultraResult.executionTime,
        fromCache: ultraResult.fromCache,
        error: ultraResult.error,
      );

      // Zamknij loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Sprawdź mounted przed kolejnymi operacjami UI
      if (!mounted) return;

      if (result.investors.isEmpty) {
        _showEmptyInvestorsDialog(product, result);
      } else {
        _showInvestorsResultDialog(product, result);
      }
    } catch (e) {
      // Zamknij loading dialog jeśli jest otwarty i widget jest mounted
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (kDebugMode) {
        print('❌ [ProductsManagementScreen] Błąd fallback wyszukiwania: $e');
      }

      // Pokaż snackbar tylko jeśli widget jest mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd wyszukiwania inwestorów: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🔧 HELPER: Tworzy chip z informacją
  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.secondaryGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.secondaryGold.withOpacity(0.2)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: AppTheme.secondaryGold,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showEmptyInvestorsDialog(
    UnifiedProduct product,
    ProductInvestorsResult result,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundSecondary,
        title: Text(
          'Brak inwestorów',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nie znaleziono inwestorów dla produktu:',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              '• Nazwa: ${product.name}',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            Text(
              '• Typ: ${product.productType.displayName}',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            if (result.debugInfo != null) ...[
              const SizedBox(height: 16),
              Text(
                'Informacje debugowania:',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '• Przeszukano inwestycji: ${result.debugInfo!.totalInvestmentsScanned}',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              Text(
                '• Dopasowane inwestycje: ${result.debugInfo!.matchingInvestments}',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Zamknij',
              style: TextStyle(color: AppTheme.secondaryGold),
            ),
          ),
        ],
      ),
    );
  }

  void _showInvestorsResultDialog(
    UnifiedProduct product,
    ProductInvestorsResult result,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.backgroundSecondary,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inwestorzy produktu',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Statystyki
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.premiumCardDecoration,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Inwestorów',
                      result.totalCount.toString(),
                      Icons.people,
                    ),
                    _buildStatItem(
                      'Kapitał',
                      '${(result.statistics.totalCapital / 1000000).toStringAsFixed(1)}M PLN',
                      Icons.account_balance_wallet,
                    ),
                    _buildStatItem(
                      'Średni kapitał',
                      '${(result.statistics.averageCapital / 1000).toStringAsFixed(0)}k PLN',
                      Icons.trending_up,
                    ),
                    _buildStatItem(
                      'Czas wyszukiwania',
                      '${result.executionTime}ms',
                      Icons.timer,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lista inwestorów
              Expanded(
                child: Container(
                  decoration: AppTheme.premiumCardDecoration,
                  child: ListView.builder(
                    itemCount: result.investors.length,
                    itemBuilder: (context, index) {
                      final investor = result.investors[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.secondaryGold,
                          child: Text(
                            investor.client.name.isNotEmpty
                                ? investor.client.name[0].toUpperCase()
                                : 'I',
                            style: TextStyle(color: AppTheme.textOnSecondary),
                          ),
                        ),
                        title: Text(
                          investor.client.name,
                          style: TextStyle(color: AppTheme.textPrimary),
                        ),
                        subtitle: Text(
                          '${investor.investmentCount} inwestycji',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        trailing: Text(
                          '${(investor.totalRemainingCapital / 1000).toStringAsFixed(0)}k PLN',
                          style: TextStyle(
                            color: AppTheme.secondaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          // TODO: Przejdź do szczegółów klienta
                          print('Kliknięto klienta: ${investor.client.name}');
                        },
                      );
                    },
                  ),
                ),
              ),

              if (result.fromCache)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cached,
                        size: 16,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Dane z cache (5 min)',
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.secondaryGold, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  // 🚀 NOWE METODY: Integracja z zoptymalizowanymi serwisami

  /// Odświeża cache używając nowych zoptymalizowanych serwisów
  Future<void> _refreshWithOptimizedServices() async {
    try {
      // Wyczyść cache wszystkich serwisów
      _analyticsMigrationService.clearAllCache();
      await _productManagementService.clearAllCache();

      // Reloaduj dane
      await _loadInitialData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.rocket_launch, color: Colors.white),
                SizedBox(width: 8),
                Text('🚀 Cache odświeżony z optymalizacjami'),
              ],
            ),
            backgroundColor: AppTheme.successPrimary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Błąd odświeżania: $e'),
            backgroundColor: AppTheme.errorPrimary,
          ),
        );
      }
    }
  }

  /// Sprawdza status cache wszystkich serwisów
  void _checkCacheStatus() {
    final migrationStatus = _analyticsMigrationService.getMigrationStatus();
    print('📊 [Products] Status migracji analityki: $migrationStatus');

    print('📊 [Products] Cache ProductManagementService sprawdzony');
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        onProductAdded: () {
          _refreshData();
        },
      ),
    );
  }

  Future<void> _showEmailDialog() async {
    if (_selectedProducts.isEmpty) {
      _showErrorSnackBar('Nie wybrano żadnych produktów');
      return;
    }

    // Konwertuj wybrane produkty na InvestorSummary dla kompatybilności
    final List<InvestorSummary> investorSummaries = [];

    for (final product in _selectedProducts) {
      // Utwórz tymczasowego klienta z danymi produktu
      final client = Client(
        id: product.companyId,
        name: product.companyName,
        email: '', // Będzie można edytować w dialogu
        phone: '',
        pesel: null,
        companyName: product.companyName,
        address: '',
        notes: '',
        isActive: product.status == ProductStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Tworzenie InvestorSummary z prawidłowymi parametrami
      final investorSummary = InvestorSummary(
        client: client,
        investments: [], // Puste - dialog pozwoli na edycję
        totalRemainingCapital: product.totalRemainingCapital,
        totalSharesValue: 0.0,
        totalValue: product.totalValue,
        totalInvestmentAmount: product.totalValue,
        totalRealizedCapital: 0.0,
        capitalSecuredByRealEstate: 0.0,
        capitalForRestructuring: 0.0,
        investmentCount: product.totalInvestments,
      );
      investorSummaries.add(investorSummary);
    }

    await showDialog(
      context: context,
      builder: (context) => EnhancedInvestorEmailDialog(
        selectedInvestors: investorSummaries,
        onEmailSent: () {
          // Wróć do normalnego trybu po wysłaniu email
          setState(() {
            _isSelectionMode = false;
            _selectedProductIds.clear();
          });
        },
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }
}

enum ViewMode { grid, list }

/// Dialog do dodawania nowego produktu
class AddProductDialog extends StatefulWidget {
  final VoidCallback onProductAdded;

  const AddProductDialog({super.key, required this.onProductAdded});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.backgroundSecondary,
      title: const Text(
        'Dodaj Nowy Produkt',
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      content: const Text(
        'Funkcjonalność dodawania produktów będzie dostępna wkrótce.',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Zamknij',
            style: TextStyle(color: AppTheme.secondaryGold),
          ),
        ),
      ],
    );
  }
}
