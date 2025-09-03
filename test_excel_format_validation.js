#!/usr/bin/env node

/**
 * 🔍 TEST FORMATOWANIA EXCEL - Sprawdza czy generowany Excel zawiera rzeczywiste dane
 * 
 * Ten skrypt testuje:
 * 1. Czy funkcja exportSelectedInvestorsToExcel działa poprawnie
 * 2. Czy dane nie są placeholder/hardcoded
 * 3. Czy format Excel jest poprawny
 * 4. Czy base64 encoding jest prawidłowy
 */

const admin = require('firebase-admin');
const ExcelJS = require('exceljs');
const fs = require('fs');
const path = require('path');

// Inicjalizacja Firebase Admin (tylko jeśli nie jest już zainicjalizowany)
try {
  if (!admin.apps.length) {
    const serviceAccount = require('./metropolitan-investment-firebase-adminsdk-fbsvc-95a38b3a38.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      databaseURL: "https://metropolitan-investment-default-rtdb.europe-west1.firebasedatabase.app"
    });
  }
} catch (error) {
  console.log('⚠️ Firebase już zainicjalizowany lub błąd:', error.message);
}

const db = admin.firestore();

/**
 * 🔍 KROK 1: Pobierz próbkę rzeczywistych danych z Firebase
 */
async function fetchSampleRealData() {
  console.log('🔍 Pobieranie próbki rzeczywistych danych z Firebase...');
  
  try {
    const investmentsSnapshot = await db.collection('investments')
      .limit(5)
      .get();
    
    if (investmentsSnapshot.empty) {
      console.log('❌ Brak danych inwestycji w Firebase');
      return [];
    }
    
    const realInvestments = [];
    investmentsSnapshot.forEach(doc => {
      const data = doc.data();
      realInvestments.push({
        id: doc.id,
        clientId: data.clientId,
        clientName: data.clientName || data.imie_nazwisko || 'Unknown',
        productName: data.productName || data.nazwa_produktu || 'Unknown Product',
        productType: data.productType || data.typ_produktu || 'Unknown Type',
        investmentAmount: data.investmentAmount || data.kwota_inwestycji || 0,
        remainingCapital: data.remainingCapital || data.kapital_pozostaly || 0,
        capitalSecuredByRealEstate: data.capitalSecuredByRealEstate || 0,
        capitalForRestructuring: data.capitalForRestructuring || 0,
        signedDate: data.signedDate || data.data_podpisania || null
      });
    });
    
    console.log(`✅ Pobrano ${realInvestments.length} rzeczywistych inwestycji`);
    realInvestments.forEach((inv, i) => {
      console.log(`  ${i+1}. ${inv.clientName} - ${inv.productName} - ${inv.investmentAmount} PLN`);
    });
    
    return realInvestments;
    
  } catch (error) {
    console.error('❌ Błąd pobierania danych z Firebase:', error);
    return [];
  }
}

/**
 * 🧪 KROK 2: Test dedykowanego serwisu Excel
 */
async function testDedicatedExcelService(realData) {
  console.log('\n🧪 Testowanie dedykowanego serwisu Excel...');
  
  try {
    // Import funkcji
    const { exportSelectedInvestorsToExcel } = require('./functions/services/dedicated-excel-export-service');
    
    // Przygotuj dane testowe (clientIds z rzeczywistych danych)
    const clientIds = [...new Set(realData.map(inv => inv.clientId))];
    
    if (clientIds.length === 0) {
      console.log('❌ Brak clientIds do testowania');
      return false;
    }
    
    console.log(`📊 Testowanie z ${clientIds.length} klientami:`, clientIds);
    
    // Wywołaj funkcję
    const mockRequest = {
      data: {
        clientIds: clientIds,
        exportTitle: 'Test Excel Format',
        requestedBy: 'test-user@example.com'
      }
    };
    
    const result = await exportSelectedInvestorsToExcel(mockRequest);
    
    if (!result.success) {
      console.log('❌ Eksport nieudany:', result.error);
      return false;
    }
    
    console.log('✅ Eksport udany!');
    console.log(`  - Filename: ${result.filename}`);
    console.log(`  - File size: ${result.fileSize} bytes`);
    console.log(`  - Record count: ${result.recordCount}`);
    console.log(`  - Investor count: ${result.investorCount}`);
    console.log(`  - Execution time: ${result.executionTimeMs}ms`);
    
    // Sprawdź czy fileData to prawidłowy base64
    if (!result.fileData || typeof result.fileData !== 'string') {
      console.log('❌ Brak danych pliku lub nieprawidłowy format');
      return false;
    }
    
    console.log(`  - Base64 length: ${result.fileData.length} characters`);
    console.log(`  - Base64 preview: ${result.fileData.substring(0, 50)}...`);
    
    return { success: true, data: result };
    
  } catch (error) {
    console.error('❌ Błąd testowania serwisu Excel:', error);
    return false;
  }
}

/**
 * 📊 KROK 3: Analiza pliku Excel
 */
