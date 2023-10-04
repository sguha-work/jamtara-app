var mongoose = require("mongoose");
const defaultConnectionString = (DBName = 'bwAuctions') => new Promise(async (resolve, reject) => {
  try {
    const connectionURL = `mongodb+srv://${process.env.Mongo_Cluster_User}:${process.env.Mongo_Cluster_Password}@${process.env.Mongo_Cluster_URL}/${DBName}?retryWrites=true&w=majority`;
    console.log("connectionURL >> ", connectionURL);
    const dbConn = await mongoose.connect(connectionURL, { useNewUrlParser: true, }); // await on a step makes process to wait until it's done/ err'd out.
    console.log("DBconn", mongoose.connection.readyState);
    resolve(dbConn);
  } catch (error) {
    console.log("Mongo Connection Err ", error);
    reject(error);
  }

})

const save = (dataModel, dbName) =>
  new Promise(async (resolve, reject) => {
    if (
      typeof dataModel.save === "undefined" ||
      typeof dataModel.save !== "function"
    ) {
      reject({
        message: "Not a valid data model",
      });
    } else {
      try {
        console.log("dataModel >>", dataModel);
        let dbResp = await dataModel.save();
        console.log("Save response >>> ", dbResp);
        resolve(dbResp);
      } catch (err) {
        console.log("Save err", err.toString());
        reject({
          message: err.message,
          status: err.code === 11000 ? 409 : 500,
        });
      }
    }
  });

const find = (dataModel, query, projection, sort = {}, limit = 20, currentPage = 0, DBName = "bwAuctions") => new Promise(async (resolve, reject) => {
  if (
    typeof dataModel.find === "undefined" ||
    typeof dataModel.find !== "function"
  ) {
    reject({
      message: "Not a valid data model",
    });
  } else {
    let db;

    try {
      await mongoose.connect(defaultConnectionString(DBName), { useNewUrlParser: true }); // await on a step makes process to wait until it's done/ err'd out.
      db = mongoose.connection;
      projection = projection || {};
      const skip = limit * currentPage;
      const dbResp = await dataModel.find(query).select(projection).sort(sort).skip(skip).limit(limit);
      resolve(dbResp);
    } catch (error) {
      console.log(error);
      reject({ message: error.message, status: 500 });
    } finally {
      db.close();
    }
  }
});

const findWithCondition = (dataModel, query, limit = 10, sort = "createdAt", order = "desc", page = 1, DBName) => {
  return new Promise(async (resolve, reject) => {
    if (
      typeof dataModel.find === "undefined" ||
      typeof dataModel.find !== "function"
    ) {
      reject({
        message: "Not a valid data model",
      });
    } else {
      let db;
      try {
        await mongoose.connect(defaultConnectionString(DBName), { useNewUrlParser: true }); // await on a step makes process to wait until it's done/ err'd out.
        db = mongoose.connection;
        let sortObj = {};
        sortObj[sort] = order;
        page = page - 1;
        let docs = await dataModel.find(query).sort(sortObj).limit(limit).skip(limit * page);
        resolve(docs);
      } catch (err) {
        console.log("DB err", err.toString());
        reject({
          message: err.message,
          status: err.code === 11000 ? 409 : 500,
        });
      } finally {
        db.close();
      }
    }
  });
};


const findById = (dataModel, id, projection, DBName) => new Promise(async (resolve, reject) => {

  if (!dataModel.findById) {
    reject({
      message: "Not a valid data model",
    });
  } else {
    try {
      const dbResp = await dataModel.findById(id).select(projection);
      console.log("dbResp >>> ", dbResp);
      resolve(dbResp);
      // const returnData = (dbResp && Object.entries(dbResp).length) ? dbResp.toJSON() : dbResp;
      // resolve(returnData);
    } catch (error) {
      console.log(error);
      reject({ message: error.message, status: 500 });
    }
  }
});

const findByIdAndUpdate = (id, value, dataModel, isChangingNumber = false) => new Promise(async (resolve, reject) => {
  if (!dataModel.findByIdAndUpdate) {
    reject({
      message: "Not a valid data model",
    });
  } else {
    try {
      let dbResp;
      if (isChangingNumber) {
        // this section will be executed only if incrementing or decrementing number
        dbResp = await dataModel.findByIdAndUpdate(id, value, { new: true });
      } else {
        dbResp = await dataModel.findByIdAndUpdate(id, { $set: value }, { new: true });
      }
      resolve(dbResp.toJSON());
    } catch (error) {
      console.log(error);
      reject({ message: error.message, status: 500 });
    }
  }
});

const findOneAndUpdate = (filter, data, dataModel, options = { new: true }, DBName) =>
  new Promise(async (resolve, reject) => {

    console.log("DBName", DBName);
    if (!dataModel.findOneAndUpdate) {
      reject({
        message: "Not a valid data model",
        status: 500,
      });
    } else {

      try {
        let dbResp = await dataModel.findOneAndUpdate(filter, data, options);
        console.log("findOneAndUpdate response >>>> ", dbResp);
        if (dbResp) {
          resolve(dbResp);
        } else {
          reject({ message: "No record found to update.", status: 404 });
        }
      } catch (err) {
        console.log("Save err", err.toString());
        reject({
          message: err.message,
          status: err.code === 11000 ? 409 : 500,
        });
      }
    }
  });
const findManyAndUpdate = (filter, data, dataModel, options = { new: true, multi: true, upsert: true }, DBName) =>
  new Promise(async (resolve, reject) => {
    console.log("DBName", DBName);
    if (!dataModel.updateMany) {
      reject({
        message: "Not a valid data model",
        status: 500,
      });
    } else {
      await mongoose.connect(defaultConnectionString(DBName), { useNewUrlParser: true, }); // await on a step makes process to wait until it's done/ err'd out.
      db = mongoose.connection;
      try {
        let dbResp = await dataModel.updateMany(filter, data, options);
        if (dbResp) {
          resolve(dbResp);
        } else {
          reject({ message: "No record found to update.", status: 404 });
        }
      } catch (err) {
        console.log("Save err", err.toString());
        reject({
          message: err.message,
          status: err.code === 11000 ? 409 : 500,
        });
      } finally {
        console.log("close db conn");
        db.close();
      }
    }
  });
const disconnect = (connection) => {
  connection.disconnect();
  console.log("DBconn", mongoose.connection.readyState);
};

const applyPatch = (dataModel, patches) => {
  return new Promise(async (resolve, reject) => {
    if (!dataModel.jsonPatch) {
      reject({
        message: "Not a valid data model",
      });
    } else {
      let db;
      try {
        await mongoose.connect(defaultConnectionString(), {
          useNewUrlParser: true,
        });
        db = mongoose.connection;
        let options = {
          autosave: true,
          rules: [],
          rules_mode: 'blacklist'
        }
        await dataModel.jsonPatch(patches, options);
        db.close();
        resolve(dataModel);
      } catch (error) {
        reject(error);
      }
    }
  });
};

module.exports = {
  // connect,
  save,
  find,
  disconnect,
  findById,
  findByIdAndUpdate,
  findOneAndUpdate,
  applyPatch,
  findWithCondition,
  findManyAndUpdate,
  defaultConnectionString,
  disconnect
};
