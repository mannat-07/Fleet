const driverService = require('../services/driverService');
const truckService  = require('../services/truckService');
const iotService    = require('../services/iotService');
const { success, created } = require('../utils/response');

async function addDriver(req, res, next) {
  try {
    const driver = await driverService.addDriver({ ownerId: req.user.uid, ...req.body });
    return created(res, driver, 'Driver added successfully');
  } catch (err) { next(err); }
}

async function deleteDriver(req, res, next) {
  try {
    await driverService.deleteDriver(req.params.driverId, req.user.uid);
    return success(res, null, 'Driver removed');
  } catch (err) { next(err); }
}

async function getDrivers(req, res, next) {
  try {
    const filters = req.query.status ? { status: req.query.status } : {};
    const includeMl = req.query.ml === 'true';
    const drivers = await driverService.getDrivers(req.user.uid, filters, includeMl);
    return success(res, { drivers, count: drivers.length });
  } catch (err) { next(err); }
}

async function getDriver(req, res, next) {
  try {
    const driver = await driverService.getDriverById(req.params.driverId, req.user.uid);
    return success(res, driver);
  } catch (err) { next(err); }
}

// GET /api/drivers/me — driver fetches their own profile + assigned truck + latest sensor
async function getMyProfile(req, res, next) {
  try {
    const driver = await driverService.getDriverByUid(req.user.uid);
    if (!driver) {
      const err = new Error('Driver profile not found for this account');
      err.statusCode = 404; throw err;
    }

    let truck  = null;
    let sensor = null;

    if (driver.assignedTruckId) {
      try {
        const db = require('../config/firebase').getDb();
        const { COLLECTIONS } = require('../config/firebase');
        const truckDoc = await db.collection(COLLECTIONS.TRUCKS).doc(driver.assignedTruckId).get();
        if (truckDoc.exists) {
          truck = truckDoc.data();
          sensor = await iotService.getLatestSensorData(driver.assignedTruckId);
        }
      } catch (_) {}
    }

    return success(res, { driver, truck, sensor });
  } catch (err) { next(err); }
}

async function assignDriver(req, res, next) {
  try {
    const result = await driverService.assignDriver(req.params.driverId, req.body.truckId, req.user.uid);
    return success(res, result, 'Driver assigned to truck');
  } catch (err) { next(err); }
}

async function unassignDriver(req, res, next) {
  try {
    const result = await driverService.unassignDriver(req.params.driverId, req.user.uid);
    return success(res, result, 'Driver unassigned');
  } catch (err) { next(err); }
}

async function updateDriverMetrics(req, res, next) {
  try {
    const result = await driverService.updateDriverMetrics(req.params.driverId, req.user.uid, req.body);
    return success(res, result, 'Driver metrics updated');
  } catch (err) { next(err); }
}

module.exports = { addDriver, getDrivers, getDriver, getMyProfile, assignDriver, unassignDriver, deleteDriver, updateDriverMetrics };
