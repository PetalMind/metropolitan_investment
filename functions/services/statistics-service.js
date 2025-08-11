/**
 * Statistics Service
 * Generuje statystyki produktów TYLKO na podstawie danych z kolekcji 'investments'
 * 
 * UWAGA: Stare kolekcje (bonds, shares, loans, apartments, products) są deprecated
 * Wszystkie dane produktów znajdują się teraz w kolekcji 'investments'
 */

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const { db } = require("../utils/firebase-config");
const { getCachedResult, setCachedResult } = require("../utils/cache-utils");
const {
  safeToDouble,
  safeToString,
  parseDate,
  mapProductType,
  mapProductStatus
} = require("../utils/data-mapping");

/**
 * Konwertuje dokument do formatu potrzebnego dla analizy statystycznej
 */
function convertDocumentForAnalysis(id, data) {
  const productType = mapProductType(data.productType);
  const status = mapProductStatus(data.status || data.productStatus);
  const investmentAmount = safeToDouble(data.investmentAmount || data.paidAmount);
  const totalValue = safeToDouble(data.remainingCapital || data.realEstateSecuredCapital) +
    safeToDouble(data.realizedCapital);

  return {
    id: id,
    productType: productType,
    productTypeName: getProductTypeName(productType),
    status: status,
    investmentAmount: investmentAmount,
    totalValue: totalValue > 0 ? totalValue : investmentAmount,
    companyName: safeToString(data.companyId || data.creditorCompany),
    interestRate: extractInterestRate(data),
    createdAt: parseDate(data.createdAt) || parseDate(data.signingDate) || new Date().toISOString(),
  };
}

/**
 * Zwraca nazwę wyświetlaną dla typu produktu
 */
function getProductTypeName(productType) {
  const typeNames = {
    apartments: 'Apartamenty',
    bonds: 'Obligacje',
    shares: 'Udziały',
    loans: 'Pożyczki',
    other: 'Inne',
  };

  return typeNames[productType] || 'Nieznany';
}

/**
 * Próbuje wyciągnąć oprocentowanie z różnych pól
 */
function extractInterestRate(data) {
  const possibleFields = [
    'interestRate',
    'oprocentowanie',
    'rate',
    'stopa',
  ];

  for (const field of possibleFields) {
    if (data[field]) {
      const rate = safeToDouble(data[field]);
      if (rate > 0) return rate;
    }
  }

  return null;
}

/**
 * Generuje statystyki produktów
 */