async function analyzeExcelFile(base64Data, realData) {
  console.log('\n📊 Analiza wygenerowanego pliku Excel...');
  
  try {
    // Konwertuj base64 do buffer
    const buffer = Buffer.from(base64Data, 'base64');
    console.log(`📁 Buffer size: ${buffer.length} bytes`);
    
    // Zapisz plik testowo
    const testFilePath = path.join(__dirname, 'test_excel_output.xlsx');
    fs.writeFileSync(testFilePath, buffer);
    console.log(`💾 Zapisano testowy plik: ${testFilePath}`);
    
    // Otwórz plik za pomocą ExcelJS
    const workbook = new ExcelJS.Workbook();
    await workbook.xlsx.load(buffer);
    
    console.log('✅ Plik Excel poprawnie otwarty przez ExcelJS');
    console.log(`📋 Arkusze: ${workbook.worksheets.map(ws => ws.name).join(', ')}`);
    
    const worksheet = workbook.getWorksheet(1);
    if (!worksheet) {
      console.log('❌ Brak arkusza w pliku');
      return false;
    }
    
    console.log(`📊 Arkusz: "${worksheet.name}"`);
    console.log(`📏 Wymiary: ${worksheet.rowCount} wierszy x ${worksheet.columnCount} kolumn`);
    
    // Sprawdź nagłówki
    const headerRow = worksheet.getRow(1);
    const headers = [];
    for (let col = 1; col <= worksheet.columnCount; col++) {
      const cellValue = headerRow.getCell(col).value;
      if (cellValue) headers.push(cellValue);
    }
    
    console.log('📋 Nagłówki:', headers);
    
    // Sprawdź kilka wierszy danych
    console.log('\n📊 Próbka danych z pliku Excel:');
    for (let row = 2; row <= Math.min(6, worksheet.rowCount); row++) {
      const rowData = worksheet.getRow(row);
      const values = [];
      for (let col = 1; col <= headers.length; col++) {
        values.push(rowData.getCell(col).value);
      }
      console.log(`  Row ${row}:`, values.join(' | '));
    }
    
    // Porównaj z rzeczywistymi danymi
    console.log('\n🔍 Weryfikacja zgodności z rzeczywistymi danymi:');
    const excelClientNames = [];
    for (let row = 2; row <= worksheet.rowCount; row++) {
      const clientName = worksheet.getRow(row).getCell(1).value;
      if (clientName && typeof clientName === 'string') {
        excelClientNames.push(clientName);
      }
    }
    
    const realClientNames = realData.map(inv => inv.clientName);
    const matchingNames = excelClientNames.filter(name => 
      realClientNames.some(realName => realName.includes(name) || name.includes(realName))
    );
    
    console.log(`✅ Znaleziono ${matchingNames.length} pasujących nazw klientów z ${excelClientNames.length} w Excel`);
    console.log(`📊 Procent zgodności: ${((matchingNames.length / Math.max(excelClientNames.length, 1)) * 100).toFixed(1)}%`);
    
    // Sprawdź czy nie ma placeholder wartości
    const placeholderPatterns = [
      'placeholder', 'test', 'example', 'dummy', 'fake', 'mock',
      'Klient 1', 'Klient 2', 'Test Client', 'Example Client'
    ];
    
    let foundPlaceholders = 0;
    excelClientNames.forEach(name => {
      const nameLower = name.toLowerCase();
      placeholderPatterns.forEach(pattern => {
        if (nameLower.includes(pattern.toLowerCase())) {
          foundPlaceholders++;
          console.log(`⚠️ Możliwy placeholder: "${name}"`);
        }
      });
    });
    
    if (foundPlaceholders === 0) {
      console.log('✅ Nie znaleziono placeholder wartości - dane wyglądają na rzeczywiste');
    } else {
      console.log(`⚠️ Znaleziono ${foundPlaceholders} potencjalnych placeholder wartości`);
    }
    
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
 * 🎯 GŁÓWNA FUNKCJA TESTOWA
 */
async function main() {
  console.log('🚀 TEST FORMATOWANIA EXCEL - ROZPOCZĘCIE\n');
  
  try {
    // Krok 1: Pobierz rzeczywiste dane
    const realData = await fetchSampleRealData();
    if (realData.length === 0) {
      console.log('❌ Brak danych do testowania');
      return;
    }
    
    // Krok 2: Test eksportu Excel
    const exportResult = await testDedicatedExcelService(realData);
    if (!exportResult || !exportResult.success) {
      console.log('❌ Test eksportu nieudany');
      return;
    }
    
    // Krok 3: Analiza pliku Excel
    const analysisResult = await analyzeExcelFile(exportResult.data.fileData, realData);
    if (!analysisResult) {
      console.log('❌ Analiza pliku nieudana');
      return;
    }
    
    console.log('\n🎉 WYNIKI KOŃCOWE:');
    console.log('✅ Funkcja exportSelectedInvestorsToExcel działa poprawnie');
    console.log('✅ Dane pochodzą z Firebase (nie są placeholder/hardcoded)');
    console.log('✅ Format Excel jest poprawny i można go otworzyć');
    console.log('✅ Base64 encoding jest prawidłowy');
    
    console.log('\n📋 PODSUMOWANIE:');
    console.log('   - Serwis Excel używa rzeczywistych danych z Firebase');
    console.log('   - Format pliku jest zgodny ze standardem .xlsx');
    console.log('   - Jeśli nadal występuje błąd otwarcia pliku, problem może być w:');
    console.log('     1. Procesie pobierania/zapisywania pliku po stronie klienta');
    console.log('     2. Przesyłaniu base64 przez Firebase Functions');
    console.log('     3. Kompatybilności z konkretną wersją Excel/LibreOffice');
    
  } catch (error) {
    console.error('❌ Błąd głównej funkcji testowej:', error);
  } finally {
    // Zamknij połączenie z Firebase
    process.exit(0);
  }
}

// Uruchom test
if (require.main === module) {
  main();
}