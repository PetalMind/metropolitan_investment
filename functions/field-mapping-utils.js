/**
 * FIREBASE FUNCTIONS - ZNORMALIZOWANE MAPOWANIA PÓL
 * Zgodność z JSON_NORMALIZATION_README.md i DART_MODELS_UPDATE_GUIDE.md
 */

// 🗂️ CENTRALNE MAPOWANIA PÓL - Priorytet: znormalizowane → stare nazwy

const FIELD_MAPPINGS = {
  // Client fields - based on split_investment_data/clients.json
  fullName: ['fullName'], // Already normalized in JSON
  companyName: ['companyName'], // Already normalized
  phone: ['phone'], // Already normalized
  email: ['email'], // Already normalized
  excelId: ['id'], // Maps to 'id' in clients.json
  isActive: ['isActive'],
  votingStatus: ['votingStatus'],
  unviableInvestments: ['unviableInvestments'],
  createdAt: ['createdAt'], // Already normalized

  // Investment fields - mix of Polish and English in JSON files
  investmentAmount: ['kwota_inwestycji'], // Polish in JSON
  remainingCapital: ['kapital_pozostaly'], // Polish in JSON
  realizedCapital: ['kapital_zrealizowany'], // Polish in JSON
  capitalForRestructuring: ['capitalForRestructuring', 'kapital_do_restrukturyzacji'], // Mixed
  capitalSecuredByRealEstate: ['realEstateSecuredCapital', 'kapital_zabezpieczony_nieruchomoscia'], // Mixed
  productType: ['productType', 'typ_produktu'], // Mixed
  contractDate: ['signingDate', 'data_podpisania'], // Mixed
  clientId: ['clientId', 'ID_Klient'], // Mixed
  client: ['clientName', 'Klient'], // Mixed
  collectionType: ['collectionType'], // Set programmatically
  
  // Bonds specific fields
  bondName: ['nazwa_obligacji'],
  issuer: ['emitent'],
  interestRate: ['oprocentowanie'],
  issueDate: ['emisja_data'],
  maturityDate: ['wykup_data'],
  
  // Shares specific fields  
  shareCount: ['shareCount'],
  pricePerShare: ['cena_za_udzial'],
  companyName: ['nazwa_spolki'],
  sharePercentage: ['procent_udzialow'],
  acquisitionDate: ['data_nabycia'],
  
  // Loans specific fields
  loanNumber: ['loanNumber'],
  borrower: ['pozyczkobiorca'],
  loanDate: ['data_udzielenia'],
  repaymentDate: ['data_splaty'],
  accrualInterest: ['odsetki_naliczone'],
  security: ['zabezpieczenie'],
  
  // Apartments specific fields
  apartmentNumber: ['apartmentNumber'],
  building: ['building'],
  address: ['address'],
  area: ['area'],
  roomCount: ['roomCount'],
  floor: ['floor'],
  pricePerM2: ['pricePerM2'],
  deliveryDate: ['deliveryDate'],
  developer: ['developer'],
  projectName: ['projectName'],
  balcony: ['balcony'],
  parkingSpace: ['parkingSpace'],
  storageRoom: ['storageRoom'],

  // Common fields for all investment types
  saleId: ['saleId', 'ID_Sprzedaz'],
  misaGuardian: ['misaGuardian', 'Opiekun z MISA'],
  branch: ['branch', 'Oddzial'],
  productStatus: ['productStatus', 'Status_produktu'],
  productStatusEntry: ['productStatusEntry', 'Produkt_status_wejscie'],
  investmentEntryDate: ['investmentEntryDate'],
  companyId: ['companyId'],
  creditorCompany: ['creditorCompany'],
  sourceFile: ['sourceFile', 'source_file'],
  uploadedAt: ['uploadedAt', 'uploaded_at'],
  status: ['status']
};

/**
 * Pobiera wartość pola według priorytetu mapowań
 * @param {Object} data - Obiekt z danymi
 * @param {string} normalizedField - Nazwa znormalizowanego pola
 * @param {*} defaultValue - Wartość domyślna
 * @returns {*} Wartość pola
 */
function getFieldValue(data, normalizedField, defaultValue = null) {
  const fieldVariants = FIELD_MAPPINGS[normalizedField];
  if (!fieldVariants) return data[normalizedField] ?? defaultValue;
  
  for (const fieldName of fieldVariants) {
    if (data[fieldName] != null) {
      return data[fieldName];
    }
  }
  return defaultValue;
}

/**
 * Bezpieczna konwersja na double z obsługą pustych stringów i formatów
 * @param {*} value - Wartość do konwersji
 * @param {number} defaultValue - Wartość domyślna
 * @returns {number} Skonwertowana wartość
 */
