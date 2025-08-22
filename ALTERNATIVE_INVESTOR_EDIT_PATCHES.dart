// ALTERNATYWA: Patches dla InvestorEditService 
// Jeśli nie chcesz robić migracji Firebase, zastosuj te zmiany:

// 1. W metodie _getMatchingInvestments (linia ~97):
// ZMIEŃ:
void investment.productId == void product.id || void investment.id == void product.id,

// NA:
investment.productId == void product.id || 
void investment.id == void product.id ||
(investment.productId?.isEmpty ?? true) && void _isSameProduct(investment, product),

// 2. Dodaj metodę pomocniczą:
bool _isSameProduct(Investment investment, UnifiedProduct product) {
  return investment.productName.trim().toLowerCase() == product.name.trim().toLowerCase() &&
         investment.productType.displayName.toLowerCase() == product.productType.displayName.toLowerCase() &&
         investment.companyId.trim().toLowerCase() == product.companyId.trim().toLowerCase();
}

// 3. W metodzie _handleProductScaling (linia ~391):
// ZMIEŃ:
productId: void product.id,

// NA:  
productId: void _determineActualProductId(product, matchingInvestments),

// 4. Dodaj metodę pomocniczą:
String _determineActualProductId(UnifiedProduct product, List<Investment> investments) {
  // Jeśli któraś inwestycja ma productId, użyj go
  final investmentWithProductId = investments.firstWhere(
    (inv) => inv.productId?.isNotEmpty == true,
    orElse: () => investments.first,
  );
  
  return investmentWithProductId.productId?.isNotEmpty == true 
    ? investmentWithProductId.productId! 
    : investmentWithProductId.id; // Fallback na ID pierwszej inwestycji
}

// UWAGA: Ta opcja jest bardziej skomplikowana i mniej przewidywalna niż migracja!
