const { Pool, Client } = require('pg')
const pool = new Pool({
    user: 'bentek',
    host: 'free-tier12.aws-ap-south-1.cockroachlabs.cloud',
    database: 'defaultdb',
    password: '!meter@Bentec1827',
    port: 26257,
    options: "--cluster=bentek-meter-lagao-635",
    
});
pool.query('SELECT NOW()', (err, res) => {
    if (err) {
        console.log(err);
    } else {
        console.log('connected');
    }
    pool.end();
})