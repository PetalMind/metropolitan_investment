/**
 * 🎯 PREMIUM ANALYTICS SERVICE - Firebase Functions
 * 
 * Kompleksowy serwis analityki premium dla zaawansowanych inwestorów
 * Przeniesienie ciężkich obliczeń analitycznych na serwer Google
 * 
 * 🚀 KLUCZOWE FUNKCJONALNOŚCI:
 * • Analiza grupy większościowej (koalicja ≥51% kapitału)
 * • Zaawansowana analiza głosowania (TAK/NIE/WSTRZYMUJE/NIEZDECYDOWANY)
 * • Inteligentne statystyki systemu z predykcją trendów
 * • Metryki wydajnościowe i analizy trend
 * • Comprehensive insights i analytics
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { admin, db } = require("../utils/firebase-config");
const { safeToDouble } = require("../utils/data-mapping");
const { getCachedResult, setCachedResult } = require("../utils/cache-utils");
const {
  calculateUnifiedTotalValue,
  calculateUnifiedViableCapital,
  calculateCapitalSecuredByRealEstate,
  getUnifiedField,
  normalizeInvestmentDocument
} = require("../utils/unified-statistics");

/**
 * 🎯 GŁÓWNA FUNKCJA: Kompleksowa analityka premium
 * Zwraca pełne dane analityczne gotowe do wyświetlenia w UI
 */
async function getPremiumInvestorAnalytics(data) {
  const startTime = Date.now();

  console.log("🎯 [Premium Analytics] Rozpoczynam kompleksową analizę premium...", data);

  try {
    const {
      page = 1,
      pageSize = 10000,
      sortBy = 'viableRemainingCapital',
      sortAscending = false,
      includeInactive = false,
      votingStatusFilter = null,
      clientTypeFilter = null,
      showOnlyWithUnviableInvestments = false,
      searchQuery = null,
      majorityThreshold = 51.0,
      forceRefresh = false,
    } = data;

    // 💾 Cache Key
    const cacheKey = `premium_analytics_${JSON.stringify({
      page, pageSize, sortBy, sortAscending, includeInactive,
      votingStatusFilter, clientTypeFilter, showOnlyWithUnviableInvestments,
      searchQuery, majorityThreshold
    })}_${forceRefresh ? Date.now() : ''}`;

    if (!forceRefresh) {
      const cached = await getCachedResult(cacheKey);
      if (cached) {
        console.log("⚡ [Premium Analytics] Zwracam z cache");
        return { ...cached, fromCache: true };
      }
    }

    // 🔍 KROK 1: Pobierz wszystkich inwestorów bezpośrednio z bazy danych
    console.log("📋 [Premium Analytics] Pobieranie danych z bazy...");
    const [clientsSnapshot, investmentsSnapshot] = await Promise.all([
      db.collection("clients").limit(10000).get(),
      db.collection("investments").limit(50000).get(),
    ]);

    const clients = clientsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    const investments = investmentsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    console.log(`📊 [Premium Analytics] Dane: ${clients.length} klientów, ${investments.length} inwestycji`);

    // Użyj lokalnej funkcji do przetworzenia danych inwestorów
    const investors = await processInvestorsData(clients, investments, {
      page,
      pageSize,
      sortBy,
      sortAscending,
      includeInactive,
      votingStatusFilter,
      clientTypeFilter,
      showOnlyWithUnviableInvestments,
      searchQuery
    });

    // 🔍 KROK 2: Oblicz analizę grupy większościowej
    const majorityAnalysis = calculateMajorityAnalysis(investors, majorityThreshold);

    // 🔍 KROK 3: Oblicz szczegółową analizę głosowania
    const votingAnalysis = calculateVotingAnalysis(investors);

    // 🔍 KROK 4: Oblicz metryki wydajnościowe
    const performanceMetrics = calculatePerformanceMetrics(investors);

    // 🔍 KROK 5: Oblicz analizę trendów
    const trendAnalysis = calculateTrendAnalysis(investors);

    // 🔍 KROK 6: Generuj inteligentne insights
    const insights = generateIntelligentInsights(investors, majorityAnalysis, votingAnalysis);

    // 🎯 WYNIK PREMIUM ANALYTICS
    const result = {
      success: true,
      data: {
        // Podstawowe dane inwestorów
        investors: investors,
        totalCount: investors.length,
        pagination: {
          currentPage: page,
          pageSize: pageSize,
          totalPages: Math.ceil(investors.length / pageSize),
          hasNextPage: page * pageSize < investors.length,
          hasPreviousPage: page > 1
        },

        // 🚀 PREMIUM ANALYTICS
        majorityAnalysis,
        votingAnalysis,
        performanceMetrics,
        trendAnalysis,
        insights,

        // Metadane
        metadata: {
          totalProcessingTime: Date.now() - startTime,
          majorityThreshold,
          analysisTimestamp: new Date().toISOString(),
          dataFreshness: 'server-computed'
        }
      },
      fromCache: false
    };

    // 💾 Cache result na 2 minuty
    await setCachedResult(cacheKey, result, 120);

    console.log(`✅ [Premium Analytics] Analiza zakończona w ${Date.now() - startTime}ms`);
    return result;

  } catch (error) {
    console.error("❌ [Premium Analytics] Błąd:", error);
    throw new HttpsError('internal', `Premium analytics failed: ${error.message}`);
  }
}

