import time
from export_report import ExportFbToJSON

currentTimeStamp = time.time()
expObj = ExportFbToJSON()

def exportData(event, context):
    fileName=event["queryStringParameters"]["fileName"] if event["queryStringParameters"]["fileName"] is not None else "exportedReport.json"
    startTimeStamp=event["queryStringParameters"]["startTimeStamp"] if event["queryStringParameters"]["startTimeStamp"] is not None else 0
    endTimeStamp=event["queryStringParameters"]["endTimeStamp"] if event["queryStringParameters"]["endTimeStamp"] is not None else currentTimeStamp
    division=event["queryStringParameters"]["division"] if event["queryStringParameters"]["division"] is not None else ""
    subdivision=event["queryStringParameters"]["subdivision"] if event["queryStringParameters"]["subdivision"] is not None else ""
    consumerName=event["queryStringParameters"]["consumerName"] if event["queryStringParameters"]["consumerName"] is not None else ""
    consumerNumber=event["queryStringParameters"]["consumerNumber"] if event["queryStringParameters"]["consumerNumber"] is not None else ""
    createdBy=event["queryStringParameters"]["createdBy"] if event["queryStringParameters"]["createdBy"] is not None else ""
    outputData = expObj.prepareAndExportReportData(fileName=fileName,
                                        startTimeStamp=startTimeStamp,
                                        endTimeStamp=endTimeStamp,
                                        division=division,
                                        subdivision=subdivision,
                                        consumerName=consumerName,
                                        consumerNumber=consumerNumber,
                                        createdBy=createdBy)
    responseObj = {}
    responseObj["statusCode"] = 200
    responseObj["headers"] = {}
    responseObj["headers"]["Content-Type"]="application/json"
    responseObj["body"] = outputData
    return responseObj