# 🔧 Naprawa eksportu dokumentów - Instrukcje wdrożenia

## Problem
Aplikacja generowała "fałszywe" pliki:
- PDF: zwykły tekst z `Content-Type: application/pdf`
- Excel: CSV z `Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
- Word: zwykły tekst z `Content-Type: application/vnd.openxmlformats-officedocument.wordprocessingml.document`

## Rozwiązanie
Dodano prawdziwe biblioteki do generowania plików binarnych:
- **ExcelJS** - prawdziwe pliki Excel (.xlsx)
- **PDFKit** - prawdziwe pliki PDF 
- **docx** - prawdziwe pliki Word (.docx)

## Kroki wdrożenia

### 1. Zainstaluj zależności w Functions
```bash
cd functions
npm install exceljs@^4.4.0 pdfkit@^0.15.0 docx@^8.5.0
```

LUB użyj przygotowanego skryptu:
```bash
chmod +x install_export_dependencies.sh
./install_export_dependencies.sh
```

### 2. Wdróż Functions na Firebase
```bash
firebase deploy --only functions
```

### 3. Przetestuj eksport
1. Uruchom aplikację
2. Wybierz inwestorów w trybie eksportu
3. Wybierz format (PDF/Excel/Word)
4. Sprawdź czy pobrany plik otwiera się poprawnie

## Zmiany techniczne

### Nowe funkcje generowania:
- `generatePDFExport()` - używa PDFKit do prawdziwych PDF
- `generateExcelExport()` - używa ExcelJS do prawdziwych Excel
- `generateWordExport()` - używa docx do prawdziwych Word

### Fallback:
Jeśli biblioteka niedostępna, funkcja używa fallback:
- PDF → TXT (`text/plain`)
- Excel → CSV (`text/csv`)
- Word → TXT (`text/plain`)

### Diagnostyka:
- Sprawdzanie dostępności bibliotek przy starcie
- Szczegółowe logowanie procesów generowania
- Informacje o rozmiarach wygenerowanych plików

## Oczekiwane rezultaty
✅ Pliki PDF otwierają się w czytnikach PDF  
✅ Pliki Excel otwierają się w Excel/LibreOffice  
✅ Pliki Word otwierają się w Word/LibreOffice  
✅ Zachowane formatowanie i struktura danych  
✅ Lepsze komunikaty błędów w przypadku problemów
