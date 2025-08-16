// DASHBOARD SPECIALIZED METRICS
// Funkcje specjalistyczne dla poszczególnych zakładek dashboard

const { onCall } = require("firebase-functions/v2/https");
// const { setGlobalOptions } = require("firebase-functions/v2"); // Moved to index.js
const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { safeToDouble, safeToString, parseDate } = require("./utils/data-mapping");
const { calculateCapitalSecuredByRealEstate } = require("./utils/unified-statistics");

// Set global options for all functions - moved to index.js
// setGlobalOptions({
//   region: "europe-west1",
//   cors: true, // Enable CORS for all functions
// });

/**
 * 📊 FUNKCJA: Dashboard Performance Tab Metrics
 * Oblicza szczegółowe metryki wydajności dla zakładki Performance
 */
exports.getDashboardPerformanceMetrics = onCall({
  memory: "1GiB",
  timeoutSeconds: 300,
}, async (request) => {
  const startTime = Date.now();
  console.log("📈 [Performance] Rozpoczynam obliczanie metryk wydajności...");

  try {
    const db = admin.firestore(); // Initialize db inside function
    const { forceRefresh = false, timePeriod = "all" } = request.data || {};
    const cacheKey = `dashboard_performance_${timePeriod}`;

    if (!forceRefresh) {
      const cached = await getCachedResult(cacheKey);
      if (cached) return cached;
    }

    // Pobierz wszystkie inwestycje
    const allInvestments = await getAllInvestmentsUnified(db);

    // Filtruj według okresu czasu
    const filteredInvestments = filterByTimePeriod(allInvestments, timePeriod);

    // Oblicz metryki wydajności
    const metrics = {
      portfolioReturns: calculatePortfolioReturns(filteredInvestments),
      productTypePerformance: calculateProductTypePerformance(filteredInvestments),
      riskReturnAnalysis: calculateRiskReturnAnalysis(filteredInvestments),
      performanceAttribution: calculatePerformanceAttribution(filteredInvestments),
      benchmarkComparison: calculateBenchmarkComparison(filteredInvestments),
      timeSeriesPerformance: calculateTimeSeriesPerformance(filteredInvestments),
      outliersAnalysis: calculateOutliersAnalysis(filteredInvestments),
      correlationMatrix: calculateCorrelationMatrix(filteredInvestments),
      executionTime: Date.now() - startTime,
      dataPoints: filteredInvestments.length,
      timestamp: new Date().toISOString(),
    };

    await setCachedResult(cacheKey, metrics, 180); // 3 minuty cache
    console.log(`✅ [Performance] Metryki obliczone w ${metrics.executionTime}ms`);

    return metrics;
  } catch (error) {
    console.error("❌ [Performance] Błąd:", error);
    throw new HttpsError(
      "internal",
      "Błąd podczas obliczania metryk wydajności",
      error.message,
    );
  }
});

/**
 * 📊 FUNKCJA: Dashboard Risk Analysis Metrics
 * Oblicza szczegółowe metryki ryzyka dla zakładki Risk
 */
exports.getDashboardRiskMetrics = onCall({
  memory: "1GiB",
  timeoutSeconds: 300,
}, async (request) => {
  const startTime = Date.now();
  console.log("⚠️ [Risk] Rozpoczynam analizę ryzyka...");

  try {
    const db = admin.firestore(); // Initialize db inside function
    const { forceRefresh = false, riskProfile = "moderate" } = request.data || {};
    const cacheKey = `dashboard_risk_${riskProfile}`;

    if (!forceRefresh) {
      const cached = await getCachedResult(cacheKey);
      if (cached) return cached;
    }

    const allInvestments = await getAllInvestmentsUnified(db);

    const metrics = {
      portfolioRiskMetrics: calculatePortfolioRiskMetrics(allInvestments),
      concentrationRisk: calculateDetailedConcentrationRisk(allInvestments),
      liquidityRisk: calculateLiquidityRiskBreakdown(allInvestments),
      creditRisk: calculateCreditRiskAnalysis(allInvestments),
      marketRisk: calculateMarketRiskExposure(allInvestments),
      operationalRisk: calculateOperationalRisk(allInvestments),
      stressTestResults: performStressTesting(allInvestments),
      riskBudgetAnalysis: calculateRiskBudgetAnalysis(allInvestments, riskProfile),
      riskMatrix: generateRiskMatrix(allInvestments),
      varAnalysis: calculateVaRAnalysis(allInvestments),
      scenarioAnalysis: performScenarioAnalysis(allInvestments),
      executionTime: Date.now() - startTime,
      timestamp: new Date().toISOString(),
    };

    await setCachedResult(cacheKey, metrics, 180);
    console.log(`✅ [Risk] Analiza ryzyka zakończona w ${metrics.executionTime}ms`);

    return metrics;
  } catch (error) {
    console.error("❌ [Risk] Błąd:", error);
    throw new HttpsError(
      "internal",
      "Błąd podczas analizy ryzyka",
      error.message,
    );
  }
});

