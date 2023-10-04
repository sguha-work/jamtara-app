class Service {
  static rejectResponse(error, code = 500) {
    return { error, code };
  }

  static successResponse(payload, code = 200) {
    payload.supportedAppVersion = process.env.SUPPORTED_APP_VERSION.split(',');
    return { payload, code };
  }
}

module.exports = Service;
