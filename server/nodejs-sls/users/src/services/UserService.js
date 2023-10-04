const Service = require("./Service");
const AWS = require("aws-sdk");
const dbService = require("./DBService");
const dbService2 = require("./DBService_v2");
const { v4: uuidv4 } = require('uuid');

const bcrypt = require('bcryptjs');
const saltRounds = 10;
const consumerDBName = process.env.consumerDBName;
const subDivisionDBName = process.env.subDivisionDBName;
const divisionDBName = process.env.divisionDBName;
const userDBName = process.env.userDBName;
const userAuthDBName = process.env.userAuthDBName;
const userSessionDBName = process.env.userSessionDBName;
const defaultPassword = process.env.defaultPassword;
const reportDBName = process.env.reportDBName;
const notificationDBName = process.env.notificationDBName;

const validate = ((type, parentId) => {
  type = type.toLowerCase();
  if (type != "all" && type != "admin" && type != "supervisor" && type != "agent" && type != "superadmin") {
    return false;
  }
  if (parentId != "nill" && parentId == "") {
    return false;
  }
  return true;
});

const validateUser = (email, mobile, aadhar_number) => {
  if (email.trim() == "") {
    return false;
  }
  if (isNaN(parseInt(mobile))) {
    return false;
  }
  if (isNaN(parseInt(aadhar_number))) {
    return false;
  }
  return true;
};

