// PREMIUM ANALYTICS FUNCTIONS - część 2
// Funkcje dla zaawansowanej analityki dashboard

const { onCall } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

// Set global options for all functions
setGlobalOptions({
  region: "europe-west1",
  cors: true  // Enable CORS for all functions
});

/**
 * 📊 FUNKCJA: Advanced Dashboard Metrics
 * Przeniesione z AdvancedAnalyticsService do Firebase Functions
 */
exports.getAdvancedDashboardMetrics = onCall({
  memory: "2GiB",
  timeoutSeconds: 540,
}, async (request) => {
  const startTime = Date.now();
  console.log("🔍 [Advanced Analytics] Rozpoczynam obliczanie metryk...");

  try {
    const db = admin.firestore(); // Initialize db inside function
    const { forceRefresh = false } = request.data || {};

    // 💾 Sprawdź cache
    const cacheKey = "advanced_dashboard_metrics";
    if (!forceRefresh) {
      const cached = await getCachedResult(cacheKey);
      if (cached) {
        console.log("⚡ [Advanced Analytics] Zwracam z cache");
        return cached;
      }
    }

    // 📊 KROK 1: Pobierz wszystkie inwestycje ze wszystkich kolekcji
    console.log("📋 [Advanced Analytics] Pobieranie danych ze wszystkich kolekcji...");

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

    // 📊 KROK 2: Konwertuj wszystkie dane do zunifikowanego formatu
    const allInvestments = [];

    // Konwertuj investments
    investmentsSnapshot.docs.forEach((doc) => {
      const investment = convertExcelDataToInvestment(doc.id, doc.data());
      allInvestments.push(investment);
    });

    // Konwertuj bonds
    bondsSnapshot.docs.forEach((doc) => {
      const investment = convertBondToInvestment(doc.id, doc.data());
      allInvestments.push(investment);
    });

    // Konwertuj shares
    sharesSnapshot.docs.forEach((doc) => {
      const investment = convertShareToInvestment(doc.id, doc.data());
      allInvestments.push(investment);
    });

    // Konwertuj loans
    loansSnapshot.docs.forEach((doc) => {
      const investment = convertLoanToInvestment(doc.id, doc.data());
      allInvestments.push(investment);
    });

    // Konwertuj apartments
    apartmentsSnapshot.docs.forEach((doc) => {
      const investment = convertApartmentToInvestment(doc.id, doc.data());
      allInvestments.push(investment);
    });

    console.log(
      `📊 [Advanced Analytics] Przetworzono ${allInvestments.length} inwestycji:`,
      `\n  - Investments: ${investmentsSnapshot.docs.length}`,
      `\n  - Bonds: ${bondsSnapshot.docs.length}`,
      `\n  - Shares: ${sharesSnapshot.docs.length}`,
      `\n  - Loans: ${loansSnapshot.docs.length}`,
      `\n  - Apartments: ${apartmentsSnapshot.docs.length}`,
    );

    // 📊 KROK 3: Oblicz zaawansowane metryki
    const metrics = {
      portfolioMetrics: calculatePortfolioMetrics(allInvestments),
      riskMetrics: calculateRiskMetrics(allInvestments),
      performanceMetrics: calculatePerformanceMetrics(allInvestments),
      clientAnalytics: calculateClientAnalytics(allInvestments),
      productAnalytics: calculateProductAnalytics(allInvestments),
      employeeAnalytics: calculateEmployeeAnalytics(allInvestments),
      geographicAnalytics: calculateGeographicAnalytics(allInvestments),
      timeSeriesAnalytics: calculateTimeSeriesAnalytics(allInvestments),
      predictionMetrics: calculatePredictionMetrics(allInvestments),
      benchmarkMetrics: calculateBenchmarkMetrics(allInvestments),
      executionTime: Date.now() - startTime,
      timestamp: new Date().toISOString(),
      source: "firebase-functions-advanced",
    };

    // 💾 Zapisz do cache na 5 minut
    await setCachedResult(cacheKey, metrics, 300);

    console.log(
      `✅ [Advanced Analytics] Metryki obliczone w ${metrics.executionTime}ms`,
    );
    return metrics;
  } catch (error) {
    console.error("❌ [Advanced Analytics] Błąd:", error);
    throw new HttpsError(
      "internal",
      "Błąd podczas obliczania metryk",
      error.message,
    );
  }
});

