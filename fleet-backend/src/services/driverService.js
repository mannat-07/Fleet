const { v4: uuidv4 } = require('uuid');
const admin = require('firebase-admin');
const { getDb, COLLECTIONS } = require('../config/firebase');

async function addDriver({ ownerId, name, phone, licenseNumber, licenseExpiry }) {
  const db = getDb();

  const driverId = uuidv4();
  const now      = admin.firestore.FieldValue.serverTimestamp();

  const driver = {
    driverId, ownerId, name,
    phone:          phone          || null,
    licenseNumber:  licenseNumber  || null,
    licenseExpiry:  licenseExpiry  || null,
    assignedTruckId: null,
    status: 'available',   // available | on_trip | off_duty
    createdAt: now, updatedAt: now,
  };

  await db.collection(COLLECTIONS.DRIVERS).doc(driverId).set(driver);
  return driver;
}

async function getDrivers(ownerId) {
  const db   = getDb();
  const snap = await db.collection(COLLECTIONS.DRIVERS)
    .where('ownerId', '==', ownerId)
    .orderBy('createdAt', 'desc')
    .get();
  return snap.docs.map(d => d.data());
}

async function getDriverById(driverId, ownerId) {
  const db  = getDb();
  const doc = await db.collection(COLLECTIONS.DRIVERS).doc(driverId).get();
  if (!doc.exists) { const err = new Error('Driver not found'); err.statusCode = 404; throw err; }
  const driver = doc.data();
  if (driver.ownerId !== ownerId) { const err = new Error('Forbidden'); err.statusCode = 403; throw err; }
  return driver;
}

async function assignDriver(driverId, truckId, ownerId) {
  const db = getDb();

  // Verify ownership of both
  const [driverDoc, truckDoc] = await Promise.all([
    db.collection(COLLECTIONS.DRIVERS).doc(driverId).get(),
    db.collection(COLLECTIONS.TRUCKS).doc(truckId).get(),
  ]);

  if (!driverDoc.exists) { const err = new Error('Driver not found'); err.statusCode = 404; throw err; }
  if (!truckDoc.exists)  { const err = new Error('Truck not found');  err.statusCode = 404; throw err; }
  if (driverDoc.data().ownerId !== ownerId || truckDoc.data().ownerId !== ownerId) {
    const err = new Error('Forbidden'); err.statusCode = 403; throw err;
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  const batch = db.batch();

  batch.update(driverDoc.ref, { assignedTruckId: truckId, status: 'on_trip', updatedAt: now });
  batch.update(truckDoc.ref,  { assignedDriverId: driverId, updatedAt: now });

  await batch.commit();
  return { driverId, truckId, status: 'assigned' };
}

async function unassignDriver(driverId, ownerId) {
  const db  = getDb();
  const doc = await db.collection(COLLECTIONS.DRIVERS).doc(driverId).get();
  if (!doc.exists) { const err = new Error('Driver not found'); err.statusCode = 404; throw err; }
  if (doc.data().ownerId !== ownerId) { const err = new Error('Forbidden'); err.statusCode = 403; throw err; }

  const { assignedTruckId } = doc.data();
  const now = admin.firestore.FieldValue.serverTimestamp();
  const batch = db.batch();

  batch.update(doc.ref, { assignedTruckId: null, status: 'available', updatedAt: now });

  if (assignedTruckId) {
    const truckRef = db.collection(COLLECTIONS.TRUCKS).doc(assignedTruckId);
    batch.update(truckRef, { assignedDriverId: null, updatedAt: now });
  }

  await batch.commit();
  return { driverId, status: 'unassigned' };
}

module.exports = { addDriver, getDrivers, getDriverById, assignDriver, unassignDriver };
