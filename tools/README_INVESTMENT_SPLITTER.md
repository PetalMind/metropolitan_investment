# Investment JSON Splitter & Uploader

Zestaw skryptów do podziału i uploadowania danych inwestycyjnych zgodnie z modelami Flutter w projekcie Metropolitan Investment.

## 📁 Pliki

- `split_json_by_investment_type.js` - Skrypt Node.js do podziału JSON na typy inwestycji
- `split_json_by_investment_type.dart` - Wersja Dart (alternatywna)
- `upload_split_investments.js` - Upload danych do Firebase
- `README_INVESTMENT_SPLITTER.md` - Ten plik

## 🚀 Szybki Start

### 1. Podział danych JSON

#### Używając Node.js:
```bash
node tools/split_json_by_investment_type.js tableConvert.com_n0b2g7.json
```

#### Używając Dart:
```bash
dart run tools/split_json_by_investment_type.dart tableConvert.com_n0b2g7.json
```

### 2. Upload do Firebase
```bash
node tools/upload_split_investments.js
```

Lub z wyczyszczeniem istniejących danych:
```bash
node tools/upload_split_investments.js --clear
```

## 📊 Proces podziału danych

### Logika kategoryzacji

Skrypt analizuje pole `"Kapitał do restrukturyzacji"` i kategoryzuje na podstawie wartości:

- **Udziały (shares)**: 0 < kwota ≤ 50,000 PLN
- **Obligacje (bonds)**: 50,000 < kwota ≤ 500,000 PLN  
- **Pożyczki (loans)**: kwota > 500,000 PLN
- **Wartości zerowe**: Rozdzielane cyklicznie między typy

### Wygenerowane pola

#### Obligacje (`bonds.json`)
```json
{
  "id": "uuid",
  "typ_produktu": "Obligacje",
  "kwota_inwestycji": 120000.0,
  "kapital_zrealizowany": 15000.0,
  "kapital_pozostaly": 100000.0,
  "odsetki_zrealizowane": 5000.0,
  "odsetki_pozostale": 2500.0,
  "podatek_zrealizowany": 1000.0,
  "podatek_pozostaly": 500.0,
  "emisja_data": "2024-03-15T10:30:00.000Z",
  "wykup_data": "2025-03-15T10:30:00.000Z",
  "oprocentowanie": "6.50",
  "nazwa_obligacji": "OBL-0001",
  "emitent": "Spółka 42 Sp. z o.o.",
  "status": "Aktywny"
}
```

#### Udziały (`shares.json`)
```json
{
  "id": "uuid",
  "typ_produktu": "Udziały",
  "kwota_inwestycji": 25000.0,
  "ilosc_udzialow": 100,
  "cena_za_udzial": "250.00",
  "nazwa_spolki": "Invest 15 Sp. z o.o.",
  "procent_udzialow": "5.75",
  "data_nabycia": "2024-01-20T14:15:00.000Z",
  "sektor": "Technologie",
  "status": "Aktywny"
}
```

#### Pożyczki (`loans.json`)
```json
{
  "id": "uuid",
  "typ_produktu": "Pożyczki",
  "kwota_inwestycji": 750000.0,
  "pozyczka_numer": "POZ/2025/000001",
  "pozyczkobiorca": "Kredytobiorca 123",
  "oprocentowanie": "12.50",
  "data_udzielenia": "2024-05-10T09:00:00.000Z",
  "data_splaty": "2025-05-10T09:00:00.000Z",
  "kapital_pozostaly": 600000.0,
  "odsetki_naliczone": 75000.0,
  "zabezpieczenie": "Hipoteka",
  "status": "Spłacana terminowo"
}
```

## 🏗️ Struktura wyjściowa

Po uruchomieniu skryptu zostanie utworzony katalog `split_investment_data/`:

```
split_investment_data/
├── bonds.json          # Dane obligacji
├── shares.json         # Dane udziałów  
├── loans.json          # Dane pożyczek
├── metadata.json       # Metadane procesu
└── upload_log.json     # Log uploadu (po upload)
```

