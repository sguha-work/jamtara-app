class ConsumerModel {
  String id = '';
  String sno = '';
  String consumerId = '';
  String currentstatus = '';
  String subdivision = '';
  String consumerNo = '';
  String kNo = '';
  String name = '';
  String address1 = '';
  String address2 = '';
  String address3 = '';
  String address4 = '';
  String load = '';
  String meterSlno = '';
  String division = '';
  String circle = '';
  String mobileNo = '';
  String consumerType = '';
  String meterMake = '';
  String tariff = '';
  String aadharNo = '';
  bool isApprovedBySupervisor = false;
  bool isRejectedBySupervisor = false;
  String createdOn = '';
  ConsumerModel(
      {this.id = '',
      this.sno = '',
      this.consumerId = '',
      this.currentstatus = '',
      this.subdivision = '',
      this.consumerNo = '',
      this.kNo = '',
      this.name = '',
      this.address1 = '',
      this.address2 = '',
      this.address3 = '',
      this.address4 = '',
      this.load = '',
      this.meterSlno = '',
      this.division = '',
      this.circle = '',
      this.mobileNo = '',
      this.consumerType = '',
      this.meterMake = '',
      this.tariff = '',
      this.aadharNo = '',
      this.isApprovedBySupervisor = false,
      this.isRejectedBySupervisor = false,
      this.createdOn = ''}) {}
  Map toJson() => {
        'id': id,
        'consumerId': consumerId,
        'currentstatus': currentstatus,
        'subdivision': subdivision,
        'consumerNo': consumerNo,
        'name': name,
        'address1': address1,
        'address2': address2,
        'address3': address3,
        'address4': address4,
        'load': load,
        'meterSlno': meterSlno,
        'division': division,
        'circle': circle,
        'mobileNo': mobileNo,
        'consumerType': consumerType,
        'meterMake': meterMake,
        'tariff': tariff,
        'aadharNo': aadharNo,
        'isApprovedBySupervisor': isApprovedBySupervisor,
        'isRejectedBySupervisor': isRejectedBySupervisor,
        'createdOn': createdOn,
      };
}
