const { v4: uuidv4 } = require('uuid');
const admin = require('firebase-admin');
const { getDb, COLLECTIONS } = require('../config/firebase');

const VALID_STATUSES = ['active', 'on_trip', 'idle', 'maintenance'];

async function addTruck({ ownerId, plate, model, type, year }) {
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
    assignedDriverId: null,
    lastLocation: null,
    lastSeen: null,
    createdAt: now, updatedAt: now,
  };

  await db.collection(COLLECTIONS.TRUCKS).doc(truckId).set(truck);
  return truck;
}

async function getTrucks(ownerId) {
  const db   = getDb();
  // Fetch without orderBy to avoid requiring a composite index.
  // Sort in-memory by createdAt descending.
  const snap = await db.collection(COLLECTIONS.TRUCKS)
    .where('ownerId', '==', ownerId)
    .get();
  return snap.docs
    .map(d => d.data())
    .sort((a, b) => {
      const ta = a.createdAt?.toMillis?.() ?? 0;
      const tb = b.createdAt?.toMillis?.() ?? 0;
      return tb - ta;
    });
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
  await doc.ref.delete();
}

module.exports = { addTruck, getTrucks, getTruckById, updateTruckStatus, deleteTruck };
