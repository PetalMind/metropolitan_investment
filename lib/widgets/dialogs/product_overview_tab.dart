import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/unified_product.dart';
import 'product_details_service.dart';

/// Zakładka ze szczegółami produktu
class ProductOverviewTab extends StatefulWidget {
  final UnifiedProduct product;

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
  final ProductDetailsService _service = ProductDetailsService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Szczegółowe informacje specyficzne dla typu produktu
              _buildProductSpecificDetails(),

              const SizedBox(height: 24),

              // Podstawowe informacje
              _buildBasicInformation(),

              const SizedBox(height: 24),

              // Opis produktu
              if (widget.product.description.isNotEmpty) ...[
                _buildDescriptionSection(),
                const SizedBox(height: 24),
              ],

              // Dodatkowe informacje
              if (widget.product.additionalInfo.isNotEmpty) ...[
                _buildAdditionalInfoSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Buduje szczegóły specyficzne dla typu produktu
  Widget _buildProductSpecificDetails() {
    switch (widget.product.productType) {
      case UnifiedProductType.bonds:
        return _buildBondsDetails();
      case UnifiedProductType.shares:
        return _buildSharesDetails();
      case UnifiedProductType.loans:
        return _buildLoansDetails();
      case UnifiedProductType.apartments:
        return _buildApartmentsDetails();
      case UnifiedProductType.other:
        return _buildOtherProductDetails();
    }
  }

  /// Szczegóły dla obligacji
  Widget _buildBondsDetails() {
    return _buildProductTypeContainer(
      title: 'Szczegóły Obligacji',
      subtitle: 'Informacje o instrumencie dłużnym',
      icon: Icons.account_balance,
      color: AppTheme.bondsColor,
      gradient: [
        AppTheme.bondsColor.withOpacity(0.1),
        AppTheme.bondsBackground,
      ],
      children: [
        if (widget.product.realizedCapital != null)
          _buildDetailRow(
            'Zrealizowany kapitał',
            _service.formatCurrency(widget.product.realizedCapital!),
          ),
        if (widget.product.remainingCapital != null)
          _buildDetailRow(
            'Pozostały kapitał',
            _service.formatCurrency(widget.product.remainingCapital!),
          ),
        if (widget.product.realizedInterest != null)
          _buildDetailRow(
            'Zrealizowane odsetki',
            _service.formatCurrency(widget.product.realizedInterest!),
          ),
        if (widget.product.remainingInterest != null)
          _buildDetailRow(
            'Pozostałe odsetki',
            _service.formatCurrency(widget.product.remainingInterest!),
          ),
        if (widget.product.interestRate != null)
          _buildDetailRow(
            'Oprocentowanie',
            '${widget.product.interestRate!.toStringAsFixed(2)}%',
          ),
        if (widget.product.maturityDate != null)
          _buildDetailRow(
            'Data zapadalności',
            _service.formatDate(widget.product.maturityDate!),
          ),
        if (widget.product.companyName != null)
          _buildDetailRow('Emitent', widget.product.companyName!),
      ],
    );
  }

  /// Szczegóły dla udziałów
  Widget _buildSharesDetails() {
    return _buildProductTypeContainer(
      title: 'Szczegóły Udziałów',
      subtitle: 'Informacje o udziałach w spółce',
      icon: Icons.trending_up,
      color: AppTheme.sharesColor,
      gradient: [
        AppTheme.sharesColor.withOpacity(0.1),
        AppTheme.sharesBackground,
      ],
      children: [
        if (widget.product.sharesCount != null)
          _buildDetailRow(
            'Liczba udziałów',
            widget.product.sharesCount.toString(),
          ),
        if (widget.product.pricePerShare != null)
          _buildDetailRow(
            'Cena za udział',
            _service.formatCurrency(widget.product.pricePerShare!),
          ),
        if (widget.product.companyName != null)
          _buildDetailRow('Nazwa spółki', widget.product.companyName!),
        _buildDetailRow(
          'Wartość całkowita',
          _service.formatCurrency(widget.product.totalValue),
        ),
      ],
    );
  }

  /// Szczegóły dla pożyczek
  Widget _buildLoansDetails() {
    return _buildProductTypeContainer(
      title: 'Szczegóły Pożyczki',
      subtitle: 'Informacje o produkcie pożyczkowym',
      icon: Icons.attach_money,
      color: AppTheme.loansColor,
      gradient: [
        AppTheme.loansColor.withOpacity(0.1),
        AppTheme.loansBackground,
      ],
      children: [
        if (widget.product.additionalInfo['borrower'] != null)
          _buildDetailRow(
            'Pożyczkobiorca',
            widget.product.additionalInfo['borrower'].toString(),
          ),
        if (widget.product.additionalInfo['creditorCompany'] != null)
          _buildDetailRow(
            'Spółka wierzyciel',
            widget.product.additionalInfo['creditorCompany'].toString(),
          ),
        if (widget.product.interestRate != null)
          _buildDetailRow(
            'Oprocentowanie',
            '${widget.product.interestRate!.toStringAsFixed(2)}%',
          ),
        if (widget.product.maturityDate != null)
          _buildDetailRow(
            'Termin spłaty',
            _service.formatDate(widget.product.maturityDate!),
          ),
        if (widget.product.additionalInfo['collateral'] != null)
          _buildDetailRow(
            'Zabezpieczenie',
            widget.product.additionalInfo['collateral'].toString(),
          ),
        if (widget.product.additionalInfo['status'] != null)
          _buildDetailRow(
            'Status pożyczki',
            widget.product.additionalInfo['status'].toString(),
          ),
      ],
    );
  }

  /// Szczegóły dla apartamentów
  Widget _buildApartmentsDetails() {
    return _buildProductTypeContainer(
      title: 'Szczegóły Apartamentu',
      subtitle: 'Informacje o nieruchomości',
      icon: Icons.apartment,
      color: AppTheme.apartmentsColor,
      gradient: [
        AppTheme.apartmentsColor.withOpacity(0.1),
        AppTheme.apartmentsBackground,
      ],
      children: [
        if (widget.product.additionalInfo['apartmentNumber'] != null)
          _buildDetailRow(
            'Numer apartamentu',
            widget.product.additionalInfo['apartmentNumber'].toString(),
          ),
        if (widget.product.additionalInfo['building'] != null)
          _buildDetailRow(
            'Budynek',
            widget.product.additionalInfo['building'].toString(),
          ),
        if (widget.product.additionalInfo['area'] != null)
          _buildDetailRow(
            'Powierzchnia',
            '${widget.product.additionalInfo['area']} m²',
          ),
        if (widget.product.additionalInfo['roomCount'] != null)
          _buildDetailRow(
            'Liczba pokoi',
            widget.product.additionalInfo['roomCount'].toString(),
          ),
        if (widget.product.additionalInfo['floor'] != null)
          _buildDetailRow(
            'Piętro',
            widget.product.additionalInfo['floor'].toString(),
          ),
        if (widget.product.additionalInfo['apartmentType'] != null)
          _buildDetailRow(
            'Typ apartamentu',
            widget.product.additionalInfo['apartmentType'].toString(),
          ),
        if (widget.product.additionalInfo['pricePerSquareMeter'] != null)
          _buildDetailRow(
            'Cena za m²',
            '${widget.product.additionalInfo['pricePerSquareMeter']} PLN/m²',
          ),
        if (widget.product.additionalInfo['address'] != null)
          _buildDetailRow(
            'Adres',
            widget.product.additionalInfo['address'].toString(),
          ),
        // Dodatkowe amenity
        const SizedBox(height: 16),
        _buildAmenities(),
      ],
    );
  }

  /// Szczegóły dla innych produktów
  Widget _buildOtherProductDetails() {
    return _buildProductTypeContainer(
      title: 'Szczegóły Produktu',
      subtitle: 'Informacje o produkcie inwestycyjnym',
      icon: Icons.inventory,
      color: AppTheme.primaryColor,
      gradient: [
        AppTheme.primaryColor.withOpacity(0.1),
        AppTheme.backgroundTertiary,
      ],
      children: [
        _buildDetailRow(
          'Wartość całkowita',
          _service.formatCurrency(widget.product.totalValue),
        ),
        if (widget.product.companyName != null)
          _buildDetailRow('Firma', widget.product.companyName!),
        if (widget.product.currency != null)
          _buildDetailRow('Waluta', widget.product.currency!),
      ],
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
  Widget _buildAmenities() {
    final amenities = <Widget>[];

    if (widget.product.additionalInfo['hasBalcony'] == true) {
      amenities.add(_buildAmenityChip('Balkon', Icons.balcony));
    }

    if (widget.product.additionalInfo['hasParkingSpace'] == true) {
      amenities.add(_buildAmenityChip('Parking', Icons.local_parking));
    }

    if (widget.product.additionalInfo['hasStorage'] == true) {
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
  Widget _buildBasicInformation() {
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
          _buildDetailRow(
            'Typ produktu',
            widget.product.productType.displayName,
          ),
          _buildDetailRow(
            'Status',
            widget.product.isActive ? 'Aktywny' : 'Nieaktywny',
          ),
          _buildDetailRow(
            'Kwota inwestycji',
            _service.formatCurrency(widget.product.investmentAmount),
          ),
          _buildDetailRow(
            'Data utworzenia',
            _service.formatDate(widget.product.createdAt),
          ),
          _buildDetailRow(
            'Ostatnia aktualizacja',
            _service.formatDate(widget.product.uploadedAt),
          ),
          _buildDetailRow('Waluta', widget.product.currency ?? 'PLN'),
        ],
      ),
    );
  }

  /// Buduje sekcję opisu
  Widget _buildDescriptionSection() {
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
              widget.product.description,
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

  /// Buduje sekcję dodatkowych informacji
  Widget _buildAdditionalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.neutralPrimary.withOpacity(0.05),
            AppTheme.neutralBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.neutralPrimary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Dodatkowe Informacje',
            'Inne dane o produkcie',
            Icons.more_horiz,
            AppTheme.neutralPrimary,
          ),
          const SizedBox(height: 20),
          ...widget.product.additionalInfo.entries
              .where((entry) => !_service.isSpecialField(entry.key))
              .map(
                (entry) => _buildDetailRow(
                  _service.formatFieldName(entry.key),
                  entry.value.toString(),
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
