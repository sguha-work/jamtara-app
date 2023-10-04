// Update with your config settings.

/**
 * @type { Object.<string, import("knex").Knex.Config> }
 */
//  require('dotenv').config();
//  const { CLIENT, DATABASE, PG_USER, PASSWORD, HOST, PG_PORT, connection } = process.env;
//  console.log('client-->', CLIENT);
module.exports = {

  development: {
    client: "cockroachdb",
    connection: "postgresql://bentek:Q4BLF1znoIh1f3RM8P842g@free-tier12.aws-ap-south-1.cockroachlabs.cloud:26257/defaultdb?sslmode=verify-full&options=--cluster%3Dbentek-dev-636",
    migrations: {
      directory: 'db/migrations',
    },
    seeds: {
      directory: 'db/seeds',
    },
  },

  staging: {
    client: 'postgresql',
    connection: {
      database: 'defaultdb',
      user:     'bentek',
      password: 'Q4BLF1znoIh1f3RM8P842g'
    },
    pool: {
      min: 2,
      max: 10
    },
    migrations: {
      tableName: 'users'
    }
  },

  production: {
    client: 'postgresql',
    connection: {
      database: 'my_db',
      user:     'username',
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
