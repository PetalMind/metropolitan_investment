# Dokumentacja Skryptów Normalizacji JSON

## Przegląd

Zestaw skryptów do ujednolicenia nazywnictwa pól w plikach JSON zgodnie z konwencjami projektu Metropolitan Investment. Skrypty mapują polskie nazwy pól z bazy danych na angielskie nazwy używane w kodzie Dart/Flutter.

## 📁 Pliki

### 1. `normalize_json_fields.py` - Główny skrypt normalizacji
- **Język**: Python 3.x
- **Funkcja**: Normalizuje nazwy pól we wszystkich plikach JSON
- **Mapowania**: 50+ zdefiniowanych mapowań pól
- **Backup**: Automatycznie tworzy kopie `.backup` przed zmianami

### 2. `validate_json_normalization.py` - Skrypt walidacji
- **Język**: Python 3.x  
- **Funkcja**: Waliduje poprawność normalizacji
- **Sprawdza**: Wymagane pola, nieoczekiwane pola, statystyki danych
- **Porównania**: Analizuje różnice przed/po normalizacji

### 3. `run_normalization.sh` - Skrypt uruchomieniowy Linux/macOS
- **Język**: Bash
- **Funkcja**: Automatyzuje cały proces normalizacji i walidacji
- **Kolory**: Kolorowe komunikaty dla lepszej czytelności
- **Sprawdzenia**: Automatycznie sprawdza dostępność Python

### 4. `run_normalization.ps1` - Skrypt uruchomieniowy Windows
- **Język**: PowerShell
- **Funkcja**: Wersja Windows skryptu bash
- **Interface**: Przyjazny interfejs użytkownika
- **Obsługa błędów**: Szczegółowe komunikaty o błędach

## 🗂️ Struktura Mapowań

### Wspólne pola (wszystkie typy inwestycji)
```python
"Kapital Pozostaly" -> "remainingCapital"
"Kwota_inwestycji" -> "investmentAmount" 
"Data_podpisania" -> "signingDate"
"typ_produktu" -> "productType"
"ID_Klient" -> "clientId"
```

### Pola specyficzne - Apartamenty
```python
"numer_apartamentu" -> "apartmentNumber"
"budynek" -> "building"
"powierzchnia" -> "area"
"liczba_pokoi" -> "roomCount"
```

### Pola specyficzne - Pożyczki
```python
"pozyczka_numer" -> "loanNumber"
"pozyczka_typ" -> "loanType"
"pozyczka_status" -> "loanStatus"
```

### Pola specyficzne - Udziały
```python
"Ilosc_Udzialow" -> "shareCount"
"wartosc_nominalna" -> "nominalValue"
"wartosc_rynkowa" -> "marketValue"
```

### Pola klientów
```python
"imie_nazwisko" -> "fullName"
"nazwa_firmy" -> "companyName"
"telefon" -> "phone"
"email" -> "email"
```

## 🚀 Użycie

### Opcja 1: Automatyczny skrypt (Zalecane)

**Linux/macOS:**
```bash
chmod +x run_normalization.sh
./run_normalization.sh
```

**Windows PowerShell:**
```powershell
.\run_normalization.ps1
```

### Opcja 2: Ręczne uruchomienie

```bash
# Normalizacja
python3 normalize_json_fields.py

# Walidacja (opcjonalnie)
python3 validate_json_normalization.py
```

## 📋 Wymagania

- **Python 3.x** (3.6 lub nowszy)
- **Moduły**: `json`, `os`, `typing`, `collections` (standardowa biblioteka)
- **Pliki**: Pliki JSON w katalogu `split_investment_data/`

## 📁 Przetwarzane Pliki

| Plik | Typ | Opis |
|------|-----|------|
| `clients.json` | Klienci | Dane kontaktowe i podstawowe info |
| `apartments.json` | Apartamenty | Inwestycje w nieruchomości mieszkalne |
| `loans.json` | Pożyczki | Produkty pożyczkowe |
| `shares.json` | Udziały | Inwestycje w udziały spółek |

## 🔍 Proces Walidacji

### Sprawdzane elementy:
1. **Kompletność danych** - czy wszystkie wymagane pola są obecne
2. **Nieoczekiwane pola** - wykrycie niezmapowanych pól  
3. **Statystyki kapitału** - analiza wartości `remainingCapital`
4. **Porównanie przed/po** - zestawienie zmian
5. **Częstotliwość pól** - które pola są najczęściej wypełnione

