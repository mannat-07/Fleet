const bcrypt = require('bcryptjs');
const jwt    = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { getDb, COLLECTIONS } = require('../config/firebase');
const admin = require('firebase-admin');

const SALT_ROUNDS = 12;

function generateToken(uid) {
  return jwt.sign({ uid }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
}

async function register({ name, email, password, phone, role }) {
  const db = getDb();

  // Check duplicate email
  const existing = await db.collection(COLLECTIONS.USERS)
    .where('email', '==', email.toLowerCase()).limit(1).get();
  if (!existing.empty) {
    const err = new Error('Email already registered'); err.statusCode = 409; throw err;
  }

  // Validate role
  const validRoles = ['owner', 'driver', 'organization'];
  const userRole = role && validRoles.includes(role) ? role : 'owner';

  const uid          = uuidv4();
  const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
  const now          = admin.firestore.FieldValue.serverTimestamp();

  const userData = {
    uid, name, email: email.toLowerCase(),
    passwordHash, phone: phone || null,
    role: userRole, disabled: false,
    createdAt: now, updatedAt: now,
  };

  await db.collection(COLLECTIONS.USERS).doc(uid).set(userData);

  const token = generateToken(uid);
  return { uid, name, email: userData.email, role: userData.role, token };
}

async function login({ email, password }) {
  const db = getDb();

  const snap = await db.collection(COLLECTIONS.USERS)
    .where('email', '==', email.toLowerCase()).limit(1).get();

  if (snap.empty) {
    const err = new Error('Invalid credentials'); err.statusCode = 401; throw err;
  }

  const userDoc  = snap.docs[0];
  const userData = userDoc.data();

  if (userData.disabled) {
    const err = new Error('Account disabled'); err.statusCode = 403; throw err;
  }

  const valid = await bcrypt.compare(password, userData.passwordHash);
  if (!valid) {
    const err = new Error('Invalid credentials'); err.statusCode = 401; throw err;
  }

  // Update last login
  await userDoc.ref.update({ lastLoginAt: admin.firestore.FieldValue.serverTimestamp() });

  const token = generateToken(userData.uid);
  return { uid: userData.uid, name: userData.name, email: userData.email, role: userData.role, token };
}

async function getProfile(uid) {
  const db  = getDb();
  const doc = await db.collection(COLLECTIONS.USERS).doc(uid).get();
  if (!doc.exists) { const err = new Error('User not found'); err.statusCode = 404; throw err; }
  const { passwordHash, ...safe } = doc.data();
  return safe;
}

module.exports = { register, login, getProfile };
