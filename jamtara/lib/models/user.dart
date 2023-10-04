import 'dart:io';
import 'dart:io' as io;

class UserModel {
  String id = '';
  String dateOfBirth = '';
  String fullName = '';
  String email = '';
  String password = '';
  String phoneNumber = '0000000000';
  String userType = 'agent'; // 'supervisor', 'admin'
  String division = '';
  String area = '';
  String city = '';
  String pin = '';
  String state = '';
  String panNumber = '';
  String aadharNumber = '';
  bool isApprovedByAdmin = false;
  bool isRejectedByAdmin = false;
  bool isApprovedBySuperAdmin = false;
  bool isRejectedBySuperAdmin = false;
  String approvedByUserId = '';
  String createdOn = '';
  String createdByUserId = '';
  String createdByName = '';
  String approvedOn = '';
  File? imageFile;
  String imageFilePath = '';
  List<String> divisions = const [];

  UserModel(
      {this.id = '',
      this.dateOfBirth = '',
      this.fullName = '',
      this.email = '',
      this.password = '',
      this.phoneNumber = '0000000000',
      this.userType = 'agent',
      this.division = '',
      this.area = '',
      this.city = '',
      this.pin = '',
      this.state = '',
      this.panNumber = '',
      this.aadharNumber = '',
      this.isApprovedByAdmin = false,
      this.isRejectedByAdmin = false,
      this.isApprovedBySuperAdmin = false,
      this.isRejectedBySuperAdmin = false,
      this.createdOn = '',
      this.createdByUserId = '',
      this.createdByName = '',
      this.approvedOn = '',
      this.approvedByUserId = '',
      this.imageFile,
      this.imageFilePath = '',
      this.divisions = const []}) {}
  Map toJson() => {
        'id': id,
        'dateOfBirth': dateOfBirth,
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'userType': userType,
        'division': division,
        'area': area,
        'city': city,
        'pin': pin,
        'state': state,
        'panNumber': panNumber,
        'aadharNumber': aadharNumber,
        'isApprovedByAdmin': isApprovedByAdmin,
        'isRejectedByAdmin': isRejectedByAdmin,
        'isApprovedBySuperAdmin': isApprovedBySuperAdmin,
        'isRejectedBySuperAdmin': isRejectedBySuperAdmin,
        'approvedByUserId': approvedByUserId,
        'createdOn': createdOn,
        'createdByUserId': createdByUserId,
        'createdByName': createdByName,
        'approvedOn': approvedOn,
        'imageFilePath': imageFilePath,
        'divisions': divisions,
      };
  UserModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    dateOfBirth = json['dateOfBirth'];
    fullName = json['fullName'];
    email = json['email'];
    phoneNumber = json['phoneNumber'];
    userType = json['userType'];
    division = json['division'];
    area = json['area'];
    city = json['city'];
    pin = json['pin'];
    state = json['state'];
    panNumber = json['panNumber'];
    aadharNumber = json['aadharNumber'];
    isApprovedByAdmin = json['isApprovedByAdmin'];
    isRejectedByAdmin = json['isRejectedByAdmin'];
    isApprovedBySuperAdmin = json['isApprovedBySuperAdmin'];
    isRejectedBySuperAdmin = json['isRejectedBySuperAdmin'];
    approvedByUserId = json['approvedByUserId'];
    createdOn = json['createdOn'];
    createdByUserId = json['createdByUserId'];
    createdByName = json['createdByName'];
    approvedOn = json['approvedOn'];
    imageFilePath = json['imageFilePath'];
    divisions = json['divisions'].cast<String>();
  }
}
