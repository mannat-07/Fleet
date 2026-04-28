/**
 * Full seed script — creates 25 trucks and 25 drivers for owner1@gmail.com
 * Run: node scripts/seed-full-data.js
 */

require('dotenv').config();
const path = require('path');
const fs = require('fs');
const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');

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
db.settings({ ignoreUndefinedProperties: true });

// ── Helpers ───────────────────────────────────────────────────────────────────
function rand(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function randFloat(min, max) {
  return Math.random() * (max - min) + min;
}

// ── Main ──────────────────────────────────────────────────────────────────────
async function main() {
  const OWNER_EMAIL = 'owner1@gmail.com';
  
  // 1. Find or create owner
  console.log(`🔍  Looking for owner: ${OWNER_EMAIL}`);
  
  let ownerId = null;
  const userSnap = await db.collection('users')
    .where('email', '==', OWNER_EMAIL)
    .limit(1)
    .get();
  
  if (!userSnap.empty) {
    ownerId = userSnap.docs[0].data().uid;
    console.log(`✅  Found owner: ${ownerId}`);
  } else {
    // Create owner in Firebase Auth
    console.log(`📝  Creating owner account...`);
    try {
      const userRecord = await admin.auth().createUser({
        email: OWNER_EMAIL,
        password: 'password123',
        displayName: 'Fleet Owner 1',
      });
      ownerId = userRecord.uid;
      
      // Create user document
      await db.collection('users').doc(ownerId).set({
        uid: ownerId,
        name: 'Fleet Owner 1',
        email: OWNER_EMAIL,
        role: 'owner',
        phone: '+91 98765 43210',
        company: 'FleetOS Demo',
        avatarInitials: 'FO',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`✅  Created owner: ${ownerId}`);
    } catch (err) {
      if (err.code === 'auth/email-already-exists') {
        // Get the user
        const user = await admin.auth().getUserByEmail(OWNER_EMAIL);
        ownerId = user.uid;
        console.log(`✅  Found existing auth user: ${ownerId}`);
      } else {
        throw err;
      }
    }
  }

  // 2. Create 25 trucks
  console.log(`\n🚛  Creating 25 trucks...`);
  
  const truckTypes = ['heavy', 'medium', 'light', 'tanker', 'flatbed'];
  const truckModels = [
    'Tata LPT 1918', 'Ashok Leyland 2518', 'Mahindra Blazo X 35',
    'Eicher Pro 6025', 'BharatBenz 1617R', 'Volvo FM 440',
    'Tata Prima 4038', 'Ashok Leyland 3718', 'Mahindra Furio 17',
    'Eicher Pro 8049'
  ];
  const states = ['MH', 'DL', 'KA', 'TN', 'GJ', 'RJ', 'UP', 'MP'];
  
  const trucks = [];
  const now = admin.firestore.FieldValue.serverTimestamp();
  const currentYear = new Date().getFullYear();
  
  for (let i = 0; i < 25; i++) {
    const truckId = uuidv4();
    const state = states[i % states.length];
    const plateNum = `${state}${String(10 + i).padStart(2, '0')} AB ${1000 + i}`;
    const year = currentYear - rand(0, 8);
    const truckAge = currentYear - year;
    
    const truck = {
      truckId,
      ownerId,
      plate: plateNum,
      model: truckModels[i % truckModels.length],
      type: truckTypes[i % truckTypes.length],
      year,
      status: ['idle', 'active', 'on_trip'][i % 3],
      assignedDriverId: null,
      lastLocation: null,
      lastSeen: null,
      // ML Performance Metrics
      maintenance_score: randFloat(75, 98),
      fuel_efficiency: randFloat(4.5, 7.5),
      breakdown_count: rand(0, 5),
      age_years: truckAge,
      total_trips: rand(50, 500),
      avg_load_capacity_used: randFloat(60, 95),
      createdAt: now,
      updatedAt: now,
    };
    
    trucks.push(truck);
    await db.collection('trucks').doc(truckId).set(truck);
    console.log(`  ✅  ${plateNum} - ${truck.model}`);
  }
  
  console.log(`✅  Created ${trucks.length} trucks`);

  // 3. Create 25 drivers
  console.log(`\n👥  Creating 25 drivers...`);
  
  const firstNames = [
    'Rajesh', 'Amit', 'Suresh', 'Vijay', 'Ramesh',
    'Prakash', 'Anil', 'Manoj', 'Sanjay', 'Deepak',
    'Ravi', 'Ashok', 'Dinesh', 'Mukesh', 'Santosh',
    'Rakesh', 'Mahesh', 'Naresh', 'Ganesh', 'Yogesh',
    'Pankaj', 'Ajay', 'Vinod', 'Sachin', 'Rahul'
  ];
  
  const lastNames = [
    'Kumar', 'Singh', 'Sharma', 'Patel', 'Verma',
    'Yadav', 'Reddy', 'Nair', 'Iyer', 'Joshi'
  ];
  
  const drivers = [];
  
  for (let i = 0; i < 25; i++) {
    const firstName = firstNames[i];
    const lastName = lastNames[i % lastNames.length];
    const fullName = `${firstName} ${lastName}`;
    const email = `driver${i + 1}@fleetdemo.com`;
    const phone = `+91 ${90000 + i}${String(10000 + i).padStart(5, '0')}`;
    
    let driverId;
    try {
      // Create Firebase Auth account
      const userRecord = await admin.auth().createUser({
        email,
        password: 'driver123',
        displayName: fullName,
      });
      driverId = userRecord.uid;
    } catch (err) {
      if (err.code === 'auth/email-already-exists') {
        const user = await admin.auth().getUserByEmail(email);
        driverId = user.uid;
      } else {
        console.error(`  ❌  Failed to create driver ${email}:`, err.message);
        continue;
      }
    }
    
    // Create user document
    await db.collection('users').doc(driverId).set({
      uid: driverId,
      name: fullName,
      email,
      phone,
      role: 'driver',
      avatarInitials: `${firstName[0]}${lastName[0]}`,
      createdAt: now,
      updatedAt: now,
    });
    
    // Create driver document
    const driver = {
      driverId,
      ownerId,
      uid: driverId,
      name: fullName,
      email,
      phone,
      licenseNumber: `DL-${states[i % states.length]}${String(100000 + i).padStart(6, '0')}`,
      licenseExpiry: `${rand(2025, 2030)}-${String(rand(1, 12)).padStart(2, '0')}-${String(rand(1, 28)).padStart(2, '0')}`,
      assignedTruckId: null,
      status: 'available',
      // ML Performance Metrics
      safety_score: randFloat(70, 98),
      on_time_delivery_rate: randFloat(75, 98),
      fuel_efficiency: randFloat(4.5, 7.5),
      alert_count: rand(0, 8),
      experience_years: rand(1, 15),
      trips_completed: rand(20, 400),
      createdAt: now,
      updatedAt: now,
    };
    
    drivers.push(driver);
    await db.collection('drivers').doc(driverId).set(driver);
    console.log(`  ✅  ${fullName} (${email})`);
  }
  
  console.log(`✅  Created ${drivers.length} drivers`);

  // 4. Assign some drivers to trucks
  console.log(`\n🔗  Assigning drivers to trucks...`);
  
  const assignCount = Math.min(10, drivers.length, trucks.length);
  for (let i = 0; i < assignCount; i++) {
    const driver = drivers[i];
    const truck = trucks[i];
    
    await db.collection('drivers').doc(driver.driverId).update({
      assignedTruckId: truck.truckId,
      status: 'on_trip',
      updatedAt: now,
    });
    
    await db.collection('trucks').doc(truck.truckId).update({
      assignedDriverId: driver.driverId,
      status: 'on_trip',
      updatedAt: now,
    });
    
    console.log(`  ✅  ${driver.name} → ${truck.plate}`);
  }
  
  console.log(`✅  Assigned ${assignCount} drivers to trucks`);

  console.log(`\n🎉  Seed complete!`);
  console.log(`\n📧  Login credentials:`);
  console.log(`   Email: ${OWNER_EMAIL}`);
  console.log(`   Password: password123`);
  console.log(`\n   You now have:`);
  console.log(`   - 25 trucks`);
  console.log(`   - 25 drivers`);
  console.log(`   - ${assignCount} active assignments`);
  
  process.exit(0);
}

main().catch(err => {
  console.error('❌  Seed failed:', err.message);
  console.error(err.stack);
  process.exit(1);
});
