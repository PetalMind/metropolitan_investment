# CLIENTS_SCREEN_STATISTICS_FIX.md

## Problem z wyświetlaniem statystyk w widoku klientów `/clients`

### Opis problemu
W widoku klientów (`/clients`) wyświetlały się niepoprawne statystyki:
- Kapitał pozostały: **0.0M PLN** 
- Inne statystyki również mogły być niepoprawne

### Diagnoza przyczyny
Problem występował na poziomie `IntegratedClientService.getClientStats()`:

1. **Firebase Functions** - główne źródło danych zwracało niepoprawne dane (prawdopodobnie "0.0M PLN")
2. **Fallback do InvestmentService** - metoda `getInvestmentStatistics()` używa różnych pól do kalkulacji `totalValue`:
   - Dla obligacji: `remainingCapital` (kapitał pozostały)
   - Dla innych produktów: `investmentAmount` (kwota pierwotna)
3. **Niepoprawne mapowanie** - w fallback używano `totalValue` z `InvestmentService` jako `totalRemainingCapital`, co dla produktów innych niż obligacje oznaczało kwotę pierwotną, a nie kapitał pozostały.

### Rozwiązanie
Wykorzystano już istniejące narzędzia w projekcie:

#### 1. Zastosowano `UnifiedStatisticsUtils`
```dart
import 'unified_statistics_utils.dart';

// W IntegratedClientService dodano metodę:
Future<ClientStats> _getUnifiedClientStats() async {
  final investmentsSnapshot = await FirebaseFirestore.instance
      .collection('investments')
      .get();

  final investmentsData = investmentsSnapshot.docs
      .map((doc) => {'id': doc.id, ...doc.data()})
      .toList();

  final unifiedStats = UnifiedSystemStats.fromInvestments(investmentsData);
  // ...
}
```

#### 2. Poprawiono logikę fallback
- **Pierwszy fallback**: Firebase Functions (bez zmian)
- **Drugi fallback**: Zunifikowane statystyki z `UnifiedStatisticsUtils`  
- **Trzeci fallback**: Standardowy `ClientService` (podstawowe dane)

#### 3. Użyto `viableCapital` zamiast `totalValue`
```dart
totalRemainingCapital: unifiedStats.viableCapital, // Tylko aktywne inwestycje
```

### Definicje zunifikowanych statystyk
Zgodnie z `STATISTICS_UNIFICATION_GUIDE.md`:

- **TOTAL_VALUE** = `remainingCapital` + `remainingInterest`
- **VIABLE_CAPITAL** = `remainingCapital` WHERE `productStatus = 'Aktywny'`
- **MAJORITY_THRESHOLD** = `viableCapital * 0.51`

### Mapowanie pól
Zunifikowane mapowanie z `UnifiedFieldMapping`:
```dart
'remainingCapital': ['kapital_pozostaly', 'remainingCapital']
'remainingInterest': ['odsetki_pozostale', 'remainingInterest'] 
'investmentAmount': ['kwota_inwestycji', 'investmentAmount']
'productStatus': ['productStatus', 'status_produktu']
```

### Rezultat
Po naprawie statystyki w `/clients` powinny wyświetlać:
- **Łącznie klientów**: Rzeczywista liczba klientów
- **Inwestycje**: Rzeczywista liczba inwestycji  
- **Pozostały kapitał**: Suma kapitału pozostałego z aktywnych inwestycji (viable capital)

### Zmiany w kodzie

#### `lib/services/integrated_client_service.dart`
- ✅ Dodano import `unified_statistics_utils.dart`
- ✅ Dodano import `cloud_firestore/cloud_firestore.dart`
- ✅ Dodano metodę `_getUnifiedClientStats()`
- ✅ Zaktualizowano fallback w `getClientStats()`
- ✅ Usunięto nieużywany import `investment_service.dart`

#### Dodane pliki testowe
- ✅ `test_client_stats_fix.dart` - Test naprawy statystyk

### Test rozwiązania
```bash
cd /home/deb/Documents/metropolitan_investment
dart run test_client_stats_fix.dart
```

### Uwagi techniczne
1. **Performance**: Zunifikowane statystyki obliczają dane w czasie rzeczywistym z Firestore
2. **Cache**: `IntegratedClientService` dziedziczy cache z `BaseService` (5 min TTL)
3. **Error handling**: Wielopoziomowy fallback zapewnia działanie nawet przy awariach
4. **Kompatybilność**: Zmiany nie wpływają na inne części systemu

### Monitoring
W logach można sprawdzić źródło danych:
- `firebase-functions` - Firebase Functions działają poprawnie
- `unified-statistics` - Użyto zunifikowanych statystyk (fallback)
- `advanced-fallback` - Stary sposób z InvestmentService 
- `basic-fallback` - Tylko dane klientów bez inwestycji

### Przyszłe usprawnienia
1. Naprawa Firebase Functions aby zwracały poprawne dane
2. Optymalizacja zapytań Firestore dla dużych zbiorów danych
3. Dodanie więcej szczegółowych statystyk w interfejsie