function safeToDouble(value, defaultValue = 0.0) {
  if (value == null || value === '') return defaultValue;
  if (typeof value === 'number') return value;
  if (typeof value === 'string') {
    // Obsługa formatów: "50,000.00", "50 000", "50.000,00"
    const cleaned = value.replace(/[,\s]/g, '').replace(/\.(?=\d{3})/g, '');
    const parsed = parseFloat(cleaned);
    return isNaN(parsed) ? defaultValue : parsed;
  }
  return defaultValue;
}

/**
 * Bezpieczna konwersja na integer
 * @param {*} value - Wartość do konwersji
 * @param {number} defaultValue - Wartość domyślna
 * @returns {number} Skonwertowana wartość
 */
function safeToInt(value, defaultValue = 0) {
  if (value == null || value === '') return defaultValue;
  if (typeof value === 'number') return Math.floor(value);
  if (typeof value === 'string') {
    const cleaned = value.replace(/[,\s]/g, '');
    const parsed = parseInt(cleaned);
    return isNaN(parsed) ? defaultValue : parsed;
  }
  return defaultValue;
}

/**
 * Bezpieczna konwersja na string
 * @param {*} value - Wartość do konwersji
 * @param {string} defaultValue - Wartość domyślna
 * @returns {string} Skonwertowana wartość
 */
function safeToString(value, defaultValue = '') {
  if (value == null) return defaultValue;
  return String(value);
}

/**
 * Konwertuje boolean z różnych formatów
 * @param {*} value - Wartość do konwersji
 * @param {boolean} defaultValue - Wartość domyślna
 * @returns {boolean} Skonwertowana wartość
 */
function safeToBoolean(value, defaultValue = false) {
  if (value == null) return defaultValue;
  if (typeof value === 'boolean') return value;
  if (typeof value === 'number') return value === 1;
  if (typeof value === 'string') {
    const lower = value.toLowerCase();
    return lower === 'true' || lower === '1' || lower === 'tak' || lower === 'yes';
  }
  return defaultValue;
}

/**
 * Parsuje datę z różnych formatów
 * @param {*} dateValue - Wartość daty do sparsowania
 * @returns {Date|null} Sparsowana data lub null
 */
