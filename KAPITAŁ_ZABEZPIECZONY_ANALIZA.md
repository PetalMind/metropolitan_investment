# 🔍 ANALIZA OBLICZANIA "KAPITAŁ ZABEZPIECZONY NIERUCHOMOŚCIAMI"

## Aktualna logika w aplikacji

### Lokalizacja w kodzie:
1. **Wyświetlanie**: `investor_details_modal.dart` → tab "Statystyki inwestycji"
2. **Obliczanie**: `InvestorSummary.fromInvestments()` w `/lib/models/investor_summary.dart`
3. **Źródło danych**: Firebase → pole `capitalSecuredByRealEstate` na głównym poziomie dokumentu

### Algorytm obliczania (linie 75-113 w investor_summary.dart):

```dart
// 1. Sprawdza różne nazwy pól w additionalInfo (w kolejności):
if (investment.additionalInfo.containsKey('capitalSecuredByRealEstate')) {
  // Pobiera z głównego poziomu Firebase
} else if (investment.additionalInfo['realEstateSecuredCapital'] != null) {
  // Alternatywna nazwa
} else if (investment.additionalInfo['Kapitał zabezpieczony nieruchomością'] != null) {
  // Polska nazwa
} else if (investment.additionalInfo['kapital_zabezpieczony_nieruchomoscia'] != null) {
  // Normalizowana polska nazwa
} else {
  // 2. AUTOMATYCZNE OBLICZENIE JAKO FALLBACK:
  final result = investment.remainingCapital - capitalForRestructuringValue;
  investmentCapitalSecured = result > 0 ? result : 0.0;
}
```

### Przykład obliczeń na podstawie Twoich danych Firebase:

**Dane z Firebase:**
```json
{
  "remainingCapital": 50000,
  "capitalSecuredByRealEstate": 0,     ← wartość z Firebase
  "capitalForRestructuring": 50000
}
```

**Co dzieje się w kodzie:**
1. `Investment.fromServerMap` kopiuje `capitalSecuredByRealEstate: 0` do `additionalInfo['realEstateSecuredCapital']`
2. `InvestorSummary.fromInvestments` znajduje wartość `0` w pierwszym kroku
3. **NIE używa** fallback obliczenia, bo wartość istnieje (choć jest 0)

**Wynik:** `capitalSecuredByRealEstate = 0`

## Możliwe problemy

### ❌ Problem 1: Błędne dane w Firebase
Jeśli w Firebase `capitalSecuredByRealEstate: 0` jest błędne, a powinno być obliczone automatycznie.

### ❌ Problem 2: Błędna logika fallback
Czy formuła `remainingCapital - capitalForRestructuring` jest poprawna biznesowo?

### ❌ Problem 3: Kolejność sprawdzania
Może powinno sprawdzać czy wartość > 0 zanim użyje z Firebase?

## Możliwe rozwiązania

### 🔧 Rozwiązanie 1: Zawsze używaj automatycznego obliczania
```dart
// Zawsze oblicz, ignoruj wartość z Firebase jeśli = 0
if (capitalSecuredFromFirebase > 0) {
  investmentCapitalSecured = capitalSecuredFromFirebase;
} else {
  // Automatyczne obliczenie
  final result = investment.remainingCapital - capitalForRestructuringValue;
  investmentCapitalSecured = result > 0 ? result : 0.0;
}
```

### 🔧 Rozwiązanie 2: Poprawa danych w Firebase
Zaktualizuj dane w Firebase, aby `capitalSecuredByRealEstate` miało poprawną wartość.

### 🔧 Rozwiązanie 3: Zmiana logiki biznesowej
Jeśli formuła `remainingCapital - capitalForRestructuring` jest niepoprawna, zastąp ją właściwą.

## Pytania biznesowe

1. **Co to znaczy "kapitał zabezpieczony nieruchomościami"?**
   - Czy to część kapitału pozostałego, która jest zabezpieczona nieruchomością?
   - Czy to oddzielna wartość niezależna od kapitału pozostałego?

2. **Jaka jest relacja między:**
   - `remainingCapital` (kapitał pozostały)
   - `capitalSecuredByRealEstate` (kapitał zabezpieczony nieruchomościami)  
   - `capitalForRestructuring` (kapitał do restrukturyzacji)

3. **Czy formuła jest poprawna:**
   ```
   kapitał_zabezpieczony = kapitał_pozostały - kapitał_do_restrukturyzacji
   ```

## Aktualny stan w Twoich danych:
- `remainingCapital`: 50,000 PLN
- `capitalSecuredByRealEstate`: 0 PLN (z Firebase)
- `capitalForRestructuring`: 50,000 PLN

**Wynik aplikacji:** 0 PLN (używa wartości z Firebase)
**Wynik fallback:** 50,000 - 50,000 = 0 PLN (ten sam rezultat)

---
**Wniosek:** Aplikacja działa zgodnie z logiką, ale być może **dane w Firebase lub logika biznesowa** wymagają korekty.
