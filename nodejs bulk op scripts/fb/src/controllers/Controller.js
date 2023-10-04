const AWS = require('aws-sdk');
class Controller {
  static convertJSONToCSV(jsonData) {
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
          csvString += individualData[key] + ","
        });
        csvString = csvString.slice(0, -1);
        csvString += "\n";
      });
    }
    return csvString;
  }
  static async sendResponse(response, payload) {
    /**
     * The default response-code is 200. We want to allow to change that. in That case,
     * payload will be an object consisting of a code and a payload. If not customized
     * send 200 and the payload as received in this method.
     */
    if (payload.isFile) {
      response.setHeader('Access-Control-Allow-Origin', '*');
      response.setHeader('Access-Control-Allow-Credentials', 'true');
      response.setHeader('Content-disposition', `attachment; filename= ${payload.fileName}`);
      let outputData;
      if (payload.fileName.indexOf('json') != -1) {
        response.setHeader('Content-type', 'application/json');
        outputData = JSON.stringify(payload);
      } else {
        try {
          outputData = Controller.convertJSONToCSV(payload.payload);
          if (payload.downloadFile) {
            response.setHeader('Access-Control-Allow-Origin', '*');
            response.setHeader('Access-Control-Allow-Credentials', 'true');
            const client = new AWS.S3();
            client.config.update({
              accessKeyId: process.env.accessKeyId,
              secretAccessKey: process.env.secretAccessKey,
              region: process.env.AWS_REGION,
              signatureVersion: "v4",
            });
            const params = {
              Bucket: 'bw-dev-image-bucket', // your bucket name
              Key: `test/${Date.now()}-test-data.csv`, // Date.now() is use for creating unique file name
              ACL: 'public-read',
              Body: outputData,
              ContentType: 'text/csv',
            };
            const uploadResp = await client.upload(params).promise();
            console.log("uploadResp-->", uploadResp);
            outputData = uploadResp;
            console.log("final result",{ "url": uploadResp });
            return response.status(201).json({ "url": uploadResp });
          } else {
            response.setHeader('Content-type', 'application/csv');
            return response.write(outputData, function (err) {
              response.end();
            });
          }
        } catch (error) {
          console.log(error);
        }
      }
    } else {
      response.setHeader('Access-Control-Allow-Origin', '*');
      response.setHeader('Access-Control-Allow-Credentials', 'true');
      response.status(payload.code || 200);
      if (payload.isFile) delete payload.isFile;
      if (payload.fileName) delete payload.fileName;
      const responsePayload =
        payload.payload !== undefined ? payload.payload : payload;
      if (responsePayload instanceof Object) {
        response.json(responsePayload);
      } else {
        response.end(responsePayload);
      }
    }
  }

  static sendError(response, error) {
    response.setHeader('Access-Control-Allow-Origin', '*');
    response.setHeader('Access-Control-Allow-Credentials', 'true');
    response.status(error.code || 500);
    if (error.error instanceof Object) {
      response.json(error.error);
    } else {
      console.log('this is the error', error);
      response.json({ message: (error.error || error.message), status: error.code || 500 });
    }
  }
  static collectRequestParams(request) {
    let requestParams = { ...request.params, ...request.query };
    try {
      if (request.body !== undefined) {
        if (
          request.headers &&
          request.headers["content-type"] === "application/json"
        ) {
          requestParams = { ...requestParams, ...request.body };
        } else if (
          request.headers &&
          typeof request.headers["content-type"] != "undefined" &&
          request.headers["content-type"].indexOf("multipart/form-data") !== -1
        ) {
          console.log(
            JSON.stringify(content["multipart/form-data"].schema.properties)
          );
          Object.keys(content["multipart/form-data"].schema.properties).forEach(
            (property) => {
              const propertyObject =
                content["multipart/form-data"].schema.properties[property];
              if (
                propertyObject.format !== undefined &&
                propertyObject.format === "binary"
              ) {
                requestParams[property] = this.collectFile(request, property);
              } else {
                requestParams[property] = request.body[property];
              }
            }
          );
        }
      }
    } catch (err) {
      console.log(err);
    }
    console.log("requestParams >>> ", requestParams);
    return requestParams;
  }

  static async handleRequest(request, response, serviceOperation) {
    try {
      const consolidatedParams = this.collectRequestParams(request);
      const serviceResponse = await serviceOperation(consolidatedParams);
      Controller.sendResponse(response, serviceResponse);
    } catch (error) {
      console.log("data error", error);
      Controller.sendError(response, error);
    }
  }
}

module.exports = Controller;