const fetchUsers = ({ type = "all", parentId = "nill", division_id, parent_type = '' }) => new Promise(async (resolve, reject) => {
  let responseObj = {};
  try {
    await dbService2.connect();
    responseObj.status = 200;
    responseObj.data = {};
    if (validate(type, parentId)) {
      let query = "";
      if (type == "all") {
        query = `SELECT * FROM ${userDBName} INNER JOIN ${userAuthDBName} ON ${userDBName}.user_id = ${userAuthDBName}.user_id;`;
      } else if (parent_type == 'super') {
        if (division_id) {
          query = `SELECT * FROM ${userDBName} INNER JOIN ${userAuthDBName} ON ${userDBName}.user_id = ${userAuthDBName}.user_id WHERE user_type='${type}' AND division_ids ? '${division_id}';`;
        } else {
          if (parentId == "nill" || (parentId != "nill" && type == 'admin')) {
            query = `SELECT * FROM ${userDBName} INNER JOIN ${userAuthDBName} ON ${userDBName}.user_id = ${userAuthDBName}.user_id WHERE user_type='${type}';`;
          } else {
            query = `SELECT * FROM ${userDBName} INNER JOIN ${userAuthDBName} ON ${userDBName}.user_id = ${userAuthDBName}.user_id WHERE user_type='${type}' AND created_by_user_id='${parentId}';`;
          }
        }
      } else {
        query = `SELECT * FROM ${userDBName}  INNER JOIN ${userAuthDBName} ON ${userDBName}.user_id = ${userAuthDBName}.user_id WHERE user_type='${type}'`;
        if (parentId != "nill") {
          // if (parent_type === 'super') {
          //   // requested for supervisor under a superAdmin so modifying the query as per requirement
          //   const adminIdListQuery = `SELECT user_id FROM ${userDBName} WHERE created_by_user_id='${parentId}'`;
          //   let uidList = await dbService.query(adminIdListQuery);
          //   uidList = uidList.map((item) => item.user_id);
          //   let idString = '';
          //   uidList.forEach((id) => {
          //     idString += `'${id}',`;
          //   });
          //   idString = idString.slice(0, -1);
          //   console.log('idString->', idString);
          //   query += ` AND created_by_user_id IN(${idString})`;
          // } else {
          query += ` AND created_by_user_id='${parentId}'`;
          //}
        }
        if (division_id) {
          query += ` AND division_ids ? '${division_id}'`;
        }
        query += ";";
      }
      console.log('final query->', query);
      let result = await dbService2.query(query);
      if (result.length) {
        if (type === 'agent') {
          // fetching report count of every agent
          // need to find a smart way
          const query = `SELECT created_by FROM reports`;
          // above query will return list of user_id s where user id will be repeated as per data entry in report table
          // so we need to count the number of repetation to determine the number of reports created by the agent
          let uidResult = await dbService2.query(query);
          uidResult = uidResult.map((id) => id.created_by);
          for (let index in result) {
            let counter = 0;
            uidResult.forEach((id) => {
              if (id == result[index]['user_id']) {
                counter += 1;
              }
            });
            result[index]['report_count'] = counter;// by default user_id will be present for 1 time
          }
        }
        let reportData = {};
        if (type === 'supervisor') {
          // creating report count
          const supervisorIdList = result.map((data) => data["user_id"]);
          let supervisorIdListString = '';
          supervisorIdList.forEach((id) => {
            supervisorIdListString += `'${id}',`;
          });
          supervisorIdListString = supervisorIdListString.slice(0, -1);
          const agentIdList = await dbService2.query(`SELECT user_id,created_by_user_id FROM ${userDBName} WHERE created_by_user_id IN (${supervisorIdListString})`);
          let agentObj = {};
          const ids = agentIdList.map((id) => {
            agentObj[id["user_id"]] = id["created_by_user_id"];
            return id["user_id"]
          });
          // agent object is like {<agentid 1>:<created by id 1>,<agentid 2>:<created by id 2>}
          let idString = '';
          ids.forEach((id) => {
            idString += `'${id}',`;
          });
          idString = idString.slice(0, -1);
          const reports = await dbService2.query(`SELECT reports.id,users.user_id FROM ${reportDBName} INNER JOIN ${userDBName} ON ${reportDBName}.created_by = ${userDBName}.user_id where ${reportDBName}.created_by IN(${idString})`);
          for (let index in ids) {
            const userId = ids[index];
            let count = 0;
            for (let index in reports) {
              if (reports[index]['user_id'] == userId) {
                count += 1;
              }
            }
            if (!reportData[agentObj[userId]]) {
              reportData[agentObj[userId]] = []
            }
            reportData[agentObj[userId]].push({
              "agent_id": userId,
              "report_count": count
            });
          }
        }
        result.forEach((data) => {
          if (data.mobile) {
            data.mobile = parseInt(data.mobile);
          }
          data['report'] = (reportData[data['user_id']]) ? reportData[data['user_id']] : null;
        });
        // getting division names for each user
        // need to find smart way to do this
        if (type !== 'admin') {
          let entireDivisionIdsList = [];
          for (let index in result) {
            const user = result[index];
            let divisionIds = user["division_ids"];
            entireDivisionIdsList.push(...divisionIds);
          }
          let divisionIdString = '';
          entireDivisionIdsList.forEach((divisionObj) => {
            if (divisionObj.trim() != '') {
              divisionIdString += `'${divisionObj}',`;
            }
          });
          divisionIdString = divisionIdString.slice(0, -1);
          let divisionOBJsFromDB = await dbService2.query(`SELECT id,division FROM ${divisionDBName} WHERE id IN (${divisionIdString})`);
          let divisionObjs = {};
          divisionOBJsFromDB.forEach((data) => {
            divisionObjs[data.id] = data.division;
          });
          for (let index in result) {
            result[index]['divisionObjs'] = [];
            for (let divisionIdIndex in result[index]['division_ids']) {
              result[index]['divisionObjs'].push({
                id: result[index]['division_ids'][divisionIdIndex],
                division: divisionObjs[result[index]['division_ids'][divisionIdIndex]]
              });
            }
          }
        } else {
          for (let index in result) {
            const user = result[index];
            let divisionIds = user["division_ids"];
            user.divisionObjs = [];
            let divisionIdString = '';
            divisionIds.forEach((divisionObj) => {
              if (divisionObj.trim() != '') {
                divisionIdString += `'${divisionObj}',`;
              }
            });
            divisionIdString = divisionIdString.slice(0, -1);
            let divisionObj = await dbService2.query(`SELECT id,division FROM ${divisionDBName} WHERE id IN (${divisionIdString})`);
            user.divisionObjs = divisionObj;
          }
        }
      }
      responseObj.data = result;
    } else {
      throw ({ message: "Input data is wrong" });
    }
    resolve(Service.successResponse(responseObj, responseObj.status));
  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  } finally {
    dbService2.release();
  }
});

