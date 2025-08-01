# 🎛️ PREMIUM ANALYTICS FILTERING SYSTEM

## Przegląd

System Premium Analytics Filtering zapewnia zaawansowane możliwości filtrowania i analizy danych inwestorów w czasie rzeczywistym. Integruje front-end Flutter z backend Firebase Functions dla optymalnej wydajności.

## 🏗️ Architektura

### Komponenty Frontend (Flutter)

#### 1. `PremiumAnalyticsDashboard`
- **Lokalizacja**: `lib/widgets/premium_analytics_dashboard.dart`
- **Funkcja**: Główny dashboard z wykresami analitycznymi
- **Cechy**:
  - Real-time filtrowanie danych
  - 4 karty analityczne (Głosowanie, Trendy, Dystrybucja, Ryzyko)
  - Integracja z panelem filtrów
  - Responsive design

#### 2. `PremiumAnalyticsFilterPanel`
- **Lokalizacja**: `lib/widgets/premium_analytics_filter_panel.dart`
- **Funkcja**: Zaawansowany panel filtrowania
- **Cechy**:
  - Wielokryterialne filtry
  - Szybkie filtry i filtry zaawansowane
  - Zapisywanie presetów
  - Animacje i UX

#### 3. `PremiumAnalyticsFloatingControls`
- **Lokalizacja**: `lib/widgets/premium_analytics_floating_controls.dart`
- **Funkcja**: Szybkie kontrolki filtrów
- **Cechy**:
  - Floating design nad wykresami
  - Najważniejsze filtry w zasięgu ręki
  - Status aktywnych filtrów

### Komponenty Backend (Firebase Functions)

#### 1. `getFilteredInvestorAnalytics`
- **Lokalizacja**: `functions/premium-analytics-filters.js`
- **Funkcja**: Zaawansowane filtrowanie serwerowe
- **Parametry**:
  ```javascript
  {
    searchQuery: string,
    votingStatusFilter: string?,
    clientTypeFilter: string?,
    minCapital: number,
    maxCapital: number,
    minInvestmentCount: number,
    maxInvestmentCount: number,
    showOnlyMajorityHolders: boolean,
    showOnlyLargeInvestors: boolean,
    showOnlyWithUnviableInvestments: boolean,
    includeActiveOnly: boolean,
    requireHighDiversification: boolean,
    recentActivityOnly: boolean,
    sortBy: string,
    sortAscending: boolean,
    page: number,
    pageSize: number
  }
  ```

#### 2. `getSmartSearchSuggestions`
- **Funkcja**: Inteligentne sugestie wyszukiwania
- **Cechy**:
  - Fuzzy search w imionach, emailach, telefonach
  - Kategoryzacja wyników
  - Limit wyników

#### 3. `getAnalyticsDashboardPresets`
- **Funkcja**: Predefiniowane zestawy filtrów
- **Presety**:
  - Właściciele większościowi
  - Głosujący ZA
  - Duzi inwestorzy (>1M PLN)
  - Problematyczne inwestycje
  - Zdywersyfikowane portfele
  - Ostatnia aktywność

## 🎯 Dostępne Filtry

### Podstawowe Filtry

#### 1. Wyszukiwanie tekstowe
- **Pole**: `searchQuery`
- **Typ**: `String`
- **Zakres**: Imię, nazwisko, email, telefon
- **Cechy**: Real-time search, case-insensitive

#### 2. Status głosowania
- **Pole**: `votingStatusFilter`
- **Typ**: `VotingStatus?`
- **Wartości**: `yes`, `no`, `abstain`, `undecided`
- **Cechy**: Single select z licznikami

#### 3. Typ klienta
- **Pole**: `clientTypeFilter`
- **Typ**: `ClientType?`
- **Wartości**: `individual`, `company`, `fund`
- **Cechy**: Single select z licznikami

### Filtry Zakresu

#### 4. Zakres kapitału
- **Pola**: `minCapital`, `maxCapital`
- **Typ**: `double`
- **Cechy**: 
  - Slider input
  - Predefiniowane zakresy
  - Format walutowy

#### 5. Liczba inwestycji
- **Pola**: `minInvestmentCount`, `maxInvestmentCount`
- **Typ**: `int`
- **Zakres**: 0-100
- **Cechy**: Range slider

### Filtry Specjalne

#### 6. Większość kapitałowa
- **Pole**: `showOnlyMajorityHolders`
- **Typ**: `boolean`
- **Funkcja**: Pokazuje tylko inwestorów w grupie większościowej (>51%)

#### 7. Duzi inwestorzy
- **Pole**: `showOnlyLargeInvestors`
- **Typ**: `boolean`
- **Funkcja**: Kapitał > 1M PLN

#### 8. Tylko aktywni
- **Pole**: `includeActiveOnly`
- **Typ**: `boolean`
- **Funkcja**: Filtruje nieaktywnych klientów

#### 9. Problematyczne inwestycje
- **Pole**: `showOnlyWithUnviableInvestments`
- **Typ**: `boolean`
- **Funkcja**: Inwestorzy z nierentownymi inwestycjami

#### 10. Wysoka dywersyfikacja
- **Pole**: `requireHighDiversification`
- **Typ**: `boolean`
- **Funkcja**: ≥3 różne typy produktów

#### 11. Ostatnia aktywność
- **Pole**: `recentActivityOnly`
- **Typ**: `boolean`
- **Funkcja**: Aktywność w ciągu 30 dni

## 📊 Metryki i Analityka

