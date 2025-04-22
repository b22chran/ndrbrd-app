const admin = require("firebase-admin");
const fs = require("fs");
const csv = require("csv-parser");

// Initialize Firebase Admin SDK
const serviceAccount = require("./weather-app-e6ab5-firebase-adminsdk-fbsvc-aa8602e6dd.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Function to import CSV
const importCSV = async (filePath, collectionName) => {
  const data = [];

  fs.createReadStream(filePath)
    .pipe(csv({ separator: "," })) 
    .on("data", (row) => {
      data.push(row);
    })
    .on("end", async () => {
      console.log(`Read ${data.length} records. Importing to Firestore...`);
      const batch = db.batch();

      data.forEach((record, index) => {
        const docRef = db.collection(collectionName).doc(); // Auto-generate ID
        batch.set(docRef, record);
      });

      await batch.commit();
      console.log("CSV successfully imported to Firestore!");
    });
};

// Run the script
importCSV("./datandrbrd-update.csv", "ndrbrd");
