import 'package:flutter/material.dart';
// CENTRALNY IMPORT zgodnie z wytycznymi (models + services)
import '../../models_and_services.dart';
import '../../theme/app_theme.dart';

/// Zakładka ze szczegółami produktu
class ProductOverviewTab extends StatefulWidget {
  final UnifiedProduct product; // Wejściowy produkt (może być niepełny / cache)

  const ProductOverviewTab({super.key, required this.product});

  @override
  State<ProductOverviewTab> createState() => _ProductOverviewTabState();
}

class _ProductOverviewTabState extends State<ProductOverviewTab>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final UnifiedProductModalService _modalService = UnifiedProductModalService();

  ProductModalData? _modalData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // ⭐ UJEDNOLICONE POBIERANIE: Używamy UnifiedProductModalService
      final modalData = await _modalService.getProductModalData(
        product: widget.product,
        forceRefresh: false,
      );

      if (mounted) {
        setState(() {
          _modalData = modalData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _modalData = null; // fallback do przekazanych danych
          _isLoading = false;
        });
      }
    }
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

    _startAnimations();
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ⭐ UJEDNOLICONE DANE: Używamy danych z UnifiedProductModalService lub fallback
    var product = _modalData?.product ?? widget.product;

    // ⭐ POPRAWA NAZWY FIRMY: Spróbuj pobrać nazwę firmy z pierwszego inwestora jeśli nie ma lub jest "Nieznana firma"
    if (_modalData != null &&
        _modalData!.investors.isNotEmpty &&
        (product.companyName == null ||
            product.companyName!.isEmpty ||
            product.companyName?.toLowerCase() == 'nieznana firma')) {
      // Znajdź pierwszego inwestora z tą samą nazwą produktu
      final matchingInvestor = _modalData!.investors
          .where(
            (investor) => investor.investments.any(
              (inv) => inv.productName == product.name,
            ),
          )
          .firstOrNull;

      if (matchingInvestor != null) {
        final investment = matchingInvestor.investments
            .where((inv) => inv.productName == product.name)
            .firstOrNull;

        if (investment != null &&
            investment.creditorCompany.isNotEmpty &&
            investment.creditorCompany.toLowerCase() != 'nieznana firma') {
          // Utwórz nowy obiekt produktu z poprawioną nazwą firmy
          product = product.copyWith(companyName: investment.creditorCompany);
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        'Ładowanie aktualnych danych produktu…',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning_outlined,
                        color: AppTheme.warningPrimary,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Błąd UnifiedProductModalService: $_error',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.warningPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Używam danych z cache',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _loadProduct,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Ponów próbę'),
                      ),
                    ],
                  ),
                ),
              ),

            if (!_isLoading && _error == null) ...[
              // ⭐ INFORMACJA O ŹRÓDLE DANYCH
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.infoPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.infoPrimary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppTheme.infoPrimary,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),

              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProductSpecificDetails(product),
                      const SizedBox(height: 24),
                      _buildBasicInformation(product),
                      if (product.description.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildDescriptionSection(product),
                      ],
                      // UWAGA: Sekcja "Dodatkowe informacje" USUNIĘTA zgodnie z wymaganiem
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Buduje szczegóły specyficzne dla typu produktu
  Widget _buildProductSpecificDetails(UnifiedProduct product) {
    switch (product.productType) {
      case UnifiedProductType.bonds:
        return _buildBondsDetails(product);
      case UnifiedProductType.shares:
        return _buildSharesDetails(product);
      case UnifiedProductType.loans:
        return _buildLoansDetails(product);
      case UnifiedProductType.apartments:
        return _buildApartmentsDetails(product);
      case UnifiedProductType.other:
        return _buildOtherProductDetails(product);
    }
  }

  /// Szczegóły dla obligacji
  Widget _buildBondsDetails(UnifiedProduct product) {
    final children = <Widget>[];
    if (product.realizedCapital != null)
      children.add(
        _buildDetailRow(
          'Zrealizowany kapitał',
          CurrencyFormatter.formatCurrency(product.realizedCapital!),
        ),
      );
    if (product.remainingCapital != null)
      children.add(
        _buildDetailRow(
          'Pozostały kapitał',
          CurrencyFormatter.formatCurrency(product.remainingCapital!),
        ),
      );
    if (product.realizedInterest != null)
      children.add(
        _buildDetailRow(
          'Zrealizowane odsetki',
          CurrencyFormatter.formatCurrency(product.realizedInterest!),
        ),
      );
    if (product.remainingInterest != null)
      children.add(
        _buildDetailRow(
          'Pozostałe odsetki',
          CurrencyFormatter.formatCurrency(product.remainingInterest!),
        ),
      );
    if (product.interestRate != null)
      children.add(
        _buildDetailRow(
          'Oprocentowanie',
          '${product.interestRate!.toStringAsFixed(2)}%',
        ),
      );
    if (product.maturityDate != null)
      children.add(
        _buildDetailRow(
          'Data zapadalności',
          product.maturityDate!.toString().split(' ')[0],
        ),
      );
    if (product.companyName != null &&
        product.companyName!.isNotEmpty &&
        product.companyName?.toLowerCase() != 'nieznana firma')
      children.add(_buildDetailRow('Emitent', product.companyName!));
    if (children.isEmpty) return const SizedBox.shrink();
    return _buildProductTypeContainer(
      title: 'Szczegóły Obligacji',
      subtitle: 'Informacje o instrumencie dłużnym',
      icon: Icons.account_balance,
      color: AppTheme.bondsColor,
      gradient: [
        AppTheme.bondsColor.withOpacity(0.1),
        AppTheme.bondsBackground,
      ],
      children: children,
    );
  }

  /// Szczegóły dla udziałów
  Widget _buildSharesDetails(UnifiedProduct product) {
    final children = <Widget>[];
    if (product.sharesCount != null)
      children.add(
        _buildDetailRow('Liczba udziałów', product.sharesCount.toString()),
      );
    if (product.pricePerShare != null)
      children.add(
        _buildDetailRow(
          'Cena za udział',
          CurrencyFormatter.formatCurrency(product.pricePerShare!),
        ),
      );
    if (product.companyName != null &&
        product.companyName!.isNotEmpty &&
        product.companyName?.toLowerCase() != 'nieznana firma')
      children.add(_buildDetailRow('Nazwa spółki', product.companyName!));
    children.add(
      _buildDetailRow(
        'Wartość całkowita',
        CurrencyFormatter.formatCurrency(product.totalValue),
      ),
    );
    if (children.isEmpty) return const SizedBox.shrink();
    return _buildProductTypeContainer(
      title: 'Szczegóły Udziałów',
      subtitle: 'Informacje o udziałach w spółce',
      icon: Icons.trending_up,
      color: AppTheme.sharesColor,
      gradient: [
        AppTheme.sharesColor.withOpacity(0.1),
        AppTheme.sharesBackground,
      ],
      children: children,
    );
  }

  /// Szczegóły dla pożyczek
  Widget _buildLoansDetails(UnifiedProduct product) {
    final children = <Widget>[];
    final info = product.additionalInfo;
    if (info['borrower'] != null) {
      children.add(
        _buildDetailRow('Pożyczkobiorca', info['borrower'].toString()),
      );
    }
    if (info['creditorCompany'] != null) {
      children.add(
        _buildDetailRow(
          'Spółka wierzyciel',
          info['creditorCompany'].toString(),
        ),
      );
    }
    if (product.interestRate != null) {
      children.add(
        _buildDetailRow(
          'Oprocentowanie',
          '${product.interestRate!.toStringAsFixed(2)}%',
        ),
      );
    }
    if (product.maturityDate != null) {
      children.add(
        _buildDetailRow(
          'Termin spłaty',
          product.maturityDate!.toString().split(' ')[0],
        ),
      );
    }
    if (info['collateral'] != null) {
      children.add(
        _buildDetailRow('Zabezpieczenie', info['collateral'].toString()),
      );
    }
    if (info['status'] != null) {
      children.add(
        _buildDetailRow('Status pożyczki', info['status'].toString()),
      );
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return _buildProductTypeContainer(
      title: 'Szczegóły Pożyczki',
      subtitle: 'Informacje o produkcie pożyczkowym',
      icon: Icons.attach_money,
      color: AppTheme.loansColor,
      gradient: [
        AppTheme.loansColor.withOpacity(0.1),
        AppTheme.loansBackground,
      ],
      children: children,
    );
  }

  /// Szczegóły dla apartamentów
  Widget _buildApartmentsDetails(UnifiedProduct product) {
    final info = product.additionalInfo;
    final children = <Widget>[];
    void addIf(String key, String label, [String? suffix]) {
      final v = info[key];
      if (v != null && v.toString().isNotEmpty) {
        children.add(
          _buildDetailRow(
            label,
            suffix == null ? v.toString() : '${v.toString()} $suffix',
          ),
        );
      }
    }

    addIf('apartmentNumber', 'Numer apartamentu');
    addIf('building', 'Budynek');
    if (info['area'] != null) {
      children.add(_buildDetailRow('Powierzchnia', '${info['area']} m²'));
    }
    addIf('roomCount', 'Liczba pokoi');
    addIf('floor', 'Piętro');
    addIf('apartmentType', 'Typ apartamentu');
    if (info['pricePerSquareMeter'] != null) {
      children.add(
        _buildDetailRow('Cena za m²', '${info['pricePerSquareMeter']} PLN/m²'),
      );
    }
    addIf('address', 'Adres');
    // Amenity chips
    if (info['hasBalcony'] == true ||
        info['hasParkingSpace'] == true ||
        info['hasStorage'] == true) {
      children.add(const SizedBox(height: 16));
      children.add(_buildAmenities(product));
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return _buildProductTypeContainer(
      title: 'Szczegóły Apartamentu',
      subtitle: 'Informacje o nieruchomości',
      icon: Icons.apartment,
      color: AppTheme.apartmentsColor,
      gradient: [
        AppTheme.apartmentsColor.withOpacity(0.1),
        AppTheme.apartmentsBackground,
      ],
      children: children,
    );
  }

  /// Szczegóły dla innych produktów
  Widget _buildOtherProductDetails(UnifiedProduct product) {
    final children = <Widget>[];
    children.add(
      _buildDetailRow(
        'Wartość całkowita',
        CurrencyFormatter.formatCurrency(product.totalValue),
      ),
    );
    if (product.companyName != null &&
        product.companyName!.isNotEmpty &&
        product.companyName?.toLowerCase() != 'nieznana firma') {
      children.add(_buildDetailRow('Firma', product.companyName!));
    }
    if (product.currency != null) {
      children.add(_buildDetailRow('Waluta', product.currency!));
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return _buildProductTypeContainer(
      title: 'Szczegóły Produktu',
      subtitle: 'Informacje o produkcie inwestycyjnym',
      icon: Icons.inventory,
      color: AppTheme.primaryColor,
      gradient: [
        AppTheme.primaryColor.withOpacity(0.1),
        AppTheme.backgroundTertiary,
      ],
      children: children,
    );
  }

  /// Buduje kontener dla konkretnego typu produktu
  Widget _buildProductTypeContainer({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title, subtitle, icon, color),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  /// Buduje header sekcji
  Widget _buildSectionHeader(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Buduje amenities dla apartamentów
  Widget _buildAmenities(UnifiedProduct product) {
    final amenities = <Widget>[];
    final info = product.additionalInfo;
    if (info['hasBalcony'] == true) {
      amenities.add(_buildAmenityChip('Balkon', Icons.balcony));
    }
    if (info['hasParkingSpace'] == true) {
      amenities.add(_buildAmenityChip('Parking', Icons.local_parking));
    }
    if (info['hasStorage'] == true) {
      amenities.add(_buildAmenityChip('Komórka', Icons.storage));
    }
    if (amenities.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 8, children: amenities);
  }

  /// Buduje chip z amenity dla apartamentów
  Widget _buildAmenityChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.successPrimary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.successPrimary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.successPrimary, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.successPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Buduje podstawowe informacje o produkcie
  Widget _buildBasicInformation(UnifiedProduct product) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceElevated.withOpacity(0.6),
            AppTheme.surfaceCard,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderPrimary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Podstawowe Informacje',
            'Ogólne dane o produkcie',
            Icons.info_outline,
            AppTheme.secondaryGold,
          ),
          const SizedBox(height: 20),
          _buildDetailRow('Typ produktu', product.productType.displayName),
          _buildDetailRow(
            'Status',
            product.isActive ? 'Aktywny' : 'Nieaktywny',
          ),
          _buildDetailRow(
            'Kwota inwestycji',
            CurrencyFormatter.formatCurrency(product.investmentAmount),
          ),
          _buildDetailRow(
            'Data utworzenia',
            product.createdAt.toString().split(' ')[0],
          ),
          _buildDetailRow(
            'Ostatnia aktualizacja',
            product.uploadedAt.toString().split(' ')[0],
          ),
          _buildDetailRow('Waluta', product.currency ?? 'PLN'),
        ],
      ),
    );
  }

  /// Buduje sekcję opisu
  Widget _buildDescriptionSection(UnifiedProduct product) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.infoPrimary.withOpacity(0.05),
            AppTheme.infoBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.infoPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Opis Produktu',
            'Szczegółowy opis produktu',
            Icons.description_outlined,
            AppTheme.infoPrimary,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.borderSecondary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              product.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textPrimary,
                height: 1.6,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textTertiary,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
