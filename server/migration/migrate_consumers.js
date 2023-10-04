const environment = process.env.NODE_ENV || 'development';
const config = require('./knexfile')[environment];
const knex = require('knex')(config);



const csvFilePath = './consumer_csv/DEOGHAR/Deoghar-I.csv';
const csv = require('csvtojson');
const fs = require('fs');
csv()
    .fromFile(csvFilePath)
    .then(async (jsonObj) => {

        const circles = await knex.select().from('circles');
        const divisions = await knex.select().from('divisions');
        const sub_divisions = await knex.select().from('sub_divisions');
        const timestamp = Date.now();
        // console.log(circles, divisions);

        // console.log(jsonObj);
        const message = fs.createWriteStream(`${__dirname}/consumer_csv/DEOGHAR/logs/${timestamp}_Deoghar-I.log`);
        try {
            
            for (let index = 0; index < jsonObj.length; index++) {
            // for (let index = 0; index < 100; index++) {

                const element = jsonObj[index];
                const DbObj = {
                    "aadhar_number": element.aadhar_number ? element.aadhar_number : null,
                    "addr1": element.addr1,
                    "addr2": element.addr1,
                    "circle_id": circles.filter((c) => { return (c.circle === element.circle) }).map(n => n.id)[0],
                    "consumer_number": element.consumer_number,
                    "consumer_type": element.consumer_type,
                    "division_id": divisions.filter((c) => { return (c.division === element.division) }).map(n => n.id)[0],
                    "load": parseInt(element.load, 10),
                    "meter_make": element.meter_make,
                    "meter_number": element.meter_number ? element.meter_number : null,
                    "meter_status": element.meter_status ? element.meter_status : null,
                    "mobile": element.mobile ? element.mobile : null,
                    "name": element.name ? element.name : null,
                    "sub_division_id": sub_divisions.filter((c) => { return (c.sub_division === element.sub_division) }).map(n => n.id)[0],
                    "tariff": element.tariff ? element.tariff : null,
                    "supervisor_approval_status": "Approved",
                    "created_by": "bentek",
                    // created_at: timestamp,
                    // updated_at: timestamp,
                }
                console.log(`${index} --> Insert data >> ${JSON.stringify(DbObj)}`);
                try {
                    const dbResp = await knex('consumers').insert(DbObj);
                    console.log(`${index} -->  Insert resp >> ${JSON.stringify(dbResp)}`);
                } catch (error) {
                    console.log("Err", error);
                    message.write(`DB Err -> ${error.toString()} \n`);
                }

            }
        } catch (error) {
            console.log("Err", error);
            message.write(`Err -> ${JSON.stringify(error)} \n`);
        }
        message.close();

        // const message = fs.createWriteStream(__dirname + "/consumer_csv/Deoghar-I.json");
        // message.write(JSON.stringify(jsonObj));
        // 
    });