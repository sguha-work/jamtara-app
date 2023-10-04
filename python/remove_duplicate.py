from firebase import FirebaseDB
firebaseObj = FirebaseDB()
result = firebaseObj.remove_duplicate_record_from_collection(
    'test_consumer_collection', 'consumerNo')
if result:
    print('Duplicate data removed successfully')
else:
    print('Duplicate data removal failed')
