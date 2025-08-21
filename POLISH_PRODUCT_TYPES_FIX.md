# Polskie nazwy typów produktów w eksporcie

## Problem który został rozwiązany
W eksportowanych plikach (Excel, PDF, CSV, Word) typy produktów wyświetlały się w języku angielskim:
- `Bonds` zamiast `Obligacje`
- `Shares` zamiast `Akcje`  
- `Loans` zamiast `Pożyczki`
- `Apartments` zamiast `Apartamenty`

## Rozwiązanie
Dodano funkcję mapowania angielskich nazw typów produktów na polskie nazwy w pliku `advanced-export-service.js`.

## Mapowanie typów produktów

| Angielska nazwa | Polska nazwa |
|----------------|--------------|
| `bonds` / `Bonds` | **Obligacje** |
| `shares` / `Shares` | **Akcje** |
| `loans` / `Loans` | **Pożyczki** |
| `apartments` / `Apartments` | **Apartamenty** |

## Implementacja

### Funkcja mapowania:
```javascript
function mapProductTypeToPolish(englishType) {
  const typeMapping = {
    'bonds': 'Obligacje',
    'shares': 'Akcje', 
    'loans': 'Pożyczki',
    'apartments': 'Apartamenty',
    'Bonds': 'Obligacje',
    'Shares': 'Akcje',
    'Loans': 'Pożyczki', 
    'Apartments': 'Apartamenty'
  };
  
  return typeMapping[englishType] || englishType || 'Nieznany typ';
}
```

### Zastosowanie w kodzie:
```javascript
const rawInvestmentType = safeToString(inv.productType || inv.typ_produktu || 'Nieznany typ');
const investmentType = mapProductTypeToPolish(rawInvestmentType); // Mapowanie na polskie nazwy
```

## Wpływ na formaty eksportu

### ✅ Excel (.xlsx)
```
| Typ produktu |
|--------------|
| Obligacje    |
| Akcje        |
| Pożyczki     |
| Apartamenty  |
```

### ✅ CSV
```
Nazwisko / Nazwa firmy,Nazwa produktu,Typ produktu,Data wejścia...
Jan Kowalski,Obligacja Seria A,Obligacje,15.01.2024...
Anna Nowak,Akcje Tech,Akcje,10.02.2024...
```

### ✅ PDF
```
1. INWESTOR: Jan Kowalski
   INWESTYCJE (2):
   1. Jan Kowalski - Obligacja Seria A - Obligacje
   2. Jan Kowalski - Akcje Tech - Akcje
```

### ✅ Word (.docx)
Wszystkie wzmianki o typach produktów będą w języku polskim.

## Przykład przed i po

### PRZED:
```
| Nazwisko | Typ produktu |
|----------|--------------|
| Jan Kowalski | Bonds |
| Anna Nowak | Shares |
| Piotr Kowal | Loans |
| Maria Zielińska | Apartments |
```

### PO:
```
| Nazwisko | Typ produktu |
|----------|--------------|
| Jan Kowalski | Obligacje |
| Anna Nowak | Akcje |
| Piotr Kowal | Pożyczki |
| Maria Zielińska | Apartamenty |
```

## Zmiany wprowadzone

### Zaktualizowane pliki:
- `functions/services/advanced-export-service.js` - dodano funkcję `mapProductTypeToPolish()`
- `functions/test-polish-product-types.js` - test mapowania (nowy)
- `deploy-polish-types.sh` - skrypt deploy'u (nowy)

### Lokalizacja zmian:
1. **Linia ~261** - dodano funkcję mapowania
2. **Linia ~293** - zastosowano mapowanie w procesowaniu danych
3. **Wszystkie eksporty** - automatycznie używają zmapowanych nazw

## Instrukcje wdrożenia

```bash
# Opcja A - Automatyczny skrypt
chmod +x deploy-polish-types.sh
./deploy-polish-types.sh

# Opcja B - Ręcznie
cd functions
firebase emulators:start --only functions  # terminal 1
node test-polish-product-types.js          # terminal 2
firebase deploy --only functions           # po testach
```

## Testowanie

Po wdrożeniu sprawdź czy:
- ✅ Excel zawiera polskie nazwy w kolumnie "Typ produktu"
- ✅ PDF używa polskich nazw w opisach inwestycji
- ✅ CSV ma polskie nazwy w kolumnie typu
- ✅ Word używa polskich nazw w dokumencie
- ✅ Funkcja fallback działa dla nieznanych typów

## Kompatybilność

- ✅ **Wsteczna kompatybilność** - obsługuje zarówno małe jak i wielkie litery
- ✅ **Fallback** - nieznane typy pozostają bez zmian
- ✅ **Wszystkie formaty** - Excel, PDF, CSV, Word
- ✅ **Istniejące dane** - nie wymaga migracji bazy danych

## Uwagi techniczne

- Mapowanie działa na poziomie eksportu, nie zmienia danych w bazie
- Obsługuje zarówno `bonds` jak i `Bonds` (różne wielkości liter)
- Fallback na oryginalną nazwę jeśli typ nieznany
- Brak wpływu na wydajność (proste mapowanie słownikowe)
