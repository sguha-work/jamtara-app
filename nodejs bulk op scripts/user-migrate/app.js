const { getFirestore } = require('firebase-admin/firestore');
const { Pool } = require("pg");
const { exit } = require('process');
const bcrypt = require('bcrypt');
const connectionString = `postgresql://bentek:Q4BLF1znoIh1f3RM8P842g@free-tier12.aws-ap-south-1.cockroachlabs.cloud:26257/defaultdb?sslmode=verify-full&options=--cluster%3Dbentek-dev-636`;
const fs = require('fs');
class FireBase {
    constructor() {
        this.admin = require("firebase-admin");

        this.fs = require('fs');
        const serviceAccount = require("./firebase.json");
        if (!this.admin.apps.length) {
            this.admin.initializeApp({
                credential: this.admin.credential.cert(serviceAccount),
            });
        }
        this.db = getFirestore();
    }
    updateCollection(collectionName, attributeName, oldValue, newValue) {
        return new Promise(async (resolve, reject) => {
            try {
                this.logFileName = Date.now() + ".json";
                console.log(`Listing documents under collection "${collectionName}" where "${attributeName}" has value "${oldValue}"`);
                const documentSnapshot = await this.db.collection(collectionName).where(attributeName, "==", oldValue).get();
                const dataArray = [];
                let index = 0;
                documentSnapshot.forEach((doc) => {
                    dataArray.push(doc.data());
                    dataArray[index]['id'] = doc.id;
                    index += 1;
                });
                console.log(`${dataArray.length} number of data is going to update, logging old data in log file`);
                this.fs.writeFileSync(this.logFileName, JSON.stringify(dataArray, null, 4));
                console.log(`Updating ${collectionName}, replacing the attribute ${attributeName} from ${oldValue} to ${newValue}`);
                for (let index in dataArray) {
                    let docId = dataArray[index]['id'];
                    console.log(`Updating data index ${index}/${dataArray.length}`);
                    let updatedObj = {};
                    updatedObj[attributeName] = newValue;
                    await this.db.collection(collectionName).doc(docId).update(updatedObj);
                }
                resolve({ success: true });
            } catch (error) {
                reject(error);
            }
        });
    }

    dumpFBDataAsJSON(collectionName) {
        return new Promise(async (resolve, reject) => {
            try {
                const documentSnapshot = await this.db.collection(collectionName).get();
                const dataArray = [];
                documentSnapshot.forEach((doc) => {
                    let data = doc.data();
                    data.id = doc.id
                    dataArray.push(data);
                });
                this.fs.writeFileSync(`${collectionName}.json`, JSON.stringify(dataArray, null, 4))
                resolve({ success: true });
            } catch (err) {
                reject(err);
            }
        });
    }

    getFireBaseCollection(collectionName) {
        return new Promise(async (resolve, reject) => {
            try {
                const documentSnapshot = await this.db.collection(collectionName).get();
                const dataArray = [];
                documentSnapshot.forEach((doc) => {
                    let data = doc.data();
                    data['id'] = doc.id;
                    dataArray.push(data);
                });
                resolve(dataArray);
            } catch (err) {
                reject(err);
            }
        });
    }
    updateFBReportWithDivisionId(docId, divisionId) {
        return new Promise(async (resolve, reject) => {
            try {
                let updatedObj = {};
                updatedObj['divisionId'] = divisionId;
                await this.db.collection('collection_reports').doc(docId).update(updatedObj);
                resolve(true);
            } catch (error) {
                reject(error);
            }
        });
    }
    updateFBReportWithSubDivisionId(docId, subDivisionId) {
        return new Promise(async (resolve, reject) => {
            try {
                let updatedObj = {};
                updatedObj['subDivisionId'] = subDivisionId;
                await this.db.collection('collection_reports').doc(docId).update(updatedObj);
                resolve(true);
            } catch (error) {
                reject(error);
            }
        });
    }
}

