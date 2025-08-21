/**
 * 🚀 BATCH PRODUCT SERVICE - Masowe przetwarzanie produktów
 * Optymalizacja pobierania wielu produktów jednocześnie
 */

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { getCachedResult, setCachedResult } = require("../utils/cache-utils");
const { safeToDouble, safeToString } = require("../utils/data-mapping");

/**
 * 🚀 GŁÓWNA FUNKCJA: Pobieranie wszystkich produktów z inwestorami jednym zapytaniem
 */
const getAllProductsWithInvestors = onCall({
  memory: "2GiB",
  timeoutSeconds: 540, // 9 minut max
  region: "europe-west1",
}, async (request) => {
  const startTime = Date.now();
  const db = admin.firestore();

  try {
    console.log("🚀 [BatchProducts] Rozpoczynam masowe pobieranie produktów...");

    const {
      forceRefresh = false,
      includeStatistics = true,
      maxProducts = 500
    } = request.data || {};

    // Cache key dla całego batch - v4 po dodaniu companyId mapping
    const cacheKey = `batch_products_with_investors_v4_${maxProducts}`;

    if (!forceRefresh) {
      const cached = await getCachedResult(cacheKey);
      if (cached) {
        console.log("⚡ [BatchProducts] Zwracam z cache");
        return {
          ...cached,
          fromCache: true,
          executionTime: Date.now() - startTime
        };
      }
    }

    // KROK 1: Pobierz wszystkie inwestycje jednym zapytaniem
    console.log("📊 [BatchProducts] Pobieranie wszystkich inwestycji...");
    const investmentsSnapshot = await db.collection('investments').get();
    const allInvestments = investmentsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    console.log(`📊 [BatchProducts] Pobrano ${allInvestments.length} inwestycji`);

    // KROK 1.5: Pobierz wszystkich klientów dla statusów głosowania 🆕
    console.log("👥 [BatchProducts] Pobieranie danych klientów...");
    const clientsSnapshot = await db.collection('clients').get();
    const clientsMap = new Map();

    clientsSnapshot.docs.forEach(doc => {
      const clientData = doc.data();
      const clientId = doc.id;
      const excelId = clientData.id ? clientData.id.toString() : null;

      // Mapuj zarówno po Firebase ID jak i Excel ID
      clientsMap.set(clientId, {
        id: clientId,
        excelId: excelId,
        votingStatus: clientData.votingStatus
      });

      if (excelId) {
        clientsMap.set(excelId, {
          id: clientId,
          excelId: excelId,
          votingStatus: clientData.votingStatus
        });
      }
    });

    console.log(`👥 [BatchProducts] Pobrano ${clientsSnapshot.docs.length} klientów, mapowanych: ${clientsMap.size}`);

    // KROK 2: Grupowanie po produktach (deduplikacja)
    const productGroups = new Map();

    for (const investment of allInvestments) {
      const productKey = generateProductKey(investment);

      if (!productGroups.has(productKey)) {
        productGroups.set(productKey, {
          investments: [],
          productInfo: extractProductInfo(investment)
        });
      }

      productGroups.get(productKey).investments.push(investment);
    }

    console.log(`📊 [BatchProducts] Pogrupowano w ${productGroups.size} unikalnych produktów`);

    // KROK 3: Równoległe przetwarzanie grup produktów (BATCH)
    const productEntries = Array.from(productGroups.entries()).slice(0, maxProducts);
    const batchSize = 20; // Przetwarzaj 20 produktów jednocześnie
    const allProducts = [];

    for (let i = 0; i < productEntries.length; i += batchSize) {
      const batch = productEntries.slice(i, i + batchSize);

      console.log(`🔄 [BatchProducts] Batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(productEntries.length / batchSize)}: przetwarzam ${batch.length} produktów...`);

      const batchResults = await Promise.allSettled(
        batch.map(async ([productKey, data]) => {
          try {
            return await processProductGroup(productKey, data.productInfo, data.investments, clientsMap); // 🆕 Przekaż mapę klientów jako clientsData
          } catch (error) {
            console.error(`❌ [BatchProducts] Błąd produktu ${productKey}:`, error.message);
            return null;
          }
        })
      );

      // Dodaj tylko udane rezultaty
      batchResults.forEach(result => {
        if (result.status === 'fulfilled' && result.value) {
          allProducts.push(result.value);
        }
      });

      // Krótka przerwa między batch'ami
      if (i + batchSize < productEntries.length) {
        await new Promise(resolve => setTimeout(resolve, 100));
      }
    }

    // KROK 4: Sortowanie według wartości
    allProducts.sort((a, b) => b.totalValue - a.totalValue);

    // KROK 5: Oblicz globalne statystyki (opcjonalnie)
    let globalStatistics = null;
    if (includeStatistics) {
      globalStatistics = calculateGlobalStatistics(allProducts);
    }

    const result = {
      products: allProducts,
      totalProducts: allProducts.length,
      totalInvestments: allInvestments.length,
      statistics: globalStatistics,
      executionTime: Date.now() - startTime,
      fromCache: false,
      metadata: {
        processedAt: new Date().toISOString(),
        batchSize,
        maxProducts
      }
    };

    // Cache na 10 minut (długo bo dane się rzadko zmieniają)
    await setCachedResult(cacheKey, result, 600);

    console.log(`✅ [BatchProducts] Zakończono w ${result.executionTime}ms, zwracam ${allProducts.length} produktów`);
    return result;

  } catch (error) {
    console.error("❌ [BatchProducts] Krytyczny błąd:", error);
    throw new HttpsError("internal", `Błąd batch produktów: ${error.message}`);
  }
});

