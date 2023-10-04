/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> } 
 */

const subDivisions = [
  { division: 'Deoghar', sub_division: 'Deoghar-I' },
  { division: 'Deoghar', sub_division: 'Deoghar-II' },
  { division: 'Deoghar', sub_division: 'Jasidih' },
  { division: 'Godda', sub_division: 'Godda' },
  { division: 'Godda', sub_division: 'Mahagama' },
  { division: 'Madhupur', sub_division: 'Madhupur' },
  { division: 'Madhupur', sub_division: 'Sarath' },
  { division: 'Dumka', sub_division: 'Basukinath' },
  { division: 'Dumka', sub_division: 'Dumka(R)' },
  { division: 'Dumka', sub_division: 'Dumka(U)' },
  { division: 'Jamtara', sub_division: 'Jamtara' },
  { division: 'Jamtara', sub_division: 'Mihijam' },
  { division: 'Giridih North', sub_division: 'Jamua' },
  { division: 'Giridih North', sub_division: 'Rajdhanwar' },
  { division: 'Giridih North', sub_division: 'Tisri' },
  { division: 'Giridih South', sub_division: 'Dumri' },
  { division: 'Giridih South', sub_division: 'Giridih(R)' },
  { division: 'Giridih South', sub_division: 'Giridih(U)' },
  { division: 'Giridih South', sub_division: 'Saria' },
  { division: 'Khunti', sub_division: 'Khunti' },
  { division: 'Khunti', sub_division: 'Torpa' },
  { division: 'Ranchi Doranda', sub_division: 'Doranda' },
  { division: 'Ranchi Doranda', sub_division: 'HEC' },
  { division: 'Ranchi Doranda', sub_division: 'Tupudana' },
  { division: 'Ranchi East', sub_division: 'Bundu' },
  { division: 'Ranchi East', sub_division: 'Ormanjhi' },
  { division: 'Ranchi East', sub_division: 'Tati silwai' },
  { division: 'Ranchi Kokar', sub_division: 'Kokar' },
  { division: 'Ranchi Kokar', sub_division: 'RMCH' },
  { division: 'Ranchi New Capital', sub_division: 'Kanke' },
  { division: 'Ranchi West', sub_division: 'Mander' },
  { division: 'Ranchi West', sub_division: 'Ratu Chatti' },
  { division: 'Ranchi West', sub_division: 'Ratu Road' },
  { division: 'Pakur', sub_division: 'Amrapara' },
  { division: 'Pakur', sub_division: 'Pakur' },
  { division: 'Pakur', sub_division: 'Pakur(Rural)' },
  { division: 'Sahebganj', sub_division: 'Barharwa' },
  { division: 'Sahebganj', sub_division: 'Rajmahal' },
  { division: 'Sahebganj', sub_division: 'Sahebganj' }
]
exports.seed = async function (knex) {
  // Deletes ALL existing entries
  await knex('sub_divisions').del()
  const divisions = await knex.select('id', 'division').from('divisions');

  const result = subDivisions.map((d) => {
    return {
      sub_division: d.sub_division,
      division_id: divisions.filter((c) => {
        return (c.division === d.division)
      }).map(n => n.id)[0]
    }
  })

  console.log("circles", JSON.stringify(result, null, 4));
  await knex('sub_divisions').insert(result);
};