/**
 * 📊 FUNKCJA: Dashboard Predictions Metrics
 * Oblicza predykcje i prognozy dla zakładki Predictions
 */
exports.getDashboardPredictions = onCall({
  memory: "1GiB",
  timeoutSeconds: 300,
}, async (request) => {
  const startTime = Date.now();
  console.log("🔮 [Predictions] Rozpoczynam analizę predykcyjną...");

  try {
    const db = admin.firestore(); // Initialize db inside function
    const { forceRefresh = false, horizon = 12 } = request.data || {}; // horizon in months
    const cacheKey = `dashboard_predictions_${horizon}`;

    if (!forceRefresh) {
      const cached = await getCachedResult(cacheKey);
      if (cached) return cached;
    }

    const allInvestments = await getAllInvestmentsUnified(db);

    const metrics = {
      returnPredictions: calculateReturnPredictions(allInvestments, horizon),
      portfolioOptimization: calculateOptimalAllocation(allInvestments),
      riskPredictions: calculateRiskPredictions(allInvestments, horizon),
      maturityForecast: calculateMaturityForecast(allInvestments),
      trendAnalysis: calculateTrendAnalysis(allInvestments),
      seasonalityAnalysis: calculateSeasonalityAnalysis(allInvestments),
      monteCarlo: performMonteCarloSimulation(allInvestments, horizon),
      opportunityAnalysis: identifyInvestmentOpportunities(allInvestments),
      recommendedActions: generateInvestmentRecommendations(allInvestments),
      confidenceIntervals: calculateConfidenceIntervals(allInvestments),
      executionTime: Date.now() - startTime,
      timestamp: new Date().toISOString(),
    };

    await setCachedResult(cacheKey, metrics, 300); // 5 minut cache dla predykcji
    console.log(`✅ [Predictions] Analiza predykcyjna zakończona w ${metrics.executionTime}ms`);

    return metrics;
  } catch (error) {
    console.error("❌ [Predictions] Błąd:", error);
    throw new HttpsError(
      "internal",
      "Błąd podczas analizy predykcyjnej",
      error.message,
    );
  }
});

/**
 * 📊 FUNKCJA: Dashboard Benchmark Metrics
 * Oblicza porównania z benchmarkami dla zakładki Benchmark
 */
exports.getDashboardBenchmarks = onCall({
  memory: "1GiB",
  timeoutSeconds: 300,
}, async (request) => {
  const startTime = Date.now();
  console.log("📊 [Benchmark] Rozpoczynam analizę benchmarków...");

  try {
    const db = admin.firestore(); // Initialize db inside function
    const { forceRefresh = false, benchmarkType = "market" } = request.data || {};
    const cacheKey = `dashboard_benchmarks_${benchmarkType}`;

    if (!forceRefresh) {
      const cached = await getCachedResult(cacheKey);
      if (cached) return cached;
    }

    const allInvestments = await getAllInvestmentsUnified(db);

    const metrics = {
      marketBenchmarks: calculateMarketBenchmarks(allInvestments, benchmarkType),
      industryComparison: calculateIndustryComparison(allInvestments),
      peerAnalysis: calculatePeerAnalysis(allInvestments),
      indexComparison: calculateIndexComparison(allInvestments),
      relativePerformance: calculateRelativePerformance(allInvestments),
      attributionAnalysis: calculateAttributionAnalysis(allInvestments),
      trackingError: calculateTrackingError(allInvestments),
      informationRatio: calculateInformationRatio(allInvestments),
      alpha: calculateAlpha(allInvestments),
      beta: calculateBeta(allInvestments),
      executionTime: Date.now() - startTime,
      timestamp: new Date().toISOString(),
    };

    await setCachedResult(cacheKey, metrics, 240); // 4 minuty cache
    console.log(`✅ [Benchmark] Analiza benchmarków zakończona w ${metrics.executionTime}ms`);

    return metrics;
  } catch (error) {
    console.error("❌ [Benchmark] Błąd:", error);
    throw new HttpsError(
      "internal",
      "Błąd podczas analizy benchmarków",
      error.message,
    );
  }
});