class CockroachDB {

    constructor() {
        this.pool = false;
        this.client = false;
        (async () => {
            if (!this.pool) {
                console.log('connecting to Aarshola');
                this.pool = new Pool({
                    connectionString,
                    max: 1,
                });
            }
            this.client = await this.pool.connect();
        })();

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
(async () => {
    const objFB = new FireBase();
    const objCock = new CockroachDB();
    const defaultPassword = 'User@123';
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(defaultPassword, saltRounds);
    /*
    var hash = crypto.pbkdf2Sync(password,  
    this.salt, 1000, 64, `sha512`).toString(`hex`); 
    */

    try {
        //await objFB.dumpFBDataAsJSON("collection_users");
        //await obj.deleteFieldFromCollection("collection_users", "divisionId");
        //obj.updateCollection("collection_consumers", "isRejectedBySupervisor", "", false);
        // const userDataFromFB = await objFB.getFireBaseCollection('collection_users');
        // console.log('Number of data fetched', userDataFromFB.length);
        // let queries = [];
        // for (let userIndex in userDataFromFB) {
        //     console.log(`Working on index ${userIndex}`);
        //     const individualUser = userDataFromFB[userIndex];
        //     if(isNaN(parseInt(individualUser['approvedOn']))){
        //         individualUser['approvedOn'] = Date.now().toString();
        //     }
        //     if(isNaN(parseInt(individualUser['createdOn']))){
        //         individualUser['createdOn'] = Date.now().toString();
        //     }
        //     if(isNaN(parseInt(individualUser['pin']))){
        //         individualUser['pin'] = '0';
        //     }
        //     if(individualUser['aadharNumber']&&individualUser['aadharNumber'].indexOf(' ')!=-1){
        //         individualUser['aadharNumber'] = individualUser['aadharNumber'].replaceAll(' ','');
        //     }
        //     if(isNaN(parseInt(individualUser['aadharNumber']))){
        //         individualUser['aadharNumber'] = '0';
        //     }
        //     if(!individualUser['divisionIds']) {
        //         individualUser['divisionIds']=[];
        //     }
        //     if(!individualUser['pan']) {
        //         individualUser['pan']='';
        //     }
        //     if(!individualUser['approvedByUserId']) {
        //         individualUser['approvedByUserId']='';
        //     }
        //     if(!individualUser['area']) {
        //         individualUser['area']='';
        //     }
        //     if(!individualUser['city']) {
        //         individualUser['city']='';
        //     }
        //     if(!individualUser['state']) {
        //         individualUser['state']='';
        //     }
        //     if(!individualUser['email']||individualUser['email']=='') {
        //         individualUser['email']=`admin${userIndex}.dummy.email@bentect.com`;
        //     }
        //     let divisionIDsFromCokcrch = [];

        //     const insertQuery1 = `INSERT INTO user_auth (user_id, password, email, mobile) VALUES ('${individualUser['id']}','${passwordHash}','${individualUser['email']}',${parseInt(individualUser['phoneNumber'])})`;
        //     console.log(insertQuery1);
        //     const insertQuery2 = `INSERT INTO users (
        //         user_id,
        //         aadhar_number,
        //         approved_by_user_id,
        //         approved_on,
        //         area,
        //         city,
        //         pin,
        //         state,
        //         created_by_user_id,
        //         created_on,
        //         dob,
        //         division_ids,
        //         full_name,
        //         image_path,
        //         pan,
        //         user_type
        //     ) VALUES (
        //         '${individualUser['id']}',
        //         ${individualUser['aadharNumber']},
        //         '${individualUser['approvedByUserId']}',
        //         ${parseInt(individualUser['approvedOn'])},
        //         '${individualUser['area']}',
        //         '${individualUser['city']}',
        //         ${parseInt(individualUser['pin'])},
        //         '${individualUser['state']}',
        //         '${individualUser['createdByUserId']}',
        //         ${individualUser['createdOn']},
        //         '${individualUser['dateOfBirth']}',
        //         '${JSON.stringify(individualUser['divisionIds'])}',
        //         '${individualUser['fullName']}',
        //         '${individualUser['imagePath']}',
        //         '${individualUser['panNumber']}',
        //         '${individualUser['userType']}'                
        //     )`;
        //     console.log(insertQuery2);
        //     queries.push(insertQuery1);
        //     queries.push(insertQuery2);
        //     const result1 = await objCock.query(insertQuery1);
        //     const result2 = await objCock.query(insertQuery2);
        //     console.log('Data inserted in both table');
        // }
        //fs.writeFileSync('queries.txt', JSON.stringify(queries));
        // creating user table
        /*
                -- public."users" definition

        -- Drop table

        -- DROP TABLE public."users";

        CREATE TABLE public.users (
            user_id VARCHAR(50) NOT NULL,
            aadhar_number INT8 NOT NULL,
            approved_by_user_id VARCHAR(50) NULL,
            approved_on INT8 NULL,
            area VARCHAR NULL,
            city VARCHAR NULL,
            pin VARCHAR NULL,
            state VARCHAR NULL,
            created_by_user_id VARCHAR(50) NULL,
            created_on INT8 NULL,
            division_ids JSONB NULL,
            full_name VARCHAR(50) NULL,
            user_type VARCHAR NULL,
            id UUID NOT NULL DEFAULT gen_random_uuid(),
            dob VARCHAR(20) NULL,
            image_path VARCHAR(200) NULL,
            pan VARCHAR(20) NULL,
            CONSTRAINT users_pk PRIMARY KEY (id ASC),
            UNIQUE INDEX users_un (user_id ASC)
        );
            -- public.user_auth definition

            -- Drop table

            -- DROP TABLE public.user_auth;

            CREATE TABLE public.user_auth (
                user_id VARCHAR(50) NOT NULL,
                email VARCHAR(100) NOT NULL,
                mobile INT8 NOT NULL,
                password VARCHAR(100) NOT NULL,
                CONSTRAINT user_auth_pk PRIMARY KEY (user_id ASC),
                UNIQUE INDEX user_auth_un (email ASC, mobile ASC)
            );

            -- public.user_sessions definition

            -- Drop table

            -- DROP TABLE public.user_sessions;

            CREATE TABLE public.user_sessions (
                id UUID NOT NULL DEFAULT gen_random_uuid(),
                user_id UUID NOT NULL,
                login_time INT8 NOT NULL,
                logout_time INT8 NULL,
                rowid INT8 NOT VISIBLE NOT NULL DEFAULT unique_rowid(),
                CONSTRAINT user_sessions_pkey PRIMARY KEY (rowid ASC)
            );

        */
        const userDataFromFB = await objFB.getFireBaseCollection('collection_users');
        //console.log('Number of data fetched', userDataFromFB.length);
        let userIdListFromFB = [];
        for (let userIndex in userDataFromFB) {
            const individualUser = userDataFromFB[userIndex];
            userIdListFromFB.push(individualUser['id']);
        }
        const query = 'SELECT user_id FROM users';
        let userIdListFromCockroach = await objCock.query(query);
        userIdListFromCockroach = userIdListFromCockroach.map((r) => r.user_id);
        //console.log('result',userIdListFromCockroach);
        let missingUserIds = [];
        userIdListFromFB.forEach((userIdFromFB) => {
            if (userIdListFromCockroach.indexOf(userIdFromFB) == -1) {
                console.log(userIdFromFB);
                missingUserIds.push(userIdFromFB);
            }
        });
        console.log(missingUserIds.length);

        // inserting missing data to cockroach
        // for (let individualUser of userDataFromFB) {
        //     if (missingUserIds.indexOf(individualUser['id']) != -1) {
        //         if(!individualUser['divisionIds']) {
        //             let divisionId = await objCock.getDivisionIdByDivisionName(individualUser['division']);
        //             if(divisionId.length) {
        //                 divisionId = divisionId[0].id;
        //                 individualUser['divisionIds'] = [divisionId];
        //                 console.log(individualUser['divisionIds']);
        //             } else {
        //                 continue;
        //             }
        //         }
        //         if(isNaN(parseInt(individualUser['approvedOn']))){
        //             individualUser['approvedOn'] = Date.now().toString();
        //         }
        //         if(isNaN(parseInt(individualUser['createdOn']))){
        //             individualUser['createdOn'] = Date.now().toString();
        //         }
        //         if(isNaN(parseInt(individualUser['pin']))){
        //             individualUser['pin'] = '0';
        //         }
        //         if(individualUser['aadharNumber']&&individualUser['aadharNumber'].indexOf(' ')!=-1){
        //             individualUser['aadharNumber'] = individualUser['aadharNumber'].replaceAll(' ','');
        //         }
        //         if(isNaN(parseInt(individualUser['aadharNumber']))){
        //             individualUser['aadharNumber'] = '0';
        //         }
        //         if(!individualUser['divisionIds']) {
        //             individualUser['divisionIds']=[];
        //         }
        //         if(!individualUser['pan']) {
        //             individualUser['pan']='';
        //         }
        //         if(!individualUser['approvedByUserId']) {
        //             individualUser['approvedByUserId']='';
        //         }
        //         if(!individualUser['area']) {
        //             individualUser['area']='';
        //         }
        //         if(!individualUser['city']) {
        //             individualUser['city']='';
        //         }
        //         if(!individualUser['state']) {
        //             individualUser['state']='';
        //         }
        //         if(!individualUser['email']||individualUser['email']=='') {
        //             individualUser['email']=`admin${userIndex}.dummy.email@bentect.com`;
        //         }
        //         let divisionIDsFromCokcrch = [];

        //         const insertQuery1 = `INSERT INTO user_auth (user_id, password, email, mobile) VALUES ('${individualUser['id']}','${passwordHash}','${individualUser['email']}',${parseInt(individualUser['phoneNumber'])})`;
        //         //console.log(insertQuery1);
        //         const insertQuery2 = `INSERT INTO users (
        //             user_id,
        //             aadhar_number,
        //             approved_by_user_id,
        //             approved_on,
        //             area,
        //             city,
        //             pin,
        //             state,
        //             created_by_user_id,
        //             created_on,
        //             dob,
        //             division_ids,
        //             full_name,
        //             image_path,
        //             pan,
        //             user_type
        //         ) VALUES (
        //             '${individualUser['id']}',
        //             ${individualUser['aadharNumber']},
        //             '${individualUser['approvedByUserId']}',
        //             ${parseInt(individualUser['approvedOn'])},
        //             '${individualUser['area']}',
        //             '${individualUser['city']}',
        //             ${parseInt(individualUser['pin'])},
        //             '${individualUser['state']}',
        //             '${individualUser['createdByUserId']}',
        //             ${individualUser['createdOn']},
        //             '${individualUser['dateOfBirth']}',
        //             '${JSON.stringify(individualUser['divisionIds'])}',
        //             '${individualUser['fullName']}',
        //             '${individualUser['imagePath']}',
        //             '${individualUser['panNumber']}',
        //             '${individualUser['userType']}'                
        //         )`;
        //         //console.log(insertQuery2);
        //         // queries.push(insertQuery1);
        //         // queries.push(insertQuery2);
        //         try {
        //         const result1 = await objCock.query(insertQuery1);
        //         const result2 = await objCock.query(insertQuery2);
        //         console.log('Data inserted in both table');
        //     } catch(error) {
        //         console.log('skipped');
        //     }
        //     }
        // }
        objCock.disconnect();

    } catch (error) {
        console.log(error);
    } finally {

        console.log('done');
        exit;
    }
    return true;
})();
