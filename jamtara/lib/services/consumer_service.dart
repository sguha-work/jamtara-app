import 'dart:convert';
import 'package:bentec/models/user.dart';

import '../models/consumer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'file_service.dart';
import 'user_service.dart';
import 'parse_csv.dart';

import 'package:file_picker/file_picker.dart';
// import common
import 'common.dart';

// importing models
import '../models/user.dart';

class ConsumerService {
  String consumerCollectionName = 'collection_consumers';
  String consumerCacheFileName = '5icuej2lquznjtm';
  UserService userService = UserService();

  late CollectionReference consumersCollectionReference =
      FirebaseFirestore.instance.collection('collection_consumers');

  Future<List<ConsumerModel>?> getAllConsumersFromFile(
      {bool filterBasedOnApprovalBySupervisor = false}) async {
    String dataFromFile = await FileService.read(consumerCacheFileName);
    Common.customLog('Data from file --------- ' + dataFromFile);
    if (dataFromFile != '') {
      final decodedData = jsonDecode(dataFromFile) as List<dynamic>;
      List<ConsumerModel> result = [];
      if (!filterBasedOnApprovalBySupervisor) {
        for (var data in decodedData) {
          var doc = data as Map;
          Common.customLog('---------1 ' +
              doc['name'] +
              ' ' +
              doc['isApprovedBySupervisor'].toString());
          result.add(getModelBasedOnData(doc));
        }
      } else {
        for (var data in decodedData) {
          var doc = data as Map;
          Common.customLog('---------2 ' +
              doc['name'] +
              ' ' +
              doc['isApprovedBySupervisor'].toString());
          if (doc['isApprovedBySupervisor'] == true) {
            Common.customLog('---------3 ' +
                doc['name'] +
                ' ' +
                doc['isApprovedBySupervisor'].toString());
            result.add(getModelBasedOnData(doc));
          }
        }
      }
      Common.customLog('result --------- ' + result.length.toString());
      return result;
    }
  }

  ConsumerModel getModelBasedOnData(Map doc) {
    return ConsumerModel(
        consumerId: doc['consumerId'],
        consumerNo: doc['consumerNo'],
        address1: doc['address1'],
        address2: doc['address2'],
        address3: doc['address3'],
        address4: doc['address4'],
        currentstatus: doc['currentstatus'],
        load: doc['load'],
        meterSlno: doc['meterSlno'],
        name: doc['name'],
        subdivision: doc['subdivision'],
        division: doc['division'],
        aadharNo: doc['aadharNo'],
        circle: doc['circle'],
        consumerType: doc['consumerType'],
        meterMake: doc['meterMake'],
        mobileNo: doc['mobileNo'],
        tariff: doc['tariff'],
        isApprovedBySupervisor: doc['isApprovedBySupervisor'],
        isRejectedBySupervisor: doc['isRejectedBySupervisor']);
  }

