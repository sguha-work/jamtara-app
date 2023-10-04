import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bentec/models/user.dart';
import 'package:bentec/services/common.dart';
import 'package:bentec/services/custom_notification.dart';
import 'package:bentec/services/permission_service.dart';
import 'package:bentec/services/user_service.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:share/share.dart';
import 'package:path_provider/path_provider.dart';
// importing models
import '../models/report.dart';
import 'file_service.dart';
import 'image_service.dart';
import 'common.dart';
import 'consumer_service.dart';

class ReportService {
  ConsumerService consumerService = ConsumerService();
  String reportsCollectionName = 'collection_reports';
  String reportCacheFileName = 'z09bgy02is2u0zv';
  UserService userService = UserService();
  CustomNotificationService customNotification = CustomNotificationService();
  static bool isListnerAdded = false;

  Future<ReportModel?> getReportDetails(String reportId) async {
    ReportModel? report;
    try {
      await FirebaseFirestore.instance
          .collection(reportsCollectionName)
          .doc(reportId)
          .get()
          .then((DocumentSnapshot document) {
        if (document.exists) {
          report = getModelFromDoc(
              doc: document,
              docId: document.id.toString(),
              createdByName: null,
              isSubmitted: null);
          return report;
        } else {
          return null;
        }
      });
    } catch (e) {
      Common.customLog('__getReportDetails__' + e.toString());
      return null;
    }
    return report;
  }

