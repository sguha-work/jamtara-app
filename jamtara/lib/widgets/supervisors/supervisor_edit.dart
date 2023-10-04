import 'package:bentec/widgets/agents/agent_list_supervisor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/common.dart';
import '../../models/user.dart';
import '../../models/division.dart';
import '../../services/user_service.dart';
import '../../services/division_service.dart';
import '../../services/dialogue.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:io' as io;

class EditSupervisor extends StatefulWidget {
  final UserModel? supervisor;
  const EditSupervisor(this.supervisor);
  @override
  State<EditSupervisor> createState() => _EditSupervisor();
}

class _EditSupervisor extends State<EditSupervisor> {
  bool isEdited = false;
  bool isNewImagePicked = false;
  bool readOnly = false;
  String userId = '';
  String imageFilePath = '';
  final UserService userService = UserService();
  final DivisionService divisionService = DivisionService();
  String errorText = '';
  String divisionValue = '-1';
  String supervisorName = '';
  List<Map<String, String>> regionCodesFromDB = [
    {'text': 'Select division', 'value': '-1'}
  ];
  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final emailController = TextEditingController();
  final panNumberController = TextEditingController();
  final aadharController = TextEditingController();
  final areaController = TextEditingController();
  final cityController = TextEditingController();
  final pinController = TextEditingController();
  final stateController = TextEditingController();
  final picker = ImagePicker();
  File? _imageFile;
  Future pickImage() async {
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    isNewImagePicked = true;
    setState(() {
      _imageFile = File(pickedFile!.path);
    });
  }

  _EditSupervisor() {
    _getRegionCodesFromDB();
  }
  Future<void> _getRegionCodesFromDB() async {
    List<DivisionModel> regionList = await divisionService.getAllDivision();
    List<Map<String, String>> valuesForDropdown = [];
    valuesForDropdown.add({'text': 'Select division', 'value': '-1'});
    for (var region in regionList) {
      valuesForDropdown.add({'text': region.code, 'value': region.code});
    }
    setState(() {
      regionCodesFromDB = valuesForDropdown;
    });
    UserModel? supervisor = widget.supervisor;
    if (!isEdited) {
      userId = supervisor!.id;
      _prepareValueForEditForm(supervisor);
    }
  }

  bool _validate() {
    if (nameController.text.trim() == '') {
      _displayError('Supervisor name cannot be empty');
      return false;
    }
    if (emailController.text.trim() == '') {
      _displayError('Supervisor email cannot be empty');
      return false;
    }
    if (!Common.isValidEmail(emailController.text)) {
      _displayError('Supervisor email is wrongly given');
      return false;
    }
    if (divisionValue == '-1') {
      _displayError('Please select division');
      return false;
    }
    return true;
  }

  void _displayError(String message) {
    setState(() {
      errorText = message;
      readOnly = true;
    });
  }

  void _clearAllInputFields() {
    setState(() {
      divisionValue = '-1';
    });
    nameController.clear();
    dobController.clear();
    phoneNumberController.clear();
    emailController.clear();
    panNumberController.clear();
    aadharController.clear();
    areaController.clear();
    cityController.clear();
    pinController.clear();
    stateController.clear();
    _imageFile = null;
  }

  void updateSupervisor(BuildContext context) async {
    if (_validate()) {
      CustomDialog.showConfirmDialog(
          context, 'Do you want to proceed with updating the supervisor?',
          () async {
        String? currentUserId = userId;
        String? currentLoggedInUserId =
            await userService.getCurrentUserId() ?? '';
        UserModel supervisor = UserModel(
            id: currentUserId,
            fullName: nameController.text.trim(),
            email: emailController.text.trim(),
            isApprovedByAdmin: true,
            isRejectedByAdmin: false,
            area: areaController.text.trim(),
            phoneNumber: phoneNumberController.text.trim(),
            division: divisionValue,
            userType: 'supervisor',
            aadharNumber: aadharController.text.trim(),
            city: cityController.text.trim(),
            panNumber: panNumberController.text.trim(),
            pin: pinController.text.trim(),
            state: stateController.text.trim(),
            approvedOn: DateTime.now().millisecondsSinceEpoch.toString(),
            dateOfBirth: dobController.text.trim(),
            approvedByUserId: currentLoggedInUserId.toString());

        if (isNewImagePicked) {
          supervisor.imageFile = _imageFile;
          supervisor.imageFilePath = '';
        } else {
          supervisor.imageFile = null;
          supervisor.imageFilePath = imageFilePath;
        }

        CustomDialog.showLoadingDialogue(context);
        // updating user
        String result = await userService.updateUser(supervisor);
        if (result.contains('error__')) {
          String messege = result.split('error__').last;
          switch (messege) {
            case 'email-already-in-use':
              _displayError('Provided email id already registered');
              break;
            case 'weak-password':
              _displayError('Please provide a strong password');
              break;
            case 'phonenumber-already-in-use':
              _displayError('Provided phone number is already in use');
              break;
            default:
              _displayError(messege);
          }
        }
        if (result.contains('success__')) {
          //String newUserId = result.split('error__').last;
          //Navigator.pop(context);
          _displayError('');
          CustomDialog.hideLoadingDialogue(context);
          Future.delayed(const Duration(milliseconds: 1000), () {
            _clearAllInputFields();
            CustomDialog.showSnack(context, 'Supervisor updated', () {
              Navigator.pop(context, true);
            });
          });
        } else {
          CustomDialog.hideLoadingDialogue(context);
        }
      });
    }
  }

