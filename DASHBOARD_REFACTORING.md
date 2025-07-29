# Dashboard - Refaktoryzacja na komponenty

## Struktura po refaktoryzacji

### Główny plik
- `/lib/screens/dashboard_screen.dart` - Zrefaktoryzowany główny dashboard

### Komponenty Dashboard
Wszystkie komponenty znajdują się w `/lib/widgets/dashboard/`:

1. **DashboardHeader** (`dashboard_header.dart`)
   - Nagłówek z tytułem
   - Selektor przedziału czasowego 
   - Przycisk odświeżania
   - Responsywny design (mobile/desktop)

2. **DashboardTabBar** (`dashboard_tab_bar.dart`)
   - Pasek z zakładkami
   - 6 tabów: Przegląd, Wydajność, Ryzyko, Prognozy, Benchmarki, Cache Debug
   - Responsywne przyciski (kompaktowe na mobile)

3. **DashboardOverviewTab** (`dashboard_overview_tab.dart`)
   - Główna zakładka z przeglądem
   - Karty z metrykami (łączna wartość, zysk, ROI)
   - Ostatnie inwestycje
   - Inwestycje wymagające uwagi
   - Szybkie metryki i struktura portfela

4. **DashboardPerformanceTab** (`dashboard_performance_tab.dart`)
   - Placeholder dla analiz wydajności
   - Przygotowany na przyszłe rozszerzenia

5. **DashboardRiskTab** (`dashboard_risk_tab.dart`)
   - Placeholder dla analiz ryzyka
   - Przygotowany na przyszłe rozszerzenia

6. **DashboardPredictionsTab** (`dashboard_predictions_tab.dart`)
   - Placeholder dla prognoz
   - Przygotowany na przyszłe rozszerzenia

7. **DashboardBenchmarkTab** (`dashboard_benchmark_tab.dart`)
   - Placeholder dla benchmarków
   - Przygotowany na przyszłe rozszerzenia

8. **DashboardCacheDebugTab** (`dashboard_cache_debug_tab.dart`)
   - Debugowanie cache'a
   - Używa istniejący CacheDebugWidget

### Import agregujący
- `/lib/widgets/dashboard/dashboard_components.dart` - Import wszystkich komponentów

## Dane wykorzystywane jako inwestycje

W `investments_screen.dart` jako **inwestycje** traktowane są:

### Źródła danych:
1. **Kolekcja Firebase `'investments'`** - główne inwestycje
2. **Kolekcje przez DataCacheService**:
   - `'bonds'` (obligacje) 
   - `'shares'` (udziały)
   - `'loans'` (pożyczki)
   - `'apartments'` (apartamenty)

### Typy produktów:
- **Obligacje** (`ProductType.bonds`)
- **Udziały** (`ProductType.shares`)
- **Pożyczki** (`ProductType.loans`) 
- **Apartamenty** (`ProductType.apartments`)

### Statusy inwestycji:
- **Aktywny** (`InvestmentStatus.active`)
- **Nieaktywny** (`InvestmentStatus.inactive`)
- **Wykup wczesniejszy** (`InvestmentStatus.earlyRedemption`)
- **Zakończony** (`InvestmentStatus.completed`)

### Kluczowe pola Firebase:
- `kwota_inwestycji` - kwota inwestycji
- `kapital_pozostaly` - kapitał pozostały  
- `odsetki_zrealizowane` - zrealizowane odsetki
- `klient` - nazwa klienta
- `produkt_nazwa` - nazwa produktu
- `data_podpisania` - data podpisania umowy

### Model Investment zawiera:
- Dane klienta (ID, nazwa)
- Dane produktu (typ, nazwa, firma wierzyciela)
- Kwoty (inwestycja, wpłaty, pozostały kapitał, odsetki)
- Daty (podpisanie, wejście, wyjście, wykup)
- Status i przydzielenie
- Metadane (employee, oddział, waluta)

## Zalety refaktoryzacji

1. **Modularność** - każdy komponent ma własny plik
2. **Responsywność** - komponenty dostosowują się do rozmiaru ekranu
3. **Łatwość rozbudowy** - nowe zakładki można łatwo dodać
4. **Czytelność** - kod jest podzielony logicznie
5. **Testowanie** - komponenty można testować osobno
6. **Reużywalność** - komponenty mogą być używane w innych miejscach

## Użycie

```dart
import '../widgets/dashboard/dashboard_components.dart';

// Wszystkie komponenty dostępne przez jeden import
DashboardHeader(...)
DashboardTabBar(...)
DashboardOverviewTab(...)
// itd.
```
