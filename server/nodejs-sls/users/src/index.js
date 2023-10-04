// index.js

const serverless = require('serverless-http');
const bodyParser = require('body-parser');
const express = require('express')
const app = express();
var userRouter = require('./routes/UserRoutes');
app.use(bodyParser.json({ strict: false }));
// Get User endpoint
app.use('/users', userRouter);
module.exports.handler = serverless(app);