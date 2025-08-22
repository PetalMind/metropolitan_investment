import '../models_and_services.dart';

/// Legacy ApartmentService - używa teraz unified investments collection
/// Pozostawiona dla kompatybilności wstecznej
class ApartmentService extends BaseService {
  @Deprecated(
    'Use UnifiedProductService instead. Apartment data is now in investments collection.',
  )
  Future<List<Apartment>> getAllApartments() async {
    // Return empty list as apartments are now in investments collection
    print(
      '⚠️ [ApartmentService] DEPRECATED: Use UnifiedProductService instead',
    );
    return [];
  }

  @Deprecated(
    'Use UnifiedProductService instead. Apartment data is now in investments collection.',
  )
  Future<Apartment?> getApartment(String id) async {
    print(
      '⚠️ [ApartmentService] DEPRECATED: Use UnifiedProductService instead',
    );
    return null;
  }

  @Deprecated(
    'Use InvestmentService instead. Apartment data is now in investments collection.',
  )
  Future<String> createApartment(Apartment apartment) async {
    throw UnsupportedError(
      'ApartmentService is deprecated. Use InvestmentService instead.',
    );
  }

  @Deprecated(
    'Use InvestmentService instead. Apartment data is now in investments collection.',
  )
  Future<void> updateApartment(String id, Map<String, dynamic> data) async {
    throw UnsupportedError(
      'ApartmentService is deprecated. Use InvestmentService instead.',
    );
  }

  @Deprecated(
    'Use InvestmentService instead. Apartment data is now in investments collection.',
  )
  Future<void> deleteApartment(String id) async {
    throw UnsupportedError(
      'ApartmentService is deprecated. Use InvestmentService instead.',
    );
  }
}
