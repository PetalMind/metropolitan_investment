import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/unified_product.dart';
import '../models/bond.dart';
import '../models/share.dart';
import '../models/loan.dart';
import '../models/apartment.dart';
import '../models/product.dart';
import 'base_service.dart';

/// Serwis do zarządzania operacjami na produktach zunifikowanych
/// Obsługuje tworzenie, edycję i usuwanie produktów z różnych kolekcji
class UnifiedProductManagementService extends BaseService {
  /// Usuwa produkt z odpowiedniej kolekcji na podstawie typu
  Future<bool> deleteProduct(UnifiedProduct product) async {
    try {
      print(
        '🗑️ [UnifiedProductManagementService] Usuwanie produktu: ${product.name}',
      );
      print('  - ID: ${product.id}');
      print('  - Typ: ${product.productType.displayName}');
      print('  - Kolekcja: ${product.productType.collectionName}');

      // Sprawdź czy produkt ma ID
      if (product.id.isEmpty) {
        throw Exception('Nie można usunąć produktu bez ID');
      }

      // Usuń z odpowiedniej kolekcji
      await firestore
          .collection(product.productType.collectionName)
          .doc(product.id)
          .delete();

      print(
        '✅ [UnifiedProductManagementService] Produkt został usunięty pomyślnie',
      );

      // Wyczyść cache po operacji
      clearAllCache();

      return true;
    } catch (e) {
      logError('deleteProduct', e);
      print(
        '❌ [UnifiedProductManagementService] Błąd podczas usuwania produktu: $e',
      );
      return false;
    }
  }

