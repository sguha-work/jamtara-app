exports.up = async function (knex) {
  return knex.schema.createTable('circles', function (table) {
    table.uuid("id").primary().notNullable().defaultTo(knex.raw('gen_random_uuid()'));
    table.string('circle', 24).notNullable().unique();
  }).createTable('divisions', function (table) {
    table.uuid("id").primary().notNullable().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('circle_id', 24).references('circles.id').notNullable().onUpdate('CASCADE').onDelete('CASCADE');
    table.string('division', 24).notNullable().unique();
  }).createTable('sub_divisions', function (table) {
    table.uuid("id").primary().notNullable().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('division_id', 24).references('divisions.id').notNullable().onUpdate('CASCADE').onDelete('CASCADE');
    table.string('sub_division', 24).notNullable().unique();
  });
};

// circle STRING(24) knex.raw('(UUID())')
exports.down = async function (knex) {
  // await knex.raw('SET foreign_key_checks = 0;');
  await knex.schema.dropTableIfExists('sub_divisions').dropTableIfExists('divisions').dropTableIfExists('circles');
  // await knex.raw('SET foreign_key_checks = 1;');
};
