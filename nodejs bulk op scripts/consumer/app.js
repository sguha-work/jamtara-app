const { Pool } = require("pg");
const connectionString = `postgresql://bentek:Q4BLF1znoIh1f3RM8P842g@free-tier12.aws-ap-south-1.cockroachlabs.cloud:26257/defaultdb?sslmode=verify-full&options=--cluster%3Dbentek-dev-636`;
const fs = require('fs');
const { promises: { readdir } } = require('fs');
const { Console } = require("console");

class CockroachDB {

    constructor() {
        this.pool = false;
        this.client = false;
    }
    connect() {
        return new Promise(async (resolve, reject) => {
            this.pool = new Pool({
                connectionString,
                max: 1,
            });
            this.client = await this.pool.connect();
            resolve();
        });
    }
    disconnect() {
        this.client.release();
    }

    query(query) {
        return new Promise(async (resolve, reject) => {
            try {
                let { rows } = await this.client.query(query);
                resolve(rows);
            } catch (err) {
                console.log("Query error", err.toString());
                reject({
                    message: err.message,
                    status: err.code === 11000 ? 409 : 500,
                });
            }
        });
    }
    getDivisionIdByDivisionName(divisionName) {
        switch (divisionName) {
            case `Giridhih (N)`:
                divisionName = 'Giridih North';
                break;
            case `Giridhih (S)`:
                divisionName = 'Giridih South';
                break;
        }
        return new Promise(async (resolve, reject) => {
            try {
                const query = `SELECT id FROM divisions WHERE division='${divisionName}'`;
                const result = await this.query(query);
                if (!result.length)
                    console.log('result->', divisionName);
                resolve(result);
            } catch (error) {
                reject(error);
            }
        });
    }
    getSubDivisionIdBySubDivisionName(subDivisionName) {
        switch (subDivisionName) {
            case `Jassidih`:
                subDivisionName = 'Jasidih';
                break;
            case `sarath`:
                subDivisionName = 'Sarath';
                break;
            case `Dumka (R)`:
                subDivisionName = 'Dumka(R)';
                break;
            case `DUMKA (R)`:
                subDivisionName = 'Dumka(R)';
                break;
            case `Madupur`:
                subDivisionName = 'Madhupur';
                break;
            case `Jamua`:
                subDivisionName = 'Jamua';
                break;
            case `Dumka (U)`:
                subDivisionName = 'Dumka(U)';
                break;
            case `Giridih (R)`:
                subDivisionName = 'Giridih(R)';
                break;
            case `Giridih (U)`:
                subDivisionName = 'Giridih(U)';
                break;
            case `Pakur (Rural)`:
                subDivisionName = 'Pakur(Rural)';
                break;
            case `Tati Silwai`:
                subDivisionName = 'Tati silwai';
                break;
        }
        return new Promise(async (resolve, reject) => {
            try {
                const query = `SELECT id FROM sub_divisions WHERE sub_division='${subDivisionName}'`;
                const result = await this.query(query);
                if (!result.length)
                    console.log('result->', subDivisionName);
                resolve(result);
            } catch (error) {
                reject(error);
            }
        });
    }
}
const alterMeterStatusText = (type) => {
    switch (type) {
        case 'Defective ':
            type = 'Defective';
            break;
        case ' Defective':
            type = 'Defective';
            break;
        case ' Unmetered':
            type = 'Unmetered';
            break;
        case 'Unmetered ':
            type = 'Unmetered';
            break;
    }
    return type;
}
const alterConsumerType = (type) => {
    switch (type) {
        case 'RULAR':
            type = 'RURAL';
            break;
        case 'GOVT':
            type = 'GOVERNMENT';
            break;
        case 'Other':
            type = 'OTHER';
            break;
        case 'OTHERS':
            type = 'OTHER';
            break;
        case 'Jamtara':
            type = 'OTHER';
            break;
        case 'JBVNL':
            type = 'JUVNL';
            break;
        case 'Rural':
            type = 'RURAL';
            break;
        case 'Urban':
            type = 'URBAN';
            break;
        case 'Other ':
            type = 'OTHER';
            break;
        case 'GOVERNMENT ':
            type = 'GOVERNMENT';
            break;
    }
    return type;
}
(async () => {
    const objCock = new CockroachDB();

    try {
        await objCock.connect();
        const { readdirSync } = require('fs');
        let divisionDirectories = readdirSync("csv", { withFileTypes: true })
            .filter(dirent => dirent.isDirectory())
            .map(dirent => dirent.name);
        for (let divisionIndex in divisionDirectories) {
            // getting division id from db
            console.log('division name -->', divisionDirectories[divisionIndex]);
            let searchString = divisionDirectories[divisionIndex];
            switch (searchString) {
                case 'RANCHI NEW CPTL':
                    searchString = `Ranchi New Capital`;
                    break;
            }
            const divisionData = await objCock.query(`SELECT * FROM divisions where UPPER(division)=UPPER('${searchString}')`);
            const circleId = divisionData[0]['circle_id'];//*
            const divisionId = divisionData[0]['id'];//*

            const subDivisionFileNames = fs.readdirSync(`./csv/${divisionDirectories[divisionIndex]}/`, { withFileTypes: true })
                .filter(item => !item.isDirectory())
                .map(item => item.name.split('.csv')[0]);
            for (let subdivisionIndex in subDivisionFileNames) {
                if(subDivisionFileNames[subdivisionIndex]==='.DS_Store'){
                    continue;
                }
                console.log('sub division->', subDivisionFileNames[subdivisionIndex]);
                const subDivisionData = await objCock.getSubDivisionIdBySubDivisionName(subDivisionFileNames[subdivisionIndex]);console.log(subDivisionData);
                const subDivisionId = subDivisionData[0]["id"];//*
                console.log('sub division id', subDivisionId);
                const filePath = `./csv/${divisionDirectories[divisionIndex]}/${subDivisionFileNames[subdivisionIndex]}.csv`;
                let fileData = await fs.readFileSync(filePath, 'utf8');
                fileData = fileData.split(/\r?\n/);
                for (lineIndex in fileData) {
                    if (lineIndex > 0) {
                        const splitedData = fileData[lineIndex].split(',');
                        if (splitedData.length < 15) {
                            continue;
                        }
                        const aadhar_number = null;
                        const addr1 = splitedData[1];
                        const addr2 = splitedData[2];
                        const circle_id = circleId;
                        const consumer_number = splitedData[4];
                        const consumer_type = alterConsumerType(splitedData[5]);
                        const division_id = divisionId;
                        const load = parseInt(splitedData[7]);
                        const meter_make = splitedData[8];
                        const meter_number = null;
                        const meter_status = alterMeterStatusText(splitedData[10]);
                        const mobile = null;
                        const name = splitedData[12];
                        const sub_division_id = subDivisionId;
                        const tariff = splitedData[14];
                        const supervisor_approval_status = 'Approved';
                        const created_by = 'bentek';
                        const created_at = '2022-07-26 21:16:48.732 +0530';
                        const updated_at = '2022-07-26 21:16:48.732 +0530';
                        const query = `INSERT INTO consumers (
                            aadhar_number,
                            addr1,
                            addr2,
                            circle_id,
                            consumer_number,
                            consumer_type,
                            division_id,
                            load,
                            meter_make,
                            meter_number,
                            meter_status,
                            mobile,
                            name,
                            sub_division_id,
                            tariff,
                            supervisor_approval_status,
                            created_by,
                            created_at,
                            updated_at) VALUES (
                                ${aadhar_number},
                                '${addr1}',
                                '${addr2}',
                                '${circle_id}',
                                '${consumer_number}',
                                '${consumer_type}',
                                '${division_id}',
                                ${load},
                                '${meter_make}',
                                ${meter_number},
                                '${meter_status}',
                                ${mobile},
                                '${name}',
                                '${sub_division_id}',
                                '${tariff}',
                                '${supervisor_approval_status}',
                                '${created_by}',
                                '${created_at}',
                                '${updated_at}'
                            );`;
                        try {

                            await objCock.query(query);
                        } catch (error) {
                            console.log(splitedData);
                            //console.log(query);
                            console.log('message->', error.message);
                            if (error.message.indexOf('duplicate key value') != -1) {
                                fs.appendFileSync('JAMTARA.txt', '\n');
                                fs.appendFileSync('JAMTARA.txt', splitedData.join(','));
                                continue;
                            }
                            console.log('deleting data of this division');
                            const delquery = `DELETE FROM consumers WHERE division_id='${divisionId}' AND sub_division_id='${subDivisionId}';`
                            await objCock.query(delquery);
                            return false;
                        }
                    }
                }
            }
        }
    } catch (error) {
        console.log(error);
    } finally {
        console.log('done');
        objCock.disconnect();
        //exit;
    }
    return true;
})();
