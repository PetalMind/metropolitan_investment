const { initializeApp } = require('firebase/app');
const { getFirestore, collection, addDoc, doc, setDoc } = require('firebase/firestore');
const fs = require('fs');

// Konfiguracja Firebase (ta sama co w upload.js)
const firebaseConfig = {
  apiKey: "AIzaSyDrA1wE8wKfiayPaOxJlvP9w9TQ0W4B8iU",
  authDomain: "metropolitan-investment.firebaseapp.com",
  projectId: "metropolitan-investment",
  storageBucket: "metropolitan-investment.firebasestorage.app",
  messagingSenderId: "78600500949",
  appId: "1:78600500949:web:a6e70e78d64c86fb8f8f1f"
};

// Inicjalizacja Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function uploadEmployees() {
  try {
    console.log('🔄 Rozpoczynam import pracowników do Firebase...');

    // Wczytaj dane pracowników
    const employeesData = JSON.parse(fs.readFileSync('./employees_data.json', 'utf8'));

    console.log(`📋 Znaleziono ${employeesData.length} pracowników do importu`);

    // Import pracowników
    let successCount = 0;
    let errorCount = 0;

    for (const employee of employeesData) {
      try {
        // Stwórz dokument pracownika
        const employeeData = {
          firstName: employee.firstName || '',
          lastName: employee.lastName || '',
          email: employee.email || '',
          phone: employee.phone || '',
          branchCode: employee.branchCode || '',
          branchName: employee.branchName || '',
          position: employee.position || 'Doradca Inwestycyjny',
          isActive: employee.isActive !== false,
          createdAt: new Date(),
          updatedAt: new Date(),
          additionalInfo: employee.additionalInfo || {}
        };

        // Dodaj do kolekcji employees
        const docRef = await addDoc(collection(db, 'employees'), employeeData);

        console.log(`✅ Dodano pracownika: ${employee.fullName} (ID: ${docRef.id})`);
        successCount++;

      } catch (error) {
        console.error(`❌ Błąd przy dodawaniu ${employee.fullName}:`, error.message);
        errorCount++;
      }
    }

    console.log(`\n🎉 Import zakończony!`);
    console.log(`✅ Pomyślnie zaimportowano: ${successCount} pracowników`);
    console.log(`❌ Błędy: ${errorCount}`);

    if (successCount > 0) {
      console.log(`\n🔥 Pracownicy zostali dodani do Firebase!`);
      console.log(`📊 Można teraz używać ich w aplikacji Flutter`);
    }

  } catch (error) {
    console.error('❌ Błąd podczas importu:', error);
  }
}

uploadEmployees();
