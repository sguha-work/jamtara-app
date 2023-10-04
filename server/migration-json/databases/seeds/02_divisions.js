/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> } 
 */

const divisions = [
  { division: 'Deoghar', circle: 'Deoghar' },
  { division: 'Godda', circle: 'Deoghar' },
  { division: 'Madhupur', circle: 'Deoghar' },
  { division: 'Dumka', circle: 'Dumka' },
  { division: 'Jamtara', circle: 'Dumka' },
  { division: 'Giridih North', circle: 'Giridih' },
  { division: 'Giridih South', circle: 'Giridih' },
  { division: 'Khunti', circle: 'Ranchi' },
  { division: 'Ranchi Doranda', circle: 'Ranchi' },
  { division: 'Ranchi East', circle: 'Ranchi' },
  { division: 'Ranchi Kokar', circle: 'Ranchi' },
  { division: 'Ranchi New Capital', circle: 'Ranchi' },
  { division: 'Ranchi West', circle: 'Ranchi' },
  { division: 'Pakur', circle: 'Sahebganj' },
  { division: 'Sahebganj', circle: 'Sahebganj' },
]
exports.seed = async function (knex) {
  // Deletes ALL existing entries
  await knex('divisions').del()
  const circles = await knex.select('id', 'circle').from('circles');

  const result = divisions.map((d) => {
    return {
      division: d.division,
      circle_id: circles.filter((c) => {
        return (c.circle === d.circle)
      }).map(n => n.id)[0]
    }
  })

  console.log("circles", JSON.stringify(result, null, 4));
  await knex('divisions').insert(result);
};
