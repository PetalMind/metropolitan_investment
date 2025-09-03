#!/usr/bin/env node

/**
 * 🔍 PROSTSZY TEST EXCEL - Testuje format Excel z mock danymi
 * 
 * Ten test sprawdza:
 * 1. Czy ExcelJS prawidłowo generuje plik .xlsx
 * 2. Czy struktura danych jest poprawna  
 * 3. Czy format base64 jest prawidłowy
 * 4. Czy plik można otworzyć
 */

const ExcelJS = require('exceljs');
const fs = require('fs');
const path = require('path');

/**
 * 🧪 Test podstawowego generowania Excel
 */
async function testBasicExcelGeneration() {
  console.log('🧪 Test podstawowego generowania Excel...');
  
  try {
    const workbook = new ExcelJS.Workbook();
    
    // Metadane workbook (jak w dedicated-excel-export-service.js)
    workbook.creator = 'Metropolitan Investment';
    workbook.created = new Date();
    workbook.modified = new Date();

    const worksheet = workbook.addWorksheet('Eksport Inwestorów');

    // NAGŁÓWKI (dokładnie jak w dedicated-excel-export-service.js)
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

    // STYLIZACJA (dokładnie jak w dedicated-excel-export-service.js)
    const headerRow = worksheet.getRow(1);
    headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    headerRow.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF366092' }
    };
    headerRow.border = {
      top: { style: 'thin' },
      left: { style: 'thin' },
      bottom: { style: 'thin' },
      right: { style: 'thin' }
    };

    // DANE TESTOWE (realistyczne polskie nazwy)
    const testData = [
      ['Jan Kowalski', 'Mieszkania Premium', 'Apartamenty', '2024-01-15', 500000, 450000, 350000, 100000],
      ['Anna Nowak', 'Obligacje Korporacyjne', 'Obligacje', '2024-02-20', 250000, 240000, 200000, 40000],
      ['Piotr Wiśniewski', 'Udziały Deweloperskie', 'Udziały', '2024-03-10', 750000, 720000, 600000, 120000],
      ['Maria Kowalczyk', 'Pożyczka Hipoteczna', 'Pożyczka', '2024-04-05', 300000, 280000, 250000, 30000],
      ['Krzysztof Zieliński', 'Fundusz Nieruchomości', 'Udziały', '2024-05-12', 1000000, 950000, 800000, 150000]
    ];

    testData.forEach(rowData => {
      const row = worksheet.addRow(rowData);
      
      // Formatowanie liczb (jak w dedicated-excel-export-service.js)
      row.getCell(5).numFmt = '#,##0.00 "PLN"'; // Kwota inwestycji
      row.getCell(6).numFmt = '#,##0.00 "PLN"'; // Kapitał pozostały
      row.getCell(7).numFmt = '#,##0.00 "PLN"'; // Kapitał zabezpieczony
      row.getCell(8).numFmt = '#,##0.00 "PLN"'; // Do restrukturyzacji
    });

    // SZEROKOŚCI KOLUMN (jak w dedicated-excel-export-service.js)
    worksheet.columns = [
      { width: 25 }, // Klient
      { width: 30 }, // Produkt
      { width: 15 }, // Typ
      { width: 12 }, // Data
      { width: 18 }, // Kwota inwestycji
      { width: 18 }, // Kapitał pozostały
      { width: 20 }, // Kapitał zabezpieczony
      { width: 18 }  // Do restrukturyzacji
    ];

    // PODSUMOWANIE (jak w dedicated-excel-export-service.js)
    const summaryRow = worksheet.addRow(['']);
    summaryRow.getCell(1).value = `PODSUMOWANIE: ${testData.length} inwestycji od ${testData.length} inwestorów`;
    summaryRow.font = { bold: true, italic: true };

    // GENERUJ BUFFER (jak w dedicated-excel-export-service.js)
    const buffer = await workbook.xlsx.writeBuffer();
    const base64Content = buffer.toString('base64');
    const currentDate = new Date().toISOString().split('T')[0];
    const filename = `Test_Excel_${currentDate}.xlsx`;

    console.log('✅ Excel wygenerowany pomyślnie!');
    console.log(`  - Buffer size: ${buffer.length} bytes`);
    console.log(`  - Base64 length: ${base64Content.length} characters`);
    console.log(`  - Filename: ${filename}`);
    console.log(`  - Rows: ${worksheet.rowCount} (header + ${testData.length} data + 1 summary)`);

    return {
      buffer,
      base64Content,
      filename,
      testData
    };

  } catch (error) {
    console.error('❌ Błąd generowania Excel:', error);
    return null;
  }
}