// 🛠️ HELPER FUNCTIONS - Konwersja danych

/**
 * Konwertuje dane Excel do zunifikowanego formatu investment
 */
function convertExcelDataToInvestment(id, data) {
  const safeToDouble = (value, defaultValue = 0.0) => {
    if (value == null) return defaultValue;
    if (typeof value === "number") return value;
    if (typeof value === "string") {
      const cleaned = value.replace(/,/g, "");
      const parsed = parseFloat(cleaned);
      return isNaN(parsed) ? defaultValue : parsed;
    }
    return defaultValue;
  };

  const parseDate = (dateStr) => {
    if (!dateStr || dateStr === "NULL") return null;
    try {
      return new Date(dateStr).toISOString();
    } catch (e) {
      return null;
    }
  };

  const mapProductType = (productType) => {
    if (!productType) return "bonds";
    const type = productType.toLowerCase();
    if (type.includes("pożyczka") || type.includes("pozyczka")) return "loans";
    if (type.includes("udział") || type.includes("udziały")) return "shares";
    if (type.includes("apartament")) return "apartments";
    return "bonds";
  };

  return {
    id: id,
    clientId: data.id_klient?.toString() || "",
    clientName: data.klient || "",
    employeeFirstName: data.pracownik_imie || "",
    employeeLastName: data.pracownik_nazwisko || "",
    branchCode: data.kod_oddzialu || "",
    productType: mapProductType(data.typ_produktu),
    productName: data.produkt_nazwa || "",
    signedDate: parseDate(data.data_podpisania) || new Date().toISOString(),
    investmentAmount: safeToDouble(data.wartosc_kontraktu),
    realizedCapital: safeToDouble(data.kapital_zrealizowany),
    realizedInterest: safeToDouble(data.odsetki_zrealizowane),
    remainingCapital: safeToDouble(data.kapital_pozostaly),
    remainingInterest: safeToDouble(data.odsetki_pozostale),
    totalValue: safeToDouble(data.kapital_pozostaly) + safeToDouble(data.odsetki_pozostale),
    profitLoss: safeToDouble(data.kapital_pozostaly) - safeToDouble(data.wartosc_kontraktu),
    profitLossPercentage: safeToDouble(data.wartosc_kontraktu) > 0 ?
      ((safeToDouble(data.kapital_pozostaly) - safeToDouble(data.wartosc_kontraktu)) / safeToDouble(data.wartosc_kontraktu)) * 100 : 0,
    status: "active",
    source: "investments",
  };
}

/**
 * Konwertuje obligacje do zunifikowanego formatu
 */
function convertBondToInvestment(id, data) {
  const safeToDouble = (value, defaultValue = 0.0) => {
    if (value == null) return defaultValue;
    if (typeof value === "number") return value;
    if (typeof value === "string") {
      const cleaned = value.replace(/,/g, "");
      const parsed = parseFloat(cleaned);
      return isNaN(parsed) ? defaultValue : parsed;
    }
    return defaultValue;
  };

  const investmentAmount = safeToDouble(data.kwota_inwestycji || data.Kwota_inwestycji);
  const remainingCapital = safeToDouble(data.kapital_pozostaly || data["Kapital Pozostaly"]);

  return {
    id: id,
    clientId: "",
    clientName: data.Klient || "",
    employeeFirstName: "",
    employeeLastName: "",
    branchCode: "",
    productType: "bonds",
    productName: data.typ_produktu || data.Typ_produktu || "Obligacje",
    signedDate: data.created_at || new Date().toISOString(),
    investmentAmount: investmentAmount,
    realizedCapital: safeToDouble(data.kapital_zrealizowany),
    realizedInterest: safeToDouble(data.odsetki_zrealizowane),
    remainingCapital: remainingCapital,
    remainingInterest: safeToDouble(data.odsetki_pozostale),
    totalValue: remainingCapital + safeToDouble(data.odsetki_pozostale),
    profitLoss: remainingCapital - investmentAmount,
    profitLossPercentage: investmentAmount > 0 ? ((remainingCapital - investmentAmount) / investmentAmount) * 100 : 0,
    status: "active",
    source: "bonds",
  };
}

