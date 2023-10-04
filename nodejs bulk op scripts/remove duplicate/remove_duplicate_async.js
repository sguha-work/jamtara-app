const admin = require("firebase-admin");
const { getFirestore } = require('firebase-admin/firestore');
const fs = require('fs');
const serviceAccount = require("./exported.json");
const logFileName = 'log1.txt';
let lengthOfDuplicateData = 0;
if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
    });
}
const db = getFirestore();
const getData = (collectionName) => new Promise(async (resolve, reject) => {
    try {
        const documentSnapshot = await db.collection(collectionName).get();
        const dataArray = [];
        documentSnapshot.forEach((doc) => {
            dataArray.push(doc.data());
        });
        resolve(dataArray);
    } catch (err) {
        reject(err);
    }
});

/**
 * This function check if duplicate value exists in the collection based on the value and attribte name provided
 * If duplicate value exists it deletes those values
 * @param {*} value 
 * @param {*} attributeName 
 * @param {*} collectionName 
 * @returns 
 */
 const checkIfDuplicateExistsAndRemoveDuplicates = (value, attributeName, collectionName) => new Promise(async (resolve, reject) => {
    try {
        const documentSnapshot = await db.collection(collectionName).where(attributeName, "==", value).get();
        const dataArray = [];
        let index = 0;
        documentSnapshot.forEach((doc) => {
            dataArray.push(doc.data());
            dataArray[index]['id'] = doc.id;
            index += 1;
        });
        if (dataArray.length > 1) {
            console.log(`${dataArray.length} duplicate exists for attribute ${attributeName} and value ${value} in collection ${collectionName}`);
            fs.appendFileSync(logFileName, `\n ${dataArray.length} duplicate exists for attribute ${attributeName} and value ${value} in collection ${collectionName}`)
            lengthOfDuplicateData += (dataArray.length - 1);
            // removing duplicate docs
            let dataToSkipDelete=false;
            for (let index = 0; index < dataArray.length; index++) {
                const data = dataArray[index];
                fs.appendFileSync(logFileName, `${JSON.stringify(data, null, 4)}`);
                if(data['METER NUMBER'] && data['METER NUMBER']!='') {
                    dataToSkipDelete = data;
                }
            }
            if(!dataToSkipDelete) {
                dataToSkipDelete = dataArray[0];
            }
            for (let index = 0; index < dataArray.length; index++) {
                if(dataArray[index].id!=dataToSkipDelete.id) {
                    console.log(`Deleting data with id ${dataArray[index].id}`);
                    await db.collection(collectionName).doc(dataArray[index].id).delete()
                }
            }
        }
        resolve({ "success": true });
    } catch (err) {
        reject(err);
    }
});

const removeDuplicate = (collectionName, attributeToIdentifyDulpicateEntry) => new Promise(async (resolve, reject) => {
    try {
        console.log(`Getting entire data set`);
        const dataList = await getData(collectionName);
        console.log('got data');
        console.log(`Total number of data in collection ${collectionName} is ${dataList.length}`);
        fs.writeFileSync(logFileName, '');
        let checkedDataList = []
        let promises = [];
        for (let index in dataList) {
            console.log(`Checking data of index ${index}`);
            if (checkedDataList.indexOf(dataList[index][attributeToIdentifyDulpicateEntry]) == -1) {
                checkedDataList.push(dataList[index][attributeToIdentifyDulpicateEntry]);
                console.log('pushing');
                promises.push(new Promise(async (resolve, reject) => {
                    try {
                        await checkIfDuplicateExistsAndRemoveDuplicates(dataList[index][attributeToIdentifyDulpicateEntry], attributeToIdentifyDulpicateEntry, collectionName);
                        resolve({ "success": true });
                    } catch (err) {
                        reject(err);
                    }
                }));
            }
        }
        console.log(`Promises length ${promises.length}`)
        Promise.all(promises).then((data) => {
            fs.appendFileSync(logFileName, `Program has removed ${lengthOfDuplicateData} number of duplicate data`);
            console.log(`Program has removed ${lengthOfDuplicateData} number of duplicate data`);
            resolve(data);
        }).catch((err) => {
            console.log("error -- >", err);
            reject(err);
        });

    } catch (err) {
        reject(err);
    }
});

(async () => {
    try {
        await removeDuplicate("collection_consumers", "CONSUMER NO");
    } catch (err) {
        console.log(`error occured`, err);
    }
})();
