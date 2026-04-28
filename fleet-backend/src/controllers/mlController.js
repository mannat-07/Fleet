const mlService = require('../services/mlService');
const { success } = require('../utils/response');

async function predictDriver(req, res, next) {
  try {
    const prediction = await mlService.predictDriverScore(req.body.driverId, req.user.uid);
    return success(res, prediction, 'Driver prediction generated');
  } catch (err) { next(err); }
}

async function predictTruck(req, res, next) {
  try {
    const prediction = await mlService.predictTruckScore(req.body.truckId, req.user.uid);
    return success(res, prediction, 'Truck prediction generated');
  } catch (err) { next(err); }
}

async function getDriverRecommendations(req, res, next) {
  try {
    const recommendations = await mlService.getDriverRecommendations(req.user.uid);
    return success(res, recommendations, 'Driver recommendations generated');
  } catch (err) { next(err); }
}

async function getTruckRecommendations(req, res, next) {
  try {
    const recommendations = await mlService.getTruckRecommendations(req.user.uid);
    return success(res, recommendations, 'Truck recommendations generated');
  } catch (err) { next(err); }
}

async function trainDriverModel(req, res, next) {
  try {
    const result = await mlService.trainDriverModel();
    return success(res, result, 'Driver model training initiated');
  } catch (err) { next(err); }
}

async function trainTruckModel(req, res, next) {
  try {
    const result = await mlService.trainTruckModel();
    return success(res, result, 'Truck model training initiated');
  } catch (err) { next(err); }
}

module.exports = {
  predictDriver,
  predictTruck,
  getDriverRecommendations,
  getTruckRecommendations,
  trainDriverModel,
  trainTruckModel,
};
