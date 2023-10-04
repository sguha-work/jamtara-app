const Controller = require("./Controller");
const service = require("../services/ConsumerService");

const fetchConsumers = async (request, response) => {
  await Controller.handleRequest(request, response, service.fetchConsumers);
};

const createConsumer = async (request, response) => {
  await Controller.handleRequest(request, response, service.createConsumer);
};

const updateConsumer = async (request, response) => {
  await Controller.handleRequest(request, response, service.updateConsumer);
};

module.exports = {
  fetchConsumers,
  createConsumer,
  updateConsumer
};
