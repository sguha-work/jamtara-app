const { getFirestore } = require('firebase-admin/firestore');
class UPDATEFB {
    constructor() {
        this.admin = require("firebase-admin");
        
        this.fs = require('fs');
        const serviceAccount = require("./exported.json");
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
                    dataArray.push(doc.data());
                });
                this.fs.writeFileSync(`${collectionName}.json`, JSON.stringify(dataArray, null, 4))
                resolve({ success: true });
            } catch (err) {
                reject(err);
            }
        });
    }
}

(async () => {
    const obj = new UPDATEFB();
    try {
        await obj.dumpFBDataAsJSON("collection_users");
        //await obj.updateCollection("collection_consumers", "isApprovedBySupervisor", "", true);
        //obj.updateCollection("collection_consumers", "isRejectedBySupervisor", "", false);
    } catch (error) {
        console.log(error);
    }
})();
