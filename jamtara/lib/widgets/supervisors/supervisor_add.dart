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

class AddSupervisor extends StatefulWidget {
  const AddSupervisor();

  @override
  State<AddSupervisor> createState() => _AddSupervisor();
}

class _AddSupervisor extends State<AddSupervisor> {
  final UserService userService = UserService();
  final DivisionService divisionService = DivisionService();
  String errorText = '';
  String selectedDivision = 'Select Division';
  // List<Map<String, String>> regionCodesFromDB = [
  //   {'text': 'Select division', 'value': '-1'}
  // ];
  List<String> divisionList = ['Select Division'];
  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
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

    setState(() {
      _imageFile = File(pickedFile!.path);
    });
  }

  _AddSupervisor() {
    _getDivisions();
  }
  Future<void> _getDivisions() async {
    String? loggedInUserId = await userService.getCurrentUserId();
    if (loggedInUserId != null) {
      UserModel? loggedInUser = await userService.getUserById(loggedInUserId);
      if (loggedInUser != null) {
        List<String> _divisions = loggedInUser.divisions;
        Common.customLog('Divisions --->' + _divisions.toString());
        setState(() {
          divisionList = _divisions;
          selectedDivision = _divisions.first;
        });
      }
    }

    // List<DivisionModel> regionList = await divisionService.getAllDivision();
    // List<Map<String, String>> valuesForDropdown = [];
    // valuesForDropdown.add({'text': 'Select division', 'value': '-1'});
    // for (var region in regionList) {
    //   valuesForDropdown.add({'text': region.code, 'value': region.code});
    // }
    // setState(() {
    //   regionCodesFromDB = valuesForDropdown;
    // });
  }

  bool _validate() {
    setState(() {
      errorText = '';
    });
    if (!Common.isValidMobileNumber(phoneNumberController.text)) {
      _displayError('Supervisor phone number is wrongly given');
      return false;
    }
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
    if (passwordController.text.trim() == '') {
      _displayError('Supervisor password cannot be empty');
      return false;
    }
    if (passwordController.text.trim() != confirmPasswordController.text) {
      _displayError('Supervisor password must be confirmed');
      return false;
    }

    if (selectedDivision == '' || selectedDivision == 'Select Division') {
      _displayError('Please select division');
      return false;
    }
    if (panNumberController.text.trim() == '' ||
        !Common.isValidPANNumber(panNumberController.text.trim())) {
      _displayError('Please enter a valid PAN no.');
      return false;
    }
    if (aadharController.text.trim() == '' ||
        !Common.isValidAadharNumber(aadharController.text.trim())) {
      _displayError('Please enter a valid aadhar no.');
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
    selectedDivision = '';
    nameController.clear();
    dobController.clear();
    phoneNumberController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    panNumberController.clear();
    aadharController.clear();
    areaController.clear();
    cityController.clear();
    pinController.clear();
    stateController.clear();
    _imageFile = null;
  }

  void addSupervisor(BuildContext context) async {
    if (_validate()) {
      CustomDialog.showConfirmDialog(
          context, 'Do you want to proceed with adding the supervisor?',
          () async {
        String? currentLoggedInUserId =
            await userService.getCurrentUserId() ?? '';
        UserModel supervisor = UserModel(
            fullName: nameController.text.trim(),
            email: emailController.text.trim(),
            isApprovedByAdmin: true,
            isRejectedByAdmin: false,
            area: areaController.text.trim(),
            phoneNumber: phoneNumberController.text.trim(),
            division: selectedDivision,
            userType: 'supervisor',
            aadharNumber: aadharController.text.trim(),
            city: cityController.text.trim(),
            panNumber: panNumberController.text.trim(),
            password: passwordController.text.trim(),
            pin: pinController.text.trim(),
            state: stateController.text.trim(),
            createdOn: DateTime.now().millisecondsSinceEpoch.toString(),
            createdByUserId: currentLoggedInUserId.toString(),
            approvedOn: DateTime.now().millisecondsSinceEpoch.toString(),
            dateOfBirth: dobController.text.trim(),
            approvedByUserId: currentLoggedInUserId.toString());

        if (_imageFile != null) {
          supervisor.imageFile = _imageFile;
        }

        CustomDialog.showLoadingDialogue(context);
        // adding user
        String result = await userService.addSupervisor(supervisor);
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
            CustomDialog.showSnack(context, 'Supervisor added', () {
              Navigator.pop(context, true);
            });
          });
        } else {
          CustomDialog.hideLoadingDialogue(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Supervisor',
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
                decoration: const InputDecoration(
                  labelText: "Enter supervisor's name",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: dobController,
                decoration: const InputDecoration(
                  labelText: "Enter supervisor's date of birth dd-mm-yy",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: phoneNumberController,
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
                decoration: const InputDecoration(
                  labelText: "Enter supervisor's email ",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Enter supervisor's password.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm supervisor's password.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
                child: DropdownButton<String>(
              value: selectedDivision,
              icon: const Icon(Icons.arrow_downward),
              iconSize: 24,
              elevation: 16,
              isExpanded: true,
              style: const TextStyle(color: Colors.black),
              underline: Container(
                height: 1,
                color: Colors.black,
              ),
              onChanged: (String? newValue) {
                setState(() {
                  selectedDivision = newValue!;
                });
              },
              items: divisionList.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            )),
            Card(
              child: TextField(
                controller: panNumberController,
                decoration: const InputDecoration(
                  labelText: "Enter supervisor's PAN number.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: aadharController,
                decoration: const InputDecoration(
                  labelText: "Enter supervisor's Aadhar id.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: areaController,
                decoration: const InputDecoration(
                  labelText: "Enter area.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: "Enter city.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: pinController,
                decoration: const InputDecoration(
                  labelText: "Enter pin.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: stateController,
                decoration: const InputDecoration(
                  labelText: "Enter state.",
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
              onPressed: () => addSupervisor(context),
              child: const Text(
                'Add Supervisor',
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
