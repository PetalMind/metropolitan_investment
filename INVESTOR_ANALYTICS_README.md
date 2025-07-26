# DOKUMENTACJA FUNKCJONALNOŚCI ANALITYKI INWESTORÓW

## Zaimplementowane funkcjonalności

### 1. Sortowanie według kapitału pozostałego ✅

**Implementacja:**
- Nowy model `InvestorSummary` agreguje dane inwestora z wszystkich jego inwestycji
- Serwis `InvestorAnalyticsService` pobiera i sortuje inwestorów według łącznej wartości portfela
- Dla udziałów uwzględniana jest kwota inwestycji zamiast kapitału pozostałego
- Aktualizacja w czasie rzeczywistym po zmianie kapitału zrealizowanego

**Lokalizacja kodu:**
- `lib/models/investor_summary.dart` - Model agregujący dane inwestora
- `lib/services/investor_analytics_service.dart` - Serwis analityczny
- `lib/screens/investor_analytics_screen.dart` - Ekran analityki

### 2. Punkt kontroli 51% ✅

**Implementacja:**
- Automatyczne obliczanie, ilu inwestorów stanowi około 51% całego kapitału
- Wyświetlanie w karcie podsumowania na górze ekranu
- Klasa `InvestorRange` przechowuje informacje o punkcie kontroli

**Funkcjonalność:**
```dart
InvestorRange? findMajorityControlPoint(List<InvestorSummary> sortedInvestors)
```

### 3. Notatki, kolorowanie i status głosowania ✅

**Implementacja:**
- Rozszerzony model `Client` o nowe pola:
  - `notes` - notatki o inwestorze
  - `colorCode` - kod koloru dla oznaczenia
  - `votingStatus` - status głosowania (tak/nie/wstrzymuje się/niezdecydowany)
  - `type` - typ klienta (osoba fizyczna/małżeństwo/spółka)

**Nowe enums:**
```dart
enum VotingStatus {
  undecided('Niezdecydowany'),
  yes('Tak'),
  no('Nie'),
  abstain('Wstrzymuje się');
}

enum ClientType {
  individual('Osoba fizyczna'),
  marriage('Małżeństwo'),
  company('Spółka'),
  other('Inne');
}
```

### 4. Dodatkowe dane kontaktowe ✅

**Implementacja:**
- Rozszerzenie modelu `Client` o pola:
  - `pesel` - PESEL dla osób fizycznych
  - `companyName` - nazwa firmy dla spółek
- Zaktualizowany `ClientForm` obsługuje wszystkie nowe pola
- Dynamiczne wyświetlanie pól w zależności od typu klienta

### 5. Generowanie maili ✅

**Implementacja:**
- Serwis `EmailService` z funkcjami:
  - Generowanie szablonów maili dla inwestorów
  - Uwzględnianie listy inwestycji w treści maila
  - Szablony dla różnych celów (aktualizacja portfela, powiadomienia o głosowaniu)
  - Eksport listy maili do CSV

**Główne funkcje:**
```dart
// Generuj szablon maila dla inwestora
String generateInvestorEmailTemplate({
  required Client client,
  required List<Investment> investments,
  String? customMessage,
})

// Generuj maile grupowe
Future<List<EmailData>> generateBulkEmails({
  required List<String> clientIds,
  required String purpose,
})
```

### 6. Inwestycje niewykonalne ✅

**Implementacja:**
- Pole `unviableInvestments` w modelu `Client` przechowuje ID niewykonalnych inwestycji
- Dialog edycji inwestora pozwala na oznaczanie inwestycji jako niewykonalne
- Filtrowanie inwestorów z niewykonalnymi inwestycjami
- Rozróżnienie między kapitałem wykonalnym i niewykonalnym

### 7. Filtrowanie według firmy ✅

**Implementacja:**
- Filtr tekstowy po nazwie firmy w `InvestorAnalyticsScreen`
- Metoda `filterByCompany` w `InvestorAnalyticsService`
- Grupowanie inwestycji według firm w `InvestorSummary`

**Funkcjonalność:**
```dart
Map<String, List<Investment>> get investmentsByCompany
```

## Struktura plików

