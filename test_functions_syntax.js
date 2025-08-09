// Test syntax of Firebase Functions files
const fs = require('fs');
const path = require('path');

function testSyntax(fileName) {
  try {
    const filePath = path.join(__dirname, 'functions', fileName);
    require(filePath);
    console.log(`✅ ${fileName} - syntax OK`);
  } catch (error) {
    console.log(`❌ ${fileName} - syntax ERROR:`, error.message);
  }
}

// Test all function files
console.log('Testing Firebase Functions syntax...\n');
testSyntax('index.js');
testSyntax('premium-analytics-filters.js');
testSyntax('advanced-analytics.js');
testSyntax('dashboard-specialized.js');
console.log('\nSyntax test complete.');
