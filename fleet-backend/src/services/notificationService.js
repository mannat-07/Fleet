const { getDb, COLLECTIONS } = require('../config/firebase');
const { computeStatus } = require('./insuranceService');

// ─── Builders ─────────────────────────────────────────────────────────────────

/**
 * Returns a notification record if the insurance is expiring within 1–5 days.
 * @param {object} insurance  Insurance record from Firestore
 * @param {string} truckPlate Plate number of the truck
 * @param {Date}   serverDate Current server date
 * @returns {object|null}
 */
function buildExpiringNotification(insurance, truckPlate, serverDate) {
  const { daysUntilExpiry } = computeStatus(insurance.startDate, insurance.expiryDate, serverDate);
  if (daysUntilExpiry >= 1 && daysUntilExpiry <= 5) {
    return {
      type: 'expiring_soon',
      truckId: insurance.truckId,
      truckPlate,
      daysUntilExpiry,
      message: `Insurance for ${truckPlate} expires in ${daysUntilExpiry} day${daysUntilExpiry === 1 ? '' : 's'}`,
    };
  }
  return null;
}

/**
 * Returns a notification record if the insurance has already expired.
 * @param {object} insurance  Insurance record from Firestore
 * @param {string} truckPlate Plate number of the truck
 * @param {Date}   serverDate Current server date
 * @returns {object|null}
 */
function buildExpiredNotification(insurance, truckPlate, serverDate) {
  const { daysUntilExpiry } = computeStatus(insurance.startDate, insurance.expiryDate, serverDate);
  if (daysUntilExpiry < 0) {
    const daysAgo = Math.abs(daysUntilExpiry);
    return {
      type: 'expired',
      truckId: insurance.truckId,
      truckPlate,
      daysUntilExpiry,
      message: `Insurance for ${truckPlate} expired ${daysAgo} day${daysAgo === 1 ? '' : 's'} ago`,
    };
  }
  return null;
}

/**
 * Returns a pending insurance notification for a truck with no insurance record.
 * @param {object} truck Truck record from Firestore
 * @returns {object}
 */
function buildPendingNotification(truck) {
  return {
    type: 'pending_insurance',
    truckId: truck.truckId,
    truckPlate: truck.plate,
    message: `No insurance record found for truck ${truck.plate}`,
  };
}

// ─── Main service function ────────────────────────────────────────────────────

/**
 * Compute all active notifications for a fleet owner in real-time.
 * Never writes to Firestore.
 * @param {string} ownerId Firebase Auth UID of the fleet owner
 * @returns {{ notifications: object[], count: number }}
 */
async function getNotifications(ownerId) {
  const db = getDb();
  const serverDate = new Date();

  // Fetch trucks and insurance records in parallel
  const [trucksSnap, insuranceSnap] = await Promise.all([
    db.collection(COLLECTIONS.TRUCKS).where('ownerId', '==', ownerId).get(),
    db.collection(COLLECTIONS.INSURANCE).where('ownerId', '==', ownerId).get(),
  ]);

  const trucks = trucksSnap.docs.map(d => d.data());
  const insuranceRecords = insuranceSnap.docs.map(d => d.data());

  // Build a map of truckId → insurance record for quick lookup
  const insuranceByTruckId = {};
  for (const ins of insuranceRecords) {
    insuranceByTruckId[ins.truckId] = ins;
  }

  // Build a map of truckId → plate for enriching insurance notifications
  const plateByTruckId = {};
  for (const truck of trucks) {
    plateByTruckId[truck.truckId] = truck.plate;
  }

  const notifications = [];

  // Check each insurance record for expiry notifications
  for (const ins of insuranceRecords) {
    const plate = plateByTruckId[ins.truckId] || ins.truckId;

    const expiring = buildExpiringNotification(ins, plate, serverDate);
    if (expiring) notifications.push(expiring);

    const expired = buildExpiredNotification(ins, plate, serverDate);
    if (expired) notifications.push(expired);
  }

  // Check each truck for pending insurance (no insurance record)
  for (const truck of trucks) {
    if (!insuranceByTruckId[truck.truckId]) {
      notifications.push(buildPendingNotification(truck));
    }
  }

  return { notifications, count: notifications.length };
}

module.exports = {
  getNotifications,
  buildExpiringNotification,
  buildExpiredNotification,
  buildPendingNotification,
};
