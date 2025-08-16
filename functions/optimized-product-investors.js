/**
 * 🚀 OPTIMIZED PRODUCT INVESTORS - Nowa precyzyjna implementacja
 * Wykorzystuje nową strukturę danych z logicznymi ID dla maksymalnej precyzji
 */

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const { admin, db } = require("./utils/firebase-config"); // Użyj centralnej konfiguracji
const { getCachedResult, setCachedResult } = require("./utils/cache-utils");

/**
 * 🎯 NOWA GŁÓWNA FUNKCJA: Ultra-precyzyjne wyszukiwanie inwestorów
 * Wykorzystuje nową strukturę z productId dla 100% precyzji
 */
exports.getProductInvestorsUltraPrecise = onCall({
  memory: "2GiB",
  timeoutSeconds: 120,
  region: "europe-west1",
}, async (request) => {
  const data = request.data || {};
  const startTime = Date.now();

  console.log("🎯 [Ultra Precise] Rozpoczynam precyzyjne wyszukiwanie...", data);

  try {
    const {
      productId,        // GŁÓWNY IDENTYFIKATOR - np. "apartment_0078"
      productName,      // BACKUP - np. "Zatoka Komfortu"
      searchStrategy = 'productId', // 'productId' | 'productName'
      forceRefresh = false,
    } = data;

    // ⚠️ WALIDACJA: productId lub productName wymagane
    if (!productId && !productName) {
      throw new HttpsError('invalid-argument', 'Wymagany productId lub productName');
    }

    // 💾 CACHE KEY - oparty na głównym identyfikatorze
    const primaryKey = productId || productName;
    const cacheKey = forceRefresh
      ? `ultra_precise_${primaryKey}_fresh_${Date.now()}`
      : `ultra_precise_${primaryKey}`;

    console.log(`🔑 [Ultra Precise] Cache key: ${cacheKey}`);

    if (!forceRefresh) {
      const cached = await getCachedResult(cacheKey);
      if (cached) {
        console.log("⚡ [Ultra Precise] Zwracam z cache");
        return { ...cached, fromCache: true };
      }
    }

    // 📊 KROK 1: PRECYZYJNE QUERY - wykorzystuj nową strukturę
    console.log("🎯 [Ultra Precise] Rozpoczynam precyzyjne query...");

    let query;
    let strategyUsed;

    if (productId && searchStrategy === 'productId') {
      // STRATEGIA 1: Bezpośrednie wyszukiwanie po productId (najdokładniejsze)
      query = db.collection('investments').where('productId', '==', productId);
      strategyUsed = 'productId_direct';
      console.log(`🎯 [Ultra Precise] Query po productId: ${productId}`);

    } else if (productName) {
      // STRATEGIA 2: Wyszukiwanie po productName (dla apartamentów to samo co projectName)
      query = db.collection('investments').where('productName', '==', productName);
      strategyUsed = 'productName_direct';
      console.log(`🎯 [Ultra Precise] Query po productName: ${productName}`);

    } else {
      throw new HttpsError('invalid-argument', 'Nieprawidłowa strategia wyszukiwania');
    }

    // Wykonaj query
    const investmentsSnapshot = await query.get();
    console.log(`📊 [Ultra Precise] Znaleziono ${investmentsSnapshot.docs.length} inwestycji`);

    if (investmentsSnapshot.docs.isEmpty) {
      console.log("⚠️ [Ultra Precise] Brak inwestycji - sprawdzam fallback...");

      // FALLBACK: jeśli nie znaleziono po productId, spróbuj po productName
      if (productId && productName && strategyUsed === 'productId_direct') {
        console.log(`🔄 [Ultra Precise] Fallback: productName = ${productName}`);
        const fallbackQuery = db.collection('investments').where('productName', '==', productName);
        const fallbackSnapshot = await fallbackQuery.get();

        if (!fallbackSnapshot.docs.isEmpty) {
          console.log(`🔄 [Ultra Precise] Fallback sukces: ${fallbackSnapshot.docs.length} inwestycji`);
          return await processInvestments(fallbackSnapshot.docs, productName, 'productName_fallback', startTime, cacheKey);
        }
      }

      // DODATKOWY FALLBACK: spróbuj szukać po projectName
      if (productName) {
        console.log(`🔄 [Ultra Precise] Fallback 2: projectName = ${productName}`);
        const projectNameQuery = db.collection('investments').where('projectName', '==', productName);
        const projectNameSnapshot = await projectNameQuery.get();

        if (!projectNameSnapshot.docs.isEmpty) {
          console.log(`🔄 [Ultra Precise] ProjectName fallback sukces: ${projectNameSnapshot.docs.length} inwestycji`);
          return await processInvestments(projectNameSnapshot.docs, productName, 'projectName_fallback', startTime, cacheKey);
        }
      }

      // DEBUGOWANIE: Sprawdź co w ogóle jest w kolekcji investments
      console.log("🔍 [Ultra Precise] DEBUGOWANIE: Sprawdzam przykładowe inwestycje...");
      const sampleQuery = db.collection('investments').limit(3);
      const sampleSnapshot = await sampleQuery.get();

      sampleSnapshot.docs.forEach((doc, index) => {
        const data = doc.data();
        console.log(`📋 [Ultra Precise] Przykład ${index + 1}:`);
        console.log(`   - ID: ${doc.id}`);
        console.log(`   - productId: ${data.productId}`);
        console.log(`   - productName: ${data.productName}`);
        console.log(`   - projectName: ${data.projectName}`);
        console.log(`   - productType: ${data.productType}`);
      });

      // Brak wyników
      console.log(`❌ [Ultra Precise] Brak inwestycji dla: productId=${productId}, productName=${productName}`);
      return createEmptyResult(primaryKey, strategyUsed, startTime, cacheKey);
    }

    // KROK 2: Przetwórz znalezione inwestycje
    return await processInvestments(investmentsSnapshot.docs, primaryKey, strategyUsed, startTime, cacheKey);

  } catch (error) {
    console.error("❌ [Ultra Precise] Szczegółowy błąd:", error);
    console.error("❌ [Ultra Precise] Stack trace:", error.stack);
    console.error("❌ [Ultra Precise] Parametry wejściowe:", {
      productId: data?.productId,
      productName: data?.productName,
      searchStrategy: data?.searchStrategy
    });

    // Zwróć bardziej szczegółowy błąd
    const errorMessage = error.message || 'Unknown error';
    console.error(`❌ [Ultra Precise] Zwracam błąd: ${errorMessage}`);

    throw new HttpsError("internal", `Ultra precise search failed: ${errorMessage}. Check logs for details.`);
  }
});

