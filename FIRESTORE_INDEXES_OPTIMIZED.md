# Zoptymalizowane Indeksy Firestore

## Przegląd Optymalizacji

Firebase automatycznie tworzy indeksy pojedynczego pola dla:
- Zapytań equality (`where('field', '==', value)`)
- Sortowania (`orderBy('field')`) 
- Zapytań array-contains

**Złożone indeksy są potrzebne tylko dla:**
- Zapytań z wieloma polami w `where`
- Kombinacji `where` + `orderBy` na różnych polach
- Zapytań inequality na różnych polach

## Indeksy Złożone (Wymagane)

### Klienci (clients)
```javascript
// Wyszukiwanie klientów po email + sortowanie po nazwisku
where('email', '==', email).orderBy('imie_nazwisko')

// Filtrowanie aktywnych klientów + sortowanie po nazwisku  
where('isActive', '==', true).orderBy('imie_nazwisko')

// Filtrowanie po typie + sortowanie po nazwisku
where('type', '==', type).orderBy('imie_nazwisko')

// Filtrowanie po statusie głosowania + sortowanie po dacie aktualizacji
where('votingStatus', '==', status).orderBy('updatedAt', 'desc')
```

### Inwestycje (investments)
```javascript
// Filtrowanie po statusie + sortowanie po dacie podpisania
where('status_produktu', '==', status).orderBy('data_podpisania', 'desc')

// Filtrowanie po kliencie + sortowanie po dacie
where('klient', '==', clientId).orderBy('data_podpisania', 'desc')

// Filtrowanie po typie produktu + sortowanie po dacie
where('typ_produktu', '==', type).orderBy('data_podpisania', 'desc')

// Wyszukiwanie po pracowniku (imię + nazwisko) + sortowanie po dacie
where('pracownik_imie', '==', firstName)
  .where('pracownik_nazwisko', '==', lastName)
  .orderBy('data_podpisania', 'desc')

// Filtrowanie po dacie wymagalności + status
where('data_wymagalnosci', '>=', date).where('status_produktu', '==', status)

// Filtrowanie po oddziale + sortowanie po dacie
where('kod_oddzialu', '==', code).orderBy('data_podpisania', 'desc')

// Sortowanie po wartości + filtrowanie po statusie
orderBy('wartosc_kontraktu', 'desc').where('status_produktu', '==', status)

// Zaawansowane filtry - status + typ + wartość
where('status_produktu', '==', status)
  .where('typ_produktu', '==', type)
  .orderBy('wartosc_kontraktu', 'desc')

// Zakres dat - podpisanie do wymagalności
where('data_podpisania', '>=', startDate)
  .where('data_wymagalnosci', '<=', endDate)

// Filtrowanie po przydziale + status + sortowanie
where('przydzial', '==', allocation)
  .where('status_produktu', '==', status)
  .orderBy('data_podpisania', 'desc')
```

### Produkty (products)
```javascript
// Aktywne produkty po typie + sortowanie po nazwie
where('isActive', '==', true)
  .where('type', '==', type)
  .orderBy('name')

// Aktywne produkty po firmie + sortowanie po nazwie  
where('isActive', '==', true)
  .where('companyId', '==', companyId)
  .orderBy('name')

// Aktywne produkty + sortowanie po dacie wymagalności
where('isActive', '==', true).orderBy('maturityDate')

// Typ + data wymagalności + status aktywności
where('type', '==', type)
  .where('maturityDate', '>=', date)
  .where('isActive', '==', true)
```

### Firmy (companies)
```javascript
// Aktywne firmy + sortowanie po nazwie
where('isActive', '==', true).orderBy('name')

// Filtrowanie po typie + sortowanie po nazwie
where('type', '==', type).orderBy('name')
```

### Pracownicy (employees)
```javascript
// Aktywni pracownicy + sortowanie po nazwisku i imieniu
where('isActive', '==', true)
  .orderBy('lastName')
  .orderBy('firstName')

// Aktywni pracownicy po oddziale + sortowanie po nazwisku
where('isActive', '==', true)
  .where('branchCode', '==', code)
  .orderBy('lastName')
```

### Akcje, Obligacje, Pożyczki (shares, bonds, loans)
```javascript
// Typ produktu + sortowanie po dacie podpisania
where('typ_produktu', '==', type).orderBy('data_podpisania', 'desc')
```

## Indeksy Pojedyncze (Automatyczne)

Firebase automatycznie utworzy indeksy dla:
- `email` (equality)
- `isActive` (equality)
- `type` (equality)
- `status_produktu` (equality)
- `klient` (equality)
- `data_podpisania` (sorting)
- `wartosc_kontraktu` (sorting)
- `name` (sorting)
- `maturityDate` (sorting/equality)
- I wszystkie inne pola używane w prostych zapytaniach

## Statystyki Wydajności

**Przed optymalizacją:**
- ~35 indeksów (w tym niepotrzebne pojedyncze)
- Zwiększone zużycie storage
- Wolniejsze zapisy

**Po optymalizacji:**
- ~26 indeksów złożonych (tylko niezbędne)
- Automatyczne indeksy pojedyncze
- Szybsze zapisy i queries
- Zredukowane koszty storage

## Monitoring

Użyj Firebase Console aby monitorować:
1. **Usage metrics** - liczba queries i ich wydajność
2. **Index usage** - które indeksy są używane najczęściej
3. **Missing indexes** - Firebase automatycznie wykryje brakujące indeksy

## Polecenia Deployment

```bash
# Wgranie indeksów
firebase deploy --only firestore:indexes

# Sprawdzenie statusu
firebase firestore:indexes

# Usunięcie nieużywanych indeksów
firebase firestore:indexes:delete
```
