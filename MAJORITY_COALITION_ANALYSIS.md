# 👥 Analiza Grupy Większościowej - Dokumentacja

## 🎯 **Koncepcja**

System analizuje **minimalną koalicję inwestorów**, która łącznie kontroluje ≥51% całkowitego kapitału pozostałego w systemie.

## 🔍 **Jak to działa?**

### 1. **Sortowanie według kapitału**
```dart
// Inwestorzy sortowani malejąco według kapitału
final sortedInvestors = List<InvestorSummary>.from(_allInvestors);
sortedInvestors.sort((a, b) => 
  b.viableRemainingCapital.compareTo(a.viableRemainingCapital));
```

### 2. **Budowanie grupy większościowej**
```dart
_majorityHolders = [];
double accumulatedCapital = 0.0;

for (final investor in sortedInvestors) {
  _majorityHolders.add(investor);
  accumulatedCapital += investor.viableRemainingCapital;
  
  final accumulatedPercentage = totalCapital > 0 
      ? (accumulatedCapital / totalCapital) * 100 
      : 0.0;
  
  // Gdy osiągniemy 51%, zatrzymaj się
  if (accumulatedPercentage >= 51.0) {
    break;
  }
}
```

### 3. **Przykład działania**
Załóżmy kapitał całkowity: **1,000,000 PLN**

| Pozycja | Inwestor | Kapitał | Udział | Skumulowane |
|---------|----------|---------|--------|-------------|
| #1 | Jan Kowalski | 300,000 PLN | 30% | **30%** |
| #2 | Anna Nowak | 150,000 PLN | 15% | **45%** |
| #3 | Piotr Wiśniewski | 80,000 PLN | 8% | **53%** ✅ |

**Grupa większościowa**: 3 inwestorów (530,000 PLN = 53%)

## 🎨 **Wizualizacja w UI**

### 📊 **Zakładka "Większość"**
- **Nagłówek**: "Grupa większościowa (≥51%)"
- **Opis**: "Minimalna koalicja inwestorów kontrolująca większość kapitału"
- **Statystyki**:
  - Próg większości: 51%
  - Rozmiar grupy większościowej: X inwestorów
  - Łączny kapitał grupy: XXX PLN
  - Udział grupy w całości: XX%

### 🏷️ **Karty inwestorów w grupie**
- **Pozycja**: #1, #2, #3... (według wielkości kapitału)
- **Skumulowany procent**: pokazuje postęp do 51%
- **Kolor**: zielony gdy skumulowane ≥51%

### 👑 **Oznaczenia członków grupy**
- **Ikona**: 👥 (grupa) zamiast 🔨 (młotek)
- **Kolor procentów**: złoty dla członków grupy
- **Wyróżnienie**: w całej aplikacji

## 💡 **Zalety tego podejścia**

### ✅ **Analiza strategiczna**
- Pokazuje **minimalną koalicję** potrzebną do kontroli
- Identyfikuje **kluczowych graczy** w systemie
- Pomaga w **planowaniu głosowań**

### ✅ **Praktyczne zastosowanie**
- **Zarząd**: wie kogo przekonać do ważnych decyzji
- **Inwestorzy**: widzą swoją pozycję w hierarchii wpływów
- **Analitycy**: rozumieją strukturę władzy

### ✅ **Dynamiczność**
- **Real-time**: aktualizuje się przy każdej zmianie kapitału
- **Elastyczność**: próg można zmieniać (51%, 67%, itp.)
- **Skalowalność**: działa z dowolną liczbą inwestorów

## 🔧 **Konfiguracja**

```dart
// Próg większości (domyślnie 51%)
double _majorityThreshold = 51.0;

// Można łatwo zmienić na inne progi:
// - 67% dla decyzji strategicznych
// - 75% dla zmian statutu
// - 90% dla fuzji i przejęć
```

## 📈 **Przypadki użycia**

### 🗳️ **Głosowania**
Pokazuje jaką koalicję trzeba zbudować aby przeforsować uchwałę

### 💼 **Fuzje i przejęcia**
Identyfikuje grupy które mogą blokować lub wspierać transakcje

### 📊 **Analiza ryzyka**
Pokazuje koncentrację władzy i możliwe zagrożenia

### 🎯 **Planowanie strategiczne**
Pomaga w budowaniu sojuszy i negocjacjach

---

## 🚀 **Wdrożenie**

System jest już **w pełni zaimplementowany** w `premium_investor_analytics_screen.dart` i gotowy do użycia!

**Najważniejsze zmiany:**
- ✅ Nowa logika `_calculateMajorityAnalysis()`
- ✅ Zaktualizowane UI z opisami grup
- ✅ Pozycje i skumulowane procenty
- ✅ Oznaczenia członków koalicji
- ✅ Intuicyjne kolory i ikony
