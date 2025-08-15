# Firebase Functions - Troubleshooting pobierania inwestycji

## Problem
Aplikacja nie pobiera inwestycji z Firebase Functions po zaimportowaniu znormalizowanych danych JSON.

## Wprowadzone zmiany (Styczeń 2025)

### 1. Dodano funkcję `getAllInvestments` do głównego eksportu
```javascript
// functions/index.js
const getAllInvestmentsService = require("./services/getAllInvestments-service");
// ...
...getAllInvestmentsService, // 🚀 DODANE
```

### 2. Zaktualizowano mapowanie typów produktów
```javascript
// functions/utils/data-mapping.js
function mapProductType(productType) {
  // ✅ Obsługa znormalizowanych typów z JSON:
  // "Apartamenty" -> "apartments"
  // "Obligacje" -> "bonds"  
  // "Udziały" -> "shares"
  // "Pożyczki" -> "loans"
}
```

### 3. Ulepszona konwersja dokumentów inwestycji
```javascript
// functions/services/getAllInvestments-service.js
function convertInvestmentData(doc) {
  // ✅ Obsługa logicznych ID (bond_0001, apartment_0045)
  // ✅ Mapowanie polskich nazw pól na angielskie
  // ✅ Obsługa formatów liczbowych z przecinkami
  // ✅ Enhanced error handling and logging
}
```

### 4. Dodana funkcja diagnostyczna
```javascript
// Nowa funkcja: diagnosticInvestments
// - Sprawdza stan kolekcji investments
// - Analizuje jakość danych
// - Provides troubleshooting suggestions
```

## Kroki weryfikacji

### 1. Deploy Firebase Functions
```bash
cd functions
firebase deploy --only functions
```

### 2. Sprawdź dostępność funkcji
W aplikacji Flutter/Dart wywołaj:
```dart
// Test basic function availability
final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
  .httpsCallable('getAllInvestments')
  .call();
```

### 3. Uruchom diagnozę
```dart
// Test diagnostic function
final diagnostic = await FirebaseFunctions.instanceFor(region: 'europe-west1')
  .httpsCallable('diagnosticInvestments')
  .call({
    'sampleSize': 10,
    'checkIndexes': true
  });

print('Diagnostic result: ${diagnostic.data}');
```

### 4. Sprawdź logi Firebase
```bash
firebase functions:log --only getAllInvestments
firebase functions:log --only diagnosticInvestments
```

## Oczekiwane wyniki

### Poprawne działanie
```json
{
  "investments": [...],
  "pagination": {
    "totalItems": 90, // Expected ~90 apartments
    "currentPage": 1,
    "hasNext": false
  },
  "metadata": {
    "diagnostic": {
      "totalDocuments": 90,
      "conversionErrors": 0,
      "successfulConversions": 90
    }
  }
}
```

### Funkcja diagnostyczna
```json
{
  "status": "HEALTHY",
  "totalDocuments": 90,
  "distribution": {
    "productTypes": {
      "Apartamenty": 90
    },
    "sourceFiles": {
      "apartments_normalized.json": 90  
    }
  },
  "dataQuality": {
    "documentsWithLogicalIds": "90/10",
    "documentsWithClientIds": "90/10", 
    "documentsWithAmounts": "90/10"
  }
}
```

## Rozwiązywanie problemów

### Problem: Brak dokumentów (totalDocuments: 0)
**Rozwiązanie:**
1. Sprawdź czy dane zostały zaimportowane: `npm run validate-investments`
2. Uruchom import ponownie: `npm run import-investments:full`
3. Sprawdź logi importu pod kątem błędów

### Problem: Błędy konwersji dokumentów
**Rozwiązanie:**
1. Sprawdź strukturę dokumentów w Firestore Console
2. Porównaj z oczekiwaną strukturą w Investment.dart
3. Uruchom diagnostykę z flagą `includeDebugInfo: true`

### Problem: Nieprawidłowe mapowanie typów produktów  
**Rozwiązanie:**
1. Sprawdź wartości pola `productType` w danych
2. Zweryfikuj mapowanie w `functions/utils/data-mapping.js`
3. Dodaj nowe mapowania jeśli potrzebne

### Problem: Błędne wartości finansowe
**Rozwiązanie:**
1. Sprawdź pola `investmentAmount`, `paymentAmount` w danych
2. Zweryfikuj funkcję `safeToDouble()` dla formatów z przecinkami
3. Sprawdź czy wartości nie są stringami "NULL"

## Testowanie w środowisku deweloperskim

### Firebase Emulator
```bash
# Uruchom lokalny emulator
firebase emulators:start --only functions,firestore

# Test z lokalnego emilatora
final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
  .useFunctionsEmulator('localhost', 5001)
  .httpsCallable('getAllInvestments')
  .call();
```

### Flutter DevTools
```dart
// Enable detailed logging in Flutter app
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  print('Firebase Functions Response: ${result.data}');
}
```

## Monitorowanie produkcyjne

### Firebase Console
1. Functions → getAllInvestments → Logs
2. Firestore → investments → Document count
3. Performance monitoring dla czasów odpowiedzi

### Alerting
Skonfiguruj alerty dla:
- Błędy funkcji > 5%
- Czas odpowiedzi > 30s  
- Brak dokumentów w kolekcji

## Następne kroki
1. Deploy i test wszystkich funkcji
2. Sprawdź kompatybilność z aplikacją Flutter
3. Monituj wydajność i błędy
4. Optimize cache settings jeśli potrzebne
