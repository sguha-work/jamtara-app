/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> } 
 */
exports.seed = async function (knex) {
  // Deletes ALL existing entries
  await knex('role').del()
  await knex('role').insert([
    { role_name: 'SUPERADMIN' },
    { role_name: 'ADMIN' },
    { role_name: 'SUPERVISOR' },
    { role_name: 'AGENT' }
  ]);
};
