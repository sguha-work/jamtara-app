/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function(knex) {
    return knex.schema.createTable('users', function (table) {
      table.uuid("id").primary().notNullable().defaultTo(knex.raw('gen_random_uuid()'));
      table.json('divisionIds');
      table.string('fullName', 255).notNullable();
      table.boolean('isApprovedByAdmin');
      table.integer('pin');
      table.string('email', 255).notNullable().unique();
      table.string('imagePath', 255).notNullable();
      table.string('panNumber', 20).notNullable().unique();
      table.uuid('approvedByUserId', 255);
      table.integer('aadharNumber').unique();
      table.string('dateOfBirth',30);
      table.integer('phoneNumber').unique();
      table.string('city',30);
      table.string('userType',10);
      table.string('createdByUserId',255);
      table.string('area',30);
      table.string('state',30);
      table.timestamps();
    });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function(knex) {
  
};
