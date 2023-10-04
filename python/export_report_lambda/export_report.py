import json
from firebase import FirebaseDB
import time

currentTimeStamp = time.time()

class ExportFbToJSON:

    def __init__(self):
        self.firebaseObj = FirebaseDB()
    
    def __getUserDataFromDB(self):
        return self.firebaseObj.read("collection_users")
    
    
    def __getReportData(self):
        return self.firebaseObj.read("collection_reports")
    
    
    def __getAgentDataById(agentId, userData):
        return userData[agentId]
    
    
    def prepareAndExportReportDataToFile(self,
                                   fileName="exportedReport.json",
                                   startTimeStamp=0,
                                   endTimeStamp=currentTimeStamp,
                                   division="",
                                   subdivision="",
                                   consumerName="",
                                   consumerNumber="",
                                   createdBy=""):
        print("########## Getting user data ##########")
        userData = self.__getUserDataFromDB()
        print("########## Getting report data ##########")
        reportData = self.__getReportData()
        print("########## Preparing final report data ##########")
        index = 0
        file = open("exportedReport.json", "w")
        file.write("[")
        file.close()
        file = open(fileName, "a")
        
        if isinstance(startTimeStamp, str):
            startTimeStamp = int(startTimeStamp)
        else:
            startTimeStamp=startTimeStamp
        
        if isinstance(endTimeStamp, str):
            endTimeStamp = int(endTimeStamp)
        else:
            endTimeStamp=endTimeStamp
        
        for key, value in reportData.items():
            #print(f"Processing data {index}")
            index += 1
            individualReportData = reportData[key]
            
            # checking start and end time
            flag_timeCheck = True
            if startTimeStamp != 0 and endTimeStamp != currentTimeStamp:
                reportTime = individualReportData["createdOn"]
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
                    flag_subdivisionCheck = False
            
            # checking consumerName
            flag_consumerNameCheck = True      
            if consumerName != "":
                if individualReportData["consumerName"] == consumerName:
                    flag_consumerNameCheck = True
                else:
                    flag_consumerNameCheck = False
            
            # checking consumerNumber
            flag_consumerNumberCheck = True      
            if consumerNumber != "":
                if individualReportData["consumerNumber"] == consumerNumber:
                    flag_consumerNumberCheck = True
                else:
                    flag_consumerNumberCheck = False
    
            # checking createdBy
            flag_createdByCheck = True      
            if createdBy != "":
                if individualReportData["createdBy"] == createdBy:
                    flag_createdByCheck = True
                else:
                    flag_createdByCheck = False
    
            if flag_timeCheck == True and flag_divisionCheck == True and flag_subdivisionCheck == True and flag_consumerNameCheck == True and flag_consumerNumberCheck == True and flag_createdByCheck == True:
                individualReportData["createdByAgent"] = userData[individualReportData["createdBy"]]
                individualReportData["id"] = key
                file.write(json.dumps(individualReportData))
                file.write(",")
            else:
                continue
    
        file.write("{}")
        file.write("]")
        file.close()

    def prepareAndExportReportData(self,
                                   fileName="exportedReport.json",
                                   startTimeStamp=0,
                                   endTimeStamp=currentTimeStamp,
                                   division="",
                                   subdivision="",
                                   consumerName="",
                                   consumerNumber="",
                                   createdBy=""):
        print("########## Getting user data ##########")
        userData = self.__getUserDataFromDB()
        print("########## Getting report data ##########")
        reportData = self.__getReportData()
        print("########## Preparing final report data ##########")
        index = 0
        outputData = "["
        
        if isinstance(startTimeStamp, str):
            startTimeStamp = int(startTimeStamp)
        else:
            startTimeStamp=startTimeStamp
        
        if isinstance(endTimeStamp, str):
            endTimeStamp = int(endTimeStamp)
        else:
            endTimeStamp=endTimeStamp
        
        for key, value in reportData.items():
            #print(f"Processing data {index}")
            index += 1
            individualReportData = reportData[key]
            
            # checking start and end time
            flag_timeCheck = True
            if startTimeStamp != 0 and endTimeStamp != currentTimeStamp:
                reportTime = individualReportData["createdOn"]
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
                    flag_subdivisionCheck = False
            
            # checking consumerName
            flag_consumerNameCheck = True      
            if consumerName != "":
                if individualReportData["consumerName"] == consumerName:
                    flag_consumerNameCheck = True
                else:
                    flag_consumerNameCheck = False
            
            # checking consumerNumber
            flag_consumerNumberCheck = True      
            if consumerNumber != "":
                if individualReportData["consumerNumber"] == consumerNumber:
                    flag_consumerNumberCheck = True
                else:
                    flag_consumerNumberCheck = False
    
            # checking createdBy
            flag_createdByCheck = True      
            if createdBy != "":
                if individualReportData["createdBy"] == createdBy:
                    flag_createdByCheck = True
                else:
                    flag_createdByCheck = False
    
            if flag_timeCheck == True and flag_divisionCheck == True and flag_subdivisionCheck == True and flag_consumerNameCheck == True and flag_consumerNumberCheck == True and flag_createdByCheck == True:
                individualReportData["createdByAgent"] = userData[individualReportData["createdBy"]]
                individualReportData["id"] = key
                outputData = outputData + json.dumps(individualReportData)
                outputData = outputData +","
            else:
                continue
    
        outputData = outputData + "{}]"
        return outputData