const fetchNotifications = ({ target_user = 'admin', target_user_id = '' }) => new Promise(async (resolve, reject) => {
  let responseObj = {};
  try {
    responseObj.status = 200;
    responseObj.data = {};
    const divisionNameList = await dbService.query(`SELECT id, division as name FROM ${divisionDBName};`);
    // target_user can be admin or superadmin
    let queryToGetNotification = `SELECT 
    nd.id,
    nd.for_user_type,
    nd.for_user,
    nd.created_by_user,
    nd.viewed,
    nd.target_user,
    nd.created_on,
    nd.status,
    nd.noti_type,
    nd.description,
    ud.approved_by_user_id,
    ud.approved_on,
    ud.division_ids AS for_user_divisionids,
    ud.full_name AS for_user_name,
    ud2.full_name AS created_by_user_name
    FROM ${notificationDBName} AS nd 
    INNER JOIN ${userDBName} AS ud ON nd.for_user = ud.user_id
    INNER JOIN ${userDBName} AS ud2 ON nd.created_by_user = ud2.user_id 
    `;
    if (target_user_id != '' && target_user_id != 'null') {
      queryToGetNotification += `WHERE nd.target_user='${target_user_id}' `;
    } else {
      queryToGetNotification += `WHERE nd.target_user='${target_user}' `;
    }
    queryToGetNotification += `ORDER BY created_on DESC`;
    console.log('queryToGetNotification->', queryToGetNotification);
    let result = await dbService.query(queryToGetNotification);
    // populating division names
    for (data of result) {
      if(data['noti_type']==='consumer_created') {
        data['approved_by_user_id'] = '';
        data['approved_on'] = '';
      }
      if (data['approved_by_user_id'] === 'undefined') {
        data['approved_by_user_id'] = '';
        data['approved_on'] = '';
      }
      const divisionIds = data['for_user_divisionids'];
      console.log('divisionIds->', divisionIds);
      data['for_user_division'] = [];

      for (divisionId of divisionIds) {
        let divisionName;
        divisionNameList.forEach((dvObj) => {
          if (dvObj.id == divisionId) {
            divisionName = dvObj.name;
          }
        });
        console.log('division name', divisionName);
        data['for_user_division'].push(divisionName);
      }
    }
    responseObj.data = result;
    resolve(Service.successResponse(responseObj, responseObj.status));
  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

const createUser = ({ email = '', mobile = 0, aadhar_number, approved_by_user_id, approved_on = Date.now(), area = '', city = '', pin = 0, state = '', created_by_user_id, created_on = Date.now(), dob = '', division_ids = [], full_name = '', image_path = '', pan = '', user_type, password }) => new Promise(async (resolve, reject) => {
  let responseObj = {};
  try {
    responseObj.status = 201;
    responseObj.data = {};
    if (aadhar_number === '') {
      aadhar_number = 0;
    }
    if (validateUser(email, mobile, aadhar_number)) {
      const userId = uuidv4();
      let passwordHash;
      if (password) {
        passwordHash = await bcrypt.hash(password, saltRounds);
      } else {
        passwordHash = await bcrypt.hash(defaultPassword, saltRounds);
      }
      /////////////////////////////////////////////////////////////
      const userAuthQuery = `INSERT INTO ${userAuthDBName} (
        user_id, 
        password, 
        email, 
        mobile
        ) VALUES (
          '${userId}',
          '${passwordHash}',
          '${email}',
          ${parseInt(mobile)}
          )`;
      const userDBQuery = `INSERT INTO ${userDBName} (
                user_id,
                aadhar_number,
                approved_by_user_id,
                approved_on,
                area,
                city,
                pin,
                state,
                created_by_user_id,
                created_on,
                dob,
                division_ids,
                full_name,
                image_path,
                pan,
                user_type
            ) VALUES (
                '${userId}',
                ${parseInt(aadhar_number)},
                '${approved_by_user_id}',
                ${approved_on},
                '${area}',
                '${city}',
                ${parseInt(pin)},
                '${state}',
                '${created_by_user_id}',
                ${created_on},
                '${dob}',
                '${JSON.stringify(division_ids)}',
                '${full_name}',
                '${image_path}',
                '${pan}',
                '${user_type}'                
            )`;
      console.log('user auth query', userAuthQuery);
      console.log('user db query', userDBQuery);
      await dbService.query(userAuthQuery);
      console.log('Auth insertion done');
      await dbService.query(userDBQuery);
      console.log('db insertion done');
      console.log(userDBQuery);
      // making the notification entry
      // notification entry will be created only if the user is not approved
      // for bulk upload user is already approved so no notification will be created
      if (!approved_by_user_id) {
        // incase of user type 'agent' the admin id of the supervisor who created the aget will be stored to 
        // notification db as target user
        let target_user;
        if (user_type == 'agent') {
          const admin = await dbService.query(`SELECT created_by_user_id FROM ${userDBName} WHERE user_id='${created_by_user_id}';`);
          const adminId = admin[0]['created_by_user_id'];
          target_user = adminId;
        } else {
          if (user_type == 'supervisor') {
            target_user = 'superadmin';
          }
        }
        // status will be pending, approved, rejected
        const notificationEntryQuery = `INSERT INTO ${notificationDBName} (
        for_user, 
        target_user,
        for_user_type, 
        created_by_user,
        created_on,
        status
        ) VALUES (
          '${userId}',
          '${target_user}',
          '${user_type}',
          '${created_by_user_id}',
          ${created_on},
          'pending'
          )`;
        console.log('notification query', notificationEntryQuery);
        await dbService.query(notificationEntryQuery);
        console.log('inserted notification in query')
      }
      responseObj.data = {
        success: true
      };
    } else {
      throw ({ message: "Validation error occured" });
    }
    resolve(Service.successResponse(responseObj, responseObj.status));
  } catch (e) {
    console.log("error->", e.message);
    if (e.message.indexOf('duplicate key') !== -1) {
      e.message = `User already exists with mobile number ${mobile}`;
      e.status = 409;
    }
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

const updateUser = ({ user_id, password, aadhar_number, approved_by_user_id, approved_on = Date.now(), area, city, pin, state, dob, division_ids = [], full_name, image_path, pan }) => new Promise(async (resolve, reject) => {
  let responseObj = {};
  try {
    responseObj.status = 201;
    responseObj.data = {};
    const userId = uuidv4();
    const passwordHash = await bcrypt.hash(defaultPassword, saltRounds);
    let result;
    /////////////////////////////////////////////////////////////
    let updateQuery = `UPDATE ${userDBName} SET `;
    if (aadhar_number) {
      updateQuery += `aadhar_number=${aadhar_number}`;
    }
    if (approved_by_user_id) {
      updateQuery += `approved_by_user_id='${approved_by_user_id}',`;
      // marking the notification as viewd
      const updateNotiQuery = `UPDATE ${notificationDBName} SET viewed=true WHERE for_user='${user_id}'`;
      console.log('updateNotiQuery->', updateNotiQuery);
      await dbService.query(updateNotiQuery);
    }
    if (approved_on) {
      updateQuery += `approved_on='${approved_on}',`;
    }
    if (area) {
      updateQuery += `area='${area}',`;
    }
    if (city) {
      updateQuery += `city='${city}',`;
    }
    if (pin) {
      updateQuery += `pin=${pin},`;
    }
    if (state) {
      updateQuery += `state='${state}',`;
    }
    if (dob) {
      updateQuery += `dob='${dob}',`;
    }
    if (division_ids && division_ids.length) {
      updateQuery += `division_ids='${JSON.stringify(division_ids)}',`;
    }
    if (full_name) {
      updateQuery += `full_name='${full_name}',`;
    }
    if (image_path) {
      updateQuery += `image_path='${image_path}',`;
    }
    if (pan) {
      updateQuery += `pan='${pan}',`;
    }
    if (updateQuery[updateQuery.length - 1] == ',') {
      // this section will be executed if atleast one field updated in 'users' table
      updateQuery = updateQuery.slice(0, -1);
      updateQuery += ` WHERE user_id='${user_id}';`;
      console.log('update query-->', updateQuery);
      result = await dbService.query(updateQuery);
    }
    if (password) {
      // if password fiedl changed, updating the auth table also
      const passwordHash = await bcrypt.hash(password, saltRounds);
      updateQuery = `UPDATE ${userAuthDBName} SET password='${passwordHash}' WHERE user_id='${user_id}'`;
      result = await dbService.query(updateQuery);
    }

    const updatedData = await dbService.query(`SELECT * FROM ${userDBName} WHERE user_id='${user_id}'`);
    console.log('result', updatedData);
    responseObj.data = updatedData;
    responseObj.data = {
      success: true
    };

    resolve(Service.successResponse(responseObj, responseObj.status));
  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

const fetchUserDetails = ({ user_id }) => new Promise(async (resolve, reject) => {
  let responseObj = {};
  try {
    responseObj.status = 200;
    responseObj.data = {};
    const result = await dbService.query(`SELECT * FROM ${userDBName} INNER JOIN ${userAuthDBName} ON ${userAuthDBName}.user_id=${userDBName}.user_id WHERE ${userDBName}.user_id='${user_id}'`);
    if (result.length) {
      // getting division names
      let divisionIdString = '';
      result[0]['division_ids'].forEach((divisionObj) => {
        divisionIdString += `'${divisionObj}',`;
      });
      divisionIdString = divisionIdString.slice(0, -1);
      const query = `SELECT id, division AS name FROM ${divisionDBName} WHERE id IN (${divisionIdString})`;
      const divisionObjs = await dbService.query(query);
      result[0].mobile = parseInt(result[0].mobile);
      responseObj.data = result[0];
      responseObj.data.divisionObjs = divisionObjs;
      resolve(Service.successResponse(responseObj, responseObj.status));
    } else {
      throw ({ message: "User not found" });
    }
  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

const deleteUser = ({ user_id }) => new Promise(async (resolve, reject) => {
  let responseObj = {};
  try {
    responseObj.status = 203;
    responseObj.data = {};
    const result = await dbService.query(`SELECT * FROM ${userDBName} WHERE user_id='${user_id}'`);
    if (result.length) {
      // user found deleting

      //deleting from auth table
      await dbService.query(`DELETE FROM ${userAuthDBName} WHERE user_id='${user_id}';`);
      // deleting from user table
      await dbService.query(`DELETE FROM ${userDBName} WHERE user_id='${user_id}';`);
    } else {
      throw ({ message: "User not found in database", status: 404 })
    }
    responseObj.data = { success: true };
    resolve(Service.successResponse(responseObj, responseObj.status));
  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

const updateNotification = ({ id, updated_by_user_id, updated_on = Date.now(), status = 'pending' }) => new Promise(async (resolve, reject) => {
  try {
    let responseObj = {};
    responseObj.status = 201;
    responseObj.data = {};
    if (status === 'approved') {
      // updating user table, marking the user as approved
      const notificationData = await dbService.query(`SELECT for_user from ${notificationDBName} WHERE id='${id}'`);
      const userId = notificationData[0]["for_user"];
      await dbService.query(`UPDATE ${userDBName} SET approved_by_user_id='${updated_by_user_id}', approved_on=${updated_on} WHERE user_id='${userId}';`);
    }
    const updateNotiQuery = `UPDATE ${notificationDBName} SET status='${status}', updated_on=${updated_on}, viewed=true WHERE id='${id}';`;
    await dbService.query(updateNotiQuery);
    resolve(Service.successResponse(responseObj, responseObj.status));
  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

const fetchAllUsersDivisionWise = () => new Promise(async (resolve, reject) => {
  try {
    let responseObj = {};
    responseObj.status = 201;
    responseObj.data = {};
    let query = `SELECT u.user_id, ua.mobile as mobile_number, ua.email,u.full_name as name,u.user_type as type,u.aadhar_number, u.division_ids FROM "${userDBName}" u INNER JOIN "${userAuthDBName}" ua ON u.user_id = ua.user_id WHERE user_type='admin';`;
    console.log('query', query);
    await dbService2.connect();
    let adminData = await dbService2.query(query);
    query = `SELECT * FROM ${divisionDBName}`;
    const divisionData = await dbService2.query(query);
    for (let admin of adminData) {
      let divisionIds = admin.division_ids;
      let divisionObjs = [];
      divisionIds.forEach((divisionId) => {
        let divisionName = "";
        divisionData.forEach((divisionObj) => {
          if (divisionObj.id === divisionId) {
            divisionName = divisionObj.division;
          }
        });
        divisionObjs.push(divisionName);
      });
      admin.divisions = divisionObjs;
      delete admin.division_ids;

      // taking supervisors under admin
      query = `SELECT u.user_id, ua.mobile as mobile_number, ua.email,u.full_name as name,u.user_type as type,u.aadhar_number FROM "${userDBName}" u INNER JOIN "${userAuthDBName}" ua ON u.user_id = ua.user_id WHERE u.user_type='supervisor' AND created_by_user_id='${admin.user_id}';`;
      console.log(query);
      const supervisors = await dbService2.query(query);
      for (let supervisor of supervisors) {
        query = `SELECT ua.mobile as mobile_number, ua.email,u.full_name as name,u.user_type as type,u.aadhar_number FROM "${userDBName}" u INNER JOIN "${userAuthDBName}" ua ON u.user_id = ua.user_id WHERE u.user_type='agent' AND created_by_user_id='${supervisor.user_id}';`;
        supervisor.agents = await dbService2.query(query);
        delete supervisor.user_id;
      }
      admin.supervisors = supervisors;
      delete admin.user_id;
    }
    responseObj.data = adminData;
    resolve(Service.successResponse(responseObj, responseObj.status));
  } catch (error) {
    console.log(error);
    reject(
      Service.rejectResponse(error.message || "Unknown error", error.status || 405)
    );
  } finally {
    dbService2.release();
  }
});

const updateUserPassword = (user_id, password = 'User@123') => new Promise(async (resolve, reject) => {
  try {console.log('update password called')
    let responseObj = {};
    responseObj.status = 201;
    responseObj.data = {};
    const passwordHash = await bcrypt.hash(password, saltRounds);
    updateQuery = `UPDATE ${userAuthDBName} SET password='${passwordHash}' WHERE user_id='${user_id}'`;
    //let result = await dbService.query(updateQuery);
    resolve(Service.successResponse(responseObj, responseObj.status));

  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

module.exports = {
  fetchUsers,
  createUser,
  fetchUserDetails,
  updateUser,
  deleteUser,
  fetchNotifications,
  updateNotification,
  fetchAllUsersDivisionWise,
  updateUserPassword
};
