const iotService = require('../services/iotService');
const { success, created, error } = require('../utils/response');

async function ingestData(req, res, next) {
  try {
    const result = await iotService.ingestSensorData(req.body);
    return created(res, result, 'Sensor data received');
  } catch (err) {
    if (err.errors) {
      return res.status(err.statusCode || 422).json({ success: false, message: err.message, errors: err.errors });
    }
    next(err);
  }
}

async function getLatest(req, res, next) {
  try {
    const data = await iotService.getLatestSensorData(req.params.truckId);
    return success(res, data || {});
  } catch (err) { next(err); }
}

async function getHistory(req, res, next) {
  try {
    const { limit, startAfter } = req.query;
    const history = await iotService.getSensorHistory(req.params.truckId, {
      limit:      parseInt(limit) || 50,
      startAfter: startAfter || null,
    });
    return success(res, { history, count: history.length });
  } catch (err) { next(err); }
}

module.exports = { ingestData, getLatest, getHistory };
