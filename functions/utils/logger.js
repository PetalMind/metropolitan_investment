/**
 * Simple logger utility for Firebase Functions
 */

function logInfo(service, message) {
  console.log(`[INFO] [${service}] ${message}`);
}

function logError(service, error) {
  console.error(`[ERROR] [${service}] ${error}`);
}

function logWarning(service, message) {
  console.warn(`[WARNING] [${service}] ${message}`);
}

function logDebug(service, message) {
  console.debug(`[DEBUG] [${service}] ${message}`);
}

module.exports = {
  logInfo,
  logError,
  logWarning,
  logDebug,
};
