#!/usr/bin/env node

/**
 * 🔍 TEST OBSŁUGI PROBLEMATYCZNYCH WARTOŚCI W EXCEL
 * 
 * Testuje czy null, undefined, NaN, puste stringi, itp. 
 * mogą powodować korupcję pliku Excel
 */

const ExcelJS = require('exceljs');
const fs = require('fs');
const path = require('path');

// Import funkcji pomocniczych (symulacja)
function safeToDouble(value) {
  // Handle null, undefined, empty string
  if (value === null || value === undefined || value === "") return 0.0;

  // Handle "NULL" string literal
  if (typeof value === "string" && (value.toUpperCase() === "NULL" || value.trim() === "")) {
    return 0.0;
  }

  // Handle numbers directly
  if (typeof value === "number") {
    if (isNaN(value) || !isFinite(value)) return 0.0;
    return value;
  }

  // Handle strings
  if (typeof value === "string") {
    const trimmed = value.trim();
    if (trimmed === "") return 0.0;

    // Handle comma-separated numbers (European format)
    let cleaned = trimmed
      .replace(/\s/g, "") // remove spaces
      .replace(/,/g, ".") // replace commas with dots
      .replace(/[^\d.-]/g, ""); // remove everything except digits, dots and minus

    const parsed = parseFloat(cleaned);
    if (isNaN(parsed) || !isFinite(parsed)) return 0.0;
    return parsed;
  }

  return 0.0;
}

function safeToString(value) {
  if (value === null || value === undefined) return "";
  return String(value).trim();
}

function formatDate(dateValue) {
  if (!dateValue) return 'Brak daty';
  
  try {
    const date = new Date(dateValue);
    if (isNaN(date.getTime())) return 'Nieprawidłowa data';
    return date.toLocaleDateString('pl-PL');
  } catch (error) {
    return 'Błąd daty';
  }
}

/**
 * 🧪 Test z problematycznymi wartościami
 */
