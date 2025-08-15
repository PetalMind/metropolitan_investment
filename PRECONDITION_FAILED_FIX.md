# 🛠️ Naprawka Błędu "Precondition Failed" w Firebase Functions

## Problem
Funkcje email i export kończyły się błędem "Precondition failed" podczas deploymentu.

## Przyczyna
Nowe funkcje używały składni `onCall(async (request) => {...})` zamiast prawidłowej konfiguracji z pamięcią i timeoutem używanej przez inne funkcje w projekcie.

## Rozwiązanie
Zaktualizowano wszystkie nowe funkcje do użycia prawidłowej konfiguracji:

```javascript
// PRZED (błędne):
const myFunction = onCall(async (request) => {

// PO (prawidłowe):
const myFunction = onCall({
  memory: "1GiB",  // lub "2GiB" dla funkcji wymagających więcej pamięci
  timeoutSeconds: 300,  // lub 540 dla długotrwałych operacji
}, async (request) => {
```

## Naprawione funkcje:
1. `sendInvestmentEmailToClient` - 1GiB, 300s
2. `sendEmailsToMultipleClients` - 1GiB, 540s (batch operations)
3. `exportInvestorsData` - 2GiB, 540s (heavy data processing)

## Weryfikacja
```bash
# Deploy z debug logowaniem
firebase deploy --only functions --debug

# Sprawdź status funkcji
firebase functions:list
```

## Status
✅ Wszystkie funkcje email i export powinny teraz działać prawidłowo
✅ Konfiguracja pamięci i timeout dopasowana do wymagań każdej funkcji
✅ Zgodność z istniejącą architekturą Firebase Functions v2