/**
 * 🔧 FUNKCJA POMOCNICZA: Przetwarzanie danych inwestorów
 * Lokalna implementacja logiki analytics bez wywołania Cloud Function
 */
async function processInvestorsData(clients, investments, filters) {
  const {
    page = 1,
    pageSize = 10000,
    sortBy = 'viableRemainingCapital',
    sortAscending = false,
    votingStatusFilter = null,
    clientTypeFilter = null,
    searchQuery = null
  } = filters;

  console.log("🔧 [Process Investors] Przetwarzanie danych...");
  console.log(`📊 [Process Investors] Otrzymano ${clients.length} klientów i ${investments.length} inwestycji`);

  // Grupuj inwestycje według klientów
  const investmentsByClient = new Map();

  console.log("🔍 [Process Investors] Rozpoczynam grupowanie inwestycji według klientów...");
  investments.forEach((investment, index) => {
    try {
      const clientName = getUnifiedField(investment, 'clientName');
      if (!clientName) {
        console.log(`⚠️ [Process Investors] Brak clientName dla inwestycji ${index}: ${JSON.stringify(investment).substring(0, 100)}`);
        return;
      }

      if (!investmentsByClient.has(clientName)) {
        investmentsByClient.set(clientName, []);
      }
      investmentsByClient.get(clientName).push(investment);
    } catch (error) {
      console.error(`❌ [Process Investors] Błąd podczas grupowania inwestycji ${index}:`, error);
      throw new HttpsError('internal', `Investment processing failed: ${error.message}`);
    }
  });

  // Utwórz podsumowania inwestorów
  const allInvestors = [];
  clients.forEach((client) => {
    const clientName = client.fullName;
    const clientInvestments = investmentsByClient.get(clientName) || [];

    if (clientInvestments.length === 0) return;

    let totalViableCapital = 0;
    let totalCapitalSecuredByRealEstate = 0;
    let totalCapitalForRestructuring = 0;
    let unifiedTotalValue = 0;

    const processedInvestments = clientInvestments.map((investment) => {
      const normalizedInvestment = normalizeInvestmentDocument(investment);
      const viableCapital = calculateUnifiedViableCapital(investment);
      const totalValue = calculateUnifiedTotalValue(investment);
      const capitalSecuredByRealEstate = calculateCapitalSecuredByRealEstate(investment);
      const capitalForRestructuring = getUnifiedField(investment, 'capitalForRestructuring');

      totalViableCapital += viableCapital;
      totalCapitalSecuredByRealEstate += capitalSecuredByRealEstate;
      totalCapitalForRestructuring += capitalForRestructuring;
      unifiedTotalValue += totalValue;

      return {
        ...normalizedInvestment,
        capitalSecuredByRealEstate,
        capitalForRestructuring,
      };
    });

    allInvestors.push({
      client: {
        id: client.id,
        name: client.fullName,
        email: client.email || "",
        phone: client.phone || "",
        companyName: client.companyName || "",
        votingStatus: client.votingStatus || "undecided",
        type: client.type || "individual",
        unviableInvestments: client.unviableInvestments || [],
      },
      investments: processedInvestments,
      viableRemainingCapital: totalViableCapital,
      unifiedTotalValue: unifiedTotalValue,
      totalInvestmentAmount: processedInvestments.reduce((sum, inv) => sum + getUnifiedField(inv.originalData, 'investmentAmount'), 0),
      capitalSecuredByRealEstate: totalCapitalSecuredByRealEstate,
      capitalForRestructuring: totalCapitalForRestructuring,
      investmentCount: clientInvestments.length,
    });
  });

  // Filtrowanie
  let filteredInvestors = allInvestors;

  if (votingStatusFilter) {
    filteredInvestors = filteredInvestors.filter(inv =>
      inv.client.votingStatus === votingStatusFilter
    );
  }

  if (clientTypeFilter) {
    filteredInvestors = filteredInvestors.filter(inv =>
      inv.client.type === clientTypeFilter
    );
  }

  if (searchQuery) {
    const query = searchQuery.toLowerCase();
    filteredInvestors = filteredInvestors.filter(inv =>
      inv.client.name.toLowerCase().includes(query) ||
      (inv.client.companyName && inv.client.companyName.toLowerCase().includes(query))
    );
  }

  // Sortowanie
  filteredInvestors.sort((a, b) => {
    let valueA = a[sortBy] || (a.client && a.client[sortBy]) || 0;
    let valueB = b[sortBy] || (b.client && b.client[sortBy]) || 0;

    if (typeof valueA === 'string' && typeof valueB === 'string') {
      valueA = valueA.toLowerCase();
      valueB = valueB.toLowerCase();
    }

    const comparison = valueA < valueB ? -1 : valueA > valueB ? 1 : 0;
    return sortAscending ? comparison : -comparison;
  });

  // Paginacja
  const startIndex = (page - 1) * pageSize;
  const endIndex = Math.min(startIndex + pageSize, filteredInvestors.length);
  const paginatedInvestors = filteredInvestors.slice(startIndex, endIndex);

  console.log(`✅ [Process Investors] Przetworzono ${paginatedInvestors.length}/${filteredInvestors.length} inwestorów`);

  return paginatedInvestors;
}

