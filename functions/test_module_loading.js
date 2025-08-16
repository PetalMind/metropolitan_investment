// Test loading optimized-product-investors.js
console.log("🔍 Testing optimized-product-investors.js loading...");

try {
  const optimizedService = require('./optimized-product-investors');
  console.log("✅ Module loaded successfully");

  if (optimizedService.getProductInvestorsUltraPrecise) {
    console.log("✅ getProductInvestorsUltraPrecise function found");
  } else {
    console.log("❌ getProductInvestorsUltraPrecise function NOT found");
  }

  console.log("🎯 Available exports:", Object.keys(optimizedService));

} catch (error) {
  console.error("❌ Error loading module:", error.message);
  console.error("Stack:", error.stack);
}

console.log("🔍 Test completed");
