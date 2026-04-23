const jwt   = require('jsonwebtoken');
const admin = require('firebase-admin');
const { getDb, COLLECTIONS } = require('../config/firebase');
const { unauthorized, forbidden } = require('../utils/response');

/**
 * Verify token — supports both:
 *   1. Firebase ID tokens (issued by Firebase Auth, used by Flutter clients)
 *   2. Custom JWTs (issued by this backend's /api/auth/login)
 */
async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return unauthorized(res, 'No token provided');
    }

    const token = authHeader.split(' ')[1];
    let uid, email, role;

    // ── Try Firebase ID token first ──────────────────────────────────────────
    try {
      const decoded = await admin.auth().verifyIdToken(token);
      uid   = decoded.uid;
      email = decoded.email || '';

      // Load role from Firestore users collection
      const db      = getDb();
      const userDoc = await db.collection(COLLECTIONS.USERS).doc(uid).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        if (userData.disabled) return forbidden(res, 'Account disabled');
        role = userData.role || 'owner';
      } else {
        // User exists in Firebase Auth but not yet in Firestore — treat as owner
        role = 'owner';
      }

      req.user = { uid, email, role };
      return next();
    } catch (firebaseErr) {
      // Not a Firebase token — fall through to custom JWT
    }

    // ── Try custom JWT ───────────────────────────────────────────────────────
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      uid = decoded.uid;

      const db      = getDb();
      const userDoc = await db.collection(COLLECTIONS.USERS).doc(uid).get();
      if (!userDoc.exists) return unauthorized(res, 'User not found');

      const user = userDoc.data();
      if (user.disabled) return forbidden(res, 'Account disabled');

      req.user = { uid, email: user.email, role: user.role || 'owner' };
      return next();
    } catch (jwtErr) {
      if (jwtErr.name === 'TokenExpiredError') return unauthorized(res, 'Token expired');
      return unauthorized(res, 'Invalid token');
    }
  } catch (err) {
    next(err);
  }
}

/**
 * Verify IoT device using shared secret in header
 */
function authenticateDevice(req, res, next) {
  const deviceSecret = req.headers['x-device-secret'];
  if (!deviceSecret || deviceSecret !== process.env.IOT_DEVICE_SECRET) {
    return unauthorized(res, 'Invalid device credentials');
  }
  next();
}

/**
 * Role-based access guard
 */
function requireRole(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.user?.role)) {
      return forbidden(res, 'Insufficient permissions');
    }
    next();
  };
}

module.exports = { authenticate, authenticateDevice, requireRole };