/**
 * Konwertuje udziały do zunifikowanego formatu
 */
function convertShareToInvestment(id, data) {
  const safeToDouble = (value, defaultValue = 0.0) => {
    if (value == null) return defaultValue;
    if (typeof value === "number") return value;
    if (typeof value === "string") {
      const cleaned = value.replace(/,/g, "");
      const parsed = parseFloat(cleaned);
      return isNaN(parsed) ? defaultValue : parsed;
    }
    return defaultValue;
  };

  const investmentAmount = safeToDouble(data.kwota_inwestycji || data.Kwota_inwestycji);
  const sharesCount = safeToDouble(data.ilosc_udzialow) || 0;
  const pricePerShare = safeToDouble(data.cena_za_udzial) || 0;
  const currentValue = sharesCount * pricePerShare;

  return {
    id: id,
    clientId: "",
    clientName: data.Klient || "",
    employeeFirstName: "",
    employeeLastName: "",
    branchCode: "",
    productType: "shares",
    productName: data.typ_produktu || data.Typ_produktu || "Udziały",
    signedDate: data.created_at || new Date().toISOString(),
    investmentAmount: investmentAmount,
    realizedCapital: 0,
    realizedInterest: safeToDouble(data.dywidendy_otrzymane),
    remainingCapital: currentValue,
    remainingInterest: 0,
    totalValue: currentValue,
    profitLoss: currentValue - investmentAmount,
    profitLossPercentage: investmentAmount > 0 ? ((currentValue - investmentAmount) / investmentAmount) * 100 : 0,
    status: "active",
    source: "shares",
    // Dodatkowe pola specyficzne dla udziałów
    sharesCount: sharesCount,
    pricePerShare: pricePerShare,
  };
}

/**
 * Konwertuje pożyczki do zunifikowanego formatu
 */
function convertLoanToInvestment(id, data) {
  const safeToDouble = (value, defaultValue = 0.0) => {
    if (value == null) return defaultValue;
    if (typeof value === "number") return value;
    if (typeof value === "string") {
      const cleaned = value.replace(/,/g, "");
      const parsed = parseFloat(cleaned);
      return isNaN(parsed) ? defaultValue : parsed;
    }
    return defaultValue;
  };

  const investmentAmount = safeToDouble(data.kwota_inwestycji || data.Kwota_inwestycji);
  const remainingCapital = safeToDouble(data.kapital_pozostaly || data["Kapital Pozostaly"]);

  return {
    id: id,
    clientId: "",
    clientName: data.Klient || data.pozyczkobiorca || "",
    employeeFirstName: "",
    employeeLastName: "",
    branchCode: "",
    productType: "loans",
    productName: data.typ_produktu || data.Typ_produktu || "Pożyczki",
    signedDate: data.created_at || data.data_udzielenia || new Date().toISOString(),
    investmentAmount: investmentAmount,
    realizedCapital: 0,
    realizedInterest: safeToDouble(data.odsetki_naliczone),
    remainingCapital: remainingCapital,
    remainingInterest: 0,
    totalValue: remainingCapital,
    profitLoss: remainingCapital - investmentAmount,
    profitLossPercentage: investmentAmount > 0 ? ((remainingCapital - investmentAmount) / investmentAmount) * 100 : 0,
    status: data.status || "active",
    source: "loans",
    // Dodatkowe pola dla pożyczek
    borrower: data.pozyczkobiorca || "",
    interestRate: data.oprocentowanie || 0,
    collateral: data.zabezpieczenie || "",
  };
}

