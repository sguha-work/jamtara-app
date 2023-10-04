const AWS = require('aws-sdk');
const Service = require('./Service');
const admin = require("firebase-admin");
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require("./exported.json");
const psurlService = require("./PreSignedURLService");
const nodeBase64 = require('nodejs-base64-converter');

// const getPreSignedURL = (folderPath = "fbdata") => new Promise(async (resolve, reject) => {
//   try {
//     const utcTimeStamp = new Date(Date.now() + (new Date().getTimezoneOffset() * 60000)).getTime();
//     const fileName = nodeBase64.encode(utcTimeStamp + "exportedData" + "csv");
//     const url = await psurlService.getPreSignedURL(fileName, folderPath, "csv");
//     resolve(url);
//   } catch (e) {
//     console.log("error in getting pre signed url", e);
//     reject(Service.rejectResponse(
//       e.message || 'Invalid input',
//       e.status || 405,
//     ));
//   }
// });

let currentTimeStamp = Date.now();
let agentList = {};
const getData = ({ downloadfile = false, filename = "", starttimestamp = 0, endtimestamp = currentTimeStamp, divisions = "", subdivision = "", consumername = "", consumernumber = "", createdby = "" }) => new Promise(
  async (resolve, reject) => {
    try {
      if (downloadfile) {
        // const presignedURL = await getPreSignedURL();
        // console.log("presignedURL",presignedURL);
        // invoking lambda to initiate s3 file preparation
        // preparing the json file and uploading it to presigned url by calling processFBData lambda
        const paramsToInvokeLambda = {
          FunctionName: `bw-fb-management-${process.env.stage}-processFBData`, /* required */
          InvocationType: "Event",
          Payload: JSON.stringify({ starttimestamp, endtimestamp, divisions, subdivision, consumername, consumernumber, createdby})
        };
        const lambdaProvider = new AWS.Lambda();
        const preferenceFromDB = await lambdaProvider.invoke(paramsToInvokeLambda).promise();

        resolve(Service.successResponse({
          success: true
        }));
      } else {
        if (!admin.apps.length) {
          admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
          });
        }
        // Initialize Firebase
        //const app = initializeApp(firebaseConfig);
        const db = getFirestore();
        const startFetchingTime = Date.now();
        console.log("fetching data ", startFetchingTime);
        let snapshot;
        if (starttimestamp != 0 && endtimestamp != currentTimeStamp) {
          console.log("here");
          snapshot = await db.collection('collection_reports')
            .where('createdOn', '>=', parseInt(starttimestamp))
            .where('createdOn', '<=', parseInt(endtimestamp))
            .get();
        } else {
          snapshot = await db.collection('collection_reports').get();
        }
        console.log("data fetch done seconds taken", ((Date.now() - startFetchingTime) / 1000));
        console.log("data length", snapshot.docs.length);
        await getAgentData(db);
        let outputData = [];
        // Print the ID && contents of each document
        const startProcessingTime = Date.now();
        snapshot.forEach(doc => {
          ///////////////////////////
          let individualReportData = doc.data();
          const documentId = doc.id;
          // checking start and end time
          let flag_timeCheck = true

          // if (starttimestamp != 0 && endtimestamp != currentTimeStamp) {
          //   let reportTime = individualReportData["createdOn"]
          //   if (reportTime >= starttimestamp && reportTime <= endtimestamp) {
          //     flag_timeCheck = true
          //   } else {
          //     flag_timeCheck = false
          //   }
          // }
          // checking division
          let flag_divisionCheck = true;
          if (divisions != "") {
            if (divisions.indexOf(",") != -1) {
              const divisionsList = divisions.split(",");
              if (divisionsList.indexOf(individualReportData["division"]) != -1) {
                flag_divisionCheck = true;
              } else {
                flag_divisionCheck = false;
              }
            } else {
              if (individualReportData["division"] == divisions) {
                flag_divisionCheck = true;
              }
              else {
                flag_divisionCheck = false;
              }
            }
          }
          // checking subdivision
          let flag_subdivisionCheck = true;
          if (subdivision != "") {
            if (individualReportData["subdivision"] == subdivision) {
              flag_subdivisionCheck = true;
            }
            else {
              flag_subdivisionCheck = false
            }
          }
          // checking consumerName
          let flag_consumerNameCheck = true;
          if (consumername != "") {
            if (individualReportData["consumerName"] == consumername) {
              flag_consumerNameCheck = true;
            }
            else {
              flag_consumerNameCheck = false;
            }
          }
          // checking consumerNumber
          let flag_consumerNumberCheck = true
          if (consumernumber != "") {
            if (individualReportData["consumerNumber"] == consumernumber) {
              flag_consumerNumberCheck = true
            }
            else {
              flag_consumerNumberCheck = false
            }
          }
          // checking createdBy
          let flag_createdByCheck = true
          if (createdby != "") {
            if (individualReportData["createdBy"] == createdby) {
              flag_createdByCheck = true;
            }
            else {
              flag_createdByCheck = false;
            }
          }
          if (flag_timeCheck == true && flag_divisionCheck == true && flag_subdivisionCheck == true && flag_consumerNameCheck == true && flag_consumerNumberCheck == true && flag_createdByCheck == true) {
            //individualReportData["createdByAgent"] = userData[individualReportData["createdBy"]]
            //individualReportData["id"] = key
            individualReportData.id = documentId;
            individualReportData.agentName = agentList[individualReportData.createdBy]["fullName"];
            individualReportData.agentEmail = agentList[individualReportData.createdBy]["email"];
            individualReportData.agentPhoneNumber = agentList[individualReportData.createdBy]["phoneNumber"];
            individualReportData.agentAadharNumber = agentList[individualReportData.createdBy]["aadharNumber"];
            delete individualReportData.createdBy;
            outputData.push(individualReportData)
          } else {

          }
          //////////////////////////
          //outputData.push(doc.data());
        });
        console.log("data process done seconds taken", ((Date.now() - startProcessingTime) / 1000));
        resolve(Service.successResponse({
          outputData
        }));
      }
    } catch (e) {
      console.log("here is the error", e);
      reject(Service.rejectResponse(
        e.message || 'Invalid input',
        e.status || 405,
      ));
    }
  },
);
const getAgentData = (db) => new Promise(async (resolve, reject) => {
  const userDBSnapshot = await db.collection('collection_users').where("userType", "==", "agent").get();
  userDBSnapshot.forEach((doc) => {
    data = doc.data();
    if (data["userType"] == "agent") {
      agentList[doc.id] = data;
    }
  });
  console.log("agentList", userDBSnapshot.docs.length);
  resolve();
});
module.exports = {
  getData
};
