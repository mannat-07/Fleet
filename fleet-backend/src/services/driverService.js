const { v4: uuidv4 } = require('uuid');
const admin = require('firebase-admin');
const { getDb, COLLECTIONS } = require('../config/firebase');

/**
 * Create a driver — also creates a Firebase Auth account + users doc
 * so the driver can log in immediately.
 *
 * Optionally assigns an idle truck atomically.
 *
 * Returns the driver record plus { email, tempPassword } for the owner to share.
 */
async function addDriver({ ownerId, name, phone, licenseNumber, licenseExpiry, email, password, truckId }) {
  const db = getDb();

  // ── 1. Derive login credentials ──────────────────────────────────────────
  if (!email) {
    const err = new Error('Driver email is required'); err.statusCode = 400; throw err;
  }

  const tempPassword = password || _generatePassword();
  const normalEmail  = email.toLowerCase().trim();

  // ── 2. Check email not already in use ────────────────────────────────────
  const existing = await db.collection(COLLECTIONS.USERS)
    .where('email', '==', normalEmail).limit(1).get();
  if (!existing.empty) {
    const err = new Error('A user with this email already exists'); err.statusCode = 409; throw err;
  }

  // ── 3. If truckId provided, verify truck is still idle (race-condition guard) ──
  let truckDoc = null;
  if (truckId) {
    truckDoc = await db.collection(COLLECTIONS.TRUCKS).doc(truckId).get();
    if (!truckDoc.exists) {
      const err = new Error('Truck not found'); err.statusCode = 404; throw err;
    }
    const truckData = truckDoc.data();
    if (truckData.ownerId !== ownerId) {
      const err = new Error('Forbidden'); err.statusCode = 403; throw err;
    }
    if (truckData.status !== 'idle' || truckData.assignedDriverId !== null) {
      const err = new Error('Selected truck is no longer available'); err.statusCode = 409; throw err;
    }
  }

  // ── 4. Create Firebase Auth account ──────────────────────────────────────
  let authUser;
  try {
    authUser = await admin.auth().createUser({
      email:         normalEmail,
      password:      tempPassword,
      displayName:   name,
      emailVerified: false,
    });
  } catch (authErr) {
    if (authErr.code === 'auth/email-already-exists') {
      const err = new Error('A user with this email already exists'); err.statusCode = 409; throw err;
    }
    throw authErr;
  }

  const uid = authUser.uid;
  const now = admin.firestore.FieldValue.serverTimestamp();

  // ── 5. Write users doc (role = driver) ───────────────────────────────────
  const userData = {
    uid,
    name,
    email:          normalEmail,
    phone:          phone || null,
    role:           'driver',
    disabled:       false,
    avatarInitials: _initials(name),
    createdAt:      now,
    updatedAt:      now,
  };

  // ── 6. Write drivers doc ──────────────────────────────────────────────────
  const driver = {
    driverId:        uid,
    ownerId,
    uid,
    name,
    email:           normalEmail,
    phone:           phone          || null,
    licenseNumber:   licenseNumber  || null,
    licenseExpiry:   licenseExpiry  || null,
    assignedTruckId: truckId        || null,
    status:          truckId ? 'on_trip' : 'available',
    createdAt:       now,
    updatedAt:       now,
  };

  if (truckId && truckDoc) {
    // Atomic batch: create user doc, create driver doc, update truck
    const batch = db.batch();
    batch.set(db.collection(COLLECTIONS.USERS).doc(uid), userData);
    batch.set(db.collection(COLLECTIONS.DRIVERS).doc(uid), driver);
    batch.update(truckDoc.ref, {
      assignedDriverId: uid,
      updatedAt: now,
    });
    await batch.commit();
  } else {
    // No truck assignment — sequential writes (existing behaviour)
    await db.collection(COLLECTIONS.USERS).doc(uid).set(userData);
    await db.collection(COLLECTIONS.DRIVERS).doc(uid).set(driver);
  }

  return {
    ...driver,
    tempPassword,
  };
}