/**
 * Konwertuje apartamenty do zunifikowanego formatu
 */
function convertApartmentToInvestment(id, data) {
  const safeToDouble = (value, defaultValue = 0.0) => {
    if (value == null) return defaultValue;
    if (typeof value === "number") return value;
    if (typeof value === "string") {
      const cleaned = value.replace(/,/g, "");
      const parsed = parseFloat(cleaned);
      return isNaN(parsed) ? defaultValue : parsed;
    }
    return defaultValue;
  };

  const area = safeToDouble(data.powierzchnia);
  const pricePerM2 = safeToDouble(data.cena_za_m2);
  const investmentAmount = safeToDouble(data.kwota_inwestycji || data.Kwota_inwestycji);
  const currentValue = area * pricePerM2;

  return {
    id: id,
    clientId: "",
    clientName: data.Klient || "",
    employeeFirstName: "",
    employeeLastName: "",
    branchCode: "",
    productType: "apartments",
    productName: data.nazwa_projektu || data.Produkt_nazwa || "Apartamenty",
    signedDate: data.created_at || new Date().toISOString(),
    investmentAmount: investmentAmount || currentValue,
    realizedCapital: 0,
    realizedInterest: 0,
    remainingCapital: currentValue,
    remainingInterest: 0,
    totalValue: currentValue,
    profitLoss: currentValue - (investmentAmount || currentValue),
    profitLossPercentage: investmentAmount > 0 ? ((currentValue - investmentAmount) / investmentAmount) * 100 : 0,
    status: data.status || "active",
    source: "apartments",
    // Dodatkowe pola dla apartamentów
    area: area,
    pricePerM2: pricePerM2,
    roomCount: data.liczba_pokoi || 0,
    apartmentNumber: data.numer_apartamentu || "",
    developer: data.deweloper || "",
  };
}

// 🛠️ CALCULATION FUNCTIONS - Funkcje obliczeniowe

/**
 * Oblicza metryki portfela
 */
function calculatePortfolioMetrics(investments) {
  let totalValue = 0;
  let totalInvested = 0;
  let totalRealized = 0;
  let totalRemaining = 0;
  let totalInterest = 0;
  let activeCount = 0;

  for (const investment of investments) {
    totalValue += investment.totalValue;
    totalInvested += investment.investmentAmount;
    totalRealized += investment.realizedCapital;
    totalRemaining += investment.remainingCapital;
    totalInterest += investment.realizedInterest + investment.remainingInterest;

    if (investment.status === "active") {
      activeCount++;
    }
  }

  const totalProfit = totalRealized + totalInterest - totalInvested;
  const roi = totalInvested > 0 ? (totalProfit / totalInvested) * 100 : 0.0;

  // Oblicz medianę
  const investmentAmounts = investments.map(i => i.investmentAmount).sort((a, b) => a - b);
  const medianInvestmentSize = investmentAmounts.length > 0 ?
    investmentAmounts.length % 2 === 0 ?
      (investmentAmounts[Math.floor(investmentAmounts.length / 2) - 1] + investmentAmounts[Math.floor(investmentAmounts.length / 2)]) / 2 :
      investmentAmounts[Math.floor(investmentAmounts.length / 2)] : 0;

  // Oblicz wzrost portfela
  const sortedByDate = investments.sort((a, b) => new Date(a.signedDate) - new Date(b.signedDate));
  const portfolioGrowthRate = sortedByDate.length > 1 ?
    ((sortedByDate[sortedByDate.length - 1].totalValue / sortedByDate[0].investmentAmount) - 1) * 100 : 0;

  return {
    totalValue,
    totalInvested,
    totalRealized,
    totalRemaining,
    totalInterest,
    totalProfit,
    roi,
    activeInvestmentsCount: activeCount,
    totalInvestmentsCount: investments.length,
    averageInvestmentSize: investments.length > 0 ? totalInvested / investments.length : 0,
    medianInvestmentSize,
    portfolioGrowthRate,
  };
}

