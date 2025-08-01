# 🌐 Przewodnik rozwiązywania problemów CORS w developmencie

## 🚨 Problem
Aplikacja Flutter uruchomiona lokalnie na `http://localhost:8080` lub `http://0.0.0.0:8080` nie może komunikować się z Firebase Cloud Functions ze względu na politykę CORS.

## 🔍 Objawy błędu:
```
Access to fetch at 'https://europe-west1-metropolitan-investment.cloudfunctions.net/analyzeMajorityControl' 
from origin 'http://0.0.0.0:8080' has been blocked by CORS policy: 
Response to preflight request doesn't pass access control check: 
No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

## 🔧 Rozwiązania:

### 1. **Konfiguracja CORS w Firebase Functions** (Zalecane)

W pliku `functions/index.js` dodaj obsługę CORS:

```javascript
const cors = require('cors')({
  origin: [
    'http://localhost:8080',
    'http://0.0.0.0:8080',
    'http://127.0.0.1:8080',
    'https://your-project.web.app',
    'https://your-project.firebaseapp.com'
  ]
});

exports.analyzeMajorityControl = functions.https.onRequest((req, res) => {
  cors(req, res, () => {
    // Twój kod funkcji
  });
});
```

### 2. **Deployment na Firebase Hosting**

```bash
# Build aplikacji
flutter build web

# Deploy na Firebase Hosting
firebase deploy --only hosting
```

### 3. **Uruchomienie lokalnego serwera Firebase**

```bash
# Uruchom lokalne środowisko Firebase
firebase serve --only hosting,functions

# Aplikacja będzie dostępna na localhost:5000
```

### 4. **Użycie Firebase Emulator Suite**

```bash
# Uruchom emulatory
firebase emulators:start

# Skonfiguruj aplikację do używania emulatorów
```

### 5. **Chrome z wyłączonym CORS** (Tylko dla developmentu!)

```bash
# Linux/Mac
google-chrome --disable-web-security --disable-features=VizDisplayCompositor --user-data-dir=/tmp/chrome_dev_session

# Windows
chrome.exe --disable-web-security --disable-features=VizDisplayCompositor --user-data-dir=c:\temp\chrome_dev_session
```

## ⚠️ Ważne uwagi:

1. **CORS to mechanizm bezpieczeństwa** - nie wyłączaj go w produkcji
2. **Firebase Hosting** automatycznie obsługuje CORS dla tego samego domeny
3. **Emulatory** są najlepszym rozwiązaniem dla developmentu
4. **Lokalny development** z Functions wymaga odpowiedniej konfiguracji

## 🛠️ Implementacja w kodzie:

Aplikacja została zaktualizowana o:
- ✅ Lepszą obsługę błędów CORS
- ✅ Bezpieczne zamykanie dialogów
- ✅ Informacyjne komunikaty o problemach z Firebase Functions
- ✅ Fallback dla funkcji wymagających Firebase Functions

## 📱 Testowanie:

1. **Lokalnie**: `flutter run -d chrome --web-port 8080`
2. **Firebase Hosting**: `firebase deploy && firebase hosting:channel:deploy preview`
3. **Emulatory**: `firebase emulators:start && flutter run -d chrome --web-port 5000`

## 🔗 Przydatne linki:

- [Firebase CORS Documentation](https://firebase.google.com/docs/functions/http-events#cors)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)
