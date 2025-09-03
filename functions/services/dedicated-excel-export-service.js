/**
 * 🔄 UNIFIED EXCEL EXPORT SERVICE - Ujednolicony serwis eksportu Excel
 * 
 * NOWE PODEJŚCIE: Używa tej samej logiki pobierania danych co PDF/Word (advanced-export-service)
 * ale z dedykowaną funkcją generowania prawdziwych plików .xlsx
 * 
 * ✅ KLUCZOWE ZMIANY:
 * - Unified data logic: jedna logika pobierania danych dla Excel, PDF i Word
 * - Advanced data structure: używa investmentDetails zamiast płaskich investments
 * - Consistent formatting: format "clientName - productName - investmentType"
 * - Enhanced debugging: szczegółowe logowanie każdego kroku
 * - Better error handling: diagnostyka problemów i fallback'i
 * 
 * 🎯 KORZYŚCI:
 * - Spójność danych między wszystkimi formatami eksportu
 * - Łatwiejsze debugowanie i utrzymanie
 * - Jedna logika biznesowa dla mapowania typów produktów
 * - Ujednolicone formatowanie dat i kwot
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
  const requestId = Math.random().toString(36).substr(2, 9);
  const { clientIds, requestedBy, exportTitle = 'Eksport Inwestorów' } = request.data || {};

  console.log(`🚀 [DedicatedExcelExport:${requestId}] ===== STARTING EXCEL EXPORT =====`);
  console.log(`📋 [DedicatedExcelExport:${requestId}] Request parameters:`, {
    clientIdsCount: clientIds?.length || 0,
    requestedBy,
    exportTitle,
    requestData: JSON.stringify(request.data).slice(0, 500) + '...',
    timestamp: new Date().toISOString(),
    memoryLimit: '2GiB',
    timeoutSeconds: 300
  });

  // WALIDACJA Z SZCZEGÓŁOWYM LOGOWANIEM
  console.log(`🔍 [DedicatedExcelExport:${requestId}] Starting input validation...`);

  if (!clientIds || !Array.isArray(clientIds) || clientIds.length === 0) {
    console.error(`❌ [DedicatedExcelExport:${requestId}] Validation failed: Invalid clientIds`, {
      clientIds: clientIds,
      isArray: Array.isArray(clientIds),
      length: clientIds?.length
    });
    throw new HttpsError('invalid-argument', 'clientIds jest wymagane (niepusta tablica)');
  }

  if (!requestedBy) {
    console.error(`❌ [DedicatedExcelExport:${requestId}] Validation failed: Missing requestedBy`);
    throw new HttpsError('invalid-argument', 'requestedBy jest wymagane');
  }

  if (clientIds.length > 500) {
    console.error(`❌ [DedicatedExcelExport:${requestId}] Validation failed: Too many clients`, {
      requestedCount: clientIds.length,
      maxAllowed: 500
    });
    throw new HttpsError('invalid-argument', 'Maksymalnie 500 klientów na eksport');
  }

  console.log(`✅ [DedicatedExcelExport:${requestId}] Input validation passed`, {
    clientCount: clientIds.length,
    requestedBy,
    exportTitle
  });

  try {
    // KROK 1: Pobierz i waliduj dane - UŻYWAMY TEJ SAMEJ LOGIKI CO PDF/WORD
    console.log(`📊 [DedicatedExcelExport:${requestId}] STEP 1: Starting data fetch and validation (using advanced logic)...`);
    const dataFetchStart = Date.now();

    const validatedData = await fetchInvestorsDataAdvanced(clientIds, requestId); const dataFetchTime = Date.now() - dataFetchStart;
    console.log(`⏱️ [DedicatedExcelExport:${requestId}] Data fetch completed in ${dataFetchTime}ms`);
    
    if (validatedData.length === 0) {
      console.error(`❌ [DedicatedExcelExport:${requestId}] No data found for any clients`, {
        originalClientCount: clientIds.length,
        validatedCount: 0,
        clientIds: clientIds.slice(0, 10) // pierwsze 10 dla debugowania
      });
      throw new HttpsError('not-found', 'Nie znaleziono żadnych danych dla podanych klientów');
    }

    console.log(`✅ [DedicatedExcelExport:${requestId}] Data validation completed`, {
      originalClientCount: clientIds.length,
      validatedInvestorCount: validatedData.length,
      totalInvestments: validatedData.reduce((total, investor) => total + investor.investments.length, 0),
      averageInvestmentsPerClient: (validatedData.reduce((total, investor) => total + investor.investments.length, 0) / validatedData.length).toFixed(2),
      dataFetchTimeMs: dataFetchTime
    });

    // KROK 2: Generuj Excel
    console.log(`📈 [DedicatedExcelExport:${requestId}] STEP 2: Starting Excel generation...`);
    const excelGenStart = Date.now();

    const excelResult = await generateDedicatedExcel(validatedData, exportTitle, requestId);

    const excelGenTime = Date.now() - excelGenStart;
    console.log(`⏱️ [DedicatedExcelExport:${requestId}] Excel generation completed in ${excelGenTime}ms`);

    // KROK 3: Zapisz historię
    console.log(`💾 [DedicatedExcelExport:${requestId}] STEP 3: Saving export history...`);
    const historyStart = Date.now();

    await saveExportHistory({
      requestId,
      requestedBy,
      exportFormat: 'excel',
      clientCount: validatedData.length,
      exportTitle,
      executionTimeMs: Date.now() - startTime,
      dataFetchTimeMs: dataFetchTime,
      excelGenTimeMs: excelGenTime,
      status: 'success'
    });

    const historyTime = Date.now() - historyStart;
    console.log(`⏱️ [DedicatedExcelExport:${requestId}] History saved in ${historyTime}ms`);

    const totalExecutionTime = Date.now() - startTime;
    const recordCount = validatedData.reduce((total, investor) => total + investor.investments.length, 0);

    console.log(`🎉 [DedicatedExcelExport:${requestId}] ===== EXPORT COMPLETED SUCCESSFULLY =====`);
    console.log(`📊 [DedicatedExcelExport:${requestId}] Final statistics:`, {
      totalExecutionTimeMs: totalExecutionTime,
      dataFetchTimeMs: dataFetchTime,
      excelGenTimeMs: excelGenTime,
      historyTimeMs: historyTime,
      investorCount: validatedData.length,
      recordCount: recordCount,
      fileSize: excelResult.fileSize,
      fileSizeKB: Math.round(excelResult.fileSize / 1024),
      averageTimePerRecord: Math.round(totalExecutionTime / recordCount),
      performanceRating: totalExecutionTime < 10000 ? 'Excellent' : totalExecutionTime < 30000 ? 'Good' : 'Slow'
    });

    return {
      success: true,
      filename: excelResult.filename,
      fileData: excelResult.fileData,
      fileSize: excelResult.fileSize,
      contentType: excelResult.contentType,
      recordCount: recordCount,
      investorCount: validatedData.length,
      executionTimeMs: totalExecutionTime,
      format: 'excel',
      requestId: requestId,
      performanceMetrics: {
        dataFetchTimeMs: dataFetchTime,
        excelGenTimeMs: excelGenTime,
        historyTimeMs: historyTime,
        averageTimePerRecord: Math.round(totalExecutionTime / recordCount)
      }
    };

  } catch (error) {
    const errorExecutionTime = Date.now() - startTime;
    console.error(`❌ [DedicatedExcelExport:${requestId}] ===== EXPORT FAILED =====`);
    console.error(`💥 [DedicatedExcelExport:${requestId}] Error details:`, {
      errorMessage: error.message,
      errorCode: error.code,
      errorStack: error.stack?.split('\n').slice(0, 5), // pierwsze 5 linii stack trace
      executionTimeMs: errorExecutionTime,
      clientCount: clientIds.length,
      requestedBy,
      exportTitle,
      timestamp: new Date().toISOString()
    });
    
    // Zapisz historię błędu z dodatkowymi szczegółami
    await saveExportHistory({
      requestId,
      requestedBy,
      exportFormat: 'excel',
      clientCount: clientIds.length,
      exportTitle,
      executionTimeMs: errorExecutionTime,
      status: 'failed',
      error: error.message,
      errorCode: error.code,
      errorType: error.constructor.name
    });

    if (error instanceof HttpsError) {
      console.log(`🔄 [DedicatedExcelExport:${requestId}] Rethrowing HttpsError`);
      throw error;
    }

    console.log(`🚨 [DedicatedExcelExport:${requestId}] Converting to HttpsError`);
    throw new HttpsError('internal', `Błąd eksportu Excel: ${error.message}`);
  }
});

/**
 * Pobiera dane inwestorów używając tej samej logiki co PDF/Word (advanced-export-service)
 * 🔄 UNIFIED DATA LOGIC - jedna logika dla wszystkich formatów
 */
