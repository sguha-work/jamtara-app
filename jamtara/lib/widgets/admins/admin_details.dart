import 'package:bentec/models/user.dart';
import 'package:bentec/services/common.dart';
import 'package:bentec/services/dialogue.dart';
import 'package:bentec/services/user_service.dart';
import 'package:bentec/widgets/regions/division_list.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:io' as io;

class AdminDetails extends StatefulWidget {
  final UserModel? adminModel;
  final bool readOnly;
  final bool isProfileBeingEdited;
  final bool isCreate;
  final bool isPartialUpdate;
  AdminDetails(this.adminModel, this.readOnly, this.isProfileBeingEdited,
      this.isCreate, this.isPartialUpdate);
  @override
  State<AdminDetails> createState() => _AdminDetailsState();
}

class _AdminDetailsState extends State<AdminDetails> {
  UserService userService = UserService();
  TextEditingController nameController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  String errorText = '';
  final picker = ImagePicker();
  File? _imageFile;
  String imageFilePath = '';
  bool isNewImagePicked = false;
  bool isPasswordChanged = false;

  List<String> assignedDivision = [];

  @override
  initState() {
    super.initState();
    prepareAdminDetails(widget.adminModel);
  }

  Future<void> prepareAdminDetails(UserModel? adminModel) async {
    if (adminModel != null) {
      if (widget.readOnly || widget.isProfileBeingEdited) {
        setState(() {
          emailController.text = adminModel.email;
          nameController.text = adminModel.fullName;
          phoneNumberController.text = adminModel.phoneNumber;
          dobController.text = adminModel.dateOfBirth;
        });
        assignedDivision = adminModel.divisions;
        File? imageFile;
        if (adminModel.imageFilePath != '') {
          // image path is the url of fire storage
          imageFilePath = adminModel.imageFilePath;
          imageFile = await Common.fileFromImageUrl(adminModel.imageFilePath);
          setState(() {
            _imageFile = imageFile;
          });
        } else {
          imageFile = null;
        }
      }
    }
  }

  Future pickImage() async {
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    isNewImagePicked = true;
    setState(() {
      _imageFile = File(pickedFile!.path);
    });
  }

  void _displayError(String message) {
    setState(() {
      errorText = message;
    });
  }

