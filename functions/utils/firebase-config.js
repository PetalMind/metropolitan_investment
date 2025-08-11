/**
 * Firebase Configuration
 */

const admin = require("firebase-admin");

// Inicjalizuj Firebase Admin (tylko raz)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

module.exports = {
  admin,
  db,
};
