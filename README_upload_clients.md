# Firebase Client Uploader

Ten skrypt Node.js służy do uploadowania danych klientów z pliku `clients_data.json` do Firebase Firestore.

## 🚀 Szybki start

### 1. Instalacja zależności
```bash
npm install firebase-admin
```

### 2. Konfiguracja Firebase

#### Opcja A: Zmienne środowiskowe
Ustaw następujące zmienne środowiskowe:
```bash
export FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
export FIREBASE_CLIENT_EMAIL="your-service-account@cosmopolitan-investment.iam.gserviceaccount.com"
export FIREBASE_CLIENT_ID="123456789"
export FIREBASE_PRIVATE_KEY_ID="key-id"
export FIREBASE_CLIENT_CERT_URL="https://www.googleapis.com/robot/v1/metadata/x509/..."
```

#### Opcja B: Plik service account (łatwiejsze)
1. Pobierz plik service account z Firebase Console:
   - Idź do Project Settings > Service Accounts
   - Kliknij "Generate new private key"
   - Zapisz jako `service-account.json` w tym folderze

### 3. Uruchomienie
```bash
node upload_clients_to_firebase.js
```

## 📊 Funkcje skryptu

- ✅ **Batch upload** - dzieli dane na mniejsze grupy (500 klientów)
- ✅ **Walidacja danych** - sprawdza poprawność przed zapisem
- ✅ **Bezpieczne nadpisywanie** - używa merge aby nie utracić istniejących danych
- ✅ **Szczegółowe logi** - pokazuje postęp i błędy
- ✅ **Weryfikacja** - sprawdza rezultat po uploadzie
- ✅ **Obsługa błędów** - kontynuuje przy błędach pojedynczych rekordów

## 🗃️ Struktura danych

Każdy klient zostanie zapisany z następującymi polami:
```javascript
{
  id: 1,
  imie_nazwisko: "Jan Kowalski",
  nazwa_firmy: "Firma Sp. z o.o.",
  telefon: "123456789",
  email: "jan@example.com",
  created_at: "2025-07-31T...",
  updated_at: "2025-07-31T...",
  source: "excel_migration_2025"
}
```

## ⚙️ Konfiguracja

W pliku `upload_clients_to_firebase.js` można zmienić:
- `batchSize` - rozmiar batcha (domyślnie 500)
- Kolekcję docelową (domyślnie 'clients')
- Pola danych do zapisania

## 🔒 Bezpieczeństwo

- Nie commituj pliku `service-account.json` do repozytorium
- Używaj zmiennych środowiskowych w produkcji
- Plik service account powinien być w `.gitignore`

## 📝 Przykład uruchomienia

```bash
$ node upload_clients_to_firebase.js

🚀 FIREBASE CLIENTS UPLOADER
📅 Data: 31.07.2025, 15:55:00
==================================================
🔥 Inicjalizacja Firebase Admin...
✅ Firebase zainicjalizowany pomyślnie!
✅ Połączenie z Firestore potwierdzone!
📄 Ładowanie danych klientów...
✅ Załadowano 1040 klientów z pliku JSON
🔍 Sprawdzanie istniejących klientów w bazie...
📊 Znaleziono 0 istniejących klientów w bazie
🚀 Rozpoczynam upload 1040 klientów...
📦 Podzielono na 3 batchy po 500 klientów

📤 Przetwarzam batch 1/3 (500 klientów)...
   ✅ Zapisano 500 klientów
📤 Przetwarzam batch 2/3 (500 klientów)...
   ✅ Zapisano 500 klientów
📤 Przetwarzam batch 3/3 (40 klientów)...
   ✅ Zapisano 40 klientów

🔍 Weryfikacja uploadu...
📊 Klientów w bazie po uploadzie: 1040
📊 Oczekiwano: 1040
✅ Weryfikacja pomyślna!

============================================================
🎯 PODSUMOWANIE UPLOADU
============================================================
📊 Całkowity czas: 45s
📊 Klientów do uploadu: 1040
✅ Pomyślnie zapisanych: 1040
❌ Błędów: 0
📈 Sukces: 100%
============================================================

🎉 Upload zakończony pomyślnie!
```
