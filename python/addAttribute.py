from firebase import FirebaseDB
firebaseObj = FirebaseDB()
# consumerNo is the field which is common in every document and must not be empty

result = firebaseObj.update_collection('collection_consumers', 'NAME', [
    {'isApprovedBySupervisor': False}, {'isRejectedBySupervisor': False}
])
if result == True:
    print('DB updation successfull')
else:
    print('DB updation failed')
