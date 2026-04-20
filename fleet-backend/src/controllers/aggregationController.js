const aggService = require('../services/aggregationService');
const { success, created } = require('../utils/response');

async function getFleetSummary(req, res, next) {
  try {
    const summary = await aggService.getFleetSummary(req.user.uid);
    return success(res, summary);
  } catch (err) { next(err); }
}

async function getActiveTrucks(req, res, next) {
  try {
    const trucks = await aggService.getActiveTrucks(req.user.uid);
    return success(res, { trucks, count: trucks.length });
  } catch (err) { next(err); }
}

async function getEarnings(req, res, next) {
  try {
    const { period = 'monthly' } = req.query;
    const earnings = await aggService.getEarningsSummary(req.user.uid, period);
    return success(res, earnings);
  } catch (err) { next(err); }
}

async function recordEarning(req, res, next) {
  try {
    const entry = await aggService.recordEarning({ ownerId: req.user.uid, ...req.body });
    return created(res, entry, 'Earning recorded');
  } catch (err) { next(err); }
}

module.exports = { getFleetSummary, getActiveTrucks, getEarnings, recordEarning };
