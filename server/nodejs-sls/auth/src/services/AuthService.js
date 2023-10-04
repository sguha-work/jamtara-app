const Service = require("./Service");
const AWS = require("aws-sdk");
const dbService = require("./DBService");
const bcrypt = require('bcryptjs');
const saltRounds = parseInt(process.env.saltRounds);

const consumerDBName = process.env.consumerDBName;
const subDivisionDBName = process.env.subDivisionDBName;
const divisionDBName = process.env.divisionDBName;
const userDBName = process.env.userDBName;
const userAuthDBName = process.env.userAuthDBName;
const userSessionDBName = process.env.userSessionDBName;

const validate = (mobile, password) => {
  return mobile && password && mobile.toString().trim() != "" && password.trim() != '' && !isNaN(parseInt(mobile));
}

const login = ({ mobile, password }) => new Promise(async (resolve, reject) => {
  let responseObj = {};
  try {
    responseObj.status = 201;
    responseObj.data = {};
    if (validate(mobile, password)) {
      const userDataFromDB = await dbService.query(`SELECT * FROM ${userAuthDBName} INNER JOIN ${userDBName} ON ${userAuthDBName}.user_id=${userDBName}.user_id  WHERE ${userAuthDBName}.mobile=${mobile};`);
      console.log('userDataFromDB-->', userDataFromDB);
      if (userDataFromDB.length) {
        if(userDataFromDB[0]['user_type']==='supervisor' ||userDataFromDB[0]['user_type']==='agent') {
          if(!userDataFromDB[0]['approved_by_user_id']||userDataFromDB[0]['approved_by_user_id']===''||userDataFromDB[0]['approved_by_user_id']==='undefined') {
            throw ({ message: "User is not approved yet so can't login", status: 401 });    
          }
        }
        const passwordHashFromDB = userDataFromDB[0]["password"];
        const match = await bcrypt.compare(password.trim(), passwordHashFromDB);
        if (match) {
          // making session entry
          dbService.query(`INSERT INTO ${userSessionDBName} (user_id, login_time) VALUES ('${userDataFromDB[0]['user_id']}', ${Date.now()});`)
          const userData = userDataFromDB[0];
          responseObj.data = userData;
          responseObj.data.success = true;
          responseObj.data.mobile = mobile;
          // enterring division names
          let divisionIdString = '';
          userData['division_ids'].forEach((divisionObj) => {
            if (divisionObj.trim() != '') {
              divisionIdString += `'${divisionObj}',`;
            }
          });
          divisionIdString = divisionIdString.slice(0, -1);
          const query = `SELECT id, division FROM ${divisionDBName} WHERE id IN (${divisionIdString})`;
          console.log('query', query)
          const divisionObjs = await dbService.query(query);
          responseObj.data.divisionObjs = divisionObjs;

        } else {
          throw ({ message: "User id and or password is wrong", status: 403 });
        }
      } else {
        throw ({ message: "User id and or password is wrong", status: 403 });
      }
    } else {
      throw ({ message: "User id and or password is invalid", status: 403 });
    }
    resolve(Service.successResponse(responseObj, responseObj.status));
  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

const changePassword = ({ userId, oldPassword, newPassword }) => new Promise(async (resolve, reject) => {
  let responseObj = {};
  try {
    responseObj.status = 201;
    responseObj.data = {};
    const userDataFromDB = await dbService.query(`SELECT * FROM ${userAuthDBName} WHERE user_id='${userId}';`);
    if (userDataFromDB.length) {
      const passwordHashFromDB = userDataFromDB[0]["password"];
      const match = await bcrypt.compare(oldPassword.trim(), passwordHashFromDB);
      console.log('matched ', match);
      if (match) {
        // old password matched, updating new password to db
        const passwordHash = await bcrypt.hash(newPassword, saltRounds);
        const query = `UPDATE ${userAuthDBName} SET password='${passwordHash}' WHERE user_id='${userId}'`;
        await dbService.query(query);
      } else {
        throw ({ message: "User id and or password is wrong", status: 403 });
      }
    } else {
      throw ({ message: "User id and or password is wrong", status: 403 });
    }
    resolve(Service.successResponse(responseObj, responseObj.status));
  } catch (e) {
    reject(
      Service.rejectResponse(e.message || "Unknown error", e.status || 405)
    );
  }
});

module.exports = {
  login,
  changePassword
};
