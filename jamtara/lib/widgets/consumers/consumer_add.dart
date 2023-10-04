import 'dart:convert';

import 'package:bentec/models/consumer.dart';
import 'package:bentec/models/user.dart';
import 'package:bentec/services/common.dart';
import 'package:bentec/services/consumer_service.dart';
import 'package:bentec/services/dialogue.dart';
import 'package:bentec/services/file_service.dart';
import 'package:bentec/services/user_service.dart';
import 'package:flutter/material.dart';

class ConsumerAdd extends StatefulWidget {
  // final bool readOnly;
  // ConsumerAdd(this.readOnly);
  @override
  State<ConsumerAdd> createState() => _ConsumerAddState();
}

class _ConsumerAddState extends State<ConsumerAdd> {
  String consumerCacheFileName = '5icuej2lquznjtm';
  final UserService _userService = UserService();
  final ConsumerService _consumerService = ConsumerService();
  String errorText = '';
  TextEditingController nameController = TextEditingController();
  TextEditingController aadharNoController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController address1Controller = TextEditingController();
  TextEditingController address2Controller = TextEditingController();
  TextEditingController address3Controller = TextEditingController();
  TextEditingController address4Controller = TextEditingController();
  TextEditingController consumerNoController = TextEditingController();
  TextEditingController consumerTypeController = TextEditingController();
  TextEditingController meterNoController = TextEditingController();
  TextEditingController meterStatusController = TextEditingController();
  TextEditingController meterMakeController = TextEditingController();
  TextEditingController divisionController = TextEditingController();
  TextEditingController subDivisionController = TextEditingController();
  TextEditingController circleController = TextEditingController();
  TextEditingController loadController = TextEditingController();
  TextEditingController tariffController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create consumer'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          child: Column(
            children: [
              Card(
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    contentPadding: EdgeInsets.all(5),
                  ),
                ),
              ),
              Card(
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: aadharNoController,
                  decoration: const InputDecoration(
                    labelText: 'Aadhar no *',
                    contentPadding: EdgeInsets.all(5),
                  ),
                ),
              ),
              Card(
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: mobileController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile number',
                    contentPadding: EdgeInsets.all(5),
                  ),
                ),
              ),
              Card(
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: address1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address 1 *',
                    contentPadding: EdgeInsets.all(5),
                  ),
                ),
              ),
              Card(
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: address2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address 2',
                    contentPadding: EdgeInsets.all(5),
                  ),
                ),
              ),
              Card(
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: address3Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address 3',
                    contentPadding: EdgeInsets.all(5),
                  ),
                ),
              ),
              Card(
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: address4Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address 4',
                    contentPadding: EdgeInsets.all(5),
                  ),
                ),
              ),
              Card(
                child: TextField(
                  enabled: false,
                  controller: divisionController,
                  decoration: const InputDecoration(
                    labelText: 'Division (Read only)',
                    contentPadding: EdgeInsets.all(5),
                  ),
                ),
              ),
              Card(
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: subDivisionController,
                  decoration: const InputDecoration(
                    labelText: 'Sub division *',
                    contentPadding: EdgeInsets.all(5),
                  ),
                ),
              ),
              Card(
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: circleController,
                  decoration: const InputDecoration(
                    labelText: 'Circle *',
                    contentPadding: EdgeInsets.all(5),
                  ),
                ),
              ),
              Card(
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: consumerNoController,
                  decoration: const InputDecoration(
                    labelText: 'Consumer number *',
                    contentPadding: EdgeInsets.all(5),
                  ),
                ),
              ),
              Card(
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: consumerTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Consumer type *',
                    contentPadding: EdgeInsets.all(5),
                  ),
                ),
              ),
              Card(
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: loadController,
                  decoration: const InputDecoration(
                    labelText: 'Load *',
                    contentPadding: EdgeInsets.all(5),
                  ),
                ),
              ),
              Card(
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: meterNoController,
                  decoration: const InputDecoration(
                    labelText: 'Meter number',
                    contentPadding: EdgeInsets.all(5),
                  ),
                ),
              ),
              Card(
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: meterStatusController,
                  decoration: const InputDecoration(
                    labelText: 'Meter status *',
                    contentPadding: EdgeInsets.all(5),
                  ),
                ),
              ),
              Card(
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: meterMakeController,
                  decoration: const InputDecoration(
                    labelText: 'Meter make',
                    contentPadding: EdgeInsets.all(5),
                  ),
                ),
              ),
              Card(
                child: TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: tariffController,
                  decoration: const InputDecoration(
                    labelText: 'Tariff',
                    contentPadding: EdgeInsets.all(5),
                  ),
                ),
              ),
              if (errorText != '') ...[
                const SizedBox(
                  height: 10,
                ),
                Text(
                  errorText,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(
                  height: 10,
                ),
              ],
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: SizedBox(
                  width: 100,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _addConsumer,
                    child: const Text(
                      'Submit',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _ConsumerAddState() {
    _getAgentDivision();
  }

  void _getAgentDivision() async {
    String? _userId = await _userService.getCurrentUserId();
    if (_userId != null) {
      UserModel? _agent = await _userService.getUserById(_userId);
      if (_agent != null && _agent.division.length != '') {
        setState(() {
          divisionController.text = _agent.division;
        });
      }
    }
  }

  void _addConsumer() async {
    if (_validate()) {
      FocusScopeNode currentFocus = FocusScope.of(context);
      if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
        currentFocus.focusedChild?.unfocus();
      }
      CustomDialog.showConfirmDialog(
          context, 'Do you want to proceed with adding the consumer?',
          () async {
        ConsumerModel consumer = ConsumerModel(
          consumerId: consumerNoController.text.trim(),
          consumerNo: consumerNoController.text.trim(),
          address1: address1Controller.text.trim(),
          address2: address2Controller.text.trim(),
          address3: address3Controller.text.trim(),
          address4: address4Controller.text.trim(),
          currentstatus: meterStatusController.text.trim(),
          load: loadController.text.trim(),
          meterSlno: meterNoController.text.trim(),
          name: nameController.text.trim(),
          subdivision: subDivisionController.text.trim(),
          division: divisionController.text.trim(),
          aadharNo: aadharNoController.text.trim(),
          circle: circleController.text.trim(),
          consumerType: consumerTypeController.text.trim(),
          meterMake: meterMakeController.text.trim(),
          mobileNo: mobileController.text.trim(),
          tariff: tariffController.text.trim(),
          isApprovedBySupervisor: false,
          isRejectedBySupervisor: false,
        );

        CustomDialog.showLoadingDialogue(context);
        String result = await _consumerService.addConsumer(consumer);
        Common.customLog('Result...' + result);
        if (result.contains('error__')) {
          String messege = result.split('error__').last;
          switch (messege) {
            case 'error__ConsumerNo already exists':
              _displayError('Provided consumer number already exists');
              break;
            default:
              _displayError(messege);
          }
        }
        if (result.contains('success__')) {
          _displayError('');
          CustomDialog.hideLoadingDialogue(context);
          Future.delayed(const Duration(milliseconds: 1000), () {
            _clearAllInputFields();
            CustomDialog.showSnack(context, 'Consumer added', () {
              // Navigator.pop(context, true);
            });
            consumer.id = result.split('success__').last;
            _cacheConsumerList(consumer);
          });
        } else {
          CustomDialog.hideLoadingDialogue(context);
        }
      });
    }
  }

  void _cacheConsumerList(ConsumerModel newlyCreatedConsumer) async {
    Common.customLog('Newly created consumer------');
    Common.customLog(newlyCreatedConsumer.id);
    Common.customLog(newlyCreatedConsumer.name);
    CustomDialog.showLoadingDialogue(context);
    List<ConsumerModel>? cachedConsumers =
        await _consumerService.getAllConsumersFromFile();
    CustomDialog.hideLoadingDialogue(context);
    if (cachedConsumers != null) {
      cachedConsumers.add(newlyCreatedConsumer);
    } else {
      cachedConsumers = [newlyCreatedConsumer];
    }
    String jsonData =
        jsonEncode(cachedConsumers.map((e) => e.toJson()).toList());
    CustomDialog.showLoadingDialogue(context,
        message: 'Consumer is being cached. Please wait.');
    FileService.write(jsonData, consumerCacheFileName, (result) {
      CustomDialog.hideLoadingDialogue(context);
      Navigator.pop(context, true);
    });
  }

  bool _validate() {
    setState(() {
      errorText = '';
    });
    if (nameController.text.trim() == '') {
      _displayError('Name cannot be empty');
      return false;
    }
    if (aadharNoController.text.trim() == '' ||
        !Common.isValidAadharNumber(aadharNoController.text.trim())) {
      _displayError('Please enter a valid aadhar no.');
      return false;
    }

    if (mobileController.text.trim() != '' &&
        !Common.isValidMobileNumber(mobileController.text)) {
      _displayError('Phone number is wrongly given');
      return false;
    }

    if (address1Controller.text.trim() == '' &&
        address2Controller.text.trim() == '' &&
        address3Controller.text.trim() == '' &&
        address4Controller.text.trim() == '') {
      _displayError('Address cannot be empty');
      return false;
    }
    if (subDivisionController.text.trim() == '') {
      _displayError('Sub-division cannot be empty');
      return false;
    }
    if (circleController.text.trim() == '') {
      _displayError('Circle cannot be empty');
      return false;
    }
    if (consumerNoController.text.trim() == '') {
      _displayError('Consumer number cannot be empty');
      return false;
    }
    if (consumerTypeController.text.trim() == '') {
      _displayError('Consumer type cannot be empty');
      return false;
    }
    if (loadController.text.trim() == '') {
      _displayError('Load cannot be empty');
      return false;
    }
    if (meterStatusController.text.trim() == '') {
      _displayError('Load cannot be empty');
      return false;
    }

    return true;
  }

  void _displayError(String message) {
    setState(() {
      errorText = message;
    });
  }

  void _clearAllInputFields() {
    nameController.clear();
    mobileController.clear();
    address1Controller.clear();
    address2Controller.clear();
    address3Controller.clear();
    address4Controller.clear();
    consumerNoController.clear();
    consumerTypeController.clear();
    meterNoController.clear();
    meterStatusController.clear();
    meterMakeController.clear();
    divisionController.clear();
    subDivisionController.clear();
    circleController.clear();
    loadController.clear();
    tariffController.clear();
    aadharNoController.clear();
  }
}