  void _addAdmin(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
    if (_validateInputDetails()) {
      CustomDialog.showConfirmDialog(
          context, 'Do you want to proceed with adding the admin', () async {
        String? currentLoggedInUserId =
            await userService.getCurrentUserId() ?? '';
        UserModel admin = UserModel(
          fullName: nameController.text.trim(),
          dateOfBirth: dobController.text.trim(),
          phoneNumber: phoneNumberController.text.trim(),
          email: emailController.text.trim(),
          divisions: assignedDivision,
          createdByUserId: currentLoggedInUserId,
          createdOn: DateTime.now().millisecondsSinceEpoch.toString(),
          userType: 'admin',
          password: passwordController.text.trim(),
        );
        if (_imageFile != null) {
          admin.imageFile = _imageFile;
        }

        CustomDialog.showLoadingDialogue(context);
        // adding admin
        String result = await userService.addAdmin(admin);
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
            CustomDialog.showSnack(context, 'Admin added', () {
              Navigator.pop(context, true);
            });
          });
        } else {
          Common.customLog('Result-----> ' + result);
          CustomDialog.hideLoadingDialogue(context);
        }
      });
    }
  }

  void _updateAdminDetails(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
    if (_validateInputDetails()) {
      CustomDialog.showConfirmDialog(
          context, 'Do you want to proceed with adding the admin', () async {
        String? currentLoggedInUserId =
            await userService.getCurrentUserId() ?? '';
        UserModel admin = UserModel(
          id: currentLoggedInUserId,
          fullName: nameController.text.trim(),
          dateOfBirth: dobController.text.trim(),
          phoneNumber: phoneNumberController.text.trim(),
          email: emailController.text.trim(),
          divisions: assignedDivision,
          createdByUserId: widget.adminModel!.createdByUserId,
          createdOn: DateTime.now().millisecondsSinceEpoch.toString(),
          userType: 'admin',
          password: passwordController.text.trim(),
        );

        if (isNewImagePicked) {
          admin.imageFile = _imageFile;
          admin.imageFilePath = '';
        } else {
          admin.imageFile = null;
          admin.imageFilePath = imageFilePath;
        }

        CustomDialog.showLoadingDialogue(context);
        // updating user
        String result = '';
        if (isPasswordChanged) {
          // updating password
          await userService.changePassword(
              admin.email,
              oldPasswordController.text.trim(),
              passwordController.text.trim(), () {
            result = 'success__';
          }, (err) {
            result = 'error__';
            _displayError('Unable to update password ' + err);
          });
        }
        Common.customLog('PASSWORD CHANGE RESULT=======> ' + result);
        if (result.contains('error__')) {
          return false;
        }
        result = await userService.updateUser(admin);
        Common.customLog('Update usre CHANGE RESULT=======> ' + result);
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
            CustomDialog.showSnack(context, 'Admin updated', () {});
          });
        } else {
          CustomDialog.hideLoadingDialogue(context);
        }
      });
    }
  }

  bool _validateInputDetails() {
    if (nameController.text.trim() == '') {
      _displayError('Admin name cannot be empty');
      return false;
    }
    if (dobController.text.trim() == '') {
      _displayError('Admin date of birth cannot be empty');
      return false;
    }
    if (phoneNumberController.text.trim() == '') {
      _displayError('Admin mobile number cannot be empty');
      return false;
    }
    if (!Common.isValidMobileNumber(phoneNumberController.text)) {
      _displayError('Admin phone number is wrongly given');
      return false;
    }

    if (emailController.text.trim() == '') {
      _displayError('Admin email cannot be empty');
      return false;
    }
    if (!Common.isValidEmail(emailController.text.trim())) {
      _displayError('Please enter a valid email');
      return false;
    }
    if (widget.isProfileBeingEdited) {
      if (passwordController.text.trim() != '') {
        isPasswordChanged = true;
        if (oldPasswordController.text.trim() == '') {
          _displayError('To change password please enter old password first');
          return false;
        }
        if (passwordController.text.trim() != confirmPasswordController.text) {
          _displayError('Admin password must be confirmed');
          return false;
        }
      } else {
        isPasswordChanged = false;
      }
    } else {
      if (passwordController.text.trim() == '') {
        _displayError('Admin password cannot be empty');
        return false;
      }
      if (passwordController.text.trim() != confirmPasswordController.text) {
        _displayError('Admin password must be confirmed');
        return false;
      }
    }

    if (!Common.isValidEmail(emailController.text)) {
      _displayError('Admin email is wrongly given');
      return false;
    }
    if (assignedDivision.isEmpty) {
      _displayError('Please assign one or more divisions');
      return false;
    }
    return true;
  }

  void _showDivisionList(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('DivisionList'),
          ),
          body: DivisionList(true, assignedDivision),
        ),
      ),
    ).then((value) {
      // Triggered after pop back in here
      setState(() {
        assignedDivision = value;
      });
    });
  }

  void deleteDivision(String divisionCode) {
    if (assignedDivision.isNotEmpty) {
      int? index = assignedDivision.indexOf(divisionCode);
      setState(() {
        assignedDivision.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Common.customLog('_imageFile.....');
    Common.customLog(_imageFile);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.readOnly
              ? 'Admin Details'
              : (widget.isProfileBeingEdited ? 'Profile' : 'Create admin'),
        ),
      ),
      body: SingleChildScrollView(
        // scrollDirection: Axis.vertical,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_imageFile != null) ...[
              Card(
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(30.0),
                    child: Image.file(_imageFile!, height: 200)),
              ),
            ],
            if (!widget.readOnly) ...[
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
            ],
            Card(
              child: TextField(
                controller: nameController,
                readOnly: widget.readOnly,
                decoration: const InputDecoration(
                  labelText: "Enter name",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                enableInteractiveSelection: !widget.readOnly,
                controller: dobController,
                readOnly: widget.readOnly,
                decoration: const InputDecoration(
                  labelText: "Enter date of birth dd-mm-yy",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: phoneNumberController,
                readOnly: (widget.readOnly || widget.isProfileBeingEdited)
                    ? true
                    : false,
                keyboardType: TextInputType.number,
                // inputFormatters: <TextInputFormatter>[
                //   FilteringTextInputFormatter.digitsOnly
                // ],
                decoration: const InputDecoration(
                  labelText: "Enter mobile no.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: emailController,
                readOnly: widget.readOnly,
                decoration: const InputDecoration(
                  labelText: "Enter email",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            if (widget.isProfileBeingEdited) ...[
              Card(
                child: TextField(
                  controller: oldPasswordController,
                  readOnly: widget.readOnly,
                  decoration: const InputDecoration(
                    labelText: "Old password",
                    contentPadding: EdgeInsets.all(5),
                  ),
                ),
              ),
            ],
            if (!widget.readOnly) ...[
              Card(
                child: TextField(
                  controller: passwordController,
                  readOnly: widget.readOnly,
                  decoration: const InputDecoration(
                    labelText: "Enter password",
                    contentPadding: EdgeInsets.all(5),
                  ),
                ),
              ),
              Card(
                child: TextField(
                  controller: confirmPasswordController,
                  readOnly: widget.readOnly,
                  decoration: const InputDecoration(
                    labelText: "Confirm password",
                    contentPadding: EdgeInsets.all(5),
                  ),
                ),
              ),
            ],

            if (widget.isProfileBeingEdited) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'Assigned divisions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (!widget.isProfileBeingEdited) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        _showDivisionList(context);
                      },
                      child: const Text(
                        'Assign division',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            Flexible(
              fit: FlexFit.loose,
              child: ListView.builder(
                  // scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemCount: assignedDivision.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        title: Text(
                          assignedDivision[index],
                        ),
                        trailing:
                            !widget.readOnly && !widget.isProfileBeingEdited
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                    ),
                                    onPressed: () =>
                                        deleteDivision(assignedDivision[index]),
                                  )
                                : null,
                      ),
                    );
                  }),
            ),
            // Card(
            //     child: DropdownButton<String>(
            //       value: divisionValue,
            //       icon: const Icon(Icons.arrow_downward),
            //       iconSize: 0.0, //24,
            //       elevation: 16,
            //       isExpanded: true,
            //       style: const TextStyle(color: Colors.black),
            //       underline: Container(
            //         height: 1,
            //         color: Colors.black,
            //       ),
            //       onChanged: (String? newValue) {
            //         // setState(() {
            //         //   divisionValue = newValue!;
            //         // });
            //       },
            //       items: regionCodesFromDB.map((Map<String, String> data) {
            //         return DropdownMenuItem<String>(
            //           value: data['value'],
            //           child: Text(data['text'].toString()),
            //         );
            //       }).toList(),
            //     )),

            Text(
              errorText,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.red),
            ),
            if (widget.isProfileBeingEdited || widget.isCreate) ...[
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () => !widget.isCreate
                    ? _updateAdminDetails(context)
                    : _addAdmin(context),
                child: Text(
                  !widget.isCreate ? 'Update details' : 'Add Admin',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
            ] else if (widget.isPartialUpdate) ...[
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () => _updateAdminDetails(context),
                child: const Text(
                  'Update details',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
