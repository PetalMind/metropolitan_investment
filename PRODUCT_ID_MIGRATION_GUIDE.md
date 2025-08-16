# 🔧 Migracja productId - Instrukcja konfiguracji

## Przygotowanie środowiska

### 1. Instalacja Firebase Admin SDK

```bash
npm install firebase-admin
```

### 2. Pobranie klucza serwisowego

1. Przejdź do [Firebase Console](https://console.firebase.google.com/)
2. Wybierz swój projekt
3. Przejdź do **Settings** > **Service accounts**
4. Kliknij **Generate new private key**
5. Zapisz plik jako `service-account-key.json` w katalogu głównym projektu

### 3. Aktualizacja konfiguracji

Edytuj plik `add_product_ids_to_investments.js` i zaktualizuj:

```javascript
// Linia ~8
const serviceAccount = require('./service-account-key.json'); // ✅ Popraw ścieżkę

// Linia ~11  
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://metropolitan-investment-default-rtdb.europe-west1.firebasedatabase.app' // ✅ Popraw URL
});
```

## Uruchomienie migracji

### Krok 1: Walidacja danych (tylko sprawdzenie)

```bash
node add_product_ids_to_investments.js --validate-only
```

### Krok 2: Wykonanie migracji

```bash
node add_product_ids_to_investments.js
```

### Krok 3: Ponowna walidacja

```bash
node add_product_ids_to_investments.js --validate-only
```

## Jak to działa

### Logika ProductId

Skrypt implementuje dokładnie tę samą logikę co `DeduplicatedProductService`:

1. **Klucz deduplikacji**: `${productName}_${productType}_${companyId}` (znormalizowane)
2. **ProductId**: ID pierwszej inwestycji w grupie (np. `bond_0093`)
3. **Wszystkie inwestycje** tego samego produktu otrzymują ten sam `productId`

### Przykład

```
Produkt: "Metropolitan Investment A1" + "Bonds" + "Metropolitan Investment S.A."

Inwestycje:
- bond_0093 ← PIERWSZA (staje się productId)
- bond_0094
- bond_0095

Wynik:
- bond_0093.productId = "bond_0093" 
- bond_0094.productId = "bond_0093"
- bond_0095.productId = "bond_0093"
```

## Bezpieczeństwo

- ⚠️ **ZAWSZE rób backup bazy danych przed migracją**
- ✅ Skrypt pomija dokumenty które już mają `productId`
- ✅ Używa Firebase batch (max 500 operacji na raz)
- ✅ Waliduje wymagane pola przed aktualizacją

## Rozwiązywanie problemów

### Błąd: "Permission denied"
```bash
# Sprawdź czy klucz serwisowy ma odpowiednie uprawnienia
# W Firebase Console -> IAM -> sprawdź role dla service account
```

### Błąd: "Collection not found"
```bash
# Sprawdź czy kolekcja 'investments' istnieje
# Uruchom walidację: node add_product_ids_to_investments.js --validate-only
```

### Duża liczba inwestycji
```bash
# Skrypt automatycznie dzieli na batche po 450 operacji
# Możesz monitorować postęp w logach
```

## Po migracji

Po udanej migracji aplikacja Flutter będzie:

1. ✅ Używać `investment.productId` zamiast generowanych hashów
2. ✅ Poprawnie grupować inwestycje według produktów 
3. ✅ Szybsze wyszukiwanie i filtrowanie
4. ✅ Zgodność z `DeduplicatedProductService`
