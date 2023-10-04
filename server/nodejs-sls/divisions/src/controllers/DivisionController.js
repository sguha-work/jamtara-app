const Controller = require("./Controller");
const service = require("../services/DivisionService");

const fetchDivisions = async (request, response) => {
  await Controller.handleRequest(request, response, service.fetchDivisions);
};

const fetchDivisionsByCircle = async (request, response) => {
  await Controller.handleRequest(request, response, service.fetchDivisionsByCircle);
};

const createDivision = async (request, response) => {
  await Controller.handleRequest(request, response, service.createDivision);
};

const updateDivision = async (request, response) => {
  await Controller.handleRequest(request, response, service.updateDivision);
};

const createSubDivision = async (request, response) => {
  await Controller.handleRequest(request, response, service.createSubDivision);
};

module.exports = {
  fetchDivisions,
  createDivision,
  fetchDivisionsByCircle,
  updateDivision,
  createSubDivision
};
