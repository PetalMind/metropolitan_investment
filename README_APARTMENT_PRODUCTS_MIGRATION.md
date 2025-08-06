# 🏠 Migracja Produktów Apartamentowych

## Przegląd

Ten system migracji automatycznie ekstraktuje produkty apartamentowe z istniejących danych inwestycyjnych i tworzy odpowiednie wpisy w kolekcji `products` w Firebase Firestore.

## Pliki

1. **`tools/apartment_products_migrator.dart`** - Migrator Dart ekstraktujący produkty
2. **`upload_apartments.js`** - Skrypt JavaScript do wgrywania do Firebase
3. **`apartment_products.json`** - Wygenerowane produkty (tworzone przez migrator)

## Krok po kroku

### 1. Uruchom migrator Dart

```bash
dart run tools/apartment_products_migrator.dart
```

To utworzy:
- `apartment_products.json` - dane produktów apartamentowych
- `upload_apartments.js` - ulepszony skrypt upload

### 2. Wgraj do Firebase

#### Bezpieczny tryb (domyślny)
```bash
node upload_apartments.js
```
- ✅ Dodaje tylko nowe produkty
- ⏭️ Pomija duplikaty
- 🔍 Sprawdza po ID i nazwie+spółce

#### Tryb force (nadpisywanie)
```bash
node upload_apartments.js --force
```
- 🔄 Nadpisuje istniejące produkty
- ⚠️ UWAGA: Może zastąpić dane!

## Funkcje antyduplicatowe

### Sprawdzanie duplikatów

Skrypt sprawdza duplikaty na 2 sposoby:

1. **Po ID produktu**
   ```javascript
   if (existingProducts.has(product.id))
   ```

2. **Po nazwie + spółce + typie**
   ```javascript
   if (existingData.name === product.name && 
       existingData.companyName === product.companyName &&
       existingData.type === 'apartments')
   ```

### Logika działania

```
🔍 Dla każdego produktu:
├── Sprawdź czy ID już istnieje
├── Sprawdź czy nazwa+spółka już istnieje
├── Jeśli duplikat i !--force: POMIŃ
├── Jeśli duplikat i --force: NADPISZ
└── Jeśli nowy: DODAJ
```

## Struktura produktu apartamentowego

```json
{
  "id": "apartment_zakopane_antalovy_metropolitan_investment_sa",
  "name": "Zakopane Antalovy",
  "type": "apartments",
  "companyId": "metropolitan_investment_sa",
  "companyName": "Metropolitan Investment S.A.",
  "currency": "PLN",
  "isPrivateIssue": true,
  "isActive": true,
  "issueDate": "2023-01-15T00:00:00.000Z",
  "maturityDate": null,
  "interestRate": null,
  "sharesCount": null,
  "sharePrice": null,
  "exchangeRate": null,
  "metadata": {
    "originalProductType": "Apartamenty",
    "totalInvestments": 11,
    "totalAmount": 8207820.83,
    "totalRealized": 0,
    "averageInvestment": 746165.53,
    "source": "apartment_migration",
    "examples": [...]
  },
  "createdAt": "2025-08-06T...",
  "updatedAt": "2025-08-06T..."
}
```

## Statystyki przykładowe

Z aktualnej migracji:
- 🏠 **4 unikalne produkty apartamentowe**
- 💼 **91 łącznych inwestycji**  
- 💰 **41,628,389.77 PLN łącznej wartości**
- 📊 **10,407,097.44 PLN średniej na produkt**

### Produkty:
1. **Zakopane Antalovy** - 8.2M PLN (11 inwestycji)
2. **Gdański Harward** - 11.5M PLN (60 inwestycji) 
3. **Osiedle Wilanówka** - 11.7M PLN (6 inwestycji)
4. **Zatoka Komfortu** - 10.2M PLN (14 inwestycji)

## Logi przykładowe

### Bezpieczny tryb
```
🏠 APARTMENT PRODUCTS UPLOADER 🏠
==============================================

🔍 Sprawdzanie istniejących produktów w bazie...
📊 Znaleziono 127 istniejących produktów w bazie

📄 Ładowanie produktów apartamentowych...
✅ Załadowano 4 produktów apartamentowych

🚀 Rozpoczynam upload produktów apartamentowych...
📋 Tryb: BEZPIECZNY (pomijanie duplikatów)

📦 [1/4] Przetwarzam: "Zakopane Antalovy"
  ✅ DODANO NOWY

📦 [2/4] Przetwarzam: "Gdański Harward"  
  ⏭️  POMINIĘTO - ID już istnieje

📦 [3/4] Przetwarzam: "Osiedle Wilanówka"
  ✅ DODANO NOWY

📦 [4/4] Przetwarzam: "Zatoka Komfortu"
  ⏭️  POMINIĘTO - Duplikat nazwy i spółki (istniejący ID: apartment_zatoka_komfortu)

======================================================================
🎯 PODSUMOWANIE UPLOADU PRODUKTÓW APARTAMENTOWYCH
======================================================================
📊 Całkowity czas: 12s
📊 Produktów do sprawdzenia: 4
✅ Nowych dodanych: 2
🔄 Zaktualizowanych: 0
⏭️  Pominiętych (duplikaty): 2
❌ Błędów: 0
📈 Sukces: 50%
======================================================================
```

## Bezpieczeństwo

- ✅ **Sprawdzanie duplikatów** - zapobiega nadpisywaniu
- ✅ **Walidacja danych** - sprawdza wymagane pola
- ✅ **Rollback friendly** - dane zachowują strukturę
- ✅ **Metadane śledzenia** - źródło, wersja, data
- ✅ **Error handling** - graceful failures

## Troubleshooting

### Błąd "apartment_products.json nie istnieje"
```bash
# Uruchom migrator najpierw
dart run tools/apartment_products_migrator.dart
```

### Błąd Firebase permissions
```bash
# Sprawdź czy service account jest skonfigurowany
ls -la service-account.json
```

### Chcę nadpisać istniejące produkty
```bash
# Użyj trybu force
node upload_apartments.js --force
```

### Chcę zobaczyć co będzie dodane bez uploadu
```bash
# Sprawdź apartment_products.json
cat apartment_products.json | jq '.[].name'
```

## Firebase Console

Po uploadzie sprawdź wyniki:
https://console.firebase.google.com/project/metropolitan-investment/firestore/data/~2Fproducts

Filtruj produkty apartamentowe:
```
type == "apartments"
```