/**
 * Generuje unikalny klucz dla produktu
 */
function generateProductKey(investment) {
  const productName = safeToString(
    investment.productName ||
    investment.projectName ||
    investment.nazwa_produktu ||
    investment.Produkt_nazwa ||
    investment.produkt_nazwa
  );

  const productType = safeToString(
    investment.productType ||
    investment.typ_produktu ||
    investment.Typ_produktu ||
    'bonds'
  );

  const companyId = safeToString(
    investment.companyId ||
    investment.ID_Spolka ||
    investment.id_spolka ||
    investment.creditorCompany ||
    investment.wierzyciel_spolka ||
    'unknown'
  );

  return `${productName}|${productType}|${companyId}`.toLowerCase()
    .replace(/[^\w\s|]/g, '')
    .trim();
}

/**
 * Wyciąga podstawowe informacje o produkcie
 */
function extractProductInfo(investment) {
  return {
    name: safeToString(
      investment.productName ||
      investment.projectName ||
      investment.nazwa_produktu ||
      investment.Produkt_nazwa ||
      investment.produkt_nazwa ||
      'Nieznany Produkt'
    ),
    type: safeToString(
      investment.productType ||
      investment.typ_produktu ||
      investment.Typ_produktu ||
      'bonds'
    ),
    companyId: safeToString(
      investment.companyId ||
      investment.ID_Spolka ||
      investment.id_spolka ||
      investment.creditorCompany ||
      'unknown'
    ),
    companyName: safeToString(
      investment.creditorCompany ||
      investment.wierzyciel_spolka ||
      investment.companyName ||
      investment.companyId ||             // ✅ DODANE: companyId dla "Metropolitan Investment S.A."
      investment.nazwa_firmy ||
      investment.nazwa_spolki ||
      investment.emitent ||
      investment.developer ||
      investment.issuer ||
      investment.Emitent ||
      investment.Developer ||
      'Nieznana Firma'
    ),
    interestRate: safeToDouble(
      investment.interestRate ||
      investment.oprocentowanie ||
      investment.Oprocentowanie
    ),
  };
}

/**
 * Przetwarza grupę inwestycji dla jednego produktu
 */
