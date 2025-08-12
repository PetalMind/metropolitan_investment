# Dokumentacja - Uzupełnianie danych klientów

## Przegląd
Ten zestaw skryptów służy do uzupełniania brakujących danych klientów (telefon, email) poprzez porównanie pliku backup (`clients_data_backup.json`) z aktualnymi danymi (`clients_extracted.json`).

## Problem
- **Plik backup**: `clients_data_backup.json` - zawiera kompletne dane z telefonami i emailami
- **Aktualne pliki**: `clients_extracted.json`, `clients_normalized.json` - mają puste pola telefon/email

## Dostępne skrypty

### 1. Podstawowy merge (JavaScript)
**Plik**: `tools/merge_missing_client_data.js`

**Funkcjonalność**:
- Dokładne dopasowanie nazw klientów
- Normalizacja nazw (lowercase, usunięcie znaków specjalnych)
- Walidacja numerów telefonów (polskie numery)
- Walidacja adresów email

**Uruchomienie**:
```bash
cd tools
node merge_missing_client_data.js
```

**Pliki wyjściowe**:
- `clients_extracted_updated.json`
- `split_investment_data_normalized/clients_normalized_updated.json`
- `client_data_merge_log.json`

### 2. Zaawansowany merge (JavaScript)
**Plik**: `tools/advanced_merge_client_data.js`

**Funkcjonalność**:
- **Fuzzy matching** - dopasowanie podobnych nazw
- Algorytm Levenshtein distance dla podobieństwa nazw
- Dopasowanie słów kluczowych (imię, nazwisko)
- Konfigurowalne progi podobieństwa (domyślnie 70%)
- Szczegółowe logowanie dopasowań

**Uruchomienie**:
```bash
cd tools  
node advanced_merge_client_data.js
```

**Pliki wyjściowe**:
- `clients_extracted_advanced_updated.json`
- `split_investment_data_normalized/clients_normalized_advanced_updated.json`
- `client_data_advanced_merge_log.json`

### 3. Dart merge
**Plik**: `tools/merge_client_data.dart`

**Funkcjonalność**:
- Implementacja w Dart zgodna z architekturą Flutter
- Podobna logika do podstawowego merge JavaScript
- Bezpośrednia integracja z modelem danych Flutter

**Uruchomienie**:
```bash
cd tools
dart merge_client_data.dart
```

**Pliki wyjściowe**:
- `clients_extracted_dart_updated.json`
- `split_investment_data_normalized/clients_normalized_dart_updated.json`
- `client_data_dart_merge_log.json`

## Interaktywny launcher

**Plik**: `run_client_merge.sh`

Interaktywne menu do uruchamiania wszystkich skryptów:

```bash
chmod +x run_client_merge.sh
./run_client_merge.sh
```

**Opcje**:
1. Podstawowy merge (JavaScript)
2. Zaawansowany merge (JavaScript) 
3. Dart merge
4. Uruchom wszystkie po kolei
5. Sprawdź różnice między plikami

## Struktura danych

### Plik backup (`clients_data_backup.json`)
```json
{
  "id": 1,
  "fullName": "Marcin Sochaczyński", 
  "companyName": "",
  "phone": "604955972",
  "email": "marcin.sochaczynski@onet.pl",
  "created_at": "2025-07-22T13:06:44.356678"
}
```

### Aktualny plik (`clients_extracted.json`)
```json
{
  "id": "10",
  "excelId": "10", 
  "fullName": "Joanna Rusiecka",
  "name": "Joanna Rusiecka",
  "email": "",           // ← TO POLE JEST PUSTE
  "phone": "",           // ← TO POLE JEST PUSTE
  "address": "",
  "pesel": null,
  "companyName": null,
  "type": "individual",
  "votingStatus": "undecided",
  "isActive": true
}
```

## Logika dopasowywania

### Normalizacja nazw
```
"Marcin Sochaczyński" → "marcin sochaczynski"
"Jan Kowalski-Nowak" → "jan kowalski nowak"  
```

### Kryteria aktualizacji
- Telefon: aktualizuje jeśli pole jest puste I numer z backup jest prawidłowy
- Email: aktualizuje jeśli pole jest puste I email z backup jest prawidłowy

### Walidacja
- **Telefon**: polskie numery 9-cyfrowe (z opcjonalnym +48)
- **Email**: standardowa walidacja RFC

## Wyniki i statystyki

Każdy skrypt generuje szczegółowe logi z:
- Liczbą przetworzonych klientów
- Liczbą zaktualizowanych rekordów
- Liczbą dodanych telefonów/emaili
- Listą klientów nieznalezionych w backup
- Przykładami dopasowań (w przypadku fuzzy matching)

## Przykład użycia

```bash
# 1. Uruchom interaktywne menu
./run_client_merge.sh

# 2. Wybierz opcję "4" - uruchom wszystkie skrypty

# 3. Sprawdź wyniki w plikach:
# - clients_extracted_updated.json (podstawowy)
# - clients_extracted_advanced_updated.json (zaawansowany)
# - clients_extracted_dart_updated.json (dart)

# 4. Porównaj statystyki w logach:
jq '.statistics' client_data_merge_log.json
jq '.statistics' client_data_advanced_merge_log.json
jq '.statistics' client_data_dart_merge_log.json
```

## Zalecenia

1. **Uruchom wszystkie wersje** i porównaj wyniki
2. **Sprawdź fuzzy matches** - czy dopasowania są poprawne
3. **Backupuj dane** przed zastosowaniem zmian w produkcji
4. **Zweryfikuj ręcznie** klientów o niskim podobieństwie nazw

## Bezpieczeństwo

- Skrypty **nie modyfikują** oryginalnych plików
- Wszystkie zmiany zapisywane są w nowych plikach z sufiksem `_updated`
- Szczegółowe logi pozwalają na weryfikację wszystkich zmian
- Walidacja danych przed aktualizacją

## Rozwiązywanie problemów

### Błąd "jq: command not found"
```bash
# Ubuntu/Debian
sudo apt install jq

# macOS  
brew install jq
```

### Błąd "dart: command not found"
```bash
# Zainstaluj Flutter/Dart SDK
# Lub użyj tylko skryptów JavaScript
```

### Plik nie znaleziony
- Sprawdź czy znajdujesz się w głównym katalogu projektu
- Sprawdź czy plik `clients_data_backup.json` istnieje
- Sprawdź ścieżki w skryptach