function parseDate(dateValue) {
  if (!dateValue || dateValue === "NULL" || dateValue === "") return null;
  try {
    if (dateValue instanceof Date) return dateValue;
    if (typeof dateValue === 'string') {
      // Obsługa formatów: "2023-12-31", "31.12.2023", "31/12/2023"
      const date = new Date(dateValue.replace(/\./g, '-').replace(/\//g, '-'));
      return isNaN(date.getTime()) ? null : date;
    }
    return null;
  } catch (error) {
    return null;
  }
}

/**
 * Tworzy zunifikowany obiekt klienta ze znormalizowanymi polami
 * Compatible with split_investment_data/clients.json
 * @param {string} id - ID dokumentu
 * @param {Object} data - Dane klienta
 * @returns {Object} Zunifikowany obiekt klienta
 */
function createNormalizedClient(id, data) {
  return {
    id,
    // Exact field names from clients.json
    fullName: safeToString(data.fullName || data.imie_nazwisko, ''),
    companyName: safeToString(data.companyName || data.nazwa_firmy, ''),
    email: safeToString(data.email, ''),
    phone: safeToString(data.phone || data.telefon, ''),
    excelId: safeToString(data.id || data.excelId), // 'id' field in clients.json maps to excelId
    
    // Metadane
    createdAt: parseDate(data.createdAt || data.created_at),
    
    // Flagi - defaults for missing fields
    isActive: safeToBoolean(data.isActive, true),
    votingStatus: safeToString(data.votingStatus, 'undecided'),
    unviableInvestments: data.unviableInvestments || [],
  };
}

/**
 * Tworzy zunifikowany obiekt inwestycji ze znormalizowanymi polami
 * Compatible with split_investment_data JSON files
 * @param {string} id - ID dokumentu
 * @param {Object} data - Dane inwestycji
 * @param {string} collectionType - Typ kolekcji (investments, bonds, shares, loans, apartments)
 * @returns {Object} Zunifikowany obiekt inwestycji
 */
function createNormalizedInvestment(id, data, collectionType = null) {
  const normalizedCollectionType = collectionType || data.collectionType || 'investments';
  
  const investment = {
    id,
    collectionType: normalizedCollectionType,
    
    // === PODSTAWOWE INFORMACJE FINANSOWE === - exact field names from JSON
    investmentAmount: safeToDouble(data.kwota_inwestycji || data.investmentAmount),
    remainingCapital: safeToDouble(data.kapital_pozostaly || data.remainingCapital),
    realizedCapital: safeToDouble(data.kapital_zrealizowany || data.realizedCapital),
    capitalForRestructuring: safeToDouble(data.capitalForRestructuring || data.kapital_do_restrukturyzacji),
    capitalSecuredByRealEstate: safeToDouble(data.realEstateSecuredCapital || data.kapital_zabezpieczony_nieruchomoscia),
    
    // === KLIENT I SPRZEDAŻ === - exact field names from JSON  
    clientId: safeToString(data.clientId || data.ID_Klient),
    client: safeToString(data.clientName || data.Klient),
    saleId: safeToString(data.saleId || data.ID_Sprzedaz),
    
    // === PRODUKT === - exact field names from JSON
    productType: safeToString(data.productType || data.typ_produktu, normalizedCollectionType),
    productStatus: safeToString(data.productStatus || data.Status_produktu),
    productStatusEntry: safeToString(data.productStatusEntry || data.Produkt_status_wejscie),
    
    // === PERSONEL === - exact field names from JSON
    misaGuardian: safeToString(data.misaGuardian || data['Opiekun z MISA']),
    branch: safeToString(data.branch || data.Oddzial),
    companyId: safeToString(data.companyId),
    creditorCompany: safeToString(data.creditorCompany),
    
    // === DATY === - exact field names from JSON
    contractDate: parseDate(data.signingDate || data['Data_podpisania'] || data.contractDate),
    investmentEntryDate: parseDate(data.investmentEntryDate),
    
    // === METADANE === - exact field names from JSON  
    createdAt: parseDate(data.createdAt || data.created_at),
    uploadedAt: parseDate(data.uploadedAt || data.uploaded_at),
    sourceFile: safeToString(data.sourceFile || data.source_file),
    status: safeToString(data.status),
  };

  // === TYPE-SPECIFIC FIELDS === - exact field names from JSON
  switch (normalizedCollectionType) {
    case 'bonds':
      investment.bondName = safeToString(data.nazwa_obligacji);
      investment.issuer = safeToString(data.emitent);
      investment.interestRate = safeToString(data.oprocentowanie);
      investment.issueDate = parseDate(data.emisja_data);
      investment.maturityDate = parseDate(data.wykup_data);
      investment.interestRealized = safeToDouble(data.odsetki_zrealizowane);
      investment.interestRemaining = safeToDouble(data.odsetki_pozostale);
      investment.taxRealized = safeToDouble(data.podatek_zrealizowany);
      investment.taxRemaining = safeToDouble(data.podatek_pozostaly);
      investment.transferToOtherProduct = safeToDouble(data.przekaz_na_inny_produkt);
      break;

    case 'shares':
      investment.shareCount = safeToString(data.shareCount);
      investment.pricePerShare = safeToDouble(data.cena_za_udzial);
      investment.companyName = safeToString(data.nazwa_spolki);
      investment.sharePercentage = safeToString(data.procent_udzialow);
      investment.acquisitionDate = parseDate(data.data_nabycia);
      investment.companyNip = safeToString(data.nip_spolki);
      investment.sector = safeToString(data.sektor);
      break;

    case 'loans':
      investment.loanNumber = safeToString(data.loanNumber);
      investment.borrower = safeToString(data.pozyczkobiorca);
      investment.interestRate = safeToString(data.oprocentowanie);
      investment.loanDate = parseDate(data.data_udzielenia);
      investment.repaymentDate = parseDate(data.data_splaty);
      investment.accrualInterest = safeToDouble(data.odsetki_naliczone);
      investment.security = safeToString(data.zabezpieczenie);
      break;

    case 'apartments':
      investment.apartmentNumber = safeToString(data.apartmentNumber);
      investment.building = safeToString(data.building);
      investment.address = safeToString(data.address);
      investment.area = safeToString(data.area);
      investment.roomCount = safeToInt(data.roomCount);
      investment.floor = safeToInt(data.floor);
      investment.pricePerM2 = safeToString(data.pricePerM2);
      investment.deliveryDate = parseDate(data.deliveryDate);
      investment.developer = safeToString(data.developer);
      investment.projectName = safeToString(data.projectName);
      investment.balcony = safeToBoolean(data.balcony);
      investment.parkingSpace = safeToBoolean(data.parkingSpace);
      investment.storageRoom = safeToBoolean(data.storageRoom);
      break;
  }

  return investment;
}

module.exports = {
  FIELD_MAPPINGS,
  getFieldValue,
  safeToDouble,
  safeToInt, 
  safeToString,
  safeToBoolean,
  parseDate,
  createNormalizedClient,
  createNormalizedInvestment
};