  Future<void> buildConsumerListCacheForAgent(Function callback,
      {bool forceRebuild = false}) async {
    String data = await FileService.read(consumerCacheFileName);
    if (data == '' || forceRebuild) {
      List<ConsumerModel> consumersList = [];
      CollectionReference consumersCollectionReference =
          FirebaseFirestore.instance.collection(consumerCollectionName);
      String? currentAgentId = await userService.getCurrentUserId() ?? '';
      if (currentAgentId != '') {
        UserModel? agent = await userService.getUserById(currentAgentId);
        if (agent != null) {
          consumersList = await consumersCollectionReference
              .where("DIVISION", isEqualTo: agent.division)
              .where("METER NUMBER", isEqualTo: "")
              .get()
              .then((QuerySnapshot querySnapshot) {
            List<ConsumerModel> result = [];
            Common.customLog(
                '------------>>>' + querySnapshot.docs.length.toString());

            for (var doc in querySnapshot.docs) {
              Common.customLog('\nNAME-----' + doc["NAME"]);
              Common.customLog('\ID-----' + doc.reference.id.toString());
              ConsumerModel consumer = ConsumerModel(
                id: doc.reference.id.toString(),
                consumerId: doc.data().toString().contains("CONSUMER NO")
                    ? doc.get("CONSUMER NO")
                    : "",
                consumerNo: doc.data().toString().contains("CONSUMER NO")
                    ? doc.get("CONSUMER NO")
                    : "",
                address1: doc.data().toString().contains("ADDRESS1")
                    ? doc.get("ADDRESS1")
                    : "",
                address2: doc.data().toString().contains("ADDRESS2")
                    ? doc.get("ADDRESS2")
                    : "",
                address3: doc.data().toString().contains("ADDRESS3")
                    ? doc.get("ADDRESS3")
                    : "",
                address4: doc.data().toString().contains("ADDRESS4")
                    ? doc.get("ADDRESS4")
                    : "",
                currentstatus: doc.data().toString().contains("METER STATUS")
                    ? doc.get("METER STATUS")
                    : "",
                load: doc.data().toString().contains("LOAD")
                    ? doc.get("LOAD")
                    : "",
                meterSlno: doc.data().toString().contains("METER NUMBER")
                    ? doc.get("METER NUMBER")
                    : "",
                name: doc.data().toString().contains("NAME")
                    ? doc.get("NAME")
                    : "",
                subdivision: doc.data().toString().contains("SUB DIVISION")
                    ? doc.get("SUB DIVISION")
                    : "",
                tariff: doc.data().toString().contains("TARIFF")
                    ? doc.get("TARIFF")
                    : "",
                mobileNo: doc.data().toString().contains("MOBILE NO")
                    ? doc.get("MOBILE NO")
                    : "",
                meterMake: doc.data().toString().contains("METER MAKE")
                    ? doc.get("METER MAKE")
                    : "",
                consumerType: doc.data().toString().contains("CONSUMER TYPE")
                    ? doc.get("CONSUMER TYPE")
                    : "",
                circle: doc.data().toString().contains("CIRCLE")
                    ? doc.get("CIRCLE")
                    : "",
                aadharNo: doc.data().toString().contains("AADHAR NO")
                    ? doc.get("AADHAR NO")
                    : "",
                division: doc.data().toString().contains("DIVISION")
                    ? doc.get("DIVISION")
                    : "",
                isApprovedBySupervisor:
                    doc.data().toString().contains("isApprovedBySupervisor")
                        ? doc.get("isApprovedBySupervisor")
                        : false,
                isRejectedBySupervisor:
                    doc.data().toString().contains("isRejectedBySupervisor")
                        ? doc.get("isRejectedBySupervisor")
                        : false,
              );
              result.add(consumer);
            }
            return result;
          }).catchError((error) {
            Common.customLog('CACHE ERROR____' + error.toString());
            return [];
          });
        }
      }
      String jsonData =
          jsonEncode(consumersList.map((e) => e.toJson()).toList());
      FileService.write(jsonData, consumerCacheFileName, (result) {
        callback();
      });
    } else {
      Common.customLog('CACHE AVAILABLE');
      callback();
    }
  }

  Future<List<DocumentSnapshot<Object?>>> getConsumerListForSuperAdmin(
      int pageLength,
      {DocumentSnapshot? startAfter}) async {
    Common.customLog('getConsumerListForSuperAdmin() is called.....');
    CollectionReference consumersCollectionReference =
        FirebaseFirestore.instance.collection(consumerCollectionName);
    List<DocumentSnapshot> docs;
    if (startAfter == null) {
      docs = await consumersCollectionReference
          .orderBy("NAME")
          .limit(pageLength)
          .get()
          .then((QuerySnapshot querySnapshot) {
        return querySnapshot.docs;
      }).catchError((error) {
        return [];
      });
    } else {
      docs = await consumersCollectionReference
          .orderBy("NAME")
          .startAfterDocument(startAfter)
          .limit(pageLength)
          .get()
          .then((QuerySnapshot querySnapshot) {
        return querySnapshot.docs;
      }).catchError((error) {
        return [];
      });
    }
    return docs;
  }

