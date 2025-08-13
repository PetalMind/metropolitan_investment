/**
 * Data Mapping Utilities
 * Funkcje pomocnicze do mapowania i konwersji danych
 */

/**
 * Bezpieczna konwersja na double
 */
function safeToDouble(value) {
  // Handle null, undefined, empty string
  if (value === null || value === undefined || value === "") return 0.0;

  // Handle "NULL" string literal
  if (typeof value === "string" && (value.toUpperCase() === "NULL" || value.trim() === "")) {
    return 0.0;
  }

  // Handle numbers directly
  if (typeof value === "number") {
    if (isNaN(value) || !isFinite(value)) return 0.0;
    return value;
  }

  // Handle strings
  if (typeof value === "string") {
    const trimmed = value.trim();

    // Empty string after trim
    if (trimmed === "") {
      return 0.0;
    }

    // Handle comma-separated numbers (European format)

    // Obsługuj polskie separatory dziesiętne i tysiące
    let cleaned = trimmed
      .replace(/\s/g, "") // usuń spacje
      .replace(/,/g, ".") // zamień przecinki na kropki
      .replace(/[^\d.-]/g, ""); // usuń wszystko oprócz cyfr, kropek i minusów

    const parsed = parseFloat(cleaned);

    if (isNaN(parsed) || !isFinite(parsed)) {
      return 0.0;
    }

    return parsed;
  }

  // Fallback for other types
  return 0.0;
}

/**
 * Bezpieczna konwersja na int
 */
function safeToInt(value) {
  if (value === null || value === undefined || value === "") return 0;
  if (typeof value === "number") return Math.floor(value);
  if (typeof value === "string") {
    const cleaned = value.replace(/[^\d-]/g, "");
    const parsed = parseInt(cleaned, 10);
    return isNaN(parsed) ? 0 : parsed;
  }
  return 0;
}

/**
 * Bezpieczna konwersja na string
 */
function safeToString(value) {
  if (value === null || value === undefined) return "";
  return String(value).trim();
}

/**
 * Bezpieczna konwersja na boolean
 */
function safeToBoolean(value) {
  if (typeof value === "boolean") return value;
  if (typeof value === "string") {
    return value.toLowerCase() === "true" || value === "1" || value === "tak";
  }
  if (typeof value === "number") return value !== 0;
  return false;
}

/**
 * Parsuje datę z różnych formatów
 */
function parseDate(value) {
  if (!value) return null;

  try {
    // Jeśli to już timestamp Firestore
    if (value && typeof value.toDate === "function") {
      return value.toDate().toISOString();
    }

    // Jeśli to string daty
    if (typeof value === "string") {
      const date = new Date(value);
      return isNaN(date.getTime()) ? null : date.toISOString();
    }

    // Jeśli to Date object
    if (value instanceof Date) {
      return isNaN(value.getTime()) ? null : value.toISOString();
    }

    return null;
  } catch (error) {
    return null;
  }
}

/**
 * Mapuje typ produktu z danych do standardowego formatu
 */
function mapProductType(productType) {
  if (!productType) return 'other';

  const type = productType.toLowerCase();

  switch (type) {
    case 'apartment':
    case 'mieszkanie':
    case 'apartament':
      return 'apartments';
    case 'bond':
    case 'bonds':
    case 'obligacja':
    case 'obligacje':
      return 'bonds';
    case 'share':
    case 'shares':
    case 'udzial':
    case 'udzialy':
      return 'shares';
    case 'loan':
    case 'loans':
    case 'pozyczka':
    case 'pozyczki':
      return 'loans';
    default:
      return 'other';
  }
}

/**
 * Mapuje status produktu do standardowego formatu
 */
function mapProductStatus(status) {
  if (!status) return 'active';

  const statusLower = status.toLowerCase();

  if (statusLower.includes('aktywn') || statusLower.includes('dostępn')) {
    return 'active';
  }
  if (statusLower.includes('nieaktywn') || statusLower.includes('niedostępn')) {
    return 'inactive';
  }
  if (statusLower.includes('oczeku') || statusLower.includes('pending')) {
    return 'pending';
  }
  if (statusLower.includes('zawiesz') || statusLower.includes('suspend')) {
    return 'suspended';
  }

  return 'active'; // domyślnie aktywny
}

module.exports = {
  safeToDouble,
  safeToInt,
  safeToString,
  safeToBoolean,
  parseDate,
  mapProductType,
  mapProductStatus,
};
