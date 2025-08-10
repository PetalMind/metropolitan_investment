# 🔄 Aktualizacja Modeli Dart - Zgodność z Znormalizowanymi JSON

## Przegląd Zmian

Wszystkie modele Dart zostały zaktualizowane, aby obsługiwać zarówno znormalizowane nazwy pól (priorytet), jak i starsze nazwy dla kompatybilności wstecznej.

## 📊 Mapowanie Pól

### Model: `Client`

| Stara nazwa | Znormalizowana nazwa | Kod Dart |
|-------------|---------------------|----------|
| `imie_nazwisko` | `fullName` | `name` |
| `nazwa_firmy` | `companyName` | `companyName` |
| `telefon` | `phone` | `phone` |
| `created_at` | `createdAt` | `createdAt` |
| `uploaded_at` | `uploadedAt` | `updatedAt` |
| `source_file` | `sourceFile` | `additionalInfo['sourceFile']` |

### Model: `Apartment`

| Stara nazwa | Znormalizowana nazwa | Kod Dart |
|-------------|---------------------|----------|
| `typ_produktu` | `productType` | `productType` |
| `kwota_inwestycji` | `investmentAmount` | `investmentAmount` |
| `kapital_do_restrukturyzacji` | `capitalForRestructuring` | `capitalForRestructuring` |
| `kapital_zabezpieczony_nieruchomoscia` | `realEstateSecuredCapital` | `capitalSecuredByRealEstate` |
| `numer_apartamentu` | `apartmentNumber` | `apartmentNumber` |
| `budynek` | `building` | `building` |
| `adres` | `address` | `address` |
| `powierzchnia` | `area` | `area` |
| `liczba_pokoi` | `roomCount` | `roomCount` |
| `pietro` | `floor` | `floor` |
| `cena_za_m2` | `pricePerM2` | `pricePerSquareMeter` |
| `data_oddania` | `deliveryDate` | `deliveryDate` |
| `deweloper` | `developer` | `developer` |
| `nazwa_projektu` | `projectName` | `projectName` |
| `balkon` | `balcony` | `hasBalcony` |
| `miejsce_parkingowe` | `parkingSpace` | `hasParkingSpace` |
| `komorka_lokatorska` | `storageRoom` | `hasStorage` |

### Model: `Loan`

| Stara nazwa | Znormalizowana nazwa | Kod Dart |
|-------------|---------------------|----------|
| `kapital_pozostaly` | `remainingCapital` | `remainingCapital` |
| `ID_Klient` | `clientId` | `clientId` |
| `Klient` | `clientName` | `clientName` |
| `pozyczka_numer` | `loanNumber` | `loanNumber` |
| `pozyczkobiorca` | `borrower` | `borrower` |
| `wierzyciel_spolka` | `creditorCompany` | `creditorCompany` |
| `oprocentowanie` | `interestRate` | `interestRate` |
| `data_udzielenia` | `disbursementDate` | `disbursementDate` |
| `data_splaty` | `repaymentDate` | `repaymentDate` |
| `odsetki_naliczone` | `accruedInterest` | `accruedInterest` |
| `zabezpieczenie` | `collateral` | `collateral` |

### Model: `Share`

| Stara nazwa | Znormalizowana nazwa | Kod Dart |
|-------------|---------------------|----------|
| `Ilosc_Udzialow` | `shareCount` | `sharesCount` |
| `Kapital Pozostaly` | `remainingCapital` | `remainingCapital` |
| `Kwota_inwestycji` | `investmentAmount` | `investmentAmount` |

### Model: `Investment` (Główny Model)

| Stara nazwa | Znormalizowana nazwa | Kod Dart |
|-------------|---------------------|----------|
| `ID_Klient` | `clientId` | `clientId` |
| `Klient` | `clientName` | `clientName` |
| `Oddzial` | `branch` | `branchCode` |
| `Status_produktu` | `productStatus` | `status` |
| `Produkt_status_wejscie` | `productStatusEntry` | `marketType` |
| `Data_podpisania` | `signingDate` | `signedDate` |
| `Data_wejscia_do_inwestycji` | `investmentEntryDate` | `entryDate` |
| `ID_Sprzedaz` | `saleId` | `proposalId` |
| `Typ_produktu` | `productType` | `productType` |
| `Produkt_nazwa` | `productName` | `productName` |
| `ID_Spolka` | `companyId` | `companyId` |
| `Ilosc_Udzialow` | `shareCount` | `sharesCount` |
| `Kapital Pozostaly` | `remainingCapital` | `remainingCapital` |
| `Opiekun z MISA` | `misaGuardian` | `additionalInfo['misaGuardian']` |

