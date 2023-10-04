import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import json
import time

# configurations begins
from firebase_admin.exceptions import FirebaseError

projectId = "bentec-meterlagao"
serviceAccountJSONFilePath = (
    "bentec-meterlagao-firebase-adminsdk-5e5wr-57ff104c13.json"
)


# configurations ends


class FirebaseDB:
    def __init__(self):
        self.serviceAccountJSONFilePath = serviceAccountJSONFilePath
        self.projectId = projectId
        self.__initializeDB()

    # Private methods
    def __initializeDB(self):
        cred = credentials.Certificate(serviceAccountJSONFilePath)
        firebase_admin.initialize_app(cred)

    def __getDBInstance(self):
        dbInstance = firestore.client()
        return dbInstance

    def __convertToCSV(self, data):
        # todo
        return data

    # Public method begins
    def write(self, collectionName, data):
        dbInstance = self.__getDBInstance()
        collectionRefference = dbInstance.collection(collectionName)
        try:
            collectionRefference.add(data)
            return 1
        except:
            print("Unable to write database")
            return False

    def writeBulk(self, collectionName, data):
        dbInstance = self.__getDBInstance()
        collectionRefference = dbInstance.collection(collectionName)
        batch = dbInstance.batch()
        counter = 0
        totalCount = 0
        for index, datum in enumerate(data):
            newDoc = collectionRefference.document()
            batch.set(newDoc, datum)
            counter += 1
            totalCount += 1
            if counter == 500:
                counter = 0
                try:
                    batch.commit()
                    batch = dbInstance.batch()
                except Exception as e:
                    print('Unable to write database ' + str(e))
        try:
            batch.commit()
        except Exception as e:
            print('Unable to write database ' + str(e))
        # Returning number of data inserted
        return totalCount

    def export(self, dbName, collectionNamesList):
        dataToReturn = {dbName: {}}
        for index, collectionName in enumerate(collectionNamesList):
            dataToReturn[dbName][collectionName] = self.read(collectionName)
        file = open(dbName + "_exported.json", "w")
        file.write(json.dumps(dataToReturn))
        file.close()

    def importDB(self, dbName):
        return

    def readCSV(self, collectionName, docName=""):
        dataToReturn = self.read(collectionName, docName)
        # todo
        return self.__convertToCSV(dataToReturn)

    def readJSON(self, collectionName, docName=""):
        dataToReturn = self.read(collectionName, docName)
        return json.dumps(dataToReturn)

    def read(self, collectionName, docName=""):
        dbInstance = self.__getDBInstance()
        collectionInstance = dbInstance.collection(collectionName)
        docs = collectionInstance.stream()
        docToReturn = {}
        if docName == "" or docName == "all":
            for doc in docs:
                docToReturn[doc.id] = doc.to_dict()
        else:
            for doc in docs:
                if doc.id == docName:
                    docToReturn = doc.to_dict()
                break
        return docToReturn

    def getQuery(self, collectionName, attributeName, value):
        dbInstance = self.__getDBInstance()
        collectionInstance = dbInstance.collection(collectionName)
        query_ref = collectionInstance.where(attributeName, u'==', value)
        docs = query_ref.stream()
        docToReturn = {}
        for doc in docs:
            docToReturn[doc.id] = doc.to_dict()
        return json.dumps(docToReturn)

    def update_collection(self, collection_name, existing_attribute, new_data):
        db_instance = self.__getDBInstance()
        collection_instance = db_instance.collection(collection_name)
        # query_ref = collection_instance.where(existing_attribute, '!=', '')
        counter = 0
        number_of_data_per_fetch = 200
        query = collection_instance.order_by(
            existing_attribute).limit(number_of_data_per_fetch)
        while True:
            print('Updating doc number ', counter, ' to ',
                  (counter+number_of_data_per_fetch))
            try:
                docs = query.get()
            except FirebaseError:
                print('Error occurred in updating DB', FirebaseError.code)
                return False
            list_of_doc = list(docs)
            last_doc = list_of_doc[len(list_of_doc)-1]
            last_pop = last_doc.to_dict()[existing_attribute]
            for doc in docs:
                counter += 1
                try:
                    for updated_obj in new_data:
                        doc.reference.update(updated_obj)
                except FirebaseError:
                    print('Error updating database', FirebaseError.code)
                    return False
            if len(list(docs)) < number_of_data_per_fetch:
                break
            else:
                query = collection_instance.order_by(existing_attribute).start_after({
                    existing_attribute: last_pop
                }).limit(number_of_data_per_fetch)
        return True

    def __is_duplicate(self, doc, collection_instance, existing_attribute):
        doc_dict = doc.to_dict()
        main_doc_id = doc.id
        data_to_check_duplicacy = doc_dict[existing_attribute]
        print(data_to_check_duplicacy)
        docs = collection_instance.where(
            existing_attribute, u'==', data_to_check_duplicacy).get()
        list_of_docs = list(docs)
        if list_of_docs:
            duplicate_doc_id_list = []
            for individualDoc in docs:
                if individualDoc.id != main_doc_id:
                    print(individualDoc.id)
                    print(individualDoc.to_dict()[existing_attribute])
                    duplicate_doc_id_list.append(individualDoc.id)
            if len(duplicate_doc_id_list) == 0:
                return False
            return duplicate_doc_id_list
        else:
            return False

    def remove_duplicate_record_from_collection(self, collection_name, existing_attribute):
        db_instance = self.__getDBInstance()
        collection_instance = db_instance.collection(collection_name)
        number_of_data_per_fetch = 200
        query = collection_instance.order_by(
            existing_attribute).limit(number_of_data_per_fetch)
        counter = 0
        duplicate_doc_id_list = []
        while True:
            try:
                docs = query.get()
            except FirebaseError:
                print('Error occurred in updating DB', FirebaseError.code)
                return False
            list_of_doc = list(docs)
            last_doc = list_of_doc[len(list_of_doc) - 1]
            last_pop = last_doc.to_dict()[existing_attribute]
            for doc in docs:
                counter += 1
                print('checking doc number ', counter)
                result = self.__is_duplicate(
                    doc, collection_instance, existing_attribute)
                print('IS_Duplicate result...', result)
                if isinstance(result, list):
                    for duplicate_doc_id in result:
                        if duplicate_doc_id not in duplicate_doc_id_list:
                            duplicate_doc_id_list.append(duplicate_doc_id)
            if len(list(docs)) < number_of_data_per_fetch:
                break
            else:
                query = collection_instance.order_by(existing_attribute).start_after({
                    existing_attribute: last_pop
                }).limit(number_of_data_per_fetch)
        print('duplicate id list', duplicate_doc_id_list)
        print('duplicate record length', len(duplicate_doc_id_list))
        return duplicate_doc_id_list
