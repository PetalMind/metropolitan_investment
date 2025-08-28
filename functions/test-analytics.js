/**
 * Simple test version of Analytics Screen Service
 */

const { onCall } = require("firebase-functions/v2/https");
const { HttpsError } = require("firebase-functions/v2/https");

/**
 * Simple test analytics function
 */
const getAnalyticsScreenDataTest = onCall({
  memory: "512MiB",
  timeoutSeconds: 60,
  cors: true,
}, async (request) => {
  console.log("🏛️ [TestAnalytics] Function called");
  
  try {
    // Return mock data for testing
    const result = {
      portfolioMetrics: {
        totalValue: 1000000,
        totalInvested: 800000,
        totalProfit: 200000,
        totalROI: 25.0,
        growthPercentage: 12.5,
        activeInvestmentsCount: 50,
        totalInvestmentsCount: 60,
        averageReturn: 8.5,
        monthlyGrowth: 2.1
      },
      productBreakdown: [
        {
          productType: "bonds",
          productName: "Obligacje Korporacyjne",
          value: 400000,
          percentage: 40.0,
          count: 20,
          averageReturn: 6.5
        },
        {
          productType: "loans", 
          productName: "Pożyczki Hipoteczne",
          value: 300000,
          percentage: 30.0,
          count: 15,
          averageReturn: 8.2
        }
      ],
      monthlyPerformance: [
        {
          month: "2024-01",
          totalValue: 950000,
          totalVolume: 50000,
          averageReturn: 7.5,
          transactionCount: 10,
          growthRate: 5.2
        }
      ],
      clientMetrics: {
        totalClients: 100,
        activeClients: 85,
        newClientsThisMonth: 5,
        clientRetentionRate: 95.0,
        averageClientValue: 10000,
        topClients: []
      },
      riskMetrics: {
        volatility: 12.5,
        sharpeRatio: 1.4,
        maxDrawdown: 8.2,
        valueAtRisk: 5.1,
        diversificationIndex: 0.75,
        riskLevel: "medium",
        concentrationRisk: 15.2
      },
      calculatedAt: new Date().toISOString(),
      executionTimeMs: 100,
      timestamp: new Date().toISOString(),
      timeRangeMonths: request.data?.timeRangeMonths || 12,
      totalClients: 100,
      totalInvestments: 60,
      source: "test-analytics-service",
      version: "1.0.0-test"
    };

    console.log("✅ [TestAnalytics] Returning mock data");
    return result;

  } catch (error) {
    console.error("❌ [TestAnalytics] Error:", error);
    throw new HttpsError("internal", "Test analytics failed", error.message);
  }
});

module.exports = {
  getAnalyticsScreenDataTest
};