### Przykładowy output walidacji:
```
📋 Walidacja pliku: apartments.json
--------------------------------------------------
📊 Liczba rekordów: 1843
📊 Liczba unikalnych pól: 45
✅ Wszystkie wymagane pola są obecne
⚠️  Nieoczekiwane pola: legacy_field_1, old_status...

🔍 Najczęściej występujące pola:
   remainingCapital: 1843 (100.0%)
   investmentAmount: 1843 (100.0%)
   productType: 1843 (100.0%)
   
💰 Kapitał pozostały:
   Zero: 1200 (65.1%)
   Dodatni: 643 (34.9%)
```

## 💾 System Backupów

- **Automatyczne kopie**: Każdy plik otrzymuje kopię `.backup` przed zmianami
- **Przywracanie**: `mv file.json.backup file.json`
- **Bezpieczeństwo**: Oryginalne dane zawsze zachowane

## ⚠️ Ważne Uwagi

### Konwencje projektu
- **Database → Code**: Polskie nazwy w Firestore → Angielskie w Dart
- **Kluczowe pole**: `kapital_pozostaly` → `remainingCapital` 
- **Analityka**: Używa `viableRemainingCapital` vs `totalRemainingCapital`

### Obsługa błędów
- **JSON malformed**: Szczegółowe komunikaty o błędach parsowania
- **Missing files**: Graceful handling brakujących plików
- **Permissions**: Sprawdzenie uprawnień zapisu
- **Encoding**: UTF-8 dla polskich znaków

## 🔧 Dostosowanie

### Dodawanie nowych mapowań
Edytuj `FIELD_MAPPINGS` w `normalize_json_fields.py`:

```python
FIELD_MAPPINGS = {
    # Dodaj nowe mapowanie
    "nowa_nazwa_polska": "newEnglishName",
    # ... reszta mapowań
}
```

### Nowe typy plików
1. Dodaj plik do listy `json_files` w skryptach
2. Dodaj oczekiwane pola do `EXPECTED_FIELDS` w walidacji
3. Przetestuj na kopii danych

## 🐛 Rozwiązywanie Problemów

### Problem: Błąd dekodowania JSON
```
❌ Błąd parsowania JSON: Expecting ',' delimiter
```
**Rozwiązanie**: Sprawdź poprawność składni JSON, usuń końcowe przecinki

### Problem: Brak uprawnień
```
❌ Permission denied
```
**Rozwiązanie**: `chmod +x *.sh` lub uruchom jako administrator

### Problem: Python nie znaleziony
```
❌ Python nie jest dostępny
```
**Rozwiązanie**: Zainstaluj Python 3.x i dodaj do PATH

### Problem: Nieoczekiwane pola
```
⚠️  Nieoczekiwane pola: legacy_field
```
**Rozwiązanie**: Dodaj mapowanie lub zaktualizuj `EXPECTED_FIELDS`

## 📈 Statystyki Wydajności

- **clients.json**: ~8,000 rekordów - ~2 sekundy
- **apartments.json**: ~1,800 rekordów - ~1 sekunda  
- **loans.json**: ~2,000 rekordów - ~1 sekunda
- **shares.json**: ~5,500 rekordów - ~3 sekundy

**Łącznie**: ~17,300 rekordów w ~7 sekund

## 🔗 Integracja z Projektem

### Firebase Import
Po normalizacji pliki są gotowe do importu:
```bash
# Deploy do Firestore
firebase deploy --only functions
node upload_clients_to_firebase.js
```

### Flutter Integration
Znormalizowane nazwy odpowiadają polom w modelach Dart:
```dart
class Investment {
  final double remainingCapital;  // było "Kapital Pozostaly"
  final double investmentAmount;  // było "Kwota_inwestycji"
  final String productType;      // było "typ_produktu"
}
```

## 📚 Dodatkowe Zasoby

- **Dokumentacja projektu**: `CLAUDE.md`
- **Analityka**: `INVESTOR_ANALYTICS_README.md`
- **Indeksy Firestore**: `FIRESTORE_INDEXES_OPTIMIZED.md`
- **Migracje**: `MIGRATION_GUIDE.md`