async function fetchInvestorsDataAdvanced(clientIds, requestId = 'unknown') {
  console.log(`📊 [DedicatedExcelExport:${requestId}] ===== STARTING ADVANCED DATA FETCH =====`);
  console.log(`� [DedicatedExcelExport:${requestId}] Using same data logic as PDF/Word service...`);

  const fetchStartTime = Date.now();
  const investorsData = [];

  console.log(`📋 [DedicatedExcelExport:${requestId}] Fetch configuration:`, {
    totalClientIds: clientIds.length,
    batchSize: 10,
    expectedBatches: Math.ceil(clientIds.length / 10),
    firstFewClientIds: clientIds.slice(0, 5),
    timestamp: new Date().toISOString()
  });

  let totalInvestmentsFound = 0;
  let totalDbQueries = 0;
  let failedBatches = 0;

  // Przetwarzaj w batches po 10 (limit Firestore) - IDENTYCZNE Z ADVANCED SERVICE
  for (let i = 0; i < clientIds.length; i += 10) {
    const batchNumber = Math.floor(i / 10) + 1;
    const batchClientIds = clientIds.slice(i, i + 10);
    const batchStartTime = Date.now();

    console.log(`📦 [DedicatedExcelExport:${requestId}] Processing batch ${batchNumber}/${Math.ceil(clientIds.length / 10)}:`, {
      batchSize: batchClientIds.length,
      clientIds: batchClientIds,
      startIndex: i,
      endIndex: i + 10 - 1
    });

    try {
      console.log(`🔎 [DedicatedExcelExport:${requestId}] Executing Firestore query for batch ${batchNumber}...`);
      const queryStartTime = Date.now();

      // Pobierz inwestycje dla tej partii - IDENTYCZNE ZAPYTANIE
      const investmentsSnapshot = await db.collection('investments')
        .where('clientId', 'in', batchClientIds)
        .get();

      totalDbQueries++;
      const queryTime = Date.now() - queryStartTime;
      const batchInvestmentsCount = investmentsSnapshot.docs.length;
      totalInvestmentsFound += batchInvestmentsCount;

      console.log(`📊 [DedicatedExcelExport:${requestId}] Batch ${batchNumber} query results:`, {
        queryTimeMs: queryTime,
        investmentsFound: batchInvestmentsCount,
        docsProcessed: investmentsSnapshot.size
      });

      // Grupuj po clientId - IDENTYCZNE Z ADVANCED SERVICE
      const investmentsByClient = {};
      console.log(`🗂️ [DedicatedExcelExport:${requestId}] Grouping investments by client for batch ${batchNumber}...`);

      investmentsSnapshot.docs.forEach(doc => {
        const investment = { id: doc.id, ...doc.data() };
        const clientId = investment.clientId;

        if (!investmentsByClient[clientId]) {
          investmentsByClient[clientId] = [];
        }
        investmentsByClient[clientId].push(investment);
      });

      console.log(`📊 [DedicatedExcelExport:${requestId}] Batch ${batchNumber} grouping summary:`, {
        uniqueClientsWithInvestments: Object.keys(investmentsByClient).length,
        clientsWithoutInvestments: batchClientIds.filter(id => !investmentsByClient[id]).length,
        totalInvestmentsInBatch: batchInvestmentsCount
      });

      // Stwórz podsumowania - UŻYWAMY ADVANCED LOGIC
      console.log(`✅ [DedicatedExcelExport:${requestId}] Creating investor summaries for batch ${batchNumber}...`);
      let validatedInBatch = 0;

      for (const clientId of batchClientIds) {
        const investments = investmentsByClient[clientId] || [];
        if (investments.length > 0) {
          console.log(`👤 [DedicatedExcelExport:${requestId}] Creating summary for client ${clientId}: ${investments.length} investments`);
          const investorSummary = createAdvancedInvestorSummary(clientId, investments, requestId);

          if (investorSummary) {
            investorsData.push(investorSummary);
            validatedInBatch++;
            console.log(`✅ [DedicatedExcelExport:${requestId}] Client ${clientId} summary created successfully`);
          } else {
            console.warn(`⚠️ [DedicatedExcelExport:${requestId}] Client ${clientId} summary creation failed`);
          }
        } else {
          console.warn(`⚠️ [DedicatedExcelExport:${requestId}] No investments found for client: ${clientId}`);
        }
      }

      const batchTime = Date.now() - batchStartTime;
      console.log(`🎯 [DedicatedExcelExport:${requestId}] Batch ${batchNumber} completed:`, {
        totalTimeMs: batchTime,
        queryTimeMs: queryTime,
        processingTimeMs: batchTime - queryTime,
        validatedClients: validatedInBatch,
        totalClientsInBatch: batchClientIds.length,
        successRate: `${((validatedInBatch / batchClientIds.length) * 100).toFixed(1)}%`
      });

    } catch (batchError) {
      failedBatches++;
      const batchTime = Date.now() - batchStartTime;

      console.error(`❌ [DedicatedExcelExport:${requestId}] Batch ${batchNumber} failed:`, {
        error: batchError.message,
        errorType: batchError.constructor.name,
        batchTimeMs: batchTime,
        clientIds: batchClientIds,
        stack: batchError.stack?.split('\n').slice(0, 3)
      });

      // Kontynuuj z następnym batch'em
      console.log(`🔄 [DedicatedExcelExport:${requestId}] Continuing with next batch despite error...`);
    }
  }

  const totalFetchTime = Date.now() - fetchStartTime;

  console.log(`🏁 [DedicatedExcelExport:${requestId}] ===== ADVANCED DATA FETCH COMPLETED =====`);
  console.log(`📈 [DedicatedExcelExport:${requestId}] Final fetch statistics:`, {
    totalExecutionTimeMs: totalFetchTime,
    totalDbQueries: totalDbQueries,
    totalInvestmentsFound: totalInvestmentsFound,
    validInvestorsCount: investorsData.length,
    originalClientCount: clientIds.length,
    failedBatches: failedBatches,
    successfulBatches: Math.ceil(clientIds.length / 10) - failedBatches,
    averageTimePerBatch: Math.round(totalFetchTime / Math.ceil(clientIds.length / 10)),
    averageInvestmentsPerValidInvestor: investorsData.length > 0 ?
      (investorsData.reduce((sum, inv) => sum + inv.investmentDetails.length, 0) / investorsData.length).toFixed(2) : 0,
    dataConversionRate: `${((investorsData.length / clientIds.length) * 100).toFixed(1)}%`
  });

  if (investorsData.length === 0) {
    console.error(`💥 [DedicatedExcelExport:${requestId}] No valid investors found after processing all batches!`);
  }

  return investorsData;
}

