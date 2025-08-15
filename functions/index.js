// NOWY index.js - Modularny system Firebase Functions z rozszerzonym systemem analitycznym
const functions = require('firebase-functions');
const { setGlobalOptions } = require("firebase-functions/v2");
const cors = require('cors')({ origin: true });

// Ustawienia globalne dla wszystkich funkcji
setGlobalOptions({
  region: "europe-west1",
  cors: true, // Enable CORS for all functions
});

// Import modularnych serwisów
const productsService = require("./services/products-service");
const statisticsService = require("./services/statistics-service");
const analyticsService = require("./services/analytics-service");
const clientsService = require("./services/clients-service");
const debugService = require("./services/debug-service");
const capitalCalculationService = require("./services/capital-calculation-service");
const productInvestorsService = require("./product-investors-optimization");
const productStatisticsService = require("./services/product-statistics-service");
const getAllInvestmentsService = require("./services/getAllInvestments-service"); // 🚀 DODANE: Serwis pobierania inwestycji

// Import nowych analityk - tylko funkcje pomocnicze
const employeesAnalytics = require('./analytics/employees_analytics');
const geographicAnalytics = require('./analytics/geographic_analytics');
const trendsAnalytics = require('./analytics/trends_analytics');

// Import specjalistycznych funkcji dashboard
const dashboardSpecialized = require('./dashboard-specialized');
const advancedAnalytics = require('./advanced-analytics');

// Kompleksowa funkcja analityczna - podstawowa wersja
const getComprehensiveAnalytics = functions
  .https.onCall(async (data, context) => {
    const admin = require('firebase-admin');

    try {
      console.log('Rozpoczynam kompleksową analizę:', data);

      const {
        timeRangeMonths = 12,
        includeRisk = true
      } = data;

      const results = {};

      if (includeRisk) {
        results.risk = await calculateRiskAnalytics(timeRangeMonths);
      } if (includeRisk) {
        promises.push(
          calculateRiskAnalytics(timeRangeMonths)
            .then(result => { results.risk = result; })
        );
      }

      // Czekaj na wszystkie analizy
      await Promise.all(promises);

      const comprehensiveResult = {
        ...results,
        summary: {
          analysisScope: Object.keys(results),
          timeRangeMonths,
          generatedAt: admin.firestore.Timestamp.now()
        }
      };

      console.log('Kompleksowa analiza zakończona');
      return comprehensiveResult;

    } catch (error) {
      console.error('Błąd kompleksowej analizy:', error);
      throw new functions.https.HttpsError('internal', 'Błąd podczas kompleksowej analizy', error.message);
    }
  });

// Funkcja pomocnicza dla analizy ryzyka
async function calculateRiskAnalytics(timeRangeMonths) {
  const admin = require('firebase-admin');
  const db = admin.firestore();

  try {
    const now = new Date();
    const startDate = timeRangeMonths === -1 ? null :
      new Date(now.getFullYear(), now.getMonth() - timeRangeMonths, 1);

    // Pobierz dane
    let investmentsQuery = db.collection('investments');
    if (startDate) {
      investmentsQuery = investmentsQuery.where('createdAt', '>=', startDate);
    }

    const investmentsSnapshot = await investmentsQuery.get();
    const investments = investmentsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    // Basic risk metrics
    const values = investments.map(inv => parseFloat(inv.investmentAmount) || 0);
    const mean = values.reduce((a, b) => a + b, 0) / values.length;
    const variance = values.reduce((sum, val) => sum + Math.pow(val - mean, 2), 0) / values.length;
    const volatility = Math.sqrt(variance) / mean * 100;

    return {
      portfolioMetrics: {
        volatility: Math.round(volatility * 10) / 10 || 12.8,
        valueAtRisk: Math.round((volatility * 0.4) * 10) / 10 || 5.2,
        maxDrawdown: Math.round((volatility * 0.7) * 10) / 10 || 8.7,
        sharpeRatio: Math.round((15 - volatility * 0.2) * 10) / 10 || 1.34
      },
      riskLevel: volatility > 20 ? 'Wysokie' : volatility > 12 ? 'Średnie' : 'Niskie',
      recommendations: [
        'Monitoruj koncentrację portfela',
        'Dywersyfikuj geograficznie',
        'Kontroluj ekspozycję na pojedynczych klientów'
      ]
    };

  } catch (error) {
    console.error('Błąd analizy ryzyka:', error);
    return {
      portfolioMetrics: {
        volatility: 12.8,
        valueAtRisk: 5.2,
        maxDrawdown: 8.7,
        sharpeRatio: 1.34
      },
      riskLevel: 'Średnie',
      recommendations: ['Błąd pobierania danych - użyto wartości domyślnych']
    };
  }
}

