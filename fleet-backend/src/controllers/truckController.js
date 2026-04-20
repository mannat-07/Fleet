const truckService = require('../services/truckService');
const { success, created } = require('../utils/response');

async function addTruck(req, res, next) {
  try {
    const truck = await truckService.addTruck({ ownerId: req.user.uid, ...req.body });
    return created(res, truck, 'Truck added successfully');
  } catch (err) { next(err); }
}

async function getTrucks(req, res, next) {
  try {
    const trucks = await truckService.getTrucks(req.user.uid);
    return success(res, { trucks, count: trucks.length });
  } catch (err) { next(err); }
}

async function getTruck(req, res, next) {
  try {
    const truck = await truckService.getTruckById(req.params.truckId, req.user.uid);
    return success(res, truck);
  } catch (err) { next(err); }
}

async function updateStatus(req, res, next) {
  try {
    const result = await truckService.updateTruckStatus(req.params.truckId, req.user.uid, req.body.status);
    return success(res, result, 'Status updated');
  } catch (err) { next(err); }
}

async function deleteTruck(req, res, next) {
  try {
    await truckService.deleteTruck(req.params.truckId, req.user.uid);
    return success(res, null, 'Truck deleted');
  } catch (err) { next(err); }
}

module.exports = { addTruck, getTrucks, getTruck, updateStatus, deleteTruck };
