/**
 * Analytics Screen Service - Metropolitan Investment
 * Specialized Firebase Function for Analytics Screen with comprehensive calculations
 * 🚀 Professional investment management platform analytics
 */

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");
const { getCachedResult, setCachedResult } = require("./utils/cache-utils");
const { admin, db } = require("./utils/firebase-config");

/**
 * Comprehensive Analytics Data for Metropolitan Investment Analytics Screen
 * Returns all data needed for overview, performance, risk, employees, geography, and trends tabs
 */
const getAnalyticsScreenData = onCall({
  memory: "4GiB",
  timeoutSeconds: 540,
  cors: true,
}, async (request) => {
  const data = request.data || {};
  const startTime = Date.now();
  const timeRangeMonths = data.timeRangeMonths || 12;
  const forceRefresh = data.forceRefresh || false;
  
  console.log("🏛️ [MetropolitanAnalytics] Starting comprehensive analytics calculation...", {
    timeRangeMonths,
    forceRefresh
  });

  try {
    // 💾 Check cache first
    const cacheKey = `analytics_screen_${timeRangeMonths}_${JSON.stringify(data)}`;
    const cached = await getCachedResult(cacheKey);
    if (cached && !forceRefresh) {
      console.log("⚡ [MetropolitanAnalytics] Returning from cache");
      return { ...cached, cacheUsed: true };
    }

    // 📊 Fetch comprehensive data from Firebase
    console.log("📋 [MetropolitanAnalytics] Fetching comprehensive data...");
    
    const [
      clientsSnapshot, 
      investmentsSnapshot, 
      employeesSnapshot,
      companiesSnapshot
    ] = await Promise.all([
      db.collection("clients").get(),
      db.collection("investments").get(),
      db.collection("employees").get(),
      db.collection("companies").get()
    ]);

    const clients = clientsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    const investments = investmentsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    const employees = employeesSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    const companies = companiesSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    console.log(`📊 [MetropolitanAnalytics] Data loaded:`, {
      clients: clients.length,
      investments: investments.length,
      employees: employees.length,
      companies: companies.length
    });

    // 🔍 Debug: Check data structure
    if (investments.length > 0) {
      const sampleInvestment = investments[0];
      console.log("🔍 [MetropolitanAnalytics] Sample investment fields:", Object.keys(sampleInvestment));
    }
    
    if (clients.length > 0) {
      const sampleClient = clients[0];
      console.log("🔍 [MetropolitanAnalytics] Sample client fields:", Object.keys(sampleClient));
    }

    // 📈 Calculate Portfolio Metrics
    const portfolioMetrics = calculatePortfolioMetrics(investments, clients, timeRangeMonths);
    
    // 📊 Calculate Product Breakdown
    const productBreakdown = calculateProductBreakdown(investments);
    
    // 📈 Calculate Monthly Performance
    const monthlyPerformance = calculateMonthlyPerformance(investments, timeRangeMonths);
    
    // 👥 Calculate Client Metrics
    const clientMetrics = calculateClientMetrics(clients, investments);
    
    // ⚠️ Calculate Risk Metrics
    const riskMetrics = calculateRiskMetrics(investments, clients);
    
    // 👔 Calculate Employee Analytics
    const employeeAnalytics = calculateEmployeeAnalytics(employees, clients, investments);
    
    // 🌍 Calculate Geographic Analytics
    const geographicAnalytics = calculateGeographicAnalytics(clients, investments);
    
    // 📈 Calculate Trend Analytics
    const trendAnalytics = calculateTrendAnalytics(investments, clients, timeRangeMonths);
    
    // 🏆 Calculate Performance Analytics
    const performanceAnalytics = calculatePerformanceAnalytics(investments, timeRangeMonths);

    // 🏛️ Build comprehensive analytics result
    const result = {
      // Overview Tab Data
      portfolioMetrics,
      productBreakdown,
      monthlyPerformance,
      clientMetrics,
      riskMetrics,
      
      // Performance Tab Data
      performanceAnalytics,
      
      // Risk Tab Data
      riskAnalysis: {
        ...riskMetrics,
        riskDistribution: calculateRiskDistribution(investments),
        concentrationRisk: calculateConcentrationRisk(investments, clients)
      },
      
      // Employees Tab Data
      employeeAnalytics,
      
      // Geographic Tab Data
      geographicAnalytics,
      
      // Trends Tab Data
      trendAnalytics,
      
      // Meta information
      executionTimeMs: Date.now() - startTime,
      timestamp: new Date().toISOString(),
      timeRangeMonths,
      totalClients: clients.length,
      totalInvestments: investments.length,
      source: "metropolitan-analytics-service",
      version: "1.0.0"
    };

    // 💾 Cache results for 5 minutes
    await setCachedResult(cacheKey, result, 300);

    console.log(`✅ [MetropolitanAnalytics] Complete analytics calculated in ${result.executionTimeMs}ms`);
    return { ...result, cacheUsed: false };

  } catch (error) {
    console.error("❌ [MetropolitanAnalytics] Error:", error);
    throw new HttpsError(
      "internal",
      "Failed to calculate analytics data",
      error.message
    );
  }
});