// 🛠️ HELPER FUNCTIONS

/**
 * Pobiera wszystkie inwestycje w zunifikowanym formacie
 */
async function getAllInvestmentsUnified(db) {
  const [
    investmentsSnapshot,
    bondsSnapshot,
    sharesSnapshot,
    loansSnapshot,
    apartmentsSnapshot,
  ] = await Promise.all([
    db.collection("investments").get(),
    db.collection("bonds").get(),
    db.collection("shares").get(),
    db.collection("loans").get(),
    db.collection("apartments").get(),
  ]);

  const allInvestments = [];

  // Użyj funkcji konwersji z advanced-analytics.js
  investmentsSnapshot.docs.forEach((doc) => {
    allInvestments.push(convertExcelDataToInvestment(doc.id, doc.data()));
  });

  bondsSnapshot.docs.forEach((doc) => {
    allInvestments.push(convertBondToInvestment(doc.id, doc.data()));
  });

  sharesSnapshot.docs.forEach((doc) => {
    allInvestments.push(convertShareToInvestment(doc.id, doc.data()));
  });

  loansSnapshot.docs.forEach((doc) => {
    allInvestments.push(convertLoanToInvestment(doc.id, doc.data()));
  });

  apartmentsSnapshot.docs.forEach((doc) => {
    allInvestments.push(convertApartmentToInvestment(doc.id, doc.data()));
  });

  return allInvestments;
}

/**
 * Filtruje inwestycje według okresu czasu
 */
function filterByTimePeriod(investments, timePeriod) {
  if (timePeriod === "all") return investments;

  const now = new Date();
  let cutoffDate;

  switch (timePeriod) {
    case "1m":
      cutoffDate = new Date(now.setMonth(now.getMonth() - 1));
      break;
    case "3m":
      cutoffDate = new Date(now.setMonth(now.getMonth() - 3));
      break;
    case "6m":
      cutoffDate = new Date(now.setMonth(now.getMonth() - 6));
      break;
    case "1y":
      cutoffDate = new Date(now.setFullYear(now.getFullYear() - 1));
      break;
    case "2y":
      cutoffDate = new Date(now.setFullYear(now.getFullYear() - 2));
      break;
    default:
      return investments;
  }

  return investments.filter((inv) => new Date(inv.signedDate) >= cutoffDate);
}

// 📈 PERFORMANCE CALCULATION FUNCTIONS

function calculatePortfolioReturns(investments) {
  if (investments.length === 0) {
    return {
      totalReturn: 0,
      annualizedReturn: 0,
      geometricMean: 0,
      arithmeticMean: 0,
      volatility: 0,
      maxDrawdown: 0,
    };
  }

  const returns = investments.map((inv) => inv.profitLossPercentage);
  const totalInvested = investments.reduce((sum, inv) => sum + inv.investmentAmount, 0);
  const totalCurrent = investments.reduce((sum, inv) => sum + inv.totalValue, 0);

  const totalReturn = totalInvested > 0 ? ((totalCurrent - totalInvested) / totalInvested) * 100 : 0;
  const arithmeticMean = returns.length > 0 ? returns.reduce((a, b) => a + b) / returns.length : 0;

  // Geometric mean calculation
  const geometricProduct = returns.reduce((product, ret) => product * (1 + ret / 100), 1);
  const geometricMean = returns.length > 0 ? (Math.pow(geometricProduct, 1 / returns.length) - 1) * 100 : 0;

  // Volatility (standard deviation)
  const variance = returns.length > 1 ?
    returns.map((r) => Math.pow(r - arithmeticMean, 2)).reduce((a, b) => a + b) / (returns.length - 1) : 0;
  const volatility = Math.sqrt(variance);

  // Annualized return based on average holding period
  const now = new Date();
  const avgHoldingPeriod = investments
    .map((inv) => (now - new Date(inv.signedDate)) / (365.25 * 24 * 60 * 60 * 1000))
    .reduce((a, b) => a + b) / investments.length;

  const annualizedReturn = avgHoldingPeriod > 0 ?
    (Math.pow(1 + totalReturn / 100, 1 / avgHoldingPeriod) - 1) * 100 : totalReturn;

  // Max drawdown calculation
  const sortedByDate = [...investments].sort((a, b) => new Date(a.signedDate) - new Date(b.signedDate));
  let peak = 0;
  let maxDrawdown = 0;
  let runningValue = 0;

  for (const investment of sortedByDate) {
    runningValue += investment.totalValue;
    if (runningValue > peak) peak = runningValue;
    const drawdown = peak > 0 ? (peak - runningValue) / peak * 100 : 0;
    if (drawdown > maxDrawdown) maxDrawdown = drawdown;
  }

  return {
    totalReturn,
    annualizedReturn,
    geometricMean,
    arithmeticMean,
    volatility,
    maxDrawdown,
  };
}

