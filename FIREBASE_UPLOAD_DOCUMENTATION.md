# 🔥 Firebase Upload System - Dokumentacja

## 📋 Przegląd

System do przesyłania znormalizowanych danych JSON do Firebase Firestore z pełnym wsparciem dla:
- ✅ Batch processing (500 dokumentów na raz)
- ✅ Automatyczna konwersja typów danych
- ✅ Walidacja i weryfikacja
- ✅ DRY RUN mode do testowania
- ✅ Szczegółowe logowanie i raporty

## 🚀 Szybki Start

### 1. **Przygotowanie**
```bash
# Upewnij się, że masz znormalizowane dane
./run_normalization.sh

# Przejdź do folderu projektu
cd /path/to/metropolitan_investment
```

### 2. **Konfiguracja Firebase**
```bash
# Umieść plik serviceAccountKey.json w głównym folderze projektu
# LUB ustaw zmienną środowiskową:
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccountKey.json"
```

### 3. **Uruchomienie**
```bash
# Automatyczny skrypt z menu wyboru
./deploy_to_firebase.sh

# LUB uruchom bezpośrednio:
npm run upload-normalized:dry-run  # Test bez wysyłania
npm run upload-normalized          # Wyślij dane
npm run upload-normalized:full     # Pełny proces z raportem
```

---

## 📁 Struktura Plików

### **Główne skrypty:**
- `upload_normalized_data_to_firebase.js` - Główny skrypt uploadu
- `test_firebase_connection.js` - Test połączenia
- `deploy_to_firebase.sh` - Skrypt automatyzacyjny

### **Konfiguracja:**
- `package.json` - Skrypty npm i zależności
- `service-account.json` - Klucze Firebase (NIE COMMITUJ!)

### **Dane:**
- `split_investment_data_normalized/` - Znormalizowane pliki JSON
- `firebase_upload_report.json` - Raport z uploadu

---

## ⚙️ Konfiguracja

### **CONFIG w upload_normalized_data_to_firebase.js:**
```javascript
const CONFIG = {
  batchSize: 500,                    // Dokumentów na batch
  dryRun: false,                     // true = tylko test
  sourceDir: './split_investment_data_normalized',
  collections: {
    'clients_normalized.json': 'clients',
    'apartments_normalized.json': 'investments',
    'loans_normalized.json': 'investments', 
    'shares_normalized.json': 'investments'
  },
  logLevel: 'INFO'                   // DEBUG, INFO, WARN, ERROR
};
```

### **Mapowanie plików na kolekcje:**
| Plik JSON | Kolekcja Firestore | Typ Produktu |
|-----------|-------------------|--------------|
| `clients_normalized.json` | `clients` | - |
| `apartments_normalized.json` | `investments` | `apartment` |
| `loans_normalized.json` | `investments` | `loan` |
| `shares_normalized.json` | `investments` | `share` |

---

## 🔧 Funkcjonalności

### **1. Konwersja Danych**

#### **Timestamps:**
```javascript
// Automatyczna konwersja formatów dat:
"2023/12/25" → Firebase Timestamp
"2023-12-25" → Firebase Timestamp
"25/12/2023" → Firebase Timestamp (format polski)
```

#### **Numeryczne wartości:**
```javascript
// Obsługa przecinków i stringów:
"50,000.50" → 50000.50
"1000" → 1000.0
```

#### **Boolean values:**
```javascript
// Normalizacja wartości logicznych:
"1", 1 → true
"0", 0 → false
```

### **2. Metadane**
Każdy dokument otrzymuje automatycznie:
```javascript
{
  uploadedAt: Firebase.Timestamp.now(),
  dataVersion: '2.0',
  migrationSource: 'normalized_json_import',
  productType: 'apartment|loan|share' // dla inwestycji
}
```

### **3. Generowanie ID**
Priorytet generowania ID dokumentu:
1. `doc.id` (jeśli istnieje)
2. `${clientId}_${productType}_${timestamp}` (dla inwestycji)
3. Automatyczne Firebase ID

---

## 📊 Dostępne Skrypty

### **npm run upload-normalized:dry-run**
```bash
# Test bez wysyłania danych
node upload_normalized_data_to_firebase.js --dry-run
```
- ✅ Waliduje struktur danych
- ✅ Sprawdza połączenie
- ✅ Pokazuje co zostałoby przesłane
- ❌ NIE wysyła danych

### **npm run upload-normalized**
```bash
# Standardowy upload
node upload_normalized_data_to_firebase.js
```
- ✅ Przesyła wszystkie dane
- ✅ Weryfikuje wyniki
- ✅ Generuje logi

### **npm run upload-normalized:cleanup**
```bash
# Usuwa poprzednie dane i przesyła nowe
node upload_normalized_data_to_firebase.js --cleanup
```
- ⚠️  Usuwa dokumenty z `migrationSource: 'normalized_json_import'`
- ✅ Przesyła nowe dane
- ✅ Weryfikuje wyniki

