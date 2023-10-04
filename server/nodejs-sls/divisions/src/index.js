// index.js

const serverless = require('serverless-http');
const bodyParser = require('body-parser');
const express = require('express')
const app = express();
var reportRouter = require('./routes/DivisionRoutes');
app.use(bodyParser.json({ strict: false }));
// Get User endpoint
app.use('/divisions', reportRouter);
module.exports.handler = serverless(app);