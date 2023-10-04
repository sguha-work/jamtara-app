// index.js

const serverless = require('serverless-http');
const bodyParser = require('body-parser');
const express = require('express')
const app = express();
var reportRouter = require('./routes/ReportRoutes');
app.use(bodyParser.json({ strict: false }));
// Get User endpoint
app.use('/report', reportRouter);
module.exports.handler = serverless(app);