  Future<void> _prepareValueForEditForm(UserModel? supervisor) async {
    if (supervisor != null) {
      setState(() {
        nameController.text = supervisor.fullName;
        supervisorName = supervisor.fullName;
        dobController.text = supervisor.dateOfBirth;
        phoneNumberController.text = supervisor.phoneNumber;
        emailController.text = supervisor.email;
        panNumberController.text = supervisor.panNumber;
        aadharController.text = supervisor.aadharNumber;
        areaController.text = supervisor.area;
        cityController.text = supervisor.city;
        pinController.text = supervisor.pin;
        stateController.text = supervisor.state;
        divisionValue = supervisor.division;
      });
      File? imageFile;
      if (supervisor.imageFilePath != '') {
        // image path is the url of fire storage
        imageFilePath = supervisor.imageFilePath;
        imageFile = await Common.fileFromImageUrl(supervisor.imageFilePath);
        setState(() {
          _imageFile = imageFile;
        });
      } else {
        imageFile = null;
      }
    }
  }

  _viewAgentList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgentList_Supervisor(widget.supervisor),
      ),
    ).then((value) {
      return value ? _EditSupervisor() : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Supervisor Details', //'Edit Supervisor',
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(30.0),
                  child: _imageFile != null
                      ? Image.file(_imageFile!, height: 200)
                      : null),
            ),
            // Card(
            //   child: TextButton(
            //     child: const Icon(
            //       Icons.add_a_photo,
            //       color: Colors.blue,
            //       size: 50,
            //     ),
            //     onPressed: pickImage,
            //   ),
            // ),
            Card(
              child: TextField(
                controller: nameController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Enter supervisor's name",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: dobController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Enter supervisor's date of birth dd-mm-yy",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: phoneNumberController,
                readOnly: true,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
                decoration: const InputDecoration(
                  labelText: "Enter supervisor's mobile no.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: emailController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText:
                      "Supervisor's email", //"Supervisor's email (This field is read only)",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
                child: DropdownButton<String>(
              value: divisionValue,
              icon: const Icon(Icons.arrow_downward),
              iconSize: 0.0, //24,
              elevation: 16,
              isExpanded: true,
              style: const TextStyle(color: Colors.black),
              underline: Container(
                height: 1,
                color: Colors.black,
              ),
              onChanged: (String? newValue) {
                // setState(() {
                //   divisionValue = newValue!;
                // });
              },
              items: regionCodesFromDB.map((Map<String, String> data) {
                return DropdownMenuItem<String>(
                  value: data['value'],
                  child: Text(data['text'].toString()),
                );
              }).toList(),
            )),
            Card(
              child: TextField(
                controller: panNumberController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Enter supervisor's PAN number.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: aadharController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Enter supervisor's Aadhar id.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: areaController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Enter area.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: cityController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Enter city.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: pinController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Enter pin.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: stateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Enter state.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextButton(
                child: Text(
                  'View agents under $supervisorName >>>',
                  style: const TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  _viewAgentList();
                },
              ),
            ),
            Text(
              errorText,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.red),
            ),
            // const SizedBox(
            //   height: 30,
            // ),
            // ElevatedButton(
            //   onPressed: () => updateSupervisor(context),
            //   child: const Text(
            //     'Update Supervisor',
            //     style: TextStyle(
            //       fontSize: 16,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