/**
 * 🔧 POMOCNICZA: Przetwarza znalezione inwestycje
 */
async function processInvestments(investmentDocs, searchKey, strategyUsed, startTime, cacheKey) {
  console.log("🔄 [Ultra Precise] Przetwarzanie inwestycji...");

  // KROK 1: Pobierz mapę klientów
  const clientsSnapshot = await db.collection('clients').limit(1000).get();
  const clientsMap = new Map();
  const clientsByExcelId = new Map();

  clientsSnapshot.docs.forEach(doc => {
    const client = { id: doc.id, ...doc.data() };
    clientsMap.set(client.id, client);

    // Mapowanie po excelId dla lepszego dopasowania
    if (client.excelId) clientsByExcelId.set(client.excelId.toString(), client);
    if (client.original_id) clientsByExcelId.set(client.original_id.toString(), client);
  });

  console.log(`👥 [Ultra Precise] Załadowano ${clientsMap.size} klientów, ${clientsByExcelId.size} z Excel ID`);

  // KROK 2: Grupowanie inwestycji według klientów
  const investmentsByClient = new Map();
  let mappedCount = 0;
  let unmappedCount = 0;

  investmentDocs.forEach(doc => {
    const investment = { id: doc.id, ...doc.data() };
    const clientId = investment.clientId?.toString();

    // ⚠️ UWAGA: W niektórych danych clientId może być pusty!
    if (!clientId || clientId.trim() === '') {
      console.warn(`⚠️ [Ultra Precise] Inwestycja bez clientId: ${investment.id} (productName: ${investment.productName})`);

      // Utwórz tymczasowego "nieznanego" klienta dla tej inwestycji
      const unknownClientKey = `unknown_${investment.id}`;
      const unknownClient = {
        id: unknownClientKey,
        fullName: investment.clientName || 'Nieznany klient',
        name: investment.clientName || 'Nieznany klient',
        email: '',
        phone: '',
        isActive: true,
      };

      if (!investmentsByClient.has(unknownClientKey)) {
        investmentsByClient.set(unknownClientKey, {
          client: unknownClient,
          investments: []
        });
      }

      investmentsByClient.get(unknownClientKey).investments.push({
        ...investment,
        mappingMethod: 'unknown_client',
      });

      unmappedCount++;
      return;
    }

    // Znajdź klienta - preferuj mapowanie po Excel ID
    let resolvedClient = clientsByExcelId.get(clientId) || clientsMap.get(clientId);

    if (!resolvedClient) {
      // Fallback: szukaj po clientName
      const clientName = investment.clientName;
      if (clientName && clientName.trim() !== '') {
        for (const [_, client] of clientsMap) {
          const dbName = client.fullName || client.imie_nazwisko || client.name || '';
          if (dbName.trim() === clientName.trim()) {
            resolvedClient = client;
            break;
          }
        }
      }
    }

    if (resolvedClient) {
      mappedCount++;
      const clientKey = resolvedClient.id;

      if (!investmentsByClient.has(clientKey)) {
        investmentsByClient.set(clientKey, {
          client: resolvedClient,
          investments: []
        });
      }

      investmentsByClient.get(clientKey).investments.push({
        ...investment,
        mappingMethod: clientsByExcelId.has(clientId) ? 'excelId' : 'uuid',
      });
    } else {
      console.warn(`❌ [Ultra Precise] Nie znaleziono klienta: ${clientId} (${investment.clientName})`);
      unmappedCount++;
    }
  });

  console.log(`📊 [Ultra Precise] Mapowanie klientów: ${mappedCount} sukces, ${unmappedCount} błędów`);

  // KROK 3: Tworzenie podsumowań inwestorów
  const investors = [];
  for (const [_, clientData] of investmentsByClient) {
    const summary = createUltraPreciseInvestorSummary(clientData.client, clientData.investments);
    investors.push(summary);
  }

  // Sortuj według wartości inwestycji
  investors.sort((a, b) => b.totalRemainingCapital - a.totalRemainingCapital);

  const result = {
    investors,
    totalCount: investors.length,
    searchStrategy: strategyUsed,
    searchKey,
    executionTime: Date.now() - startTime,
    fromCache: false,
    statistics: {
      totalInvestments: investmentDocs.length,
      totalCapital: investors.reduce((sum, inv) => sum + inv.totalRemainingCapital, 0),
      averageCapital: investors.length > 0
        ? investors.reduce((sum, inv) => sum + inv.totalRemainingCapital, 0) / investors.length
        : 0,
    },
    mappingStats: {
      mapped: mappedCount,
      unmapped: unmappedCount,
      mappingRatio: mappedCount / (mappedCount + unmappedCount)
    }
  };

  // Cache na 5 minut
  await setCachedResult(cacheKey, result, 300);

  console.log(`✅ [Ultra Precise] Zakończono: ${investors.length} inwestorów w ${result.executionTime}ms`);
  return result;
}