  Future<List<DocumentSnapshot<Object?>>>
      getConsumerListByPageFilteredByDivision(int pageLength, String division,
          {DocumentSnapshot? startAfter, bool isDescending = false}) async {
    CollectionReference consumersCollectionReference =
        FirebaseFirestore.instance.collection(consumerCollectionName);
    Query _query = consumersCollectionReference
        .where("DIVISION", isEqualTo: division)
        .limit(pageLength);
    if (isDescending) {
      _query = _query.orderBy("createdOn", descending: isDescending);
    } else {
      _query = _query.orderBy("NAME");
    }
    List<DocumentSnapshot> docs;
    Common.customLog("DIVISION........." + division);
    if (startAfter == null) {
      docs = await _query.get().then((QuerySnapshot querySnapshot) {
        return querySnapshot.docs;
      }).catchError((error) {
        Common.customLog(
            'getConsumerListByPageFilteredByDivision............ERROR...' +
                error.toString());
        return [];
      });
    } else {
      docs = await _query
          .startAfterDocument(startAfter)
          .get()
          .then((QuerySnapshot querySnapshot) {
        return querySnapshot.docs;
      }).catchError((error) {
        Common.customLog(
            'getConsumerListByPageFilteredByDivision............ERROR...' +
                error.toString());
        return [];
      });
    }
    return docs;
  }

  Future<String> approveConsumer(ConsumerModel consumer) async {
    CollectionReference consumersCollectionReference =
        FirebaseFirestore.instance.collection(consumerCollectionName);
    String result = "";
    result = await consumersCollectionReference
        .doc(consumer.id)
        .update(
            {"isApprovedBySupervisor": true, "isRejectedBySupervisor": false})
        .then((value) => "success__")
        .catchError((error) => "error__" + error.toString());
    return result;
  }

  Future<String> rejectSupervisor(ConsumerModel consumer) async {
    CollectionReference consumersCollectionReference =
        FirebaseFirestore.instance.collection(consumerCollectionName);
    String result = "";
    result = await consumersCollectionReference
        .doc(consumer.id)
        .update(
            {"isApprovedBySupervisor": false, "isRejectedBySupervisor": true})
        .then((value) => "success__")
        .catchError((error) => "error__" + error.toString());
    return result;
  }

  Future<int> getNumberOfConsumersUnderDivision(String division) async {
    CollectionReference consumersCollectionReference =
        FirebaseFirestore.instance.collection(consumerCollectionName);
    return await consumersCollectionReference
        .where("DIVISION", isEqualTo: division)
        .get()
        .then((QuerySnapshot querySnapshot) {
      return querySnapshot.docs.length;
    });
  }

  getConsumerList(Function callback) async {
    List<ConsumerModel>? listOfConsumers = await getAllConsumersFromFile();
    if (listOfConsumers != null) {
      callback(listOfConsumers);
    }
  }