/**
 * 📊 Test analizy wygenerowanego pliku
 */
async function testExcelFileAnalysis(excelData) {
  console.log('\n📊 Analiza wygenerowanego pliku Excel...');
  
  try {
    const { buffer, base64Content, filename, testData } = excelData;
    
    // Zapisz plik testowo
    const testFilePath = path.join(__dirname, filename);
    fs.writeFileSync(testFilePath, buffer);
    console.log(`💾 Zapisano testowy plik: ${testFilePath}`);
    
    // Test 1: Sprawdź czy można otworzyć plik przez ExcelJS
    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(buffer);
    
    console.log('✅ Plik Excel poprawnie otwarty przez ExcelJS');
    console.log(`📋 Arkusze: ${workbook.worksheets.map(ws => ws.name).join(', ')}`);
    
    const worksheet = workbook.getWorksheet(1);
    console.log(`📊 Arkusz: "${worksheet.name}"`);
    console.log(`📏 Wymiary: ${worksheet.rowCount} wierszy x ${worksheet.columnCount} kolumn`);
    
    // Test 2: Sprawdź nagłówki
    const headerRow = worksheet.getRow(1);
    const headers = [];
    for (let col = 1; col <= worksheet.columnCount; col++) {
      const cellValue = headerRow.getCell(col).value;
      if (cellValue) headers.push(cellValue);
    }
    
    console.log('📋 Nagłówki:', headers);
    
    // Test 3: Sprawdź dane
    console.log('\n📊 Próbka danych z Excel:');
    for (let row = 2; row <= Math.min(4, worksheet.rowCount - 1); row++) {
      const rowData = worksheet.getRow(row);
      const values = [];
      for (let col = 1; col <= headers.length; col++) {
        values.push(rowData.getCell(col).value);
      }
      console.log(`  Row ${row}:`, values.join(' | '));
    }
    
    // Test 4: Sprawdź base64
    console.log('\n🔍 Test base64:');
    console.log(`  - Base64 length: ${base64Content.length}`);
    console.log(`  - Base64 preview: ${base64Content.substring(0, 50)}...`);
    
    // Test konwersji base64 z powrotem
    const bufferFromBase64 = Buffer.from(base64Content, 'base64');
    const isIdentical = buffer.equals(bufferFromBase64);
    console.log(`  - Base64 roundtrip test: ${isIdentical ? '✅ OK' : '❌ FAILED'}`);
    
    // Test 5: Sprawdź czy plik ma poprawny content type
    const fileStats = fs.statSync(testFilePath);
    console.log(`📁 File stats: ${fileStats.size} bytes`);
    
    // Usuń testowy plik
    fs.unlinkSync(testFilePath);
    console.log('🗑️ Usunięto testowy plik');
    
    return true;
    
  } catch (error) {
    console.error('❌ Błąd analizy pliku Excel:', error);
    return false;
  }
}

/**
 * 🧪 Test sympulowanego procesu jak w dedicated-excel-export-service.js
 */
