const Controller = require("./Controller");
const service = require("../services/AuthService");


const login = async (request, response) => {
  await Controller.handleRequest(request, response, service.login);
};

const changePassword = async (request, response) => {
  await Controller.handleRequest(request, response, service.changePassword);
};

module.exports = {
  login,
  changePassword
};
