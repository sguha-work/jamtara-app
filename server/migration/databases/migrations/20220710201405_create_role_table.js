/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = async function (knex) {
    return knex.schema.createTable('role', function (table) {
        table.uuid("role_id").primary().notNullable().defaultTo(knex.raw('gen_random_uuid()'));
        table.string('role_name', 16).notNullable().unique();
    })
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = async function (knex) {
    await knex.schema.dropTableIfExists('role');
};
