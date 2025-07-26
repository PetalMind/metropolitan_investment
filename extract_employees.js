const fs = require('fs');

// Wczytaj dane inwestycji
const investmentsData = JSON.parse(fs.readFileSync('./investments_data.json', 'utf8'));

// Zbiór unikalnych pracowników
const employeesMap = new Map();

investmentsData.forEach(investment => {
  const firstName = investment.praconwnik_imie?.toString().trim() || '';
  const lastName = investment.pracownik_nazwisko?.toString().trim() || '';
  const branch = investment.oddzial?.toString().trim() || '';

  if (firstName || lastName) {
    const fullName = `${firstName} ${lastName}`.trim();
    const key = fullName.toLowerCase();

    if (!employeesMap.has(key)) {
      employeesMap.set(key, {
        firstName: firstName,
        lastName: lastName,
        fullName: fullName,
        branchCode: branch,
        branchName: branch,
        position: 'Doradca Inwestycyjny',
        email: '',
        phone: '',
        isActive: true,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        additionalInfo: {
          source: 'investment_data_extraction',
          extractedAt: new Date().toISOString()
        }
      });
    } else {
      // Aktualizuj oddział jeśli nie był ustawiony
      const existing = employeesMap.get(key);
      if (!existing.branchCode && branch) {
        existing.branchCode = branch;
        existing.branchName = branch;
      }
    }
  }
});

// Konwertuj na tablicę
const employees = Array.from(employeesMap.values());

// Sortuj według nazwiska
employees.sort((a, b) => a.lastName.localeCompare(b.lastName));

// Zapisz do pliku
fs.writeFileSync('./employees_data.json', JSON.stringify(employees, null, 2));

console.log(`✅ Wyekstraktowano ${employees.length} unikalnych pracowników:`);
employees.forEach(emp => {
  console.log(`   - ${emp.fullName} (${emp.branchCode})`);
});

console.log(`\n📊 Statystyki:`);
const branchStats = {};
employees.forEach(emp => {
  const branch = emp.branchCode || 'Nieznany';
  branchStats[branch] = (branchStats[branch] || 0) + 1;
});

Object.entries(branchStats).forEach(([branch, count]) => {
  console.log(`   ${branch}: ${count} pracowników`);
});
