const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');
const { getDb, COLLECTIONS } = require('../config/firebase');
const logger = require('../utils/logger');
const wsService = require('./wsService');

/**
 * Validate and sanitise incoming IoT sensor payload
 */
function validateSensorPayload(data) {
  const errors = [];

  if (!data.truckId || typeof data.truckId !== 'string') errors.push('truckId is required');
  if (data.location) {
    if (typeof data.location.lat !== 'number' || typeof data.location.lng !== 'number') {
      errors.push('location.lat and location.lng must be numbers');
    }
    if (data.location.lat < -90  || data.location.lat > 90)  errors.push('Invalid latitude');
    if (data.location.lng < -180 || data.location.lng > 180) errors.push('Invalid longitude');
  }
  if (data.temperature !== undefined && typeof data.temperature !== 'number') errors.push('temperature must be a number');
  if (data.fuelLevel   !== undefined && (data.fuelLevel < 0 || data.fuelLevel > 100)) errors.push('fuelLevel must be 0–100');
  if (data.loadStatus  !== undefined && !['loaded', 'empty', 'partial'].includes(data.loadStatus)) errors.push('Invalid loadStatus');
  if (data.doorStatus  !== undefined && !['open', 'closed', 'locked'].includes(data.doorStatus)) errors.push('Invalid doorStatus');

  return errors;
}

/**
 * Ingest sensor data from IoT device
 */
async function ingestSensorData(payload) {
  const errors = validateSensorPayload(payload);
  if (errors.length) {
    const err = new Error('Invalid sensor payload'); err.statusCode = 422; err.errors = errors; throw err;
  }

  const db = getDb();

  // Verify truck exists
  const truckSnap = await db.collection(COLLECTIONS.TRUCKS)
    .where('plate', '==', payload.truckId.toUpperCase()).limit(1).get();

  if (truckSnap.empty) {
    const err = new Error(`Truck ${payload.truckId} not registered`); err.statusCode = 404; throw err;
  }

  const truckDoc = truckSnap.docs[0];
  const truckId  = truckDoc.id;

  const timestamp = payload.timestamp
    ? admin.firestore.Timestamp.fromDate(new Date(payload.timestamp))
    : admin.firestore.FieldValue.serverTimestamp();

  const sensorRecord = {
    sensorId:    uuidv4(),
    truckId,
    plate:       payload.truckId.toUpperCase(),
    location:    payload.location    || null,
    temperature: payload.temperature ?? null,
    fuelLevel:   payload.fuelLevel   ?? null,
    loadStatus:  payload.loadStatus  || null,
    doorStatus:  payload.doorStatus  || null,
    speed:       payload.speed       ?? null,
    engineOn:    payload.engineOn    ?? null,
    timestamp,
    receivedAt:  admin.firestore.FieldValue.serverTimestamp(),
  };

  const batch = db.batch();

  // Write sensor record
  const sensorRef = db.collection(COLLECTIONS.SENSOR_DATA).doc(sensorRecord.sensorId);
  batch.set(sensorRef, sensorRecord);

  // Update truck's last known state
  const truckUpdate = {
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    lastSeen:  admin.firestore.FieldValue.serverTimestamp(),
  };
  if (payload.location)    truckUpdate.lastLocation = payload.location;
  if (payload.fuelLevel !== undefined) truckUpdate.lastFuelLevel = payload.fuelLevel;
  if (payload.loadStatus)  truckUpdate.lastLoadStatus = payload.loadStatus;
  if (payload.doorStatus)  truckUpdate.lastDoorStatus = payload.doorStatus;

  batch.update(truckDoc.ref, truckUpdate);
  await batch.commit();

  // Broadcast to WebSocket clients
  wsService.broadcast({
    event:   'sensor_update',
    truckId,
    plate:   payload.truckId.toUpperCase(),
    data:    sensorRecord,
  });

  logger.debug(`Sensor data ingested for truck ${payload.truckId}`);
  return { sensorId: sensorRecord.sensorId, truckId };
}

/**
 * Get latest sensor reading for a truck
 */
async function getLatestSensorData(truckId) {
  const db   = getDb();
  const snap = await db.collection(COLLECTIONS.SENSOR_DATA)
    .where('truckId', '==', truckId)
    .orderBy('receivedAt', 'desc')
    .limit(1)
    .get();
  return snap.empty ? null : snap.docs[0].data();
}

/**
 * Get sensor history for a truck (paginated)
 */
async function getSensorHistory(truckId, { limit = 50, startAfter } = {}) {
  const db = getDb();
  let query = db.collection(COLLECTIONS.SENSOR_DATA)
    .where('truckId', '==', truckId)
    .orderBy('receivedAt', 'desc')
    .limit(Math.min(limit, 200));

  if (startAfter) {
    const cursor = await db.collection(COLLECTIONS.SENSOR_DATA).doc(startAfter).get();
    if (cursor.exists) query = query.startAfter(cursor);
  }

  const snap = await query.get();
  return snap.docs.map(d => d.data());
}

module.exports = { ingestSensorData, getLatestSensorData, getSensorHistory, validateSensorPayload };