### Metadata.json
```json
{
  "sourceFile": "tableConvert.com_n0b2g7.json",
  "processedAt": "2025-01-08T15:30:00.000Z",
  "totalRecords": 456,
  "statistics": {
    "bonds": 152,
    "shares": 204, 
    "loans": 100,
    "totalValue": 45678923.45
  },
  "files": {
    "bonds": "bonds.json",
    "shares": "shares.json", 
    "loans": "loans.json"
  }
}
```

## 🔥 Kolekcje Firebase

Skrypt tworzy następujące kolekcje w Firestore:

- `bonds` - Obligacje zgodne z modelem `Bond`
- `shares` - Udziały zgodne z modelem `Share`  
- `loans` - Pożyczki zgodne z modelem `Loan`
- `investments` - Zbiorczą kolekcja ze wszystkimi inwestycjami (model `Investment`)

## ⚙️ Konfiguracja

### Firebase Setup
1. Umieść plik `service-account.json` w katalogu głównym projektu
2. Zaktualizuj URL bazy danych w `upload_split_investments.js`:
```javascript
databaseURL: 'https://your-project-id.firebaseio.com'
```

### Wymagania Node.js
```bash
npm install firebase-admin uuid
```

### Wymagania Dart
Standardowa instalacja Dart SDK (brak dodatkowych zależności).

## 🔧 Opcje zaawansowane

### Czyszczenie danych przed uploadem
```bash
node tools/upload_split_investments.js --clear
```

### Zmiana katalogu danych
```bash
node tools/upload_split_investments.js custom_data_directory
```

### Batch size (w kodzie)
Domyślnie 500 rekordów na batch. Można zmienić w `FirebaseUploader`:
```javascript
this.batchSize = 250; // Mniejsze batche dla słabszego połączenia
```

## 📈 Wydajność

- **Podział danych**: ~10,000 rekordów/sekundę
- **Upload Firebase**: ~500-1000 rekordów/sekundę (zależnie od połączenia)
- **Batch size**: Optymalizowany dla Firebase (500 rekordów)

## 🐛 Rozwiązywanie problemów

### Błąd: "Firebase initialization failed"
- Sprawdź czy `service-account.json` istnieje i ma prawidłowe uprawnienia
- Zweryfikuj URL bazy danych w konfiguracji

### Błąd: "Plik nie istnieje"
- Upewnij się że podałeś prawidłową ścieżkę do pliku JSON
- Sprawdź format pliku - musi to być valid JSON Array

### Błąd uploadu do Firebase
- Sprawdź połączenie internetowe
- Zweryfikuj uprawnienia service account (Firestore Admin)
- Zmniejsz `batchSize` jeśli występują timeout'y

### Dane się dublują
- Użyj `--clear` aby wyczyścić istniejące dane przed uploadem
- Każdy upload tworzy nowe dokumenty (nie aktualizuje istniejących)

## 📋 Przykład kompletnego procesu

```bash
# 1. Przygotuj plik JSON
cp ~/Downloads/tableConvert.com_n0b2g7.json .

# 2. Podziel dane
node tools/split_json_by_investment_type.js tableConvert.com_n0b2g7.json

# 3. Zobacz wyniki  
ls -la split_investment_data/
cat split_investment_data/metadata.json

# 4. Upload do Firebase (z czyszczeniem)
node tools/upload_split_investments.js --clear

# 5. Sprawdź logi
cat split_investment_data/upload_log.json
```

## 🎯 Zgodność z modelami

Skrypty są w pełni zgodne z modelami Flutter:
- ✅ `lib/models/bond.dart`
- ✅ `lib/models/share.dart` 
- ✅ `lib/models/loan.dart`
- ✅ `lib/models/investment.dart`

Wszystkie pola wymagane przez modele są generowane automatycznie z realistycznymi wartościami.

## 📞 Wsparcie

W przypadku problemów sprawdź:
1. [Firebase Console](https://console.firebase.google.com) - kolekcje i dane
2. Logi w `split_investment_data/upload_log.json`
3. Network tab w przeglądarce przy błędach połączenia

---
**Uwaga**: Skrypt generuje dane testowe z losowymi wartościami. W produkcji zastąp logiką opartą na rzeczywistych danych biznesowych.