function calculateProductTypePerformance(investments) {
  const productGroups = {};

  investments.forEach((investment) => {
    if (!productGroups[investment.productType]) {
      productGroups[investment.productType] = [];
    }
    productGroups[investment.productType].push(investment);
  });

  const performance = {};

  Object.keys(productGroups).forEach((type) => {
    const typeInvestments = productGroups[type];
    const returns = typeInvestments.map((inv) => inv.profitLossPercentage);
    const totalInvested = typeInvestments.reduce((sum, inv) => sum + inv.investmentAmount, 0);
    const totalCurrent = typeInvestments.reduce((sum, inv) => sum + inv.totalValue, 0);

    performance[type] = {
      totalReturn: totalInvested > 0 ? ((totalCurrent - totalInvested) / totalInvested) * 100 : 0,
      averageReturn: returns.length > 0 ? returns.reduce((a, b) => a + b) / returns.length : 0,
      volatility: calculateVolatility(returns),
      sharpeRatio: calculateSharpeRatio(returns),
      count: typeInvestments.length,
      totalValue: totalCurrent,
      totalInvested: totalInvested,
      successRate: typeInvestments.filter((inv) => inv.profitLoss > 0).length / typeInvestments.length * 100,
    };
  });

  return performance;
}

function calculateRiskReturnAnalysis(investments) {
  const riskReturnPoints = investments.map((investment) => ({
    id: investment.id,
    productType: investment.productType,
    risk: Math.abs(investment.profitLossPercentage - 5.0), // Risk as deviation from 5% expected return
    return: investment.profitLossPercentage,
    value: investment.totalValue,
    clientName: investment.clientName,
  }));

  // Efficient frontier calculation (simplified)
  const productRiskReturn = {};
  investments.forEach((inv) => {
    if (!productRiskReturn[inv.productType]) {
      productRiskReturn[inv.productType] = { risks: [], returns: [] };
    }
    productRiskReturn[inv.productType].risks.push(Math.abs(inv.profitLossPercentage - 5.0));
    productRiskReturn[inv.productType].returns.push(inv.profitLossPercentage);
  });

  const efficientFrontier = Object.keys(productRiskReturn).map((type) => {
    const data = productRiskReturn[type];
    const avgRisk = data.risks.reduce((a, b) => a + b) / data.risks.length;
    const avgReturn = data.returns.reduce((a, b) => a + b) / data.returns.length;

    return {
      productType: type,
      risk: avgRisk,
      return: avgReturn,
      sharpeRatio: avgRisk > 0 ? (avgReturn - 2.0) / avgRisk : 0, // Risk-free rate = 2%
    };
  });

  return {
    scatterData: riskReturnPoints,
    efficientFrontier: efficientFrontier,
    optimalPortfolio: efficientFrontier.reduce((best, current) =>
      current.sharpeRatio > best.sharpeRatio ? current : best, efficientFrontier[0] || {}),
  };
}

function calculatePerformanceAttribution(investments) {
  const totalInvested = investments.reduce((sum, inv) => sum + inv.investmentAmount, 0);
  const totalReturn = investments.reduce((sum, inv) => sum + inv.profitLoss, 0);

  const attributions = {};

  investments.forEach((investment) => {
    const weight = totalInvested > 0 ? investment.investmentAmount / totalInvested : 0;
    const contribution = weight * investment.profitLossPercentage;

    if (!attributions[investment.productType]) {
      attributions[investment.productType] = {
        allocation: 0,
        selection: 0,
        interaction: 0,
        totalContribution: 0,
      };
    }

    attributions[investment.productType].totalContribution += contribution;
    attributions[investment.productType].allocation += weight * 100;
  });

  return {
    attributions,
    totalAttribution: Object.values(attributions).reduce((sum, attr) => sum + attr.totalContribution, 0),
  };
}