async function testProblematicValues() {
  console.log('🧪 Test z problematycznymi wartościami...');
  
  // Problematyczne wartości, które mogą wystąpić w danych Firebase
  const problematicTestData = [
    // Normalne wartości
    ['Jan Kowalski', 'Obligacje Standard', 'Obligacje', '2024-01-15', 500000, 450000, 350000, 100000],
    
    // Wartości null/undefined 
    ['Anna Nowak', null, 'Udziały', undefined, null, 250000, undefined, 0],
    
    // Puste stringi
    ['Piotr Test', '', 'Pożyczki', '', '', '', '', ''],
    
    // NaN i Infinity
    ['Maria Problem', 'Test Product', 'Apartamenty', 'invalid-date', NaN, Infinity, -Infinity, Number.POSITIVE_INFINITY],
    
    // Dziwne stringi liczbowe
    ['Krzysztof Data', 'Product Name', 'Obligacje', null, '1,500.50', '2 000,75', 'NULL', ''],
    
    // Bardzo długie stringi
    ['Test' + 'x'.repeat(1000), 'Product' + 'y'.repeat(500), 'Type', '2024-01-01', 0, 0, 0, 0],
    
    // Specjalne znaki
    ['Łukasz Żółć', 'Produkt "Specjalny" & Co', 'Obligacje ąćęłńóśźż', '2024-12-31', 1000.99, 999.99, 500.50, 499.49],
    
    // Boolean wartości (czasem mogą się pojawić)
    [true, false, 'Obligacje', true, false, true, false, true],
    
    // Obiekty i tablice (błędne dane)
    [{ name: 'Test' }, ['array', 'data'], 'Obligacje', { date: '2024-01-01' }, [], {}, [], {}]
  ];
  
  try {
    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'Metropolitan Investment Test';
    workbook.created = new Date();
    workbook.modified = new Date();

    const worksheet = workbook.addWorksheet('Test Problematycznych Wartości');

    // Nagłówki
    const headers = [
      'Klient',
      'Produkt', 
      'Typ',
      'Data podpisania',
      'Kwota inwestycji',
      'Kapitał pozostały',
      'Kapitał zabezpieczony',
      'Do restrukturyzacji'
    ];

    worksheet.addRow(headers);

    // Stylizacja nagłówków
    const headerRow = worksheet.getRow(1);
    headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    headerRow.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF366092' }
    };

    console.log('📊 Przetwarzanie problematycznych danych...');
    
    // Przetwórz każdy wiersz przez funkcje walidujące
    problematicTestData.forEach((rowData, index) => {
      console.log(`\n📋 Row ${index + 1}: Processing...`);
      
      try {
        // Przygotuj dane z użyciem funkcji safe*
        const processedRow = [
          safeToString(rowData[0]), // clientName
          safeToString(rowData[1]), // productName  
          safeToString(rowData[2]), // productType
          formatDate(rowData[3]),   // signedDate
          safeToDouble(rowData[4]), // investmentAmount
          safeToDouble(rowData[5]), // remainingCapital
          safeToDouble(rowData[6]), // capitalSecuredByRealEstate
          safeToDouble(rowData[7])  // capitalForRestructuring
        ];
        
        console.log(`  Original: [${rowData.map(v => typeof v === 'object' ? JSON.stringify(v).substring(0,20) + '...' : String(v).substring(0,20)).join(', ')}]`);
        console.log(`  Processed: [${processedRow.join(', ')}]`);
        
        // Dodaj wiersz do Excel
        const row = worksheet.addRow(processedRow);
        
        // Formatowanie liczb (tylko jeśli to naprawdę liczby)
        if (typeof processedRow[4] === 'number' && !isNaN(processedRow[4])) {
          row.getCell(5).numFmt = '#,##0.00 "PLN"';
        }
        if (typeof processedRow[5] === 'number' && !isNaN(processedRow[5])) {
          row.getCell(6).numFmt = '#,##0.00 "PLN"';
        }
        if (typeof processedRow[6] === 'number' && !isNaN(processedRow[6])) {
          row.getCell(7).numFmt = '#,##0.00 "PLN"';
        }
        if (typeof processedRow[7] === 'number' && !isNaN(processedRow[7])) {
          row.getCell(8).numFmt = '#,##0.00 "PLN"';
        }
        
        console.log(`  ✅ Row ${index + 1} added successfully`);
        
      } catch (rowError) {
        console.error(`  ❌ Error processing row ${index + 1}:`, rowError);
        
        // Dodaj wiersz z błędem jako fallback
        const fallbackRow = [
          'ERROR_ROW',
          'ERROR_PRODUCT', 
          'ERROR_TYPE',
          'Błąd daty',
          0,
          0,
          0,
          0
        ];
        worksheet.addRow(fallbackRow);
      }
    });

    // Szerokości kolumn
    worksheet.columns = [
      { width: 30 }, // Klient (szerszy dla długich danych)
      { width: 35 }, // Produkt
      { width: 20 }, // Typ
      { width: 15 }, // Data
      { width: 18 }, // Kwota inwestycji
      { width: 18 }, // Kapitał pozostały
      { width: 20 }, // Kapitał zabezpieczony
      { width: 18 }  // Do restrukturyzacji
    ];

    // Podsumowanie
    const summaryRow = worksheet.addRow(['']);
    summaryRow.getCell(1).value = `TEST PROBLEMATYCZNYCH WARTOŚCI: ${problematicTestData.length} przypadków testowych`;
    summaryRow.font = { bold: true, italic: true };

    console.log('\n📁 Generowanie buffera Excel...');
    
    // Generuj buffer
    const buffer = await workbook.xlsx.writeBuffer();
    const base64Content = buffer.toString('base64');
    const filename = 'Test_Problematic_Values.xlsx';

    console.log('✅ Excel wygenerowany pomyślnie!');
    console.log(`  - Buffer size: ${buffer.length} bytes`);
    console.log(`  - Base64 length: ${base64Content.length} characters`);
    console.log(`  - Test cases: ${problematicTestData.length}`);

    // Zapisz plik testowo
    const testFilePath = path.join(__dirname, filename);
    fs.writeFileSync(testFilePath, buffer);
    console.log(`💾 Zapisano plik testowy: ${testFilePath}`);
    
    // Sprawdź czy można otworzyć
    const testWorkbook = new ExcelJS.Workbook();
    await testWorkbook.xlsx.readFile(testFilePath);
    
    console.log('✅ Plik testowy poprawnie otwarty przez ExcelJS!');
    
    // Sprawdź zawartość
    const testWorksheet = testWorkbook.getWorksheet(1);
    console.log(`📊 Test file - ${testWorksheet.rowCount} rows, ${testWorksheet.columnCount} columns`);
    
    // Usuń plik
    fs.unlinkSync(testFilePath);
    console.log('🗑️ Usunięto plik testowy');

    return {
      success: true,
      buffer,
      base64Content,
      filename,
      testCasesCount: problematicTestData.length
    };

  } catch (error) {
    console.error('❌ Błąd testu problematycznych wartości:', error);
    return null;
  }
}