function _generatePassword() {
  const chars = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789@#';
  let pwd = '';
  for (let i = 0; i < 10; i++) pwd += chars[Math.floor(Math.random() * chars.length)];
  return pwd;
}

function _initials(name = '') {
  const parts = name.trim().split(' ');
  if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
  return name.length > 0 ? name[0].toUpperCase() : '?';
}

/**
 * @param {string} ownerId
 * @param {{ status?: string }} filters
 */
async function getDrivers(ownerId, filters = {}) {
  const db   = getDb();
  const snap = await db.collection(COLLECTIONS.DRIVERS)
    .where('ownerId', '==', ownerId)
    .get();

  let drivers = snap.docs
    .map(d => d.data())
    .sort((a, b) => {
      const ta = a.createdAt?.toMillis?.() ?? 0;
      const tb = b.createdAt?.toMillis?.() ?? 0;
      return tb - ta;
    });

  // In-memory filter for available drivers (avoids composite index)
  if (filters.status === 'available') {
    drivers = drivers.filter(d => d.status === 'available' && d.assignedTruckId === null);
  }

  return drivers;
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

  const [driverDoc, truckDoc] = await Promise.all([
    db.collection(COLLECTIONS.DRIVERS).doc(driverId).get(),
    db.collection(COLLECTIONS.TRUCKS).doc(truckId).get(),
  ]);

  if (!driverDoc.exists) { const err = new Error('Driver not found'); err.statusCode = 404; throw err; }
  if (!truckDoc.exists)  { const err = new Error('Truck not found');  err.statusCode = 404; throw err; }
  if (driverDoc.data().ownerId !== ownerId || truckDoc.data().ownerId !== ownerId) {
    const err = new Error('Forbidden'); err.statusCode = 403; throw err;
  }

  const now   = admin.firestore.FieldValue.serverTimestamp();
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
  const now   = admin.firestore.FieldValue.serverTimestamp();
  const batch = db.batch();
  batch.update(doc.ref, { assignedTruckId: null, status: 'available', updatedAt: now });
  if (assignedTruckId) {
    batch.update(db.collection(COLLECTIONS.TRUCKS).doc(assignedTruckId), { assignedDriverId: null, updatedAt: now });
  }
  await batch.commit();
  return { driverId, status: 'unassigned' };
}

/**
 * Look up a driver record by their Firebase Auth uid.
 */
async function getDriverByUid(uid) {
  const db  = getDb();
  const doc = await db.collection(COLLECTIONS.DRIVERS).doc(uid).get();
  if (doc.exists) return doc.data();

  // Legacy fallback: query by uid field
  const snap = await db.collection(COLLECTIONS.DRIVERS)
    .where('uid', '==', uid).limit(1).get();
  return snap.empty ? null : snap.docs[0].data();
}

/**
 * Delete driver — also removes Firebase Auth account and users doc.
 */
async function deleteDriver(driverId, ownerId) {
  const db  = getDb();
  const doc = await db.collection(COLLECTIONS.DRIVERS).doc(driverId).get();
  if (!doc.exists) { const err = new Error('Driver not found'); err.statusCode = 404; throw err; }
  if (doc.data().ownerId !== ownerId) { const err = new Error('Forbidden'); err.statusCode = 403; throw err; }

  const { assignedTruckId, uid } = doc.data();
  const now   = admin.firestore.FieldValue.serverTimestamp();
  const batch = db.batch();

  batch.delete(doc.ref);
  batch.delete(db.collection(COLLECTIONS.USERS).doc(driverId));

  if (assignedTruckId) {
    batch.update(db.collection(COLLECTIONS.TRUCKS).doc(assignedTruckId),
      { assignedDriverId: null, updatedAt: now });
  }
  await batch.commit();

  // Delete Firebase Auth account (best-effort)
  try { await admin.auth().deleteUser(uid || driverId); } catch (_) {}
}

module.exports = { addDriver, getDrivers, getDriverById, getDriverByUid, assignDriver, unassignDriver, deleteDriver };
