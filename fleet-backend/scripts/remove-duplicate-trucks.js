/**
 * Remove duplicate trucks - keeps only the latest version of each plate number
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

async function removeDuplicates() {
  const OWNER_EMAIL = 'owner1@gmail.com';
  
  // Find owner
  const userSnap = await db.collection('users')
    .where('email', '==', OWNER_EMAIL)
    .limit(1)
    .get();
  
  if (userSnap.empty) {
    console.log('❌ Owner not found');
    process.exit(1);
  }
  
  const ownerId = userSnap.docs[0].data().uid;
  console.log('✅ Found owner:', ownerId);
  
  // Get all trucks for this owner
  const trucksSnap = await db.collection('trucks')
    .where('ownerId', '==', ownerId)
    .get();
  
  console.log(`\n📊 Total trucks: ${trucksSnap.size}`);
  
  // Group trucks by plate number
  const trucksByPlate = new Map();
  
  trucksSnap.docs.forEach(doc => {
    const truck = doc.data();
    const plate = truck.plate;
    
    if (!trucksByPlate.has(plate)) {
      trucksByPlate.set(plate, []);
    }
    
    trucksByPlate.get(plate).push({
      id: doc.id,
      data: truck,
      createdAt: truck.createdAt?.toMillis?.() ?? 0,
    });
  });
  
  console.log(`📋 Unique plates: ${trucksByPlate.size}`);
  
  // Find duplicates and delete older versions
  let duplicatesFound = 0;
  let trucksDeleted = 0;
  const batch = db.batch();
  
  for (const [plate, trucks] of trucksByPlate.entries()) {
    if (trucks.length > 1) {
      duplicatesFound++;
      console.log(`\n🔍 Found ${trucks.length} trucks with plate: ${plate}`);
      
      // Sort by createdAt (newest first)
      trucks.sort((a, b) => b.createdAt - a.createdAt);
      
      // Keep the first (newest), delete the rest
      const toKeep = trucks[0];
      const toDelete = trucks.slice(1);
      
      console.log(`   ✅ Keeping: ${toKeep.id} (created: ${new Date(toKeep.createdAt).toISOString()})`);
      
      for (const truck of toDelete) {
        console.log(`   ❌ Deleting: ${truck.id} (created: ${new Date(truck.createdAt).toISOString()})`);
        batch.delete(db.collection('trucks').doc(truck.id));
        trucksDeleted++;
      }
    }
  }
  
  if (trucksDeleted > 0) {
    console.log(`\n🗑️  Deleting ${trucksDeleted} duplicate trucks...`);
    await batch.commit();
    console.log('✅ Duplicates removed!');
  } else {
    console.log('\n✅ No duplicates found!');
  }
  
  console.log(`\n📊 Summary:`);
  console.log(`   - Duplicate plates found: ${duplicatesFound}`);
  console.log(`   - Trucks deleted: ${trucksDeleted}`);
  console.log(`   - Trucks remaining: ${trucksByPlate.size}`);
  
  process.exit(0);
}

removeDuplicates().catch(err => {
  console.error('❌ Error:', err.message);
  console.error(err.stack);
  process.exit(1);
});