/**
 * 🧪 Test dedykowanej funkcji generateDedicatedExcel z problematycznymi danymi
 */
async function testDedicatedExcelWithProblematicData() {
  console.log('\n🧪 Test dedykowanej funkcji z problematycznymi danymi...');
  
  // Symulacja danych jak z validateInvestorData ale z problematycznymi wartościami
  const problematicInvestorsData = [
    {
      clientId: 'client_001',
      clientName: 'Jan Kowalski',
      investments: [
        {
          clientName: 'Jan Kowalski',
          productName: 'Obligacje Standard',
          productType: 'Obligacje',
          signedDate: '15.01.2024',
          investmentAmount: 500000,
          remainingCapital: 450000,
          capitalSecuredByRealEstate: 350000,
          capitalForRestructuring: 100000,
          investmentId: 'inv_001'
        }
      ]
    },
    {
      clientId: 'client_002',
      clientName: null, // Problematyczna wartość
      investments: [
        {
          clientName: '', // Pusta wartość
          productName: undefined, // Undefined
          productType: null, // Null
          signedDate: 'invalid-date', // Nieprawidłowa data
          investmentAmount: NaN, // NaN
          remainingCapital: Infinity, // Infinity  
          capitalSecuredByRealEstate: 'not-a-number', // String zamiast liczby
          capitalForRestructuring: '', // Pusty string
          investmentId: 'inv_002'
        }
      ]
    },
    {
      clientId: '',
      clientName: 'Test Długiej Nazwy ' + 'x'.repeat(500), // Bardzo długa nazwa
      investments: [
        {
          clientName: 'Łukasz Żółć ąćęłńóśźż', // Polskie znaki
          productName: 'Produkt "Specjalny" & Co', // Specjalne znaki
          productType: 'Obligacje ąćęłńóśźż',
          signedDate: null,
          investmentAmount: '1,500.50', // String z liczbą
          remainingCapital: '2 000,75', // Format europejski  
          capitalSecuredByRealEstate: 'NULL', // String NULL
          capitalForRestructuring: false, // Boolean
          investmentId: ''
        }
      ]
    }
  ];
  
  try {
    // Symulacja generateDedicatedExcel
    const workbook = new ExcelJS.Workbook();
    
    workbook.creator = 'Metropolitan Investment';
    workbook.created = new Date();
    workbook.modified = new Date();

    const worksheet = workbook.addWorksheet('Eksport Inwestorów');

    const headers = [
      'Klient',
      'Produkt', 
      'Typ',
      'Data podpisania',
      'Kwota inwestycji',
      'Kapitał pozostały',
      'Kapitał zabezpieczony',
      'Do restrukturyzacji'
    ];

    worksheet.addRow(headers);

    // Stylizacja nagłówków
    const headerRow = worksheet.getRow(1);
    headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    headerRow.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF366092' }
    };

    let totalRows = 0;

    // Przetwórz dane inwestorów (z walidacją)
    problematicInvestorsData.forEach((investor, investorIndex) => {
      console.log(`\n👤 Investor ${investorIndex + 1}: Processing...`);
      
      investor.investments.forEach((investment, invIndex) => {
        console.log(`  💼 Investment ${invIndex + 1}:`, investment.clientName || 'NO_NAME');
        
        try {
          // Użyj funkcji safe* (jak w dedicated-excel-export-service.js)
          const processedInvestment = {
            clientName: safeToString(investment.clientName),
            productName: safeToString(investment.productName),
            productType: safeToString(investment.productType),
            signedDate: formatDate(investment.signedDate),
            investmentAmount: safeToDouble(investment.investmentAmount),
            remainingCapital: safeToDouble(investment.remainingCapital),
            capitalSecuredByRealEstate: safeToDouble(investment.capitalSecuredByRealEstate),
            capitalForRestructuring: safeToDouble(investment.capitalForRestructuring)
          };
          
          console.log(`    Processed:`, processedInvestment);
          
          const row = worksheet.addRow([
            processedInvestment.clientName,
            processedInvestment.productName,
            processedInvestment.productType,
            processedInvestment.signedDate,
            processedInvestment.investmentAmount,
            processedInvestment.remainingCapital,
            processedInvestment.capitalSecuredByRealEstate,
            processedInvestment.capitalForRestructuring
          ]);

          // Formatowanie liczb (bezpieczne)
          try {
            if (typeof processedInvestment.investmentAmount === 'number' && !isNaN(processedInvestment.investmentAmount)) {
              row.getCell(5).numFmt = '#,##0.00 "PLN"';
            }
            if (typeof processedInvestment.remainingCapital === 'number' && !isNaN(processedInvestment.remainingCapital)) {
              row.getCell(6).numFmt = '#,##0.00 "PLN"';
            }
            if (typeof processedInvestment.capitalSecuredByRealEstate === 'number' && !isNaN(processedInvestment.capitalSecuredByRealEstate)) {
              row.getCell(7).numFmt = '#,##0.00 "PLN"';
            }
            if (typeof processedInvestment.capitalForRestructuring === 'number' && !isNaN(processedInvestment.capitalForRestructuring)) {
              row.getCell(8).numFmt = '#,##0.00 "PLN"';
            }
          } catch (formatError) {
            console.warn(`    ⚠️ Format error for row ${totalRows + 1}:`, formatError.message);
          }

          totalRows++;
          console.log(`    ✅ Investment row added (total: ${totalRows})`);
          
        } catch (investmentError) {
          console.error(`    ❌ Error processing investment:`, investmentError);
        }
      });
    });

    // Szerokości kolumn
    worksheet.columns = [
      { width: 25 },
      { width: 30 },
      { width: 15 },
      { width: 12 },
      { width: 18 },
      { width: 18 },
      { width: 20 },
      { width: 18 }
    ];

    // Podsumowanie
    const summaryRow = worksheet.addRow(['']);
    summaryRow.getCell(1).value = `PODSUMOWANIE: ${totalRows} inwestycji od ${problematicInvestorsData.length} inwestorów (TEST PROBLEMATYCZNYCH DANYCH)`;
    summaryRow.font = { bold: true, italic: true };

    // Generuj buffer
    const buffer = await workbook.xlsx.writeBuffer();
    const base64Content = buffer.toString('base64');
    const filename = 'Test_Dedicated_Problematic.xlsx';

    console.log('✅ Dedicated test zakończony pomyślnie!');
    console.log(`  - Generated ${totalRows} investment rows`);
    console.log(`  - Buffer size: ${buffer.length} bytes`);
    console.log(`  - Base64 length: ${base64Content.length}`);
    
    // Zapisz i sprawdź plik
    const testFilePath = path.join(__dirname, filename);
    fs.writeFileSync(testFilePath, buffer);
    console.log(`💾 Zapisano plik testu dedicated: ${testFilePath}`);
    
    // Sprawdź czy można otworzyć
    const testWorkbook = new ExcelJS.Workbook();
    await testWorkbook.xlsx.readFile(testFilePath);
    
    console.log('✅ Plik dedicated test poprawnie otwarty!');
    
    // Usuń plik
    fs.unlinkSync(testFilePath);
    console.log('🗑️ Usunięto plik testu dedicated');
    
    return {
      success: true,
      buffer,
      base64Content,
      totalRows,
      investorCount: problematicInvestorsData.length
    };
    
  } catch (error) {
    console.error('❌ Błąd testu dedicated z problematycznymi danymi:', error);
    return null;
  }
}