/**
 * Oblicza metryki ryzyka
 */
function calculateRiskMetrics(investments) {
  const returns = investments.map(i => i.profitLossPercentage);

  const volatility = calculateVolatility(returns);
  const sharpeRatio = calculateSharpeRatio(returns);
  const maxDrawdown = calculateMaxDrawdown(investments);
  const valueAtRisk = calculateVaR(returns);
  const concentrationRisk = calculateConcentrationRisk(investments);

  return {
    volatility,
    sharpeRatio,
    maxDrawdown,
    valueAtRisk,
    concentrationRisk,
    diversificationRatio: calculateDiversificationRatio(investments),
    liquidityRisk: calculateLiquidityRisk(investments),
    creditRisk: calculateCreditRisk(investments),
    beta: 1.0, // Uproszczona beta
  };
}

/**
 * Oblicza metryki wydajności
 */
function calculatePerformanceMetrics(investments) {
  const returns = investments.map(i => i.profitLossPercentage);
  const profitableCount = investments.filter(i => i.profitLoss > 0).length;

  const totalInvested = investments.reduce((sum, inv) => sum + inv.investmentAmount, 0);
  const totalCurrent = investments.reduce((sum, inv) => sum + inv.totalValue, 0);
  const totalROI = totalInvested > 0 ? ((totalCurrent - totalInvested) / totalInvested) * 100 : 0;

  const annualizedReturn = calculateAnnualizedReturn(investments);
  const sharpeRatio = calculateSharpeRatio(returns);
  const maxDrawdown = calculateMaxDrawdown(investments);

  // Znajdź najlepsze i najgorsze inwestycje
  const bestPerformingInvestment = investments.reduce((best, current) =>
    current.profitLossPercentage > best.profitLossPercentage ? current : best, investments[0] || null);

  const worstPerformingInvestment = investments.reduce((worst, current) =>
    current.profitLossPercentage < worst.profitLossPercentage ? current : worst, investments[0] || null);

  // Wydajność według typu produktu
  const productPerformance = {};
  const productGroups = {};

  investments.forEach(inv => {
    if (!productGroups[inv.productType]) {
      productGroups[inv.productType] = [];
    }
    productGroups[inv.productType].push(inv);
  });

  Object.keys(productGroups).forEach(type => {
    const typeInvestments = productGroups[type];
    const avgReturn = typeInvestments.reduce((sum, inv) => sum + inv.profitLossPercentage, 0) / typeInvestments.length;
    productPerformance[type] = avgReturn;
  });

  // Top performers
  const topPerformers = investments
    .sort((a, b) => b.profitLossPercentage - a.profitLossPercentage)
    .slice(0, 10);

  return {
    averageReturn: returns.length > 0 ? returns.reduce((a, b) => a + b) / returns.length : 0,
    bestPerformingInvestment,
    worstPerformingInvestment,
    successRate: investments.length > 0 ? (profitableCount / investments.length) * 100 : 0,
    alpha: 0, // Uproszczona alpha
    beta: 1.0, // Uproszczona beta
    informationRatio: 0,
    trackingError: 0,
    totalROI,
    annualizedReturn,
    sharpeRatio,
    maxDrawdown,
    productPerformance,
    topPerformers,
  };
}

// Helper calculation functions

function calculateVolatility(returns) {
  if (returns.length === 0) return 0;
  const mean = returns.reduce((a, b) => a + b) / returns.length;
  const variance = returns.map(r => Math.pow(r - mean, 2)).reduce((a, b) => a + b) / returns.length;
  return Math.sqrt(variance);
}

