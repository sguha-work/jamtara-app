import json
from firebase import FirebaseDB
import time
firebaseObj = FirebaseDB()
currentTimeStamp = time.time()


def getUserDataFromDB():
    return firebaseObj.read("collection_users")


def getReportData():
    return firebaseObj.read("collection_reports")


def getAgentDataById(agentId, userData):
    return userData[agentId]


def prepareAndExportReportData(fileName="exportedReport.json", startTimeStamp=0, endTimeStamp=currentTimeStamp, division="", subdivision="", consumerName="", consumerNumber="", createdByUserId=""):
    print("########## Getting user data ##########")
    userData = getUserDataFromDB()
    print("########## Getting report data ##########")
    reportData = getReportData()
    print("########## Preparing final report data ##########")
    index = 0
    file = open("exportedReport.json", "w")
    file.write("[")
    file.close()
    file = open(fileName, "a")
    for key, value in reportData.items():
        print(f"Processing data {index}")
        index += 1
        individualReportData = reportData[key]
        
        # checking start and end time
        flag_timeCheck = True
        if startTimeStamp != 0 and endTimeStamp != currentTimeStamp:
            reportTime = individualReportData["createdByAgent"]
            if reportTime >= startTimeStamp and reportTime <= endTimeStamp:
                flag_timeCheck = True
            else:
                flag_timeCheck = False

        # checking division
        flag_divisionCheck = True        
        if division != "":
            if individualReportData["division"] == division:
                flag_divisionCheck = True
            else:
                flag_divisionCheck = False
        
        # checking subdivision
        flag_subdivisionCheck = True      
        if subdivision != "":
            if individualReportData["subdivision"] == subdivision:
                flag_subdivisionCheck = True
            else:
                flag_subdivisionCheck = True
        
        # checking consumerName
        flag_consumerNameCheck = True      
        if consumerName != "":
            if individualReportData["consumerName"] == consumerName:
                flag_consumerNameCheck = True
            else:
                flag_consumerNameCheck = True
        
        # checking consumerNumber
        flag_consumerNumberCheck = True      
        if consumerNumber != "":
            if individualReportData["consumerNumber"] == consumerNumber:
                flag_consumerNumberCheck = True
            else:
                flag_consumerNumberCheck = True

        # checking createdByUserId
        flag_createdByUserIdCheck = True      
        if createdByUserId != "":
            if individualReportData["createdByUserId"] == createdByUserId:
                flag_createdByUserIdCheck = True
            else:
                flag_createdByUserIdCheck = True

        if flag_timeCheck == True and flag_divisionCheck == True and flag_subdivisionCheck == True and flag_consumerNameCheck == True and flag_consumerNumberCheck == True and flag_createdByUserIdCheck == True:
            individualReportData["createdByAgent"] = userData[individualReportData["createdBy"]]
            individualReportData["id"] = key
            file.write(json.dumps(individualReportData))
            file.write(",")
        else:
            print("Skipping this step as conditioned not matched")
            continue

    file.write("{}")
    file.write("]")
    file.close()


prepareAndExportReportData()