## 🔍 Strategia Kompatybilności

### 1. **Priorytet odczytywania** (`fromFirestore`)
```dart
// Znormalizowana nazwa ma priorytet
name: data['fullName'] ?? data['imie_nazwisko'] ?? data['name'] ?? '',
```

### 2. **Podwójny zapis** (`toFirestore`)
```dart
// Zapisz obie wersje
'fullName': name,           // Nowa znormalizowana
'imie_nazwisko': name,      // Stara dla kompatybilności
```

### 3. **Hierarchia nazw pól**
1. **Priorytet 1**: Znormalizowane nazwy angielskie (`fullName`, `investmentAmount`)
2. **Priorytet 2**: Stare nazwy z wielkimi literami (`Kapital Pozostaly`, `ID_Klient`)
3. **Priorytet 3**: Stare nazwy z małymi literami (`kapital_pozostaly`, `id_klient`)

## 🚀 Korzyści z Aktualizacji

### ✅ **Zgodność z nowym schematem**
- Modele obsługują znormalizowane nazwy pól z JSON
- Automatyczna migracja na nowe nazwy

### ✅ **Kompatybilność wsteczna**
- Istniejące dane nadal działają
- Stare nazwy pól są obsługiwane

### ✅ **Bezpieczna migracja**
- Brak ryzyka utraty danych
- Stopniowa migracja możliwa

### ✅ **Lepszy kod**
- Spójne nazwy w całej aplikacji
- Łatwiejsze debugowanie

## 🔧 Używanie Zaktualizowanych Modeli

### Nowe dane (po normalizacji)
```dart
// JSON znormalizowany
{
  "fullName": "Jan Kowalski",
  "investmentAmount": 100000,
  "remainingCapital": 50000
}

// Automatycznie mapowane do:
final client = Client.fromFirestore(doc);
print(client.name); // "Jan Kowalski"
```

### Stare dane (przed normalizacją)
```dart
// JSON nieznormalizowany
{
  "imie_nazwisko": "Jan Kowalski", 
  "Kwota_inwestycji": "100,000.00",
  "Kapital Pozostaly": "50,000.00"
}

// Nadal działa:
final investment = Investment.fromFirestore(doc);
print(investment.clientName); // "Jan Kowalski"
print(investment.remainingCapital); // 50000.0
```

## ⚠️ Uwagi Implementacyjne

### 1. **Obsługa stringów z przecinkami**
```dart
// Automatyczna konwersja "50,000.00" -> 50000.0
double parseCapitalValue(dynamic value) {
  if (value is String) {
    final cleaned = value.replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0.0;
  }
  return safeToDouble(value);
}
```

### 2. **Nullable safety**
```dart
// Bezpieczne fallback do starych nazw
data['clientId'] ?? data['ID_Klient'] ?? ''
```

### 3. **Zachowanie dodatkowych informacji**
```dart
// Wszystkie nierozpoznane pola trafiają do additionalInfo
additionalInfo: Map<String, dynamic>.from(data)
  ..removeWhere((key, value) => knownFields.contains(key))
```

## 🎯 Następne Kroki

1. **Testowanie**: Przetestuj import z znormalizowanymi JSON
2. **Walidacja**: Upewnij się, że stare dane nadal działają  
3. **Deployment**: Deploy zaktualizowanych modeli
4. **Monitoring**: Monitoruj czy wszystkie pola są poprawnie mapowane

## 📝 Przykład Użycia

```dart
// Import ze znormalizowanego JSON
final apartments = await FirebaseFirestore.instance
    .collection('apartments')
    .get()
    .then((snapshot) => snapshot.docs
        .map((doc) => Apartment.fromFirestore(doc))
        .toList());

// Wszystkie pola są automatycznie mapowane:
for (final apt in apartments) {
  print('Numer: ${apt.apartmentNumber}');     // z 'apartmentNumber'
  print('Budynek: ${apt.building}');          // z 'building' 
  print('Powierzchnia: ${apt.area}');         // z 'area'
  print('Kapitał: ${apt.remainingCapital}');  // z Investment base class
}
```

## ✨ **Podsumowanie**

Modele zostały **w pełni dostosowane** do nowego schematu JSON przy zachowaniu **100% kompatybilności wstecznej**. Aplikacja będzie działać zarówno ze starymi, jak i nowymi danymi! 🎉
