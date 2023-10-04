/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('reports', function (table) {
        table.uuid("id").primary().notNullable().defaultTo(knex.raw('gen_random_uuid()'));
        table.specificType("coordinates", "geometry(point, 4326)");
        table.integer('meter_number', 24).unique();
        table.jsonb('imageLinks', 24);
        table.uuid('consumer_id', 24).references('id').inTable('consumers').notNullable().onUpdate('CASCADE').onDelete('CASCADE');
        table.timestamps();
    })
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = async function (knex) {
    await knex.schema.dropTableIfExists('reports');
};
