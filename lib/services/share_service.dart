import 'base_service.dart';
import '../models_and_services.dart';

/// Legacy ShareService - używa teraz unified investments collection
/// Pozostawiona dla kompatybilności wstecznej
class ShareService extends BaseService {
  @Deprecated(
    'Use UnifiedProductService instead. Share data is now in investments collection.',
  )
  Future<List<Share>> getAllShares() async {
    // Return empty list as shares are now in investments collection
    print('⚠️ [ShareService] DEPRECATED: Use UnifiedProductService instead');
    return [];
  }

  @Deprecated(
    'Use UnifiedProductService instead. Share data is now in investments collection.',
  )
  Future<Share?> getShare(String id) async {
    print('⚠️ [ShareService] DEPRECATED: Use UnifiedProductService instead');
    return null;
  }

  @Deprecated(
    'Use InvestmentService instead. Share data is now in investments collection.',
  )
  Future<String> createShare(Share share) async {
    throw UnsupportedError(
      'ShareService is deprecated. Use InvestmentService instead.',
    );
  }

  @Deprecated(
    'Use InvestmentService instead. Share data is now in investments collection.',
  )
  Future<void> updateShare(String id, Map<String, dynamic> data) async {
    throw UnsupportedError(
      'ShareService is deprecated. Use InvestmentService instead.',
    );
  }

  @Deprecated(
    'Use InvestmentService instead. Share data is now in investments collection.',
  )
  Future<void> deleteShare(String id) async {
    throw UnsupportedError(
      'ShareService is deprecated. Use InvestmentService instead.',
    );
  }
}
