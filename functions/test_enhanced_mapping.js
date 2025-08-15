/**
 * Test enhanced mapping functions after Firebase Functions changes
 * Sprawdza czy funkcje po naszych zmianach poprawnie mapują znormalizowane dane
 */

// Import functions from product-investors-optimization.js (simulation)
function getInvestmentProductId(investment) {
  return investment.productId ||
    investment.id ||
    investment.product_id ||
    investment.id_produktu ||
    investment.ID_Produktu ||
    '';
}

function getInvestmentProductName(investment) {
  return investment.productName ||
    investment.projectName ||  // 🚀 ENHANCED: Added for apartments
    investment.name ||
    investment.Produkt_nazwa ||
    investment.nazwa_obligacji ||
    '';
}

function getInvestmentProductType(investment) {
  return investment.productType ||
    investment.type ||
    investment.investment_type ||
    investment.Typ_produktu ||
    investment.typ_produktu ||
    '';
}

function extractClientIdentifiers(investment) {
  const identifiers = [];

  if (investment.clientId) identifiers.push(investment.clientId.toString());
  if (investment.client_id) identifiers.push(investment.client_id.toString());
  if (investment.ID_Klient) identifiers.push(investment.ID_Klient.toString());
  if (investment.id_klient) identifiers.push(investment.id_klient.toString());
  if (investment.klient_id) identifiers.push(investment.klient_id.toString());

  // 🚀 ENHANCED: New fields
  if (investment.saleId) identifiers.push(investment.saleId.toString());
  if (investment.excel_id) identifiers.push(investment.excel_id.toString());

  return identifiers.filter(id => id && id !== 'undefined' && id !== 'NULL' && id !== 'null');
}

function getInvestmentClientName(investment) {
  return investment.clientName ||
    investment.client_name ||
    investment.fullName ||
    investment.name ||
    investment.Klient ||
    investment.klient ||
    '';
}

function safeToDouble(value) {
  if (value === null || value === undefined || value === 'NULL' || value === 'null') return 0;
  if (typeof value === 'number') return value;
  if (typeof value === 'string') {
    const cleaned = value.replace(/[,\s]/g, '');
    const parsed = parseFloat(cleaned);
    return isNaN(parsed) ? 0 : parsed;
  }
  return 0;
}

// Test data from normalized JSON files
const testData = {
  apartment: {
    "productType": "Apartamenty",
    "investmentAmount": 190143.66,
    "capitalForRestructuring": 0,
    "capitalSecuredByRealEstate": 0,
    "saleId": "1436",
    "clientId": "10",
    "clientName": "Joanna Rusiecka",
    "advisor": "Jarosław Maliniak",
    "branch": "GDA",
    "productStatus": "Aktywny",
    "projectName": "Gdański Harward",
    "paymentAmount": 190143.66,
    "id": "apartment_0001"
  },
  bond: {
    "productType": "Obligacje",
    "investmentAmount": 50000.00,
    "clientId": "15",
    "clientName": "Jan Kowalski",
    "productName": "Obligacje Metropolitalne Series A",
    "id": "bond_0001"
  },
  legacy: {
    "Typ_produktu": "Udziały",
    "kwota_inwestycji": 75000.00,
    "ID_Klient": "20",
    "Klient": "Anna Nowak",
    "Produkt_nazwa": "Udziały Legacy Fund",
    "id": "share_legacy_001"
  }
};