/**
 * Tworzy zaawansowane podsumowanie inwestora - IDENTYCZNE Z ADVANCED SERVICE
 * 🔄 UNIFIED SUMMARY LOGIC - jedna logika dla wszystkich formatów
 */
function createAdvancedInvestorSummary(clientId, investments, requestId = 'unknown') {
  console.log(`🔍 [DedicatedExcelExport:${requestId}] Creating advanced summary for client ${clientId}...`);

  if (!investments || investments.length === 0) {
    console.warn(`⚠️ [DedicatedExcelExport:${requestId}] No investments for client ${clientId}`);
    return null;
  }

  /**
   * Mapuje angielskie nazwy typów produktów na polskie - IDENTYCZNE Z ADVANCED
   */
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

  const firstInvestment = investments[0];

  // Podstawowe dane - IDENTYCZNE Z ADVANCED
  const clientName = safeToString(
    firstInvestment.clientName ||
    firstInvestment.imie_nazwisko ||
    'Nieznany klient'
  );

  console.log(`👤 [DedicatedExcelExport:${requestId}] Processing ${investments.length} investments for ${clientName}...`);

  // Przygotuj szczegóły każdej inwestycji zgodnie z formatem ADVANCED SERVICE:
  // clientName - productName - investmentType
  const investmentDetails = investments.map((inv, index) => {
    console.log(`💼 [DedicatedExcelExport:${requestId}] Processing investment ${index + 1}/${investments.length} for ${clientName}:`, {
      investmentId: inv.id,
      rawProductName: inv.productName || inv.nazwa_produktu,
      rawProductType: inv.productType || inv.typ_produktu
    });

    const productName = safeToString(inv.productName || inv.nazwa_produktu || 'Nieznany produkt');
    const rawInvestmentType = safeToString(inv.productType || inv.typ_produktu || 'Nieznany typ');
    const investmentType = mapProductTypeToPolish(rawInvestmentType); // Mapowanie na polskie nazwy
    const investmentEntryDate = inv.signingDate || inv.data_podpisania || inv.Data_podpisania || null;
    const investmentAmount = safeToDouble(inv.investmentAmount || inv.kwota_inwestycji || 0);
    const remainingCapital = safeToDouble(inv.remainingCapital || inv.kapital_pozostaly || 0);
    const capitalSecuredByRealEstate = safeToDouble(inv.capitalSecuredByRealEstate || inv.kapital_zabezpieczony_nieruchomoscami || 0);
    const capitalForRestructuring = safeToDouble(inv.capitalForRestructuring || inv.kapital_do_restrukturyzacji || 0);

    const detail = {
      // Format: clientName - productName - investmentType (IDENTYCZNY Z ADVANCED)
      displayName: `${clientName} - ${productName} - ${investmentType}`,
      clientName,
      productName,
      investmentType,
      investmentEntryDate: investmentEntryDate ? new Date(investmentEntryDate).toLocaleDateString('pl-PL') : 'Brak daty',
      investmentAmount,
      remainingCapital,
      capitalSecuredByRealEstate,
      capitalForRestructuring,
      investmentId: inv.id
    };

    console.log(`📊 [DedicatedExcelExport:${requestId}] Investment ${index + 1} processed:`, {
      displayName: detail.displayName,
      amounts: {
        investment: detail.investmentAmount,
        remaining: detail.remainingCapital
      }
    });

    return detail;
  });

  // Obliczenia finansowe (sumy) - IDENTYCZNE Z ADVANCED
  let totalInvestment = 0;
  let totalRemaining = 0;
  let totalRealized = 0;
  let totalSecured = 0;
  let totalForRestructuring = 0;

  const productTypes = new Set();
  const statuses = new Set();

  investments.forEach(inv => {
    totalInvestment += safeToDouble(inv.investmentAmount || inv.kwota_inwestycji || 0);
    totalRemaining += safeToDouble(inv.remainingCapital || inv.kapital_pozostaly || 0);
    totalRealized += safeToDouble(inv.realizedCapital || inv.kapital_zrealizowany || 0);
    totalSecured += safeToDouble(inv.capitalSecuredByRealEstate || 0);
    totalForRestructuring += safeToDouble(inv.capitalForRestructuring || inv.kapital_do_restrukturyzacji || 0);

    if (inv.productType) productTypes.add(inv.productType);
    if (inv.status) statuses.add(inv.status);
  });

  const summary = {
    clientId,
    clientName,
    investmentCount: investments.length,
    totalInvestmentAmount: totalInvestment,
    totalRemainingCapital: totalRemaining,
    totalRealizedCapital: totalRealized,
    totalSecuredCapital: totalSecured,
    totalCapitalForRestructuring: totalForRestructuring,
    productTypes: Array.from(productTypes),
    statuses: Array.from(statuses),
    investmentDetails, // 🚀 KLUCZOWE: Szczegóły każdej inwestycji w formacie ADVANCED
    investments: investments,
    performanceRate: totalInvestment > 0 ? ((totalRealized / totalInvestment) * 100) : 0,
    riskLevel: calculateRiskLevel(totalSecured, totalRemaining)
  };

  console.log(`✅ [DedicatedExcelExport:${requestId}] Advanced summary created for ${clientName}:`, {
    investmentCount: summary.investmentCount,
    totalInvestmentAmount: summary.totalInvestmentAmount,
    investmentDetailsCount: summary.investmentDetails.length,
    riskLevel: summary.riskLevel
  });

  return summary;
}

