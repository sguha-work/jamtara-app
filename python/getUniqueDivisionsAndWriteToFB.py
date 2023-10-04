from csvParser import CsvParser
from firebase import FirebaseDB
import json
import os
import time

folderName = '23.11.2021'
filenames = os.listdir(folderName);
firebaseObj = FirebaseDB()
uniqueDivisionList = []
divisionListFromDB = []
divisionListFromFiles = []
# getting unique divisions from db
divisionFromDatabase = json.loads(firebaseObj.readJSON('collection_divisions'))
documentKeys = divisionFromDatabase.keys()
for key in documentKeys:
    data = divisionFromDatabase[key]
    division = data['code']
    divisionListFromDB.append(division)

# getting unique divisions from files
for file in filenames:
    print('Processing --- ' + file)
    csvParserobj = CsvParser(folderName + '/' + file)
    data = json.loads(csvParserobj.getJSONData())
    for datum in data:
        division = datum['DIVISION']
        if division in divisionListFromFiles:
            continue
        else:
            divisionListFromFiles.append(division)
for division in divisionListFromFiles:
    if division in divisionListFromDB:
        continue
    else:
        uniqueDivisionList.append(division)
print(uniqueDivisionList)
# writing unique divisions to firebase
counter = 0
writableData = []
for datum in uniqueDivisionList:
    writableData.append({
        'code': datum,
        'createdBy': 'admin',
        'createdOn': str(round(time.time() * 1000))
    })
    counter += 1
if len(writableData):
    firebaseObj.writeBulk('collection_divisions', writableData)
print('******* Number of data written '+str(counter)+' *****')