  Future<Position> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return position;
  }

  Future<List<String>> _uploadReportImagesToFireStore(
      List<String>? imageBase64DataList) async {
    List<String> imageLinks = [];
    if (imageBase64DataList != null) {
      for (String data in imageBase64DataList) {
        String output = await ImageService.uploadBase64ImageToFirebase(
            data, Common.getUniqueId(), 'report_images');
        if (!output.contains('error__')) {
          if (output.contains('success__')) {
            output = output.split('success__').last;
          }
          imageLinks.add(output);
        }
      }
    }
    return imageLinks;
  }

  List<ReportModel> _getReportListFromJSONObj(data) {
    List<ReportModel> reportList = [];
    for (var obj in data) {
      List<String> imageDataList = [];
      for (var imgData in obj['imageBase64StringList']) {
        imageDataList.add(imgData.toString());
      }
      reportList.add(ReportModel(
          division: obj['division'],
          latitude: obj['latitude'] ?? '',
          longitude: obj['longitude'] ?? '',
          consumerNumber: obj['consumerNumber'],
          createdBy: obj['createdBy'],
          createdOn: obj['createdOn'],
          filePathList: [],
          id: '',
          subdivision: obj['subdivision'] ?? '',
          consumerName: obj['consumerName'] ?? '',
          isSubmitted: false,
          consumerAadharNumber: obj['consumerAadharNumber'] ?? '',
          consumerMeterNumber: obj['consumerMeterNumber'] ?? '',
          consumerMobileNumber: obj['consumerMobileNumber'] ?? '',
          imageBase64StringList: imageDataList,
          sealingPageNo: obj['sealingPageNo'] ?? ''));
    }
    return reportList;
  }

  Future<void> saveReportToCache(ReportModel report, Function callback) async {
    // getting data from cache file
    String dataFromFile = await FileService.read(reportCacheFileName);
    String jsonDataToBeWritten = '';
    Position pos = await _getCurrentLocation();
    report.latitude = pos.latitude.toString();
    report.longitude = pos.longitude.toString();
    if (dataFromFile == '') {
      // No data in cache, building new list
      List<ReportModel> reportList = [];
      reportList.add(report);
      jsonDataToBeWritten =
          jsonEncode(reportList.map((e) => e.toJson()).toList());
    } else {
      // cache is available
      final decodedData = jsonDecode(dataFromFile);
      List<ReportModel> reportList = _getReportListFromJSONObj(decodedData);
      var searchArray = reportList
          .where((element) => element.consumerNumber == report.consumerNumber);
      if (searchArray.isEmpty) {
        // data is not available in the cache, appending
        reportList.add(report);
        jsonDataToBeWritten =
            jsonEncode(reportList.map((e) => e.toJson()).toList());
      } else {
        // data is available in the cache, no need to append
      }
    }
    await FileService.write(jsonDataToBeWritten, reportCacheFileName, (result) {
      callback(result);
    });
  }

  Future<String> updateReportToDB(ReportModel report) async {
    try {
      String docId = report.id;
      CollectionReference reportCollectionReference =
          FirebaseFirestore.instance.collection(reportsCollectionName);
      List<String> imageLinks =
          await _uploadReportImagesToFireStore(report.imageBase64StringList);
      Common.customLog('Image Links ---->>>' + imageLinks.toString());
      String result = '';
      result = await reportCollectionReference
          .doc(docId)
          .update({
            "createdOn": report.createdOn,
            "createdBy": report.createdBy,
            "imageLinks": imageLinks.join(','),
            "division": report.division,
            "consumerNumber": report.consumerNumber,
            "latitude": report.latitude,
            "longitude": report.longitude,
            "consumerName": report.consumerName,
            "subdivision": report.subdivision,
            "consumerMobileNumber": report.consumerMobileNumber,
            "consumerMeterNumber": report.consumerMeterNumber,
            "consumerAadharNumber": report.consumerAadharNumber,
            "sealingPageNo": report.sealingPageNo
          })
          .then((value) => 'success__' + docId)
          .catchError((error) => 'error__' + error.toString());

      Common.customLog('RESULT ~~~~~~~> ' + result.toString());
      return result.toString();
    } catch (e) {
      return 'error__';
    }
  }

  Future<void> getReportListForAgent(Function callback) async {
    List<ReportModel> reportListFromFile = await getReportListFromFile();
    try {
      String? agentId = await userService.getCurrentUserId() ?? '';
      if (agentId != null && agentId != '') {
        FirebaseFirestore.instance
            .collection(reportsCollectionName)
            .orderBy('createdOn', descending: true)
            .where('createdBy', isEqualTo: agentId)
            .get()
            .then((QuerySnapshot querySnapshot) {
          List<ReportModel> reportList = [];
          if (querySnapshot.docs.isEmpty) {
            reportList = [];
          } else {
            for (var doc in querySnapshot.docs) {
              ReportModel report = getModelFromDoc(
                  doc: doc,
                  docId: doc.reference.id,
                  createdByName: null,
                  isSubmitted: "true");
              reportList.add(report);
            }
          }
          reportListFromFile.addAll(reportList);
          callback(reportListFromFile);
        });
      }
    } catch (error) {
      callback([]);
    }
  }

  Future<List<ReportModel>> getReportListByAgentIdFromDB(String agentId) async {
    try {
      List<ReportModel> reportList = await FirebaseFirestore.instance
          .collection(reportsCollectionName)
          .orderBy('createdOn', descending: true)
          .where('createdBy', isEqualTo: agentId)
          .get()
          .then((QuerySnapshot querySnapshot) {
        List<ReportModel> reportList = [];
        if (querySnapshot.docs.isEmpty) {
          reportList = [];
        } else {
          for (var doc in querySnapshot.docs) {
            ReportModel report = getModelFromDoc(
                doc: doc,
                docId: doc.reference.id,
                createdByName: null,
                isSubmitted: "true");
            reportList.add(report);
          }
        }
        return reportList;
      });
      return reportList;
    } catch (error) {
      Common.customLog('--------error ' + error.toString());
      return [];
    }
  }

  Future<int> getReportListCountByAgentIdFromDB(String agentId) async {
    try {
      int count = await FirebaseFirestore.instance
          .collection(reportsCollectionName)
          .where('createdBy', isEqualTo: agentId)
          .get()
          .then((QuerySnapshot querySnapshot) {
        List<ReportModel> reportList = [];
        if (querySnapshot.docs.isEmpty) {
          return 0;
        } else {
          return querySnapshot.docs.length;
        }
      });
      return count;
    } catch (error) {
      return 0;
    }
  }

  Future<List<ReportModel>> getReportListForAdmin(String division,
      {DocumentSnapshot? startAt, int limit = 10}) async {
    List<ReportModel> reportList = [];
    try {
      var docs;
      if (division == '') {
        if (startAt == null) {
          docs = await FirebaseFirestore.instance
              .collection(reportsCollectionName)
              .orderBy('createdOn', descending: true)
              .limit(limit)
              .get()
              .then((QuerySnapshot querySnapshot) {
            if (querySnapshot.docs.isEmpty) {
              return [];
            } else {
              return querySnapshot.docs;
            }
          });
        } else {
          docs = await FirebaseFirestore.instance
              .collection(reportsCollectionName)
              .orderBy('createdOn', descending: true)
              .startAt([startAt])
              .limit(limit)
              .get()
              .then((QuerySnapshot querySnapshot) {
                if (querySnapshot.docs.isEmpty) {
                  return [];
                } else {
                  return querySnapshot.docs;
                }
              });
        }
      } else {
        if (startAt == null) {
          docs = await FirebaseFirestore.instance
              .collection(reportsCollectionName)
              .where('division', isEqualTo: division)
              .orderBy('createdOn', descending: true)
              .limit(limit)
              .get()
              .then((QuerySnapshot querySnapshot) {
            if (querySnapshot.docs.isEmpty) {
              return [];
            } else {
              return querySnapshot.docs;
            }
          });
        } else {
          docs = await FirebaseFirestore.instance
              .collection(reportsCollectionName)
              .where('division', isEqualTo: division)
              .orderBy('createdOn', descending: true)
              .startAt([startAt])
              .limit(limit)
              .get()
              .then((QuerySnapshot querySnapshot) {
                if (querySnapshot.docs.isEmpty) {
                  return [];
                } else {
                  return querySnapshot.docs;
                }
              });
        }
      }
      if (docs.isNotEmpty) {
        List<ReportModel> reportList = [];
        for (var doc in docs) {
          String? agentName =
              await userService.getUserNameById(doc['createdBy']);
          ReportModel report = getModelFromDoc(
              doc: doc,
              docId: doc.reference.id,
              createdByName: agentName,
              isSubmitted: null);
          reportList.add(report);
        }
        return reportList;
      }
    } catch (error) {
      reportList = [];
    }
    return reportList;
  }

  Future<List<ReportModel>> getReportListBasedOnDivision(String division) {
    return getReportListForAdmin(division);
  }

  Future<int> getTotalReportCount() async {
    var docs = await FirebaseFirestore.instance
        .collection(reportsCollectionName)
        .get()
        .then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        return [];
      } else {
        return querySnapshot.docs;
      }
    });
    return docs.length;
  }

  Future<int> getTotalReportCountBasedOnDivision(String division) async {
    Common.customLog('Division-----' + division);
    var docs = await FirebaseFirestore.instance
        .collection(reportsCollectionName)
        .where('division', isEqualTo: division)
        .get()
        .then((QuerySnapshot querySnapshot) {
      Common.customLog(
          'Docs length----------' + querySnapshot.docs.length.toString());
      if (querySnapshot.docs.isEmpty) {
        return [];
      } else {
        return querySnapshot.docs;
      }
    });
    return docs.length;
  }

  Future<List<ReportModel>> getReportListFromFile() async {
    List<ReportModel> reportList = [];
    String dataFromFile = await FileService.read(reportCacheFileName);
    if (dataFromFile == '') {
      reportList = [];
    } else {
      // data is in the cache, appending
      final decodedData = jsonDecode(dataFromFile);
      reportList = _getReportListFromJSONObj(decodedData);
    }
    return reportList;
  }

  Future<bool> _checkIfDBEntryExists(
      String currentUserId, ReportModel report) async {
    var docs = await FirebaseFirestore.instance
        .collection(reportsCollectionName)
        .where('createdBy', isEqualTo: currentUserId)
        .where('consumerNumber', isEqualTo: report.consumerNumber)
        .where('consumerName', isEqualTo: report.consumerName)
        .get()
        .then((QuerySnapshot querySnapshot) {
      return querySnapshot.docs;
    });
    if (docs.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  uploadLocalReportDataToDB(Function callback) async {
    List<ReportModel> localReportList = [];
    localReportList = await getReportListFromFile();
    if (localReportList.isNotEmpty) {
      String currentUserId = await userService.getCurrentUserId() ?? '';
      if (currentUserId != '') {
        UserModel? agent = await userService.getUserById(currentUserId);
        WriteBatch writeBatch = FirebaseFirestore.instance.batch();
        CollectionReference reportCollectionReference =
            FirebaseFirestore.instance.collection(reportsCollectionName);
        CollectionReference notificationCollectionReference = FirebaseFirestore
            .instance
            .collection(customNotification.notificationsCollectionName);

        for (ReportModel submittebleReport in localReportList) {
          bool isEntryWrittenToDB =
              await _checkIfDBEntryExists(currentUserId, submittebleReport);
          if (isEntryWrittenToDB) {
            // skipping db write if entry already exists
            Common.customLog('\nREPORT EXISTS IN FIREBASE ----------');
            Common.customLog(
                'CONSUMER NAME ----------' + submittebleReport.consumerName);
            Common.customLog('CONSUMER NUMBER ----------' +
                submittebleReport.consumerNumber);
            Common.customLog(
                'CREATED BY ----------' + submittebleReport.createdBy);
            continue;
          }

          Common.customLog('\nREPORT DOES NOT EXISTS IN FIREBASE ----------');
          Common.customLog(
              'CONSUMER NAME ----------' + submittebleReport.consumerName);
          Common.customLog(
              'CONSUMER NUMBER ----------' + submittebleReport.consumerNumber);
          Common.customLog(
              'CREATED BY ----------' + submittebleReport.createdBy);
          // update meter info to consumer collection
          String status = await consumerService.updateConsumer(
              submittebleReport.consumerNumber,
              submittebleReport.consumerMeterNumber,
              submittebleReport.consumerMobileNumber,
              submittebleReport.consumerAadharNumber);
          // uploading images to firebase and getting the links
          List<String> imageLinks = await _uploadReportImagesToFireStore(
              submittebleReport.imageBase64StringList);
          DocumentReference document =
              reportCollectionReference.doc(Common.getUniqueId());
          DocumentReference notificationDocumentReference =
              notificationCollectionReference.doc(Common.getUniqueId());
          SetOptions options = SetOptions(merge: true);
          writeBatch.set(
              document,
              {
                "createdOn": submittebleReport.createdOn,
                "createdBy": submittebleReport.createdBy,
                //"imageBase64StringList":
                //submittebleReport.imageBase64StringList!.join(','),
                "imageLinks": imageLinks.join(','),
                "division": agent!.division,
                "consumerNumber": submittebleReport.consumerNumber,
                "latitude": submittebleReport.latitude,
                "longitude": submittebleReport.longitude,
                "consumerName": submittebleReport.consumerName,
                "subdivision": submittebleReport.subdivision,
                'consumerMobileNumber': submittebleReport.consumerMobileNumber,
                'consumerMeterNumber': submittebleReport.consumerMeterNumber,
                'consumerAadharNumber': submittebleReport.consumerAadharNumber,
                'sealingPageNo': submittebleReport.sealingPageNo,
              },
              options);
          writeBatch.set(
              notificationDocumentReference,
              {
                "title": "New report added",
                "body": "New report added by " +
                    agent.fullName +
                    ' (agent) in division \n' +
                    agent.division +
                    ' and subdivission ' +
                    submittebleReport.subdivision +
                    ' for \n' +
                    submittebleReport.consumerName +
                    '(' +
                    submittebleReport.consumerNumber +
                    ') on \n' +
                    Common.getFormattedDateTimeFromTimeStamp(
                        submittebleReport.createdOn),
                "data": "",
                "time": DateTime.now().millisecondsSinceEpoch.toString(),
                "type": 'report-added'
              },
              options);
        }
        try {
          writeBatch.commit();
          FileService.write('', reportCacheFileName, (result) {
            callback(result);
          });
        } catch (e) {
          callback(e.toString());
        }
      }
    }
  }

  Future<List<ReportModel>> _getReportList(
      {String division = '', DateTime? startDate, DateTime? endDate}) async {
    var docs;
    if (division == '' && startDate == null && endDate == null) {
      docs = await FirebaseFirestore.instance
          .collection(reportsCollectionName)
          .orderBy('createdOn', descending: true)
          .get()
          .then((QuerySnapshot querySnapshot) {
        if (querySnapshot.docs.isEmpty) {
          return [];
        } else {
          return querySnapshot.docs;
        }
      });
    } else if (division != '' && startDate != null && endDate != null) {
      docs = await FirebaseFirestore.instance
          .collection(reportsCollectionName)
          .orderBy('createdOn', descending: true)
          .where('division', isEqualTo: division)
          .where('createdOn', isGreaterThanOrEqualTo: startDate)
          .where('createdOn', isLessThanOrEqualTo: endDate)
          .get()
          .then((QuerySnapshot querySnapshot) {
        if (querySnapshot.docs.isEmpty) {
          return [];
        } else {
          return querySnapshot.docs;
        }
      });
    }
    if (docs.isEmpty) {
      return [];
    } else {
      List<ReportModel> reportList = [];
      for (var doc in docs) {
        String? agentName = await userService.getUserNameById(doc['createdBy']);
        ReportModel report = getModelFromDoc(
            doc: doc,
            docId: doc.reference.id,
            createdByName: agentName,
            isSubmitted: null);
        reportList.add(report);
      }
      return reportList;
    }
  }

  Future<bool> downloadReportListAsCSV(
      {String division = '', DateTime? startDate, DateTime? endDate}) async {
    await PermissionService.askStoragePermission();
    List<ReportModel> reportList = await _getReportList(
        division: division, startDate: startDate, endDate: endDate);
    if (reportList.isEmpty) {
      // Nothing to right
      return false;
    } else {
      List<List<dynamic>> rows = [];
      rows.add([
        "Agent Name",
        "Agent Phone number",
        "Supervisor Name",
        "Supervisor Mobile",
        "Subdivision",
        "Created On",
        "Region",
        "Consumer Number",
        "Consumer Name",
        "Consumer Aadhar number",
        "Consumer Mobile Number",
        "Meter number",
        "Images"
      ]);
      for (ReportModel report in reportList) {
        String agentName = '';
        String agentPhoneNumber = '';
        String supervisorName = '';
        String supervisorPhoneNumber = '';
        UserModel? agent = await userService.getUserById(report.createdBy);
        if (agent != null) {
          agentName = agent.fullName;
          agentPhoneNumber = agent.phoneNumber;
          UserModel? supervisor =
              await userService.getUserById(agent.createdByUserId);
          if (supervisor != null) {
            supervisorName = supervisor.fullName;
            supervisorPhoneNumber = supervisor.phoneNumber;
          }
        }
        rows.add([
          agentName,
          agentPhoneNumber,
          supervisorName,
          supervisorPhoneNumber,
          report.subdivision,
          Common.getFormattedDateTimeFromTimeStamp(report.createdOn),
          report.division,
          report.consumerName,
          report.consumerAadharNumber,
          report.consumerMobileNumber,
          report.consumerMeterNumber,
          report.imageLinks!.join(',')
        ]);
      }
      String csv = const ListToCsvConverter().convert(rows);
      String timeStamp = DateTime.now().microsecondsSinceEpoch.toString();
      String fileName = 'report-csv' + timeStamp + '.csv';
      FileService.write(csv, fileName, (result) async {
        final Directory directory = await getApplicationDocumentsDirectory();
        final String localPath = '${directory.path}/$fileName';
        Share.shareFiles([localPath], text: 'Todays report');
      });
      return true;
    }
  }

  downloadSpecificReportListAsCSV(
      List<ReportModel> listOfReport, Function callback) async {
    await PermissionService.askStoragePermission();
    List<ReportModel> reportList = listOfReport;
    if (reportList.isEmpty) {
      // Nothing to right
      callback(false);
      // return false;
    } else {
      List<List<dynamic>> rows = [];
      rows.add([
        "Agent Name",
        "Agent Phone number",
        "Supervisor Name",
        "Supervisor Mobile",
        "Subdivision",
        "Created On",
        "Region",
        "Consumer Number",
        "Consumer Name",
        "Consumer Aadhar number",
        "Consumer Mobile Number",
        "Meter number",
        "Latitude",
        "Longitude",
        "Images"
      ]);
      for (ReportModel report in reportList) {
        String agentName = '';
        String agentPhoneNumber = '';
        String supervisorName = '';
        String supervisorPhoneNumber = '';
        UserModel? agent = await userService.getUserById(report.createdBy);
        if (agent != null) {
          agentName = agent.fullName;
          agentPhoneNumber = agent.phoneNumber;
          UserModel? supervisor =
              await userService.getUserById(agent.createdByUserId);
          if (supervisor != null) {
            supervisorName = supervisor.fullName;
            supervisorPhoneNumber = supervisor.phoneNumber;
          }
        }

        String formattedImageLinks = '';
        if (report.imageLinks != null && report.imageLinks!.length == 1) {
          formattedImageLinks =
              Common.getForMattedLinkForCSV(report.imageLinks![0]);
          rows.add([
            agentName,
            agentPhoneNumber,
            supervisorName,
            supervisorPhoneNumber,
            report.subdivision,
            Common.getFormattedDateTimeFromTimeStamp(report.createdOn),
            report.division,
            report.consumerNumber,
            report.consumerName,
            report.consumerAadharNumber,
            report.consumerMobileNumber,
            report.consumerMeterNumber,
            report.latitude,
            report.longitude,
            formattedImageLinks
          ]);
        }
        if (report.imageLinks != null && report.imageLinks!.length > 1) {
          int index = 0;
          for (String link in report.imageLinks ?? []) {
            formattedImageLinks = Common.getForMattedLinkForCSV(link);
            if (index == 0) {
              rows.add([
                agentName,
                agentPhoneNumber,
                supervisorName,
                supervisorPhoneNumber,
                report.subdivision,
                Common.getFormattedDateTimeFromTimeStamp(report.createdOn),
                report.division,
                report.consumerNumber,
                report.consumerName,
                report.consumerAadharNumber,
                report.consumerMobileNumber,
                report.consumerMeterNumber,
                report.latitude,
                report.longitude,
                formattedImageLinks
              ]);
            } else {
              rows.add([
                '',
                '',
                '',
                '',
                '',
                '',
                '',
                '',
                '',
                '',
                '',
                '',
                '',
                '',
                formattedImageLinks
              ]);
            }
            index += 1;
          }
        }
      }
      String csv = const ListToCsvConverter().convert(rows);
      String timeStamp = DateTime.now().microsecondsSinceEpoch.toString();
      String fileName = 'report-csv' + timeStamp + '.csv';
      Common.customLog('-----1');
      FileService.write(csv, fileName, (result) async {
        final Directory directory = await getApplicationDocumentsDirectory();
        final String localPath = '${directory.path}/$fileName';
        Common.customLog('-----3');
        Share.shareFiles([localPath], text: 'Report CSV');
      });
      Common.customLog('-----2');
      callback(true);
    }
  }

  Future<List<ReportModel>> getReportListBasedOnAgent(
      String agentId, DateTime startDate, DateTime endDate) async {
    CollectionReference _colRef =
        FirebaseFirestore.instance.collection(reportsCollectionName);
    Query query = _colRef.where('createdBy', isEqualTo: agentId);
    if (startDate == endDate) {
      Common.customLog('equal...');
      var startOfTheDay =
          DateTime(startDate.year, startDate.month, startDate.day, 0, 1);
      var endOfTheDay =
          DateTime(startDate.year, startDate.month, startDate.day, 23, 59);
      query = _colRef.where('createdOn',
          isGreaterThanOrEqualTo:
              Common.getTimeStampFromDateTime(startOfTheDay));
      query = query.where('createdOn',
          isLessThanOrEqualTo: Common.getTimeStampFromDateTime(endOfTheDay));
    } else {
      Common.customLog('Not equal...');
      query = query.where('createdOn',
          isGreaterThanOrEqualTo: Common.getTimeStampFromDateTime(startDate));
      query = query.where('createdOn',
          isLessThanOrEqualTo: Common.getTimeStampFromDateTime(endDate));
    }
    query = query.orderBy('createdOn', descending: true);
    var docs;
    docs = await query.get().then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        Common.customLog('empty');
        return [];
      } else {
        return querySnapshot.docs;
      }
    }).catchError((e) {
      Common.customLog(e);
      return [];
    });
    if (docs.isEmpty) {
      return [];
    } else {
      List<ReportModel> reportList = [];
      for (var doc in docs) {
        String? agentName = await userService.getUserNameById(doc['createdBy']);
        ReportModel report = getModelFromDoc(
            doc: doc,
            docId: doc.reference.id,
            createdByName: agentName,
            isSubmitted: null);
        reportList.add(report);
      }
      return reportList;
    }
  }

  Future<int> getReportListLengthBasedOnSupervisor(String supervisorId) async {
    List<UserModel>? agentList =
        await userService.getAllAgentBasedOnCreator(supervisorId);
    List<ReportModel> reportList = [];
    int reportListLength = 0;
    if (agentList != null) {
      for (UserModel agent in agentList) {
        var docs;
        docs = await FirebaseFirestore.instance
            .collection(reportsCollectionName)
            .where('createdBy', isEqualTo: agent.id)
            .orderBy('createdOn', descending: true)
            .get()
            .then((QuerySnapshot querySnapshot) {
          if (querySnapshot.docs.isEmpty) {
            return [];
          } else {
            return querySnapshot.docs;
          }
        }).catchError((e) {
          return [];
        });
        if (!docs.isEmpty) {
          for (var _ in docs) {
            reportListLength += 1;
          }
        }
      }
      return reportListLength;
    } else {
      return 0;
    }
  }

  Future<List<ReportModel>> getReportListBasedOnSupervisorFilteredByTime(
      String supervisorId, DateTime startDate, DateTime endDate) async {
    CollectionReference _colRef =
        FirebaseFirestore.instance.collection(reportsCollectionName);

    List<UserModel>? agentList =
        await userService.getAllAgentBasedOnCreator(supervisorId);
    List<ReportModel> reportList = [];
    if (agentList != null) {
      for (UserModel agent in agentList) {
        Query query = _colRef.where('createdBy', isEqualTo: agent.id);
        if (startDate == endDate) {
          Common.customLog('equal...');
          var startOfTheDay =
              DateTime(startDate.year, startDate.month, startDate.day, 0, 1);
          var endOfTheDay =
              DateTime(startDate.year, startDate.month, startDate.day, 23, 59);
          query = _colRef.where('createdOn',
              isGreaterThanOrEqualTo:
                  Common.getTimeStampFromDateTime(startOfTheDay));
          query = query.where('createdOn',
              isLessThanOrEqualTo:
                  Common.getTimeStampFromDateTime(endOfTheDay));
        } else {
          Common.customLog('Not equal...');
          query = query.where('createdOn',
              isGreaterThanOrEqualTo:
                  Common.getTimeStampFromDateTime(startDate));
          query = query.where('createdOn',
              isLessThanOrEqualTo: Common.getTimeStampFromDateTime(endDate));
        }
        query = query.orderBy('createdOn', descending: true);
        var docs;
        docs = await query.get().then((QuerySnapshot querySnapshot) {
          if (querySnapshot.docs.isEmpty) {
            Common.customLog('empty');
            return [];
          } else {
            return querySnapshot.docs;
          }
        }).catchError((e) {
          Common.customLog(e);
          return [];
        });
        if (docs.isEmpty) {
          return [];
        } else {
          for (var doc in docs) {
            String? agentName =
                await userService.getUserNameById(doc['createdBy']);
            ReportModel report = getModelFromDoc(
                doc: doc,
                docId: doc.reference.id,
                createdByName: agentName,
                isSubmitted: null);
            reportList.add(report);
          }
        }
      }
      return reportList;
    } else {
      return [];
    }
  }

  Future<List<ReportModel>> getReportListByAgentPhoneNumber(
      String phoneNumber, DateTime startDate, DateTime endDate) async {
    UserModel? agent = await userService.getUserByPhoneNumber(phoneNumber);
    if (agent != null) {
      String agentId = agent.id;
      return await getReportListBasedOnAgent(agentId, startDate, endDate);
    } else {
      return [];
    }
  }

  Future<List<ReportModel>> getReportListBySupervisorPhoneNumber(
      String phoneNumber, DateTime startDate, DateTime endDate) async {
    UserModel? supervisor = await userService.getUserByPhoneNumber(phoneNumber);
    if (supervisor != null) {
      String supervisorId = supervisor.id;
      return await getReportListBasedOnSupervisorFilteredByTime(
          supervisorId, startDate, endDate);
    } else {
      return [];
    }
  }

  Future<List<ReportModel>> getReportListBasedOnDivisionFilteredByTime(
      String division, DateTime startDate, DateTime endDate) async {
    CollectionReference _colRef =
        FirebaseFirestore.instance.collection(reportsCollectionName);
    Query query = _colRef.where('division', isEqualTo: division);
    if (startDate == endDate) {
      var startOfTheDay =
          DateTime(startDate.year, startDate.month, startDate.day, 0, 1);
      var endOfTheDay =
          DateTime(startDate.year, startDate.month, startDate.day, 23, 59);
      query = _colRef.where('createdOn',
          isGreaterThanOrEqualTo:
              Common.getTimeStampFromDateTime(startOfTheDay));
      query = query.where('createdOn',
          isLessThanOrEqualTo: Common.getTimeStampFromDateTime(endOfTheDay));
    } else {
      query = _colRef.where('createdOn',
          isGreaterThanOrEqualTo: Common.getTimeStampFromDateTime(startDate));
      query = query.where('createdOn',
          isLessThanOrEqualTo: Common.getTimeStampFromDateTime(endDate));
    }
    query = query.orderBy('createdOn', descending: true);
    var docs;
    docs = await query.get().then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        Common.customLog('empty');
        return [];
      } else {
        Common.customLog(
            'Not empty.....' + querySnapshot.docs.length.toString());
        return querySnapshot.docs;
      }
    }).catchError((e) {
      Common.customLog(e);
      return [];
    });
    if (docs.isEmpty) {
      return [];
    } else {
      List<ReportModel> reportList = [];
      for (var doc in docs) {
        String? agentName = await userService.getUserNameById(doc['createdBy']);
        ReportModel report = getModelFromDoc(
            doc: doc,
            docId: doc.reference.id,
            createdByName: agentName,
            isSubmitted: null);
        reportList.add(report);
      }
      return reportList;
    }
  }

  Future<List<ReportModel>> getReportListBasedOnDivisionsFilteredByTime(
      List<String> divisions, DateTime startDate, DateTime endDate) async {
    CollectionReference _colRef =
        FirebaseFirestore.instance.collection(reportsCollectionName);
    Query query = _colRef.where('division', whereIn: divisions);
    if (startDate == endDate) {
      Common.customLog('equal...');
      var startOfTheDay =
          DateTime(startDate.year, startDate.month, startDate.day, 0, 1);
      var endOfTheDay =
          DateTime(startDate.year, startDate.month, startDate.day, 23, 59);
      query = _colRef.where('createdOn',
          isGreaterThanOrEqualTo:
              Common.getTimeStampFromDateTime(startOfTheDay));
      query = query.where('createdOn',
          isLessThanOrEqualTo: Common.getTimeStampFromDateTime(endOfTheDay));
    } else {
      Common.customLog('Not equal...');
      query = query.where('createdOn',
          isGreaterThanOrEqualTo: Common.getTimeStampFromDateTime(startDate));
      query = query.where('createdOn',
          isLessThanOrEqualTo: Common.getTimeStampFromDateTime(endDate));
    }
    query = query.orderBy('createdOn', descending: true);
    var docs;
    docs = await query.get().then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        Common.customLog('empty');
        return [];
      } else {
        return querySnapshot.docs;
      }
    }).catchError((e) {
      Common.customLog(e);
      return [];
    });
    if (docs.isEmpty) {
      return [];
    } else {
      List<ReportModel> reportList = [];
      for (var doc in docs) {
        String? agentName = await userService.getUserNameById(doc['createdBy']);
        ReportModel report = getModelFromDoc(
            doc: doc,
            docId: doc.reference.id,
            createdByName: agentName,
            isSubmitted: null);
        reportList.add(report);
      }
      return reportList;
    }
  }

  Future<List<ReportModel>> getReportListFilteredByTime(
      DateTime startDate, DateTime endDate) async {
    CollectionReference _colRef =
        FirebaseFirestore.instance.collection(reportsCollectionName);
    Query query;
    if (startDate == endDate) {
      var startOfTheDay =
          DateTime(startDate.year, startDate.month, startDate.day, 0, 1);
      var endOfTheDay =
          DateTime(startDate.year, startDate.month, startDate.day, 23, 59);
      query = _colRef.where('createdOn',
          isGreaterThanOrEqualTo:
              Common.getTimeStampFromDateTime(startOfTheDay));
      query = query.where('createdOn',
          isLessThanOrEqualTo: Common.getTimeStampFromDateTime(endOfTheDay));
    } else {
      query = _colRef.where('createdOn',
          isGreaterThanOrEqualTo: Common.getTimeStampFromDateTime(startDate));
      query = query.where('createdOn',
          isLessThanOrEqualTo: Common.getTimeStampFromDateTime(endDate));
    }
    query = query.orderBy('createdOn', descending: true);
    var docs;
    docs = await query.get().then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        Common.customLog('empty');
        return [];
      } else {
        Common.customLog(
            'Not empty.....' + querySnapshot.docs.length.toString());
        return querySnapshot.docs;
      }
    }).catchError((e) {
      Common.customLog(e);
      return [];
    });
    if (docs.isEmpty) {
      return [];
    } else {
      List<ReportModel> reportList = [];
      for (var doc in docs) {
        String? agentName = await userService.getUserNameById(doc['createdBy']);
        ReportModel report = getModelFromDoc(
            doc: doc,
            docId: doc.reference.id,
            createdByName: agentName,
            isSubmitted: null);
        reportList.add(report);
      }
      return reportList;
    }
  }

  Future<String> deleteReport(ReportModel report) async {
    CollectionReference divisionsCollectionReference =
        FirebaseFirestore.instance.collection(reportsCollectionName);
    String result = '';
    result = await divisionsCollectionReference
        .doc(report.id)
        .delete()
        .then((value) {
      return 'success__';
    }).catchError((error) {
      return 'error__' + error.toString();
    });
    return result;
  }

  ReportModel getModelFromDoc(
      {dynamic doc,
      required String docId,
      String? createdByName,
      String? isSubmitted}) {
    ReportModel model = ReportModel(
        consumerName: doc.data().toString().contains('consumerName')
            ? doc.get('consumerName')
            : '',
        subdivision: doc.data().toString().contains('subdivision')
            ? doc.get('subdivision')
            : '',
        division: doc.data().toString().contains('division')
            ? doc.get('division')
            : '',
        imageLinks: (doc.data().toString().contains('imageLinks')
                ? doc.get('imageLinks')
                : '')
            .split(','),
        createdOn: doc.data().toString().contains('createdOn')
            ? doc.get('createdOn')
            : 0,
        createdBy: doc.data().toString().contains('createdBy')
            ? doc.get('createdBy')
            : '',
        consumerNumber: doc.data().toString().contains('consumerNumber')
            ? doc.get('consumerNumber')
            : '',
        latitude: doc.data().toString().contains('latitude')
            ? doc.get('latitude')
            : '',
        longitude: doc.data().toString().contains('longitude')
            ? doc.get('longitude')
            : '',
        consumerAadharNumber:
            doc.data().toString().contains('consumerAadharNumber')
                ? doc.get('consumerAadharNumber')
                : '',
        consumerMeterNumber:
            doc.data().toString().contains('consumerMeterNumber')
                ? doc.get('consumerMeterNumber')
                : '',
        consumerMobileNumber:
            doc.data().toString().contains('consumerMobileNumber')
                ? doc.get('consumerMobileNumber')
                : '',
        id: docId,
        sealingPageNo: doc.data().toString().contains('sealingPageNo')
            ? doc.get('sealingPageNo')
            : '');
    if (createdByName != null) {
      model.createdByName = createdByName;
    }
    if (isSubmitted != null) {
      model.isSubmitted = isSubmitted == "true" ? true : false;
    }
    return model;
  }
}