```
lib/
├── models/
│   ├── client.dart (rozszerzony)
│   ├── investor_summary.dart (nowy)
│   └── investment.dart
├── services/
│   ├── investor_analytics_service.dart (nowy)
│   ├── email_service.dart (nowy)
│   └── client_service.dart (rozszerzony)
├── screens/
│   ├── investor_analytics_screen.dart (nowy)
│   └── main_screen.dart (dodany nowy tab)
└── widgets/
    └── client_form.dart (rozszerzony)
```

## Jak używać nowych funkcjonalności

### 1. Dostęp do analityki inwestorów
- Nowy tab "Inwestorzy" w głównym menu aplikacji
- Automatyczne sortowanie według wartości portfela (kapitał pozostały + udziały)

### 2. Filtrowanie i wyszukiwanie
- **Filtr tekstowy:** szukaj po nazwie inwestora lub firmie
- **Filtr kwoty:** ustaw min/max wartość portfela
- **Filtr firmy:** szukaj po konkretnej spółce
- **Status głosowania:** filtruj według decyzji głosowania
- **Typ klienta:** filtruj osoby fizyczne/małżeństwa/spółki
- **Niewykonalne inwestycje:** pokaż tylko z problemowymi inwestycjami

### 3. Edycja danych inwestora
- Kliknij na kartę inwestora aby otworzyć szczegóły
- Możliwość edycji:
  - Statusu głosowania (tak/nie/wstrzymuje się/niezdecydowany)
  - Notatek
  - Oznaczania inwestycji jako niewykonalne
  - Koloru oznaczenia

### 4. Generowanie maili
- Przycisk "email" w górnej części ekranu
- Automatyczne generowanie listy maili dla wyfiltrowanych inwestorów
- Możliwość kopiowania listy adresów email
- Podgląd szczegółów każdego inwestora z listą jego inwestycji

### 5. Punkty kontroli
- Karta na górze ekranu pokazuje:
  - Łączną wartość portfela
  - Liczbę inwestorów
  - Ilu inwestorów stanowi 51% kapitału

## Przykłady użycia

### Przygotowanie do głosowania
1. Przejdź do "Inwestorzy"
2. Sprawdź punkt kontroli 51%
3. Dla każdego kluczowego inwestora:
   - Ustaw status głosowania
   - Dodaj notatki o rozmowie
   - Oznacz kolorem (zielony=tak, czerwony=nie)
4. Wygeneruj maile dla niezdecydowanych

### Analiza problemowych inwestycji
1. Użyj filtru "Niewykonalne inwestycje"
2. Dla każdego inwestora oznacz problematyczne produkty
3. Wygeneruj maile z informacją o sytuacji
4. Śledź status rozmów w notatkach

### Przygotowanie raportów
1. Filtruj według wysokości kapitału
2. Eksportuj listę maili do CSV
3. Użyj danych do analiz zewnętrznych

## Potencjalne ulepszenia

### Krótkoterminowe:
1. **Integracja z prawdziwym klientem email** - dodanie pakietu `url_launcher`
2. **Eksport do Excel** - szczegółowe raporty inwestorów
3. **Historia zmian** - śledzenie zmian statusów głosowania
4. **Powiadomienia** - przypomnienia o kontakcie z inwestorami

### Długoterminowe:
1. **Dashboard głosowania** - śledzenie wyników w czasie rzeczywistym
2. **Automatyczne kategoryzowanie** - AI do analizy notatek
3. **Integracja z kalendarzem** - planowanie spotkań z inwestorami
4. **Analityka predykcyjna** - przewidywanie wyników głosowania

## Techniczne uwagi

### Wydajność:
- Dane są buforowane w `BaseService`
- Lazy loading dla dużych list inwestorów
- Optymalizowane zapytania do Firestore

### Bezpieczeństwo:
- Wszystkie operacje wymagają uwierzytelnienia
- Dane wrażliwe są zabezpieczone
- Audit trail dla krytycznych operacji

### Skalowalność:
- Architektura umożliwia łatwe dodawanie nowych funkcji
- Modularny design serwisów
- Możliwość rozszerzenia o nowe typy analiz

## Migracja danych

Istniejące dane będą automatycznie uzupełnione domyślnymi wartościami:
- `votingStatus`: `VotingStatus.undecided`
- `type`: `ClientType.individual`
- `colorCode`: `'#FFFFFF'`
- `notes`: pusty string
- `unviableInvestments`: pusta lista

Dane można później zaktualizować poprzez interfejs użytkownika.