/**
 * Oblicza poziom ryzyka - IDENTYCZNE Z ADVANCED SERVICE
 */
function calculateRiskLevel(secured, remaining) {
  if (remaining === 0) return 'BRAK';
  const securityRatio = secured / remaining;

  if (securityRatio >= 0.8) return 'NISKIE';
  if (securityRatio >= 0.5) return 'ŚREDNIE';
  return 'WYSOKIE';
}/**
 * Generuje dedykowany plik Excel
 */
async function generateDedicatedExcel(investorsData, exportTitle, requestId = 'unknown') {
  const excelStartTime = Date.now();

  console.log(`📊 [DedicatedExcelExport:${requestId}] ===== STARTING EXCEL GENERATION =====`);
  console.log(`📋 [DedicatedExcelExport:${requestId}] Excel generation input:`, {
    investorsCount: investorsData.length,
    exportTitle,
    firstInvestorSample: investorsData[0] ? {
      clientId: investorsData[0].clientId,
      clientName: investorsData[0].clientName,
      investmentCount: investorsData[0].investments?.length || 0,
      firstInvestmentId: investorsData[0].investments?.[0]?.investmentId
    } : null,
    timestamp: new Date().toISOString()
  });

  try {
    const ExcelJS = require('exceljs');
    console.log(`📚 [DedicatedExcelExport:${requestId}] ExcelJS library loaded successfully`);

    const workbook = new ExcelJS.Workbook();
    
    // Metadane workbook z debugowaniem
    workbook.creator = 'Metropolitan Investment';
    workbook.created = new Date();
    workbook.modified = new Date();

    console.log(`📖 [DedicatedExcelExport:${requestId}] Workbook created with metadata:`, {
      creator: workbook.creator,
      created: workbook.created,
      modified: workbook.modified
    });

    const worksheet = workbook.addWorksheet('Eksport Inwestorów');
    console.log(`📄 [DedicatedExcelExport:${requestId}] Worksheet "Eksport Inwestorów" created`);

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

    console.log(`📋 [DedicatedExcelExport:${requestId}] Adding headers:`, headers);
    worksheet.addRow(headers);

    // STYLIZACJA NAGŁÓWKÓW
    console.log(`🎨 [DedicatedExcelExport:${requestId}] Applying header styling...`);
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
    let processedInvestors = 0;
    let processedInvestments = 0;

    // DANE INWESTORÓW Z SZCZEGÓŁOWYM DEBUGOWANIEM - UŻYWAMY FORMATU ADVANCED
    console.log(`📊 [DedicatedExcelExport:${requestId}] Starting data processing for ${investorsData.length} investors (using advanced format)...`);

    investorsData.forEach((investor, investorIndex) => {
      console.log(`👤 [DedicatedExcelExport:${requestId}] Processing investor ${investorIndex + 1}/${investorsData.length}:`, {
        clientId: investor.clientId,
        clientName: investor.clientName,
        investmentDetailsCount: investor.investmentDetails?.length || 0
      });

      if (!investor.investmentDetails || investor.investmentDetails.length === 0) {
        console.warn(`⚠️ [DedicatedExcelExport:${requestId}] Investor ${investor.clientName} has no investmentDetails to process`);
        return;
      }

      // UŻYWAMY investmentDetails ZAMIAST investments (format advanced service)
      investor.investmentDetails.forEach((detail, detailIndex) => {
        console.log(`💼 [DedicatedExcelExport:${requestId}] Processing investment detail ${detailIndex + 1}/${investor.investmentDetails.length} for ${investor.clientName}:`, {
          displayName: detail.displayName,
          productName: detail.productName,
          investmentType: detail.investmentType,
          investmentAmount: detail.investmentAmount,
          remainingCapital: detail.remainingCapital
        });

        const rowData = [
          detail.clientName,
          detail.productName,
          detail.investmentType, // używamy investmentType zamiast productType
          detail.investmentEntryDate, // używamy investmentEntryDate zamiast signedDate
          detail.investmentAmount,
          detail.remainingCapital,
          detail.capitalSecuredByRealEstate,
          detail.capitalForRestructuring
        ];

        console.log(`📝 [DedicatedExcelExport:${requestId}] Row data for investment ${detail.investmentId}:`, rowData);

        const row = worksheet.addRow(rowData);

        // Formatowanie liczb z debugowaniem
        console.log(`💰 [DedicatedExcelExport:${requestId}] Applying currency formatting to row ${totalRows + 2}...`);
        row.getCell(5).numFmt = '#,##0.00 "PLN"'; // Kwota inwestycji
        row.getCell(6).numFmt = '#,##0.00 "PLN"'; // Kapitał pozostały
        row.getCell(7).numFmt = '#,##0.00 "PLN"'; // Kapitał zabezpieczony
        row.getCell(8).numFmt = '#,##0.00 "PLN"'; // Do restrukturyzacji

        totalRows++;
        processedInvestments++;
      });

      processedInvestors++;

      console.log(`✅ [DedicatedExcelExport:${requestId}] Investor ${investor.clientName} processed successfully:`, {
        investmentDetailsProcessed: investor.investmentDetails.length,
        totalRowsSoFar: totalRows
      });
    });

    console.log(`📊 [DedicatedExcelExport:${requestId}] Data processing completed:`, {
      totalInvestorsProcessed: processedInvestors,
      totalInvestmentDetailsProcessed: processedInvestments,
      totalExcelRows: totalRows,
      expectedRows: investorsData.reduce((sum, inv) => sum + (inv.investmentDetails?.length || 0), 0)
    });    // SZEROKOŚCI KOLUMN
    console.log(`📐 [DedicatedExcelExport:${requestId}] Setting column widths...`);
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
    console.log(`📋 [DedicatedExcelExport:${requestId}] Adding summary row...`);
    const summaryRow = worksheet.addRow(['']);
    summaryRow.getCell(1).value = `PODSUMOWANIE: ${totalRows} inwestycji od ${investorsData.length} inwestorów`;
    summaryRow.font = { bold: true, italic: true };

    // GENERUJ BUFFER
    console.log(`💾 [DedicatedExcelExport:${requestId}] Generating Excel buffer...`);
    const bufferStartTime = Date.now();

    const buffer = await workbook.xlsx.writeBuffer();

    const bufferTime = Date.now() - bufferStartTime;
    console.log(`⏱️ [DedicatedExcelExport:${requestId}] Buffer generation completed in ${bufferTime}ms`);

    const base64Content = Buffer.from(buffer).toString('base64');
    const currentDate = new Date().toISOString().split('T')[0];
    const filename = `${exportTitle.replace(/[^a-zA-Z0-9]/g, '_')}_${currentDate}.xlsx`;

    const totalExcelTime = Date.now() - excelStartTime;

    console.log(`✅ [DedicatedExcelExport:${requestId}] ===== EXCEL GENERATION COMPLETED =====`);
    console.log(`📈 [DedicatedExcelExport:${requestId}] Final Excel statistics:`, {
      filename,
      bufferSizeBytes: buffer.length,
      bufferSizeKB: Math.round(buffer.length / 1024),
      base64SizeBytes: base64Content.length,
      totalRows: totalRows,
      totalInvestors: processedInvestors,
      totalInvestments: processedInvestments,
      totalGenerationTimeMs: totalExcelTime,
      bufferGenerationTimeMs: bufferTime,
      averageTimePerRow: Math.round(totalExcelTime / totalRows),
      compressionRatio: ((buffer.length / base64Content.length) * 100).toFixed(1) + '%'
    });

    return {
      filename,
      fileData: base64Content,
      fileSize: buffer.length,
      contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    };

  } catch (error) {
    const errorTime = Date.now() - excelStartTime;
    console.error(`❌ [DedicatedExcelExport:${requestId}] ===== EXCEL GENERATION FAILED =====`);
    console.error(`💥 [DedicatedExcelExport:${requestId}] Excel generation error:`, {
      errorMessage: error.message,
      errorType: error.constructor.name,
      errorStack: error.stack?.split('\n').slice(0, 5),
      failureTimeMs: errorTime,
      investorsDataLength: investorsData?.length || 0,
      timestamp: new Date().toISOString()
    });

    throw new Error(`Błąd generowania Excel: ${error.message}`);
  }
}

