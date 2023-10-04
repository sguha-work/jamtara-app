import 'dart:io';
import 'dart:io' as io;

class ReportModel {
  int createdOn = 0;
  String createdBy = '';
  String createdByName = '';
  String id = '';
  List<String>? filePathList = [];
  List<String>? imageBase64StringList = [];
  List<String>? imageLinks = [];
  String division = '';
  String subdivision = '';
  String consumerNumber = '';
  String consumerName = '';
  String latitude = '';
  String longitude = '';
  bool isSubmitted = false;
  String consumerAadharNumber = '';
  String consumerMobileNumber = '';
  String consumerMeterNumber = '';
  String sealingPageNo = '';
  ReportModel(
      {this.createdOn = 0,
      this.createdBy = '',
      this.createdByName = '',
      this.id = '',
      this.latitude = '',
      this.longitude = '',
      this.filePathList,
      this.division = '',
      this.consumerNumber = '',
      this.consumerName = '',
      this.subdivision = '',
      this.isSubmitted = false,
      this.consumerAadharNumber = '',
      this.consumerMeterNumber = '',
      this.consumerMobileNumber = '',
      this.imageLinks,
      this.imageBase64StringList,
      this.sealingPageNo = ''}) {}
  Map toJson() => {
        'createdOn': createdOn,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'id': id,
        'filePathList': filePathList,
        'imageBase64StringList': imageBase64StringList,
        'imageLinks': imageLinks,
        'division': division,
        'consumerNumber': consumerNumber,
        'latitude': latitude,
        'longitude': longitude,
        'subdivision': subdivision,
        'consumerName': consumerName,
        'isSubmitted': isSubmitted,
        'consumerAadharNumber': consumerAadharNumber,
        'consumerMeterNumber': consumerMeterNumber,
        'consumerMobileNumber': consumerMobileNumber,
        'sealingPageNo': sealingPageNo
      };
}