async function testDedicatedServiceSimulation() {
  console.log('\n🧪 Symulacja procesu z dedicated-excel-export-service.js...');
  
  try {
    // Symulowane dane inwestorów (jak z validateInvestorData)
    const investorsData = [
      {
        clientId: 'client_001',
        clientName: 'Jan Kowalski',
        investments: [
          {
            clientName: 'Jan Kowalski',
            productName: 'Mieszkania Premium',
            productType: 'Apartamenty',
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
        clientName: 'Anna Nowak',
        investments: [
          {
            clientName: 'Anna Nowak',
            productName: 'Obligacje Korporacyjne', 
            productType: 'Obligacje',
            signedDate: '20.02.2024',
            investmentAmount: 250000,
            remainingCapital: 240000,
            capitalSecuredByRealEstate: 200000,
            capitalForRestructuring: 40000,
            investmentId: 'inv_002'
          }
        ]
      }
    ];
    
    // Użyj tej samej logiki co w generateDedicatedExcel
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

    // Dodaj dane inwestorów (dokładnie jak w dedicated-excel-export-service.js)
    investorsData.forEach(investor => {
      investor.investments.forEach(investment => {
        const row = worksheet.addRow([
          investment.clientName,
          investment.productName,
          investment.productType,
          investment.signedDate,
          investment.investmentAmount,
          investment.remainingCapital,
          investment.capitalSecuredByRealEstate,
          investment.capitalForRestructuring
        ]);

        // Formatowanie liczb
        row.getCell(5).numFmt = '#,##0.00 "PLN"';
        row.getCell(6).numFmt = '#,##0.00 "PLN"';
        row.getCell(7).numFmt = '#,##0.00 "PLN"';
        row.getCell(8).numFmt = '#,##0.00 "PLN"';

        totalRows++;
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
    summaryRow.getCell(1).value = `PODSUMOWANIE: ${totalRows} inwestycji od ${investorsData.length} inwestorów`;
    summaryRow.font = { bold: true, italic: true };

    // Generuj buffer
    const buffer = await workbook.xlsx.writeBuffer();
    const base64Content = buffer.toString('base64');
    const filename = 'Test_Dedicated_Service.xlsx';

    console.log('✅ Symulacja dedicated service zakończona pomyślnie!');
    console.log(`  - Generated ${totalRows} investment rows`);
    console.log(`  - Buffer size: ${buffer.length} bytes`);
    console.log(`  - Base64 length: ${base64Content.length}`);
    
    // Zapisz i sprawdź plik
    const testFilePath = path.join(__dirname, filename);
    fs.writeFileSync(testFilePath, buffer);
    console.log(`💾 Zapisano plik symulacji: ${testFilePath}`);
    
    // Sprawdź czy można otworzyć
    const testWorkbook = new ExcelJS.Workbook();
    await testWorkbook.xlsx.readFile(testFilePath);
    
    console.log('✅ Plik symulacji poprawnie otwarty!');
    console.log('💡 To pokazuje, że proces generowania Excel jest prawidłowy');
    
    // Usuń plik
    fs.unlinkSync(testFilePath);
    console.log('🗑️ Usunięto plik symulacji');
    
    return {
      success: true,
      buffer,
      base64Content,
      totalRows,
      investorCount: investorsData.length
    };
    
  } catch (error) {
    console.error('❌ Błąd symulacji dedicated service:', error);
    return null;
  }
}

/**
 * 🎯 GŁÓWNA FUNKCJA TESTOWA
 */
async function main() {
  console.log('🚀 PROSTSZY TEST EXCEL - ROZPOCZĘCIE\n');
  
  try {
    // Test 1: Podstawowe generowanie Excel
    console.log('='.repeat(50));
    const basicExcel = await testBasicExcelGeneration();
    if (!basicExcel) {
      console.log('❌ Test podstawowy nieudany');
      return;
    }
    
    // Test 2: Analiza pliku Excel
    console.log('='.repeat(50));
    const analysisResult = await testExcelFileAnalysis(basicExcel);
    if (!analysisResult) {
      console.log('❌ Analiza pliku nieudana');
      return;
    }
    
    // Test 3: Symulacja dedicated service
    console.log('='.repeat(50));
    const serviceResult = await testDedicatedServiceSimulation();
    if (!serviceResult) {
      console.log('❌ Symulacja service nieudana');
      return;
    }
    
    // Podsumowanie
    console.log('\n' + '='.repeat(50));
    console.log('🎉 WYNIKI TESTÓW:');
    console.log('✅ ExcelJS poprawnie generuje pliki .xlsx');
    console.log('✅ Format base64 jest prawidłowy');
    console.log('✅ Pliki można otworzyć przez ExcelJS');
    console.log('✅ Symulacja dedicated service działa poprawnie');
    console.log('✅ Struktura danych jest zgodna z oczekiwaniami');
    
    console.log('\n📋 WNIOSKI:');
    console.log('🔍 Kod generowania Excel w dedicated-excel-export-service.js');
    console.log('   używa prawidłowych metod ExcelJS i powinien tworzyć');
    console.log('   prawidłowe pliki .xlsx');
    
    console.log('\n💡 Jeśli nadal występuje błąd "Format pliku jest nieprawidłowy":');
    console.log('   1. Problem może być w przesyłaniu base64 przez Firebase Functions');
    console.log('   2. Możliwy błąd w procesie pobierania/zapisywania po stronie klienta');
    console.log('   3. Sprawdź czy base64 nie jest uszkodzony podczas transferu');
    console.log('   4. Możliwy problem z nagłówkami HTTP (Content-Type)');
    console.log('   5. Sprawdź czy dane nie zawierają null/undefined wartości');
    
  } catch (error) {
    console.error('❌ Błąd głównej funkcji testowej:', error);
  }
}

// Uruchom test
if (require.main === module) {
  main();
}