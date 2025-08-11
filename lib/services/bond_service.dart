import 'base_service.dart';
import '../models_and_services.dart';

/// Legacy BondService - używa teraz unified investments collection
/// Pozostawiona dla kompatybilności wstecznej
class BondService extends BaseService {
  @Deprecated(
    'Use UnifiedProductService instead. Bond data is now in investments collection.',
  )
  Future<List<Bond>> getAllBonds() async {
    // Return empty list as bonds are now in investments collection
    print('⚠️ [BondService] DEPRECATED: Use UnifiedProductService instead');
    return [];
  }

  @Deprecated(
    'Use UnifiedProductService instead. Bond data is now in investments collection.',
  )
  Future<Bond?> getBond(String id) async {
    print('⚠️ [BondService] DEPRECATED: Use UnifiedProductService instead');
    return null;
  }

  @Deprecated(
    'Use InvestmentService instead. Bond data is now in investments collection.',
  )
  Future<String> createBond(Bond bond) async {
    throw UnsupportedError(
      'BondService is deprecated. Use InvestmentService instead.',
    );
  }

  @Deprecated(
    'Use InvestmentService instead. Bond data is now in investments collection.',
  )
  Future<void> updateBond(String id, Map<String, dynamic> data) async {
    throw UnsupportedError(
      'BondService is deprecated. Use InvestmentService instead.',
    );
  }

  @Deprecated(
    'Use InvestmentService instead. Bond data is now in investments collection.',
  )
  Future<void> deleteBond(String id) async {
    throw UnsupportedError(
      'BondService is deprecated. Use InvestmentService instead.',
    );
  }
}
