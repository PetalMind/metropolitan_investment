/**
 * Quick Syntax Check - Sprawdza składnię wszystkich plików JavaScript
 */

const fs = require('fs');
const path = require('path');

console.log('🔍 Sprawdzanie składni JavaScript w functions/...\n');

const filesToCheck = [
  'index.js',
  'services/email-service.js',
  'services/custom-email-service.js',
  'services/smtp-test-service.js',
  'utils/firebase-config.js',
  'utils/data-mapping.js'
];

let errors = 0;

for (const file of filesToCheck) {
  const filePath = path.join(__dirname, file);

  if (!fs.existsSync(filePath)) {
    console.log(`⚠️ Plik nie istnieje: ${file}`);
    continue;
  }

  try {
    // Sprawdź składnię poprzez require
    delete require.cache[require.resolve(`./${file}`)];
    require(`./${file}`);
    console.log(`✅ ${file}`);
  } catch (error) {
    console.log(`❌ ${file}: ${error.message}`);
    errors++;
  }
}

console.log(`\n📊 Wyniki:`);
console.log(`   Sprawdzonych plików: ${filesToCheck.length}`);
console.log(`   Błędów składni: ${errors}`);

if (errors === 0) {
  console.log('\n🎉 Wszystkie pliki mają poprawną składnię!');
  process.exit(0);
} else {
  console.log('\n❌ Znalezione błędy składni! Popraw je przed deploymentem.');
  process.exit(1);
}
