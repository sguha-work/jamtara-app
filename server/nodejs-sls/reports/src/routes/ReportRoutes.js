var express = require("express");
var router = express.Router();

const reportsController = require("../controllers/ReportController");
// const CognitoExpress = require("cognito-express");
// //Initializing CognitoExpress constructor
// const cognitoExpress = new CognitoExpress({
//   region: process.env.AWS_REGION, //process.env.AWS_REGION,
//   cognitoUserPoolId: process.env.COGNITO_USER_POOL_ID,
//   tokenUse: "access", //Possible Values: access | id
//   tokenExpiration: 3600 //Up to default expiration of 1 hour (3600000 ms)
// });
// const jwtVerifier = (req, res, next) => {
//   //I'm passing in the access token in header under key accessToken
//   const accessTokenFromClient = (req.headers.authorization) ? req.headers.authorization.replace("Bearer ", "") : '';
//   // //Fail if token not present in header.
//   res.setHeader('Access-Control-Allow-Origin', '*');
//   res.setHeader('Access-Control-Allow-Credentials', 'true');
//   if (!accessTokenFromClient) return res.status(401).json({ message: "Access Token missing from header", status: 401 });
//   cognitoExpress.validate(accessTokenFromClient, function (err, response) {

//     //If API is not authenticated, Return 401 with error message. 
//     if (err) return res.status(401).json({ message: err, status: 401 });
//     //Else API has been authenticated. Proceed.
//     req.identity = response;
//     req.identity.authorization = req.headers.authorization;
//     next();
//   });
// };

router.get("/:reportId", async function (req, res, next) {
  await reportsController.fetchReports(req, res);
});

router.get("/search/condition", async function (req, res, next) {
  await reportsController.fetchReportsConditionaly(req, res);
});

router.get("/count/agent/:agentId", async function (req, res, next) {
  await reportsController.fetchReportCountByAgent(req, res);
});

router.get("/agent/:agentId", async function (req, res, next) {
  await reportsController.fetchReportsByAgent(req, res);
});

router.get("/get-data/send-mail", async function (req, res, next) {
  await reportsController.getBulkReportData(req, res);
});

router.post("/", async function (req, res, next) {
  await reportsController.createReport(req, res);
});


module.exports = router;
