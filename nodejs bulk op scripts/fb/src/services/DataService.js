const AWS = require('aws-sdk');
const admin = require("firebase-admin");
const { getFirestore } = require('firebase-admin/firestore');
const nodemailer = require('nodemailer');
const serviceAccount = require("./exported.json");
let agentList = {};
let currentTimeStamp = Date.now();

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

const sendMail = (csvData) => new Promise(async (resolve, reject) => {
    try {

        const transporter = nodemailer.createTransport({
            service: 'Gmail',
            auth: {
                user: 'aritrikdas@gmail.com',
                pass: 'gydrasanyrffsxws'
            }
        });
        const mailOptions = {
            from: 'aritrikdas@gmail.com',
            to: "bentecmeterlagao@gmail.com",
            bcc: "sguha1988.life@gmail.com,",
            subject: 'Sending Email with report data',
            text: `Download from attachment`,
            attachments: [
      {
        filename: Date.now().toLocaleString()+".csv",
        content: csvData,
      },
    ],
        };
        const mailResp = await transporter.sendMail(mailOptions);
    } catch (error) {
        reject(error);
    }
});
module.exports.getFBData = (event) => new Promise(async (resolve, reject) => {
    try {
        console.log("event", event)
        const starttimestamp = event.starttimestamp,
            endtimestamp = event.endtimestamp,
            divisions = event.divisions,
            subdivision = event.subdivision,
            consumername = event.consumername,
            consumernumber = event.consumernumber,
            createdby = event.createdby,
            isAll = event.isAll;
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
            // checking start and end time
            // let flag_timeCheck = true
            // if (starttimestamp != 0 && endtimestamp != currentTimeStamp) {
            //     let reportTime = individualReportData["createdOn"]
            //     if (reportTime >= starttimestamp && reportTime <= endtimestamp) {
            //         flag_timeCheck = true
            //     } else {
            //         flag_timeCheck = false
            //     }
            // }
            
            // let flag_divisionCheck = true;
            // if (divisions != "") {
            //     if (divisions.indexOf(",") != -1) {
            //         const divisionsList = divisions.split(",");
            //         if (divisionsList.indexOf(individualReportData["division"]) != -1) {
            //             flag_divisionCheck = true;
            //         } else {
            //             flag_divisionCheck = false;
            //         }
            //     } else {
            //         if (individualReportData["division"] == divisions) {
            //             flag_divisionCheck = true;
            //         }
            //         else {
            //             flag_divisionCheck = false;
            //         }
            //     }
            // }
            // // checking subdivision
            // let flag_subdivisionCheck = true;
            // if (subdivision != "") {
            //     if (individualReportData["subdivision"] == subdivision) {
            //         flag_subdivisionCheck = true;
            //     }
            //     else {
            //         flag_subdivisionCheck = false
            //     }
            // }
            // // checking consumerName
            // let flag_consumerNameCheck = true;
            // if (consumername != "") {
            //     if (individualReportData["consumerName"] == consumername) {
            //         flag_consumerNameCheck = true;
            //     }
            //     else {
            //         flag_consumerNameCheck = false;
            //     }
            // }
            // // checking consumerNumber
            // let flag_consumerNumberCheck = true
            // if (consumernumber != "") {
            //     if (individualReportData["consumerNumber"] == consumernumber) {
            //         flag_consumerNumberCheck = true
            //     }
            //     else {
            //         flag_consumerNumberCheck = false
            //     }
            // }
            // // checking createdBy
            // let flag_createdByCheck = true
            // if (createdby != "") {
            //     if (individualReportData["createdBy"] == createdby) {
            //         flag_createdByCheck = true;
            //     }
            //     else {
            //         flag_createdByCheck = false;
            //     }
            // }
            if (true) {
                individualReportData.id = documentId;
                individualReportData.agentName = agentList[individualReportData.createdBy]["fullName"];
                individualReportData.agentEmail = agentList[individualReportData.createdBy]["email"];
                individualReportData.agentPhoneNumber = agentList[individualReportData.createdBy]["phoneNumber"];
                individualReportData.agentAadharNumber = agentList[individualReportData.createdBy]["aadharNumber"];
                individualReportData.createdOnDateTime = (new Date(individualReportData.createdOn).toLocaleString()).split(',').join('|');
                outputData.push(individualReportData);
            }
        });
        const csvdata = convertJSONToCSV({ outputData: outputData });
        
        await sendMail(csvdata);
        resolve(outputData);
    } catch (error) {
        console.log("error-->", error);
        reject(error);
    }
});