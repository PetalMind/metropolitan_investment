import 'base_service.dart';
import '../models_and_services.dart';

/// Legacy LoanService - używa teraz unified investments collection
/// Pozostawiona dla kompatybilności wstecznej
class LoanService extends BaseService {
  @Deprecated(
    'Use UnifiedProductService instead. Loan data is now in investments collection.',
  )
  Future<List<Loan>> getAllLoans() async {
    // Return empty list as loans are now in investments collection
    print('⚠️ [LoanService] DEPRECATED: Use UnifiedProductService instead');
    return [];
  }

  @Deprecated(
    'Use UnifiedProductService instead. Loan data is now in investments collection.',
  )
  Future<Loan?> getLoan(String id) async {
    print('⚠️ [LoanService] DEPRECATED: Use UnifiedProductService instead');
    return null;
  }

  @Deprecated(
    'Use InvestmentService instead. Loan data is now in investments collection.',
  )
  Future<String> createLoan(Loan loan) async {
    throw UnsupportedError(
      'LoanService is deprecated. Use InvestmentService instead.',
    );
  }

  @Deprecated(
    'Use InvestmentService instead. Loan data is now in investments collection.',
  )
  Future<void> updateLoan(String id, Map<String, dynamic> data) async {
    throw UnsupportedError(
      'LoanService is deprecated. Use InvestmentService instead.',
    );
  }

  @Deprecated(
    'Use InvestmentService instead. Loan data is now in investments collection.',
  )
  Future<void> deleteLoan(String id) async {
    throw UnsupportedError(
      'LoanService is deprecated. Use InvestmentService instead.',
    );
  }
}