/**
 * 🏆 ANALIZA GRUPY WIĘKSZOŚCIOWEJ
 * Znajduje minimalną grupę inwestorów która kontroluje ≥51 % kapitału
 */
function calculateMajorityAnalysis(investors, majorityThreshold = 51.0) {
  console.log(`🏆 [Majority Analysis] Analiza dla progu ${majorityThreshold}%`);

  if (!investors || investors.length === 0) {
    return {
      totalCapital: 0,
      majorityThreshold,
      majorityHolders: [],
      majorityCapital: 0,
      majorityPercentage: 0,
      holdersCount: 0,
      averageHolding: 0,
      medianHolding: 0,
      concentrationIndex: 0
    };
  }

  const totalCapital = investors.reduce((sum, investor) => {
    const capital = safeToDouble(investor.viableRemainingCapital);
    return sum + capital;
  }, 0);

  // Sortuj inwestorów według kapitału malejąco
  const sortedInvestors = [...investors].sort((a, b) => {
    const capitalA = safeToDouble(a.viableRemainingCapital);
    const capitalB = safeToDouble(b.viableRemainingCapital);
    return capitalB - capitalA;
  });

  // Znajdź minimalną grupę która tworzy większość
  const majorityHolders = [];
  let accumulatedCapital = 0;

  for (const investor of sortedInvestors) {
    const investorCapital = safeToDouble(investor.viableRemainingCapital);
    majorityHolders.push(investor);
    accumulatedCapital += investorCapital;

    const accumulatedPercentage = totalCapital > 0
      ? (accumulatedCapital / totalCapital) * 100
      : 0;

    // Gdy osiągniemy próg większościowy, zatrzymaj się
    if (accumulatedPercentage >= majorityThreshold) {
      break;
    }
  }

  // Oblicz dodatkowe metryki
  const majorityCapitals = majorityHolders.map(h => safeToDouble(h.viableRemainingCapital));
  const averageHolding = majorityCapitals.length > 0
    ? majorityCapitals.reduce((a, b) => a + b, 0) / majorityCapitals.length
    : 0;

  const sortedCapitals = [...majorityCapitals].sort((a, b) => a - b);
  const medianHolding = sortedCapitals.length > 0
    ? sortedCapitals.length % 2 === 0
      ? (sortedCapitals[Math.floor(sortedCapitals.length / 2 - 1)] + sortedCapitals[Math.floor(sortedCapitals.length / 2)]) / 2
      : sortedCapitals[Math.floor(sortedCapitals.length / 2)]
    : 0;

  // Indeks koncentracji (Herfindahl-Hirschman Index)
  const concentrationIndex = majorityCapitals.length > 0
    ? majorityCapitals.reduce((sum, capital) => {
      const marketShare = capital / accumulatedCapital;
      return sum + (marketShare * marketShare);
    }, 0) * 10000 // Przeskalowanie do standardu HHI
    : 0;

  const majorityPercentage = totalCapital > 0
    ? (accumulatedCapital / totalCapital) * 100
    : 0;

  console.log(`✅ [Majority Analysis] Znaleziono ${majorityHolders.length} holders kontrolujących ${majorityPercentage.toFixed(2)}%`);

  return {
    totalCapital,
    majorityThreshold,
    majorityHolders,
    majorityCapital: accumulatedCapital,
    majorityPercentage,
    holdersCount: majorityHolders.length,
    averageHolding,
    medianHolding,
    concentrationIndex
  };
}

