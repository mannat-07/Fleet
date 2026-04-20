const driverService = require('../services/driverService');
const { success, created } = require('../utils/response');

async function addDriver(req, res, next) {
  try {
    const driver = await driverService.addDriver({ ownerId: req.user.uid, ...req.body });
    return created(res, driver, 'Driver added successfully');
  } catch (err) { next(err); }
}

async function getDrivers(req, res, next) {
  try {
    const drivers = await driverService.getDrivers(req.user.uid);
    return success(res, { drivers, count: drivers.length });
  } catch (err) { next(err); }
}

async function getDriver(req, res, next) {
  try {
    const driver = await driverService.getDriverById(req.params.driverId, req.user.uid);
    return success(res, driver);
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

module.exports = { addDriver, getDrivers, getDriver, assignDriver, unassignDriver };
