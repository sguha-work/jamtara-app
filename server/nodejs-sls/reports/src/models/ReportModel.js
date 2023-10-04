const sql = require('sql');

let Reports = sql.define({
  name: 'reports',
  columns: [
    'consumerAadharNumber',
    'consumerMeterNumber',
    'createdBy',
    'createdOn',
    'division',
    'imageLinks',
    'latitude',
    'longitude',
    'subdivision'
  ]
});
module.exports = Reports