/**
 * Calculate comprehensive portfolio metrics
 */
function calculatePortfolioMetrics(investments, clients, timeRangeMonths) {
  console.log("💰 [MetropolitanAnalytics] Calculating portfolio metrics...");
  
  // Calculate total values using multiple field mapping approaches
  let totalValue = 0;
  let totalProfit = 0;
  let totalInvestmentAmount = 0;
  let remainingCapital = 0;
  let activeInvestmentsCount = 0;
  
  investments.forEach(investment => {
    // Try multiple field name approaches for robust data extraction
    const investmentAmount = getFieldValue(investment, ['investmentAmount', 'kwota_inwestycji', 'Kwota_inwestycji', 'Kwota Inwestycji']) || 0;
    const remainingAmount = getFieldValue(investment, ['remainingCapital', 'kapital_pozostaly', 'Kapital Pozostaly', 'pozostaly_kapital']) || 0;
    const realizedAmount = getFieldValue(investment, ['realizedCapital', 'kapital_zrealizowany', 'Kapital Zrealizowany']) || 0;
    
    totalInvestmentAmount += investmentAmount;
    remainingCapital += remainingAmount;
    totalProfit += realizedAmount;
    
    // Check if investment is active
    const status = getFieldValue(investment, ['status', 'Status', 'stan']) || 'active';
    if (status === 'active' || !status || status === 'aktywny') {
      activeInvestmentsCount++;
    }
  });
  
  totalValue = totalInvestmentAmount + totalProfit;
  const totalROI = totalInvestmentAmount > 0 ? ((totalProfit / totalInvestmentAmount) * 100) : 0;
  const growthPercentage = totalInvestmentAmount > 0 ? ((totalValue - totalInvestmentAmount) / totalInvestmentAmount * 100) : 0;
  
  console.log(`💰 [MetropolitanAnalytics] Portfolio metrics calculated:`, {
    totalValue: totalValue.toFixed(2),
    totalInvestmentAmount: totalInvestmentAmount.toFixed(2),
    remainingCapital: remainingCapital.toFixed(2),
    totalROI: totalROI.toFixed(2),
    activeInvestmentsCount
  });
  
  return {
    totalValue,
    totalInvestmentAmount,
    remainingCapital,
    totalProfit,
    totalROI,
    growthPercentage,
    activeInvestmentsCount,
    totalInvestmentsCount: investments.length
  };
}

/**
 * Calculate product breakdown by type
 */
function calculateProductBreakdown(investments) {
  console.log("📊 [MetropolitanAnalytics] Calculating product breakdown...");
  
  const breakdown = {
    bonds: { count: 0, value: 0, percentage: 0 },
    loans: { count: 0, value: 0, percentage: 0 },
    shares: { count: 0, value: 0, percentage: 0 },
    apartments: { count: 0, value: 0, percentage: 0 },
    other: { count: 0, value: 0, percentage: 0 }
  };
  
  let totalValue = 0;
  
  investments.forEach(investment => {
    const value = getFieldValue(investment, ['investmentAmount', 'kwota_inwestycji']) || 0;
    totalValue += value;
    
    // Determine product type from various fields
    let productType = 'other';
    const typeField = getFieldValue(investment, ['productType', 'typ_produktu', 'type', 'rodzaj']) || '';
    const productName = getFieldValue(investment, ['productName', 'nazwa_produktu', 'name']) || '';
    const id = investment.id || '';
    
    // Smart product type detection
    const typeStr = `${typeField} ${productName} ${id}`.toLowerCase();
    
    if (typeStr.includes('obligac') || typeStr.includes('bond') || id.startsWith('bond_')) {
      productType = 'bonds';
    } else if (typeStr.includes('pożyczka') || typeStr.includes('loan') || id.startsWith('loan_')) {
      productType = 'loans';
    } else if (typeStr.includes('udział') || typeStr.includes('share') || typeStr.includes('akcj') || id.startsWith('share_')) {
      productType = 'shares';
    } else if (typeStr.includes('apartament') || typeStr.includes('apartment') || typeStr.includes('mieszkan') || id.startsWith('apartment_')) {
      productType = 'apartments';
    }
    
    breakdown[productType].count++;
    breakdown[productType].value += value;
  });
  
  // Calculate percentages
  Object.keys(breakdown).forEach(type => {
    breakdown[type].percentage = totalValue > 0 ? (breakdown[type].value / totalValue * 100) : 0;
  });
  
  console.log(`📊 [MetropolitanAnalytics] Product breakdown:`, breakdown);
  return breakdown;
}

