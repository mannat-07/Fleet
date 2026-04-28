/**
 * Check if owner1@gmail.com has trucks and drivers in Firestore
 */

require('dotenv').config();
const path = require('path');
const fs = require('fs');
const admin = require('firebase-admin');

// ── Init Firebase ─────────────────────────────────────────────────────────────
const keyPath = path.resolve(__dirname, '../serviceAccountKey.json');
if (!fs.existsSync(keyPath)) {
  console.error('❌  serviceAccountKey.json not found at', keyPath);
  process.exit(1);
}
admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(fs.readFileSync(keyPath, 'utf8')))
});
const db = admin.firestore();

async function check() {
  const OWNER_EMAIL = 'owner1@gmail.com';
  
  // Find owner in users collection
  const userSnap = await db.collection('users')
    .where('email', '==', OWNER_EMAIL)
    .limit(1)
    .get();
  
  if (userSnap.empty) {
    console.log('❌ No user found with email', OWNER_EMAIL, 'in Firestore');
    console.log('\n💡 Run: node fleet-backend/scripts/seed-full-data.js');
    process.exit(0);
  }
  
  const userData = userSnap.docs[0].data();
  console.log('✅ Found user in Firestore:');
  console.log('   uid:', userData.uid);
  console.log('   email:', userData.email);
  console.log('   role:', userData.role);
  
  // Check trucks for this ownerId
  const trucksSnap = await db.collection('trucks')
    .where('ownerId', '==', userData.uid)
    .get();
  console.log('\n🚛 Trucks for this owner:', trucksSnap.size);
  
  if (trucksSnap.size > 0) {
    console.log('   Sample trucks:');
    trucksSnap.docs.slice(0, 3).forEach(doc => {
      const t = doc.data();
      console.log('   -', t.plate, '|', t.model, '|', t.status);
    });
  }
  
  // Check drivers for this ownerId
  const driversSnap = await db.collection('drivers')
    .where('ownerId', '==', userData.uid)
    .get();
  console.log('\n👥 Drivers for this owner:', driversSnap.size);
  
  if (driversSnap.size > 0) {
    console.log('   Sample drivers:');
    driversSnap.docs.slice(0, 3).forEach(doc => {
      const d = doc.data();
      console.log('   -', d.name, '|', d.email, '|', d.status);
    });
  }
  
  if (trucksSnap.size === 0 && driversSnap.size === 0) {
    console.log('\n❌ No trucks or drivers found for this owner!');
    console.log('💡 Run: node fleet-backend/scripts/seed-full-data.js');
  } else {
    console.log('\n✅ Data looks good!');
  }
  
  process.exit(0);
}

check().catch(err => {
  console.error('❌ Error:', err.message);
  console.error(err.stack);
  process.exit(1);
});