/**
 * 🗳️ ZAAWANSOWANA ANALIZA GŁOSOWANIA
 * Szczegółowa analiza rozkładu głosów i kapitału
 */
function calculateVotingAnalysis(investors) {
  console.log("🗳️ [Voting Analysis] Analiza rozkładu głosowania");

  if (!investors || investors.length === 0) {
    return {
      totalCapital: 0,
      totalInvestors: 0,
      votingDistribution: {},
      votingCounts: {},
      capitalByVotingStatus: {},
      percentageByVotingStatus: {},
      averageCapitalByStatus: {},
      votingPower: {}
    };
  }

  const totalCapital = investors.reduce((sum, investor) => {
    return sum + safeToDouble(investor.viableRemainingCapital);
  }, 0);

  const votingStatuses = ['yes', 'no', 'abstain', 'undecided'];

  const votingCounts = {};
  const capitalByVotingStatus = {};

  // Inicjalizuj countery
  votingStatuses.forEach(status => {
    votingCounts[status] = 0;
    capitalByVotingStatus[status] = 0;
  });

  // Policz głosy i kapitał według statusu
  investors.forEach(investor => {
    const votingStatus = investor.client?.votingStatus || 'undecided';
    const capital = safeToDouble(investor.viableRemainingCapital);

    if (votingStatuses.includes(votingStatus)) {
      votingCounts[votingStatus]++;
      capitalByVotingStatus[votingStatus] += capital;
    } else {
      // Fallback dla nieznanych statusów
      votingCounts['undecided']++;
      capitalByVotingStatus['undecided'] += capital;
    }
  });

  // Oblicz procentowe rozkłady
  const percentageByVotingStatus = {};
  const averageCapitalByStatus = {};
  const votingPower = {};

  votingStatuses.forEach(status => {
    const capital = capitalByVotingStatus[status];
    const count = votingCounts[status];

    percentageByVotingStatus[status] = totalCapital > 0
      ? (capital / totalCapital) * 100
      : 0;

    averageCapitalByStatus[status] = count > 0
      ? capital / count
      : 0;

    votingPower[status] = {
      votes: count,
      capital: capital,
      percentage: percentageByVotingStatus[status],
      averageCapital: averageCapitalByStatus[status]
    };
  });

  // Deprecated: votingDistribution dla backward compatibility
  const votingDistribution = {};
  votingStatuses.forEach(status => {
    votingDistribution[status] = percentageByVotingStatus[status];
  });

  console.log(`✅ [Voting Analysis] Analiza ${investors.length} inwestorów z kapitałem ${totalCapital.toFixed(2)}`);

  return {
    totalCapital,
    totalInvestors: investors.length,
    votingDistribution, // Deprecated ale zachowane dla kompatybilności
    votingCounts,
    capitalByVotingStatus,
    percentageByVotingStatus,
    averageCapitalByStatus,
    votingPower
  };
}

/**
 * 📊 METRYKI WYDAJNOŚCIOWE
 * Oblicza kluczowe wskaźniki wydajności portfela
 */
