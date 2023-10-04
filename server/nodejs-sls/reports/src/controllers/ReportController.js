const Controller = require("./Controller");
const service = require("../services/ReportService");

const fetchReports = async (request, response) => {
  await Controller.handleRequest(request, response, service.fetchReports);
};

const fetchReportCountByAgent = async (request, response) => {
  await Controller.handleRequest(request, response, service.fetchReportCountByAgent);
};

const fetchReportsByAgent = async (request, response) => {
  await Controller.handleRequest(request, response, service.fetchReportsByAgent);
};

const fetchReportsConditionaly = async (request, response) => {
  await Controller.handleRequest(request, response, service.fetchReportsConditionaly);
};

const getBulkReportData = async (request, response) => {
  await Controller.handleRequest(request, response, service.getBulkReportData);
};

const createReport = async (request, response) => {
  await Controller.handleRequest(request, response, service.createReport);
};

module.exports = {
  fetchReports,
  createReport,
  fetchReportCountByAgent,
  fetchReportsByAgent,
  fetchReportsConditionaly,
  getBulkReportData
};
