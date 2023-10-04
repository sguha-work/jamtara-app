const { Pool } = require("pg");
const getConnectionString = (DBName = 'defaultdb') =>
  `postgresql://${process.env.DB_USERNAME}:${process.env.DB_PASSWORD}@${process.env.DB_URL}/${DBName}?sslmode=verify-full&options=--cluster%3Dbentek-dev-636`;
let pool, client;
const connect = async () => {
  try {
    if (!pool) {
      const connectionString = getConnectionString();
      pool = new Pool({
        connectionString,
        max: 1,
      });
    }
    client = await pool.connect();
  } catch (error) {
    console.log('unable to connect to db');
  }
}

const query = (query) =>
  new Promise(async (resolve, reject) => {
    try {
      let { rows } = await client.query(query);
      resolve(rows);
    } catch (err) {
      console.log("Query error", err.toString());
      reject({
        message: err.message,
        status: err.code === 11000 ? 409 : 500,
      });
    }
  });

const release = () => {
  console.log("close db conn");
  client.release();
}
module.exports = {
  query,
  release,
  connect
};
