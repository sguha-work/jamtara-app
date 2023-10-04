import os
from flask import Flask, send_file, request
from export_report import ExportFbToJSON
import time

portName = 5000
currentTimeStamp = time.time()
expObj = ExportFbToJSON()

# create the Flask app
flaskapp = Flask(__name__)


@flaskapp.route('/')
def home():
    return 'Hello from python!'


@flaskapp.route('/get-report', methods=['GET'])
def get_report():
    args = request.args.to_dict()
    print("Executing script")
    expObj.prepareAndExportReportDataToFile(fileName=args.get("fileName") if args.get("fileName") is not None else "exportedReport.json",
                                      startTimeStamp=args.get("startTimeStamp") if args.get("startTimeStamp") is not None else 0,
                                      endTimeStamp=args.get("endTimeStamp") if args.get("endTimeStamp") is not None else currentTimeStamp,
                                      division=args.get("division") if args.get("division") is not None else "",
                                      subdivision=args.get("subdivision") if args.get("subdivision") is not None else "",
                                      consumerName=args.get("consumerName") if args.get("consumerName") is not None else "",
                                      consumerNumber=args.get("consumerNumber") if args.get("consumerNumber") is not None else "",
                                      createdBy=args.get("createdBy") if args.get("createdBy") is not None else "")
    print("Script execution done")
    directory = os.getcwd()
    print("current directory", directory)
    path = directory+"/exportedReport.json"
    return send_file(path, as_attachment=True)


# if __name__ == '__main__':
#     app.run(debug=True, port=portName)
if __name__ == '__main__':
    flaskapp.run(debug=True, port=portName, host='0.0.0.0')
