// Update with your config settings.

/**
 * @type { Object.<string, import("knex").Knex.Config> }
 */

require('dotenv').config();
const { CLIENT, DATABASE, PG_USER, PASSWORD, HOST, PG_PORT, connection } = process.env;


module.exports = {

  development: {
    client: CLIENT,
    connection: connection,
    //{
      // database: DATABASE,
      // user: PG_USER,
      // password: PASSWORD,
      // host: HOST,
      // port: PG_PORT,
    // },
    migrations: {
      directory: __dirname + '/databases/migrations',
    },
    seeds: {
      directory: __dirname + '/databases/seeds',
    },
  },

  staging: {
    client: 'postgresql',
    connection: {
      database: 'my_db',
      user: 'username',
      password: 'password'
    },
    pool: {
      min: 2,
      max: 10
    },
    migrations: {
      tableName: 'knex_migrations'
    }
  },

  production: {
    client: 'postgresql',
    connection: {
      database: 'my_db',
      user: 'username',
      password: 'password'
    },
    pool: {
      min: 2,
      max: 10
    },
    migrations: {
      tableName: 'knex_migrations'
    }
  }

};
