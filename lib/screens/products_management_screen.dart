import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../models_and_services.dart';
import '../services/firebase_functions_products_service.dart' as fb;
import '../adapters/product_statistics_adapter.dart';
import '../widgets/premium_loading_widget.dart';
import '../widgets/premium_error_widget.dart';
import '../widgets/product_card_widget.dart';
import '../widgets/product_stats_widget.dart';
import '../widgets/product_filter_widget.dart';
import '../widgets/dialogs/product_details_dialog.dart';

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
  late final FirebaseFunctionsProductInvestorsService _productInvestorsService;
  late final DeduplicatedProductService _deduplicatedProductService;
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // Stan ekranu
  List<UnifiedProduct> _allProducts = [];
  List<UnifiedProduct> _filteredProducts = [];
  List<DeduplicatedProduct> _deduplicatedProducts = [];
  List<DeduplicatedProduct> _filteredDeduplicatedProducts = [];
  fb.ProductStatistics? _statistics;
  UnifiedProductsMetadata? _metadata;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

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
        print('📊 [ProductsManagementScreen]   - Typ: ${product.productType} (${product.productType.displayName})');
        print('📊 [ProductsManagementScreen]   - Collection: ${product.productType.collectionName}');
        print(
          '📊 [ProductsManagementScreen]   originalProduct: ${product.originalProduct?.runtimeType}',
        );
        if (product.originalProduct is Investment) {
          final inv = product.originalProduct as Investment;
          print('📊 [ProductsManagementScreen]   investmentId: ${inv.id}');
          print('📊 [ProductsManagementScreen]   - Original Investment Type: ${inv.productType} (${inv.productType.runtimeType})');
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

    print('🔍 [ProductsManagementScreen] Parametry z URL/Widget:');
    print(
      '🔍 [ProductsManagementScreen] highlightedProductId: ${widget.highlightedProductId}',
    );
    print(
      '🔍 [ProductsManagementScreen] highlightedInvestmentId: ${widget.highlightedInvestmentId}',
    );
    print('🔍 [ProductsManagementScreen] productName: $productName');
    print('🔍 [ProductsManagementScreen] productType: $productType');
    print('🔍 [ProductsManagementScreen] clientId: $clientId');
    print('🔍 [ProductsManagementScreen] clientName: $clientName');

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
    _productInvestorsService = FirebaseFunctionsProductInvestorsService();
    _deduplicatedProductService = DeduplicatedProductService();
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
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🔄 [ProductsManagementScreen] Rozpoczynam ładowanie danych...');

      // TEST: Sprawdź połączenie z Firebase Functions
      // Z fallback system, testy nie będą blokować aplikacji
      if (kDebugMode) {
        print(
          '🔄 [ProductsManagementScreen] Testowanie Firebase Functions (z fallback)...',
        );
        try {
          await _productService.testDirectFirestoreAccess();
          await _productService.testConnection();
        } catch (e) {
          print(
            '❌ [ProductsManagementScreen] Test połączenia nieudany (będzie używany fallback): $e',
          );
        }
      }

      // Pobierz produkty, statystyki i deduplikowane produkty równolegle
      final results = await Future.wait([
        _productService.getUnifiedProducts(
          pageSize: 1000, // Pobierz więcej na początku
          sortBy: _sortField.name,
          sortAscending: _sortDirection == SortDirection.ascending,
        ),
        _showDeduplicatedView
            ? _deduplicatedProductService
                  .getDeduplicatedProductStatistics()
                  .then(
                    (stats) =>
                        ProductStatisticsAdapter.adaptFromUnifiedToFB(stats),
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
          _filteredProducts = List.from(
            _allProducts,
          ); // Kopia dla filtrowania lokalnego
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

        print(
          '📊 [ProductsManagementScreen] Załadowano ${_allProducts.length} produktów, '
          'cache używany: ${_metadata?.cacheUsed ?? false}',
        );
      }
    } catch (e) {
      print('❌ [ProductsManagementScreen] Błąd podczas ładowania: $e');
      if (mounted) {
        setState(() {
          _error = 'Błąd podczas ładowania produktów: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Odświeża statystyki po przełączeniu trybu wyświetlania
  Future<void> _refreshStatistics() async {
    if (_statistics == null) return;

    try {
      final newStats = _showDeduplicatedView
          ? await _deduplicatedProductService
                .getDeduplicatedProductStatistics()
                .then(
                  (stats) =>
                      ProductStatisticsAdapter.adaptFromUnifiedToFB(stats),
                )
          : await _productService.getProductStatistics();

      if (mounted) {
        setState(() {
          _statistics = newStats;
        });
      }
    } catch (e) {
      print('❌ [ProductsManagementScreen] Błąd odświeżania statystyk: $e');
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
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    // Dodaj efekt wibracji dla lepszego UX
    HapticFeedback.mediumImpact();

    try {
      // Odśwież cache na serwerze
      await _productService.refreshCache();
      await _loadInitialData();

      print('🔄 [ProductsManagementScreen] Dane odświeżone');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _applyFiltersAndSearch() {
    print('🔄 [ProductsManagement] _applyFiltersAndSearch wywołane: showDeduplicated=$_showDeduplicatedView');
    if (_showDeduplicatedView) {
      _applyFiltersAndSearchForDeduplicatedProducts();
    } else {
      _applyFiltersAndSearchForRegularProducts();
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
    print('🔧 [ProductsManagement] Aplikowanie filtrów do deduplikowanych produktów...');
    print('🔧 [ProductsManagement] Filtry - typy: ${_filterCriteria.productTypes?.map((t) => t.displayName).join(", ")}');
    print('🔧 [ProductsManagement] Filtry - statusy: ${_filterCriteria.statuses?.map((s) => s.displayName).join(", ")}');
    print('🔧 [ProductsManagement] Filtry - firma: "${_filterCriteria.companyName}"');
    print('🔧 [ProductsManagement] Filtry - kwoty: ${_filterCriteria.minInvestmentAmount}-${_filterCriteria.maxInvestmentAmount}');
    
    if (_filterCriteria.productTypes != null && _filterCriteria.productTypes!.isNotEmpty) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        // Porównuj bezpośrednio UnifiedProductType z UnifiedProductType
        final matches = _filterCriteria.productTypes!.contains(product.productType);
        if (!matches) {
          print('🔧 [ProductsManagement] Filtrowanie - odrzucam "${product.name}" (${product.productType.displayName}) - nie pasuje do ${_filterCriteria.productTypes!.map((t) => t.displayName).join(", ")}');
        } else {
          print('🔧 [ProductsManagement] Filtrowanie - akceptuję "${product.name}" (${product.productType.displayName})');
        }
        return matches;
      }).toList();
      print('🔧 [ProductsManagement] Filtr typów: ${beforeCount} → ${filtered.length}');
    }
    
    if (_filterCriteria.statuses != null && _filterCriteria.statuses!.isNotEmpty) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        final matches = _filterCriteria.statuses!.contains(product.status);
        return matches;
      }).toList();
      print('🔧 [ProductsManagement] Filtr statusów: ${beforeCount} → ${filtered.length}');
    }
    
    if (_filterCriteria.companyName != null && _filterCriteria.companyName!.isNotEmpty) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        final matches = product.companyName.toLowerCase().contains(_filterCriteria.companyName!.toLowerCase());
        return matches;
      }).toList();
      print('🔧 [ProductsManagement] Filtr firmy: ${beforeCount} → ${filtered.length}');
    }
    
    if (_filterCriteria.minInvestmentAmount != null) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        final matches = product.averageInvestment >= _filterCriteria.minInvestmentAmount!;
        return matches;
      }).toList();
      print('🔧 [ProductsManagement] Filtr min kwoty: ${beforeCount} → ${filtered.length}');
    }
    
    if (_filterCriteria.maxInvestmentAmount != null) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        final matches = product.averageInvestment <= _filterCriteria.maxInvestmentAmount!;
        return matches;
      }).toList();
      print('🔧 [ProductsManagement] Filtr max kwoty: ${beforeCount} → ${filtered.length}');
    }

    if (_filterCriteria.minInterestRate != null) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        final rate = product.interestRate ?? 0.0;
        final matches = rate >= _filterCriteria.minInterestRate!;
        return matches;
      }).toList();
      print('🔧 [ProductsManagement] Filtr min oprocentowania: ${beforeCount} → ${filtered.length}');
    }
    
    if (_filterCriteria.maxInterestRate != null) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        final rate = product.interestRate ?? 0.0;
        final matches = rate <= _filterCriteria.maxInterestRate!;
        return matches;
      }).toList();
      print('🔧 [ProductsManagement] Filtr max oprocentowania: ${beforeCount} → ${filtered.length}');
    }

    if (_filterCriteria.createdAfter != null) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        final matches = product.earliestInvestmentDate.isAfter(_filterCriteria.createdAfter!) || 
                       product.earliestInvestmentDate.isAtSameMomentAs(_filterCriteria.createdAfter!);
        return matches;
      }).toList();
      print('🔧 [ProductsManagement] Filtr daty początkowej: ${beforeCount} → ${filtered.length}');
    }
    
    if (_filterCriteria.createdBefore != null) {
      final beforeCount = filtered.length;
      filtered = filtered.where((product) {
        final matches = product.latestInvestmentDate.isBefore(_filterCriteria.createdBefore!) || 
                       product.latestInvestmentDate.isAtSameMomentAs(_filterCriteria.createdBefore!);
        return matches;
      }).toList();
      print('🔧 [ProductsManagement] Filtr daty końcowej: ${beforeCount} → ${filtered.length}');
    }
    
    print('🔧 [ProductsManagement] Filtry zastosowane: ${_deduplicatedProducts.length} → ${filtered.length}');

    print('🔄 [ProductsManagement] Sortowanie ${filtered.length} deduplikowanych produktów po: ${_sortField.displayName} (${_sortDirection.displayName})');
    
    // Debug: wypisz pierwsze 3 produkty przed sortowaniem
    if (filtered.length > 0) {
      print('🔧 [ProductsManagement] PRZED sortowaniem:');
      for (int i = 0; i < filtered.length && i < 3; i++) {
        final product = filtered[i];
        print('🔧 [ProductsManagement]   ${i+1}. ${product.name} - ${product.productType.displayName} (${product.productType.collectionName})');
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
        print('🔧 [ProductsManagement] Porównywanie DEDUPLIKOWANE "${a.name}" (${a.productType.collectionName}/${a.productType.displayName}) vs "${b.name}" (${b.productType.collectionName}/${b.productType.displayName}) = $comparison (result: $result)');
      }
      
      return result;
    });

    setState(() {
      _filteredDeduplicatedProducts = filtered;
    });
    
    print('🔄 [ProductsManagement] Sortowanie deduplikowanych produktów zakończone, znaleziono: ${_filteredDeduplicatedProducts.length}');
  }

  void _sortProducts(List<UnifiedProduct> products) {
    print('🔄 [ProductsManagement] Sortowanie ${products.length} zwykłych produktów po: ${_sortField.displayName} (${_sortDirection.displayName})');
    
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
        print('🔧 [ProductsManagement] Porównywanie ZWYKLE "${a.name}" (${a.productType.collectionName}/${a.productType.displayName}) vs "${b.name}" (${b.productType.collectionName}/${b.productType.displayName}) = $comparison (result: $result)');
      }
      
      return result;
    });
    
    print('🔄 [ProductsManagement] Sortowanie zakończone');
  }

  void _onFilterChanged(ProductFilterCriteria criteria) {
    print('🔧 [ProductsManagement] _onFilterChanged wywołane');
    print('🔧 [ProductsManagement] Nowe kryteria: productTypes=${criteria.productTypes?.map((t) => t.displayName).join(", ")}, statuses=${criteria.statuses?.map((s) => s.displayName).join(", ")}');
    print('🔧 [ProductsManagement] Firma: "${criteria.companyName}", kwoty: ${criteria.minInvestmentAmount}-${criteria.maxInvestmentAmount}');
    print('🔧 [ProductsManagement] Poprzednie kryteria: productTypes=${_filterCriteria?.productTypes?.map((t) => t.displayName).join(", ")}, statuses=${_filterCriteria?.statuses?.map((s) => s.displayName).join(", ")}');
    setState(() {
      _filterCriteria = criteria;
    });
    print('🔧 [ProductsManagement] setState zakończone, wywołuję _applyFiltersAndSearch');
    _applyFiltersAndSearch();
  }

  void _onSortChanged(ProductSortField field, SortDirection direction) {
    print('🔄 [ProductsManagement] Sortowanie zmienione na: ${field.displayName} (${direction.displayName})');
    print('🔄 [ProductsManagement] Poprzednie sortowanie: ${_sortField.displayName} (${_sortDirection.displayName})');
    setState(() {
      _sortField = field;
      _sortDirection = direction;
    });
    print('🔄 [ProductsManagement] setState zakończone, wywołuję _applyFiltersAndSearch');
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
              child: PremiumLoadingWidget(message: 'Ładowanie produktów...'),
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
                      'Zarządzanie Produktami',
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
        key: ValueKey('deduplicated_list_${_sortField.name}_${_sortDirection.name}'),
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
    return FloatingActionButton.extended(
      onPressed: _showAddProductDialog,
      backgroundColor: AppTheme.secondaryGold,
      foregroundColor: AppTheme.textOnSecondary,
      icon: const Icon(Icons.add),
      label: const Text('Dodaj Produkt'),
      elevation: 8,
    );
  }

  Widget _buildDeduplicatedProductCard(DeduplicatedProduct product, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.premiumCardDecoration,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDeduplicatedProductDetails(product),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                    child: _buildStatColumn(
                      'Łączna wartość',
                      '${(product.totalValue / 1000000).toStringAsFixed(1)}M PLN',
                      Icons.account_balance_wallet,
                    ),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      'Inwestorów',
                      '${product.uniqueInvestors}',
                      Icons.people,
                    ),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      'Pozostały kapitał',
                      '${(product.totalRemainingCapital / 1000000).toStringAsFixed(1)}M PLN',
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
                          'Duplikacja: ${(product.duplicationRatio * 100).toStringAsFixed(1)}% (${product.totalInvestments - product.uniqueInvestors} duplikatów)',
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
        'uniqueInvestors': deduped.uniqueInvestors,
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

  /// Pokazuje inwestorów dla danego produktu
  void _showProductInvestors(UnifiedProduct product) async {
    try {
      // Zamknij dialog szczegółów produktu
      Navigator.of(context).pop();

      // Pokaż loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const PremiumLoadingWidget(message: 'Wyszukiwanie inwestorów...'),
      );

      final result = await _productInvestorsService.getProductInvestors(
        productName: product.name,
        productType: product.productType.name,
        searchStrategy: 'comprehensive',
      );

      // Zamknij loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result.investors.isEmpty) {
        if (mounted) {
          _showEmptyInvestorsDialog(product, result);
        }
      } else {
        if (mounted) {
          _showInvestorsResultDialog(product, result);
        }
      }
    } catch (e) {
      // Zamknij loading dialog jeśli jest otwarty
      if (mounted) {
        Navigator.of(context).pop();
      }

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
