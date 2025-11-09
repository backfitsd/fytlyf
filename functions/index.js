const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const auth = admin.auth();
const db = admin.firestore();

/**
 * Runs every 2 minutes.
 * Finds accounts created but not verified within 10 minutes.
 * Deletes:
 *   - Firebase Auth user
 *   - users/{uid} (if exists)
 *   - pending_users/{uid}
 *   - usernames/{username}
 */
exports.cleanUnverifiedAccounts = functions.pubsub
  .schedule("every 2 minutes")
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const cutoff = new Date(now.toDate().getTime() - 10 * 60 * 1000); // 10 minutes

    const pendingSnap = await db
      .collection("pending_users")
      .where("createdAt", "<=", cutoff)
      .get();

    if (pendingSnap.empty) return null;

    const batch = db.batch();

    for (const doc of pendingSnap.docs) {
      const uid = doc.id;
      const data = doc.data();
      const username = data.username;

      // 1. Delete username reservation
      if (username) {
        batch.delete(db.collection("usernames").doc(username));
      }

      // 2. Delete pending entry
      batch.delete(db.collection("pending_users").doc(uid));

      // 3. Delete Firestore user doc if exists
      batch.delete(db.collection("users").doc(uid));

      // 4. Delete auth user
      try {
        await auth.deleteUser(uid);
      } catch (err) {
        console.error("Failed to delete auth user:", err);
      }
    }

    await batch.commit();
    return null;
  });
