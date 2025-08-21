# Ulepszenie formatu eksportu Excel - Podzielone kolumny

## Problem który został rozwiązany
W poprzednim formacie Excel wszystkie dane klienta, nazwy produktu i typu były łączone w jednej kolumnie "Inwestor - Produkt - Typ", co utrudniało analizę i sortowanie danych.

## Nowy format Excel

### Kolumny w języku polskim:

| Nr | Kolumna | Opis | Formatowanie |
|----|---------|------|--------------|
| 1 | **Nazwisko / Nazwa firmy** | Imię i nazwisko osoby fizycznej lub nazwa firmy | Tekst |
| 2 | **Nazwa produktu** | Konkretna nazwa produktu inwestycyjnego | Tekst |  
| 3 | **Typ produktu** | Kategoria produktu (Obligacja, Lokata, Pożyczka, itp.) | Tekst |
| 4 | **Data wejścia** | Data rozpoczęcia inwestycji | Data (dd.mm.rrrr) |
| 5 | **Kwota inwestycji (PLN)** | Początkowa kwota inwestycji | Waluta PLN |
| 6 | **Kapitał pozostały (PLN)** | Aktualna wartość inwestycji | Waluta PLN |
| 7 | **Kapitał zabezpieczony nieruchomością (PLN)** | Kwota zabezpieczona | Waluta PLN |
| 8 | **Kapitał do restrukturyzacji (PLN)** | Kwota wymagająca restrukturyzacji | Waluta PLN |

### Korzyści nowego formatu:

✅ **Łatwiejsze sortowanie** - możliwość sortowania osobno po nazwisku, produkcie lub typie  
✅ **Lepsza analiza** - filtry Excel działają na pojedynczych polach  
✅ **Czytelność** - przejrzyste kolumny zamiast łączonych tekstów  
✅ **Formatowanie kwot** - automatyczne formatowanie PLN z separatorami tysięcy  
✅ **Optymalne szerokości** - kolumny automatycznie dopasowane do zawartości  
✅ **Polski interfejs** - wszystkie nagłówki w języku polskim  

### Przykład danych:

| Nazwisko / Nazwa firmy | Nazwa produktu | Typ produktu | Data wejścia | Kwota inwestycji (PLN) | Kapitał pozostały (PLN) |
|----------------------|----------------|--------------|--------------|----------------------|------------------------|
| Jan Kowalski | Obligacja korporacyjna Seria A | Obligacja | 15.01.2024 | 75 000,00 PLN | 65 000,00 PLN |
| Firma ABC Sp. z o.o. | Pożyczka hipoteczna na mieszkanie | Pożyczka | 20.02.2024 | 200 000,00 PLN | 180 000,00 PLN |

## Zmiany techniczne

### Zaktualizowane pliki:
- `functions/services/advanced-export-service.js` - główna logika Excel
- `functions/test-excel-format.js` - test nowego formatu (nowy)
- `deploy-excel-fix.sh` - skrypt deploy'u (nowy)

### Kod nagłówków:
```javascript
const headers = [
  'Nazwisko / Nazwa firmy',
  'Nazwa produktu', 
  'Typ produktu',
  'Data wejścia',
  'Kwota inwestycji (PLN)',
  'Kapitał pozostały (PLN)',
  'Kapitał zabezpieczony nieruchomością (PLN)',
  'Kapitał do restrukturyzacji (PLN)'
];
```

### Formatowanie kwot:
```javascript
const currencyFormat = '#,##0.00 "PLN"';
for (let i = 5; i <= 8; i++) {
  worksheet.getColumn(i).numFmt = currencyFormat;
}
```

## Instrukcje wdrożenia

```bash
# 1. Przejdź do katalogu projektu
cd /home/deb/Documents/metropolitan_investment

# 2. Uruchom skrypt deploy'u
chmod +x deploy-excel-fix.sh
./deploy-excel-fix.sh
```

**LUB ręcznie:**

```bash
# 1. Przetestuj lokalnie (wymaga emulatora)
cd functions
firebase emulators:start --only functions  # w pierwszym terminalu
node test-excel-format.js                  # w drugim terminalu

# 2. Sprawdź plik test_excel_separated_columns.xlsx

# 3. Wdróż do produkcji
firebase deploy --only functions
```

## Kompatybilność

- ✅ **CSV fallback** - również zaktualizowany z podzielonymi kolumnami
- ✅ **Istniejące dane** - format danych nie zmieniony, tylko prezentacja
- ✅ **Wszystkie przeglądarki** - standardowy format Excel (.xlsx)
- ✅ **LibreOffice/OpenOffice** - pełna kompatybilność

## Testowanie

Po wdrożeniu sprawdź czy:
- ✅ Excel otwiera się poprawnie
- ✅ Kolumny są oddzielne i nazywają się po polsku
- ✅ Kwoty mają formatowanie PLN z separatorami
- ✅ Można sortować i filtrować po każdej kolumnie
- ✅ Dane są kompletne i poprawne