async function processProductGroup(productKey, productInfo, investments, clientsData) { // 🆕 Zmieniono nazwę na clientsData
  // Grupowanie po klientach (deduplikacja inwestorów)
  const clientsMap = new Map();
  let totalValue = 0;
  let totalRemainingCapital = 0;

  for (const investment of investments) {
    const clientId = safeToString(
      investment.clientId ||
      investment.id_klient ||
      investment.ID_Klient ||
      `unknown_${investment.id}`
    );

    const investmentAmount = safeToDouble(
      investment.investmentAmount ||
      investment.kwota_inwestycji
    );

    const remainingCapital = safeToDouble(
      investment.remainingCapital ||
      investment.kapital_pozostaly
    );

    totalValue += investmentAmount;
    totalRemainingCapital += remainingCapital;

    // Grupuj po kliencie
    if (!clientsMap.has(clientId)) {
      // 🆕 Znajdź status głosowania klienta
      const clientInfo = clientsData.get(clientId);
      const votingStatus = clientInfo ? clientInfo.votingStatus : 'undecided';

      clientsMap.set(clientId, {
        clientId,
        clientName: safeToString(
          investment.clientName ||
          investment.inwestor_imie_nazwisko ||
          investment.Klient
        ),
        investments: [],
        totalAmount: 0,
        totalRemaining: 0,
        votingStatus: votingStatus // 🆕 Dodaj status głosowania
      });
    }

    const clientData = clientsMap.get(clientId);
    clientData.investments.push(investment);
    clientData.totalAmount += investmentAmount;
    clientData.totalRemaining += remainingCapital;
  }

  // Konwertuj mapę na tablicę inwestorów
  const investors = Array.from(clientsMap.values())
    .sort((a, b) => b.totalRemaining - a.totalRemaining);

  return {
    id: Math.abs(productKey.split('').reduce((a, b) => (((a << 5) - a) + b.charCodeAt(0)) | 0, 0)).toString(),
    name: productInfo.name,
    productType: mapProductType(productInfo.type),
    companyName: productInfo.companyName,
    companyId: productInfo.companyId,
    totalValue,
    totalRemainingCapital,
    totalInvestments: investments.length,
    uniqueInvestors: investors.length,
    actualInvestorCount: investors.length, // W tym przypadku to samo
    averageInvestment: totalValue / investments.length,
    interestRate: productInfo.interestRate,

    // Daty
    earliestInvestmentDate: findEarliestDate(investments),
    latestInvestmentDate: findLatestDate(investments),

    // Status
    status: determineProductStatus(investments),

    // Lista inwestorów (top 10 dla wydajności)
    topInvestors: investors.slice(0, 10),

    // Metadane
    metadata: {
      productKey,
      sourceInvestments: investments.length,
      lastUpdated: new Date().toISOString()
    }
  };
}

/**
 * Mapuje typ produktu na enum
 */
function mapProductType(type) {
  const typeStr = type.toLowerCase();
  if (typeStr.includes('apartment') || typeStr.includes('apartament')) return 'apartments';
  if (typeStr.includes('share') || typeStr.includes('udział')) return 'shares';
  if (typeStr.includes('loan') || typeStr.includes('pożyczk')) return 'loans';
  return 'bonds'; // default
}

/**
 * Znajduje najwcześniejszą datę
 */
function findEarliestDate(investments) {
  let earliest = null;
  for (const inv of investments) {
    const date = inv.createdAt || inv.signedDate || inv.data_podpisania;
    if (date) {
      const parsedDate = typeof date === 'string' ? new Date(date) : date.toDate();
      if (!earliest || parsedDate < earliest) {
        earliest = parsedDate;
      }
    }
  }
  return earliest || new Date();
}

/**
 * Znajduje najpóźniejszą datę
 */
function findLatestDate(investments) {
  let latest = null;
  for (const inv of investments) {
    const date = inv.createdAt || inv.signedDate || inv.data_podpisania;
    if (date) {
      const parsedDate = typeof date === 'string' ? new Date(date) : date.toDate();
      if (!latest || parsedDate > latest) {
        latest = parsedDate;
      }
    }
  }
  return latest || new Date();
}

/**
 * Określa status produktu
 */
function determineProductStatus(investments) {
  const activeCount = investments.filter(inv => {
    const status = (inv.status || inv.status_produktu || 'active').toString().toLowerCase();
    return status.includes('active') || status.includes('aktywny');
  }).length;

  const activeRatio = activeCount / investments.length;
  if (activeRatio > 0.8) return 'active';
  if (activeRatio > 0.2) return 'pending';
  return 'inactive';
}

/**
 * Oblicza globalne statystyki
 */
function calculateGlobalStatistics(products) {
  const totalValue = products.reduce((sum, p) => sum + p.totalValue, 0);
  const totalCapital = products.reduce((sum, p) => sum + p.totalRemainingCapital, 0);
  const totalInvestors = products.reduce((sum, p) => sum + p.uniqueInvestors, 0);

  return {
    totalProducts: products.length,
    totalValue,
    totalRemainingCapital: totalCapital,
    totalInvestors,
    averageValuePerProduct: totalValue / products.length,
    averageInvestorsPerProduct: totalInvestors / products.length,

    // Rozkład typów produktów
    productTypeDistribution: products.reduce((acc, p) => {
      acc[p.productType] = (acc[p.productType] || 0) + 1;
      return acc;
    }, {}),

    // Top 5 produktów
    topProductsByValue: products
      .sort((a, b) => b.totalValue - a.totalValue)
      .slice(0, 5)
      .map(p => ({
        name: p.name,
        value: p.totalValue,
        investors: p.uniqueInvestors
      }))
  };
}

module.exports = {
  getAllProductsWithInvestors
};