/**
 * Zapisuje historię eksportu
 */
async function saveExportHistory(data) {
  try {
    await db.collection('export_history').add({
      ...data,
      timestamp: new Date(),
      service: 'dedicated-excel-export-unified'
    });
  } catch (error) {
    console.warn('⚠️ [DedicatedExcelExport] Failed to save history:', error);
  }
}

/**
 * 🔧 POMOCNICZE FUNKCJE DEBUGOWANIA
 */

/**
 * Loguje metryki wydajności z kolorami i szczegółami
 */
function logPerformanceMetrics(requestId, phase, startTime, additionalData = {}) {
  const duration = Date.now() - startTime;
  const rating = getPerformanceRating(duration, phase);

  console.log(`⏱️ [DedicatedExcelExport:${requestId}] Performance ${phase}:`, {
    durationMs: duration,
    rating: rating,
    timestamp: new Date().toISOString(),
    ...additionalData
  });

  return duration;
}

/**
 * Ocenia wydajność na podstawie czasu wykonania
 */
function getPerformanceRating(durationMs, phase) {
  const thresholds = {
    'data-fetch': { excellent: 5000, good: 15000, slow: 30000 },
    'validation': { excellent: 1000, good: 5000, slow: 10000 },
    'excel-generation': { excellent: 3000, good: 10000, slow: 20000 },
    'overall': { excellent: 10000, good: 30000, slow: 60000 }
  };

  const threshold = thresholds[phase] || thresholds.overall;

  if (durationMs <= threshold.excellent) return '🟢 Excellent';
  if (durationMs <= threshold.good) return '🟡 Good';
  if (durationMs <= threshold.slow) return '🟠 Slow';
  return '🔴 Very Slow';
}