  /// Aktualizuje produkt w odpowiedniej kolekcji
  Future<bool> updateProduct(
    UnifiedProduct product,
    Map<String, dynamic> updates,
  ) async {
    try {
      print(
        '✏️ [UnifiedProductManagementService] Aktualizacja produktu: ${product.name}',
      );
      print('  - ID: ${product.id}');
      print('  - Typ: ${product.productType.displayName}');
      print('  - Kolekcja: ${product.productType.collectionName}');
      print('  - Aktualizacje: ${updates.keys.join(', ')}');

      if (product.id.isEmpty) {
        throw Exception('Nie można zaktualizować produktu bez ID');
      }

      // Dodaj timestamp aktualizacji
      final updatesWithTimestamp = {
        ...updates,
        'ostatnia_aktualizacja': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await firestore
          .collection(product.productType.collectionName)
          .doc(product.id)
          .update(updatesWithTimestamp);

      print(
        '✅ [UnifiedProductManagementService] Produkt został zaktualizowany pomyślnie',
      );

      // Wyczyść cache po operacji
      clearAllCache();

      return true;
    } catch (e) {
      logError('updateProduct', e);
      print(
        '❌ [UnifiedProductManagementService] Błąd podczas aktualizacji produktu: $e',
      );
      return false;
    }
  }

  /// Tworzy nowy produkt w odpowiedniej kolekcji
  Future<String?> createProduct(
    UnifiedProductType productType,
    Map<String, dynamic> productData,
  ) async {
    try {
      print(
        '➕ [UnifiedProductManagementService] Tworzenie produktu typu: ${productType.displayName}',
      );
      print('  - Kolekcja: ${productType.collectionName}');
      print('  - Dane: ${productData.keys.join(', ')}');

      // Dodaj metadane
      final dataWithMetadata = {
        ...productData,
        'data_utworzenia': Timestamp.now(),
        'ostatnia_aktualizacja': Timestamp.now(),
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'source_file': 'app_created',
        'typ_produktu': productType.collectionName,
      };

      final docRef = await firestore
          .collection(productType.collectionName)
          .add(dataWithMetadata);

      print(
        '✅ [UnifiedProductManagementService] Produkt został utworzony z ID: ${docRef.id}',
      );

      // Wyczyść cache po operacji
      clearAllCache();

      return docRef.id;
    } catch (e) {
      logError('createProduct', e);
      print(
        '❌ [UnifiedProductManagementService] Błąd podczas tworzenia produktu: $e',
      );
      return null;
    }
  }

  /// Pobiera szczegółowe informacje o produkcie z konkretnej kolekcji
  Future<UnifiedProduct?> getProductDetails(
    String id,
    UnifiedProductType productType,
  ) async {
    try {
      final doc = await firestore
          .collection(productType.collectionName)
          .doc(id)
          .get();

      if (!doc.exists) {
        return null;
      }

      // Konwertuj na UnifiedProduct w zależności od typu
      switch (productType) {
        case UnifiedProductType.bonds:
          return UnifiedProduct.fromBond(Bond.fromFirestore(doc));
        case UnifiedProductType.shares:
          return UnifiedProduct.fromShare(Share.fromFirestore(doc));
        case UnifiedProductType.loans:
          return UnifiedProduct.fromLoan(Loan.fromFirestore(doc));
        case UnifiedProductType.apartments:
          return UnifiedProduct.fromApartment(Apartment.fromFirestore(doc));
        case UnifiedProductType.other:
          return UnifiedProduct.fromProduct(Product.fromFirestore(doc));
      }
    } catch (e) {
      logError('getProductDetails', e);
      return null;
    }
  }

  /// Sprawdza czy produkt można bezpiecznie usunąć
  Future<ProductDeletionCheck> checkProductDeletion(
    UnifiedProduct product,
  ) async {
    try {
      print(
        '🔍 [UnifiedProductManagementService] Sprawdzanie możliwości usunięcia produktu: ${product.name}',
      );

      // Sprawdź czy są jakieś inwestycje związane z produktem
      final investmentsQuery = await firestore
          .collection('investments')
          .where('nazwa_produktu', isEqualTo: product.name)
          .limit(1)
          .get();

      final hasInvestments = investmentsQuery.docs.isNotEmpty;

      // Sprawdź czy są jakieś powiązania w innych kolekcjach
      final relatedDataQuery = await firestore
          .collection('investor_summaries')
          .where('productId', isEqualTo: product.id)
          .limit(1)
          .get();

      final hasRelatedData = relatedDataQuery.docs.isNotEmpty;

      final canDelete = !hasInvestments && !hasRelatedData;

      final warnings = <String>[];
      if (hasInvestments) {
        warnings.add('Produkt ma powiązane inwestycje');
      }
      if (hasRelatedData) {
        warnings.add('Produkt ma powiązane dane w systemie');
      }

      print('  - Może być usunięty: $canDelete');
      print('  - Ostrzeżenia: ${warnings.join(', ')}');

      return ProductDeletionCheck(
        canDelete: canDelete,
        warnings: warnings,
        relatedInvestments: hasInvestments ? investmentsQuery.docs.length : 0,
        relatedData: hasRelatedData ? relatedDataQuery.docs.length : 0,
      );
    } catch (e) {
      logError('checkProductDeletion', e);
      return ProductDeletionCheck(
        canDelete: false,
        warnings: ['Błąd podczas sprawdzania: $e'],
        relatedInvestments: 0,
        relatedData: 0,
      );
    }
  }

  /// Soft delete - oznacza produkt jako nieaktywny zamiast usuwania
  Future<bool> softDeleteProduct(UnifiedProduct product) async {
    try {
      print(
        '🗃️ [UnifiedProductManagementService] Soft delete produktu: ${product.name}',
      );

      final updates = {
        'isActive': false,
        'is_active': false,
        'status': 'inactive',
        'deleted_at': Timestamp.now(),
        'ostatnia_aktualizacja': Timestamp.now(),
      };

      return await updateProduct(product, updates);
    } catch (e) {
      logError('softDeleteProduct', e);
      return false;
    }
  }

  /// Przywraca produkt po soft delete
  Future<bool> restoreProduct(UnifiedProduct product) async {
    try {
      print(
        '🔄 [UnifiedProductManagementService] Przywracanie produktu: ${product.name}',
      );

      final updates = {
        'isActive': true,
        'is_active': true,
        'status': 'active',
        'deleted_at': FieldValue.delete(),
        'ostatnia_aktualizacja': Timestamp.now(),
      };

      return await updateProduct(product, updates);
    } catch (e) {
      logError('restoreProduct', e);
      return false;
    }
  }

  /// Pobiera historię zmian produktu (jeśli jest dostępna)
  Future<List<Map<String, dynamic>>> getProductHistory(
    UnifiedProduct product,
  ) async {
    try {
      // Sprawdź czy istnieje kolekcja historii
      final historyQuery = await firestore
          .collection('product_history')
          .where('productId', isEqualTo: product.id)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return historyQuery.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      logError('getProductHistory', e);
      // Historia może nie być dostępna - nie jest to błąd krytyczny
      return [];
    }
  }
}

/// Klasa reprezentująca wynik sprawdzenia możliwości usunięcia produktu
class ProductDeletionCheck {
  final bool canDelete;
  final List<String> warnings;
  final int relatedInvestments;
  final int relatedData;

  const ProductDeletionCheck({
    required this.canDelete,
    required this.warnings,
    required this.relatedInvestments,
    required this.relatedData,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  String get warningsText => warnings.join('\n• ');
}
