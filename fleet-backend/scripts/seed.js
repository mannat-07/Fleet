/**
 * Seed script — adds dummy earnings + insurance fields to existing trucks.
 * Run: node scripts/seed.js
 *
 * Auto-detects owner by finding trucks and using their ownerId.
 * Falls back to querying users collection for role=owner.
 */

require('dotenv').config();
const path  = require('path');
const fs    = require('fs');
const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');

// ── Init Firebase ─────────────────────────────────────────────────────────────
const keyPath = path.resolve(__dirname, '../serviceAccountKey.json');
if (!fs.existsSync(keyPath)) {
  console.error('❌  serviceAccountKey.json not found at', keyPath);
  process.exit(1);
}
admin.initializeApp({ credential: admin.credential.cert(JSON.parse(fs.readFileSync(keyPath, 'utf8'))) });
const db = admin.firestore();
db.settings({ ignoreUndefinedProperties: true });

// ── Helpers ───────────────────────────────────────────────────────────────────
function daysAgo(n, hourOffset = 0) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  d.setHours(8 + hourOffset, 0, 0, 0);
  return admin.firestore.Timestamp.fromDate(d);
}

function rand(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

// ── Main ──────────────────────────────────────────────────────────────────────
async function main() {
  // 1. Find owner — first try trucks collection to get real ownerId
  const trucksSnap = await db.collection('trucks').limit(20).get();
  const trucks = trucksSnap.docs.map(d => ({ id: d.id, ...d.data() }));

  let ownerId = null;

  if (trucks.length > 0) {
    // Use the ownerId from the first truck
    ownerId = trucks[0].ownerId;
    console.log(`✅  Detected owner from trucks: ${ownerId}`);
  } else {
    // Fallback: look in users collection
    const ownerSnap = await db.collection('users')
      .where('role', 'in', ['owner', 'Fleet Owner']).limit(1).get();
    if (!ownerSnap.empty) {
      ownerId = ownerSnap.docs[0].data().uid;
      console.log(`✅  Owner from users collection: ${ownerId}`);
    }
  }

  if (!ownerId) {
    console.error('❌  No owner found. Sign up as Fleet Owner in the app first, then add at least one truck.');
    process.exit(1);
  }

  // Filter trucks belonging to this owner
  const ownerTrucks = trucks.filter(t => t.ownerId === ownerId);
  console.log(`🚛  Found ${ownerTrucks.length} truck(s) for this owner`);

  if (ownerTrucks.length === 0) {
    console.error('❌  No trucks found for this owner. Add trucks in the app first.');
    process.exit(1);
  }

  // 2. Add insurance fields to each truck
  const insuranceProviders = [
    'HDFC Ergo', 'New India Assurance', 'Bajaj Allianz',
    'ICICI Lombard', 'Oriental Insurance', 'Tata AIG',
  ];
  const insuranceStatuses = ['Valid', 'Valid', 'Valid', 'Expiring', 'Expired'];

  const batch1 = db.batch();
  ownerTrucks.forEach((truck, i) => {
    const status = insuranceStatuses[i % insuranceStatuses.length];
    const expiry = new Date();
    if (status === 'Valid')    expiry.setMonth(expiry.getMonth() + rand(4, 14));
    if (status === 'Expiring') expiry.setDate(expiry.getDate() + rand(5, 20));
    if (status === 'Expired')  expiry.setMonth(expiry.getMonth() - rand(1, 4));

    const options = { year: 'numeric', month: 'short', day: '2-digit' };
    const expiryStr = expiry.toLocaleDateString('en-IN', options);

    batch1.update(db.collection('trucks').doc(truck.id), {
      insuranceStatus:   status,
      insuranceExpiry:   expiryStr,
      insuranceProvider: insuranceProviders[i % insuranceProviders.length],
    });
    console.log(`  🛡️  ${truck.plate} → ${status} (${expiryStr}) — ${insuranceProviders[i % insuranceProviders.length]}`);
  });
  await batch1.commit();
  console.log('✅  Insurance fields written to trucks\n');

  // 3. Seed earnings — 30 days of realistic daily entries
  const descriptions = [
    'Freight delivery — Mumbai to Pune',
    'Long haul — Delhi to Jaipur',
    'Local delivery — City run',
    'Express cargo — Airport pickup',
    'Bulk transport — Warehouse to port',
    'Port delivery — JNPT',
    'Cold chain delivery',
    'Construction material transport',
    'FMCG distribution run',
    'E-commerce last mile',
  ];

  // Delete existing earnings for this owner to avoid duplicates
  const existingEarnings = await db.collection('earnings').where('ownerId', '==', ownerId).get();
  if (!existingEarnings.empty) {
    const delBatch = db.batch();
    existingEarnings.docs.forEach(d => delBatch.delete(d.ref));
    await delBatch.commit();
    console.log(`🗑️   Cleared ${existingEarnings.size} existing earning(s)`);
  }

  // Generate 30 days of earnings
  const earningsBatch = db.batch();
  let totalAmount = 0;
  let count = 0;

  for (let day = 29; day >= 0; day--) {
    // 1–3 trips per day
    const numTrips = rand(1, Math.min(3, ownerTrucks.length + 1));
    for (let t = 0; t < numTrips; t++) {
      const truck     = ownerTrucks[t % ownerTrucks.length];
      const amount    = rand(12000, 52000);
      const earningId = uuidv4();
      const ts        = daysAgo(day, t * 2);

      earningsBatch.set(db.collection('earnings').doc(earningId), {
        earningId,
        ownerId,
        truckId:     truck.truckId || truck.id,
        amount,
        description: descriptions[rand(0, descriptions.length - 1)],
        tripId:      null,
        date:        ts,
        createdAt:   ts,
      });
      totalAmount += amount;
      count++;
    }
  }

  await earningsBatch.commit();
  const totalL = (totalAmount / 100000).toFixed(2);
  console.log(`💰  Seeded ${count} earnings over 30 days — total ₹${totalL}L`);

  // 4. Also update truck statuses to be more interesting
  const statusOptions = ['active', 'on_trip', 'idle', 'active', 'on_trip'];
  const statusBatch = db.batch();
  ownerTrucks.forEach((truck, i) => {
    statusBatch.update(db.collection('trucks').doc(truck.id), {
      status: statusOptions[i % statusOptions.length],
    });
  });
  await statusBatch.commit();
  console.log('🚛  Updated truck statuses (active/on_trip/idle)');

  console.log('\n🎉  Seed complete! Restart the app and pull-to-refresh.');
  process.exit(0);
}

main().catch(err => {
  console.error('❌  Seed failed:', err.message);
  console.error(err.stack);
  process.exit(1);
});
