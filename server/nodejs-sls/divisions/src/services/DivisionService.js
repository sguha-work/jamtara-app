const Service = require("./Service");
const AWS = require("aws-sdk");
const dbService = require("./DBService");
const ReportModel = require("../models/DivisionModel");
const divisionDBName = process.env.divisionDBName;
const subDivisionDBName = process.env.subDivisionDBName;

const fetchDivisions = ({ byuser, perpage, currentpage, sort, order }) => new Promise(async (resolve, reject) => {
  let responseObj = {};
  let filter = {};
  try {
    responseObj.status = 200;
    let result = await dbService.find(ReportModel);
    let promises = []
    const setSubdivisions = (individualDivision) => new Promise(async (resolve, reject) => {
      console.log(individualDivision.id);
      const query = `SELECT * FROM sub_divisions WHERE division_id='${individualDivision.id}'`;
      const subdivisionResultSet = await dbService.query(query);
      individualDivision["sub_divisions"] = subdivisionResultSet;
      resolve();
    });
    for (let index = 0; index < result.length; index++) {
      promises.push(new Promise(async (resolve, reject) => {
        await setSubdivisions(result[index]);
        resolve();
      }));
    }
    await Promise.all(promises);
    responseObj.data = result;
    resolve(Service.successResponse(responseObj, responseObj.status));
  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

const fetchDivisionsByCircle = ({ circleId }) => new Promise(async (resolve, reject) => {
  let responseObj = {};
  try {
    const result = await dbService.query(`SELECT * FROM ${divisionDBName} WHERE circle_id='${circleId}';`);
    responseObj.data = result;
    responseObj.status = 200;
    resolve(Service.successResponse(responseObj, responseObj.status));
  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

const createDivision = ({ circle_id, division}) => new Promise(async (resolve, reject) => {
  let responseObj = {};
  try {
    const result = await dbService.query(`INSERT INTO ${divisionDBName} (circle_id, division)    VALUES ('${circle_id}','${division}');`);
    responseObj.data = result;
    responseObj.status = 201;
    resolve(Service.successResponse(responseObj, responseObj.status));
  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

const createSubDivision = ({ division_id, sub_division}) => new Promise(async (resolve, reject) => {
  let responseObj = {};
  try {
    const result = await dbService.query(`INSERT INTO ${subDivisionDBName} (division_id, sub_division)    VALUES ('${division_id}','${sub_division}');`);
    responseObj.data = result;
    responseObj.status = 201;
    resolve(Service.successResponse(responseObj, responseObj.status));
  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

const updateDivision = ({ division, divisionId }) => new Promise(async (resolve, reject) => {
  let responseObj = {};
  try {
    const result = await dbService.query(`UPDATE ${divisionDBName} SET division = '${division}' WHERE id = '${divisionId}';`);
    responseObj.data = result;
    responseObj.status = 204;
    resolve(Service.successResponse(responseObj, responseObj.status));
  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

module.exports = {
  fetchDivisions,
  createDivision,
  fetchDivisionsByCircle,
  updateDivision,
  createSubDivision
};
