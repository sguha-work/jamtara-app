// index.js

const serverless = require("serverless-http");
const bodyParser = require("body-parser");
const express = require("express");
const app = express();
// const AWS = require('aws-sdk');

var fbRouter = require("./routes/fb");
// const USERS_TABLE = process.env.USERS_TABLE;
const IS_OFFLINE = process.env.IS_OFFLINE;

if (IS_OFFLINE === "true") {
  // dynamoDb = new AWS.DynamoDB.DocumentClient({
  //   region: 'localhost',
  //   endpoint: 'http://localhost:8000'
  // })
  // console.log(dynamoDb);
} else {
  // dynamoDb = new AWS.DynamoDB.DocumentClient();
}

app.use(bodyParser.json({ strict: false }));

app.use("/fb", fbRouter);

module.exports.handler = serverless(app);
