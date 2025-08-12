const fs = require('fs');
const path = require('path');

// Sprawdź różne pliki JSON z klientami
const filesToCheck = [
  'clients_extracted_updated.json',
  'clients_extracted.json',
  'split_investment_data_normalized/clients_normalized_updated.json',
  'split_investment_data_normalized/clients_normalized.json'
];

console.log('🔍 Sprawdzanie liczby klientów w plikach JSON...\n');

filesToCheck.forEach(fileName => {
  const filePath = path.join(__dirname, fileName);

  if (fs.existsSync(filePath)) {
    try {
      const rawData = fs.readFileSync(filePath, 'utf8');
      const data = JSON.parse(rawData);

      if (Array.isArray(data)) {
        const validClients = data.filter(client => client && (client.excelId || client.id));
        const uniqueIds = new Set(validClients.map(c => c.excelId || c.id));

        console.log(`📄 ${fileName}:`);
        console.log(`   - Total records: ${data.length}`);
        console.log(`   - Valid clients: ${validClients.length}`);
        console.log(`   - Unique IDs: ${uniqueIds.size}`);

        // Sample check
        if (validClients.length > 0) {
          const withEmail = validClients.filter(c => c.email && c.email !== 'brak' && c.email.trim() !== '').length;
          const withPhone = validClients.filter(c => c.phone && c.phone.trim() !== '').length;
          console.log(`   - With email: ${withEmail} (${Math.round(withEmail / validClients.length * 100)}%)`);
          console.log(`   - With phone: ${withPhone} (${Math.round(withPhone / validClients.length * 100)}%)`);
        }
        console.log('');
      } else {
        console.log(`❌ ${fileName}: Not an array`);
      }
    } catch (error) {
      console.log(`❌ ${fileName}: Parse error - ${error.message}`);
    }
  } else {
    console.log(`⚠️ ${fileName}: File not found`);
  }
});

console.log('✅ Done!');