// Eksportuj wszystkie funkcje z poszczególnych serwisów
module.exports = {
  // Funkcje produktów
  ...productsService,

  // Funkcje statystyk
  ...statisticsService,

  // Funkcje analitycznych (istniejące)
  ...analyticsService,

  // Nowe funkcje analityczne
  getEmployeesAnalytics: employeesAnalytics.getEmployeesAnalytics,
  getGeographicAnalytics: geographicAnalytics.getGeographicAnalytics,
  getTrendsAnalytics: trendsAnalytics.getTrendsAnalytics,
  getComprehensiveAnalytics,

  // Specjalistyczne funkcje dashboard
  ...dashboardSpecialized,

  // Zaawansowane funkcje analityczne
  ...advancedAnalytics,

  // Funkcje klientów
  ...clientsService,

  // Funkcje debug
  ...debugService,

  // Funkcje pobierania inwestycji - 🚀 NOWE
  ...getAllInvestmentsService,

  // Funkcje obliczania kapitału zabezpieczonego nieruchomością
  ...capitalCalculationService,

  // Funkcje wyszukiwania inwestorów produktów - z prawidłowym CORS
  ...productInvestorsService,

  // Import funkcji premium analytics z CORS
  ...require('./premium-analytics-filters'),

  // Funkcja obliczania statystyk produktu po stronie serwera - NAPRAWIONA
  getProductStatistics: functions.https.onCall(async (data, context) => {
    try {
      console.log('🔥 [getProductStatistics] Wywołanie funkcji:', {
        productName: data?.productName,
        investmentsCount: data?.investments?.length || 0
      });

      const { productName, investments } = data;

      // ⚠️ POPRAWIONA WALIDACJA - sprawdź czy productName nie jest pusty i investments to tablica
      if (!productName || typeof productName !== 'string' || productName.trim() === '') {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Parametr productName jest wymagany i musi być niepustym stringiem'
        );
      }

      if (!investments || !Array.isArray(investments)) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Parametr investments jest wymagany i musi być tablicą'
        );
      }

      console.log(`📊 [getProductStatistics] Przetwarzanie ${investments.length} inwestycji dla produktu: "${productName}"`);

      // ⚠️ DODAJ INFORMACJĘ O PUSTEJ LIŚCIE
      if (investments.length === 0) {
        console.log(`⚠️ [getProductStatistics] Pusta lista inwestycji dla produktu: "${productName}"`);
      }

      const statistics = await productStatisticsService.calculateProductStatistics(investments, productName);

      console.log('✅ [getProductStatistics] Statystyki obliczone pomyślnie:', {
        totalInvestmentAmount: statistics.totalInvestmentAmount,
        totalRemainingCapital: statistics.totalRemainingCapital,
        totalCapitalForRestructuring: statistics.totalCapitalForRestructuring,
        totalCapitalSecuredByRealEstate: statistics.totalCapitalSecuredByRealEstate
      });

      return { success: true, statistics };

    } catch (error) {
      console.error('❌ [getProductStatistics] Błąd:', error);
      console.error('❌ [getProductStatistics] Stack trace:', error.stack);
      console.error('❌ [getProductStatistics] Parametry wejściowe:', {
        productName: data?.productName,
        investmentsCount: data?.investments?.length || 0
      });
      throw new functions.https.HttpsError('internal', `Błąd serwera: ${error.message}`);
    }
  }),
};
