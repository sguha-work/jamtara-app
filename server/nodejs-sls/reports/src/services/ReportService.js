const Service = require("./Service");
const AWS = require("aws-sdk");
const nodemailer = require('nodemailer');
const dbService = require("./DBService");
const ReportModel = require("../models/ReportModel");
const dbService2 = require("./DBService_v2");
const reportDBName = process.env.reportDBName;
const consumerDBName = process.env.consumerDBName;
const userDBName = process.env.userDBName;
const userAuthDBName = process.env.userAuthDBName;
const divisionDBName = process.env.divisionDBName;
const subDivisionDBName = process.env.subDivisionDBName;
const circleDBName = process.env.circleDBName;
const notificationDBName = process.env.notificationDBName;

const fetchReports = ({ reportId }) => new Promise(async (resolve, reject) => {
  console.log('report', reportId);
  let responseObj = {};
  try {
    responseObj.status = 200;
    let result;
    if (reportId == "all") {
      result = await dbService.find(ReportModel);
    } else {
      result = await dbService.query(`SELECT * FROM ${reportDBName} WHERE id='${reportId}';`);
    }
    responseObj.data = result;
    resolve(Service.successResponse(responseObj, responseObj.status));
  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

const fetchReportsConditionaly = ({ adminId, division, supervisorId, agentId, startTimeStamp, endTimeStamp, limit = 500, page = 0, orderBy = 'created_at', count = false }) => new Promise(async (resolve, reject) => {
  let responseObj = {};
  try {
    responseObj.status = 200;
    let result;
    let query = '';
    if (!startTimeStamp) {
      startTimeStamp = new Date("01/01/2020").toISOString();
    } else {
      startTimeStamp = new Date(parseInt(startTimeStamp)).toISOString();
    }
    if (!endTimeStamp) {
      endTimeStamp = new Date().toISOString();
    } else {
      endTimeStamp = new Date(parseInt(endTimeStamp)).toISOString();
    }
    if (count) {
      query = `SELECT count(id) 
      FROM ${reportDBName} 
      WHERE ${reportDBName}.created_at >= '${startTimeStamp}' AND ${reportDBName}.created_at <= '${endTimeStamp}'`;
    } else {
      query = `SELECT ${reportDBName}.id,
              ${reportDBName}.meter_number,
              ${reportDBName}.image_links,
              ${reportDBName}.consumer_id,
              ${reportDBName}.created_at,
              ${reportDBName}.updated_at,
              ${reportDBName}.created_by,
              ${reportDBName}.division_id,
              ${reportDBName}.sub_division_id,
              ${reportDBName}.sealing_page_number,
              ${reportDBName}.coordinates,
              ${consumerDBName}.aadhar_number,
              ${consumerDBName}.addr1,
              ${consumerDBName}.addr2,
              ${consumerDBName}.circle_id,
              ${circleDBName}.circle,
              ${consumerDBName}.consumer_number,
              ${consumerDBName}.consumer_type,
              ${consumerDBName}.load,
              ${consumerDBName}.meter_make,
              ${consumerDBName}.meter_status,
              ${consumerDBName}.mobile,
              ${consumerDBName}.name,
              ${consumerDBName}.tariff,
              ${consumerDBName}.supervisor_approval_status,
              ${divisionDBName}.division,
              ${subDivisionDBName}.sub_division,
              ${userDBName}.full_name AS agent_name
              FROM ${reportDBName} 
              INNER JOIN ${consumerDBName} ON ${reportDBName}.consumer_id=${consumerDBName}.id
              INNER JOIN ${circleDBName} ON ${circleDBName}.id=${consumerDBName}.circle_id 
              INNER JOIN ${divisionDBName} ON ${reportDBName}.division_id=${divisionDBName}.id 
              INNER JOIN ${subDivisionDBName} ON ${reportDBName}.sub_division_id=${subDivisionDBName}.id 
              INNER JOIN ${userDBName} ON ${reportDBName}.created_by=${userDBName}.user_id
              WHERE ${reportDBName}.created_at >= '${startTimeStamp}' AND ${reportDBName}.created_at <= '${endTimeStamp}'`;
    }
    if (agentId) {
      query += ` AND ${reportDBName}.created_by='${agentId}'`;
    }
    if (supervisorId) {
      // getting list of agent ids under the supervisor
      const agentSelectquery = `SELECT user_id FROM ${userDBName} WHERE user_type='agent' AND created_by_user_id='${supervisorId}'`;
      const result = await dbService.query(agentSelectquery);
      console.log('result', result);
      let idString = '';
      result.forEach((individualId) => {
        idString += `'${individualId["user_id"]}',`
      });
      // removing trailing comma if any
      if (idString[idString.length - 1] == ',') {
        idString = idString.slice(0, -1);
      }
      query += ` AND ${reportDBName}.created_by IN (${idString})`;
    }

    if (adminId) {
      const agentSelectquery = `SELECT ag.user_id FROM ${userDBName} AS ag
      INNER JOIN ${userDBName} AS su ON ag.created_by_user_id = su.user_id
      WHERE ag.user_type='agent' AND su.created_by_user_id='${adminId}';
      `;
      const result = await dbService.query(agentSelectquery);
      let idString = '';
      result.forEach((individualId) => {
        idString += `'${individualId["user_id"]}',`
      });
      // removing trailing comma if any
      if (idString[idString.length - 1] == ',') {
        idString = idString.slice(0, -1);
      }
      query += ` AND ${reportDBName}.created_by IN (${idString})`;
    }
    if (page) {
      query += ` ORDER BY ${orderBy} LIMIT ${limit} OFFSET ${((page - 1) * limit)};`
    } else {
      query += `;`;
    } console.log('query-->', query);
    result = await dbService.query(query);
    if (count) {
      result = result[0];
    } else {
      //result.forEach((individualReport) => {
      //individualReport["created_at"] = parseInt((new Date(individualReport["created_at"])).getTime());
      //});
    }
    responseObj.data = result;
    resolve(Service.successResponse(responseObj, responseObj.status));
  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

const fetchReportCountByAgent = ({ agentId }) => new Promise(async (resolve, reject) => {
  let responseObj = {};
  try {
    responseObj.status = 200;
    const result = await dbService.query(`SELECT COUNT(id) FROM ${reportDBName} WHERE created_by='${agentId}';`);
    responseObj.data = result;
    resolve(Service.successResponse(responseObj, responseObj.status));
  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

const fetchReportsByAgent = ({ agentId, limit = 500, page = 0, orderBy = 'created_at' }) => new Promise(async (resolve, reject) => {
  let responseObj = {};
  try {
    responseObj.status = 200;
    responseObj.data = {};
    const agentDetails = await dbService.query(`SELECT full_name, created_by_user_id FROM ${userDBName} WHERE user_id='${agentId}';`);
    const agentName = agentDetails[0]["full_name"];
    const supervisorId = agentDetails[0]["created_by_user_id"];
    const supervisorDetails = await dbService.query(`SELECT full_name FROM ${userDBName} WHERE user_id='${supervisorId}';`);
    const supervisorName = supervisorDetails[0]['full_name'];
    let query = `SELECT ${reportDBName}.id,
    ${reportDBName}.meter_number,
    ${reportDBName}.image_links,
    ${reportDBName}.consumer_id,
    ${reportDBName}.created_at,
    ${reportDBName}.updated_at,
    ${reportDBName}.created_by,
    ${reportDBName}.division_id,
    ${reportDBName}.sub_division_id,
    ${reportDBName}.sealing_page_number,
    ${reportDBName}.coordinates,
    ${consumerDBName}.aadhar_number,
    ${consumerDBName}.addr1,
    ${consumerDBName}.addr2,
    ${consumerDBName}.circle_id,
    ${consumerDBName}.consumer_number,
    ${consumerDBName}.consumer_type,
    ${consumerDBName}.load,
    ${consumerDBName}.meter_make,
    ${consumerDBName}.meter_status,
    ${consumerDBName}.mobile,
    ${consumerDBName}.name,
    ${consumerDBName}.tariff,
    ${consumerDBName}.supervisor_approval_status,
    ${divisionDBName}.division,
    ${subDivisionDBName}.sub_division
     FROM ${reportDBName} 
     INNER JOIN ${consumerDBName} ON ${reportDBName}.consumer_id=${consumerDBName}.id 
     INNER JOIN ${divisionDBName} ON ${reportDBName}.division_id=${divisionDBName}.id 
     INNER JOIN ${subDivisionDBName} ON ${reportDBName}.sub_division_id=${subDivisionDBName}.id 
     WHERE ${reportDBName}.created_by='${agentId}'`;
    if (page) {
      query += ` ORDER BY ${orderBy} LIMIT ${limit} OFFSET ${((page - 1) * limit)};`
    } else {
      query += `;`;
    }
    let result = await dbService.query(query);
    console.log(result);
    result.forEach((individualReport) => {
      individualReport["created_at"] = parseInt((new Date(individualReport["created_at"])).getTime());
      individualReport["agent_name"] = agentName;
      individualReport["supervisor_name"] = supervisorName;
    });
    responseObj.data = result;
    resolve(Service.successResponse(responseObj, responseObj.status));
  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

const createReport = ({ created_at, consumer_number, sealing_page_number=0, mobile, aadhar_number, meter_number, created_by, division_id, image_links, latitude, longitude, sub_division_id }) => new Promise(async (resolve, reject) => {
  let responseObj = {};
  try {
    responseObj.status = 201;
    console.log('input data-->', consumer_number, mobile, aadhar_number, meter_number, created_by, division_id, image_links, latitude, longitude, sub_division_id);
    const consumerData = await dbService.query(`SELECT * FROM ${consumerDBName} WHERE consumer_number='${consumer_number}'`);
    console.log('consumerData-->', consumerData);
    if (consumerData.length) {
      if (consumerData[0].meter_number == '' || consumerData[0].meter_number == null) {
        // making the notification entry
        // fetching the admin id of report creator who is going to have the notification
        const admin = await dbService.query(`select u1.created_by_user_id from ${userDBName} u1 inner join ${userDBName} u2 on u1.user_id = u2.created_by_user_id and u2.user_id ='${created_by}';`);
        const adminId = admin[0]['created_by_user_id'];
        const target_user = adminId;
        const notificationEntryQuery = `INSERT INTO ${notificationDBName} (
          for_user, 
          target_user,
          for_user_type, 
          created_by_user,
          created_on,
          status,
          noti_type,
          description
          ) VALUES (
            '${created_by}',
            '${target_user}',
            'agent',
            '${created_by}',
            ${created_at},
            'pending',
            'report_created',
            'Report created for consumer number ${consumer_number} with name ${consumerData[0]['name']}, aadhar number ${aadhar_number}'
            )`;
        
        // running notification query after the report is inserted
        // notification entry inserted
        const insertQuery = `INSERT INTO ${reportDBName} (created_by, created_at, division_id, image_links, coordinates, sub_division_id, meter_number, consumer_id,sealing_page_number)    VALUES ('${created_by}', '${new Date(created_at).toISOString()}', '${division_id}','${JSON.stringify(image_links)}', '${latitude},${longitude}', '${sub_division_id}', ${meter_number}, '${consumerData[0].id}',${sealing_page_number});`;
        console.log('insertQuery', insertQuery);
        await dbService.Iquery(insertQuery);
        
        console.log('notification query', notificationEntryQuery);
        await dbService.Iquery(notificationEntryQuery);
        // updating consumer table , adding meter number to consumer entry
        await dbService.query(`UPDATE ${consumerDBName} SET meter_number=${meter_number}, aadhar_number=${aadhar_number},mobile=${mobile} WHERE consumer_number='${consumer_number}';`);
        const report = await dbService.query(`SELECT * FROM ${reportDBName} WHERE consumer_id='${consumerData[0].id}'`);
        responseObj.data = report;
        responseObj.data.mobile = mobile;
        responseObj.data.aadhar_number = aadhar_number;
        resolve(Service.successResponse(responseObj, responseObj.status));
      } else {
        throw { message: `Meter already updated for the consumer` };
      }
    } else {
      throw { message: `No consumer data found` };
    }
  } catch (e) {console.log('Error --->', e);
    if (e.message.indexOf('duplicate key') !== -1) {console.log('e.message',e.message);
      e.message = `Report already exists with consumer number ${consumer_number}`;
      e.status = 409;
    }
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

const convertJSONToCSV = (jsonData) => {
  let csvString = "";
  let mainKeys;
  if (Array.isArray(jsonData) && jsonData.length) {
    const keys = Object.keys(jsonData[0]);
    const replacer = (_key, value) => value === null ? '' : ((Array.isArray(value)&&value.length>1)?value.join('||'):(Array.isArray(value)&&value.length==1)?value[0]:value);
    
    const processRow = row => keys.map(key => JSON.stringify(row[key], replacer)).join(',');
    csvString =  [ keys.join(','), ...jsonData.map(processRow) ].join('\r\n');
  }
  return csvString;
}

const sendMail = (presignedURL, mail_to = 'bentecmeterlagao@gmail.com') => new Promise(async (resolve, reject) => {
  try {

    const transporter = nodemailer.createTransport({
      service: 'Gmail',
      auth: {
        user: 'aritrikdas@gmail.com',
        pass: 'gydrasanyrffsxws'
      }
    });
    const mailOptions = {
      from: 'bentecmeterlagao@gmail.com',
      // for now sending mail to hardcoded email id, latter we need to move it to env variable
      to: 'bentecmeterlagao@gmail.com',//mail_to,
      bcc: "sguha1988.life@gmail.com,",
      subject: 'Sending Email with report data',
      text: `Download the csv file from the following url ${presignedURL}`
    };
    const mailResp = await transporter.sendMail(mailOptions);
    resolve({ success: true });
  } catch (error) {
    reject(error);
  }
})

const getBulkReportData = ({ downloadfile = false, filename = "", starttimestamp = 0, endtimestamp, divisionid, subdivisionid, consumerid, created_by_user_id, mail_to }) => new Promise(async (resolve, reject) => {
  let currentTimeStamp = Date.now();
  if (!endtimestamp) {
    endtimestamp = currentTimeStamp;
  }
  try {
    console.log('downloadfile-->', downloadfile);
    await dbService2.connect();
    if (downloadfile) {
      // invoking lambda to initiate s3 file preparation
      // preparing the json file and uploading it to presigned url by calling processFBData lambda
      // const paramsToInvokeLambda = {
      //   FunctionName: `bw-fb-management-${process.env.stage}-processFBData`, /* required */
      //   InvocationType: "Event",
      //   Payload: JSON.stringify({ starttimestamp, endtimestamp, divisions, subdivision, consumername, consumernumber, createdby })
      // };
      // const lambdaProvider = new AWS.Lambda();
      // const preferenceFromDB = await lambdaProvider.invoke(paramsToInvokeLambda).promise();
      if (mail_to) {
        // getting user email
        const userEmail = await dbService2.query(`SELECT email from user_auth WHERE user_id='${mail_to}'`);
        mail_to = userEmail[0]['email'];
      }
      if (!starttimestamp) {
        starttimestamp = new Date("01/01/2020").toISOString();
      } else {
        starttimestamp = new Date(parseInt(starttimestamp)).toISOString();
      }
      if (!endtimestamp) {
        endtimestamp = new Date().toISOString();
      } else {
        endtimestamp = new Date(parseInt(endtimestamp)).toISOString();
      }
      let query = `SELECT ${reportDBName}.id,
              ${reportDBName}.meter_number,
              ${reportDBName}.image_links,
              ${reportDBName}.consumer_id,
              ${reportDBName}.created_at,
              ${reportDBName}.updated_at,
              ${reportDBName}.created_by,
              ${reportDBName}.division_id,
              ${reportDBName}.sub_division_id,
              ${reportDBName}.sealing_page_number,
              ${reportDBName}.coordinates,
              ${consumerDBName}.aadhar_number,
              ${consumerDBName}.addr1,
              ${consumerDBName}.addr2,
              ${consumerDBName}.circle_id,
              ${circleDBName}.circle,
              ${consumerDBName}.consumer_number,
              ${consumerDBName}.consumer_type,
              ${consumerDBName}.load,
              ${consumerDBName}.meter_make,
              ${consumerDBName}.meter_status,
              ${consumerDBName}.mobile,
              ${consumerDBName}.name,
              ${consumerDBName}.tariff,
              ${consumerDBName}.supervisor_approval_status,
              ${divisionDBName}.division,
              ${subDivisionDBName}.sub_division,
              ${userDBName}.full_name AS agent_name,
              ${userAuthDBName}.email AS agent_email,
              ${userAuthDBName}.mobile AS agent_phone_number
              FROM ${reportDBName} 
              INNER JOIN ${consumerDBName} ON ${reportDBName}.consumer_id=${consumerDBName}.id
              INNER JOIN ${circleDBName} ON ${circleDBName}.id=${consumerDBName}.circle_id 
              INNER JOIN ${divisionDBName} ON ${reportDBName}.division_id=${divisionDBName}.id 
              INNER JOIN ${subDivisionDBName} ON ${reportDBName}.sub_division_id=${subDivisionDBName}.id 
              INNER JOIN ${userDBName} ON ${reportDBName}.created_by=${userDBName}.user_id
              INNER JOIN ${userAuthDBName} ON ${reportDBName}.created_by=${userAuthDBName}.user_id
              WHERE ${reportDBName}.created_at >= '${starttimestamp}' AND ${reportDBName}.created_at <= '${endtimestamp}'`;
      if (created_by_user_id) {
        query += ` AND ${reportDBName}.created_by='${created_by_user_id}'`;
      }
      if (divisionid) {
        query += ` AND ${reportDBName}.division_id='${divisionid}'`;
      }
      if (subdivisionid) {
        query += ` AND ${reportDBName}.sub_division_id='${subdivisionid}'`;
      }
      if (consumerid) {
        query += ` AND ${reportDBName}.consumer_id='${consumerid}'`;
      }
      console.log('query-->', query);
      let result = convertJSONToCSV(await dbService2.query(query));
      const client = new AWS.S3();
      client.config.update({
        accessKeyId: "AKIA5M2B6THZDQ5UPGMC",
        secretAccessKey: "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",
        region: process.env.AWS_REGION,
        signatureVersion: "v4",
      });
      const params = {
        Bucket: process.env.fileUploadBucket, // pass your bucket name
        Key: `test/report_${currentTimeStamp}.csv`, // file will be saved as test/contacts.csv
        Body: result,//JSON.stringify(data, null, 2)
        ContentType: 'application/csv'
      };
      const data = await client.upload(params).promise();
      console.log("data-->", data);

      await sendMail(data.Location, mail_to);
      resolve(Service.successResponse({
        success: true
      }));
    } else {
      console.log('came to else part');
    }
    // for now we are only implementing the download file section
    // else {
    //   if (!admin.apps.length) {
    //     admin.initializeApp({
    //       credential: admin.credential.cert(serviceAccount),
    //     });
    //   }
    //   // Initialize Firebase
    //   //const app = initializeApp(firebaseConfig);
    //   const db = getFirestore();
    //   const startFetchingTime = Date.now();
    //   console.log("fetching data ", startFetchingTime);
    //   let snapshot;
    //   if (starttimestamp != 0 && endtimestamp != currentTimeStamp) {
    //     console.log("here");
    //     snapshot = await db.collection('collection_reports')
    //       .where('createdOn', '>=', parseInt(starttimestamp))
    //       .where('createdOn', '<=', parseInt(endtimestamp))
    //       .get();
    //   } else {
    //     snapshot = await db.collection('collection_reports').get();
    //   }
    //   console.log("data fetch done seconds taken", ((Date.now() - startFetchingTime) / 1000));
    //   console.log("data length", snapshot.docs.length);
    //   await getAgentData(db);
    //   let outputData = [];
    //   // Print the ID && contents of each document
    //   const startProcessingTime = Date.now();
    //   snapshot.forEach(doc => {
    //     ///////////////////////////
    //     let individualReportData = doc.data();
    //     const documentId = doc.id;
    //     // checking start and end time
    //     let flag_timeCheck = true

    //     // if (starttimestamp != 0 && endtimestamp != currentTimeStamp) {
    //     //   let reportTime = individualReportData["createdOn"]
    //     //   if (reportTime >= starttimestamp && reportTime <= endtimestamp) {
    //     //     flag_timeCheck = true
    //     //   } else {
    //     //     flag_timeCheck = false
    //     //   }
    //     // }
    //     // checking division
    //     let flag_divisionCheck = true;
    //     if (divisions != "") {
    //       if (divisions.indexOf(",") != -1) {
    //         const divisionsList = divisions.split(",");
    //         if (divisionsList.indexOf(individualReportData["division"]) != -1) {
    //           flag_divisionCheck = true;
    //         } else {
    //           flag_divisionCheck = false;
    //         }
    //       } else {
    //         if (individualReportData["division"] == divisions) {
    //           flag_divisionCheck = true;
    //         }
    //         else {
    //           flag_divisionCheck = false;
    //         }
    //       }
    //     }
    //     // checking subdivision
    //     let flag_subdivisionCheck = true;
    //     if (subdivision != "") {
    //       if (individualReportData["subdivision"] == subdivision) {
    //         flag_subdivisionCheck = true;
    //       }
    //       else {
    //         flag_subdivisionCheck = false
    //       }
    //     }
    //     // checking consumerName
    //     let flag_consumerNameCheck = true;
    //     if (consumername != "") {
    //       if (individualReportData["consumerName"] == consumername) {
    //         flag_consumerNameCheck = true;
    //       }
    //       else {
    //         flag_consumerNameCheck = false;
    //       }
    //     }
    //     // checking consumerNumber
    //     let flag_consumerNumberCheck = true
    //     if (consumernumber != "") {
    //       if (individualReportData["consumerNumber"] == consumernumber) {
    //         flag_consumerNumberCheck = true
    //       }
    //       else {
    //         flag_consumerNumberCheck = false
    //       }
    //     }
    //     // checking createdBy
    //     let flag_createdByCheck = true
    //     if (createdby != "") {
    //       if (individualReportData["createdBy"] == createdby) {
    //         flag_createdByCheck = true;
    //       }
    //       else {
    //         flag_createdByCheck = false;
    //       }
    //     }
    //     if (flag_timeCheck == true && flag_divisionCheck == true && flag_subdivisionCheck == true && flag_consumerNameCheck == true && flag_consumerNumberCheck == true && flag_createdByCheck == true) {
    //       //individualReportData["createdByAgent"] = userData[individualReportData["createdBy"]]
    //       //individualReportData["id"] = key
    //       individualReportData.id = documentId;
    //       individualReportData.agentName = agentList[individualReportData.createdBy]["fullName"];
    //       individualReportData.agentEmail = agentList[individualReportData.createdBy]["email"];
    //       individualReportData.agentPhoneNumber = agentList[individualReportData.createdBy]["phoneNumber"];
    //       individualReportData.agentAadharNumber = agentList[individualReportData.createdBy]["aadharNumber"];
    //       delete individualReportData.createdBy;
    //       outputData.push(individualReportData)
    //     } else {

    //     }
    //     //////////////////////////
    //     //outputData.push(doc.data());
    //   });
    //   console.log("data process done seconds taken", ((Date.now() - startProcessingTime) / 1000));
    //   resolve(Service.successResponse({
    //     outputData
    //   }));
    // }
  } catch (e) {
    console.log("here is the error", e);
    reject(Service.rejectResponse(
      e.message || 'Invalid input',
      e.status || 405,
    ));
  } finally {
    dbService2.release();
  }
});

module.exports = {
  fetchReports,
  createReport,
  fetchReportCountByAgent,
  fetchReportsByAgent,
  fetchReportsConditionaly,
  getBulkReportData
};
