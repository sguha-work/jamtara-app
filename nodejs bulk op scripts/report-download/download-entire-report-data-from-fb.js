const admin = require("firebase-admin");
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require("./exported.json");
let agentList = {};
const fs = require('fs');

const convertJSONToCSV = (jsonData) => {
    let csvString = "";
    let mainKeys;
    if (Array.isArray(jsonData.outputData) && jsonData.outputData.length) {
        jsonData.outputData.forEach((individualData) => {
            const keys = Object.keys(individualData);
            if (csvString == "") {
                // setting up header of csv file
                csvString += keys.join(",") + "\n";
                mainKeys = keys;
            }
            mainKeys.forEach((key) => {
                if (key === 'imageLinks' && individualData[key].indexOf(',') !== -1) {
                    csvString += individualData[key].split(',').join('||') + ","
                } else {
                    csvString += individualData[key] + ",";
                }
            });
            csvString = csvString.slice(0, -1);
            csvString += "\n";
        });
    }
    return csvString;
}
const getAgentData = (db) => new Promise(async (resolve, reject) => {
    const userDBSnapshot = await db.collection('collection_users').where("userType", "==", "agent").get();
    userDBSnapshot.forEach((doc) => {
        let data = doc.data();
        if (data["userType"] == "agent") {
            agentList[doc.id] = data;
        }
    });
    console.log("agentList", userDBSnapshot.docs.length);
    resolve();
});

(async () => {
    const getData = () => new Promise(async (resolve, reject) => {
        try {
            if (!admin.apps.length) {
                admin.initializeApp({
                    credential: admin.credential.cert(serviceAccount),
                });
            }
            const db = getFirestore();
            const startFetchingTime = Date.now();
            console.log("fetching data ", startFetchingTime);
            let snapshot = await db.collection('collection_reports').get();
            console.log("data fetch done seconds taken", ((Date.now() - startFetchingTime) / 1000));
            console.log("data length", snapshot.docs.length);
            await getAgentData(db);
            let outputData = [];
            // Print the ID && contents of each document
            const startProcessingTime = Date.now();
            snapshot.forEach(doc => {
                let individualReportData = doc.data();
                const documentId = doc.id;
                individualReportData.id = documentId;
                individualReportData.agentName = agentList[individualReportData.createdBy]["fullName"];
                individualReportData.agentEmail = agentList[individualReportData.createdBy]["email"];
                individualReportData.agentPhoneNumber = agentList[individualReportData.createdBy]["phoneNumber"];
                individualReportData.agentAadharNumber = agentList[individualReportData.createdBy]["aadharNumber"];
                individualReportData.createdOnDateTime = (new Date(individualReportData.createdOn).toLocaleString()).split(',').join('|');
                outputData.push(individualReportData);
            });
            outputData = outputData.sort(function(firstData, secondData){
                return secondData.createdOnDateTime>firstData.createdOnDateTime?1:-1;
            });
            const csvdata = convertJSONToCSV({ outputData: outputData });
            fs.writeFileSync('exported-report-data.csv', csvdata);
            resolve(outputData);
        } catch (error) {
            console.log(error);
            reject(error);
        }
    });
    await getData();
})();