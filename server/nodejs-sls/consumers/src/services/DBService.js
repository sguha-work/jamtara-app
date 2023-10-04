const { Pool } = require("pg");
const getConnectionString = (DBName = 'defaultdb') =>
  `postgresql://${process.env.DB_USERNAME}:${process.env.DB_PASSWORD}@${process.env.DB_URL}/${DBName}?sslmode=verify-full&options=--cluster%3Dbentek-dev-636`;

const save = (dataModel, dataToInsert, returnAttribute, dbName) =>
  new Promise(async (resolve, reject) => {
    let pool, client;
    try {
      if (!pool) {
        const connectionString = getConnectionString();
        pool = new Pool({
          connectionString,
          max: 1,
        });
      }
      client = await pool.connect();
      const query = dataModel.insert(dataToInsert).returning(dataModel[returnAttribute]).toQuery();
      let { rows } = await client.query(query);
      resolve(rows);
    } catch (err) {
      console.log("Save err", err.toString());
      reject({
        message: err.message,
        status: err.code === 11000 ? 409 : 500,
      });
    } finally {
      console.log("close db conn");
      client.release();
    }
  });

const find = (dataModel, query, dbName) =>
  new Promise(async (resolve, reject) => {
    let pool, client;
    try {
      if (!pool) {
        const connectionString = getConnectionString();
        console.log("connectionString", connectionString);
        pool = new Pool({
          connectionString,
          max: 1,
        });
      }
      client = await pool.connect();
      const query = dataModel.select().toQuery();//.where(user.state.equals('WA'))
      console.log('query-->', query.text);
      let { rows } = await client.query(query);
      resolve(rows);
    } catch (err) {
      console.log("Find err", err.toString());
      reject({
        message: err.message,
        status: err.code === 11000 ? 409 : 500,
      });
    } finally {
      console.log("close db conn");
      client.release();
    }
  });

const query = (query) =>
  new Promise(async (resolve, reject) => {
    let pool, client;
    try {
      if (!pool) {
        const connectionString = getConnectionString();
        console.log("connectionString", connectionString);
        pool = new Pool({
          connectionString,
          max: 1,
        });
      }
      client = await pool.connect();
      console.log('query-->', query);
      let { rows } = await client.query(query);
      resolve(rows);
    } catch (err) {
      console.log("Query error", err.toString());
      reject({
        message: err.message,
        status: err.code === 11000 ? 409 : 500,
      });
    } finally {
      console.log("close db conn");
      client.release();
    }
  });
module.exports = {
  save,
  find,
  query
};