function calculateBenchmarkComparison(investments) {
  // Define benchmark returns for different product types
  const benchmarks = {
    bonds: 4.5, // 4.5% for bonds
    shares: 8.0, // 8.0% for shares
    loans: 6.0, // 6.0% for loans
    apartments: 5.5, // 5.5% for apartments
    market: 6.0, // Overall market benchmark
  };

  const portfolioReturn = investments.length > 0 ?
    investments.reduce((sum, inv) => sum + inv.profitLossPercentage, 0) / investments.length : 0;

  const comparison = {};

  Object.keys(benchmarks).forEach((key) => {
    if (key === "market") {
      comparison[key] = {
        benchmark: benchmarks[key],
        portfolio: portfolioReturn,
        outperformance: portfolioReturn - benchmarks[key],
        trackingError: calculateVolatility(investments.map((inv) => inv.profitLossPercentage - benchmarks[key])),
      };
    } else {
      const productInvestments = investments.filter((inv) => inv.productType === key);
      if (productInvestments.length > 0) {
        const productReturn = productInvestments.reduce((sum, inv) => sum + inv.profitLossPercentage, 0) / productInvestments.length;
        comparison[key] = {
          benchmark: benchmarks[key],
          portfolio: productReturn,
          outperformance: productReturn - benchmarks[key],
          trackingError: calculateVolatility(productInvestments.map((inv) => inv.profitLossPercentage - benchmarks[key])),
        };
      }
    }
  });

  return comparison;
}

function calculateTimeSeriesPerformance(investments) {
  // Group investments by month
  const monthlyGroups = {};

  investments.forEach((investment) => {
    const date = new Date(investment.signedDate);
    const monthKey = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;

    if (!monthlyGroups[monthKey]) {
      monthlyGroups[monthKey] = [];
    }
    monthlyGroups[monthKey].push(investment);
  });

  const monthlyData = Object.keys(monthlyGroups)
    .sort()
    .map((month) => {
      const monthInvestments = monthlyGroups[month];
      const totalInvested = monthInvestments.reduce((sum, inv) => sum + inv.investmentAmount, 0);
      const totalCurrent = monthInvestments.reduce((sum, inv) => sum + inv.totalValue, 0);
      const averageReturn = monthInvestments.reduce((sum, inv) => sum + inv.profitLossPercentage, 0) / monthInvestments.length;

      return {
        month,
        totalInvested,
        totalCurrent,
        averageReturn,
        count: monthInvestments.length,
        cumulativeReturn: totalInvested > 0 ? ((totalCurrent - totalInvested) / totalInvested) * 100 : 0,
      };
    });

  // Calculate rolling returns
  const rollingReturns = monthlyData.map((data, index) => {
    if (index < 11) return { ...data, rolling12Month: null };

    const last12Months = monthlyData.slice(index - 11, index + 1);
    const totalInvested12M = last12Months.reduce((sum, m) => sum + m.totalInvested, 0);
    const totalCurrent12M = last12Months.reduce((sum, m) => sum + m.totalCurrent, 0);

    return {
      ...data,
      rolling12Month: totalInvested12M > 0 ? ((totalCurrent12M - totalInvested12M) / totalInvested12M) * 100 : 0,
    };
  });

  return {
    monthlyData: rollingReturns,
    latestMonth: rollingReturns[rollingReturns.length - 1] || null,
    trend: calculateTrendDirection(rollingReturns),
  };
}

function calculateTrendDirection(data) {
  if (data.length < 3) return "neutral";

  const recent = data.slice(-3);
  const returns = recent.map((d) => d.averageReturn);

  if (returns[2] > returns[1] && returns[1] > returns[0]) return "up";
  if (returns[2] < returns[1] && returns[1] < returns[0]) return "down";
  return "neutral";
}

