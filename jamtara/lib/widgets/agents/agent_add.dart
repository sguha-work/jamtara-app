import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bentec/models/division.dart';
import '../../services/common.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import '../../services/division_service.dart';
import '../../services/dialogue.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddAgent extends StatefulWidget {
  const AddAgent({Key? key}) : super(key: key);

  @override
  State<AddAgent> createState() => _AddAgent();
}

class _AddAgent extends State<AddAgent> {
  final UserService userService = UserService();
  final DivisionService divisionService = DivisionService();
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

  String errorText = '';
  String divisionValue = '-1';
  File? _imageFile;
  List<Map<String, String>> divisionsFromDB = [
    {'text': 'Select division', 'value': '-1'}
  ];

  _AddAgent() {
    _getDivisionsFromDB();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Agent',
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
                  labelText: "Enter agent's name",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: dobController,
                decoration: const InputDecoration(
                  labelText: "Enter agent's date of birth dd-mm-yy",
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
                  labelText: "Enter agent's mobile no.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Enter agent's email ",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Enter agent's password.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm agent's password.",
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
              onChanged: (String? newValue) {
                setState(() {
                  divisionValue = newValue!;
                });
              },
              items: divisionsFromDB.map((Map<String, String> data) {
                return DropdownMenuItem<String>(
                  value: data['value'],
                  child: Text(data['text'].toString()),
                );
              }).toList(),
            )),
            Card(
              child: TextField(
                controller: panNumberController,
                decoration: const InputDecoration(
                  labelText: "Enter agent's PAN number.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: aadharController,
                decoration: const InputDecoration(
                  labelText: "Enter agent's Aadhar id.",
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
              onPressed: () => addAgent(context),
              child: const Text(
                'Add Agent',
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

  // Instance methods
  Future pickImage() async {
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    setState(() {
      _imageFile = File(pickedFile!.path);
    });
  }

  Future<void> _getDivisionsFromDB() async {
    List<DivisionModel> regionList = await divisionService.getAllDivision();
    // getting region code of supervisor
    String currentLoggedInUserRegion =
        await userService.getDivisionOfCurrentUser();

    List<Map<String, String>> valuesForDropdown = [];
    valuesForDropdown.add({'text': 'Select division', 'value': '-1'});
    for (var region in regionList) {
      valuesForDropdown.add({'text': region.code, 'value': region.code});
    }
    setState(() {
      divisionsFromDB = valuesForDropdown;
      if (currentLoggedInUserRegion != '') {
        divisionValue = currentLoggedInUserRegion;
      }
    });
  }

  bool _validateInputDetails() {
    if (phoneNumberController.text.trim() == '') {
      _displayError('Agent mobile number cannot be empty');
      return false;
    }
    if (!Common.isValidMobileNumber(phoneNumberController.text)) {
      _displayError('Agent phone number is wrongly given');
      return false;
    }
    if (nameController.text.trim() == '') {
      _displayError('Agent name cannot be empty');
      return false;
    }
    if (emailController.text.trim() == '') {
      _displayError('Agent email cannot be empty');
      return false;
    }
    if (!Common.isValidEmail(emailController.text.trim())) {
      _displayError('Please enter a valid email');
      return false;
    }
    if (passwordController.text.trim() == '') {
      _displayError('Agent password cannot be empty');
      return false;
    }
    if (passwordController.text.trim() != confirmPasswordController.text) {
      _displayError('Agent password must be confirmed');
      return false;
    }
    if (!Common.isValidEmail(emailController.text)) {
      _displayError('Agent email is wrongly given');
      return false;
    }
    if (divisionValue == '-1') {
      _displayError('Please select division');
      return false;
    }
    if (!Common.isValidPANNumber(panNumberController.text)) {
      _displayError('Agent PAN is wrongly given');
      return false;
    }
    if (!Common.isValidAadharNumber(aadharController.text)) {
      _displayError('Agent aadhar is wrongly given');
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
    divisionValue = '-1';
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

  void addAgent(BuildContext context) async {
    if (_validateInputDetails()) {
      CustomDialog.showConfirmDialog(
          context, 'Do you want to proceed with adding the agent', () async {
        String? currentLoggedInUserId =
            await userService.getCurrentUserId() ?? '';
        UserModel agent = UserModel(
            fullName: nameController.text.trim(),
            email: emailController.text.trim(),
            isApprovedByAdmin: false,
            isRejectedByAdmin: false,
            area: areaController.text.trim(),
            phoneNumber: phoneNumberController.text.trim(),
            division: divisionValue,
            userType: 'agent',
            aadharNumber: aadharController.text.trim(),
            city: cityController.text.trim(),
            panNumber: panNumberController.text.trim(),
            password: passwordController.text.trim(),
            pin: pinController.text.trim(),
            state: stateController.text.trim(),
            createdOn: DateTime.now().millisecondsSinceEpoch.toString(),
            createdByUserId: currentLoggedInUserId.toString(),
            approvedOn: '',
            dateOfBirth: dobController.text.trim(),
            approvedByUserId: '');

        if (_imageFile != null) {
          agent.imageFile = _imageFile;
        }

        CustomDialog.showLoadingDialogue(context);
        // adding user
        String result = await userService.addUser(agent);
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
            CustomDialog.showSnack(context, 'Agent added', () {
              Navigator.pop(context, true);
            });
          });
        } else {
          CustomDialog.hideLoadingDialogue(context);
        }
      });
    }
  }
}
