const Controller = require("./Controller");
const service = require("../services/UserService");

const fetchUsers = async (request, response) => {
  await Controller.handleRequest(request, response, service.fetchUsers);
};
const fetchNotifications = async (request, response) => {
  await Controller.handleRequest(request, response, service.fetchNotifications);
};
const fetchUserDetails = async (request, response) => {
  await Controller.handleRequest(request, response, service.fetchUserDetails);
};

const fetchAllUsersDivisionWise = async (request, response) => {
  await Controller.handleRequest(request, response, service.fetchAllUsersDivisionWise);
};

const createUser = async (request, response) => {
  await Controller.handleRequest(request, response, service.createUser);
};

const updateUser = async (request, response) => {
  await Controller.handleRequest(request, response, service.updateUser);
};

const updateNotification = async (request, response) => {
  await Controller.handleRequest(request, response, service.updateNotification);
};

const deleteUser = async (request, response) => {
  await Controller.handleRequest(request, response, service.deleteUser);
};

const updateUserPassword = async () => {
  await Controller.handleRequest(request, response, service.updateUserPassword);
}

module.exports = {
  fetchUsers,
  createUser,
  fetchUserDetails,
  updateUser,
  deleteUser,
  fetchNotifications,
  updateNotification,
  fetchAllUsersDivisionWise,
  updateUserPassword
};
