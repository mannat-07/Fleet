const insuranceService = require('../services/insuranceService');
const { success, created } = require('../utils/response');

async function addInsurance(req, res, next) {
  try {
    const record = await insuranceService.createInsurance({
      ownerId: req.user.uid,
      ...req.body,
    });
    return created(res, record, 'Insurance record created');
  } catch (err) { next(err); }
}

async function getInsurances(req, res, next) {
  try {
    const records = await insuranceService.getInsuranceRecords(req.user.uid);
    return success(res, { insurance: records, count: records.length });
  } catch (err) { next(err); }
}

async function getInsurance(req, res, next) {
  try {
    const record = await insuranceService.getInsuranceById(req.params.insuranceId, req.user.uid);
    return success(res, record);
  } catch (err) { next(err); }
}

async function updateInsurance(req, res, next) {
  try {
    const record = await insuranceService.updateInsurance(
      req.params.insuranceId,
      req.user.uid,
      req.body
    );
    return success(res, record, 'Insurance record updated');
  } catch (err) { next(err); }
}

async function deleteInsurance(req, res, next) {
  try {
    await insuranceService.deleteInsurance(req.params.insuranceId, req.user.uid);
    return success(res, null, 'Insurance record deleted');
  } catch (err) { next(err); }
}

module.exports = { addInsurance, getInsurances, getInsurance, updateInsurance, deleteInsurance };