  Future<String> getConsumerIdByConsumerNumber(String consumerNumber) async {
    String consumerId = "";
    CollectionReference consumersCollectionReference =
        FirebaseFirestore.instance.collection(consumerCollectionName);
    consumerId = await consumersCollectionReference
        .where("CONSUMER NO", isEqualTo: consumerNumber)
        .get()
        .then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs[0].reference.id.toString();
      } else {
        return '';
      }
    });
    return consumerId;
  }

  Future<String> updateConsumer(String consumerNumber, String meterNumber,
      String mobileNumber, String aadharNumber) async {
    String consumerId = await getConsumerIdByConsumerNumber(consumerNumber);
    CollectionReference consumersCollectionReference =
        FirebaseFirestore.instance.collection(consumerCollectionName);
    String result = await consumersCollectionReference.doc(consumerId).update({
      "METER NUMBER": meterNumber,
      "MOBILE NO": mobileNumber,
      "AADHAR NO": aadharNumber
    }).then((_) {
      return 'success__';
    }).catchError((error) {
      return 'error__';
    });
    return result;
  }

  Future<bool> isConsumerNumberExists(String consumerNumber) async {
    bool result = await FirebaseFirestore.instance
        .collection(consumerCollectionName)
        .where("CONSUMER NO", isEqualTo: consumerNumber)
        .get()
        .then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        return false;
      } else {
        return true;
      }
    }).catchError((e) {
      return false;
    });
    return result;
  }

  Future<String> addConsumer(ConsumerModel consumer) async {
    bool isPhoneNumberExists =
        await isConsumerNumberExists(consumer.consumerNo);
    if (isPhoneNumberExists) {
      return 'error__ConsumerNo already exists';
    }

    try {
      CollectionReference consumerCollectionReference =
          FirebaseFirestore.instance.collection(consumerCollectionName);
      String result = "";
      result = await consumerCollectionReference
          .add({
            "NAME": consumer.name,
            "ADDRESS1": consumer.address1,
            "ADDRESS2": consumer.address2,
            "ADDRESS3": consumer.address3,
            "ADDRESS4": consumer.address4,
            "SUB DIVISION": consumer.subdivision,
            "CIRCLE": consumer.circle,
            "CONSUMER NO": consumer.consumerNo,
            "CONSUMER TYPE": consumer.consumerType,
            "DIVISION": consumer.division,
            "LOAD": consumer.load,
            "METER MAKE": consumer.meterMake,
            "METER NUMBER": consumer.meterSlno,
            "METER STATUS": consumer.currentstatus,
            "MOBILE NO": consumer.mobileNo,
            "TARIFF": consumer.tariff,
            "AADHAR NO": consumer.aadharNo,
            "isApprovedBySupervisor": false,
            "isRejectedBySupervisor": false,
            "createdOn": DateTime.now().millisecondsSinceEpoch.toString()
          })
          .then((value) => 'success__' + value.id.toString())
          .catchError((error) => 'error__' + error.toString());
      return result;
    } catch (e) {
      return 'error__';
    }
  }

  Future<ConsumerModel> getConsumersFromCSVData(dataChunkList) async {
    ConsumerModel consumer = ConsumerModel(
        circle: dataChunkList[0],
        division: dataChunkList[1],
        subdivision: dataChunkList[2],
        consumerType: dataChunkList[3],
        consumerNo: dataChunkList[4],
        consumerId: dataChunkList[4],
        name: dataChunkList[5],
        address1: dataChunkList[6],
        address2: dataChunkList[7],
        address3: dataChunkList[8],
        address4: dataChunkList[9],
        tariff: dataChunkList[10],
        load: dataChunkList[11],
        currentstatus: dataChunkList[12],
        meterSlno: dataChunkList[13],
        meterMake: dataChunkList[14],
        mobileNo: dataChunkList[15]);
    return consumer;
  }

  Future<String> uploadConsumersFromCSV(Function callback,
      {PlatformFile? selectedFile}) async {
    Common.customLog("1.........");
    String result = '';
    int totalConsumersToBeAdded = 0;
    int totalConsumersAdded = 0;
    if (selectedFile != null) {
      List<dynamic> dataFromFile = ParseCSV.getCSVLines(selectedFile);
      totalConsumersToBeAdded = dataFromFile.length;
      Common.customLog("2.........");
      for (String dataLine in dataFromFile) {
        List<String> dataChunkList = dataLine.split(',');
        if (dataChunkList.length >= 6 && dataChunkList[5].trim() != '') {
          ConsumerModel consumer = await getConsumersFromCSVData(dataChunkList);
          Common.customLog('~~~~~~~~~~~~>' + consumer.name);
          result = await addConsumer(consumer);
          totalConsumersAdded = totalConsumersAdded + 1;
          Common.customLog("Adding consumer result........." + result);
          callback(totalConsumersToBeAdded, totalConsumersAdded);
        } else {
          Common.customLog("ERROR.........");
          continue;
        }
      }
    } else {
      Common.customLog("SELECTED FILE IS NOT VALID.....");
    }
    Common.customLog("Result........" + result.toString());
    return result;
  }
}