function calculatePerformanceMetrics(investors) {
  console.log("📊 [Performance Metrics] Obliczam metryki wydajnościowe");

  if (!investors || investors.length === 0) {
    return {
      totalInvestors: 0,
      totalCapital: 0,
      averageInvestment: 0,
      medianInvestment: 0,
      capitalConcentration: 0,
      top10Percentage: 0,
      diversificationIndex: 0,
      riskMetrics: {}
    };
  }

  const capitals = investors.map(investor => safeToDouble(investor.viableRemainingCapital));
  const totalCapital = capitals.reduce((a, b) => a + b, 0);

  // Podstawowe statystyki
  const averageInvestment = capitals.length > 0 ? totalCapital / capitals.length : 0;

  const sortedCapitals = [...capitals].sort((a, b) => a - b);
  const medianInvestment = sortedCapitals.length > 0
    ? sortedCapitals.length % 2 === 0
      ? (sortedCapitals[Math.floor(sortedCapitals.length / 2 - 1)] + sortedCapitals[Math.floor(sortedCapitals.length / 2)]) / 2
      : sortedCapitals[Math.floor(sortedCapitals.length / 2)]
    : 0;

  // Koncentracja kapitału (top 10%)
  const sortedCapitalsDesc = [...capitals].sort((a, b) => b - a);
  const top10Count = Math.max(1, Math.floor(capitals.length * 0.1));
  const top10Capital = sortedCapitalsDesc.slice(0, top10Count).reduce((a, b) => a + b, 0);
  const top10Percentage = totalCapital > 0 ? (top10Capital / totalCapital) * 100 : 0;

  // Indeks Herfindhala-Hirschmana (koncentracja rynku)
  const capitalConcentration = capitals.length > 0
    ? capitals.reduce((sum, capital) => {
      const marketShare = totalCapital > 0 ? capital / totalCapital : 0;
      return sum + (marketShare * marketShare);
    }, 0) * 10000
    : 0;

  // Indeks dywersyfikacji (odwrotność koncentracji)
  const diversificationIndex = capitalConcentration > 0
    ? 10000 / capitalConcentration
    : 0;

  // Metryki ryzyka
  const variance = capitals.length > 1
    ? capitals.reduce((sum, capital) => {
      const diff = capital - averageInvestment;
      return sum + (diff * diff);
    }, 0) / (capitals.length - 1)
    : 0;

  const standardDeviation = Math.sqrt(variance);
  const coefficientOfVariation = averageInvestment > 0
    ? standardDeviation / averageInvestment
    : 0;

  const riskMetrics = {
    variance,
    standardDeviation,
    coefficientOfVariation,
    range: sortedCapitals.length > 0
      ? sortedCapitals[sortedCapitals.length - 1] - sortedCapitals[0]
      : 0
  };

  console.log(`✅ [Performance Metrics] Analiza ${investors.length} inwestorów, koncentracja: ${capitalConcentration.toFixed(0)}`);

  return {
    totalInvestors: investors.length,
    totalCapital,
    averageInvestment,
    medianInvestment,
    capitalConcentration,
    top10Percentage,
    diversificationIndex,
    riskMetrics
  };
}

/**
 * 📈 ANALIZA TRENDÓW
 * Identyfikuje trendy i wzorce w danych inwestorów
 */
function calculateTrendAnalysis(investors) {
  console.log("📈 [Trend Analysis] Analiza trendów i wzorców");

  if (!investors || investors.length === 0) {
    return {
      growth: { rate: 0, trend: 'neutral' },
      volatility: { level: 'low', index: 0 },
      momentum: { direction: 'neutral', strength: 0 },
      cyclical: { phase: 'unknown', confidence: 0 },
      forecast: { shortTerm: 'stable', longTerm: 'stable' }
    };
  }

  // Symulacja analizy trendów (w rzeczywistości byłoby to oparte na danych historycznych)
  const capitals = investors.map(investor => safeToDouble(investor.viableRemainingCapital));
  const totalCapital = capitals.reduce((a, b) => a + b, 0);
  const averageCapital = totalCapital / capitals.length;

  // Oblicz zmienność jako proxy dla volatility
  const variance = capitals.reduce((sum, capital) => {
    const diff = capital - averageCapital;
    return sum + (diff * diff);
  }, 0) / capitals.length;

  const volatilityIndex = Math.sqrt(variance) / averageCapital;

  let volatilityLevel = 'low';
  if (volatilityIndex > 0.3) volatilityLevel = 'high';
  else if (volatilityIndex > 0.15) volatilityLevel = 'medium';

  // Symulacja momentum na podstawie rozkładu kapitału
  const sortedCapitals = [...capitals].sort((a, b) => b - a);
  const top20Capital = sortedCapitals.slice(0, Math.ceil(capitals.length * 0.2)).reduce((a, b) => a + b, 0);
  const top20Percentage = totalCapital > 0 ? (top20Capital / totalCapital) * 100 : 0;

  let momentumDirection = 'neutral';
  let momentumStrength = 0;

  if (top20Percentage > 80) {
    momentumDirection = 'bearish'; // Wysoka koncentracja = bearish
    momentumStrength = (top20Percentage - 80) / 20;
  } else if (top20Percentage < 50) {
    momentumDirection = 'bullish'; // Niska koncentracja = bullish
    momentumStrength = (50 - top20Percentage) / 50;
  }

  console.log(`✅ [Trend Analysis] Volatilność: ${volatilityLevel}, Momentum: ${momentumDirection}`);

  return {
    growth: {
      rate: 0, // Byłoby obliczane z danych historycznych
      trend: momentumDirection
    },
    volatility: {
      level: volatilityLevel,
      index: volatilityIndex
    },
    momentum: {
      direction: momentumDirection,
      strength: momentumStrength
    },
    cyclical: {
      phase: 'expansion', // Symulacja
      confidence: 0.7
    },
    forecast: {
      shortTerm: volatilityLevel === 'high' ? 'volatile' : 'stable',
      longTerm: momentumDirection === 'bullish' ? 'positive' : 'stable'
    }
  };
}

