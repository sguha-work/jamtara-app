const sql = require('sql');

let Divisions = sql.define({
  name: 'divisions',
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
module.exports = Divisions