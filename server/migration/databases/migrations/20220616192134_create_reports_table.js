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
 * 
{
        "consumerMeterNumber": "431899",
        "subdivision": "Giridih(R)",
        "consumerAadharNumber": "430346377488",
        "longitude": "86.202906",
        "consumerNumber": "BUTKJ0001",
        "createdBy": "wdjW1MRDvBM99Z4gAyTadeHd1uL2",
        "consumerMobileNumber": "9798011516",
        "createdOn": 1649233882534,
        "division": "Giridhih (S)",
        "latitude": "24.2258697",
        "imageLinks": "https://firebasestorage.googleapis.com/v0/b/bentec-meterlagao.appspot.com/o/report_images%2FXNNTA5GjsLZL2FjnT8nGu?alt=media&token=33a08860-b3c2-4609-a418-852147cad762,https://firebasestorage.googleapis.com/v0/b/bentec-meterlagao.appspot.com/o/report_images%2Fl6rIOyieVdQdb_gGmFXeg?alt=media&token=7a2e1845-0ed7-47b2-998f-60aac5221ebc",
        "consumerName": "KURBAN MIYA S/O PASIKA"
    },
 */
/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = async function (knex) {
    await knex.schema.dropTableIfExists('reports');
};
