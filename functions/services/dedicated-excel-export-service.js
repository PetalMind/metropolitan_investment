/**
 * Dedykowany serwis eksportu Excel dla inwestorów
 * 
 * Rozwiązuje problemy z formatem plików Excel poprzez:
 * - Walidację danych przed eksportem
 * - Uproszczoną ścieżkę generowania Excel
 * - Lepsze logowanie i diagnostykę
 * - Fallback dla brakujących danych
 */

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const { db } = require("../utils/firebase-config");
const { safeToDouble, safeToString } = require("../utils/data-mapping");

/**
 * Dedykowany eksport Excel z zaznaczonych inwestorów
 */
const exportSelectedInvestorsToExcel = onCall({ 
  memory: '2GiB', 
  timeoutSeconds: 300 
}, async (request) => {
  const startTime = Date.now();
  const { clientIds, requestedBy, exportTitle = 'Eksport Inwestorów' } = request.data || {};

  console.log(`🚀 [DedicatedExcelExport] Starting export for ${clientIds?.length || 0} clients`);

  // WALIDACJA
  if (!clientIds || !Array.isArray(clientIds) || clientIds.length === 0) {
    throw new HttpsError('invalid-argument', 'clientIds jest wymagane (niepusta tablica)');
  }

  if (!requestedBy) {
    throw new HttpsError('invalid-argument', 'requestedBy jest wymagane');
  }

  if (clientIds.length > 500) {
    throw new HttpsError('invalid-argument', 'Maksymalnie 500 klientów na eksport');
  }

  try {
    // KROK 1: Pobierz i waliduj dane
    const validatedData = await fetchAndValidateInvestorData(clientIds);
    
    if (validatedData.length === 0) {
      throw new HttpsError('not-found', 'Nie znaleziono żadnych danych dla podanych klientów');
    }

    console.log(`✅ [DedicatedExcelExport] Validated ${validatedData.length} investors with data`);

    // KROK 2: Generuj Excel
    const excelResult = await generateDedicatedExcel(validatedData, exportTitle);

    // KROK 3: Zapisz historię
    await saveExportHistory({
      requestedBy,
      exportFormat: 'excel',
      clientCount: validatedData.length,
      exportTitle,
      executionTimeMs: Date.now() - startTime,
      status: 'success'
    });

    console.log(`🎉 [DedicatedExcelExport] Export completed in ${Date.now() - startTime}ms`);

    return {
      success: true,
      filename: excelResult.filename,
      fileData: excelResult.fileData,
      fileSize: excelResult.fileSize,
      contentType: excelResult.contentType,
      recordCount: validatedData.reduce((total, investor) => total + investor.investments.length, 0),
      investorCount: validatedData.length,
      executionTimeMs: Date.now() - startTime,
      format: 'excel'
    };

  } catch (error) {
    console.error('❌ [DedicatedExcelExport] Export failed:', error);
    
    await saveExportHistory({
      requestedBy,
      exportFormat: 'excel',
      clientCount: clientIds.length,
      exportTitle,
      executionTimeMs: Date.now() - startTime,
      status: 'failed',
      error: error.message
    });

    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', `Błąd eksportu Excel: ${error.message}`);
  }
});

/**
 * Pobiera i waliduje dane inwestorów
 */
async function fetchAndValidateInvestorData(clientIds) {
  const validInvestors = [];
  const batchSize = 10;

  console.log(`🔍 [DedicatedExcelExport] Fetching data for ${clientIds.length} clients...`);

  // Przetwarzaj w batch'ach
  for (let i = 0; i < clientIds.length; i += batchSize) {
    const batch = clientIds.slice(i, i + batchSize);
    
    try {
      const investmentsSnapshot = await db.collection('investments')
        .where('clientId', 'in', batch)
        .get();

      console.log(`📊 [DedicatedExcelExport] Batch ${i/batchSize + 1}: Found ${investmentsSnapshot.docs.length} investments for ${batch.length} clients`);

      // Grupuj inwestycje po klientach
      const investmentsByClient = {};
      investmentsSnapshot.docs.forEach(doc => {
        const investment = { id: doc.id, ...doc.data() };
        const clientId = investment.clientId;

        if (!investmentsByClient[clientId]) {
          investmentsByClient[clientId] = [];
        }
        investmentsByClient[clientId].push(investment);
      });

      // Waliduj i dodaj każdego klienta
      for (const clientId of batch) {
        const investments = investmentsByClient[clientId] || [];
        
        if (investments.length > 0) {
          const validatedInvestor = validateInvestorData(clientId, investments);
          if (validatedInvestor) {
            validInvestors.push(validatedInvestor);
          }
        } else {
          console.warn(`⚠️ [DedicatedExcelExport] No investments found for client: ${clientId}`);
        }
      }

    } catch (batchError) {
      console.error(`❌ [DedicatedExcelExport] Batch error:`, batchError);
    }
  }

  return validInvestors;
}

/**
 * Waliduje dane pojedynczego inwestora
 */
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
  }).filter(inv => inv.investmentAmount > 0 || inv.remainingCapital > 0); // Tylko inwestycje z kwotami

  if (validInvestments.length === 0) {
    console.warn(`⚠️ [DedicatedExcelExport] No valid investments for client: ${clientId}`);
    return null;
  }

  console.log(`✅ [DedicatedExcelExport] Validated client ${clientName}: ${validInvestments.length} investments`);

  return {
    clientId,
    clientName,
    investments: validInvestments
  };
}

/**
 * Generuje dedykowany plik Excel
 */
async function generateDedicatedExcel(investorsData, exportTitle) {
  console.log(`📊 [DedicatedExcelExport] Generating Excel for ${investorsData.length} investors...`);

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
        row.getCell(5).numFmt = '#,##0.00 "PLN"'; // Kwota inwestycji
        row.getCell(6).numFmt = '#,##0.00 "PLN"'; // Kapitał pozostały
        row.getCell(7).numFmt = '#,##0.00 "PLN"'; // Kapitał zabezpieczony
        row.getCell(8).numFmt = '#,##0.00 "PLN"'; // Do restrukturyzacji

        totalRows++;
      });
    });

    // SZEROKOŚCI KOLUMN
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

    // DODAJ PODSUMOWANIE
    const summaryRow = worksheet.addRow(['']);
    summaryRow.getCell(1).value = `PODSUMOWANIE: ${totalRows} inwestycji od ${investorsData.length} inwestorów`;
    summaryRow.font = { bold: true, italic: true };

    // GENERUJ BUFFER
    const buffer = await workbook.xlsx.writeBuffer();
    const base64Content = buffer.toString('base64');
    const currentDate = new Date().toISOString().split('T')[0];
    const filename = `${exportTitle.replace(/[^a-zA-Z0-9]/g, '_')}_${currentDate}.xlsx`;

    console.log(`✅ [DedicatedExcelExport] Excel generated: ${buffer.length} bytes, ${totalRows} rows`);

    return {
      filename,
      fileData: base64Content,
      fileSize: buffer.length,
      contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    };

  } catch (error) {
    console.error('❌ [DedicatedExcelExport] Excel generation failed:', error);
    throw new Error(`Błąd generowania Excel: ${error.message}`);
  }
}

/**
 * Pomocnicze funkcje
 */
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

async function saveExportHistory(data) {
  try {
    await db.collection('export_history').add({
      ...data,
      timestamp: new Date(),
      service: 'dedicated-excel-export'
    });
  } catch (error) {
    console.warn('⚠️ [DedicatedExcelExport] Failed to save history:', error);
  }
}

module.exports = {
  exportSelectedInvestorsToExcel
};