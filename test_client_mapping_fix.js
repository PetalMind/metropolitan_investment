const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function testClientMapping() {
  try {
    console.log('=== TESTOWANIE POPRAWKI MAPOWANIA KLIENTÓW ===\n');

    // 1. Sprawdź inwestycję z clientId 254
    console.log('🔍 1. Sprawdzanie inwestycji z clientId 254...');
    const investmentsSnapshot = await db.collection('investments')
      .where('id_klient', '==', 254)
      .limit(1)
      .get();

    if (!investmentsSnapshot.empty) {
      const investment = investmentsSnapshot.docs[0];
      const data = investment.data();
      console.log('✅ Znaleziono inwestycję:');
      console.log('   - ID inwestycji:', investment.id);
      console.log('   - Client ID (id_klient):', data.id_klient);
      console.log('   - Nazwa klienta (klient):', data.klient);
      console.log('   - Produkt:', data.produkt_nazwa);
    } else {
      console.log('❌ Nie znaleziono inwestycji z clientId 254');
      return;
    }

    // 2. Sprawdź czy istnieje klient z excelId = "254"
    console.log('\n🔍 2. Sprawdzanie klienta z excelId = "254"...');
    const clientByExcelId = await db.collection('clients')
      .where('excelId', '==', '254')
      .limit(1)
      .get();

    if (!clientByExcelId.empty) {
      const client = clientByExcelId.docs[0];
      const clientData = client.data();
      console.log('✅ Znaleziono klienta przez excelId:');
      console.log('   - Document ID (UUID):', client.id);
      console.log('   - Excel ID:', clientData.excelId);
      console.log('   - Nazwa:', clientData.imie_nazwisko || clientData.name);
      console.log('   - Email:', clientData.email);
    } else {
      console.log('❌ Nie znaleziono klienta z excelId = "254"');

      // 3. Sprawdź czy można znaleźć klienta po nazwie z inwestycji
      if (!investmentsSnapshot.empty) {
        const investmentData = investmentsSnapshot.docs[0].data();
        const clientName = investmentData.klient;

        console.log(`\n🔍 3. Sprawdzanie klienta po nazwie: "${clientName}"...`);
        const clientByName = await db.collection('clients')
          .where('imie_nazwisko', '==', clientName)
          .limit(1)
          .get();

        if (!clientByName.empty) {
          const client = clientByName.docs[0];
          const clientData = client.data();
          console.log('✅ Znaleziono klienta przez nazwę:');
          console.log('   - Document ID (UUID):', client.id);
          console.log('   - Excel ID:', clientData.excelId || 'BRAK');
          console.log('   - Nazwa:', clientData.imie_nazwisko || clientData.name);
          console.log('   - Email:', clientData.email);

          // Sprawdź czy można dodać excelId do tego klienta
          if (!clientData.excelId) {
            console.log('\n🔧 4. Dodawanie brakującego excelId...');
            await client.ref.update({
              excelId: '254',
              original_id: '254'
            });
            console.log('✅ Dodano excelId = "254" do klienta');
          }
        } else {
          console.log('❌ Nie znaleziono klienta po nazwie');
        }
      }
    }

    // 4. Podsumowanie stanu bazy
    console.log('\n📊 5. Podsumowanie stanu bazy danych:');

    const totalInvestments = await db.collection('investments').count().get();
    console.log(`   - Łączna liczba inwestycji: ${totalInvestments.data().count}`);

    const totalClients = await db.collection('clients').count().get();
    console.log(`   - Łączna liczba klientów: ${totalClients.data().count}`);

    const clientsWithExcelId = await db.collection('clients')
      .where('excelId', '!=', null)
      .count()
      .get();
    console.log(`   - Klienci z excelId: ${clientsWithExcelId.data().count}`);

    console.log('\n✅ Test zakończony pomyślnie');
    process.exit(0);
  } catch (error) {
    console.error('❌ Błąd podczas testowania:', error);
    process.exit(1);
  }
}

testClientMapping();
