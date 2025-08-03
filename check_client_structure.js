const admin = require("firebase-admin");
admin.initializeApp({
  credential: admin.credential.cert(require("./service-account.json")),
});
const db = admin.firestore();

async function checkClientStructure() {
  try {
    const snapshot = await db.collection("clients").limit(3).get();

    if (snapshot.empty) {
      console.log("No clients found");
      return;
    }

    snapshot.forEach((doc) => {
      console.log("\n=== CLIENT DOCUMENT ===");
      console.log("Firebase UUID:", doc.id);
      const data = doc.data();
      console.log("Document data:", JSON.stringify(data, null, 2));

      // Sprawdź czy jest gdzieś oryginalne ID
      if (data.id) console.log("Original ID found:", data.id);
      if (data.original_id) console.log("Original ID found:", data.original_id);
      if (data.client_id) console.log("Client ID found:", data.client_id);
      if (data.excel_id) console.log("Excel ID found:", data.excel_id);
    });
  } catch (error) {
    console.error("Error:", error);
  }

  process.exit(0);
}

checkClientStructure();