/**
 * Loguje wykorzystanie pamięci (jeśli dostępne)
 */
function logMemoryUsage(requestId, phase) {
  try {
    if (typeof process !== 'undefined' && process.memoryUsage) {
      const memory = process.memoryUsage();
      console.log(`🧠 [DedicatedExcelExport:${requestId}] Memory usage during ${phase}:`, {
        heapUsedMB: Math.round(memory.heapUsed / 1024 / 1024),
        heapTotalMB: Math.round(memory.heapTotal / 1024 / 1024),
        rssMB: Math.round(memory.rss / 1024 / 1024),
        externalMB: Math.round(memory.external / 1024 / 1024),
        timestamp: new Date().toISOString()
      });
    }
  } catch (error) {
    console.warn(`⚠️ [DedicatedExcelExport:${requestId}] Could not log memory usage:`, error.message);
  }
}

/**
 * Diagnostyka błędów z szczegółową analizą
 */
function logErrorDiagnostics(requestId, error, context = {}) {
  console.error(`🔍 [DedicatedExcelExport:${requestId}] Error diagnostics:`, {
    errorType: error.constructor.name,
    errorMessage: error.message,
    errorCode: error.code,
    context: context,
    stackTrace: error.stack?.split('\n').slice(0, 10), // pierwsze 10 linii
    timestamp: new Date().toISOString(),
    nodeVersion: process.version,
    platform: process.platform
  });

  // Szczegółowa analiza popularnych błędów
  if (error.message.includes('ECONNRESET')) {
    console.error(`🌐 [DedicatedExcelExport:${requestId}] Network error detected - connection reset`);
  }

  if (error.message.includes('timeout')) {
    console.error(`⏰ [DedicatedExcelExport:${requestId}] Timeout error detected - operation took too long`);
  }

  if (error.message.includes('ExcelJS')) {
    console.error(`📊 [DedicatedExcelExport:${requestId}] ExcelJS library error - possible data formatting issue`);
  }

  if (error.message.includes('Firebase')) {
    console.error(`🔥 [DedicatedExcelExport:${requestId}] Firebase error - possible authentication or quota issue`);
  }
}

