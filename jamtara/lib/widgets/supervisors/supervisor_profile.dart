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

class SupervisorProfile extends StatefulWidget {
  final UserModel? supervisor;
  const SupervisorProfile(this.supervisor);
  @override
  State<SupervisorProfile> createState() => _SupervisorProfile();
}

class _SupervisorProfile extends State<SupervisorProfile> {
  bool _isPasswordChanged = false;
  bool isEdited = false;
  bool isNewImagePicked = false;
  bool readOnly = false;
  String userId = '';
  String imageFilePath = '';
  final UserService userService = UserService();
  final DivisionService divisionService = DivisionService();
  String errorText = '';
  String divisionValue = '-1';
  List<Map<String, String>> regionCodesFromDB = [
    {'text': 'Select region code', 'value': '-1'}
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
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final oldPasswordController = TextEditingController();
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

  _SupervisorProfile() {
    _getRegionCodesFromDB();
  }
  Future<void> _getRegionCodesFromDB() async {
    List<DivisionModel> regionList = await divisionService.getAllDivision();
    List<Map<String, String>> valuesForDropdown = [];
    valuesForDropdown.add({'text': 'Select region code', 'value': '-1'});
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
    if (passwordController.text.trim() != '') {
      _isPasswordChanged = true;
      if (oldPasswordController.text.trim() == '') {
        _displayError('To change password please enter old password first');
        return false;
      }
      if (passwordController.text.trim() != confirmPasswordController.text) {
        _displayError('Supervisor password must be confirmed');
        return false;
      }
    } else {
      _isPasswordChanged = false;
    }
    if (aadharController.text.trim() == '') {
      _displayError('Supervisor aadhar number cannot be empty');
      return false;
    }
    if (aadharController.text.trim() == '' ||
        !Common.isValidAadharNumber(aadharController.text.trim())) {
      _displayError('Please enter a valid aadhar no.');
      return false;
    }
    if (panNumberController.text.trim() == '') {
      _displayError('Supervisor PAN number cannot be empty');
      return false;
    }
    if (!Common.isValidPANNumber(panNumberController.text.trim())) {
      _displayError('Please enter a valid PAN no.');
      return false;
    }
    if (areaController.text.trim() == '') {
      _displayError('Supervisor area cannot be empty');
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

  void updateSupervisor(BuildContext context) async {
    if (_validate()) {
      CustomDialog.showConfirmDialog(
          context, 'Do you want to proceed with profile update?', () async {
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
        String result = '';
        if (_isPasswordChanged) {
          // updating password
          await userService.changePassword(
              supervisor.email,
              oldPasswordController.text.trim(),
              passwordController.text.trim(), () {
            result = 'success__';
          }, (err) {
            result = 'error__';
            _displayError('Unable to update password ' + err);
          });
        }
        if (result.contains('error__')) {
          return false;
        }
        result = await userService.updateUser(supervisor);
        if (result.contains('error__')) {
          String messege = result.split('error__').last;
          switch (messege) {
            case 'weak-password':
              _displayError('Please provide a strong password');
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
            CustomDialog.showSnack(context, 'Supervisor updated', () {});
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Supervisor profile',
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
            Card(
              child: TextButton(
                child: const Icon(
                  Icons.add_a_photo,
                  color: Colors.blue,
                  size: 50,
                ),
                onPressed: pickImage,
              ),
            ),
            Card(
              child: TextField(
                controller: nameController,
                readOnly: readOnly,
                decoration: const InputDecoration(
                  labelText: "Name",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: dobController,
                readOnly: readOnly,
                decoration: const InputDecoration(
                  labelText: "Date of birth dd-mm-yy",
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
                  labelText: "Mobile number.(This field is read only)",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: emailController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Email (This field is read only)",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Old password.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "New password.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm new password.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
                child: DropdownButton<String>(
              value: divisionValue,
              icon: const Icon(Icons.arrow_downward),
              iconSize: 24,
              elevation: 16,
              isExpanded: true,
              style: const TextStyle(color: Colors.black),
              underline: Container(
                height: 1,
                color: Colors.black,
              ),
              onChanged: null,
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
                readOnly: readOnly,
                decoration: const InputDecoration(
                  labelText: "PAN number.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: aadharController,
                readOnly: readOnly,
                decoration: const InputDecoration(
                  labelText: "Aadhar id.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: areaController,
                readOnly: readOnly,
                decoration: const InputDecoration(
                  labelText: "Area.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: cityController,
                readOnly: readOnly,
                decoration: const InputDecoration(
                  labelText: "City.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: pinController,
                readOnly: readOnly,
                decoration: const InputDecoration(
                  labelText: "PIN.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: stateController,
                readOnly: readOnly,
                decoration: const InputDecoration(
                  labelText: "State.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Text(
              errorText,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(
              height: 30,
            ),
            ElevatedButton(
              onPressed: () => updateSupervisor(context),
              child: const Text(
                'Update Profile',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
