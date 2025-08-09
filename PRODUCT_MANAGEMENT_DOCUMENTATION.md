# Dokumentacja funkcjonalności Edycji i Usuwania Produktów

## Przegląd

Dodano funkcjonalność edycji i usuwania produktów do dialogu szczegółów produktów. Nowe funkcje obejmują:

- **Przyciski akcji w headerze**: Edycja i Usuń
- **Nowoczesny dialog edycji**: Z walidacją i animacjami
- **Inteligentny dialog usuwania**: Sprawdza powiązania przed usunięciem
- **Loading states**: Podczas wykonywania operacji
- **Proper error handling**: Z możliwością retry

## Struktura plików

### Nowe pliki:
- `lib/services/unified_product_management_service.dart` - Serwis do zarządzania produktami
- `lib/widgets/dialogs/product_edit_dialog.dart` - Dialog edycji produktu  
- `lib/widgets/dialogs/product_delete_dialog.dart` - Dialog usuwania produktu
- `lib/widgets/dialogs/index.dart` - Eksporter dialogów

### Zmodyfikowane pliki:
- `lib/widgets/product_details_dialog.dart` - Dodano przyciski akcji w header

## Użycie

### Otwieranie dialogu produktu z nowymi funkcjonalnościami

```dart
showDialog(
  context: context,
  builder: (context) => EnhancedProductDetailsDialog(
    product: selectedProduct, // UnifiedProduct
  ),
);
```

### Bezpośrednie użycie dialogu edycji

```dart
showDialog(
  context: context,
  builder: (context) => ProductEditDialog(
    product: productToEdit,
    onProductUpdated: () {
      // Odśwież dane po aktualizacji
      refreshProductsList();
    },
  ),
);
```

### Bezpośrednie użycie dialogu usuwania

```dart
showDialog(
  context: context,
  builder: (context) => ProductDeleteDialog(
    product: productToDelete,
    onProductDeleted: () {
      // Usuń produkt z listy po potwierdzeniu
      refreshProductsList();
    },
  ),
);
```

## Funkcje dialogu edycji

### Pola do edycji:
- **Nazwa produktu** - wymagane
- **Kwota inwestycji** - wymagane, walidacja liczbowa
- **Oprocentowanie** - opcjonalne, walidacja 0-100%
- **Waluta** - wymagane, 3 znaki (PLN, USD itp.)
- **Opis** - opcjonalne, do 500 znaków

### Funkcje:
- ✅ Walidacja formularza w czasie rzeczywistym
- ✅ Śledzenie zmian - przycisk "Zapisz" aktywny tylko gdy są zmiany
- ✅ Potwierdzenie wyjścia przy niezapisanych zmianach
- ✅ Loading state podczas zapisywania
- ✅ Animacje przejść i pól
- ✅ Responsywny design

## Funkcje dialogu usuwania

### Inteligentne sprawdzanie:
- **Sprawdza powiązania** - inwestycje, dane systemowe
- **Rekomenduje akcję** - hard delete vs soft delete
- **Pokazuje ostrzeżenia** - jeśli są powiązania

### Opcje usuwania:
- **Usuń trwale** - całkowite usunięcie z bazy (tylko jeśli brak powiązań)
- **Dezaktywuj** - soft delete, oznacza jako nieaktywny

### Funkcje:
- ✅ Sprawdzenie powiązań przed usunięciem
- ✅ Dwuetapowe potwierdzenie dla trwałego usunięcia  
- ✅ Loading state podczas operacji
- ✅ Animacje błędów (shake effect)
- ✅ Szczegółowe informacje o produkcie

## Serwis zarządzania produktami

### UnifiedProductManagementService

#### Metody:
- `deleteProduct(product)` - Trwałe usunięcie
- `softDeleteProduct(product)` - Soft delete  
- `updateProduct(product, updates)` - Aktualizacja
- `createProduct(type, data)` - Tworzenie nowego
- `checkProductDeletion(product)` - Sprawdzenie możliwości usunięcia
- `getProductDetails(id, type)` - Szczegóły produktu

#### Obsługiwane kolekcje:
- `bonds` - Obligacje
- `shares` - Udziały  
- `loans` - Pożyczki
- `apartments` - Apartamenty
- `products` - Pozostałe produkty

## Bezpieczeństwo i walidacja

### Sprawdzanie powiązań:
```dart
final check = await managementService.checkProductDeletion(product);
if (check.canDelete) {
  // Bezpieczne usunięcie
} else {
  // Tylko soft delete, pokazuj ostrzeżenia
  print('Ostrzeżenia: ${check.warningsText}');
}
```

### Aktualizacja z walidacją:
- Sprawdza obecność wymaganych pól
- Waliduje typy danych (liczby, daty)
- Automatycznie dodaje timestampy
- Czyści cache po operacji

## Obsługa błędów

### Try-catch dla wszystkich operacji Firebase
### Logging szczegółowy dla debugowania  
### User-friendly komunikaty błędów
### Możliwość retry w przypadku błędów

## Wydajność

### Cache clearing po operacjach
### Minimalne refreshe danych
### Lazy loading dla dużych dataset'ów  
### Animacje z hardware acceleration

## Testowanie

### Testowanie funkcjonalności:

1. **Test edycji**:
   - Otwórz dialog produktu
   - Kliknij "Edycja"  
   - Zmień pola
   - Zapisz zmiany
   - Sprawdź czy dane zostały zaktualizowane

2. **Test usuwania - bez powiązań**:
   - Wybierz produkt bez inwestycji
   - Kliknij "Usuń"
   - Wybierz "Usuń trwale"
   - Potwierdź usunięcie
   - Sprawdź czy produkt zniknął z bazy

3. **Test usuwania - z powiązaniami**:
   - Wybierz produkt z inwestycjami
   - Kliknij "Usuń"  
   - Sprawdź czy pokazuje ostrzeżenia
   - Opcja tylko "Dezaktywuj"
   - Sprawdź czy produkt został oznaczony jako nieaktywny

## Przykłady integracji

### W ekranie listy produktów:

```dart
class ProductsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            onTap: () => showDialog(
              context: context,
              builder: (context) => EnhancedProductDetailsDialog(
                product: product,
              ),
            ),
          );
        },
      ),
    );
  }
}
```

### W dashboardzie administracyjnym:

```dart
FloatingActionButton.extended(
  onPressed: () => showDialog(
    context: context,
    builder: (context) => ProductEditDialog(
      product: null, // null = nowy produkt
      onProductUpdated: refreshDashboard,
    ),
  ),
  label: Text('Dodaj produkt'),
  icon: Icon(Icons.add),
)
```

## Wsparcie i rozwiązywanie problemów

### Błędy Firebase:
- Sprawdź połączenie z internetem
- Zweryfikuj uprawnienia Firestore
- Sprawdź indeksy w Firebase Console

### Błędy walidacji:
- Sprawdź formaty dat
- Zweryfikuj typy liczbowe
- Sprawdź długość stringów

### Problemy z animacjami:
- Sprawdź czy device ma wystarczająco pamięci
- Zmniejsz duration animacji na słabszych urządzeniach