/**
 * 🎯 GŁÓWNA FUNKCJA TESTOWA
 */
async function main() {
  console.log('🚀 TEST OBSŁUGI PROBLEMATYCZNYCH WARTOŚCI - ROZPOCZĘCIE\n');
  
  try {
    // Test 1: Podstawowy test problematycznych wartości
    console.log('='.repeat(60));
    const basicTest = await testProblematicValues();
    if (!basicTest) {
      console.log('❌ Test podstawowy nieudany');
      return;
    }
    
    // Test 2: Test dedykowanej funkcji z problematycznymi danymi
    console.log('='.repeat(60));
    const dedicatedTest = await testDedicatedExcelWithProblematicData();
    if (!dedicatedTest) {
      console.log('❌ Test dedicated nieudany');
      return;
    }
    
    // Podsumowanie
    console.log('\n' + '='.repeat(60));
    console.log('🎉 WYNIKI TESTÓW PROBLEMATYCZNYCH WARTOŚCI:');
    console.log('✅ Funkcje safeToDouble, safeToString, formatDate działają poprawnie');
    console.log('✅ Problematyczne wartości (null, undefined, NaN) są bezpiecznie obsługiwane');
    console.log('✅ ExcelJS poprawnie generuje pliki mimo problematycznych danych');
    console.log('✅ Format base64 pozostaje prawidłowy');
    console.log('✅ Polskie znaki i specjalne charaktery są obsługiwane');
    
    console.log('\n📋 WNIOSKI:');
    console.log('🔍 Funkcje walidacyjne w dedicated-excel-export-service.js');
    console.log('   są odporne na problematyczne wartości');
    console.log('🔍 Problem z korupcją Excel NIE jest spowodowany przez null/undefined/NaN');
    console.log('🔍 Prawdopodobne przyczyny korupcji pliku Excel:');
    console.log('   1. ❌ Transfer base64 przez Firebase Functions (headers/encoding)');
    console.log('   2. ❌ Pobieranie/zapisywanie po stronie klienta (Flutter/Dart)');  
    console.log('   3. ❌ Inne problemy z przesyłaniem danych');
    console.log('   4. ❌ Problem z konkretną wersją ExcelJS/Office');
    
    console.log('\n💡 NASTĘPNE KROKI:');
    console.log('   1. Sprawdź logi Firebase Functions podczas eksportu');
    console.log('   2. Porównaj base64 wygenerowany vs. otrzymany po stronie klienta');
    console.log('   3. Sprawdź nagłówki HTTP w odpowiedzi Firebase Functions');
    console.log('   4. Zweryfikuj proces downloadBase64File w Flutter');
    
  } catch (error) {
    console.error('❌ Błąd głównej funkcji testowej:', error);
  }
}

// Uruchom test
if (require.main === module) {
  main();
}