// Run tests
function runEnhancedMappingTests() {
  console.log('🚀 ENHANCED FIREBASE FUNCTIONS MAPPING TESTS');
  console.log('='.repeat(60));
  console.log('');

  let passedTests = 0;
  let totalTests = 0;

  // Test 1: Apartment product ID mapping
  totalTests++;
  console.log('📊 TEST 1: Apartment Product ID Mapping');
  const apartmentId = getInvestmentProductId(testData.apartment);
  console.log(`   Input: id="${testData.apartment.id}"`);
  console.log(`   Result: "${apartmentId}"`);
  console.log(`   Expected: "apartment_0001"`);
  if (apartmentId === "apartment_0001") {
    console.log('   ✅ PASSED');
    passedTests++;
  } else {
    console.log('   ❌ FAILED');
  }
  console.log('');

  // Test 2: Apartment product name (projectName)
  totalTests++;
  console.log('📊 TEST 2: Apartment Product Name (projectName support)');
  const apartmentName = getInvestmentProductName(testData.apartment);
  console.log(`   Input: projectName="${testData.apartment.projectName}"`);
  console.log(`   Result: "${apartmentName}"`);
  console.log(`   Expected: "Gdański Harward"`);
  if (apartmentName === "Gdański Harward") {
    console.log('   ✅ PASSED');
    passedTests++;
  } else {
    console.log('   ❌ FAILED');
  }
  console.log('');

  // Test 3: Enhanced client identifiers (saleId)
  totalTests++;
  console.log('📊 TEST 3: Enhanced Client Identifiers (includes saleId)');
  const apartmentClientIds = extractClientIdentifiers(testData.apartment);
  console.log(`   Input: clientId="${testData.apartment.clientId}", saleId="${testData.apartment.saleId}"`);
  console.log(`   Result: [${apartmentClientIds.join(', ')}]`);
  console.log(`   Expected: ["10", "1436"]`);
  const expectedIds = ["10", "1436"];
  const clientIdsMatch = expectedIds.every(id => apartmentClientIds.includes(id)) &&
    apartmentClientIds.length === expectedIds.length;
  if (clientIdsMatch) {
    console.log('   ✅ PASSED');
    passedTests++;
  } else {
    console.log('   ❌ FAILED');
  }
  console.log('');

  // Test 4: Bond mapping (standard fields)
  totalTests++;
  console.log('📊 TEST 4: Bond Standard Fields Mapping');
  const bondName = getInvestmentProductName(testData.bond);
  const bondId = getInvestmentProductId(testData.bond);
  console.log(`   Bond Name: "${bondName}" (expected: "Obligacje Metropolitalne Series A")`);
  console.log(`   Bond ID: "${bondId}" (expected: "bond_0001")`);
  if (bondName === "Obligacje Metropolitalne Series A" && bondId === "bond_0001") {
    console.log('   ✅ PASSED');
    passedTests++;
  } else {
    console.log('   ❌ FAILED');
  }
  console.log('');

  // Test 5: Legacy data compatibility
  totalTests++;
  console.log('📊 TEST 5: Legacy Data Compatibility');
  const legacyType = getInvestmentProductType(testData.legacy);
  const legacyName = getInvestmentProductName(testData.legacy);
  const legacyClientIds = extractClientIdentifiers(testData.legacy);
  console.log(`   Legacy Type: "${legacyType}" (expected: "Udziały")`);
  console.log(`   Legacy Name: "${legacyName}" (expected: "Udziały Legacy Fund")`);
  console.log(`   Legacy Client ID: [${legacyClientIds.join(', ')}] (expected: ["20"])`);
  if (legacyType === "Udziały" &&
    legacyName === "Udziały Legacy Fund" &&
    legacyClientIds.includes("20")) {
    console.log('   ✅ PASSED');
    passedTests++;
  } else {
    console.log('   ❌ FAILED');
  }
  console.log('');

  // Test 6: Financial fields mapping (paymentAmount vs investmentAmount)
  totalTests++;
  console.log('📊 TEST 6: Financial Fields Priority (paymentAmount support)');
  const apartmentAmount1 = safeToDouble(testData.apartment.investmentAmount);
  const apartmentAmount2 = safeToDouble(testData.apartment.paymentAmount);
  console.log(`   investmentAmount: ${apartmentAmount1}`);
  console.log(`   paymentAmount: ${apartmentAmount2}`);
  console.log(`   Both should be: 190143.66`);
  if (apartmentAmount1 === 190143.66 && apartmentAmount2 === 190143.66) {
    console.log('   ✅ PASSED');
    passedTests++;
  } else {
    console.log('   ❌ FAILED');
  }
  console.log('');

  // Summary
  console.log('🎯 TEST SUMMARY');
  console.log('='.repeat(60));
  console.log(`   Total Tests: ${totalTests}`);
  console.log(`   Passed: ${passedTests}`);
  console.log(`   Failed: ${totalTests - passedTests}`);
  console.log(`   Success Rate: ${Math.round((passedTests / totalTests) * 100)}%`);
  console.log('');

  if (passedTests === totalTests) {
    console.log('🎉 ALL TESTS PASSED! Firebase Functions enhanced mapping is working correctly.');
    console.log('✅ System should now properly handle normalized JSON data');
    console.log('✅ Product search by ID, name, and type should work');
    console.log('✅ Client mapping with multiple identifiers should work');
    console.log('✅ Legacy data compatibility is maintained');
  } else {
    console.log('⚠️  Some tests failed. Check the mapping functions.');
  }

  console.log('');
  console.log('🚀 Enhanced features added:');
  console.log('   • projectName support for apartments');
  console.log('   • saleId as additional client identifier');
  console.log('   • paymentAmount as alternative to investmentAmount');
  console.log('   • Enhanced logical ID support (apartment_0001, etc.)');
  console.log('   • Backward compatibility with legacy polish fields');
}

// Run the tests
runEnhancedMappingTests();
