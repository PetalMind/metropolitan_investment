# Flutter Metropolitan Investment - New Feature Development Prompt

## Tryb agenta
```prompt
---
mode: agent
---
```

## Opis projektu
Metropolitan Investment to zaawansowana platforma Flutter do zarządzania inwestycjami z backendem Firebase. System obsługuje klientów, inwestycje (akcje, obligacje, pożyczki), pracowników oraz złożone analizy inwestorów z przetwarzaniem po stronie serwera.

## Architektura systemowa

### Frontend (Flutter)
- **State Management**: Podwójny system: `provider` + `flutter_riverpod`
- **Routing**: Go Router z architekturą shell layout w `lib/config/app_routes.dart`
- **Theme**: Dark-first design system w `lib/theme/app_theme.dart`
- **Models**: Centralne eksporty z `lib/models_and_services.dart` - ZAWSZE importuj stąd

### Backend (Firebase)
- **Firestore**: Główna baza danych z optymalizacjami indeksów (`firestore.indexes.json`)
- **Functions**: Ciężkie przetwarzanie analityk w `functions/index.js` (region: Europe-West1)
- **Analytics**: Analityka inwestorów po stronie serwera z 5-minutowym cache
- **Authentication**: Firebase Auth z niestandardowym `AuthProvider`

### Wzorce serwisów
Wszystkie serwisy dziedziczą po `BaseService` i przestrzegają wzorca:
- Używają `FirebaseFirestore.instance` bezpośrednio
- Implementują obsługę błędów z try-catch
- Zwracają `Future<List<T>>` lub `Future<T?>`
- Cache często używanych danych

## Konwencje projektowe

### Struktura modeli
- **Client**: `imie_nazwisko`, `email`, `telefon`, `nazwa_firmy`
- **Investment**: Używa pola `kapital_pozostaly` (NIE `remainingCapital`) dla spójności
- **InvestorSummary**: Agreguje client + investments z `viableRemainingCapital`

### Nazewnictwo serwisów
- Zoptymalizowane serwisy: `optimized_*_service.dart` dla operacji krytycznych wydajnościowo
- Serwisy Firebase Functions: `firebase_functions_*_service.dart` dla wywołań serwerowych
- Bazowe serwisy: Standardowe operacje CRUD dziedziczące po `BaseService`

### Wzorzec nawigacji
- Trasy zdefiniowane w klasie `AppRoutes` z generatorami ścieżek typowanych
- Shell layout opakowuje uwierzytelnione trasy w `MainLayout`
- Metody rozszerzeń na `BuildContext` dla bezpiecznej nawigacji typów

### Architektura analityk
Krytyczny wzorzec: Filtrowanie po stronie klienta + agregacja po stronie serwera
1. `PremiumInvestorAnalyticsScreen` wywołuje `firebase_functions_analytics_service.dart`
2. Serwer przetwarza w `functions/index.js` z optymalizacją pamięci
3. Wyniki cache przez 5 minut serwerowo, 2 minuty klientowo

## Wzorce wydajnościowe

### Ładowanie danych
- Używaj Firebase Functions dla analityk (>1000 rekordów)
- Implementuj paginację z `pageSize: 250` dla dużych zbiorów danych
- Cache wyników w serwisach używając prostego cache opartego na Map

### Optymalizacja UI
- Lazy loading z `ListView.builder` dla dużych list
- Używaj pakietu `shimmer` dla stanów ładowania
- `fl_chart` i `syncfusion_flutter_charts` dla wizualizacji

## Zadanie do wykonania

### Cel
[OPISZ KONKRETNĄ FUNKCJONALNOŚĆ DO ZAIMPLEMENTOWANIA]

### Wymagania funkcjonalne
1. [WYMAGANIE 1]
2. [WYMAGANIE 2]
3. [WYMAGANIE 3]

### Wymagania techniczne
1. **Architektura**: Przestrzegaj wzorców projektowych (BaseService, provider/riverpod)
2. **Nawigacja**: Używaj systemu AppRoutes z typowanymi ścieżkami
3. **Style**: Konsekwentnie stosuj AppTheme (dark-first)
4. **Wydajność**: Implementuj cache i lazy loading gdzie to zasadne
5. **Firebase**: Wykorzystuj Firebase Functions dla ciężkich operacji

### Ograniczenia
1. **Kompatybilność**: Web + Mobile (responsive design)
2. **Performance**: Maksymalnie 550 elementów na stronę
3. **Memory**: Firebase Functions mają limit 2GB pamięci
4. **Region**: Firebase Functions działają w europe-west1

### Kryteria sukcesu
1. ✅ Funkcjonalność działa na web i mobile
2. ✅ Przestrzega wzorców architektonicznych projektu
3. ✅ Implementuje odpowiednie loading states i error handling
4. ✅ Używa systemu cache dla optymalizacji wydajności
5. ✅ Posiada responsive design dla różnych rozmiarów ekranów

### Szczegółowe instrukcje implementacji

#### 1. Struktura plików
```
lib/
  models/
    [nazwa_modelu].dart
  services/
    [nazwa_serwisu]_service.dart
  screens/
    [nazwa_ekranu]_screen.dart
  widgets/
    [nazwa_komponentu]_widget.dart
```

#### 2. Wzorce kodu
- **Importy**: Zawsze z `models_and_services.dart`
- **State Management**: Provider dla auth, Riverpod dla dane
- **Error Handling**: Try-catch w serwisach, FutureBuilder w UI
- **Cache**: BaseService.getCachedData() dla często używanych danych

#### 3. Testowanie
- Uruchom `flutter run` dla testów lokalnych
- Testuj na różnych rozmiarach ekranów
- Sprawdź wydajność z dużymi zbiorami danych

#### 4. Firebase Functions (jeśli potrzebne)
```javascript
exports.nazwaFunkcji = functions
  .region("europe-west1")
  .runWith({ memory: "2GB", timeoutSeconds: 540 })
  .https.onCall(async (data) => {
    // Implementacja
  });
```

### Dodatkowe uwagi
- Sprawdź `firestore.indexes.json` dla wymaganych indeksów złożonych
- Dokumentacja CORS znajduje się w `CORS_DEVELOPMENT_GUIDE.md`
- Firebase Functions używają 2GB pamięci dla operacji analitycznych
- Wszystkie nowe komponenty powinny wspierać dark theme

---
**Pamiętaj**: Ten projekt używa ustalonej architektury i wzorców. Przestrzegaj ich konsekwentnie dla zachowania spójności i maintainability kodu.