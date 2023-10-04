const { getFirestore } = require('firebase-admin/firestore');
//const firebase = require("firebase");
// Required for side-effects
//require("firebase/firestore");
const { Pool } = require("pg");
const { exit } = require('process');
const connectionString = `postgresql://bentek:Q4BLF1znoIh1f3RM8P842g@free-tier12.aws-ap-south-1.cockroachlabs.cloud:26257/defaultdb?sslmode=verify-full&options=--cluster%3Dbentek-dev-636`;

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
    deleteFieldFromCollection(collectionName, attributeName) {
        return new Promise(async (resolve, reject) => {
            try {
                const documentSnapshot = await this.db.collection(collectionName).get();
                const dataArray = [];
                let index = 0;
                documentSnapshot.forEach((doc) => {
                    dataArray.push(doc.data());
                    dataArray[index]['id'] = doc.id;
                    index += 1;
                });
                for (let index in dataArray) {
                    let docId = dataArray[index]['id'];
                    let updatedObj = {};
                    updatedObj[attributeName] = firebase.firestore.FieldValue.delete();
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
                    data.id=doc.id
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
    updateFBUserWithDivisionId(docId, divisionId, multi = false) {
        return new Promise(async (resolve, reject) => {
            try {
                let updatedObj = {};
                if (multi) {
                    updatedObj['divisionIds'] = divisionId;                    
                } else {                    
                    updatedObj['divisionIds'] = [divisionId];
                }
                await this.db.collection('collection_users').doc(docId).update(updatedObj);
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
}
(async () => {
    const objFB = new FireBase();
    const objCock = new CockroachDB();
    try {
        await objFB.dumpFBDataAsJSON("collection_users");
        //await obj.deleteFieldFromCollection("collection_users", "divisionId");
        //obj.updateCollection("collection_consumers", "isRejectedBySupervisor", "", false);
        // const userDataFromFB = await objFB.getFireBaseCollection('collection_users');
        // for (let userIndex in userDataFromFB) {
        //     const individualUser = userDataFromFB[userIndex];
        //     if (individualUser.division) {
        //         //console.log(individualUser.division);
        //         const divisionId = await objCock.getDivisionIdByDivisionName(individualUser.division);
        //         const id = (divisionId.length) ? divisionId[0].id : false;
        //         if (id) {
        //             // update firebase with divisionId
        //             await objFB.updateFBUserWithDivisionId(individualUser.id, id);
        //         }
        //     }
        //     if (individualUser.divisions) {
        //         let ids = [];
        //         for (let divisionIndex in individualUser.divisions) {
        //             const individualDivision = individualUser.divisions[divisionIndex];
        //             const divisionId = await objCock.getDivisionIdByDivisionName(individualDivision);
        //             const id = (divisionId.length) ? divisionId[0].id : false;
        //             ids.push(id);
        //             console.log('division name ' + individualDivision + ' id =' + id);
        //         }
        //         if (ids.length) {
        //             await objFB.updateFBUserWithDivisionId(individualUser.id, ids, true);
        //         }
        //     }
        // }
        // objCock.disconnect();

    } catch (error) {
        console.log(error);
    } finally {
        console.log('done');
        exit;
    }
    return true;
})();