/**
 * Calculate monthly performance data
 */
function calculateMonthlyPerformance(investments, timeRangeMonths) {
  console.log("📈 [MetropolitanAnalytics] Calculating monthly performance...");
  
  const monthlyData = [];
  const currentDate = new Date();
  
  for (let i = timeRangeMonths - 1; i >= 0; i--) {
    const monthDate = new Date(currentDate);
    monthDate.setMonth(monthDate.getMonth() - i);
    
    const monthKey = `${monthDate.getFullYear()}-${String(monthDate.getMonth() + 1).padStart(2, '0')}`;
    
    // Calculate investments for this month
    const monthInvestments = investments.filter(investment => {
      const investmentDate = getFieldValue(investment, ['signingDate', 'data_podpisania', 'Data_podpisania', 'createdAt']);
      if (!investmentDate) return false;
      
      const invDate = new Date(investmentDate);
      return invDate.getFullYear() === monthDate.getFullYear() && 
             invDate.getMonth() === monthDate.getMonth();
    });
    
    const monthValue = monthInvestments.reduce((sum, inv) => {
      return sum + (getFieldValue(inv, ['investmentAmount', 'kwota_inwestycji']) || 0);
    }, 0);
    
    monthlyData.push({
      month: monthKey,
      value: monthValue,
      count: monthInvestments.length,
      growth: 0 // Will be calculated in relation to previous month
    });
  }
  
  // Calculate growth rates
  for (let i = 1; i < monthlyData.length; i++) {
    const current = monthlyData[i].value;
    const previous = monthlyData[i - 1].value;
    monthlyData[i].growth = previous > 0 ? ((current - previous) / previous * 100) : 0;
  }
  
  console.log(`📈 [MetropolitanAnalytics] Monthly performance calculated for ${monthlyData.length} months`);
  return monthlyData;
}

/**
 * Calculate client metrics
 */
function calculateClientMetrics(clients, investments) {
  console.log("👥 [MetropolitanAnalytics] Calculating client metrics...");
  
  const activeClients = clients.filter(client => {
    const status = getFieldValue(client, ['status', 'Status', 'stan']) || 'active';
    return status === 'active' || !status || status === 'aktywny';
  });
  
  const newClientsThisMonth = clients.filter(client => {
    const createdDate = getFieldValue(client, ['createdAt', 'data_utworzenia', 'Data_utworzenia']);
    if (!createdDate) return false;
    
    const clientDate = new Date(createdDate);
    const currentDate = new Date();
    const monthAgo = new Date();
    monthAgo.setMonth(monthAgo.getMonth() - 1);
    
    return clientDate >= monthAgo && clientDate <= currentDate;
  });
  
  // Calculate average investment per client
  const totalInvestmentValue = investments.reduce((sum, inv) => {
    return sum + (getFieldValue(inv, ['investmentAmount', 'kwota_inwestycji']) || 0);
  }, 0);
  
  const averageInvestmentPerClient = activeClients.length > 0 ? (totalInvestmentValue / activeClients.length) : 0;
  
  const clientMetrics = {
    totalClients: clients.length,
    activeClients: activeClients.length,
    newClientsThisMonth: newClientsThisMonth.length,
    averageInvestmentPerClient,
    clientGrowthRate: clients.length > 0 ? (newClientsThisMonth.length / clients.length * 100) : 0
  };
  
  console.log(`👥 [MetropolitanAnalytics] Client metrics:`, clientMetrics);
  return clientMetrics;
}

/**
 * Calculate risk metrics
 */
