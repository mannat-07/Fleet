const admin = require('firebase-admin');
const { getDb, COLLECTIONS } = require('../config/firebase');

/**
 * Fleet summary for dashboard
 */
async function getFleetSummary(ownerId) {
  const db = getDb();

  const [trucksSnap, driversSnap] = await Promise.all([
    db.collection(COLLECTIONS.TRUCKS).where('ownerId', '==', ownerId).get(),
    db.collection(COLLECTIONS.DRIVERS).where('ownerId', '==', ownerId).get(),
  ]);

  const trucks  = trucksSnap.docs.map(d => d.data());
  const drivers = driversSnap.docs.map(d => d.data());

  const truckStats = {
    total:       trucks.length,
    active:      trucks.filter(t => t.status === 'active').length,
    onTrip:      trucks.filter(t => t.status === 'on_trip').length,
    idle:        trucks.filter(t => t.status === 'idle').length,
    maintenance: trucks.filter(t => t.status === 'maintenance').length,
  };

  const driverStats = {
    total:     drivers.length,
    onTrip:    drivers.filter(d => d.status === 'on_trip').length,
    available: drivers.filter(d => d.status === 'available').length,
    offDuty:   drivers.filter(d => d.status === 'off_duty').length,
  };

  return { trucks: truckStats, drivers: driverStats };
}

/**
 * Active trucks with latest sensor data
 */
async function getActiveTrucks(ownerId) {
  const db   = getDb();
  // Fetch all owner trucks without compound filter to avoid index requirement.
  // Filter active/on_trip in-memory.
  const snap = await db.collection(COLLECTIONS.TRUCKS)
    .where('ownerId', '==', ownerId)
    .get();

  const trucks = snap.docs
    .map(d => d.data())
    .filter(t => t.status === 'active' || t.status === 'on_trip');

  // Attach latest sensor reading for each
  const enriched = await Promise.all(
    trucks.map(async (truck) => {
      try {
        const sensorSnap = await db.collection(COLLECTIONS.SENSOR_DATA)
          .where('truckId', '==', truck.truckId)
          .orderBy('receivedAt', 'desc')
          .limit(1)
          .get();
        const latest = sensorSnap.empty ? null : sensorSnap.docs[0].data();
        return { ...truck, latestSensor: latest };
      } catch (_) {
        return { ...truck, latestSensor: null };
      }
    })
  );

  return enriched;
}

/**
 * Earnings summary — daily / weekly / monthly
 */
async function getEarningsSummary(ownerId, period = 'monthly') {
  const db  = getDb();
  const now = new Date();

  let startDate;
  switch (period) {
    case 'daily':   startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate()); break;
    case 'weekly':  startDate = new Date(now.getTime() - 7  * 24 * 60 * 60 * 1000); break;
    case 'monthly': startDate = new Date(now.getFullYear(), now.getMonth(), 1); break;
    default:        startDate = new Date(now.getFullYear(), now.getMonth(), 1);
  }

  // Single-field query — no composite index needed.
  // Filter by date range and sort in-memory.
  const snap = await db.collection(COLLECTIONS.EARNINGS)
    .where('ownerId', '==', ownerId)
    .get();

  const startMs = startDate.getTime();

  const records = snap.docs
    .map(d => d.data())
    .filter(r => {
      const ms = r.date?.toMillis?.() ?? r.date?.toDate?.()?.getTime?.() ?? 0;
      return ms >= startMs;
    })
    .sort((a, b) => {
      const ta = a.date?.toMillis?.() ?? 0;
      const tb = b.date?.toMillis?.() ?? 0;
      return ta - tb;
    });

  const total = records.reduce((sum, r) => sum + (r.amount || 0), 0);

  const byDay = {};
  records.forEach(r => {
    const day = r.date?.toDate?.()?.toISOString?.().split('T')[0] ?? 'unknown';
    byDay[day] = (byDay[day] || 0) + (r.amount || 0);
  });

  return {
    period,
    total,
    currency: 'INR',
    records: records.length,
    chartData: Object.entries(byDay).map(([date, amount]) => ({ date, amount })),
  };
}

/**
 * Record an earning entry
 */
async function recordEarning({ ownerId, truckId, amount, description, tripId }) {
  const db  = getDb();
  const { v4: uuidv4 } = require('uuid');
  const earningId = uuidv4();

  const entry = {
    earningId, ownerId, truckId,
    amount:      Number(amount),
    description: description || null,
    tripId:      tripId      || null,
    date:        admin.firestore.FieldValue.serverTimestamp(),
    createdAt:   admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.collection(COLLECTIONS.EARNINGS).doc(earningId).set(entry);
  return entry;
}

module.exports = { getFleetSummary, getActiveTrucks, getEarningsSummary, recordEarning };
