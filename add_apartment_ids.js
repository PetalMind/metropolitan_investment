#!/usr/bin/env node

/**
 * Skrypt do dodania ID do apartamentów w formacie apartment_XXXX
 */

const fs = require('fs');
const path = require('path');

function addIdsToApartments() {
  console.log('🏢 Dodaję ID do apartamentów...\n');

  const filePath = './split_investment_data_normalized/apartments_normalized.json';

  if (!fs.existsSync(filePath)) {
    console.error('❌ Plik apartments_normalized.json nie istnieje');
    process.exit(1);
  }

  try {
    // Wczytaj plik
    const fileContent = fs.readFileSync(filePath, 'utf8');
    const apartments = JSON.parse(fileContent);

    if (!Array.isArray(apartments)) {
      console.error('❌ Plik nie zawiera tablicy danych');
      process.exit(1);
    }

    console.log(`📊 Znaleziono ${apartments.length} apartamentów`);

    // Utwórz backup
    const backupPath = filePath + '.backup_' + new Date().toISOString().substring(0, 19).replace(/[:.]/g, '-');
    fs.writeFileSync(backupPath, fileContent, 'utf8');
    console.log(`💾 Utworzono backup: ${path.basename(backupPath)}`);

    // Dodaj ID do każdego apartamentu
    let addedIds = 0;
    apartments.forEach((apartment, index) => {
      if (!apartment.id) {
        const apartmentNumber = (index + 1).toString().padStart(4, '0');
        apartment.id = `apartment_${apartmentNumber}`;
        addedIds++;
      }
    });

    console.log(`✅ Dodano ${addedIds} ID do apartamentów`);

    // Zapisz zmodyfikowany plik
    fs.writeFileSync(filePath, JSON.stringify(apartments, null, 2), 'utf8');

    console.log(`💾 Zaktualizowano plik: ${filePath}`);

    // Pokaż przykłady
    console.log('\n📝 Przykłady dodanych ID:');
    apartments.slice(0, 5).forEach(apartment => {
      console.log(`   ${apartment.id} - ${apartment.clientName} (${apartment.investmentAmount} PLN)`);
    });

    console.log('\n🎉 Apartamenty są teraz gotowe do importu!');

  } catch (error) {
    console.error('❌ Błąd przetwarzania pliku:', error.message);
    process.exit(1);
  }
}

// Uruchom skrypt
addIdsToApartments();
