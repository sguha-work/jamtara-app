// index.js

const serverless = require('serverless-http');
const bodyParser = require('body-parser');
const express = require('express')
const app = express();
var authRouter = require('./routes/AuthRoutes');
app.use(bodyParser.json({ strict: false }));
// Get User endpoint
app.use('/auth', authRouter);
module.exports.handler = serverless(app);