/**
 * Data Mapping Utilities
 * Helper functions for data mapping and conversion
 */

/**
 * Safe conversion to double
 */
function safeToDouble(value) {
  // Handle null, undefined, empty string
  if (value === null || value === undefined || value === "") return 0.0;

  // Handle "NULL" string literal
  if (typeof value === "string" && (value.toUpperCase() === "NULL" || value.trim() === "")) {
    console.log(`❌ [Analytics] Cannot parse: "${value}" -> "${value}"`);
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
      console.log(`❌ [Analytics] Cannot parse: "${value}" -> "${value}"`);
      return 0.0;
    }

    // Handle comma-separated numbers (European format)
    console.log(`🔍 [Analytics] Parsing value with comma: "${trimmed}"`);

    // Handle Polish decimal and thousand separators
    let cleaned = trimmed
      .replace(/\s/g, "") // remove spaces
      .replace(/,/g, ".") // replace commas with dots
      .replace(/[^\d.-]/g, ""); // remove everything except digits, dots and minus

    const parsed = parseFloat(cleaned);

    if (isNaN(parsed) || !isFinite(parsed)) {
      console.log(`❌ [Analytics] Cannot parse: "${value}" -> "${value}"`);
      return 0.0;
    }

    return parsed;
  }

  // Fallback for other types
  console.log(`❌ [Analytics] Unsupported type for: "${value}"`);
  return 0.0;
}

/**
 * Safe conversion to int
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
 * Safe conversion to string
 */
function safeToString(value) {
  if (value === null || value === undefined) return "";
  return String(value).trim();
}

/**
 * Safe conversion to boolean
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
 * Parses date from various formats
 */
function parseDate(value) {
  if (!value) return null;

  try {
    // If it's already a Firestore timestamp
    if (value && typeof value.toDate === "function") {
      return value.toDate().toISOString();
    }

    // If it's a date string
    if (typeof value === "string") {
      const date = new Date(value);
      return isNaN(date.getTime()) ? null : date.toISOString();
    }

    // If it's a Date object
    if (value instanceof Date) {
      return isNaN(value.getTime()) ? null : value.toISOString();
    }

    return null;
  } catch (error) {
    console.warn("Date parsing error:", value, error);
    return null;
  }
}

/**
 * Maps product type from data to standard format
 * UPDATED: Handle normalized data from JSON import
 */
function mapProductType(productType) {
  if (!productType) return 'other';

  const type = productType.toString().toLowerCase().trim();

  // Handle normalized types from JSON
  if (type === 'apartamenty' || type.includes('apartament')) {
    return 'apartments';
  }
  if (type === 'obligacje' || type.includes('obligacj')) {
    return 'bonds';
  }
  if (type === 'udziały' || type.includes('udział')) {
    return 'shares';
  }
  if (type === 'pożyczki' || type.includes('pożyczk')) {
    return 'loans';
  }

  // Handle English names
  switch (type) {
    case 'apartment':
    case 'apartments':
    case 'mieszkanie':
      return 'apartments';
    case 'bond':
    case 'bonds':
    case 'obligacja':
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
      console.log(`⚠️ [mapProductType] Unknown product type: "${productType}" -> fallback: 'other'`);
      return 'other';
  }
}

/**
 * Maps product status to standard format
 * UPDATED: Handle normalized statuses from JSON import
 */
function mapProductStatus(status) {
  if (!status) return 'active';

  const statusLower = status.toString().toLowerCase().trim();

  // Handle Polish statuses from JSON
  if (statusLower === 'aktywny' || statusLower.includes('aktywn')) {
    return 'active';
  }
  if (statusLower === 'nieaktywny' || statusLower.includes('nieaktywn')) {
    return 'inactive';
  }
  if (statusLower === 'zakończony' || statusLower.includes('zakończ')) {
    return 'completed';
  }
  if (statusLower === 'wykup wczesniejszy' || statusLower.includes('wykup')) {
    return 'earlyRedemption';
  }

  // Handle English statuses
  if (statusLower.includes('dostępn') || statusLower === 'available') {
    return 'active';
  }
  if (statusLower.includes('niedostępn') || statusLower === 'unavailable') {
    return 'inactive';
  }
  if (statusLower.includes('oczeku') || statusLower.includes('pending')) {
    return 'pending';
  }
  if (statusLower.includes('zawiesz') || statusLower.includes('suspend')) {
    return 'suspended';
  }

  console.log(`⚠️ [mapProductStatus] Unknown status: "${status}" -> fallback: 'active'`);
  return 'active'; // default to active
}

/**
 * Formats currency for display
 */
function formatCurrency(value, currency = 'PLN') {
  const amount = safeToDouble(value);
  return `${amount.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ' ')} ${currency}`;
}

module.exports = {
  safeToDouble,
  safeToInt,
  safeToString,
  safeToBoolean,
  parseDate,
  mapProductType,
  mapProductStatus,
  formatCurrency,
};
