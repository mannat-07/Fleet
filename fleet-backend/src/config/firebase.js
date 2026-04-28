const admin  = require('firebase-admin');
const path   = require('path');
const fs     = require('fs');
const logger = require('../utils/logger');

let db           = null;
let _initialized = false;
let _initError   = null;

// ─── Credential detection helpers ────────────────────────────────────────────

function _isPlaceholder(val) {
  if (!val) return true;
  const v = val.trim();
  return (
    v === '' ||
    v.includes('YOUR_PRIVATE_KEY_HERE') ||
    v.includes('your-service-account') ||
    v === '""' ||
    v === "''"
  );
}

function _hasRealInlineCredentials() {
  const key   = process.env.FIREBASE_PRIVATE_KEY  || '';
  const email = process.env.FIREBASE_CLIENT_EMAIL || '';
  const pid   = process.env.FIREBASE_PROJECT_ID   || '';
  return (
    !_isPlaceholder(pid) &&
    !_isPlaceholder(email) &&
    !_isPlaceholder(key) &&
    key.length > 100
  );
}

// ─── Main init ────────────────────────────────────────────────────────────────

function initFirebase() {
  // Already initialised (e.g. hot-reload)
  if (admin.apps.length) {
    db           = admin.firestore();
    _initialized = true;
    return;
  }

  // ── Strategy 1: explicit JSON file path in env ────────────────────────────
  const envPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (envPath) {
    const resolved = path.resolve(envPath);
    return _initFromFile(resolved, 'FIREBASE_SERVICE_ACCOUNT_PATH');
  }

  // ── Strategy 2: serviceAccountKey.json sitting next to this project ───────
  const defaultPaths = [
    path.resolve(__dirname, '../../serviceAccountKey.json'),   // fleet-backend/
    path.resolve(__dirname, '../../../serviceAccountKey.json'), // one level up
  ];
  for (const p of defaultPaths) {
    if (fs.existsSync(p)) {
      return _initFromFile(p, 'auto-detected serviceAccountKey.json');
    }
  }

  // ── Strategy 3: inline env vars ───────────────────────────────────────────
  if (_hasRealInlineCredentials()) {
    try {
      const privateKey = process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n');
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId:   process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey,
        }),
      });
      _finalize('env vars (FIREBASE_PROJECT_ID / CLIENT_EMAIL / PRIVATE_KEY)');
    } catch (err) {
      _fail(`Inline credential error: ${err.message}`);
    }
    return;
  }

  // ── Strategy 4: Google Application Default Credentials ────────────────────
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    try {
      admin.initializeApp({ credential: admin.credential.applicationDefault() });
      _finalize('GOOGLE_APPLICATION_CREDENTIALS');
    } catch (err) {
      _fail(`ADC error: ${err.message}`);
    }
    return;
  }

  // ── No credentials ────────────────────────────────────────────────────────
  _fail(
    'No Firebase credentials found.\n' +
    '  Fix: download your service account key from\n' +
    '  https://console.firebase.google.com/project/hackindia-2dd25/settings/serviceaccounts/adminsdk\n' +
    '  and save it as  fleet-backend/serviceAccountKey.json\n' +
    '  (or set FIREBASE_SERVICE_ACCOUNT_PATH in .env)'
  );
}

function _initFromFile(filePath, source) {
  try {
    const json = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    admin.initializeApp({ credential: admin.credential.cert(json) });
    _finalize(source);
  } catch (err) {
    _fail(`Failed to load service account from "${filePath}": ${err.message}`);
  }
}

function _finalize(source) {
  db = admin.firestore();
  db.settings({ ignoreUndefinedProperties: true });
  _initialized = true;
  logger.info(`✅ Firebase connected via ${source}`);
}

function _fail(msg) {
  _initError = msg;
  logger.warn('⚠️  Firebase NOT connected:');
  msg.split('\n').forEach(line => logger.warn(`   ${line}`));
  logger.warn('   → Server starts, but all /api/* routes will return 503 until credentials are added.');
}

// ─── Public API ───────────────────────────────────────────────────────────────

function getDb() {
  if (_initialized && db) return db;
  const err = new Error(
    _initError
      ? `Firebase unavailable — ${_initError.split('\n')[0]}`
      : 'Firebase not initialised.'
  );
  err.statusCode = 503;
  throw err;
}

function getFirebaseStatus() {
  return { initialized: _initialized, error: _initError || null };
}

const COLLECTIONS = {
  USERS:       'users',
  TRUCKS:      'trucks',
  DRIVERS:     'drivers',
  SENSOR_DATA: 'sensorData',
  EARNINGS:    'earnings',
  INSURANCE:   'insurance',
};

module.exports = { initFirebase, getDb, getFirebaseStatus, COLLECTIONS };
