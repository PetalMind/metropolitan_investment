# 🔥 Aktualizacja Indeksów Firestore - Znormalizowane Nazwy Pól

## 📋 Przegląd Zmian

Wszystkie indeksy Firestore zostały zaktualizowane zgodnie z **znormalizowanymi nazwami pól** z `DART_MODELS_UPDATE_GUIDE.md`. Indeksy teraz używają angielskich nazw pól zamiast polskich.

## 🔄 Mapowanie Nazw Pól w Indeksach

### 🏢 **Kolekcja: `clients`**

| Stara nazwa | ➡️ | Nowa znormalizowana | Opis |
|-------------|----|--------------------|------|
| `imie_nazwisko` | ➡️ | `fullName` | Imię i nazwisko klienta |

### 💰 **Kolekcje: `bonds`, `shares`, `loans`, `apartments`**

| Stara nazwa | ➡️ | Nowa znormalizowana | Opis |
|-------------|----|--------------------|------|
| `ID_Klient` | ➡️ | `clientId` | ID klienta |
| `Produkt_nazwa` | ➡️ | `productName` | Nazwa produktu |
| `pozyczkobiorca` | ➡️ | `borrower` | Pożyczkobiorca (loans) |
| `nazwa_projektu` | ➡️ | `projectName` | Nazwa projektu (apartments) |
| `deweloper` | ➡️ | `developer` | Deweloper (apartments) |
| `typ_produktu` | ➡️ | `productType` | Typ produktu |
| `kapital_pozostaly` | ➡️ | `remainingCapital` | Kapitał pozostały |
| `kapital_do_restrukturyzacji` | ➡️ | `capitalForRestructuring` | Kapitał do restrukturyzacji |
| `kapital_zabezpieczony_nieruchomoscia` | ➡️ | `realEstateSecuredCapital` | Kapitał zabezpieczony nieruchomością |
| `created_at` | ➡️ | `createdAt` | Data utworzenia |

### 📊 **Kolekcja: `investments`**

| Stara nazwa | ➡️ | Nowa znormalizowana | Opis |
|-------------|----|--------------------|------|
| `id_klient` | ➡️ | `clientId` | ID klienta |
| `klient` | ➡️ | `clientName` | Nazwa klienta |
| `produkt_nazwa` | ➡️ | `productName` | Nazwa produktu |
| `typ_produktu` | ➡️ | `productType` | Typ produktu |
| `status_produktu` | ➡️ | `productStatus` | Status produktu |
| `data_kontraktu` | ➡️ | `contractDate` | Data kontraktu |
| `data_podpisania` | ➡️ | `signingDate` | Data podpisania |
| `data_wymagalnosci` | ➡️ | `maturityDate` | Data wymagalności |
| `wartosc_kontraktu` | ➡️ | `contractValue` | Wartość kontraktu |
| `kapital_pozostaly` | ➡️ | `remainingCapital` | Kapitał pozostały |
| `pracownik_imie` | ➡️ | `employeeFirstName` | Imię pracownika |
| `pracownik_nazwisko` | ➡️ | `employeeLastName` | Nazwisko pracownika |
| `kod_oddzialu` | ➡️ | `branchCode` | Kod oddziału |
| `przydzial` | ➡️ | `allocation` | Przydział |

## 🚀 **Wdrożenie Indeksów**

### Polecenia do wykonania:

```bash
# 1. Wdróż zaktualizowane indeksy
firebase deploy --only firestore:indexes

# 2. Sprawdź status indeksów
firebase firestore:indexes

# 3. W przypadku problemów z istniejącymi indeksami
firebase deploy --only firestore:indexes --force
```

## ✅ **Korzyści z Aktualizacji**

### 🎯 **Zgodność z kodem**
- Indeksy używają tych samych nazw pól co modele Dart
- Spójność w całej aplikacji
- Łatwiejsze debugowanie zapytań

### 🔍 **Optymalizacja zapytań**
- Wszystkie główne zapytania są zindeksowane
- Obsługa sortowania i filtrowania
- Kompozytowe indeksy dla złożonych zapytań

### 🛡️ **Kompatybilność**
- Firebase automatycznie obsługuje single-field indeksy
- Zachowane są tylko konieczne indeksy kompozytowe
- Brak niepotrzebnych indeksów (błąd HTTP 400)

## 📈 **Główne Kategorie Indeksów**

### 1️⃣ **Indeksy klientów**
```json
{
  "fields": [
    { "fieldPath": "email", "order": "ASCENDING" },
    { "fieldPath": "fullName", "order": "ASCENDING" }
  ]
}
```

### 2️⃣ **Indeksy inwestycji**
```json
{
  "fields": [
    { "fieldPath": "productStatus", "order": "ASCENDING" },
    { "fieldPath": "signingDate", "order": "DESCENDING" }
  ]
}
```

### 3️⃣ **Indeksy kapitałów**
```json
{
  "fields": [
    { "fieldPath": "remainingCapital", "order": "DESCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

### 4️⃣ **Indeksy analityczne**
```json
{
  "fields": [
    { "fieldPath": "productStatus", "order": "ASCENDING" },
    { "fieldPath": "productType", "order": "ASCENDING" },
    { "fieldPath": "contractValue", "order": "DESCENDING" }
  ]
}
```

## ⚠️ **Ważne Uwagi**

### 🔄 **Proces migracji**
1. **Bezpieczne**: Stare dane nadal działają dzięki fallback w modelach Dart
2. **Stopniowe**: Nowe dane używają znormalizowanych nazw
3. **Automatyczne**: Firebase będzie używać odpowiednich indeksów

### 🛠️ **Wskazówki deweloperskie**
- Używaj znormalizowanych nazw w nowych zapytaniach
- Stare nazwy będą działać do momentu pełnej migracji danych
- Monitoruj performance zapytań po wdrożeniu

### 📊 **Testowanie**
```dart
// Przykład zapytania z nowymi nazwami
FirebaseFirestore.instance
  .collection('investments')
  .where('productStatus', isEqualTo: 'active')
  .orderBy('signingDate', descending: true)
  .limit(50);
```

## 🎯 **Następne Kroki**

1. **Deploy indeksów**: `firebase deploy --only firestore:indexes`
2. **Upload znormalizowanych danych**: `node upload_normalized_data_to_firebase.js`
3. **Testowanie zapytań**: Sprawdź czy wszystkie zapytania działają prawidłowo
4. **Monitoring**: Obserwuj metryki wydajności w Firebase Console

## ✨ **Podsumowanie**

Indeksy Firestore zostały w pełni **dostosowane do znormalizowanego schematu** i są **gotowe do użycia** z nowymi danymi JSON! 🚀

---

**Status**: ✅ **Gotowe do wdrożenia**  
**Kompatybilność**: 🔄 **Backward compatible**  
**Testowane**: ⏳ **Oczekuje na deployment**
