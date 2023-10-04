// Importing Firebase packages
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'custom_notification.dart';
import 'file_service.dart';
import 'image_service.dart';
import 'parse_csv.dart';
// import common
import 'common.dart';

// importing models
import '../models/user.dart';

class UserService {
  FirebaseAuth auth = FirebaseAuth.instance;

  final String _usersCollectionName = 'collection_users';
  final String userInfoCacheFileName =
      'cache_user_info'; // this file will be deleted on logout
  Future<String> register(email, password) async {
    email = email.trim();
    password = password.trim();
    if (password == '') {
      return 'error__empty-password';
    }
    if (Common.isValidEmail(email)) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        final User userData = userCredential.user!;
        return 'success__' + userData.uid;
      } on FirebaseAuthException catch (e) {
        //'weak-password','email-already-in-use'
        return 'error__' + e.code;
      } catch (e) {
        return 'error__' + e.toString();
      }
    } else {
      return 'error__invalid-email';
    }
  }

  Future<String?> getCurrentUserId() async {
    //trying to get user data from saved file
    String dataFromFile = await FileService.read(userInfoCacheFileName);
    if (dataFromFile != '') {
      try {
        Map<String, dynamic> jsonData = jsonDecode(dataFromFile);
        UserModel user = UserModel.fromJson(jsonData);
        return user.id;
      } catch (e) {
        return '';
      }
    } else {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return user.uid;
      } else {
        return null;
      }
    }
  }

  Future<String> signIn(String email, String password) async {
    email = email.trim();
    password = password.trim();
    if (password == '') {
      return 'error_empty-password';
    }
    if (Common.isValidEmail(email)) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        final User userData = userCredential.user!;
        UserModel? userDataFromDB = await getUserById(userData.uid);
        if (userDataFromDB != null) {
          String jsonDataToBeWritten = jsonEncode(userDataFromDB.toJson());
          FileService.write(
              jsonDataToBeWritten, userInfoCacheFileName, (String result) {});
        }
        return 'success__' + userData.uid;
      } on FirebaseAuthException catch (e) {
        //weak-password,email-already-in-use
        return ('error__' + e.code);
      } catch (e) {
        return ('error__' + e.toString());
      }
    } else {
      return 'error__invalid-email';
    }
  }

  Future<List<UserModel>?> getAllAdminsCreatedBySuperAdmin() async {
    List<UserModel>? listOfAdmins = await getAllAdmins();
    return listOfAdmins;
  }

  Future<List<UserModel>?> getAllAdmins() async {
    List<UserModel> adminList = [];
    try {
      await FirebaseFirestore.instance
          .collection(_usersCollectionName)
          .where('userType', isEqualTo: 'admin')
          .get()
          .then((QuerySnapshot querySnapshot) {
        for (var doc in querySnapshot.docs) {
          UserModel user = UserModel(
              id: doc.reference.id.toString(),
              email: doc.data().toString().contains("email")
                  ? doc.get("email")
                  : '',
              phoneNumber: doc.data().toString().contains("phoneNumber")
                  ? doc.get("phoneNumber")
                  : '',
              userType: doc.data().toString().contains("userType")
                  ? doc.get("userType")
                  : '',
              createdOn: doc.data().toString().contains("createdOn")
                  ? doc.get("createdOn")
                  : '',
              fullName: doc.data().toString().contains("fullName")
                  ? doc.get("fullName")
                  : '',
              dateOfBirth: doc.data().toString().contains("dateOfBirth")
                  ? doc.get("dateOfBirth")
                  : '',
              divisions: doc.data().toString().contains("divisions")
                  ? (doc.get("divisions").cast<String>() ?? [])
                  : [],
              imageFilePath: doc.data().toString().contains("imagePath")
                  ? ((doc.get("imagePath") != null &&
                          doc.get("imagePath") != "")
                      ? doc.get("imagePath")
                      : "")
                  : "");
          adminList.add(user);
        }
      });

      return adminList;
    } catch (e) {
      return null;
    }
  }

  // Future<List<UserModel>?> getAllSupervisorBasedOnRegion(
  //     {String division = ''}) async {
  //   List<UserModel> usersList = [];
  //   try {
  //     if (division == '') {
  //       await FirebaseFirestore.instance
  //           .collection(_usersCollectionName)
  //           .where('userType', isEqualTo: 'supervisor')
  //           .get()
  //           .then((QuerySnapshot querySnapshot) {
  //         for (var doc in querySnapshot.docs) {
  //           UserModel user = UserModel(
  //               fullName: doc.data().toString().contains("fullName")
  //                   ? doc.get("fullName")
  //                   : '',
  //               dateOfBirth: doc.data().toString().contains("dateOfBirth")
  //                   ? doc.get("dateOfBirth")
  //                   : '',
  //               email: doc.data().toString().contains("email")
  //                   ? doc.get("email")
  //                   : '',
  //               phoneNumber: doc.data().toString().contains("phoneNumber")
  //                   ? doc.get("phoneNumber")
  //                   : '',
  //               userType: doc.data().toString().contains("userType")
  //                   ? doc.get("userType")
  //                   : '',
  //               division: doc.data().toString().contains("division")
  //                   ? doc.get("division")
  //                   : '',
  //               area: doc.data().toString().contains("area")
  //                   ? doc.get("area")
  //                   : '',
  //               city: doc.data().toString().contains("city")
  //                   ? doc.get("city")
  //                   : '',
  //               pin:
  //                   doc.data().toString().contains("pin") ? doc.get("pin") : '',
  //               state: doc.data().toString().contains("state")
  //                   ? doc.get("state")
  //                   : '',
  //               panNumber: doc.data().toString().contains("panNumber")
  //                   ? doc.get("panNumber")
  //                   : '',
  //               aadharNumber: doc.data().toString().contains("aadharNumber")
  //                   ? doc.get("aadharNumber")
  //                   : '',
  //               isApprovedByAdmin:
  //                   doc.data().toString().contains("isApprovedByAdmin")
  //                       ? doc.get("isApprovedByAdmin")
  //                       : '',
  //               createdOn: doc.data().toString().contains("createdOn")
  //                   ? doc.get("createdOn")
  //                   : '',
  //               approvedOn: doc.data().toString().contains("approvedOn")
  //                   ? doc.get("approvedOn")
  //                   : '');
  //           usersList.add(user);
  //         }
  //       });
  //     } else {
  //       await FirebaseFirestore.instance
  //           .collection(_usersCollectionName)
  //           .where('division', isEqualTo: division)
  //           .where('userType', isEqualTo: 'supervisor')
  //           .get()
  //           .then((QuerySnapshot querySnapshot) {
  //         for (var doc in querySnapshot.docs) {
  //           UserModel user = UserModel(
  //               fullName: doc.data().toString().contains("fullName")
  //                   ? doc.get("fullName")
  //                   : '',
  //               dateOfBirth: doc.data().toString().contains("dateOfBirth")
  //                   ? doc.get("dateOfBirth")
  //                   : '',
  //               email: doc.data().toString().contains("email")
  //                   ? doc.get("email")
  //                   : '',
  //               phoneNumber: doc.data().toString().contains("phoneNumber")
  //                   ? doc.get("phoneNumber")
  //                   : '',
  //               userType: doc.data().toString().contains("userType")
  //                   ? doc.get("userType")
  //                   : '',
  //               division: doc.data().toString().contains("division")
  //                   ? doc.get("division")
  //                   : '',
  //               area: doc.data().toString().contains("area")
  //                   ? doc.get("area")
  //                   : '',
  //               city: doc.data().toString().contains("city")
  //                   ? doc.get("city")
  //                   : '',
  //               pin:
  //                   doc.data().toString().contains("pin") ? doc.get("pin") : '',
  //               state: doc.data().toString().contains("state")
  //                   ? doc.get("state")
  //                   : '',
  //               panNumber: doc.data().toString().contains("panNumber")
  //                   ? doc.get("panNumber")
  //                   : '',
  //               aadharNumber: doc.data().toString().contains("aadharNumber")
  //                   ? doc.get("aadharNumber")
  //                   : '',
  //               isApprovedByAdmin:
  //                   doc.data().toString().contains("isApprovedByAdmin")
  //                       ? doc.get("isApprovedByAdmin")
  //                       : '',
  //               createdOn: doc.data().toString().contains("createdOn")
  //                   ? doc.get("createdOn")
  //                   : '',
  //               approvedOn: doc.data().toString().contains("approvedOn")
  //                   ? doc.get("approvedOn")
  //                   : '');
  //           usersList.add(user);
  //         }
  //       });
  //     }
  //     return usersList;
  //   } catch (e) {
  //     return null;
  //   }
  // }

  Future<List<UserModel>?> getAllSupervisorBasedOnDivision(
      String division) async {
    List<UserModel>? listOfSupervisor = await getAllUserBasedOnDivision(
        userType: 'supervisor', division: division);
    return listOfSupervisor;
  }

  Future<List<UserModel>?> getAllSupervisor() async {
    List<UserModel>? listOfSupervisor =
        await getAllUser(userType: 'supervisor');
    return listOfSupervisor;
  }

  Future<List<DocumentSnapshot<Object?>>> getAllSupervisorsWithPagination(
      int pageLength,
      {DocumentSnapshot? startAfter,
      String? division}) async {
    Common.customLog('getAllSupervisorsWithPagination() is called.....');
    CollectionReference _colRef =
        FirebaseFirestore.instance.collection(_usersCollectionName);
    Query _query = _colRef.where('userType', isEqualTo: 'supervisor');
    List<DocumentSnapshot> docs;
    if (startAfter == null) {
      _query = _query.limit(pageLength);
      if (division != null) {
        _query = _query.where('division', isEqualTo: division);
      }
      docs = await _query.get().then((QuerySnapshot querySnapshot) {
        return querySnapshot.docs;
      }).catchError((error) {
        return [];
      });
    } else {
      _query = _query.limit(pageLength);
      if (division != null) {
        _query = _query.where('division', isEqualTo: division);
      }
      docs = await _query
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

  Future<int> getAllSupervisorCount(String? division) async {
    int supervisorCount = 0;
    CollectionReference _colRef =
        FirebaseFirestore.instance.collection(_usersCollectionName);
    Query query = _colRef.where('userType', isEqualTo: 'supervisor');
    if (division != null) {
      query = query.where('division', isEqualTo: division);
    }
    await query.get().then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        supervisorCount = 0;
      } else {
        supervisorCount = querySnapshot.docs.length;
      }
    });
    return supervisorCount;
  }
  /*
  CollectionReference _colRef =
          FirebaseFirestore.instance.collection(_usersCollectionName);
      Query query = _colRef.orderBy('createdOn', descending: true);
      query = query.where('userType', isEqualTo: userType);
      if (divisions.isNotEmpty) {
        query = query.where('division', whereIn: divisions);
      }
   */

  Future<List<UserModel>?> getAllAgent(String? currentUserId) async {
    if (currentUserId != null) {
      List<UserModel>? listOfAgent =
          await getAllAgentBasedOnCreator(currentUserId);
      return listOfAgent;
    } else {
      List<UserModel>? listOfAgent = await getAllUser(userType: 'agent');
      return listOfAgent;
    }
  }

  Future<List<UserModel>?>? getAllAgentBasedOnCreator(
      String supervisorId) async {
    List<UserModel> usersList = [];
    try {
      await FirebaseFirestore.instance
          .collection(_usersCollectionName)
          .where('userType', isEqualTo: 'agent')
          .where('createdByUserId', isEqualTo: supervisorId)
          .get()
          .then((QuerySnapshot querySnapshot) {
        for (var doc in querySnapshot.docs) {
          UserModel user = UserModel(
              id: doc.reference.id.toString(),
              fullName: doc.data().toString().contains("fullName")
                  ? doc.get("fullName")
                  : '',
              dateOfBirth: doc.data().toString().contains("dateOfBirth")
                  ? doc.get("dateOfBirth")
                  : '',
              email: doc.data().toString().contains("email")
                  ? doc.get("email")
                  : '',
              phoneNumber: doc.data().toString().contains("phoneNumber")
                  ? doc.get("phoneNumber")
                  : '',
              userType: doc.data().toString().contains("userType")
                  ? doc.get("userType")
                  : '',
              division: doc.data().toString().contains("division")
                  ? doc.get("division")
                  : '',
              area:
                  doc.data().toString().contains("area") ? doc.get("area") : '',
              city:
                  doc.data().toString().contains("city") ? doc.get("city") : '',
              pin: doc.data().toString().contains("pin") ? doc.get("pin") : '',
              state: doc.data().toString().contains("state")
                  ? doc.get("state")
                  : '',
              panNumber: doc.data().toString().contains("panNumber")
                  ? doc.get("panNumber")
                  : '',
              aadharNumber: doc.data().toString().contains("aadharNumber")
                  ? doc.get("aadharNumber")
                  : '',
              isApprovedByAdmin:
                  doc.data().toString().contains("isApprovedByAdmin")
                      ? doc.get("isApprovedByAdmin")
                      : '',
              isRejectedByAdmin:
                  doc.data().toString().contains("isRejectedByAdmin")
                      ? doc.get("isRejectedByAdmin")
                      : '',
              createdOn: doc.data().toString().contains("createdOn")
                  ? doc.get("createdOn")
                  : '',
              approvedOn: doc.data().toString().contains("approvedOn")
                  ? doc.get("approvedOn")
                  : '',
              imageFilePath: doc.data().toString().contains("imagePath")
                  ? ((doc.get("imagePath") != null &&
                          doc.get("imagePath") != "")
                      ? doc.get("imagePath")
                      : "")
                  : "");

          usersList.add(user);
        }
      });
      return usersList;
    } catch (e) {
      return null;
    }
  }

  Future<List<UserModel>?> getAllUserBasedOnDivision(
      {String userType = '', String division = ''}) async {
    Common.customLog('---->' + userType);
    Common.customLog('---->' + division);
    List<UserModel> usersList = [];
    try {
      await FirebaseFirestore.instance
          .collection(_usersCollectionName)
          .where('division', isEqualTo: division)
          .where('userType', isEqualTo: userType)
          .get()
          .then((QuerySnapshot querySnapshot) {
        for (var doc in querySnapshot.docs) {
          Common.customLog('----' + doc.reference.id.toString());
          Common.customLog('----' + doc['userType']);
          UserModel user = UserModel(
              id: doc.reference.id.toString(),
              fullName: doc.data().toString().contains("fullName")
                  ? doc.get("fullName")
                  : '',
              dateOfBirth: doc.data().toString().contains("dateOfBirth")
                  ? doc.get("dateOfBirth")
                  : '',
              email: doc.data().toString().contains("email")
                  ? doc.get("email")
                  : '',
              phoneNumber: doc.data().toString().contains("phoneNumber")
                  ? doc.get("phoneNumber")
                  : '',
              userType: doc.data().toString().contains("userType")
                  ? doc.get("userType")
                  : '',
              division: doc.data().toString().contains("division")
                  ? doc.get("division")
                  : '',
              area:
                  doc.data().toString().contains("area") ? doc.get("area") : '',
              city:
                  doc.data().toString().contains("city") ? doc.get("city") : '',
              pin: doc.data().toString().contains("pin") ? doc.get("pin") : '',
              state: doc.data().toString().contains("state")
                  ? doc.get("state")
                  : '',
              panNumber: doc.data().toString().contains("panNumber")
                  ? doc.get("panNumber")
                  : '',
              aadharNumber: doc.data().toString().contains("aadharNumber")
                  ? doc.get("aadharNumber")
                  : '',
              isApprovedByAdmin:
                  doc.data().toString().contains("isApprovedByAdmin")
                      ? doc.get("isApprovedByAdmin")
                      : '',
              isRejectedByAdmin:
                  doc.data().toString().contains("isRejectedByAdmin")
                      ? doc.get("isRejectedByAdmin")
                      : '',
              createdOn: doc.data().toString().contains("createdOn")
                  ? doc.get("createdOn")
                  : '',
              approvedOn: doc.data().toString().contains("approvedOn")
                  ? doc.get("approvedOn")
                  : '',
              imageFilePath: doc.data().toString().contains("imagePath")
                  ? ((doc.get("imagePath") != null &&
                          doc.get("imagePath") != "")
                      ? doc.get("imagePath")
                      : "")
                  : "");
          usersList.add(user);
        }
      });

      return usersList;
    } catch (e) {
      return null;
    }
  }

  Future<List<UserModel>?> getAllUser(
      {String userType = '', String division = ''}) async {
    List<UserModel> usersList = [];
    try {
      await FirebaseFirestore.instance
          .collection(_usersCollectionName)
          .where('userType', isEqualTo: userType)
          .get()
          .then((QuerySnapshot querySnapshot) {
        for (var doc in querySnapshot.docs) {
          Common.customLog('----~~>' + doc.reference.id.toString());
          UserModel user = UserModel(
              id: doc.reference.id.toString(),
              fullName: doc.data().toString().contains("fullName")
                  ? doc.get("fullName")
                  : '',
              dateOfBirth: doc.data().toString().contains("dateOfBirth")
                  ? doc.get("dateOfBirth")
                  : '',
              email: doc.data().toString().contains("email")
                  ? doc.get("email")
                  : '',
              phoneNumber: doc.data().toString().contains("phoneNumber")
                  ? doc.get("phoneNumber")
                  : '',
              userType: doc.data().toString().contains("userType")
                  ? doc.get("userType")
                  : '',
              division: doc.data().toString().contains("division")
                  ? doc.get("division")
                  : '',
              area:
                  doc.data().toString().contains("area") ? doc.get("area") : '',
              city:
                  doc.data().toString().contains("city") ? doc.get("city") : '',
              pin: doc.data().toString().contains("pin") ? doc.get("pin") : '',
              state: doc.data().toString().contains("state")
                  ? doc.get("state")
                  : '',
              panNumber: doc.data().toString().contains("panNumber")
                  ? doc.get("panNumber")
                  : '',
              aadharNumber: doc.data().toString().contains("aadharNumber")
                  ? doc.get("aadharNumber")
                  : '',
              isApprovedByAdmin:
                  doc.data().toString().contains("isApprovedByAdmin")
                      ? doc.get("isApprovedByAdmin")
                      : '',
              isRejectedByAdmin:
                  doc.data().toString().contains("isRejectedByAdmin")
                      ? doc.get("isRejectedByAdmin")
                      : '',
              createdOn: doc.data().toString().contains("createdOn")
                  ? doc.get("createdOn")
                  : '',
              approvedOn: doc.data().toString().contains("approvedOn")
                  ? doc.get("approvedOn")
                  : '',
              imageFilePath: doc.data().toString().contains("imagePath")
                  ? ((doc.get("imagePath") != null &&
                          doc.get("imagePath") != "")
                      ? doc.get("imagePath")
                      : "")
                  : "");
          usersList.add(user);
        }
      });

      return usersList;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isPhoeNumberExists(String phoneNumber) async {
    bool result = await FirebaseFirestore.instance
        .collection(_usersCollectionName)
        .where('phoneNumber', isEqualTo: phoneNumber)
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

  Future<String> addSupervisor(UserModel user) async {
    bool isPhoneNumberExists = await isPhoeNumberExists(user.phoneNumber);
    if (isPhoneNumberExists) {
      return 'error__phonenumber-already-in-use';
    }
    String registrationResult = await register(user.email, user.password);
    if (registrationResult.contains('error__')) {
      return registrationResult;
    }
    String userId = registrationResult.split('success__').last;
    String imagePath = '';
    try {
      if (user.imageFile != null) {
        String result = await ImageService.uploadImageToFirebase(
            user.imageFile, userId, 'profilepics');
        if (result.contains('error__')) {
          return result;
        } else {
          imagePath = result.split('success__').last;
        }
      }
    } catch (exception) {
      imagePath = '';
    }
    CollectionReference usersCollectionReference =
        FirebaseFirestore.instance.collection(_usersCollectionName);
    String result = '';
    result = await usersCollectionReference.doc(userId).set({
      'dateOfBirth': user.dateOfBirth,
      'fullName': user.fullName,
      'email': user.email,
      'phoneNumber': user.phoneNumber,
      'userType': user.userType,
      'division': user.division,
      'area': user.area,
      'city': user.city,
      'pin': user.pin,
      'state': user.state,
      'panNumber': user.panNumber,
      'aadharNumber': user.aadharNumber,
      'isApprovedByAdmin': user.isApprovedByAdmin,
      'isRejectedByAdmin': user.isRejectedByAdmin,
      'isApprovedBySuperAdmin': user.isApprovedBySuperAdmin,
      'isRejectedBySuperAdmin': user.isRejectedBySuperAdmin,
      'approvedByUserId': user.approvedByUserId,
      'createdOn': user.createdOn,
      'createdByUserId': user.createdByUserId,
      'approvedOn': user.approvedOn,
      'imagePath': imagePath
    }).then((value) {
      if (user.userType == 'agent') {
        // making notification entry for agent addition
        CustomNotificationService notification = CustomNotificationService();
        notification.makeNotificationEntryToDB(
            'agent-added',
            'New agent added',
            'A new agent named ' +
                user.fullName +
                ' is added on ' +
                Common.getFormattedDateTimeFromTimeStamp(
                    int.parse(user.createdOn)) +
                ' in region ' +
                user.division,
            '',
            () {});
      }
      return 'success__' + userId;
    }).catchError((error) => 'error__' + error.toString());
    return result.toString();
  }

  Future<String> addUser(UserModel user) async {
    bool isPhoneNumberExists = await isPhoeNumberExists(user.phoneNumber);
    if (isPhoneNumberExists) {
      return 'error__phonenumber-already-in-use';
    }
    String registrationResult = await register(user.email, user.password);
    if (registrationResult.contains('error__')) {
      return registrationResult;
    }
    String userId = registrationResult.split('success__').last;
    String imagePath = '';
    try {
      if (user.imageFile != null) {
        String result = await ImageService.uploadImageToFirebase(
            user.imageFile, userId, 'profilepics');
        if (result.contains('error__')) {
          return result;
        } else {
          imagePath = result.split('success__').last;
        }
      }
    } catch (exception) {
      imagePath = '';
    }
    CollectionReference usersCollectionReference =
        FirebaseFirestore.instance.collection(_usersCollectionName);
    String result = '';
    result = await usersCollectionReference.doc(userId).set({
      'dateOfBirth': user.dateOfBirth,
      'fullName': user.fullName,
      'email': user.email,
      'phoneNumber': user.phoneNumber,
      'userType': user.userType,
      'division': user.division,
      'area': user.area,
      'city': user.city,
      'pin': user.pin,
      'state': user.state,
      'panNumber': user.panNumber,
      'aadharNumber': user.aadharNumber,
      'isApprovedByAdmin': user.isApprovedByAdmin,
      'isRejectedByAdmin': user.isRejectedByAdmin,
      'approvedByUserId': user.approvedByUserId,
      'createdOn': user.createdOn,
      'createdByUserId': user.createdByUserId,
      'approvedOn': user.approvedOn,
      'imagePath': imagePath
    }).then((value) {
      if (user.userType == 'agent') {
        // making notification entry for agent addition
        CustomNotificationService notification = CustomNotificationService();
        notification.makeNotificationEntryToDB(
            'agent-added',
            'New agent added',
            'A new agent named ' +
                user.fullName +
                ' is added on ' +
                Common.getFormattedDateTimeFromTimeStamp(
                    int.parse(user.createdOn)) +
                ' in region ' +
                user.division,
            '',
            () {});
      }
      return 'success__' + userId;
    }).catchError((error) => 'error__' + error.toString());
    return result.toString();
  }

  Future<String> addAdmin(UserModel user) async {
    bool isPhoneNumberExists = await isPhoeNumberExists(user.phoneNumber);
    if (isPhoneNumberExists) {
      return 'error__phonenumber-already-in-use';
    }
    String registrationResult = await register(user.email, user.password);
    if (registrationResult.contains('error__')) {
      return registrationResult;
    }
    String userId = registrationResult.split('success__').last;
    String imagePath = '';
    try {
      if (user.imageFile != null) {
        String result = await ImageService.uploadImageToFirebase(
            user.imageFile, userId, 'profilepics');
        if (result.contains('error__')) {
          return result;
        } else {
          imagePath = result.split('success__').last;
        }
      }
    } catch (exception) {
      imagePath = '';
    }
    CollectionReference usersCollectionReference =
        FirebaseFirestore.instance.collection(_usersCollectionName);
    String result = '';
    result = await usersCollectionReference.doc(userId).set({
      'dateOfBirth': user.dateOfBirth,
      'fullName': user.fullName,
      'email': user.email,
      'phoneNumber': user.phoneNumber,
      'userType': user.userType,
      'createdOn': user.createdOn,
      'createdByUserId': user.createdByUserId,
      'imagePath': imagePath,
      'divisions': user.divisions
    }).then((value) {
      return 'success__' + userId;
    }).catchError((error) => 'error__' + error.toString());
    return result.toString();
  }

  Future<List<UserModel>?> getUserListForAdminWithApprovalStatus(
      String userType, List<String> divisions) async {
    Common.customLog('userType......' + userType);
    Common.customLog('Divisions of admin......' + divisions.toString());
    List<UserModel> usersList = [];
    try {
      CollectionReference _colRef =
          FirebaseFirestore.instance.collection(_usersCollectionName);
      Query query = _colRef.orderBy('createdOn', descending: true);
      query = query.where('userType', isEqualTo: userType);
      if (divisions.isNotEmpty) {
        query = query.where('division', whereIn: divisions);
      }

      await query.get().then((QuerySnapshot querySnapshot) {
        Common.customLog(
            'querySnapshot.docs......' + querySnapshot.docs.length.toString());
        if (querySnapshot.docs.isEmpty) {
          return null;
        }
        for (var doc in querySnapshot.docs) {
          UserModel user = UserModel(
              id: doc.reference.id.toString(),
              fullName: doc.data().toString().contains("fullName")
                  ? doc.get("fullName")
                  : '',
              dateOfBirth: doc.data().toString().contains("dateOfBirth")
                  ? doc.get("dateOfBirth")
                  : '',
              email: doc.data().toString().contains("email")
                  ? doc.get("email")
                  : '',
              phoneNumber: doc.data().toString().contains("phoneNumber")
                  ? doc.get("phoneNumber")
                  : '',
              userType: doc.data().toString().contains("userType")
                  ? doc.get("userType")
                  : '',
              division: doc.data().toString().contains("division")
                  ? doc.get("division")
                  : '',
              area:
                  doc.data().toString().contains("area") ? doc.get("area") : '',
              city:
                  doc.data().toString().contains("city") ? doc.get("city") : '',
              pin: doc.data().toString().contains("pin") ? doc.get("pin") : '',
              state: doc.data().toString().contains("state")
                  ? doc.get("state")
                  : '',
              panNumber: doc.data().toString().contains("panNumber")
                  ? doc.get("panNumber")
                  : '',
              aadharNumber: doc.data().toString().contains("aadharNumber")
                  ? doc.get("aadharNumber")
                  : '',
              isApprovedByAdmin:
                  doc.data().toString().contains("isApprovedByAdmin")
                      ? doc.get("isApprovedByAdmin")
                      : '',
              isRejectedByAdmin:
                  doc.data().toString().contains("isRejectedByAdmin")
                      ? doc.get("isRejectedByAdmin")
                      : '',
              createdOn: doc.data().toString().contains("createdOn")
                  ? doc.get("createdOn")
                  : '',
              approvedOn: doc.data().toString().contains("approvedOn")
                  ? doc.get("approvedOn")
                  : '',
              createdByUserId: doc.data().toString().contains("createdByUserId")
                  ? doc.get("createdByUserId")
                  : '',
              imageFilePath: doc.data().toString().contains("imagePath")
                  ? ((doc.get("imagePath") != null &&
                          doc.get("imagePath") != "")
                      ? doc.get("imagePath")
                      : "")
                  : "");
          usersList.add(user);
        }
      });
      return usersList;
    } catch (e) {
      Common.customLog('ERROR_getUserListWithApprovalStatus_' + e.toString());
      return null;
    }
  }

  Future<List<UserModel>?> getUserListForSuperAdminWithApprovalStatus(
      String userType, List<String> divisions) async {
    Common.customLog('userType......' + userType);
    Common.customLog('Divisions of admin......' + divisions.toString());
    List<UserModel> usersList = [];
    try {
      CollectionReference _colRef =
          FirebaseFirestore.instance.collection(_usersCollectionName);
      Query query = _colRef.orderBy('createdOn', descending: true);
      query = query.where('userType', isEqualTo: userType);
      if (divisions.isNotEmpty) {
        query = query.where('division', whereIn: divisions);
      }

      await query.get().then((QuerySnapshot querySnapshot) {
        Common.customLog(
            'querySnapshot.docs......' + querySnapshot.docs.length.toString());
        if (querySnapshot.docs.isEmpty) {
          return null;
        }
        for (var doc in querySnapshot.docs) {
          UserModel user = UserModel(
              id: doc.reference.id.toString(),
              fullName: doc.data().toString().contains("fullName")
                  ? doc.get("fullName")
                  : '',
              dateOfBirth: doc.data().toString().contains("dateOfBirth")
                  ? doc.get("dateOfBirth")
                  : '',
              email: doc.data().toString().contains("email")
                  ? doc.get("email")
                  : '',
              phoneNumber: doc.data().toString().contains("phoneNumber")
                  ? doc.get("phoneNumber")
                  : '',
              userType: doc.data().toString().contains("userType")
                  ? doc.get("userType")
                  : '',
              division: doc.data().toString().contains("division")
                  ? doc.get("division")
                  : '',
              area:
                  doc.data().toString().contains("area") ? doc.get("area") : '',
              city:
                  doc.data().toString().contains("city") ? doc.get("city") : '',
              pin: doc.data().toString().contains("pin") ? doc.get("pin") : '',
              state: doc.data().toString().contains("state")
                  ? doc.get("state")
                  : '',
              panNumber: doc.data().toString().contains("panNumber")
                  ? doc.get("panNumber")
                  : '',
              aadharNumber: doc.data().toString().contains("aadharNumber")
                  ? doc.get("aadharNumber")
                  : '',
              isApprovedBySuperAdmin:
                  doc.data().toString().contains("isApprovedBySuperAdmin")
                      ? doc.get("isApprovedBySuperAdmin")
                      : '',
              isRejectedBySuperAdmin:
                  doc.data().toString().contains("isRejectedBySuperAdmin")
                      ? doc.get("isRejectedBySuperAdmin")
                      : '',
              createdOn: doc.data().toString().contains("createdOn")
                  ? doc.get("createdOn")
                  : '',
              approvedOn: doc.data().toString().contains("approvedOn")
                  ? doc.get("approvedOn")
                  : '',
              createdByUserId: doc.data().toString().contains("createdByUserId")
                  ? doc.get("createdByUserId")
                  : '',
              imageFilePath: doc.data().toString().contains("imagePath")
                  ? ((doc.get("imagePath") != null &&
                          doc.get("imagePath") != "")
                      ? doc.get("imagePath")
                      : "")
                  : "");
          usersList.add(user);
        }
      });
      return usersList;
    } catch (e) {
      Common.customLog('ERROR_getUserListWithApprovalStatus_' + e.toString());
      return null;
    }
  }

  Future<UserModel?> getUserById(String id) async {
    UserModel? user;
    try {
      user = await FirebaseFirestore.instance
          .collection(_usersCollectionName)
          .doc(id)
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          if (documentSnapshot.get('userType') == 'superadmin') {
            user = UserModel(
              id: documentSnapshot.id.toString(),
              email: documentSnapshot.data().toString().contains("email")
                  ? documentSnapshot.get("email")
                  : "",
              phoneNumber:
                  documentSnapshot.data().toString().contains("phoneNumber")
                      ? documentSnapshot.get("phoneNumber")
                      : "",
              userType: documentSnapshot.data().toString().contains("userType")
                  ? documentSnapshot.get("userType")
                  : "",
              createdOn:
                  documentSnapshot.data().toString().contains("createdOn")
                      ? documentSnapshot.get("createdOn")
                      : "",
            );
          } else if (documentSnapshot.get('userType') == 'admin') {
            user = UserModel(
                id: documentSnapshot.id.toString(),
                fullName: documentSnapshot.data().toString().contains("fullName")
                    ? documentSnapshot.get("fullName")
                    : "",
                dateOfBirth: documentSnapshot.data().toString().contains("dateOfBirth")
                    ? documentSnapshot.get("dateOfBirth")
                    : "",
                email: documentSnapshot.data().toString().contains("email")
                    ? documentSnapshot.get("email")
                    : "",
                phoneNumber: documentSnapshot.data().toString().contains("phoneNumber")
                    ? documentSnapshot.get("phoneNumber")
                    : "",
                userType: documentSnapshot.data().toString().contains("userType")
                    ? documentSnapshot.get("userType")
                    : "",
                createdOn: documentSnapshot.data().toString().contains("createdOn")
                    ? documentSnapshot.get("createdOn")
                    : "",
                createdByUserId:
                    documentSnapshot.data().toString().contains("createdByUserId")
                        ? documentSnapshot.get("createdByUserId")
                        : "",
                divisions: documentSnapshot.data().toString().contains("divisions")
                    ? (documentSnapshot.get("divisions").cast<String>() ?? [])
                    : [],
                imageFilePath: documentSnapshot.data().toString().contains("imagePath")
                    ? ((documentSnapshot.get("imagePath") != null &&
                            documentSnapshot.get("imagePath") != "")
                        ? documentSnapshot.get("imagePath")
                        : "")
                    : "");
          } else {
            user = UserModel(
                id: documentSnapshot.id.toString(),
                fullName: documentSnapshot.data().toString().contains("fullName")
                    ? documentSnapshot.get("fullName")
                    : "",
                dateOfBirth:
                    documentSnapshot.data().toString().contains("dateOfBirth")
                        ? documentSnapshot.get("dateOfBirth")
                        : "",
                email: documentSnapshot.data().toString().contains("email")
                    ? documentSnapshot.get("email")
                    : "",
                phoneNumber:
                    documentSnapshot.data().toString().contains("phoneNumber")
                        ? documentSnapshot.get("phoneNumber")
                        : "",
                userType: documentSnapshot.data().toString().contains("userType")
                    ? documentSnapshot.get("userType")
                    : "",
                division: documentSnapshot.data().toString().contains("division")
                    ? documentSnapshot.get("division")
                    : "",
                area: documentSnapshot.data().toString().contains("area")
                    ? documentSnapshot.get("area")
                    : "",
                city: documentSnapshot.data().toString().contains("city")
                    ? documentSnapshot.get("city")
                    : "",
                pin: documentSnapshot.data().toString().contains("pin")
                    ? documentSnapshot.get("pin")
                    : "",
                state: documentSnapshot.data().toString().contains("state")
                    ? documentSnapshot.get("state")
                    : "",
                panNumber: documentSnapshot.data().toString().contains("panNumber")
                    ? documentSnapshot.get("panNumber")
                    : "",
                aadharNumber: documentSnapshot.data().toString().contains("aadharNumber") ? documentSnapshot.get("aadharNumber") : "",
                isApprovedByAdmin: documentSnapshot.data().toString().contains("isApprovedByAdmin") ? documentSnapshot.get("isApprovedByAdmin") : false,
                isRejectedByAdmin: documentSnapshot.data().toString().contains("isRejectedByAdmin") ? documentSnapshot.get("isRejectedByAdmin") : false,
                createdOn: documentSnapshot.data().toString().contains("createdOn") ? documentSnapshot.get("createdOn") : "",
                createdByUserId: documentSnapshot.data().toString().contains("createdByUserId") ? documentSnapshot.get("createdByUserId") : "",
                approvedOn: documentSnapshot.data().toString().contains("approvedOn") ? documentSnapshot.get("approvedOn") : "",
                imageFilePath: documentSnapshot.data().toString().contains("imagePath") ? ((documentSnapshot.get("imagePath") != null && documentSnapshot.get("imagePath") != "") ? documentSnapshot.get("imagePath") : "") : "");
          }

          return user;
        } else {
          return null;
        }
      });
    } catch (e) {
      user = null;
    }
    return user;
  }

  Future<String?> getUserNameById(String userId) async {
    String? name;
    try {
      name = await FirebaseFirestore.instance
          .collection(_usersCollectionName)
          .doc(userId)
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          String name = documentSnapshot.get('fullName');
          return name;
        } else {
          return null;
        }
      });
    } catch (e) {
      name = null;
    }
    return name;
  }

  Future<UserModel?> getUserByPhoneNumber(String phoneNumber) async {
    UserModel? user;
    try {
      user = await FirebaseFirestore.instance
          .collection(_usersCollectionName)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get()
          .then((QuerySnapshot querySnapshot) {
        if (querySnapshot.docs.isEmpty) {
          return null;
        } else {
          var doc = querySnapshot.docs.first;
          UserModel userFromDB = UserModel(
              id: doc.reference.id.toString(),
              phoneNumber: doc.data().toString().contains("phoneNumber")
                  ? doc.get("phoneNumber")
                  : "",
              email: doc.data().toString().contains("email")
                  ? doc.get("email")
                  : "",
              createdByUserId: doc.data().toString().contains("createdByUserId")
                  ? doc.get("createdByUserId")
                  : "");
          return userFromDB;
        }
      });
    } catch (e) {
      user = null;
    }
    return user;
  }

  Future<UserModel?> getUserWithPhoneNumber(String phoneNumber) async {
    UserModel? user;
    try {
      user = await FirebaseFirestore.instance
          .collection(_usersCollectionName)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get()
          .then((QuerySnapshot querySnapshot) {
        if (querySnapshot.docs.isEmpty) {
          return null;
        } else {
          var doc = querySnapshot.docs.first;
          UserModel user = UserModel(
              id: doc.reference.id.toString(),
              fullName: doc.data().toString().contains("fullName")
                  ? doc.get("fullName")
                  : "",
              dateOfBirth: doc.data().toString().contains("dateOfBirth")
                  ? doc.get("dateOfBirth")
                  : "",
              email: doc.data().toString().contains("email")
                  ? doc.get("email")
                  : "",
              phoneNumber: doc.data().toString().contains("phoneNumber")
                  ? doc.get("phoneNumber")
                  : "",
              userType: doc.data().toString().contains("userType")
                  ? doc.get("userType")
                  : "",
              createdOn: doc.data().toString().contains("createdOn")
                  ? doc.get("createdOn")
                  : "",
              createdByUserId: doc.data().toString().contains("createdByUserId")
                  ? doc.get("createdByUserId")
                  : "",
              divisions: doc.data().toString().contains("divisions")
                  ? (doc.get("divisions").cast<String>() ?? [])
                  : [],
              imageFilePath: doc.data().toString().contains("imagePath")
                  ? ((doc.get("imagePath") != null &&
                          doc.get("imagePath") != "")
                      ? doc.get("imagePath")
                      : "")
                  : "");

          return user;
        }
      });
    } catch (e) {
      user = null;
      Common.customLog('ERROR___<' + e.toString() + '>');
    }
    return user;
  }

  Future<String> updateUser(UserModel user) async {
    String userId = user.id;
    Common.customLog('USER ID UPDATE -----' + userId);
    String imagePath = user.imageFilePath;
    // check if phone number changed, and incase its changed verify the
    // given phonenumber is already associated with another user or not
    // UserModel? userFromDB = await getUserByPhoneNumber(user.phoneNumber);
    // if (userFromDB != null) {
    //   if (userFromDB.id != user.id) {
    //     return 'error__phonenumber-already-in-use';
    //   }
    // }
    // If image is changed replacing the image
    try {
      if (user.imageFile != null && user.imageFilePath == '') {
        String result = await ImageService.uploadImageToFirebase(
            user.imageFile, userId, 'profilepics');
        if (result.contains('error__')) {
          return result;
        } else {
          imagePath = result.split('success__').last.split('profilepics/')[0];
        }
      } else {
        imagePath = user.imageFilePath;
      }
    } catch (exception) {
      imagePath = '';
    }
    CollectionReference usersCollectionReference =
        FirebaseFirestore.instance.collection(_usersCollectionName);
    String result = '';
    if (user.userType == 'admin') {
      result = await usersCollectionReference
          .doc(userId)
          .update({
            'dateOfBirth': user.dateOfBirth,
            'fullName': user.fullName,
            'email': user.email,
            'phoneNumber': user.phoneNumber,
            'userType': user.userType,
            'createdOn': user.createdOn,
            'imagePath': imagePath,
            'divisions': user.divisions
          })
          .then((value) => 'success__' + userId)
          .catchError((error) {
            Common.customLog('error__' + error.toString());
          });
    } else {
      result = await usersCollectionReference
          .doc(userId)
          .update({
            'dateOfBirth': user.dateOfBirth,
            'fullName': user.fullName,
            'email': user.email,
            'phoneNumber': user.phoneNumber,
            'userType': user.userType,
            'division': user.division,
            'area': user.area,
            'city': user.city,
            'pin': user.pin,
            'state': user.state,
            'panNumber': user.panNumber,
            'aadharNumber': user.aadharNumber,
            'isApprovedByAdmin': user.isApprovedByAdmin,
            'isRejectedByAdmin': user.isRejectedByAdmin,
            'approvedByUserId': user.approvedByUserId,
            'createdOn': user.createdOn,
            'approvedOn': user.approvedOn,
            'imagePath': imagePath
          })
          .then((value) => 'success__' + userId)
          .catchError((error) => 'error__' + error.toString());
    }
    Common.customLog('RESULT ~~~~~~~> ' + result.toString());
    return result.toString();
  }

  Future<String> updateRegionOfSupervisor(
      String userId, String newdivision) async {
    CollectionReference usersCollectionReference =
        FirebaseFirestore.instance.collection(_usersCollectionName);
    String result = '';
    result = await usersCollectionReference
        .doc(userId)
        .update({'division': newdivision})
        .then((value) => 'success__')
        .catchError((error) => 'error__' + error.toString());
    return result;
  }

  Future<String?> getUserEmailFromPhoneNumber(String phoneNumber) async {
    String? email;
    try {
      email = await FirebaseFirestore.instance
          .collection(_usersCollectionName)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get()
          .then((QuerySnapshot querySnapshot) {
        if (querySnapshot.docs.isEmpty) {
          return '';
        }
        for (var doc in querySnapshot.docs) {
          return doc["email"] ?? '';
        }
      });
    } catch (error) {
      email = '';
    }
    if (email == '') {
      email = null;
    }
    return email;
  }

  Future<String?> signinWithPhoneNumberAndPassword(
      String phoneNumber, String password) async {
    String? email = await getUserEmailFromPhoneNumber(phoneNumber.toString());
    if (email != null) {
      String result = await signIn(email, password);
      return result;
    } else {
      return 'error__phone-number-not-registered';
    }
  }

  Future<void> signout() async {
    await FirebaseAuth.instance.signOut();
    await _destroyAgentInfoCache();
  }

  Future<String?> getCurrentUserType() async {
    String? currentUserId = await getCurrentUserId();

    if (currentUserId == null) {
      return null;
    } else {
      String? type;
      try {
        var docSnapshot = await FirebaseFirestore.instance
            .collection(_usersCollectionName)
            .doc(currentUserId)
            .get();
        if (docSnapshot.exists) {
          Map<String, dynamic>? data = docSnapshot.data();
          var value = data?['userType'];
          return value.toString();
        } else {
          return null;
        }
      } catch (exception) {
        type = null;
      }
      return type;
    }
  }

  Future<UserModel> getSupervisorObjectFromCSVData(dataChunkList) async {
    String? currentLoggedInUserId = await getCurrentUserId();
    UserModel user = UserModel(
        fullName: dataChunkList[1],
        area: dataChunkList[2],
        phoneNumber: dataChunkList[3],
        aadharNumber: dataChunkList[4],
        email: dataChunkList[5],
        imageFile: null,
        createdByUserId: currentLoggedInUserId ?? ''.toString(),
        createdOn: DateTime.now().millisecondsSinceEpoch.toString(),
        approvedOn: DateTime.now().millisecondsSinceEpoch.toString(),
        approvedByUserId: currentLoggedInUserId ?? ''.toString(),
        dateOfBirth: '',
        state: '',
        pin: '',
        panNumber: '',
        userType: 'supervisor',
        division: "27",
        city: '',
        isApprovedByAdmin: true,
        isRejectedByAdmin: false,
        password: 'user@jamtara');
    return user;
  }

  Future<String> uploadSupervisorFromCSV(PlatformFile selectedFile) async {
    List<dynamic> dataFromFile = ParseCSV.getCSVLines(selectedFile);
    String result = '';
    for (String dataLine in dataFromFile) {
      List<String> dataChunkList = dataLine.split(',');
      if (dataChunkList.length >= 6 && dataChunkList[5].trim() != '') {
        UserModel user = await getSupervisorObjectFromCSVData(dataChunkList);
        if (Common.isValidEmail(user.email)) {
          result = 'error__email-is-not-formatted-pr operly';
        }
        if (Common.isValidMobileNumber(user.phoneNumber)) {
          result = 'error__phonenumber-is-not-valid';
        }
        result = await addUser(user);
        if (result.contains('error__')) {
          break;
        }
      } else {
        continue;
      }
    }
    return result;
  }

  Future<String> approveAgent(UserModel agent) async {
    CollectionReference usersCollectionReference =
        FirebaseFirestore.instance.collection(_usersCollectionName);
    String result = '';
    String? currentUserID = await getCurrentUserId();
    result = await usersCollectionReference
        .doc(agent.id)
        .update({
          'isApprovedByAdmin': true,
          'isRejectedByAdmin': false,
          'approvedByUserId': currentUserID ?? '',
          'approvedOn': DateTime.now().millisecondsSinceEpoch.toString()
        })
        .then((value) => 'success__')
        .catchError((error) => 'error__' + error.toString());
    return result;
  }

  Future<String> rejectAgent(UserModel agent) async {
    CollectionReference usersCollectionReference =
        FirebaseFirestore.instance.collection(_usersCollectionName);
    String result = '';
    String? currentUserID = await getCurrentUserId();
    result = await usersCollectionReference
        .doc(agent.id)
        .update({
          'isApprovedByAdmin': false,
          'isRejectedByAdmin': true,
          'approvedByUserId': currentUserID ?? '',
          'approvedOn': DateTime.now().millisecondsSinceEpoch.toString()
        })
        .then((value) => 'success__')
        .catchError((error) => 'error__' + error.toString());
    return result;
  }

  Future<String> approveSupervisor(UserModel agent) async {
    CollectionReference usersCollectionReference =
        FirebaseFirestore.instance.collection(_usersCollectionName);
    String result = '';
    String? currentUserID = await getCurrentUserId();
    result = await usersCollectionReference
        .doc(agent.id)
        .update({
          'isApprovedBySuperAdmin': true,
          'isRejectedBySuperAdmin': false,
          'approvedByUserId': currentUserID ?? '',
          'approvedOn': DateTime.now().millisecondsSinceEpoch.toString()
        })
        .then((value) => 'success__')
        .catchError((error) => 'error__' + error.toString());
    return result;
  }

  Future<String> rejectSupervisor(UserModel agent) async {
    CollectionReference usersCollectionReference =
        FirebaseFirestore.instance.collection(_usersCollectionName);
    String result = '';
    String? currentUserID = await getCurrentUserId();
    result = await usersCollectionReference
        .doc(agent.id)
        .update({
          'isApprovedBySuperAdmin': false,
          'isRejectedBySuperAdmin': true,
          'approvedByUserId': currentUserID ?? '',
          'approvedOn': DateTime.now().millisecondsSinceEpoch.toString()
        })
        .then((value) => 'success__')
        .catchError((error) => 'error__' + error.toString());
    return result;
  }

  Future<void> changePassword(String email, String currentPassword,
      String newPassword, Function success, Function failed) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cred =
          EmailAuthProvider.credential(email: email, password: currentPassword);

      user.reauthenticateWithCredential(cred).then((value) {
        user.updatePassword(newPassword).then((_) {
          success();
        }).catchError((error) {
          failed(error.toString());
        });
      }).catchError((error) {
        failed(error.toString());
      });
    }
  }

  Future<String> getDivisionOfCurrentUser() async {
    String? currentLoggedInUserId = await getCurrentUserId();
    if (currentLoggedInUserId != null) {
      UserModel? user = await getUserById(currentLoggedInUserId);
      if (user != null) {
        return user.division;
      } else {
        return '';
      }
    } else {
      return '';
    }
  }

  Future<void> buildAgentInfoCache() async {
    String? userId = await getCurrentUserId();
    if (userId != null) {
      // getting agent's info
      UserModel? agent = await getUserById(userId);
      if (agent != null) {
        String supervisorId = agent.createdByUserId;
        String? supervisorName = await getUserNameById(supervisorId);
        if (supervisorName != null) {
          agent.createdByName = supervisorName;
        } else {
          agent.createdByName = 'Annonymus';
        }
        String jsonDataToBeWritten = jsonEncode(agent.toJson());
        FileService.write(
            jsonDataToBeWritten, userInfoCacheFileName, (String result) {});
      }
    }
  }

  Future<UserModel> getAgentInfoFromCache() async {
    UserModel agent;
    try {
      String dataFromFile = await FileService.read(userInfoCacheFileName);
      final decodedData = jsonDecode(dataFromFile);
      agent = UserModel(
          fullName: decodedData['fullName'],
          dateOfBirth: decodedData['dateOfBirth'],
          email: decodedData['email'],
          division: decodedData['division'],
          createdOn: decodedData['createdOn'],
          isApprovedByAdmin: decodedData['isApprovedByAdmin'],
          city: decodedData['city'],
          panNumber: decodedData['panNumber'],
          imageFilePath: decodedData['imageFilePath'],
          state: decodedData['state'],
          aadharNumber: decodedData['aadharNumber'],
          area: decodedData['area'],
          phoneNumber: decodedData['phoneNumber'],
          pin: decodedData['pin'],
          createdByName: decodedData['createdByName'],
          createdByUserId: decodedData['createdByUserId']);
    } catch (error) {
      agent = UserModel();
    }
    return agent;
  }

  Future<void> _destroyAgentInfoCache() async {
    FileService.delete(userInfoCacheFileName);
  }
}