function calculateSharpeRatio(returns) {
  if (returns.length === 0) return 0;
  const riskFreeRate = 2.0; // 2% stopa wolna od ryzyka
  const avgReturn = returns.reduce((a, b) => a + b) / returns.length;
  const volatility = calculateVolatility(returns);
  return volatility > 0 ? (avgReturn - riskFreeRate) / volatility : 0;
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

function calculateVaR(returns, confidence = 0.05) {
  if (returns.length === 0) return 0;
  const sorted = [...returns].sort((a, b) => a - b);
  const index = Math.floor(returns.length * confidence);
  return index < sorted.length ? sorted[index] : sorted[sorted.length - 1];
}

function calculateConcentrationRisk(investments) {
  const productValues = {};
  let totalValue = 0;

  investments.forEach(investment => {
    productValues[investment.productType] = (productValues[investment.productType] || 0) + investment.totalValue;
    totalValue += investment.totalValue;
  });

  if (totalValue === 0) return 0;

  let hhi = 0;
  Object.values(productValues).forEach(value => {
    const share = value / totalValue;
    hhi += share * share;
  });

  return hhi * 10000; // HHI w skali 0-10000
}

function calculateDiversificationRatio(investments) {
  const productTypes = new Set(investments.map(inv => inv.productType));
  return investments.length > 0 ? (productTypes.size / investments.length) * 100 : 0;
}

function calculateLiquidityRisk(investments) {
  // Uproszczone ryzyko płynności - procent inwestycji typu loans i apartments
  const illiquidCount = investments.filter(inv => inv.productType === 'loans' || inv.productType === 'apartments').length;
  return investments.length > 0 ? (illiquidCount / investments.length) * 100 : 0;
}

function calculateCreditRisk(investments) {
  // Uproszczone ryzyko kredytowe
  let riskScore = 0;
  investments.forEach(investment => {
    switch (investment.productType) {
      case 'bonds': riskScore += 1; break;
      case 'shares': riskScore += 3; break;
      case 'apartments': riskScore += 2; break;
      case 'loans': riskScore += 4; break;
      default: riskScore += 2;
    }
  });
  return investments.length > 0 ? riskScore / investments.length : 0;
}

function calculateAnnualizedReturn(investments) {
  if (investments.length === 0) return 0;

  const totalInvested = investments.reduce((sum, inv) => sum + inv.investmentAmount, 0);
  const totalCurrent = investments.reduce((sum, inv) => sum + inv.totalValue, 0);

  if (totalInvested <= 0) return 0;

  // Oblicz średni czas trwania inwestycji w latach
  const now = new Date();
  const averageYears = investments
    .map(inv => (now - new Date(inv.signedDate)) / (365.25 * 24 * 60 * 60 * 1000))
    .reduce((a, b) => a + b) / investments.length;

  if (averageYears <= 0) return 0;

  // CAGR = (Wartość końcowa / Wartość początkowa)^(1/lata) - 1
  return (Math.pow(totalCurrent / totalInvested, 1 / averageYears) - 1) * 100;
}

// Pozostałe funkcje obliczeniowe (clientAnalytics, productAnalytics, etc.)
// będą dodane w kolejnych częściach...

function calculateClientAnalytics(investments) {
  // Uproszczona analityka klientów
  const clientGroups = {};
  investments.forEach(investment => {
    if (!clientGroups[investment.clientName]) {
      clientGroups[investment.clientName] = [];
    }
    clientGroups[investment.clientName].push(investment);
  });

  const clientValues = {};
  Object.keys(clientGroups).forEach(name => {
    clientValues[name] = clientGroups[name].reduce((sum, inv) => sum + inv.totalValue, 0);
  });

  const sortedClients = Object.entries(clientValues)
    .sort(([, a], [, b]) => b - a)
    .slice(0, 10)
    .map(([name, value]) => ({ name, value }));

  return {
    totalClients: Object.keys(clientGroups).length,
    topClients: sortedClients,
    clientConcentration: 0, // Simplified
    averageClientValue: Object.values(clientValues).length > 0 ?
      Object.values(clientValues).reduce((a, b) => a + b) / Object.values(clientValues).length : 0,
    clientRetention: 0, // Simplified
    newClientsThisMonth: 0, // Simplified
  };
}

function calculateProductAnalytics(investments) {
  const productGroups = {};
  investments.forEach(investment => {
    if (!productGroups[investment.productType]) {
      productGroups[investment.productType] = [];
    }
    productGroups[investment.productType].push(investment);
  });

  const productPerformance = {};
  Object.keys(productGroups).forEach(type => {
    const invs = productGroups[type];
    productPerformance[type] = {
      totalValue: invs.reduce((sum, inv) => sum + inv.totalValue, 0),
      averageReturn: invs.length > 0 ?
        invs.reduce((sum, inv) => sum + inv.profitLossPercentage, 0) / invs.length : 0,
      count: invs.length,
      riskLevel: calculateVolatility(invs.map(inv => inv.profitLossPercentage)),
    };
  });

  // Znajdź najlepszy i najgorszy produkt
  let bestPerformingProduct = null;
  let worstPerformingProduct = null;
  let bestReturn = -Infinity;
  let worstReturn = Infinity;

  Object.keys(productPerformance).forEach(type => {
    const avgReturn = productPerformance[type].averageReturn;
    if (avgReturn > bestReturn) {
      bestReturn = avgReturn;
      bestPerformingProduct = type;
    }
    if (avgReturn < worstReturn) {
      worstReturn = avgReturn;
      worstPerformingProduct = type;
    }
  });

  return {
    productPerformance,
    bestPerformingProduct,
    worstPerformingProduct,
    productDiversification: Object.keys(productGroups).length,
  };
}

// Pozostałe uproszczone funkcje analityczne
function calculateEmployeeAnalytics(investments) {
  return {
    employeePerformance: {},
    topPerformers: [],
    averageEmployeeVolume: 0,
  };
}

function calculateGeographicAnalytics(investments) {
  return {
    branchPerformance: {},
    topBranches: [],
    geographicDiversification: 0,
  };
}

function calculateTimeSeriesAnalytics(investments) {
  return {
    monthlyData: [],
    growthTrend: 0,
    seasonality: {},
    momentum: 0,
  };
}

function calculatePredictionMetrics(investments) {
  const activeInvestments = investments.filter(inv => inv.status === 'active');

  return {
    projectedReturns: activeInvestments.length > 0 ?
      activeInvestments.reduce((sum, inv) => sum + inv.profitLossPercentage, 0) / activeInvestments.length * 1.2 : 0,
    expectedMaturityValue: activeInvestments.reduce((sum, inv) => sum + inv.remainingCapital + inv.remainingInterest, 0),
    riskAdjustedReturns: 0, // Simplified
    portfolioOptimization: "Brak rekomendacji",
  };
}

function calculateBenchmarkMetrics(investments) {
  const marketBenchmark = 5.0;
  const portfolioReturn = investments.length > 0 ?
    investments.reduce((sum, inv) => sum + inv.profitLossPercentage, 0) / investments.length : 0;

  return {
    vsMarketReturn: portfolioReturn - marketBenchmark,
    relativePerfomance: marketBenchmark !== 0 ? (portfolioReturn / marketBenchmark) * 100 : 0,
    outperformingInvestments: investments.filter(inv => inv.profitLossPercentage > marketBenchmark).length,
    benchmarkCorrelation: Math.min(1.0, Math.max(-1.0, portfolioReturn / marketBenchmark)),
  };
}

// Cache functions (reuse from existing index.js)
const cache = new Map();
const cacheTimestamps = new Map();

async function getCachedResult(key) {
  const timestamp = cacheTimestamps.get(key);
  if (!timestamp || Date.now() - timestamp > 300000) { // 5 minut
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
