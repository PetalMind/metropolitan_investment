# 🔧 Aktualizacja InvestorEditService - Sierpień 2025

## Problem

Aplikacja używała logiki z `DeduplicatedProductService` która generowała ID produktów jako hashe lub używała ID pierwszej inwestycji. W Firebase masz już pole `productId` w każdej inwestycji, ale aplikacja nie korzystała z tych prawdziwych ID.

**Przykład problemu:**
- Firebase: `investment.productId = "bond_0734"`
- DeduplicatedService: `product.id = "bond_0735"` (hash lub ID pierwszej inwestycji)
- Aplikacja próbowała dopasować `product.id` do `investment.productId` ❌

## Rozwiązanie

### 1. Zaktualizowana logika wyszukiwania inwestycji

W metodzie `findInvestmentsForProduct()`:

```dart
// ⭐ NOWA STRATEGIA WYSZUKIWANIA (Sierpień 2025):
// 1. Najpierw szukaj po productId z Firebase (PREFEROWANE)
// 2. Potem po dokładnej nazwie + company + type  
// 3. Fallback po ID inwestycji (kompatybilność wsteczna)
// 4. Ostatni fallback - częściowe dopasowanie nazw
```

### 2. Zaktualizowana logika skalowania produktu

W metodzie `scaleProduct()`:

```dart
// ⭐ ZNAJDŹ PRAWDZIWY PRODUCTID Z FIREBASE
// Problem: product.id może być hashem z DeduplicatedProductService
// Rozwiązanie: Znajdź inwestycje tego produktu i użyj ich productId

final sampleInvestments = await _findSampleInvestmentsForProduct(product);
final realProductId = sampleInvestments.first.productId ?? sampleInvestments.first.id;

// Przekaż prawdziwy productId do Firebase Functions
await _investmentService.scaleProductInvestments(
  productId: realProductId, // ⭐ PRAWDZIWY ID Z FIREBASE
  ...
);
```

### 3. Nowa metoda pomocnicza

Dodano `_findSampleInvestmentsForProduct()` która:
- Bezpośrednio odpytuje Firebase
- Wyszukuje inwestycje po nazwie produktu + companyId
- Zwraca przykładowe inwestycje do określenia prawdziwego productId

## Korzyści

1. ✅ **Używa prawdziwych productId z Firebase** zamiast hashów
2. ✅ **Poprawne skalowanie produktów** - Firebase Functions otrzymują prawidłowe ID
3. ✅ **Lepsze wyszukiwanie inwestycji** - pierwszeństwo dla productId
4. ✅ **Kompatybilność wsteczna** - fallbacki dla starych danych
5. ✅ **Bardziej niezawodne** - mniej problemów z dopasowywaniem

## Zmienione pliki

- `lib/services/investor_edit_service.dart` - Główna logika
- Dodano import `cloud_firestore/cloud_firestore.dart`

## Testowanie

Po tych zmianach:

1. **Edycja inwestycji** powinna poprawnie znajdować inwestycje dla produktu
2. **Skalowanie produktu** powinno działać z prawdziwymi productId
3. **Logi** pokażą dokładny proces wyszukiwania:
   ```
   🔍 [InvestorEditService] KROK 1: Szukam po productId z Firebase
   ✅ [InvestorEditService] Znaleziono dopasowania po productId: 2
   ```

## Następne kroki

Jeśli nadal są problemy:

1. **Sprawdź logi** - nowa logika pokazuje szczegółowe kroki wyszukiwania
2. **Zweryfikuj productId w Firebase** - upewnij się że wszystkie inwestycje mają poprawne productId
3. **Rozważ migrację** - uruchom skrypt `add_product_ids_to_investments.js` żeby uzupełnić brakujące productId

## Kompatybilność

- ✅ Działa z istniejącymi danymi
- ✅ Nie zmienia struktury Firebase
- ✅ Zachowuje kompatybilność z DeduplicatedProductService
- ✅ Fallbacki dla przypadków brzegowych