### **npm run upload-normalized:full**
```bash
# Pełny proces z raportem
node upload_normalized_data_to_firebase.js --cleanup --report
```
- 🧹 Cleanup poprzednich danych
- 📤 Upload nowych danych
- 📋 Generuje szczegółowy raport
- ✅ Pełna weryfikacja

### **npm run test-firebase**
```bash
# Test połączenia z Firebase
node test_firebase_connection.js
```
- 🔗 Sprawdza połączenie
- 📁 Listuje kolekcje
- 🔍 Sprawdza uprawnienia

---

## 📋 Przykładowe Użycie

### **Szybki test:**
```bash
./deploy_to_firebase.sh
# Wybierz opcję 1 (DRY RUN)
```

### **Pierwsza instalacja:**
```bash
./deploy_to_firebase.sh
# Wybierz opcję 4 (FULL)
```

### **Aktualizacja danych:**
```bash
./deploy_to_firebase.sh
# Wybierz opcję 3 (CLEANUP + UPLOAD)
```

---

## 📊 Format Raportu

### **Przykładowy firebase_upload_report.json:**
```json
{
  "timestamp": "2025-08-10T14:30:00.000Z",
  "collections": {
    "clients": {
      "total": 1250,
      "imported": 1200,
      "percentage": "96.0"
    },
    "investments": {
      "total": 3800,
      "imported": 3750,
      "percentage": "98.7"
    }
  }
}
```

---

## 🔍 Logowanie

### **Poziomy logowania:**
- **DEBUG**: Szczegółowe informacje o przetwarzanych dokumentach
- **INFO**: Podstawowe informacje o postępie
- **WARN**: Ostrzeżenia (np. puste pliki)
- **ERROR**: Błędy krytyczne

### **Przykładowe logi:**
```
[2025-08-10T14:30:00.000Z] INFO: 🚀 Rozpoczynanie przesyłania znormalizowanych danych do Firebase
[2025-08-10T14:30:01.000Z] INFO: 📁 Przetwarzanie: clients_normalized.json -> clients
[2025-08-10T14:30:02.000Z] INFO: Załadowano plik clients_normalized.json: 1200 rekordów
[2025-08-10T14:30:15.000Z] INFO: ✅ Zakończono clients_normalized.json: 1200 sukces, 0 błędów
```

---

## ⚠️ Uwagi Bezpieczeństwa

### **❌ NIE COMMITUJ:**
- `service-account.json`
- Plików z danymi produkcyjnymi
- Konfiguracji z hasłami

### **✅ SPRAWDŹ PRZED URUCHOMIENIEM:**
- Czy używasz właściwego projektu Firebase
- Czy masz backupy danych
- Czy uruchomiłeś DRY RUN

### **🔒 Uprawnienia Firebase:**
Wymagane uprawnienia dla Service Account:
- `Cloud Datastore User`
- `Firebase Admin`

---

## 🐛 Rozwiązywanie Problemów

### **Błąd: "service-account.json not found"**
```bash
# Pobierz klucz z Firebase Console:
# Project Settings > Service Accounts > Generate Private Key
# Zapisz jako service-account.json w głównym folderze
```

### **Błąd: "Permission denied"**
```bash
# Sprawdź uprawnienia Service Account
# Upewnij się, że konto ma uprawnienia do Firestore
```

### **Błąd: "Module not found"**
```bash
# Zainstaluj zależności:
npm install

# Lub konkretnie Firebase Admin:
npm install firebase-admin
```

### **Dane nie są przesyłane (sukces: 0)**
```bash
# Sprawdź czy pliki JSON istnieją:
ls -la split_investment_data_normalized/

# Sprawdź zawartość plików:
head split_investment_data_normalized/clients_normalized.json
```

---

## 🎯 Następne Kroki

Po zakończeniu uploadu:

### **1. Weryfikacja w Firebase Console**
- Przejdź do Firestore Database
- Sprawdź kolekcje `clients` i `investments`
- Zweryfikuj liczbę dokumentów

### **2. Test w aplikacji Flutter**
```bash
# Uruchom aplikację i sprawdź czy dane się ładują
flutter run
```

### **3. Monitoring wydajności**
- Sprawdź czasy odpowiedzi zapytań
- Zoptymalizuj indeksy jeśli potrzeba

---

## 📞 Wsparcie

W przypadku problemów:
1. Uruchom `npm run test-firebase`
2. Sprawdź logi w konsoli
3. Sprawdź uprawnienia Firebase
4. Użyj DRY RUN do debugowania

---

## 🎉 Gratulacje!

System Firebase Upload jest gotowy do użycia. Twoje znormalizowane dane JSON mogą być teraz bezpiecznie przesłane do Firebase Firestore z pełną kontrolą i monitoringiem procesu.