const getUnifiedProductStatistics = onCall({
  memory: "1GiB",
  timeoutSeconds: 180,
  cors: true,
}, async (request) => {
  const data = request.data || {};
  console.log("📊 [Product Statistics] Rozpoczynam analizę statystyk produktów...");

  try {
    const { forceRefresh = false } = data;

    // 💾 Sprawdź cache
    const cacheKey = "unified_product_statistics";
    if (!forceRefresh) {
      const cached = await getCachedResult(cacheKey);
      if (cached) {
        console.log("⚡ [Product Statistics] Zwracam z cache");
        return cached;
      }
    }

    // Pobierz dane bezpośrednio z kolekcji 'investments'
    console.log("📊 [Product Statistics] Pobieranie danych z kolekcji 'investments'...");
    const investmentsSnapshot = await db.collection("investments").get();

    console.log(`📊 [Product Statistics] Pobrano ${investmentsSnapshot.size} dokumentów`);

    if (investmentsSnapshot.size === 0) {
      const emptyStats = {
        totalProducts: 0,
        activeProducts: 0,
        inactiveProducts: 0,
        totalInvestmentAmount: 0,
        totalValue: 0,
        averageInvestmentAmount: 0,
        averageValue: 0,
        profitLoss: 0,
        profitLossPercentage: 0,
        activePercentage: 0,
        typeDistribution: [],
        statusDistribution: [],
        mostValuableType: 'apartments',
        mostValuableTypeValue: 0,
        topCompaniesByValue: [],
        interestRateStats: {
          averageRate: 0,
          minRate: 0,
          maxRate: 0,
          productsWithRate: 0,
        },
        recentProducts: {
          lastMonth: 0,
          lastQuarter: 0,
          lastYear: 0,
        },
        timestamp: new Date().toISOString(),
        cacheUsed: false,
      };

      await setCachedResult(cacheKey, emptyStats, 300);
      return emptyStats;
    }

    // Konwertuj dokumenty na produkty dla analizy
    const products = [];
    investmentsSnapshot.docs.forEach(doc => {
      try {
        const data = doc.data();
        const product = convertDocumentForAnalysis(doc.id, data);
        products.push(product);
      } catch (error) {
        console.warn(`⚠️ [Product Statistics] Błąd konwersji dokumentu ${doc.id}:`, error);
      }
    });

    // Podstawowe statystyki
    const totalProducts = products.length;
    const activeProducts = products.filter(p => p.status === 'active').length;
    const inactiveProducts = totalProducts - activeProducts;

    const totalInvestmentAmount = products.reduce((sum, p) => sum + (p.investmentAmount || 0), 0);
    const totalValue = products.reduce((sum, p) => sum + (p.totalValue || 0), 0);

    const averageInvestmentAmount = totalProducts > 0 ? totalInvestmentAmount / totalProducts : 0;
    const averageValue = totalProducts > 0 ? totalValue / totalProducts : 0;

    const profitLoss = totalValue - totalInvestmentAmount;
    const profitLossPercentage = totalInvestmentAmount > 0 ? (profitLoss / totalInvestmentAmount) * 100 : 0;
    const activePercentage = totalProducts > 0 ? (activeProducts / totalProducts) * 100 : 0;

    // Dystrybucja typów
    const typeStats = {};
    products.forEach(product => {
      const type = product.productType;
      if (!typeStats[type]) {
        typeStats[type] = {
          productType: type,
          productTypeName: product.productTypeName,
          count: 0,
          totalInvestment: 0,
          totalValue: 0,
        };
      }
      typeStats[type].count++;
      typeStats[type].totalInvestment += product.investmentAmount || 0;
      typeStats[type].totalValue += product.totalValue || 0;
    });

    const typeDistribution = Object.values(typeStats).map(stat => ({
      ...stat,
      percentage: (stat.count / totalProducts) * 100,
    }));

    // Dystrybucja statusów
    const statusStats = {};
    products.forEach(product => {
      const status = product.status;
      if (!statusStats[status]) {
        statusStats[status] = {
          status: status,
          statusName: getStatusDisplayName(status),
          count: 0,
        };
      }
      statusStats[status].count++;
    });

    const statusDistribution = Object.values(statusStats).map(stat => ({
      ...stat,
      percentage: (stat.count / totalProducts) * 100,
    }));

    // Najbardziej wartościowy typ
    let mostValuableType = 'apartments';
    let mostValuableTypeValue = 0;

    typeDistribution.forEach(type => {
      if (type.totalValue > mostValuableTypeValue) {
        mostValuableType = type.productType;
        mostValuableTypeValue = type.totalValue;
      }
    });

    // Top spółki po wartości
    const companyStats = {};
    products.forEach(product => {
      const company = product.companyName || 'Nieznana spółka';
      if (!companyStats[company]) {
        companyStats[company] = {
          companyName: company,
          productCount: 0,
          totalInvestment: 0,
          totalValue: 0,
        };
      }
      companyStats[company].productCount++;
      companyStats[company].totalInvestment += product.investmentAmount || 0;
      companyStats[company].totalValue += product.totalValue || 0;
    });

    const topCompaniesByValue = Object.values(companyStats)
      .sort((a, b) => b.totalValue - a.totalValue)
      .slice(0, 10);

    // Statystyki oprocentowania
    const productsWithInterest = products.filter(p => p.interestRate && p.interestRate > 0);
    const interestRates = productsWithInterest.map(p => p.interestRate);

    const interestRateStats = {
      averageRate: interestRates.length > 0 ?
        interestRates.reduce((sum, rate) => sum + rate, 0) / interestRates.length : 0,
      minRate: interestRates.length > 0 ? Math.min(...interestRates) : 0,
      maxRate: interestRates.length > 0 ? Math.max(...interestRates) : 0,
      productsWithRate: productsWithInterest.length,
    };

    // Statystyki czasowe (ostatnie produkty)
    const now = new Date();
    const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, now.getDate());
    const lastQuarter = new Date(now.getFullYear(), now.getMonth() - 3, now.getDate());
    const lastYear = new Date(now.getFullYear() - 1, now.getMonth(), now.getDate());

    const recentProducts = {
      lastMonth: products.filter(p => new Date(p.createdAt) >= lastMonth).length,
      lastQuarter: products.filter(p => new Date(p.createdAt) >= lastQuarter).length,
      lastYear: products.filter(p => new Date(p.createdAt) >= lastYear).length,
    };

    const result = {
      // Podstawowe statystyki
      totalProducts,
      activeProducts,
      inactiveProducts,
      totalInvestmentAmount,
      totalValue,
      averageInvestmentAmount,
      averageValue,
      profitLoss,
      profitLossPercentage,
      activePercentage,

      // Dystrybucje
      typeDistribution,
      statusDistribution,

      // Najbardziej wartościowy typ
      mostValuableType,
      mostValuableTypeValue,

      // Top spółki
      topCompaniesByValue,

      // Statystyki oprocentowania
      interestRateStats,

      // Statystyki czasowe
      recentProducts,

      // Metadane
      timestamp: new Date().toISOString(),
      cacheUsed: false,
    };

    // 💾 Cache wyników na 5 minut
    await setCachedResult(cacheKey, result, 300);

    console.log(`✅ [Product Statistics] Wygenerowano statystyki dla ${totalProducts} produktów`);
    return result;

  } catch (error) {
    console.error("❌ [Product Statistics] Błąd:", error);
    throw new HttpsError(
      "internal",
      "Nie udało się wygenerować statystyk produktów",
      error.message,
    );
  }
});

/**
 * Zwraca nazwę wyświetlaną dla statusu
 */
function getStatusDisplayName(status) {
  const statusNames = {
    active: 'Aktywny',
    inactive: 'Nieaktywny',
    pending: 'Oczekujący',
    suspended: 'Zawieszony',
  };

  return statusNames[status] || 'Nieznany';
}

module.exports = {
  getUnifiedProductStatistics,
};
