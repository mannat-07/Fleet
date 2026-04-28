const { v4: uuidv4 } = require('uuid');
const admin = require('firebase-admin');
const { getDb, COLLECTIONS } = require('../config/firebase');

// ─── Pure status computation ──────────────────────────────────────────────────

/**
 * Compute insurance status from dates.
 * @param {string} startDate  ISO 8601 date string e.g. "2025-01-15"
 * @param {string} expiryDate ISO 8601 date string
 * @param {Date}   serverDate Current server date (Date object, time stripped)
 * @returns {{ status: string, daysUntilExpiry: number }}
 */
function computeStatus(startDate, expiryDate, serverDate) {
  const expiry = new Date(expiryDate);
  const server = new Date(serverDate);
  // Strip time component for pure date comparison
  expiry.setUTCHours(0, 0, 0, 0);
  server.setUTCHours(0, 0, 0, 0);

  const daysUntilExpiry = Math.floor((expiry - server) / 86400000);

  let status;
  if (daysUntilExpiry < 0) {
    status = 'Expired';
  } else if (daysUntilExpiry <= 30) {
    status = 'Expiring Soon';
  } else {
    status = 'Valid';
  }

  return { status, daysUntilExpiry };
}

// ─── Helper: attach daysUntilExpiry to a record ───────────────────────────────

function _withComputed(record) {
  const serverDate = new Date();
  const { status, daysUntilExpiry } = computeStatus(
    record.startDate,
    record.expiryDate,
    serverDate
  );
  return { ...record, status, daysUntilExpiry };
}

// ─── CRUD ─────────────────────────────────────────────────────────────────────

async function createInsurance({ ownerId, truckId, policyNumber, provider, startDate, expiryDate }) {
  const db = getDb();

  // Validate date order
  if (new Date(startDate) >= new Date(expiryDate)) {
    const err = new Error('Start date must be before expiry date');
    err.statusCode = 400;
    throw err;
  }

  // Verify truck belongs to owner
  const truckDoc = await db.collection(COLLECTIONS.TRUCKS).doc(truckId).get();
  if (!truckDoc.exists) {
    const err = new Error('Truck not found'); err.statusCode = 404; throw err;
  }
  if (truckDoc.data().ownerId !== ownerId) {
    const err = new Error('Forbidden'); err.statusCode = 403; throw err;
  }

  // Check for duplicate insurance record for this truck
  const existing = await db.collection(COLLECTIONS.INSURANCE)
    .where('truckId', '==', truckId)
    .limit(1)
    .get();
  if (!existing.empty) {
    const err = new Error('An insurance record already exists for this truck');
    err.statusCode = 409;
    throw err;
  }

  const serverDate = new Date();
  const { status, daysUntilExpiry } = computeStatus(startDate, expiryDate, serverDate);

  const insuranceId = uuidv4();
  const now = admin.firestore.FieldValue.serverTimestamp();

  const record = {
    insuranceId,
    truckId,
    ownerId,
    policyNumber,
    provider,
    startDate,
    expiryDate,
    status,
    createdAt: now,
    updatedAt: now,
  };

  await db.collection(COLLECTIONS.INSURANCE).doc(insuranceId).set(record);

  return { ...record, daysUntilExpiry, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() };
}

async function getInsuranceRecords(ownerId) {
  const db = getDb();
  const snap = await db.collection(COLLECTIONS.INSURANCE)
    .where('ownerId', '==', ownerId)
    .get();

  const records = snap.docs.map(d => {
    const data = d.data();
    return _withComputed({
      ...data,
      createdAt: data.createdAt?.toDate?.()?.toISOString?.() ?? data.createdAt,
      updatedAt: data.updatedAt?.toDate?.()?.toISOString?.() ?? data.updatedAt,
    });
  });

  // Sort by createdAt descending
  records.sort((a, b) => {
    const ta = new Date(a.createdAt).getTime();
    const tb = new Date(b.createdAt).getTime();
    return tb - ta;
  });

  return records;
}

async function getInsuranceById(insuranceId, ownerId) {
  const db = getDb();
  const doc = await db.collection(COLLECTIONS.INSURANCE).doc(insuranceId).get();
  if (!doc.exists) {
    const err = new Error('Insurance record not found'); err.statusCode = 404; throw err;
  }
  const data = doc.data();
  if (data.ownerId !== ownerId) {
    const err = new Error('Forbidden'); err.statusCode = 403; throw err;
  }
  return _withComputed({
    ...data,
    createdAt: data.createdAt?.toDate?.()?.toISOString?.() ?? data.createdAt,
    updatedAt: data.updatedAt?.toDate?.()?.toISOString?.() ?? data.updatedAt,
  });
}

async function updateInsurance(insuranceId, ownerId, updates) {
  const db = getDb();
  const doc = await db.collection(COLLECTIONS.INSURANCE).doc(insuranceId).get();
  if (!doc.exists) {
    const err = new Error('Insurance record not found'); err.statusCode = 404; throw err;
  }
  const existing = doc.data();
  if (existing.ownerId !== ownerId) {
    const err = new Error('Forbidden'); err.statusCode = 403; throw err;
  }

  const newStartDate  = updates.startDate  ?? existing.startDate;
  const newExpiryDate = updates.expiryDate ?? existing.expiryDate;

  if (new Date(newStartDate) >= new Date(newExpiryDate)) {
    const err = new Error('Start date must be before expiry date');
    err.statusCode = 400;
    throw err;
  }

  const serverDate = new Date();
  const { status, daysUntilExpiry } = computeStatus(newStartDate, newExpiryDate, serverDate);

  const patch = {
    ...(updates.policyNumber !== undefined && { policyNumber: updates.policyNumber }),
    ...(updates.provider     !== undefined && { provider:     updates.provider }),
    startDate:  newStartDate,
    expiryDate: newExpiryDate,
    status,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await doc.ref.update(patch);

  const updated = { ...existing, ...patch, daysUntilExpiry };
  return {
    ...updated,
    createdAt: existing.createdAt?.toDate?.()?.toISOString?.() ?? existing.createdAt,
    updatedAt: new Date().toISOString(),
  };
}

async function deleteInsurance(insuranceId, ownerId) {
  const db = getDb();
  const doc = await db.collection(COLLECTIONS.INSURANCE).doc(insuranceId).get();
  if (!doc.exists) {
    const err = new Error('Insurance record not found'); err.statusCode = 404; throw err;
  }
  if (doc.data().ownerId !== ownerId) {
    const err = new Error('Forbidden'); err.statusCode = 403; throw err;
  }
  await doc.ref.delete();
}

module.exports = {
  computeStatus,
  createInsurance,
  getInsuranceRecords,
  getInsuranceById,
  updateInsurance,
  deleteInsurance,
};
