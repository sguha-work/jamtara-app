/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> } 
 */
exports.seed = async function (knex) {
  // Deletes ALL existing entries
  await knex('circles').del()
  await knex('circles').insert([
    { circle: 'Deoghar' },
    { circle: 'Dumka' },
    { circle: 'Giridih' },
    { circle: 'Ranchi' },
    { circle: 'Sahebganj' }
  ]);
};
