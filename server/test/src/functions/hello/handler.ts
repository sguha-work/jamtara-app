let start = process.hrtime();

import 'source-map-support/register';

const { Pool } = require("pg");

let pool;

import type { ValidatedEventAPIGatewayProxyEvent } from '@libs/apiGateway';
import { formatJSONResponse } from '@libs/apiGateway';
import { middyfy } from '@libs/lambda';

import schema from './schema';

const sql = require('sql');
const consumersToInsert = require("./new.json");

/**
 * 
 * {
    "aadhar_number": null,
    "addr1": "C/o MD ISRAIL",
    "addr2": "ANSARI KURMA MAL MANDRO",
    "circle": "Deoghar",
    "consumer_number": "KURDS00020",
    "consumer_type": "OTHER",
    "division": "Godda",
    "load": 1,
    "meter_make": "BENTEC",
    "meter_number": 12345678,
    "meter_status": "NotFound",
    "mobile": 1234567898,
    "name": "SAIMUN KHATUN",
    "sub_division": "Mahagama",
    "tariff": "DS-1 (B)",
    "created_on": 1645209010,
    "supervisor_approval_status": "Approved"
}
// ( aadhar_number, addr1, addr2, circle, consumer_number, consumer_type, division, load, 
// meter_make, meter_number, meter_status, mobile, name, sub_division, tariff, created_on, supervisor_approval_status)
 */

const insertRows = (p) => new Promise<void>(async (resolve, reject) => {
  const client = await p.connect();
  console.log("Hey! You successfully connected to your CockroachDB cluster.");
  let Consumers = sql.define({
    name: 'consumers',
    columns: [
      'consumer_id',
      'aadhar_number', 'addr1', 'addr2', 'circle', 'consumer_number', 'consumer_type',
      'division', 'load', 'meter_make', 'meter_number', 'meter_status', 'mobile',
      'name', 'sub_division', 'tariff', 'created_on', 'supervisor_approval_status'
    ]
  });
  // resolve();
  try {

    let query = Consumers.insert(consumersToInsert).returning(Consumers.consumer_id).toQuery();
   let {rows} = await client.query(query);
    // const query = await client.query('SELECT * FROM consumers;');
    // console.log("query >>>", JSON.stringify(query));
    client.release();
    resolve(rows);
  } catch (err) {
    console.log(err.stack);
    reject(err);
  }
})

const hello: ValidatedEventAPIGatewayProxyEvent<typeof schema> = async (event, context) => {
  context.callbackWaitsForEmptyEventLoop = false;
  if (!pool) {
    const connectionString = 'postgresql://bentek:Q4BLF1znoIh1f3RM8P842g@free-tier12.aws-ap-south-1.cockroachlabs.cloud:26257/defaultdb?sslmode=verify-full&options=--cluster%3Dbentek-dev-636';
    pool = new Pool({
      connectionString,
      max: 1,
    });
  }

  try {
    const dbresp = await insertRows(pool);

    console.log("Return Response");
    let stop = process.hrtime(start);

    return formatJSONResponse({
      message: `Hello ${event.body.name}, welcome to the exciting Serverless world!`,
      exectime: `Time Taken to execute: ${(stop[0] * 1e9 + stop[1]) / 1e9} seconds`,
      dbresp: dbresp,
      arrLength: consumersToInsert.length
      // event,
    }, 200);
  } catch (error) {
    console.log("err >>", error);
    return formatJSONResponse({
      message: `500! server err`,
    }, 500);
  }
}

export const main = middyfy(hello);
