const http = require('http');
const https = require('https');
const { getDb, COLLECTIONS } = require('../config/firebase');
const logger = require('../utils/logger');

const ML_API_URL = process.env.ML_API_URL || 'http://localhost:5001';

/**
 * Make HTTP request to Python ML API
 */
function makeMLRequest(path, method = 'GET', body = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, ML_API_URL);
    const protocol = url.protocol === 'https:' ? https : http;
    
    const options = {
      hostname: url.hostname,
      port: url.port || (url.protocol === 'https:' ? 443 : 80),
      path: url.pathname + url.search,
      method,
      headers: {
        'Content-Type': 'application/json',
      },
    };

    const req = protocol.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(parsed);
          } else {
            reject(new Error(parsed.error || `ML API error: ${res.statusCode}`));
          }
        } catch (err) {
          reject(new Error(`Failed to parse ML API response: ${err.message}`));
        }
      });
    });

    req.on('error', (err) => {
      reject(new Error(`ML API connection failed: ${err.message}`));
    });

    if (body) {
      req.write(JSON.stringify(body));
    }

    req.end();
  });
}

/**
 * Predict driver score using ML model
 */
async function predictDriverScore(driverId, ownerId) {
  const db = getDb();
  const doc = await db.collection(COLLECTIONS.DRIVERS).doc(driverId).get();
  
  if (!doc.exists) {
    const err = new Error('Driver not found');
    err.statusCode = 404;
    throw err;
  }

  const driver = doc.data();
  if (driver.ownerId !== ownerId) {
    const err = new Error('Forbidden');
    err.statusCode = 403;
    throw err;
  }

  const features = {
    safety_score: driver.safety_score || 85,
    fuel_efficiency: driver.fuel_efficiency || 5.5,
    on_time_delivery_rate: driver.on_time_delivery_rate || 80,
    alert_count: driver.alert_count || 0,
    experience_years: driver.experience_years || 0,
    trips_completed: driver.trips_completed || 0,
  };

  try {
    const prediction = await makeMLRequest('/predict/driver', 'POST', features);
    return {
      driverId,
      driverName: driver.name,
      predictedScore: prediction.predicted_score,
      features,
    };
  } catch (err) {
    logger.error('ML prediction failed:', err.message);
    const mlErr = new Error('ML service unavailable. Ensure Python ML API is running on port 5001.');
    mlErr.statusCode = 503;
    throw mlErr;
  }
}

/**
 * Predict truck score using ML model
 */
async function predictTruckScore(truckId, ownerId) {
  const db = getDb();
  const doc = await db.collection(COLLECTIONS.TRUCKS).doc(truckId).get();
  
  if (!doc.exists) {
    const err = new Error('Truck not found');
    err.statusCode = 404;
    throw err;
  }

  const truck = doc.data();
  if (truck.ownerId !== ownerId) {
    const err = new Error('Forbidden');
    err.statusCode = 403;
    throw err;
  }

  const features = {
    maintenance_score: truck.maintenance_score || 90,
    fuel_efficiency: truck.fuel_efficiency || 5.5,
    breakdown_count: truck.breakdown_count || 0,
    age_years: truck.age_years || 0,
    total_trips: truck.total_trips || 0,
    avg_load_capacity_used: truck.avg_load_capacity_used || 75,
  };

  try {
    const prediction = await makeMLRequest('/predict/truck', 'POST', features);
    return {
      truckId,
      truckPlate: truck.plate,
      predictedScore: prediction.predicted_score,
      features,
    };
  } catch (err) {
    logger.error('ML prediction failed:', err.message);
    const mlErr = new Error('ML service unavailable. Ensure Python ML API is running on port 5001.');
    mlErr.statusCode = 503;
    throw mlErr;
  }
}

/**
 * Get top recommended drivers for the owner
 */
