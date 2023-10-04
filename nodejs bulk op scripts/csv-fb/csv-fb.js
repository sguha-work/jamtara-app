const { getFirestore } = require('firebase-admin/firestore');
class CSVFB {
    constructor() {
        this.admin = require("firebase-admin");
        this.logFileName = Date.now() + ".txt";
        this.fs = require('fs');
        const serviceAccount = require("./exported.json");
        if (!this.admin.apps.length) {
            this.admin.initializeApp({
                credential: this.admin.credential.cert(serviceAccount),
            });
        }
        this.db = getFirestore();
    }
    getJSONFromCSV(csvFilePath) {
        return new Promise(async (resolve, reject) => {
            try {
                console.log('processing file -> ', csvFilePath);
                const allFileContents = this.fs.readFileSync(csvFilePath, 'utf-8');
                let lineCounter = 0;
                let headers = [];
                let data = [];
                allFileContents.split(/\r?\n/).forEach((line) => {
                    if (lineCounter === 0) {
                        headers = line.split(",").map((data) => {
                            return data.split('\r')[0];
                        });
                    } else {
                        let individualDataList = line.split(",");
                        let obj = {};
                        individualDataList.forEach((individualData, index) => {
                            if (headers[index]) {
                                obj[headers[index]] = individualData.split('\r')[0];
                            }
                        });
                        data.push(obj);
                    }
                    lineCounter += 1;
                });
                console.log(`Total number of JSON data ${data.length}`);
                resolve(data);
            } catch (error) {
                reject(error);
            }
        });
    }
    checkIfConsumerNoExistsInDB(consumerNo) {
        return new Promise(async (resolve, reject) => {
            try {
                const documentSnapshot = await this.db.collection("collection_consumers").where("CONSUMER NO", "==", consumerNo).get();
                const dataArray = [];
                documentSnapshot.forEach((doc) => {
                    dataArray.push(doc.data());
                });
                if (dataArray.length) {
                    resolve({ exists: true, data: dataArray[0] });
                } else {
                    resolve({ exists: false });
                }
            } catch (error) {
                reject(error);
            }
        });
    }
    writeCSVToFB(fileList, collectionName) {
        return new Promise(async (resolve, reject) => {
            try {
                this.fs.writeFileSync(this.logFileName, '');
                for (let index in fileList) {
                    const jsonDataList = await this.getJSONFromCSV(fileList[index]);
                    //console.log(jsonData);
                    this.fs.writeFileSync(`${Date.now()}.json`, JSON.stringify(jsonDataList, null, 4));
                    for (let jsonIndex in jsonDataList) {
                        const jsonData = jsonDataList[jsonIndex];
                        const isConsumerExists = await this.checkIfConsumerNoExistsInDB(jsonData['CONSUMER NO']);
                        console.log(`Registering consumer ${jsonData['CONSUMER NO']} data index ${jsonIndex}/${jsonDataList.length}`);
                        if (isConsumerExists.exists) {
                            console.log(`consumer data exists logging into log file`);
                            this.fs.appendFileSync(this.logFileName, `\n ${jsonData['CONSUMER NO']} already exists in database`);
                            this.fs.appendFileSync(this.logFileName, `\n` + JSON.stringify(isConsumerExists, isConsumerExists.data, 4));
                        } else {
                            console.log(`Writing to FB`);
                            await this.db.collection(collectionName).add(jsonData);
                        }
                    }
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
                this.fs.writeFileSync(`${collectionName}.json`,JSON.stringify(dataArray,null,4))
                resolve({success:true});
            } catch (err) {
                reject(err);
            }
        });
    }
}

(async () => {
    const obj = new CSVFB();
    try {
        // await obj.writeCSVToFB([
        //     //'data/GIRIDIH NORTH Consumer Data Upload Format - 29129 Nos.csv',
        //     'data/GIRIDIH SOUTH Consumer Data Upload Format - 21906 Nos.csv'
        // ], 'collection_consumers');
        await obj.dumpFBDataAsJSON("collection_consumers");
    } catch (error) {
        console.log(error);
    }
})();
