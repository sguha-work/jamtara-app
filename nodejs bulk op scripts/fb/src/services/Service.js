class Service {
  static rejectResponse(error, code = 500) {
    return { error, code };
  }

  static successResponse(payload, code = 200) {
    return { payload, code, isFile:payload.isFile, fileName: payload.fileName, downloadFile: payload.downloadFile };
  }
}

module.exports = Service;