function calculateOutliersAnalysis(investments) {
  const returns = investments.map((inv) => inv.profitLossPercentage);

  if (returns.length === 0) {
    return { outliers: [], statisticalSummary: {} };
  }

  const sorted = [...returns].sort((a, b) => a - b);
  const q1 = sorted[Math.floor(sorted.length * 0.25)];
  const q3 = sorted[Math.floor(sorted.length * 0.75)];
  const iqr = q3 - q1;

  const lowerBound = q1 - 1.5 * iqr;
  const upperBound = q3 + 1.5 * iqr;

  const outliers = investments.filter((inv) =>
    inv.profitLossPercentage < lowerBound || inv.profitLossPercentage > upperBound,
  ).map((inv) => ({
    id: inv.id,
    clientName: inv.clientName,
    productType: inv.productType,
    return: inv.profitLossPercentage,
    value: inv.totalValue,
    type: inv.profitLossPercentage < lowerBound ? "underperformer" : "overperformer",
  }));

  return {
    outliers,
    statisticalSummary: {
      q1,
      median: sorted[Math.floor(sorted.length * 0.5)],
      q3,
      iqr,
      lowerBound,
      upperBound,
      outliersCount: outliers.length,
      totalCount: investments.length,
    },
  };
}

function calculateCorrelationMatrix(investments) {
  const productTypes = [...new Set(investments.map((inv) => inv.productType))];
  const correlations = {};

  productTypes.forEach((type1) => {
    correlations[type1] = {};

    productTypes.forEach((type2) => {
      const returns1 = investments
        .filter((inv) => inv.productType === type1)
        .map((inv) => inv.profitLossPercentage);

      const returns2 = investments
        .filter((inv) => inv.productType === type2)
        .map((inv) => inv.profitLossPercentage);

      if (returns1.length > 0 && returns2.length > 0) {
        correlations[type1][type2] = calculateCorrelation(returns1, returns2);
      } else {
        correlations[type1][type2] = 0;
      }
    });
  });

  return correlations;
}

function calculateCorrelation(returns1, returns2) {
  if (returns1.length !== returns2.length || returns1.length === 0) return 0;

  const mean1 = returns1.reduce((a, b) => a + b) / returns1.length;
  const mean2 = returns2.reduce((a, b) => a + b) / returns2.length;

  let numerator = 0;
  let sum1Sq = 0;
  let sum2Sq = 0;

  for (let i = 0; i < returns1.length; i++) {
    const diff1 = returns1[i] - mean1;
    const diff2 = returns2[i] - mean2;
    numerator += diff1 * diff2;
    sum1Sq += diff1 * diff1;
    sum2Sq += diff2 * diff2;
  }

  const denominator = Math.sqrt(sum1Sq * sum2Sq);
  return denominator === 0 ? 0 : numerator / denominator;
}

// ⚠️ RISK CALCULATION FUNCTIONS

function calculatePortfolioRiskMetrics(investments) {
  const returns = investments.map((inv) => inv.profitLossPercentage);

  return {
    volatility: calculateVolatility(returns),
    var95: calculateVaR(returns, 0.05),
    var99: calculateVaR(returns, 0.01),
    cvar95: calculateConditionalVaR(returns, 0.05),
    maxDrawdown: calculateMaxDrawdown(investments),
    sharpeRatio: calculateSharpeRatio(returns),
    sortinoRatio: calculateSortinoRatio(returns),
    calmarRatio: calculateCalmarRatio(returns, calculateMaxDrawdown(investments)),
    skewness: calculateSkewness(returns),
    kurtosis: calculateKurtosis(returns),
  };
}

function calculateDetailedConcentrationRisk(investments) {
  const concentrations = {
    byProductType: {},
    byClient: {},
    byEmployee: {},
    byValue: [],
  };

  const totalValue = investments.reduce((sum, inv) => sum + inv.totalValue, 0);

  // Concentration by product type
  investments.forEach((inv) => {
    concentrations.byProductType[inv.productType] =
      (concentrations.byProductType[inv.productType] || 0) + inv.totalValue;
  });

  // Calculate HHI
  let hhi = 0;
  Object.values(concentrations.byProductType).forEach((value) => {
    const share = totalValue > 0 ? value / totalValue : 0;
    hhi += share * share;
  });

  // Top 10 largest investments
  concentrations.byValue = investments
    .sort((a, b) => b.totalValue - a.totalValue)
    .slice(0, 10)
    .map((inv) => ({
      id: inv.id,
      clientName: inv.clientName,
      productType: inv.productType,
      value: inv.totalValue,
      percentage: totalValue > 0 ? (inv.totalValue / totalValue) * 100 : 0,
    }));

  return {
    ...concentrations,
    herfindahlIndex: hhi * 10000,
    concentrationScore: hhi > 0.25 ? "high" : hhi > 0.15 ? "medium" : "low",
    diversificationRatio: Object.keys(concentrations.byProductType).length / investments.length * 100,
  };
}

