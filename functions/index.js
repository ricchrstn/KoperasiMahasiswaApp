/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */


// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
exports.sendNotifications = functions.pubsub
    .schedule("every hour")
    .onRun(async (context) => {
      const currentHour = new Date().getHours(); // Ambil jam saat ini
      const usersSnapshot = await admin.firestore().collection("users").get();

      usersSnapshot.forEach(async (userDoc) => {
        const userData = userDoc.data();
        const optimalHour = userData.optimalNotificationHour; // Jam optimal dari Firestore

        if (optimalHour === currentHour) {
          const deviceToken = userData.deviceToken; // Token perangkat pengguna
          if (deviceToken) {
          // Kirim notifikasi menggunakan FCM
            await admin.messaging().sendToDevice(deviceToken, {
              notification: {
                title: "Pengingat Koperasi",
                body: "Jangan lupa cek aktivitas koperasi Anda hari ini!",
              },
            });
            console.log(`Notifikasi dikirim ke ${userDoc.id}`);
          }
        }
      });
    });