/**
 * 🎯 POMOCNICZA: Tworzy precyzyjne podsumowanie inwestora
 */
function createUltraPreciseInvestorSummary(client, investments) {
  let totalInvestmentAmount = 0;
  let totalRemainingCapital = 0;
  let totalCapitalForRestructuring = 0;

  const processedInvestments = investments.map(investment => {
    const investmentAmount = parseFloat(investment.investmentAmount || 0);
    const remainingCapital = parseFloat(investment.remainingCapital || 0);
    const capitalForRestructuring = parseFloat(investment.capitalForRestructuring || 0);

    totalInvestmentAmount += investmentAmount;
    totalRemainingCapital += remainingCapital;
    totalCapitalForRestructuring += capitalForRestructuring;

    return {
      id: investment.id,
      productId: investment.productId,
      // ✅ Preferuj productName, fallback na projectName
      productName: investment.productName || investment.projectName,
      // ✅ Sprawdź productType i investmentType
      productType: investment.productType || investment.investmentType,
      investmentAmount,
      remainingCapital,
      capitalForRestructuring,
      // ✅ Sprawdź oba pola dla capitalSecuredByRealEstate
      capitalSecuredByRealEstate: investment.capitalSecuredByRealEstate ||
        investment.realEstateSecuredCapital || 0,
      // ✅ Preferuj signingDate (rzeczywiste pole Firebase)
      signedDate: investment.signingDate || investment.signedDate || investment.investmentEntryDate,
      status: investment.productStatus || investment.status || 'Unknown',
      saleId: investment.saleId,
      branch: investment.branch,
      advisor: investment.advisor,
      // ✅ Dodatkowe pola z Firebase
      sourceFile: investment.sourceFile,
      realizedCapital: parseFloat(investment.realizedCapital || 0),
      realizedInterest: parseFloat(investment.realizedInterest || 0),
      remainingInterest: parseFloat(investment.remainingInterest || 0),
      currency: investment.currency || 'PLN',
      marketType: investment.productStatusEntry,
    };
  });

  return {
    client: {
      id: client.id,
      name: client.fullName || client.imie_nazwisko || client.name || 'Unknown',
      email: client.email || '',
      phone: client.telefon || client.phone || '',
      companyName: client.nazwa_firmy || client.companyName || null,
      isActive: client.isActive !== false,
      excelId: client.excelId || client.original_id,
    },
    investments: processedInvestments,
    investmentCount: investments.length,
    totalInvestmentAmount,
    totalRemainingCapital,
    totalCapitalForRestructuring,
    totalCapitalSecuredByRealEstate: Math.max(totalRemainingCapital - totalCapitalForRestructuring, 0),
    averageInvestment: investments.length > 0 ? totalRemainingCapital / investments.length : 0,
  };
}

/**
 * 🔧 POMOCNICZA: Tworzy pusty wynik
 */
async function createEmptyResult(searchKey, strategyUsed, startTime, cacheKey) {
  const result = {
    investors: [],
    totalCount: 0,
    searchStrategy: strategyUsed,
    searchKey,
    executionTime: Date.now() - startTime,
    fromCache: false,
    statistics: { totalInvestments: 0, totalCapital: 0, averageCapital: 0 },
    mappingStats: { mapped: 0, unmapped: 0, mappingRatio: 0 }
  };

  // Cache pustego wyniku na 1 minutę
  await setCachedResult(cacheKey, result, 60);
  return result;
}