// Helper functions for risk calculations
function calculateConditionalVaR(returns, confidence) {
  if (returns.length === 0) return 0;
  const varValue = calculateVaR(returns, confidence);
  const tailReturns = returns.filter((r) => r <= varValue);
  return tailReturns.length > 0 ? tailReturns.reduce((a, b) => a + b) / tailReturns.length : 0;
}

function calculateSortinoRatio(returns) {
  if (returns.length === 0) return 0;
  const targetReturn = 0;
  const avgReturn = returns.reduce((a, b) => a + b) / returns.length;
  const downside = returns.filter((r) => r < targetReturn);

  if (downside.length === 0) return Infinity;

  const downsideDeviation = Math.sqrt(
    downside.map((r) => Math.pow(r - targetReturn, 2)).reduce((a, b) => a + b) / downside.length,
  );

  return downsideDeviation > 0 ? (avgReturn - 2.0) / downsideDeviation : 0; // Risk-free rate = 2%
}

function calculateCalmarRatio(returns, maxDrawdown) {
  if (returns.length === 0 || maxDrawdown === 0) return 0;
  const avgReturn = returns.reduce((a, b) => a + b) / returns.length;
  return avgReturn / Math.abs(maxDrawdown);
}

function calculateSkewness(returns) {
  if (returns.length < 3) return 0;

  const mean = returns.reduce((a, b) => a + b) / returns.length;
  const variance = returns.map((r) => Math.pow(r - mean, 2)).reduce((a, b) => a + b) / returns.length;
  const stdDev = Math.sqrt(variance);

  if (stdDev === 0) return 0;

  const skewness = returns
    .map((r) => Math.pow((r - mean) / stdDev, 3))
    .reduce((a, b) => a + b) / returns.length;

  return skewness;
}

function calculateKurtosis(returns) {
  if (returns.length < 4) return 0;

  const mean = returns.reduce((a, b) => a + b) / returns.length;
  const variance = returns.map((r) => Math.pow(r - mean, 2)).reduce((a, b) => a + b) / returns.length;
  const stdDev = Math.sqrt(variance);

  if (stdDev === 0) return 0;

  const kurtosis = returns
    .map((r) => Math.pow((r - mean) / stdDev, 4))
    .reduce((a, b) => a + b) / returns.length;

  return kurtosis - 3; // Excess kurtosis
}

// Placeholder implementations for additional functions
function calculateLiquidityRiskBreakdown(investments) {
  return { liquidityScore: 0, breakdown: {} };
}

function calculateCreditRiskAnalysis(investments) {
  return { creditScore: 0, riskDistribution: {} };
}

function calculateMarketRiskExposure(investments) {
  return { marketBeta: 1.0, sectorExposure: {} };
}

function calculateOperationalRisk(investments) {
  return { operationalScore: 0, riskFactors: [] };
}

function performStressTesting(investments) {
  return { scenarios: [], stressResults: {} };
}

function calculateRiskBudgetAnalysis(investments, riskProfile) {
  return { budgetAllocation: {}, utilization: 0 };
}

function generateRiskMatrix(investments) {
  return { matrix: [], riskCategories: {} };
}

function calculateVaRAnalysis(investments) {
  const returns = investments.map((inv) => inv.profitLossPercentage);
  return {
    var95: calculateVaR(returns, 0.05),
    var99: calculateVaR(returns, 0.01),
    cvar95: calculateConditionalVaR(returns, 0.05),
    cvar99: calculateConditionalVaR(returns, 0.01),
  };
}

function performScenarioAnalysis(investments) {
  return { scenarios: [], results: {} };
}

// 🔮 PREDICTION FUNCTIONS - simplified implementations
function calculateReturnPredictions(investments, horizon) {
  return { predictedReturns: [], confidence: 0.7 };
}

function calculateOptimalAllocation(investments) {
  return { allocation: {}, expectedReturn: 0, expectedRisk: 0 };
}

function calculateRiskPredictions(investments, horizon) {
  return { riskForecast: [], scenarios: [] };
}

function calculateMaturityForecast(investments) {
  return { maturitySchedule: [], projectedCashflows: [] };
}

