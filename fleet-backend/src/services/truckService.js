const { v4: uuidv4 } = require('uuid');
const admin = require('firebase-admin');
const { getDb, COLLECTIONS } = require('../config/firebase');

const VALID_STATUSES = ['active', 'on_trip', 'idle', 'maintenance'];

/**
 * @param {{ ownerId, plate, model, type, year, driverId? }} params
 */
async function addTruck({ ownerId, plate, model, type, year, driverId }) {
  const db = getDb();

  // Unique plate check
  const existing = await db.collection(COLLECTIONS.TRUCKS)
    .where('plate', '==', plate.toUpperCase()).limit(1).get();
  if (!existing.empty) {
    const err = new Error('Truck with this plate already exists'); err.statusCode = 409; throw err;
  }

  const truckId = uuidv4();
  const now     = admin.firestore.FieldValue.serverTimestamp();

  const truck = {
    truckId, ownerId,
    plate: plate.toUpperCase(),
    model: model || null,
    type:  type  || null,
    year:  year  || null,
    status: 'idle',
    assignedDriverId: driverId || null,
    lastLocation: null,
    lastSeen: null,
    createdAt: now, updatedAt: now,
  };

  if (driverId) {
    // Race-condition guard: verify driver is still available
    const driverDoc = await db.collection(COLLECTIONS.DRIVERS).doc(driverId).get();
    if (!driverDoc.exists) {
      const err = new Error('Driver not found'); err.statusCode = 404; throw err;
    }
    const driverData = driverDoc.data();
    if (driverData.ownerId !== ownerId) {
      const err = new Error('Forbidden'); err.statusCode = 403; throw err;
    }
    if (driverData.status !== 'available' || driverData.assignedTruckId !== null) {
      const err = new Error('Selected driver is no longer available'); err.statusCode = 409; throw err;
    }

    // Atomic batch write: create truck + update driver
    const batch = db.batch();
    batch.set(db.collection(COLLECTIONS.TRUCKS).doc(truckId), truck);
    batch.update(driverDoc.ref, {
      assignedTruckId: truckId,
      status: 'on_trip',
      updatedAt: now,
    });
    await batch.commit();
  } else {
    await db.collection(COLLECTIONS.TRUCKS).doc(truckId).set(truck);
  }

  return truck;
}

/**
 * @param {string} ownerId
 * @param {{ status?: string }} filters
 */
async function getTrucks(ownerId, filters = {}) {
  const db   = getDb();
  const snap = await db.collection(COLLECTIONS.TRUCKS)
    .where('ownerId', '==', ownerId)
    .get();

  let trucks = snap.docs
    .map(d => d.data())
    .sort((a, b) => {
      const ta = a.createdAt?.toMillis?.() ?? 0;
      const tb = b.createdAt?.toMillis?.() ?? 0;
      return tb - ta;
    });

  // In-memory filter for idle trucks (avoids composite index)
  if (filters.status === 'idle') {
    trucks = trucks.filter(t => t.status === 'idle' && t.assignedDriverId === null);
  }

  return trucks;
}

async function getTruckById(truckId, ownerId) {
  const db  = getDb();
  const doc = await db.collection(COLLECTIONS.TRUCKS).doc(truckId).get();
  if (!doc.exists) { const err = new Error('Truck not found'); err.statusCode = 404; throw err; }
  const truck = doc.data();
  if (truck.ownerId !== ownerId) { const err = new Error('Forbidden'); err.statusCode = 403; throw err; }
  return truck;
}

async function updateTruckStatus(truckId, ownerId, status) {
  if (!VALID_STATUSES.includes(status)) {
    const err = new Error(`Invalid status. Must be one of: ${VALID_STATUSES.join(', ')}`);
    err.statusCode = 400; throw err;
  }
  const db  = getDb();
  const doc = await db.collection(COLLECTIONS.TRUCKS).doc(truckId).get();
  if (!doc.exists) { const err = new Error('Truck not found'); err.statusCode = 404; throw err; }
  if (doc.data().ownerId !== ownerId) { const err = new Error('Forbidden'); err.statusCode = 403; throw err; }

  await doc.ref.update({ status, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
  return { truckId, status };
}

async function deleteTruck(truckId, ownerId) {
  const db  = getDb();
  const doc = await db.collection(COLLECTIONS.TRUCKS).doc(truckId).get();
  if (!doc.exists) { const err = new Error('Truck not found'); err.statusCode = 404; throw err; }
  if (doc.data().ownerId !== ownerId) { const err = new Error('Forbidden'); err.statusCode = 403; throw err; }

  const batch = db.batch();
  batch.delete(doc.ref);

  // Cascade: delete associated insurance record if it exists
  const insuranceSnap = await db.collection(COLLECTIONS.INSURANCE)
    .where('truckId', '==', truckId)
    .limit(1)
    .get();
  if (!insuranceSnap.empty) {
    batch.delete(insuranceSnap.docs[0].ref);
  }

  await batch.commit();
}

module.exports = { addTruck, getTrucks, getTruckById, updateTruckStatus, deleteTruck };
