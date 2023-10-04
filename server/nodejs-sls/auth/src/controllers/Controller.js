class Controller {
  static sendResponse(response, payload) {
    /**
     * The default response-code is 200. We want to allow to change that. in That case,
     * payload will be an object consisting of a code and a payload. If not customized
     * send 200 and the payload as received in this method.
     */
    response.setHeader('Access-Control-Allow-Origin', '*');
    response.setHeader('Access-Control-Allow-Credentials', 'true');
    response.status(payload.code || 200);
    const responsePayload = payload.payload !== undefined ? payload.payload : payload;
    if (responsePayload instanceof Object) {
      response.json(responsePayload);
    } else {
      response.end(responsePayload);
    }
  }

  static sendError(response, error) {
    response.setHeader('Access-Control-Allow-Origin', '*');
    response.setHeader('Access-Control-Allow-Credentials', 'true');
    response.status(error.code || 500);
    if (error.error instanceof Object) {
      response.json(error.error);
    } else {
      response.json({ message: (error.error || error.message), status: error.code || 500 });
    }
  }
  static collectRequestParams(request) {
    let requestParams = { ...request.params, ...request.query, ...request.body };
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
    // request.openapi.schema.parameters.forEach((param) => {
    //   if (param.in === 'path') {
    //     requestParams[param.name] = request.openapi.pathParams[param.name];
    //   } else if (param.in === 'query') {
    //     requestParams[param.name] = request.query[param.name];
    //   } else if (param.in === 'header') {
    //     requestParams[param.name] = request.headers[param.name];
    //   }
    // });

    console.log("requestParams >>> ", requestParams);
    return requestParams;
  }

  static async handleRequest(request, response, serviceOperation, validationSchema) {
    try {
      const consolidatedParams = this.collectRequestParams(request);
      
      if (request.identity) {
        consolidatedParams.identity = request.identity;
        console.log('request.identity', request.identity);
      }
      const serviceResponse = await serviceOperation(consolidatedParams);
      Controller.sendResponse(response, serviceResponse);
    } catch (error) {
      Controller.sendError(response, error);
    }
  }
}

module.exports = Controller;
