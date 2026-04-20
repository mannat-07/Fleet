const jwt = require('jsonwebtoken');
const { getDb, COLLECTIONS } = require('../config/firebase');
const { unauthorized, forbidden } = require('../utils/response');

/**
 * Verify JWT and attach user to req.user
 */
async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return unauthorized(res, 'No token provided');
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Fetch fresh user from Firestore to ensure account still active
    const db = getDb();
    const userDoc = await db.collection(COLLECTIONS.USERS).doc(decoded.uid).get();

    if (!userDoc.exists) return unauthorized(res, 'User not found');

    const user = userDoc.data();
    if (user.disabled) return forbidden(res, 'Account disabled');

    req.user = { uid: decoded.uid, email: user.email, role: user.role || 'owner' };
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') return unauthorized(res, 'Token expired');
    if (err.name === 'JsonWebTokenError')  return unauthorized(res, 'Invalid token');
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
 * Role-based access (optional)
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
