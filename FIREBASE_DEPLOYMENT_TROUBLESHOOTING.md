# Firebase Hosting Deployment - Rozwiązywanie problemów

## Problem
Podczas próby deployment do Firebase Hosting pojawia się błąd:
```
Error: Invalid project id: firebase use kosztomat.
```

## Przyczyna
Firebase CLI cache miał nieprawidłowy alias projektu z poprzednich prób konfiguracji.

## Rozwiązanie

### 1. Sprawdź aktualną konfigurację
```bash
cat .firebaserc
```

### 2. Wyczyść cache Firebase CLI
```bash
firebase use --clear
```

### 3. Ustaw poprawny projekt
```bash
firebase use metropolitan-investment
```

### 4. Opcjonalnie: Użyj service account
```bash
export GOOGLE_APPLICATION_CREDENTIALS="./service-account.json"
firebase deploy --only hosting
```

### 5. Alternatywne rozwiązanie - manualne wgranie przez Firebase Console
1. Zbuduj aplikację: `flutter build web --release`
2. Przejdź do Firebase Console: https://console.firebase.google.com/
3. Wybierz projekt `metropolitan-investment`
4. Przejdź do Hosting
5. Ręcznie wgraj zawartość folderu `build/web/`

## Status plików konfiguracyjnych

### firebase.json ✅
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

### .firebaserc ✅
```json
{
  "projects": {
    "default": "metropolitan-investment"
  }
}
```

### Build Flutter Web ✅
- Lokalizacja: `build/web/`
- Status: Kompletny z wszystkimi plikami
- Wersja: Najnowsza (flutter build web wykonane)

## Przyszłe deployment
Użyj skryptu `deploy.sh` który automatyzuje cały proces.