function calculateTrendAnalysis(investments) {
  return { trend: "neutral", momentum: 0, signals: [] };
}

function calculateSeasonalityAnalysis(investments) {
  return { seasonalPatterns: {}, cyclicality: 0 };
}

function performMonteCarloSimulation(investments, horizon) {
  return { simulations: [], statistics: {} };
}

function identifyInvestmentOpportunities(investments) {
  return { opportunities: [], recommendations: [] };
}

function generateInvestmentRecommendations(investments) {
  return { recommendations: [], actionItems: [] };
}

function calculateConfidenceIntervals(investments) {
  return { intervals: {}, methodology: "bootstrap" };
}

// 📊 BENCHMARK FUNCTIONS - simplified implementations
function calculateMarketBenchmarks(investments, benchmarkType) {
  return { benchmarks: {}, comparison: {} };
}

function calculateIndustryComparison(investments) {
  return { industryMetrics: {}, ranking: [] };
}

function calculatePeerAnalysis(investments) {
  return { peerMetrics: {}, positioning: {} };
}

function calculateIndexComparison(investments) {
  return { indexMetrics: {}, correlation: {} };
}

function calculateRelativePerformance(investments) {
  return { relativeReturns: [], outperformance: 0 };
}

function calculateAttributionAnalysis(investments) {
  return { attribution: {}, breakdown: {} };
}

function calculateTrackingError(investments) {
  return { trackingError: 0, consistency: 0 };
}

function calculateInformationRatio(investments) {
  return { informationRatio: 0, activeReturn: 0 };
}

function calculateAlpha(investments) {
  return { alpha: 0, significance: 0 };
}

function calculateBeta(investments) {
  return { beta: 1.0, rsquared: 0 };
}

// Helper functions from advanced-analytics.js
function calculateVolatility(returns) {
  if (returns.length === 0) return 0;
  const mean = returns.reduce((a, b) => a + b) / returns.length;
  const variance = returns.map((r) => Math.pow(r - mean, 2)).reduce((a, b) => a + b) / returns.length;
  return Math.sqrt(variance);
}

function calculateSharpeRatio(returns) {
  if (returns.length === 0) return 0;
  const riskFreeRate = 2.0;
  const avgReturn = returns.reduce((a, b) => a + b) / returns.length;
  const volatility = calculateVolatility(returns);
  return volatility > 0 ? (avgReturn - riskFreeRate) / volatility : 0;
}

function calculateVaR(returns, confidence = 0.05) {
  if (returns.length === 0) return 0;
  const sorted = [...returns].sort((a, b) => a - b);
  const index = Math.floor(returns.length * confidence);
  return index < sorted.length ? sorted[index] : sorted[sorted.length - 1];
}

function calculateMaxDrawdown(investments) {
  if (investments.length === 0) return 0;

  const sortedByDate = [...investments].sort((a, b) => new Date(a.signedDate) - new Date(b.signedDate));
  let peak = 0;
  let maxDrawdown = 0;
  let runningValue = 0;

  for (const investment of sortedByDate) {
    runningValue += investment.totalValue;
    if (runningValue > peak) peak = runningValue;
    const drawdown = peak > 0 ? (peak - runningValue) / peak * 100 : 0;
    if (drawdown > maxDrawdown) maxDrawdown = drawdown;
  }

  return maxDrawdown;
}

// Conversion functions - simplified references
function convertExcelDataToInvestment(id, data) {
  // Use implementation from advanced-analytics.js
  return { id, ...data };
}

function convertBondToInvestment(id, data) {
  return { id, ...data };
}

function convertShareToInvestment(id, data) {
  return { id, ...data };
}

function convertLoanToInvestment(id, data) {
  return { id, ...data };
}

function convertApartmentToInvestment(id, data) {
  return { id, ...data };
}

// Cache functions
const cache = new Map();
const cacheTimestamps = new Map();

async function getCachedResult(key) {
  const timestamp = cacheTimestamps.get(key);
  if (!timestamp || Date.now() - timestamp > 300000) {
    cache.delete(key);
    cacheTimestamps.delete(key);
    return null;
  }
  return cache.get(key);
}

async function setCachedResult(key, data, ttlSeconds) {
  cache.set(key, data);
  cacheTimestamps.set(key, Date.now());

  setTimeout(() => {
    cache.delete(key);
    cacheTimestamps.delete(key);
  }, ttlSeconds * 1000);
}
