from csvParser import CsvParser
from firebase import FirebaseDB
import json
import os
folderName = '23.11.2021'
filenames = os.listdir(folderName);
firebaseObj = FirebaseDB()
for file in filenames:
    print('Processing --- '+file)
    csvParserobj = CsvParser(folderName+'/'+file)
    data = json.loads(csvParserobj.getJSONData())
    count = firebaseObj.writeBulk(u'collection_consumers', data)
    print('***** Number of data written '+str(count)+' *****')
print('************** done **********')
###csvParserobj = CsvParser("sample-csv.csv")
###data = json.loads(csvParserobj.getJSONData())
###firebaseObj = FirebaseDB()

## Bulk insert example
###firebaseObj.writeBulk(u'collections_consumers', data)
