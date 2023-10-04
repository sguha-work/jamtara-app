import 'dart:ffi';

import 'package:bentec/services/common.dart';
import 'package:flutter/material.dart';
import 'package:bentec/services/dialogue.dart';
import 'package:bentec/utility/views/custom_cached_network_image.dart';
import 'package:bentec/utility/views/progress_view.dart';
import 'package:bentec/widgets/supervisors/supervisor_add.dart';
import '../../services/user_service.dart';
import '../../models/user.dart';
import 'supervisor_edit.dart';
import 'package:file_picker/file_picker.dart';

class SupervisorList extends StatefulWidget {
  @override
  State<SupervisorList> createState() => _SupervisorListState();
}

class _SupervisorListState extends State<SupervisorList> {
  List<String> assignedDivisionList = [];
  String _selectedDivision = '';
  String? _loggedInUserType;
  int groupValue = 1;
  String txt = '';
  String _selectedFileUploadStatus = '';
  List<Card> supervisorCardForDetails = [
    Card(
      child: ListTile(
        title: const Text('Loading supervisor list ...'),
        subtitle: const Text(''),
        selected: false,
        onTap: () {},
        leading: const CircularProgressIndicator(
          backgroundColor: Colors.yellow,
        ),
      ),
    )
  ];

  UserService userService = UserService();
  _SupervisorListState() {
    _setloggedInUserType();
  }
  void _setloggedInUserType() async {
    _loggedInUserType = await userService.getCurrentUserType();
    if (_loggedInUserType != null) {
      _getDivisionListForAdmin();
    }
  }

  _getDivisionListForAdmin() async {
    String? currentLoggedInUserId = await userService.getCurrentUserId();
    if (currentLoggedInUserId != null) {
      UserModel? admin = await userService.getUserById(currentLoggedInUserId);
      if (admin != null && admin.divisions.isNotEmpty) {
        setState(() {
          assignedDivisionList = admin.divisions;
          _selectedDivision = assignedDivisionList.first;
        });
      }
      _getAndSetListOfSupervisors(_selectedDivision);
    }
  }

  void addSupervisor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddSupervisor()),
    ).then((value) {
      return value ? _getAndSetListOfSupervisors(_selectedDivision) : null;
    });
  }

  void showUploadView(BuildContext cntxt) {
    Common.customLog('Show upload called...........');
    showDialog(
      barrierDismissible: false,
      context: cntxt,
      builder: (BuildContext context) => _showUploadPopup(cntxt),
    );
  }

  void hideUploadView(BuildContext cntxt) {
    Navigator.of(context).pop();
  }

  Widget _showUploadPopup(BuildContext context) {
    return AlertDialog(
      elevation: 5,
      content: SizedBox(
        height: 200,
        width: 300,
        child: Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => hideUploadView(context),
                    icon: Icon(Icons.cancel_rounded),
                  )
                ],
              ),
              ElevatedButton(
                child: const Text(
                  'Select file to upload.',
                ),
                onPressed: () => uploadSupervisors(context),
              ),
              Text(
                _selectedFileUploadStatus,
              ),
              const SizedBox(height: 50, child: ProgressView()),
            ],
          ),
        ),
      ),
    );
  }

  void uploadSupervisors(BuildContext context) async {
    late PlatformFile selectedFile;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['csv']);
    try {
      if (result != null) {
        setState(() {
          _selectedFileUploadStatus =
              result.files.first.name + ' is now loading';
        });
        selectedFile = result.files.first;
        String? resultString =
            await userService.uploadSupervisorFromCSV(selectedFile);
        if (resultString.contains('error__')) {
          String errorMessege = resultString.split('error__').last;
          switch (errorMessege) {
            case 'email-is-not-formatted-properly':
              setState(() {
                _selectedFileUploadStatus =
                    'One or more email id is not well formatted';
              });
              break;
            case 'phonenumber-is-not-valid':
              setState(() {
                _selectedFileUploadStatus =
                    'One or more phone number d is not well formatted';
              });
              break;
            default:
              setState(() {
                _selectedFileUploadStatus = errorMessege;
              });
          }
        } else {
          setState(() {
            _selectedFileUploadStatus = 'All supervisors loaded from the file';
          });
        }
      } else {
        setState(() {
          _selectedFileUploadStatus = 'Unable to load file. Exiting---';
        });
      }
    } catch (error) {
      setState(() {
        _selectedFileUploadStatus = 'Unable to load file. Exiting---';
      });
    }
    hideUploader(context);
  }

  void hideUploader(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 5000), () {
      setState(() {
        _selectedFileUploadStatus = '';
      });
      hideUploadView(context);
    });
  }

  void _getAndSetListOfSupervisors(String division) async {
    List<UserModel>? listOfSupervisor;
    switch (_loggedInUserType) {
      case 'admin':
        listOfSupervisor = await userService.getAllUserBasedOnDivision(
            division: _selectedDivision, userType: 'supervisor');
        break;
      case 'superadmin':
        listOfSupervisor = await userService.getAllSupervisor();
        break;
      default:
    }

    if (listOfSupervisor == null || listOfSupervisor.isEmpty) {
      setState(() {
        supervisorCardForDetails = [
          Card(
            child: ListTile(
              title: Text('No supervisors found'),
              isThreeLine: true,
              subtitle: const Text(''),
              selected: false,
              onTap: () {},
            ),
          )
        ];
      });
    } else {
      List<Card> supervisorList = [];
      for (UserModel supervisor in listOfSupervisor) {
        supervisorList.add(
          Card(
            child: ListTile(
              title: Text(supervisor.fullName),
              isThreeLine: true,
              subtitle: Text('Contact number(+91) ' +
                  supervisor.phoneNumber +
                  ' Division code: ' +
                  supervisor.division),
              trailing: const Icon(
                Icons.manage_accounts_outlined,
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              leading: CustomCachedNetworkImage.showNetworkImage(
                supervisor.imageFilePath,
                60,
              ),
              selected: false,
              onTap: () {
                _editSupervisor(supervisor);
              },
            ),
          ),
        );
      }
      setState(() {
        supervisorCardForDetails = supervisorList;
      });
    }
  }

  void _editSupervisor(UserModel supervisor) {
    Common.customLog(supervisor);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSupervisor(supervisor),
      ),
    ).then((value) {
      return value ? _getAndSetListOfSupervisors(_selectedDivision) : null;
    });
  }

  void _selectedDivisionChanged(String? division) {
    if (division != null) {
      supervisorCardForDetails.clear();
      setState(() {
        supervisorCardForDetails = [
          Card(
            child: ListTile(
              title: const Text('Loading supervisor list ...'),
              subtitle: const Text(''),
              selected: false,
              onTap: () {},
              leading: const CircularProgressIndicator(
                backgroundColor: Colors.yellow,
              ),
            ),
          )
        ];
        _selectedDivision = division;
      });
      _getAndSetListOfSupervisors(_selectedDivision);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      widthFactor: double.infinity,
      heightFactor: double.infinity,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => showUploadView(context),
                icon: const Icon(Icons.upload_rounded),
              ),
              if (assignedDivisionList.isNotEmpty &&
                  _loggedInUserType == 'admin') ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: DropdownButton<String>(
                    value: _selectedDivision,
                    icon: const Icon(Icons.arrow_downward),
                    elevation: 16,
                    onChanged: (String? newValue) {
                      _selectedDivisionChanged(newValue);
                    },
                    items: assignedDivisionList
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ],
              IconButton(
                onPressed: () => addSupervisor(context),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              children: supervisorCardForDetails,
            ),
          ),
        ],
      ),
    );
  }
}
