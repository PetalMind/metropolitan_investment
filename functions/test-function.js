/**
 * 🧪 FUNKCJA TESTOWA - sprawdzenie czy Firebase Functions działają
 */

const {onCall} = require("firebase-functions/v2/https");

exports.testFunction = onCall({
  region: "europe-west1",
}, async (request) => {

  return {
    success: true,
    message: "Firebase Functions działają poprawnie!",
    timestamp: new Date().toISOString(),
    requestData: request.data || {},
  };
});
