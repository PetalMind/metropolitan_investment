# Upload Clients from JSON to Firebase

## Description
This script uploads client data from `clients_extracted_updated.json` to the `clients` collection in Firebase Firestore.

## Files
- `upload_clients_from_normalized_json.js` - main Node.js script
- `upload_clients_from_json.sh` - bash wrapper for easier usage
- `ServiceAccount.json` - Firebase access key
- `clients_extracted_updated.json` - source data with complete email and phone data

## Użycie

### 1. Weryfikacja danych (zalecane)
```bash
# Weryfikacja struktury danych przed przesłaniem
node upload_clients_from_normalized_json.js --verify

# lub za pomocą bash
chmod +x upload_clients_from_json.sh
./upload_clients_from_json.sh --verify-only
```

### 2. Przesłanie danych
```bash
# Interaktywne przesłanie (z potwierdzeniem)
node upload_clients_from_normalized_json.js

# lub za pomocą bash
./upload_clients_from_json.sh
```

### 3. Użycie przez npm scripts
```bash
# Weryfikacja
npm run verify-json-data

# Przesłanie
npm run upload-from-json
```

## Funkcje skryptu

### Mapowanie danych
Skrypt mapuje dane zgodnie ze strukturą `Client.dart`:
- `excelId` → ID dokumentu w Firestore
- Wszystkie pola zgodne z modelem Dart
- Konwersja dat na Firebase Timestamp
- Obsługa kompatybilności z różnymi formatami

### Bezpieczeństwo
- Weryfikacja danych przed przesłaniem
- Batch operations (500 dokumentów na raz)
- Obsługa błędów z kontynuacją
- Merge strategy (nie nadpisuje istniejących dokumentów całkowicie)

### Logowanie
- Szczegółowe logi procesu
- Liczniki postępu
- Raport końcowy z statystykami
- Obsługa błędów z opisami

## Data Structure in Firestore

Each document will have ID equal to `excelId` and will contain fields matching Client.dart structure:

```javascript
{
  // Core fields (matching Client.dart constructor)
  fullName: "Client Name",
  name: "Client Name", 
  email: "email@example.com",
  phone: "123456789",
  address: "Address",
  pesel: "12345678901",
  companyName: null,
  type: "individual",
  notes: "",
  votingStatus: "undecided", 
  colorCode: "#FFFFFF",
  unviableInvestments: [],
  createdAt: Timestamp,
  updatedAt: Timestamp,
  isActive: true,
  additionalInfo: {...},
  
  // Firebase document metadata
  excelId: "10",
  
  // Compatibility fields for legacy systems
  imie_nazwisko: "Client Name",
  original_id: "10",
  telefon: "123456789",
  nazwa_firmy: "",
  created_at: "2025-08-11T11:25:35.619176",
  uploaded_at: "2025-08-11T11:25:35.619192",
  uploadedAt: "2025-08-11T11:25:35.619192",
  sourceFile: "normalized_json",
  source_file: "normalized_json"
}

## Wymagania
- Node.js 
- firebase-admin package
- Dostęp do Firebase (ServiceAccount.json)
- Plik źródłowy JSON w odpowiedniej lokalizacji

## Rozwiązywanie problemów

### Brak uprawnień Firebase
Sprawdź czy `ServiceAccount.json` ma odpowiednie uprawnienia do Firestore.

### Błędy parsowania dat
Skrypt automatycznie obsługuje różne formaty dat i używa domyślnych wartości w przypadku błędów.

### Duplikaty excelId  
Skrypt wykryje duplikaty podczas weryfikacji. Użyj merge strategy, więc późniejsze rekordy zaktualizują wcześniejsze.

### Duże pliki JSON
Skrypt przetwarza dane w batch'ach po 500 dokumentów, więc może obsłużyć duże zbiory danych.