async function getDriverRecommendations(ownerId) {
  const db = getDb();
  const snap = await db.collection(COLLECTIONS.DRIVERS)
    .where('ownerId', '==', ownerId)
    .get();

  if (snap.empty) {
    return { recommendations: [], count: 0 };
  }

  const predictions = [];
  for (const doc of snap.docs) {
    const driver = doc.data();
    const features = {
      safety_score: driver.safety_score || 85,
      fuel_efficiency: driver.fuel_efficiency || 5.5,
      on_time_delivery_rate: driver.on_time_delivery_rate || 80,
      alert_count: driver.alert_count || 0,
      experience_years: driver.experience_years || 0,
      trips_completed: driver.trips_completed || 0,
    };

    try {
      const prediction = await makeMLRequest('/predict/driver', 'POST', features);
      predictions.push({
        driverId: driver.driverId,
        name: driver.name,
        email: driver.email,
        predictedScore: prediction.predicted_score,
        status: driver.status,
        assignedTruckId: driver.assignedTruckId,
      });
    } catch (err) {
      logger.warn(`Failed to predict for driver ${driver.driverId}:`, err.message);
    }
  }

  // Sort by predicted score descending
  predictions.sort((a, b) => b.predictedScore - a.predictedScore);

  return {
    recommendations: predictions.slice(0, 10),
    count: predictions.length,
  };
}

/**
 * Get top recommended trucks for the owner
 */
async function getTruckRecommendations(ownerId) {
  const db = getDb();
  const snap = await db.collection(COLLECTIONS.TRUCKS)
    .where('ownerId', '==', ownerId)
    .get();

  if (snap.empty) {
    return { recommendations: [], count: 0 };
  }

  const predictions = [];
  for (const doc of snap.docs) {
    const truck = doc.data();
    const features = {
      maintenance_score: truck.maintenance_score || 90,
      fuel_efficiency: truck.fuel_efficiency || 5.5,
      breakdown_count: truck.breakdown_count || 0,
      age_years: truck.age_years || 0,
      total_trips: truck.total_trips || 0,
      avg_load_capacity_used: truck.avg_load_capacity_used || 75,
    };

    try {
      const prediction = await makeMLRequest('/predict/truck', 'POST', features);
      predictions.push({
        truckId: truck.truckId,
        plate: truck.plate,
        model: truck.model,
        predictedScore: prediction.predicted_score,
        status: truck.status,
        assignedDriverId: truck.assignedDriverId,
      });
    } catch (err) {
      logger.warn(`Failed to predict for truck ${truck.truckId}:`, err.message);
    }
  }

  // Sort by predicted score descending
  predictions.sort((a, b) => b.predictedScore - a.predictedScore);

  return {
    recommendations: predictions.slice(0, 10),
    count: predictions.length,
  };
}

/**
 * Trigger driver model retraining
 */
async function trainDriverModel() {
  try {
    const result = await makeMLRequest('/train/driver', 'POST');
    return result;
  } catch (err) {
    logger.error('Driver model training failed:', err.message);
    const mlErr = new Error('ML training service unavailable.');
    mlErr.statusCode = 503;
    throw mlErr;
  }
}

/**
 * Trigger truck model retraining
 */
async function trainTruckModel() {
  try {
    const result = await makeMLRequest('/train/truck', 'POST');
    return result;
  } catch (err) {
    logger.error('Truck model training failed:', err.message);
    const mlErr = new Error('ML training service unavailable.');
    mlErr.statusCode = 503;
    throw mlErr;
  }
}

/**
 * Batch predict driver scores using ML model (much faster than individual predictions)
 */
async function batchPredictDrivers(drivers) {
  try {
    const response = await makeMLRequest('/predict/drivers/batch', 'POST', { drivers });
    return response.predictions || [];
  } catch (err) {
    logger.error('Batch driver prediction failed:', err.message);
    // Return empty predictions on failure
    return drivers.map(d => ({ id: d.id, predicted_score: null }));
  }
}

/**
 * Batch predict truck scores using ML model (much faster than individual predictions)
 */
async function batchPredictTrucks(trucks) {
  try {
    const response = await makeMLRequest('/predict/trucks/batch', 'POST', { trucks });
    return response.predictions || [];
  } catch (err) {
    logger.error('Batch truck prediction failed:', err.message);
    // Return empty predictions on failure
    return trucks.map(t => ({ id: t.id, predicted_score: null }));
  }
}

module.exports = {
  predictDriverScore,
  predictTruckScore,
  getDriverRecommendations,
  getTruckRecommendations,
  trainDriverModel,
  trainTruckModel,
  batchPredictDrivers,
  batchPredictTrucks,
};
