const Service = require("./Service");
const AWS = require("aws-sdk");
const dbService = require("./DBService");
const consumerDBName = process.env.consumerDBName;
const subDivisionDBName = process.env.subDivisionDBName;
const divisionDBName = process.env.divisionDBName;

const fetchConsumers = ({ sub_division_id, division_id, limit = 500, page = 1, orderBy = 'name' }) => new Promise(async (resolve, reject) => {
  let responseObj = {};
  try {
    responseObj.status = 200;
    let result;
    let totalNumberOfData;
    if (sub_division_id == 'all') {
      result = await dbService.query(`SELECT * FROM ${consumerDBName};`);
    } else {
      // checking if subdivision is valid or not
      // if not valid then the subdivision id will be treted as divisionid
      let query;
      let totalCountQuery;
      if (sub_division_id) {
        query = `SELECT * FROM ${consumerDBName} WHERE meter_number IS NULL AND sub_division_id='${sub_division_id}' ORDER BY ${orderBy}`;
        totalCountQuery = `SELECT COUNT(id) FROM ${consumerDBName} WHERE sub_division_id='${sub_division_id}'`;
      } else if (division_id) {
        query = `SELECT * FROM ${consumerDBName} WHERE meter_number IS NULL AND division_id='${division_id}' ORDER BY ${orderBy}`;
        totalCountQuery = `SELECT COUNT(id) FROM ${consumerDBName} WHERE division_id='${division_id}'`;
      } else {
        throw { message: `Please provide division or subdivision id` };
      }
      query += ` LIMIT ${limit} OFFSET ${((page - 1) * limit)};`;
      result = await dbService.query(query);
      totalNumberOfData = await dbService.query(totalCountQuery);
    }
    // manually modifying data as per request
    result.forEach((individualConsumers) => {
      individualConsumers['aadhar'] = (individualConsumers['aadhar_number'] == null) ? 0 : individualConsumers['aadhar_number'];
      delete individualConsumers['aadhar_number'];
      if (!individualConsumers['mobile'] || individualConsumers['mobile'] == null) {
        individualConsumers['mobile'] = 0;
      } else {
        individualConsumers['mobile'] = parseInt(individualConsumers['mobile']);
      }
      if (!individualConsumers['meter_number'] || individualConsumers['meter_number'] == null) {
        individualConsumers['meter_number'] = '';
      }
      individualConsumers['load'] = isNaN(parseInt(individualConsumers['load'])) ? 0 : parseInt(individualConsumers['load']);
    });
    responseObj.consumers = result;
    responseObj.totalRows = parseInt(totalNumberOfData[0].count);
    responseObj.page = {
      limit: limit,
      page: page
    };
    resolve(Service.successResponse(responseObj, responseObj.status));
  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});
const sanitize = (value) => {
  if (typeof value === 'undefined') {
    value = null;
  }
  return value;
};
const createConsumer = ({ aadhar_number, addr1, addr2, circle_id, consumer_number, consumer_type, division_id, load, meter_make, meter_number, meter_status, mobile, name, sub_division_id, tariff, supervisor_approval_status, created_by }) => new Promise(async (resolve, reject) => {
  let responseObj = {};
  try {
    responseObj.status = 201;
    console.log('input data-->', aadhar_number, addr1, addr2, circle_id, consumer_number, consumer_type, division_id, load, meter_make, meter_number, meter_status, mobile, name, sub_division_id, tariff, supervisor_approval_status);
    const consumerData = await dbService.query(`SELECT consumer_number, name FROM ${consumerDBName} WHERE consumer_number='${consumer_number}'`);
    console.log('consumerData-->', consumerData);
    if (consumerData.length) {
      throw { message: `Consumer already registered` };
    } else {
      const query = `INSERT INTO ${consumerDBName} (aadhar_number,addr1,addr2,circle_id,consumer_number,consumer_type,division_id,load,meter_make,meter_status,mobile,name,sub_division_id,tariff,supervisor_approval_status, created_by)    VALUES (${sanitize(aadhar_number)},'${sanitize(addr1)}','${sanitize(addr2)}','${sanitize(circle_id)}','${sanitize(consumer_number)}','${sanitize(consumer_type)}','${sanitize(division_id)}',${sanitize(load)},'${sanitize(meter_make)}','${sanitize(meter_status)}',${sanitize(mobile)},'${sanitize(name)}','${sanitize(sub_division_id)}','${sanitize(tariff)}','${sanitize(supervisor_approval_status)}','${sanitize(created_by)}');`
      console.log('query-->', query);
      await dbService.query(query);
      const result = await dbService.query(`SELECT * FROM ${consumerDBName} WHERE consumer_number='${consumer_number}'`);
      responseObj.data = result;
      // making notification entry
      let notificationEntryQuery;
      const supervisorIds = await dbService.query(`SELECT user_id from users WHERE division_ids  @> '["${division_id}"]';`);
      notificationEntryQuery = `INSERT INTO notifications (
        for_user, 
        target_user,
        for_user_type, 
        created_by_user,
        created_on,
        status,
        noti_type,
        description
        ) VALUES `;
      supervisorIds.forEach((id) => {
        notificationEntryQuery += `(
          '${created_by}',
          '${id['user_id']}',
          'supervisor',
          '${created_by}',
          ${Date.now()},
          'pending',
          'consumer_created',
          'Consumer created consumer number ${consumer_number} with name ${name}, aadhar number ${aadhar_number}, id |${result[0]['id']}|'
          ),`;
      });
      notificationEntryQuery = notificationEntryQuery.slice(0, -1);
      notificationEntryQuery += ";";
      await dbService.query(notificationEntryQuery);

      resolve(Service.successResponse(responseObj, responseObj.status));
    }
  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

const updateConsumer = ({ id, aadhar_number, addr1, addr2, circle_id, consumer_number, consumer_type, division_id, load, meter_make, meter_number, meter_status, mobile, name, sub_division_id, tariff, supervisor_approval_status, approved_by_user_id }) => new Promise(async (resolve, reject) => {
  let responseObj = {};
  try {
    responseObj.status = 201;
    console.log('input data-->', aadhar_number, addr1, addr2, circle_id, consumer_number, consumer_type, division_id, load, meter_make, meter_number, meter_status, mobile, name, sub_division_id, tariff, supervisor_approval_status);
    const consumerData = await dbService.query(`SELECT consumer_number, name FROM ${consumerDBName} WHERE id='${id}'`);
    console.log('consumerData-->', consumerData);
    if (consumerData.length) {
      console.log('executing here');
      let updateQuery = `UPDATE ${consumerDBName} SET `;
      if (aadhar_number) {
        updateQuery += `aadhar_number=${aadhar_number}`;
      }
      if (addr1) {
        updateQuery += `addr1='${addr1}',`;
      }
      if (addr2) {
        updateQuery += `addr2='${addr2}',`;
      }
      if (circle_id) {
        updateQuery += `circle_id='${circle_id}',`;
      }
      if (consumer_number) {
        updateQuery += `consumer_number='${consumer_number}',`;
      }
      if (consumer_type) {
        updateQuery += `consumer_type='${consumer_type}',`;
      }
      if (division_id) {
        updateQuery += `division_id='${division_id}',`;
      }
      if (load) {
        updateQuery += `load='${load}',`;
      }
      if (meter_make) {
        updateQuery += `meter_make='${meter_make}',`;
      }
      if (meter_number) {
        updateQuery += `meter_number='${meter_number}',`;
      }
      if (meter_status) {
        updateQuery += `meter_status='${meter_status}',`;
      }
      if (mobile) {
        updateQuery += `mobile=${mobile},`;
      }
      if (name) {
        updateQuery += `name='${name}',`;
      }
      if (sub_division_id) {
        updateQuery += `sub_division_id='${sub_division_id}',`;
      }
      if (tariff) {
        updateQuery += `tariff='${tariff}',`;
      }
      if (supervisor_approval_status) {
        updateQuery += `supervisor_approval_status='${supervisor_approval_status}', approved_by_user_id='${approved_by_user_id}',`;
        // updating associeted notification status if any
        let status ;
        if(supervisor_approval_status === 'Approved') {
          status = 'approved';
        } else {
          status = 'rejected';
        }
        const notiUpdatequery = `UPDATE notifications SET viewed=true, status='${status}' WHERE noti_type='consumer_created' AND description LIKE '%${id}%';`;
        dbService.query(notiUpdatequery);
      }
      if (updateQuery[updateQuery.length - 1] == ',') {
        updateQuery = updateQuery.slice(0, -1);
      }
      updateQuery += ` WHERE id='${id}';`;
      console.log('update query-->', updateQuery);
      const result = await dbService.query(updateQuery);
      const updatedData = await dbService.query(`SELECT * FROM ${consumerDBName} WHERE id='${id}'`);
      console.log('result', updatedData);
      responseObj.data = updatedData;
      resolve(Service.successResponse(responseObj, responseObj.status));
    } else {
      throw { message: `No consumer data found` };
    }
  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

module.exports = {
  fetchConsumers,
  createConsumer,
  updateConsumer
};
