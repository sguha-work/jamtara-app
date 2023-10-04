import 'package:cloud_firestore/cloud_firestore.dart';

// importing models
import '../models/division.dart';

class DivisionService {
  String divisionsCollectionName = 'collection_divisions';
  Future<String> add(DivisionModel division) async {
    bool ifExists = await _ifAlreadyExists(division.code);
    if (!ifExists) {
      CollectionReference divisionsCollectionReference =
          FirebaseFirestore.instance.collection(divisionsCollectionName);
      String result = "";
      result = await divisionsCollectionReference
          .add({
            "code": division.code,
            "createdOn": division.createdOn,
            "createdBy": division.createdBy
          })
          .then((value) => 'success__')
          .catchError((error) => 'error__' + error.toString());
      return result;
    } else {
      return 'error__division-code-already-exists';
    }
  }

  Future<bool> _ifAlreadyExists(String divisionCode) async {
    DivisionModel? division = await getDivisionByDivisionCode(divisionCode);
    if (division != null) {
      return true;
    } else {
      return false;
    }
  }

  Future<String> update(String regionId, DivisionModel region) async {
    CollectionReference divisionsCollectionReference =
        FirebaseFirestore.instance.collection(divisionsCollectionName);
    String result = '';
    result = await divisionsCollectionReference
        .doc(regionId)
        .update({"code": region.code})
        .then((value) => 'success__')
        .catchError((error) => 'error__' + error.toString());
    return result;
  }

  Future<DivisionModel?> getDivisionByDivisionCode(String divisionCode) async {
    CollectionReference divisionCollectionReference =
        FirebaseFirestore.instance.collection(divisionsCollectionName);
    DivisionModel? division = null;
    division = await divisionCollectionReference
        .where("code", isEqualTo: divisionCode)
        .get()
        .then((QuerySnapshot querySnapshot) {
      DivisionModel? result = null;
      for (var doc in querySnapshot.docs) {
        result = DivisionModel(code: doc["code"], createdOn: doc["createdOn"]);
        break;
      }
      return result;
    }).catchError((error) {
      return null;
    });
    return division;
  }

  Future<List<DivisionModel>> getAllDivision(
      {double startAt = 0, double endAt = 0}) async {
    CollectionReference divisionsCollectionReference =
        FirebaseFirestore.instance.collection(divisionsCollectionName);
    List<DivisionModel> divisionList = [];
    if (startAt == endAt && endAt == 0) {
      divisionList = await divisionsCollectionReference
          .get()
          .then((QuerySnapshot querySnapshot) {
        List<DivisionModel> result = [];
        for (var doc in querySnapshot.docs) {
          result.add(DivisionModel(
              id: doc.reference.id.toString(),
              code: doc["code"],
              createdBy: doc["createdBy"],
              createdOn: doc["createdOn"]));
        }
        return result;
      }).catchError((error) {
        return [];
      });
    } else {
      divisionList = await divisionsCollectionReference
          .startAt([startAt])
          .endAt([endAt])
          .get()
          .then((QuerySnapshot querySnapshot) {
            List<DivisionModel> result = [];
            for (var doc in querySnapshot.docs) {
              result.add(DivisionModel(
                  id: doc.reference.id.toString(),
                  code: doc["code"],
                  createdOn: doc["createdOn"]));
            }
            return result;
          })
          .catchError((error) {
            return [];
          });
    }
    return divisionList;
  }

  Future<List<DivisionModel>> getAllDivisionsForAdmin(
      String userType, String mobileNumber,
      {double startAt = 0, double endAt = 0}) async {
    CollectionReference divisionsCollectionReference =
        FirebaseFirestore.instance.collection(divisionsCollectionName);
    List<DivisionModel> divisionList = [];
    if (startAt == endAt && endAt == 0) {
      divisionList = await divisionsCollectionReference
          .where("userType", isEqualTo: userType)
          .where("phoneNumber", isEqualTo: mobileNumber)
          .get()
          .then((QuerySnapshot querySnapshot) {
        List<DivisionModel> result = [];
        for (var doc in querySnapshot.docs) {
          result.add(DivisionModel(
              id: doc.reference.id.toString(),
              code: doc["code"],
              createdBy: doc["createdBy"],
              createdOn: doc["createdOn"]));
        }
        return result;
      }).catchError((error) {
        return [];
      });
    } else {
      divisionList = await divisionsCollectionReference
          .startAt([startAt])
          .endAt([endAt])
          .get()
          .then((QuerySnapshot querySnapshot) {
            List<DivisionModel> result = [];
            for (var doc in querySnapshot.docs) {
              result.add(DivisionModel(
                  id: doc.reference.id.toString(),
                  code: doc["code"],
                  createdOn: doc["createdOn"]));
            }
            return result;
          })
          .catchError((error) {
            return [];
          });
    }
    return divisionList;
  }

  Future<String> delete(DivisionModel region) async {
    CollectionReference divisionsCollectionReference =
        FirebaseFirestore.instance.collection(divisionsCollectionName);
    String result = '';
    result = await divisionsCollectionReference
        .doc(region.id)
        .delete()
        .then((value) {
      return 'success__';
    }).catchError((error) {
      return 'error__' + error.toString();
    });
    return result;
  }
}