function calculateRiskMetrics(investments, clients) {
  console.log("⚠️ [MetropolitanAnalytics] Calculating risk metrics...");
  
  let highRiskInvestments = 0;
  let mediumRiskInvestments = 0;
  let lowRiskInvestments = 0;
  let totalRiskValue = 0;
  
  investments.forEach(investment => {
    const value = getFieldValue(investment, ['investmentAmount', 'kwota_inwestycji']) || 0;
    totalRiskValue += value;
    
    // Determine risk level based on product type and value
    const productType = getFieldValue(investment, ['productType', 'typ_produktu']) || '';
    const investmentAmount = value;
    
    let riskLevel = 'medium';
    
    // High risk: Large investments, shares, crypto
    if (investmentAmount > 1000000 || 
        productType.toLowerCase().includes('akcj') || 
        productType.toLowerCase().includes('share') ||
        productType.toLowerCase().includes('crypto')) {
      riskLevel = 'high';
    }
    // Low risk: Bonds, secured investments
    else if (productType.toLowerCase().includes('obligac') || 
             productType.toLowerCase().includes('bond') ||
             productType.toLowerCase().includes('zabezpiecz')) {
      riskLevel = 'low';
    }
    
    switch (riskLevel) {
      case 'high': highRiskInvestments++; break;
      case 'medium': mediumRiskInvestments++; break;
      case 'low': lowRiskInvestments++; break;
    }
  });
  
  const totalInvestments = investments.length;
  const riskMetrics = {
    highRiskInvestments,
    mediumRiskInvestments,
    lowRiskInvestments,
    highRiskPercentage: totalInvestments > 0 ? (highRiskInvestments / totalInvestments * 100) : 0,
    mediumRiskPercentage: totalInvestments > 0 ? (mediumRiskInvestments / totalInvestments * 100) : 0,
    lowRiskPercentage: totalInvestments > 0 ? (lowRiskInvestments / totalInvestments * 100) : 0,
    averageRiskLevel: calculateAverageRiskLevel(highRiskInvestments, mediumRiskInvestments, lowRiskInvestments)
  };
  
  console.log(`⚠️ [MetropolitanAnalytics] Risk metrics:`, riskMetrics);
  return riskMetrics;
}

/**
 * Helper function to get field value with fallback options
 */
function getFieldValue(obj, fieldNames) {
  for (const fieldName of fieldNames) {
    if (obj[fieldName] !== undefined && obj[fieldName] !== null && obj[fieldName] !== '') {
      return obj[fieldName];
    }
  }
  return null;
}

/**
 * Calculate average risk level
 */
function calculateAverageRiskLevel(high, medium, low) {
  const total = high + medium + low;
  if (total === 0) return 0;
  
  // Weight: high=3, medium=2, low=1
  const weightedScore = (high * 3 + medium * 2 + low * 1) / total;
  return weightedScore;
}

/**
 * Calculate employee analytics (placeholder - implement based on your employee data structure)
 */
function calculateEmployeeAnalytics(employees, clients, investments) {
  return {
    totalEmployees: employees.length,
    activeEmployees: employees.filter(emp => emp.status === 'active').length,
    // Add more employee-specific metrics as needed
  };
}

/**
 * Calculate geographic analytics (placeholder - implement based on your client location data)
 */
function calculateGeographicAnalytics(clients, investments) {
  return {
    totalRegions: 0,
    regionalDistribution: {},
    // Add more geographic metrics as needed
  };
}

/**
 * Calculate trend analytics
 */
function calculateTrendAnalytics(investments, clients, timeRangeMonths) {
  return {
    investmentTrends: [],
    clientTrends: [],
    growthTrends: [],
    // Add more trend calculations as needed
  };
}

/**
 * Calculate performance analytics
 */
function calculatePerformanceAnalytics(investments, timeRangeMonths) {
  return {
    totalROI: 0,
    averageReturn: 0,
    bestPerformingProducts: [],
    // Add more performance metrics as needed
  };
}

/**
 * Calculate risk distribution
 */
function calculateRiskDistribution(investments) {
  return {
    distribution: {},
    // Add risk distribution calculations
  };
}

/**
 * Calculate concentration risk
 */
function calculateConcentrationRisk(investments, clients) {
  return {
    concentrationIndex: 0,
    topInvestors: [],
    // Add concentration risk calculations
  };
}

module.exports = {
  getAnalyticsScreenData
};