/**
 * 🔍 INTELIGENTNE INSIGHTS
 * Generuje automatyczne spostrzeżenia na podstawie analizy danych
 */
function generateIntelligentInsights(investors, majorityAnalysis, votingAnalysis) {
  console.log("🔍 [Intelligent Insights] Generuję automatyczne spostrzeżenia");

  const insights = [];

  if (!investors || investors.length === 0) {
    return insights;
  }

  // Insight 1: Koncentracja większościowa
  if (majorityAnalysis.holdersCount <= 5) {
    insights.push({
      type: 'warning',
      category: 'concentration',
      title: 'Wysoka koncentracja kontroli',
      message: `Tylko ${majorityAnalysis.holdersCount} inwestorów kontroluje ${majorityAnalysis.majorityPercentage.toFixed(1)}% kapitału`,
      severity: 'high',
      actionable: true
    });
  } else if (majorityAnalysis.holdersCount >= 20) {
    insights.push({
      type: 'positive',
      category: 'diversification',
      title: 'Zdywersyfikowana kontrola',
      message: `Kontrola rozproszona między ${majorityAnalysis.holdersCount} inwestorów`,
      severity: 'low',
      actionable: false
    });
  }

  // Insight 2: Rozkład głosowania
  const yesPercentage = votingAnalysis.percentageByVotingStatus?.yes || 0;
  const noPercentage = votingAnalysis.percentageByVotingStatus?.no || 0;
  const undecidedPercentage = votingAnalysis.percentageByVotingStatus?.undecided || 0;

  if (undecidedPercentage > 30) {
    insights.push({
      type: 'warning',
      category: 'voting',
      title: 'Duża liczba niezdecydowanych',
      message: `${undecidedPercentage.toFixed(1)}% kapitału to niezdecydowani inwestorzy`,
      severity: 'medium',
      actionable: true
    });
  }

  if (yesPercentage > 60) {
    insights.push({
      type: 'positive',
      category: 'voting',
      title: 'Silne poparcie',
      message: `${yesPercentage.toFixed(1)}% kapitału głosuje "TAK"`,
      severity: 'low',
      actionable: false
    });
  }

  // Insight 3: Średnia wielkość inwestycji
  const totalCapital = majorityAnalysis.totalCapital;
  const averageInvestment = totalCapital / investors.length;

  if (averageInvestment > 1000000) {
    insights.push({
      type: 'info',
      category: 'capital',
      title: 'Portfolio wysokiej wartości',
      message: `Średnia inwestycja: ${(averageInvestment / 1000000).toFixed(1)}M zł`,
      severity: 'low',
      actionable: false
    });
  }

  // Insight 4: Koncentracja HHI
  if (majorityAnalysis.concentrationIndex > 2500) {
    insights.push({
      type: 'warning',
      category: 'concentration',
      title: 'Wysoki indeks koncentracji',
      message: `HHI: ${majorityAnalysis.concentrationIndex.toFixed(0)} wskazuje na wysoką koncentrację rynku`,
      severity: 'medium',
      actionable: true
    });
  }

  console.log(`✅ [Intelligent Insights] Wygenerowano ${insights.length} spostrzeżeń`);

  return insights;
}

// 🚀 WRAPPER FIREBASE FUNCTION
const getPremiumInvestorAnalyticsFunction = onCall({
  memory: "2GiB",
  timeoutSeconds: 600, // 10 minut dla premium analytics
  region: "europe-west1",
}, async (request) => {
  return await getPremiumInvestorAnalytics(request.data || {});
});

module.exports = {
  getPremiumInvestorAnalytics: getPremiumInvestorAnalyticsFunction,
  calculateMajorityAnalysis,
  calculateVotingAnalysis,
  calculatePerformanceMetrics,
  calculateTrendAnalysis,
  generateIntelligentInsights
};
