/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
    return knex.schema.createTable('consumers', function (table) {
        table.uuid("id").primary().notNullable().defaultTo(knex.raw('gen_random_uuid()'));
        table.integer('aadhar_number', 12).unique();
        table.string('addr1', 100).notNullable();
        table.string('addr2', 100);
        table.uuid('circle_id', 24).references('id').inTable('circles').notNullable().onUpdate('CASCADE').onDelete('CASCADE');
        table.string('consumer_number', 20).notNullable().unique();
        table.enu('consumer_type', ['OTHER', 'GOVERNMENT', 'RURAL', 'URBAN', 'BPL'], { useNative: true, existingType: true, enumName: 'consumer_type' });
        table.uuid('division_id', 24).references('id').inTable('divisions').notNullable().onUpdate('CASCADE').onDelete('CASCADE');
        table.integer('load', 4);
        table.string('meter_make', 10);
        table.integer('meter_number', 24).unique();
        table.enu('meter_status', ['Burnt', 'Defective', 'Meter Mismatch', 'Meter Not Found', 'Premises Locked', 'Unmetered'], { useNative: true, existingType: true, enumName: 'meter_status' });
        table.integer('mobile', 10).unique();
        table.string('name', 50).notNullable();
        table.uuid('sub_division_id', 24).references('id').inTable('sub_divisions').notNullable().onUpdate('CASCADE').onDelete('CASCADE');
        table.string('tariff', 24);
        table.enu('supervisor_approval_status', ['Pending', 'Approved', 'Rejected'], { useNative: true, existingType: true, enumName: 'supervisor_approval_status' });
        table.string('created_by', 24).notNullable();
        table.timestamps(false, true);
    })
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = async function (knex) {
    // await knex.raw('SET foreign_key_checks = 0;');
    await knex.schema.dropTableIfExists('consumers');
    // await knex.raw('SET foreign_key_checks = 1;');
};