/**
 * Loguje szczegółowe statystyki danych
 */
function logDataStatistics(requestId, data, phase) {
  console.log(`📊 [DedicatedExcelExport:${requestId}] Data statistics for ${phase}:`, {
    totalRecords: Array.isArray(data) ? data.length : 1,
    dataType: typeof data,
    isArray: Array.isArray(data),
    sampleKeys: typeof data === 'object' && data !== null ? Object.keys(data).slice(0, 10) : null,
    memorySizeEstimate: estimateObjectSize(data),
    timestamp: new Date().toISOString()
  });
}

/**
 * Szacuje rozmiar obiektu w bajtach
 */
function estimateObjectSize(obj) {
  try {
    const jsonString = JSON.stringify(obj);
    return {
      estimatedBytes: jsonString.length * 2, // UTF-16 characters
      estimatedKB: Math.round((jsonString.length * 2) / 1024),
      estimatedMB: Math.round((jsonString.length * 2) / 1024 / 1024)
    };
  } catch (error) {
    return { error: 'Could not estimate size' };
  }
}

/**
 * Tworzy checkpoint debugowania dla długich operacji
 */
function createDebugCheckpoint(requestId, checkpointName, data = {}) {
  console.log(`🏁 [DedicatedExcelExport:${requestId}] Checkpoint: ${checkpointName}`, {
    checkpoint: checkpointName,
    timestamp: new Date().toISOString(),
    data: data
  });
}

