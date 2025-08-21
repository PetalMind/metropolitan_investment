# Poprawa obsługi polskich znaków w eksporcie PDF

## Problem
W generowanych plikach PDF polskie znaki diakrytyczne (ąćęłńóśźż) wyświetlały się jako nieprawidłowe wzorki/symbole.

## Rozwiązanie
Dodano obsługę fontów z pełnym wsparciem Unicode (Montserrat) dla poprawnego renderowania polskich znaków.

## Zmiany wprowadzone

### 1. Dodano automatyczne kopiowanie fontów
- Fonty Montserrat są automatycznie kopiowane z `assets/fonts/` do `functions/assets/fonts/`
- Obsługiwane style: Regular, Bold, Medium
- Fallback na domyślne fonty jeśli Montserrat niedostępny

### 2. Zaktualizowano funkcję PDF (advanced-export-service.js)
```javascript
// Rejestracja fontów z obsługą polskich znaków
doc.registerFont('Montserrat', regularFont);
doc.registerFont('Montserrat-Bold', boldFont);
doc.registerFont('Montserrat-Medium', mediumFont);

// Używanie odpowiednich fontów w dokumencie
doc.font('Montserrat-Bold').fontSize(20).text('TYTUŁ Z ĄĆĘŁŃÓŚŹŻ');
doc.font('Montserrat').fontSize(12).text('Tekst z polskimi znakami: ąćęłńóśźż');
```

### 3. Utworzono narzędzia pomocnicze
- `setup-fonts.js` - kopiowanie fontów do katalogu functions
- `test-polish-chars.js` - testowanie polskich znaków w PDF

## Instrukcje deploy'u

### Krok 1: Skopiuj fonty
```bash
cd functions
node setup-fonts.js
```

### Krok 2: Przetestuj lokalnie
```bash
# Uruchom emulator functions
firebase emulators:start --only functions

# W nowym terminalu
cd functions
node test-polish-chars.js
```

### Krok 3: Sprawdź wygenerowany PDF
- Plik testowy zostanie zapisany jako `functions/test_polish_chars.pdf`
- Otwórz i sprawdź czy polskie znaki wyświetlają się poprawnie

### Krok 4: Deploy do produkcji
```bash
firebase deploy --only functions
```

## Weryfikacja
Po deploy'u przetestuj eksport PDF z aplikacji i sprawdź czy:
- ✅ Polskie znaki (ąćęłńóśźż) wyświetlają się poprawnie
- ✅ Różne style tekstu (nagłówki, treść) używają odpowiednich fontów
- ✅ Fallback działa poprawnie gdy fonty niedostępne

## Pliki zmienione
- `functions/services/advanced-export-service.js` - główna logika PDF
- `functions/setup-fonts.js` - kopiowanie fontów (nowy)
- `functions/test-polish-chars.js` - testy polskich znaków (nowy)
- `functions/assets/fonts/` - katalog z fontami (nowy)

## Uwagi techniczne
- Fonty Montserrat obsługują pełen zestaw znaków Unicode
- Automatyczne fallback na domyślne fonty gwarantuje działanie
- Kopiowanie fontów odbywa się automatycznie przy pierwszym uruchomieniu
- Rozmiar każdego fontu: ~200KB (akceptowalne dla Cloud Functions)