### Podstawowe Metryki
```dart
class PremiumAnalyticsMetrics {
  final double totalCapital;           // Łączny kapitał po filtrach
  final double originalCapital;        // Oryginalny kapitał
  final double capitalPercentage;      // % kapitału po filtrach
  final int investorCount;             // Liczba inwestorów po filtrach
  final int originalInvestorCount;     // Oryginalna liczba
  final double investorPercentage;     // % inwestorów po filtrach
}
```

### Dystrybucja Głosowania
```dart
Map<VotingStatus, VotingMetrics> votingDistribution;

class VotingMetrics {
  final int count;                     // Liczba inwestorów
  final double capital;                // Kapitał w statusie
}
```

### Dystrybucja Kapitału
```dart
class CapitalDistribution {
  final int small;                     // < 100K PLN
  final int medium;                    // 100K - 1M PLN  
  final int large;                     // > 1M PLN
}
```

### Statystyki Dywersyfikacji
```dart
class DiversificationStats {
  final double averageProducts;        // Średnia liczba produktów
  final int highlyDiversified;         // Liczba zdywersyfikowanych
  final double diversificationPercentage; // % zdywersyfikowanych
}
```

## 🚀 Wykorzystanie

### Podstawowe Filtrowanie

```dart
// Utwórz filtr
final filter = PremiumAnalyticsFilter(
  searchQuery: 'Jan Kowalski',
  votingStatusFilter: VotingStatus.yes,
  minCapital: 100000,
  showOnlyLargeInvestors: true,
);

// Zastosuj na dashboardzie
PremiumAnalyticsDashboard(
  investors: allInvestors,
  votingDistribution: votingDistribution,
  votingCounts: votingCounts,
  totalCapital: totalCapital,
  majorityHolders: majorityHolders,
);
```

### Zaawansowane Filtrowanie z Firebase

```dart
// Użyj serwisu Premium Analytics
final result = await PremiumAnalyticsFilterService.getFilteredAnalytics(
  filter: filter,
  sortBy: 'viableCapital',
  sortAscending: false,
  page: 1,
  pageSize: 100,
);

// Wynik zawiera pełne metryki
final metrics = result.analytics;
final filteredInvestors = result.investors;
```

### Presety Dashboardu

```dart
// Pobierz dostępne presety
final presets = await PremiumAnalyticsFilterService.getDashboardPresets();

// Zastosuj preset
final majorityPreset = presets.firstWhere((p) => p.id == 'majority_holders');
final filter = majorityPreset.toFilter();
```

## 🎨 Customizacja UI

### Kolory Statusów Głosowania
```dart
Color _getVotingStatusColor(VotingStatus status) {
  switch (status) {
    case VotingStatus.yes:    return Color(0xFF00C851); // Zielony
    case VotingStatus.no:     return Color(0xFFFF4444); // Czerwony  
    case VotingStatus.abstain: return Color(0xFFFF8800); // Pomarańczowy
    case VotingStatus.undecided: return Color(0xFF9E9E9E); // Szary
  }
}
```

### Animacje i Przejścia
- Slide-in dla panelu filtrów (300ms)
- Fade-in dla floating controls (400ms)
- Elastic animations dla wykresów (1500-2000ms)
- Smooth transitions dla chip selection (200ms)

## 🔧 Konfiguracja i Wydajność

### Cache Strategy
- Client-side: Krótkoterminowy cache filtrowanych danych
- Server-side: 5-minutowy cache w Firebase Functions
- Inteligentne odświeżanie przy zmianie filtrów

### Optimalizacje
- Lazy loading wykresów
- Debounced search (300ms)
- Virtualized lists dla dużych zbiorów danych
- Background processing w isolates

### Limity i Ograniczenia
- Maksymalnie 10,000 klientów w jednym zapytaniu
- Maksymalnie 50,000 inwestycji w jednym zapytaniu
- Timeout Firebase Functions: 9 minut
- Limit pamięci: 2GB per function

## 🧪 Testowanie

### Unit Tests
```dart
// Test filtra
testWidgets('Premium filter applies correctly', (tester) async {
  final filter = PremiumAnalyticsFilter(minCapital: 100000);
  final filtered = investors.where(filter.matches).toList();
  expect(filtered.length, lessThan(investors.length));
});
```

### Integration Tests
```dart
// Test Firebase Functions
test('getFilteredAnalytics returns correct data', () async {
  final result = await PremiumAnalyticsFilterService.getFilteredAnalytics(
    filter: PremiumAnalyticsFilter(showOnlyLargeInvestors: true),
  );
  expect(result.investors.every((i) => i.viableRemainingCapital >= 1000000), true);
});
```

## 📱 Responsywność

### Breakpoints
- **Mobile**: < 600px - Stack layout, simplified filters
- **Tablet**: 600-1200px - Side-by-side layout, full filters  
- **Desktop**: > 1200px - Multi-column layout, advanced features

### Adaptacje
- Touch-friendly controls na mobile
- Keyboard shortcuts na desktop
- Gesture navigation na tablet

## 🔄 Aktualizacje i Rozwój

### Planowane Funkcje
- [ ] Export filtrowanych danych do Excel/PDF
- [ ] Zapisywanie i udostępnianie presetów filtrów
- [ ] Collaborative filtering (zespołowe filtry)
- [ ] AI-powered filtering suggestions
- [ ] Real-time updates z WebSocket
- [ ] Advanced data visualization (D3.js integration)

### Monitorowanie
- Performance metrics w Firebase Analytics
- Error tracking z Crashlytics
- User behavior analytics
- A/B testing różnych UX podejść

## 📞 Wsparcie

Dla pytań technicznych i wsparcia:
- GitHub Issues: [cosmopolitan_investment/issues]
- Email: dev@metropolitan-investment.pl
- Slack: #premium-analytics-dev