/**
 * Waliduje integralność danych przed eksportem
 */
function validateDataIntegrity(requestId, investorsData) {
  console.log(`🔍 [DedicatedExcelExport:${requestId}] Starting data integrity validation...`);

  const validation = {
    totalInvestors: investorsData.length,
    investorsWithData: 0,
    investorsWithoutData: 0,
    totalInvestments: 0,
    invalidInvestments: 0,
    missingFields: {},
    dataQualityScore: 0
  };

  investorsData.forEach((investor, index) => {
    if (!investor.investments || investor.investments.length === 0) {
      validation.investorsWithoutData++;
      console.warn(`⚠️ [DedicatedExcelExport:${requestId}] Investor ${index} has no investments`);
      return;
    }

    validation.investorsWithData++;
    validation.totalInvestments += investor.investments.length;

    investor.investments.forEach((investment, invIndex) => {
      // Sprawdź wymagane pola
      const requiredFields = ['clientName', 'productName', 'investmentAmount'];
      const missingFieldsForInvestment = [];

      requiredFields.forEach(field => {
        if (!investment[field] || investment[field] === '') {
          missingFieldsForInvestment.push(field);
          validation.missingFields[field] = (validation.missingFields[field] || 0) + 1;
        }
      });

      if (missingFieldsForInvestment.length > 0) {
        validation.invalidInvestments++;
        console.warn(`⚠️ [DedicatedExcelExport:${requestId}] Investment ${invIndex} for investor ${index} missing fields:`, missingFieldsForInvestment);
      }
    });
  });

  // Oblicz score jakości danych
  validation.dataQualityScore = validation.totalInvestments > 0 ?
    Math.round(((validation.totalInvestments - validation.invalidInvestments) / validation.totalInvestments) * 100) : 0;

  console.log(`📋 [DedicatedExcelExport:${requestId}] Data integrity validation results:`, validation);

  return validation;
}

module.exports = {
  exportSelectedInvestorsToExcel
  // 🔄 UNIFIED EXCEL EXPORT: 
  // Teraz używa tej samej logiki danych co PDF/Word ale generuje prawdziwe pliki .xlsx
};