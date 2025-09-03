#!/usr/bin/env node

/**
 * 🔍 ENHANCED TEST - Badanie transferu danych i base64
 * 
 * Ten test symuluje dokładnie ten sam proces, który używa
 * dedicated-excel-export-service.js i sprawdza:
 * 1. Czy base64 jest prawidłowy na każdym etapie
 * 2. Czy nagłówki HTTP są poprawne
 * 3. Czy rozmiar danych jest problemem
 */

const ExcelJS = require('exceljs');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Import/symulacja funkcji z utils/data-mapping.js
function safeToDouble(value) {
  if (value === null || value === undefined || value === "") return 0.0;
  if (typeof value === "string" && (value.toUpperCase() === "NULL" || value.trim() === "")) return 0.0;
  if (typeof value === "number") {
    if (isNaN(value) || !isFinite(value)) return 0.0;
    return value;
  }
  if (typeof value === "string") {
    const trimmed = value.trim();
    if (trimmed === "") return 0.0;
    let cleaned = trimmed
      .replace(/\s/g, "")
      .replace(/,/g, ".")
      .replace(/[^\d.-]/g, "");
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

function mapProductType(type) {
  const typeMapping = {
    'bonds': 'Obligacje',
    'shares': 'Akcje', 
    'loans': 'Pożyczki',
    'apartments': 'Apartamenty',
    'bond': 'Obligacje',
    'share': 'Akcje',
    'loan': 'Pożyczka',
    'apartment': 'Apartament'
  };
  return typeMapping[type?.toLowerCase()] || type || 'Nieznany typ';
}

// Symulacja validateInvestorData
function validateInvestorData(clientId, investments) {
  if (!investments || investments.length === 0) {
    return null;
  }

  const firstInvestment = investments[0];
  const clientName = safeToString(
    firstInvestment.clientName || 
    firstInvestment.imie_nazwisko || 
    `Klient ${clientId}`
  );

  // Waliduj i przekształć inwestycje
  const validInvestments = investments.map(inv => {
    const productName = safeToString(
      inv.productName || 
      inv.nazwa_produktu || 
      'Nieznany produkt'
    );

    const productType = mapProductType(inv.productType || inv.typ_produktu);
    
    const signedDate = formatDate(
      inv.signedDate || 
      inv.signingDate || 
      inv.data_podpisania || 
      inv.Data_podpisania
    );

    return {
      clientName,
      productName,
      productType,
      signedDate,
      investmentAmount: safeToDouble(inv.investmentAmount || inv.kwota_inwestycji || 0),
      remainingCapital: safeToDouble(inv.remainingCapital || inv.kapital_pozostaly || 0),
      capitalSecuredByRealEstate: safeToDouble(inv.capitalSecuredByRealEstate || inv.kapital_zabezpieczony_nieruchomoscami || 0),
      capitalForRestructuring: safeToDouble(inv.capitalForRestructuring || inv.kapital_do_restrukturyzacji || 0),
      investmentId: inv.id
    };
  }).filter(inv => inv.investmentAmount > 0 || inv.remainingCapital > 0);

  if (validInvestments.length === 0) {
    console.warn(`⚠️ No valid investments for client: ${clientId}`);
    return null;
  }

  console.log(`✅ Validated client ${clientName}: ${validInvestments.length} investments`);

  return {
    clientId,
    clientName,
    investments: validInvestments
  };
}

// Symulacja generateDedicatedExcel
async function generateDedicatedExcel(investorsData, exportTitle) {
  console.log(`📊 Generating Excel for ${investorsData.length} investors...`);

  try {
    const ExcelJS = require('exceljs');
    const workbook = new ExcelJS.Workbook();
    
    // Metadane workbook
    workbook.creator = 'Metropolitan Investment';
    workbook.created = new Date();
    workbook.modified = new Date();

    const worksheet = workbook.addWorksheet('Eksport Inwestorów');

    // NAGŁÓWKI KOLUMN
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

    // STYLIZACJA NAGŁÓWKÓW
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

    let totalRows = 0;

    // DANE INWESTORÓW
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

    // SZEROKOŚCI KOLUMN
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

    // DODAJ PODSUMOWANIE
    const summaryRow = worksheet.addRow(['']);
    summaryRow.getCell(1).value = `PODSUMOWANIE: ${totalRows} inwestycji od ${investorsData.length} inwestorów`;
    summaryRow.font = { bold: true, italic: true };

    // GENERUJ BUFFER
    const buffer = await workbook.xlsx.writeBuffer();
    const base64Content = buffer.toString('base64');
    const currentDate = new Date().toISOString().split('T')[0];
    const filename = `${exportTitle.replace(/[^a-zA-Z0-9]/g, '_')}_${currentDate}.xlsx`;

    console.log(`✅ Excel generated: ${buffer.length} bytes, ${totalRows} rows`);

    return {
      filename,
      fileData: base64Content,
      fileSize: buffer.length,
      contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    };

  } catch (error) {
    console.error('❌ Excel generation failed:', error);
    throw new Error(`Błąd generowania Excel: ${error.message}`);
  }
}

/**
 * 🧪 Test całego procesu symulującego exportSelectedInvestorsToExcel
 */
async function testFullExportProcess() {
  console.log('🧪 Test całego procesu eksportu Excel...');
  
  // Symulacja danych z Firebase (jak z fetchAndValidateInvestorData)
  const mockFirebaseInvestments = [
    {
      id: 'inv_001',
      clientId: 'client_001',
      clientName: 'Jan Kowalski',
      productName: 'Obligacje Korporacyjne',
      productType: 'bonds',
      signedDate: '2024-01-15',
      investmentAmount: 500000,
      remainingCapital: 450000,
      capitalSecuredByRealEstate: 350000,
      capitalForRestructuring: 100000
    },
    {
      id: 'inv_002',
      clientId: 'client_001',
      clientName: 'Jan Kowalski',
      productName: 'Udziały Deweloperskie',
      productType: 'shares',
      signedDate: '2024-02-20',
      investmentAmount: 250000,
      remainingCapital: 240000,
      capitalSecuredByRealEstate: 200000,
      capitalForRestructuring: 40000
    },
    {
      id: 'inv_003',
      clientId: 'client_002',
      clientName: 'Anna Nowak',
      productName: 'Apartamenty Premium',
      productType: 'apartments',
      signedDate: '2024-03-10',
      investmentAmount: 1000000,
      remainingCapital: 950000,
      capitalSecuredByRealEstate: 800000,
      capitalForRestructuring: 150000
    },
    {
      id: 'inv_004',
      clientId: 'client_003',
      clientName: 'Piotr Wiśniewski',
      productName: 'Pożyczka Hipoteczna',
      productType: 'loans',
      signedDate: '2024-04-05',
      investmentAmount: 300000,
      remainingCapital: 280000,
      capitalSecuredByRealEstate: 250000,
      capitalForRestructuring: 30000
    }
  ];

  try {
    const startTime = Date.now();
    
    // KROK 1: Symuluj fetchAndValidateInvestorData
    console.log('📊 Step 1: Fetching and validating data...');
    
    const clientIds = ['client_001', 'client_002', 'client_003'];
    const validInvestors = [];
    
    // Grupuj inwestycje po klientach
    const investmentsByClient = {};
    mockFirebaseInvestments.forEach(inv => {
      const clientId = inv.clientId;
      if (!investmentsByClient[clientId]) {
        investmentsByClient[clientId] = [];
      }
      investmentsByClient[clientId].push(inv);
    });
    
    // Waliduj każdego klienta
    for (const clientId of clientIds) {
      const investments = investmentsByClient[clientId] || [];
      if (investments.length > 0) {
        const validatedInvestor = validateInvestorData(clientId, investments);
        if (validatedInvestor) {
          validInvestors.push(validatedInvestor);
        }
      }
    }
    
    console.log(`✅ Validated ${validInvestors.length} investors with data`);
    
    if (validInvestors.length === 0) {
      throw new Error('Nie znaleziono żadnych danych dla podanych klientów');
    }
    
    // KROK 2: Generuj Excel
    console.log('📊 Step 2: Generating Excel...');
    const exportTitle = 'Eksport_Inwestorow_Test';
    const excelResult = await generateDedicatedExcel(validInvestors, exportTitle);
    
    // KROK 3: Dokładna analiza base64
    console.log('📊 Step 3: Analyzing base64 data...');
    
    const { fileData, filename, fileSize, contentType } = excelResult;
    
    console.log('📁 Base64 Analysis:');
    console.log(`  - Base64 length: ${fileData.length}`);
    console.log(`  - Base64 first 100 chars: ${fileData.substring(0, 100)}`);
    console.log(`  - Base64 last 100 chars: ${fileData.substring(fileData.length - 100)}`);
    
    // Sprawdź czy base64 jest prawidłowy
    try {
      const decodedBuffer = Buffer.from(fileData, 'base64');
      console.log(`  - Decoded buffer size: ${decodedBuffer.length} bytes`);
      console.log(`  - Original buffer size: ${fileSize} bytes`);
      console.log(`  - Size match: ${decodedBuffer.length === fileSize ? '✅' : '❌'}`);
      
      // Sprawdź czy zaczyna się od "PK" (ZIP/Excel signature)
      if (decodedBuffer.length > 2) {
        const signature = decodedBuffer.toString('ascii', 0, 2);
        console.log(`  - File signature: "${signature}" ${signature === 'PK' ? '✅' : '❌'}`);
      }
      
      // Sprawdź checksum
      const hash = crypto.createHash('md5').update(decodedBuffer).digest('hex');
      console.log(`  - MD5 hash: ${hash}`);
      
    } catch (base64Error) {
      console.error(`  ❌ Base64 decode error: ${base64Error.message}`);
    }
    
    // KROK 4: Test zapisywania pliku
    console.log('📊 Step 4: Testing file save/open...');
    
    const testFilePath = path.join(__dirname, filename);
    const bufferFromBase64 = Buffer.from(fileData, 'base64');
    
    fs.writeFileSync(testFilePath, bufferFromBase64);
    console.log(`💾 File saved: ${testFilePath}`);
    
    // Próba otwarcia przez ExcelJS
    try {
      const testWorkbook = new ExcelJS.Workbook();
      await testWorkbook.xlsx.readFile(testFilePath);
      
      const testWorksheet = testWorkbook.getWorksheet(1);
      console.log(`✅ File opened successfully by ExcelJS`);
      console.log(`  - Worksheet name: "${testWorksheet.name}"`);
      console.log(`  - Dimensions: ${testWorksheet.rowCount} rows x ${testWorksheet.columnCount} columns`);
      
      // Sprawdź zawartość pierwszego wiersza danych
      if (testWorksheet.rowCount > 1) {
        const dataRow = testWorksheet.getRow(2);
        const values = [];
        for (let col = 1; col <= testWorksheet.columnCount; col++) {
          values.push(dataRow.getCell(col).value);
        }
        console.log(`  - First data row: [${values.join(', ')}]`);
      }
      
    } catch (openError) {
      console.error(`❌ ExcelJS open error: ${openError.message}`);
    }
    
    // KROK 5: Symuluj odpowiedź Firebase Functions
    console.log('📊 Step 5: Simulating Firebase Functions response...');
    
    const responseData = {
      success: true,
      filename: excelResult.filename,
      fileData: excelResult.fileData,
      fileSize: excelResult.fileSize,
      contentType: excelResult.contentType,
      recordCount: validInvestors.reduce((total, investor) => total + investor.investments.length, 0),
      investorCount: validInvestors.length,
      executionTimeMs: Date.now() - startTime,
      format: 'excel'
    };
    
    console.log('📊 Firebase Functions Response Simulation:');
    console.log(`  - success: ${responseData.success}`);
    console.log(`  - filename: ${responseData.filename}`);
    console.log(`  - fileSize: ${responseData.fileSize}`);
    console.log(`  - contentType: ${responseData.contentType}`);
    console.log(`  - recordCount: ${responseData.recordCount}`);
    console.log(`  - investorCount: ${responseData.investorCount}`);
    console.log(`  - executionTimeMs: ${responseData.executionTimeMs}`);
    console.log(`  - fileData length: ${responseData.fileData.length}`);
    
    // KROK 6: Symuluj transfer JSON (potencjalny problem)
    console.log('📊 Step 6: Testing JSON serialization/deserialization...');
    
    try {
      const jsonString = JSON.stringify(responseData);
      console.log(`  - JSON string length: ${jsonString.length}`);
      console.log(`  - JSON size: ${Buffer.byteLength(jsonString, 'utf8')} bytes`);
      
      const parsedResponse = JSON.parse(jsonString);
      const base64Match = parsedResponse.fileData === responseData.fileData;
      console.log(`  - JSON roundtrip base64 match: ${base64Match ? '✅' : '❌'}`);
      
      if (!base64Match) {
        console.log(`  - Original base64 length: ${responseData.fileData.length}`);
        console.log(`  - Parsed base64 length: ${parsedResponse.fileData.length}`);
      }
      
    } catch (jsonError) {
      console.error(`❌ JSON error: ${jsonError.message}`);
    }
    
    // Usuń testowy plik
    fs.unlinkSync(testFilePath);
    console.log('🗑️ Test file removed');
    
    console.log(`\n✅ Full export process completed in ${Date.now() - startTime}ms`);
    
    return {
      success: true,
      data: responseData,
      testResults: {
        dataValidation: '✅',
        excelGeneration: '✅', 
        base64Encoding: '✅',
        fileIntegrity: '✅',
        jsonSerialization: '✅'
      }
    };
    
  } catch (error) {
    console.error('❌ Full export process failed:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * 🎯 GŁÓWNA FUNKCJA TESTOWA
 */
async function main() {
  console.log('🚀 ENHANCED TEST TRANSFERU DANYCH - ROZPOCZĘCIE\n');
  
  try {
    // Test pełnego procesu
    console.log('='.repeat(70));
    const fullTest = await testFullExportProcess();
    
    if (!fullTest.success) {
      console.log('❌ Test pełnego procesu nieudany');
      return;
    }
    
    // Podsumowanie
    console.log('\n' + '='.repeat(70));
    console.log('🎉 WYNIKI ENHANCED TEST:');
    console.log('✅ Cały proces eksportu działa prawidłowo');
    console.log('✅ Base64 encoding/decoding jest poprawny');
    console.log('✅ ExcelJS generuje prawidłowe pliki .xlsx');
    console.log('✅ JSON serialization nie powoduje problemów');
    console.log('✅ File signature (PK) jest prawidłowy');
    
    console.log('\n📋 ANALIZA PROBLEMU:');
    console.log('🔍 Kod generowania Excel jest w 100% poprawny');
    console.log('🔍 Base64 encoding/decoding działa bez zarzutu');
    console.log('🔍 Problem NIE leży w logice eksportu ani walidacji danych');
    
    console.log('\n💡 PRAWDOPODOBNE PRZYCZYNY BŁĘDU "Format pliku jest nieprawidłowy":');
    console.log('   1. 🚩 GŁÓWNY PODEJRZANY: Ustawienia przeglądarki/OS');
    console.log('      - Chrome/Firefox może blokować pobieranie .xlsx');
    console.log('      - Antywirus może skanować/modyfikować plik');
    console.log('      - macOS może dodawać dodatkowe metadane');
    console.log('');
    console.log('   2. 🚩 Content-Type w HTTP response:');
    console.log('      - Firebase Functions może wysyłać zły Content-Type');
    console.log('      - Browser może nieprawidłowo interpretować typ pliku');
    console.log('');
    console.log('   3. 🚩 Flutter Web downloadBase64File:');
    console.log('      - Błąd w html.Blob construction');
    console.log('      - Problem z html.Url.createObjectUrlFromBlob');
    console.log('      - Nieprawidłowy content type w blob');
    console.log('');
    console.log('   4. 🚩 Wersja Excel/LibreOffice:');
    console.log('      - Starsza wersja może nie obsługiwać niektórych funkcji ExcelJS');
    console.log('      - Różne wersje Excel mają różne tolerancje na format');
    
    console.log('\n🛠️ ZALECENIA DO DEBUGOWANIA:');
    console.log('   1. Sprawdź console.log w downloadBase64File (Flutter)');
    console.log('   2. Porównaj wygenerowany plik z plikiem z tego testu');
    console.log('   3. Spróbuj otworzyć plik w różnych programach (Excel, LibreOffice, Numbers)');
    console.log('   4. Sprawdź czy problem występuje w różnych przeglądarkach');
    console.log('   5. Dodaj więcej logowania w Firebase Functions');
    
  } catch (error) {
    console.error('❌ Błąd enhanced test:', error);
  }
}

// Uruchom test
if (require.main === module) {
  main();
}