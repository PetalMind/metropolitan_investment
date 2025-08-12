# Capital Calculation Service - Dokumentacja

## Przegląd

Capital Calculation Service to nowy moduł Firebase Functions, który oblicza i zapisuje pole **"Kapitał zabezpieczony nieruchomością"** bezpośrednio do bazy danych Firestore według wzoru:

```
Kapitał zabezpieczony nieruchomością = Kapitał Pozostały - Kapitał do restrukturyzacji
```

## Dostępne funkcje

### 1. `updateCapitalSecuredByRealEstate`
Główna funkcja do obliczania i zapisywania wartości do bazy danych.

**Parametry:**
- `batchSize` (opcjonalny, domyślnie 500) - rozmiar batcha dla wydajności
- `dryRun` (opcjonalny, domyślnie false) - tryb testowy bez zapisu do bazy
- `investmentId` (opcjonalny) - ID konkretnej inwestycji do aktualizacji
- `includeDetails` (opcjonalny, domyślnie false) - czy zwracać szczegóły wszystkich operacji

**Przykład wywołania z frontend:**
```javascript
const functions = getFunctions(app, 'europe-west1');
const updateCapital = httpsCallable(functions, 'updateCapitalSecuredByRealEstate');

// Test wszystkich inwestycji (tryb symulacji)
const dryRunResult = await updateCapital({
  dryRun: true,
  batchSize: 250,
  includeDetails: true
});

// Aktualizacja wszystkich inwestycji
const updateResult = await updateCapital({
  dryRun: false,
  batchSize: 500
});

// Aktualizacja konkretnej inwestycji
const singleResult = await updateCapital({
  investmentId: "specific_investment_id",
  dryRun: false
});
```

**Zwracane dane:**
```javascript
{
  processed: 1250,           // Liczba przetworzonych inwestycji
  updated: 890,              // Liczba zaktualizowanych inwestycji
  errors: 5,                 // Liczba błędów
  details: [...],            // Szczegóły (jeśli includeDetails=true)
  executionTimeMs: 12500,    // Czas wykonania w ms
  timestamp: "2025-08-12T...", 
  dryRun: false,
  summary: {
    successRate: "99.6%",
    updateRate: "71.2%"
  }
}
```

### 2. `checkCapitalCalculationStatus`
Sprawdza status obliczeń - ile inwestycji ma prawidłowe/nieprawidłowe wartości.

**Parametry:** Brak

**Przykład wywołania:**
```javascript
const checkStatus = httpsCallable(functions, 'checkCapitalCalculationStatus');
const status = await checkStatus();
```

**Zwracane dane:**
```javascript
{
  statistics: {
    totalInvestments: 5000,
    withCalculatedField: 4800,
    withCorrectCalculation: 4750,
    needsUpdate: 250,
    completionRate: "96.0%",
    accuracyRate: "95.0%"
  },
  samples: [
    // Próbki inwestycji wymagających aktualizacji
  ],
  recommendations: [
    "Uruchom updateCapitalSecuredByRealEstate aby zaktualizować 250 inwestycji"
  ],
  timestamp: "2025-08-12T..."
}
```

### 3. `scheduleCapitalRecalculation`
Funkcja do automatycznego przeliczania (można użyć w cron jobs).

**Parametry:** Brak

**Logika:**
1. Sprawdza status obliczeń
2. Jeśli wszystko jest aktualne - kończy z informacją
3. Jeśli są inwestycje do aktualizacji - uruchamia automatyczną aktualizację

## Pola zapisywane w bazie danych

Funkcja zapisuje do każdej inwestycji w kolekcji `investments`:

```javascript
{
  // Główne pole (polskie)
  kapital_zabezpieczony_nieruchomoscia: 450000.00,
  
  // Pole angielskie (dla kompatybilności)
  capitalSecuredByRealEstate: 450000.00,
  
  // Metadane aktualizacji
  last_capital_calculation: Timestamp,
  capital_calculation_version: "1.0"
}
```

## Mapowanie pól (FIELD_MAPPING)

Funkcja rozpoznaje następujące warianty nazw pól:

**Kapitał Pozostały:**
- `kapital_pozostaly`
- `remainingCapital` 
- `Kapital Pozostaly`

**Kapitał do restrukturyzacji:**
- `kapital_do_restrukturyzacji`
- `capitalForRestructuring`
- `Kapitał do restrukturyzacji`

**Kapitał zabezpieczony nieruchomością:**
- `kapital_zabezpieczony_nieruchomoscia`
- `capitalSecuredByRealEstate`
- `Kapitał zabezpieczony nieruchomością`

## Bezpieczeństwo i wydajność

### Batching
- Przetwarzanie w batchach (domyślnie 500 inwestycji na batch)
- Krótkie przerwy między batchami (100ms) dla uniknięcia przeciążenia
- Timeout: 540 sekund, Pamięć: 2GB

### Walidacja
- Sprawdzanie czy wartość się zmieniła (tolerancja 0.01 PLN)
- Pomijanie aktualizacji jeśli wartość jest już prawidłowa
- Zabezpieczenie przed wartościami ujemnymi (min. wartość = 0)

### Tryb testowy (dryRun)
- `dryRun: true` - tylko oblicza, nie zapisuje do bazy
- Idealne do testowania przed wdrożeniem produkcyjnym

## Workflow wdrożenia

### 1. Pierwszy deploy
```bash
cd functions
firebase deploy --only functions
```

### 2. Sprawdzenie statusu
```javascript
const status = await checkCapitalCalculationStatus();
console.log(`Wymaga aktualizacji: ${status.statistics.needsUpdate} inwestycji`);
```

### 3. Test symulacyjny
```javascript
const dryRun = await updateCapitalSecuredByRealEstate({
  dryRun: true,
  batchSize: 100,
  includeDetails: true
});
```

### 4. Produkcyjna aktualizacja
```javascript
const result = await updateCapitalSecuredByRealEstate({
  dryRun: false,
  batchSize: 500
});
```

### 5. Weryfikacja
```javascript
const finalStatus = await checkCapitalCalculationStatus();
console.log(`Poprawność: ${finalStatus.statistics.accuracyRate}`);
```

## Monitoring i logi

Wszystkie operacje są logowane w Firebase Functions Logs:

```
🚀 [CapitalCalculation] Rozpoczynam aktualizację kapitału...
📋 [CapitalCalculation] Znaleziono 5000 inwestycji do przetworzenia
🔄 [CapitalCalculation] Przetwarzanie batcha 1/10 (500 inwestycji)
✅ [CapitalCalculation] Zaktualizowano inwestycję inv_123: 400000 → 450000
✅ [CapitalCalculation] Zakończono: 5000 przetworzonych, 890 zaktualizowanych, 0 błędów
```

## Integracja z istniejącymi funkcjami

Wszystkie istniejące funkcje analityczne (`getOptimizedInvestorAnalytics`, etc.) automatycznie będą używać nowych, prawidłowo obliczonych wartości dzięki zunifikowanemu systemowi `unified-statistics.js`.

## Harmonogram automatyczny (opcjonalny)

Możesz skonfigurować automatyczne przeliczanie:

```javascript
// Cloud Scheduler (opcjonalnie)
exports.scheduledCapitalRecalculation = functions.pubsub
  .schedule('0 2 * * 1') // Każdy poniedziałek o 2:00
  .timeZone('Europe/Warsaw')
  .onRun(async (context) => {
    return scheduleCapitalRecalculation();
  });
```

## Troubleshooting

### Problem: Timeout podczas aktualizacji
**Rozwiązanie:** Zmniejsz `batchSize` z 500 na 250 lub 100

### Problem: Nieoczekiwane wartości
**Rozwiązanie:** Sprawdź mapowanie pól w `FIELD_MAPPING` - może twoje dane używają innych nazw kolumn

### Problem: Błędy uprawnień
**Rozwiązanie:** Upewnij się, że Firebase Functions ma uprawnienia do zapisu w Firestore

### Problem: Stare wartości w cache
**Rozwiązanie:** Cache analityk jest odświeżany automatycznie, ale możesz wyczyścić ręcznie wywołując `clearAnalyticsCache`
