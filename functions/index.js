const {setGlobalOptions} = require("firebase-functions/v2");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();
setGlobalOptions({region: "europe-west1", maxInstances: 10});

const database = getFirestore();

exports.onListingRequestCreated = onDocumentCreated(
  "listingRequests/{requestId}",
  async (event) => {
    const request = event.data?.data();
    if (!request?.listingOwnerId) return;

    const requesterName = request.requesterName || "Bir kullanıcı";
    const listingTitle = request.listingTitle || "ilanınız";

    await notifyUser(request.listingOwnerId, {
      title: "Yeni ilan talebi",
      body: `${requesterName}, “${listingTitle}” ilanıyla ilgileniyor.`,
      type: "requestReceived",
      listingId: request.listingId || "",
      requestId: event.params.requestId,
    });
  },
);

exports.onListingRequestStatusUpdated = onDocumentUpdated(
  "listingRequests/{requestId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!after?.requesterId || before?.status === after.status) return;
    if (after.status !== "accepted" && after.status !== "rejected") return;

    const accepted = after.status === "accepted";
    const listingTitle = after.listingTitle || "İlan";

    await notifyUser(after.requesterId, {
      title: accepted ? "Talebin kabul edildi" : "Talebin reddedildi",
      body: accepted
        ? `“${listingTitle}” ilanı için iletişim bilgisi açıldı.`
        : `“${listingTitle}” ilanı için gönderdiğin talep reddedildi.`,
      type: accepted ? "requestAccepted" : "requestRejected",
      listingId: after.listingId || "",
      requestId: event.params.requestId,
    });
  },
);

async function notifyUser(userId, notification) {
  const notificationReference = database
    .collection("users")
    .doc(userId)
    .collection("notifications")
    .doc();

  await notificationReference.set({
    ...notification,
    isRead: false,
    createdAt: FieldValue.serverTimestamp(),
  });

  const devices = await database
    .collection("users")
    .doc(userId)
    .collection("devices")
    .limit(500)
    .get();
  const deviceDocuments = devices.docs.filter(
    (document) => typeof document.data().token === "string",
  );
  const tokens = deviceDocuments.map((document) => document.data().token);
  if (tokens.length === 0) return;

  const response = await getMessaging().sendEachForMulticast({
    tokens,
    notification: {
      title: notification.title,
      body: notification.body,
    },
    data: {
      type: notification.type,
      listingId: notification.listingId,
      requestId: notification.requestId,
      notificationId: notificationReference.id,
    },
    android: {
      priority: "high",
      notification: {channelId: "requests"},
    },
    apns: {
      payload: {aps: {sound: "default"}},
    },
  });

  const invalidCodes = new Set([
    "messaging/invalid-registration-token",
    "messaging/registration-token-not-registered",
  ]);
  const deletions = [];
  response.responses.forEach((result, index) => {
    if (!result.success && invalidCodes.has(result.error?.code)) {
      deletions.push(deviceDocuments[index].ref.delete());
    }
  });
  await Promise.all(deletions);
}
