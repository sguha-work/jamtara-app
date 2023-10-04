import 'package:bentec/models/report.dart';
import 'package:bentec/services/common.dart';
import 'package:bentec/services/extensions.dart';
import 'package:bentec/services/report_service.dart';
import 'package:bentec/widgets/agents/agent_list_reports.dart';
import 'package:bentec/widgets/reports/filter_view.dart';
import 'package:bentec/widgets/reports/filtered_report_list.dart';
import 'package:flutter/material.dart';
import 'package:bentec/utility/views/custom_cached_network_image.dart';
import '../../services/user_service.dart';
import '../../models/user.dart';

class SupervisorListForReports extends StatefulWidget {
  var sections = ['Supervisor', 'Agent', 'Report'];
  int sectionIndex = 0;

  SupervisorListForReports({Key? key}) : super(key: key);
  @override
  State<SupervisorListForReports> createState() =>
      _SupervisorListForReportsState();
}

class _SupervisorListForReportsState extends State<SupervisorListForReports> {
  UserService userService = UserService();
  List<String> assignedDivisionList = [];
  String _selectedDivision = '';
  int groupValue = 1;
  String txt = '';
  String? _loggedInUserType;
  UserModel? _loggedInUser;
  //String _selectedFileUploadStatus = '';
  int _totalReportCount = 0;
  int _totalSupervisorCount = 0;
  final ReportService _reportService = ReportService();
  List<UserModel>? _listOfSupervisor = [];
  List<Card> _supervisorCardForReports = [];
  final int _pageLength = 10;
  var lastDoc = null;
  bool _lastPageReached = false;
  bool _fetchingData = true;
  late final ScrollController _scrollController = ScrollController();

  @override
  initState() {
    super.initState();

    _fetchLoggedInUserType();
    _scrollController.addListener(() {
      if (_scrollController.position.atEdge) {
        if (_scrollController.position.pixels == 0) {
          // You're at the top.
        } else {
          // You're at the bottom.
          Common.customLog('Fetch and set next bunch of data.......');
          if (!_lastPageReached) {
            prepareSupervisorList();
          }
        }
      }
    });
  }

  _fetchLoggedInUserType() async {
    String? userId = await userService.getCurrentUserId();
    if (userId != null) {
      _loggedInUser = await userService.getUserById(userId);
      if (_loggedInUser != null) {
        _loggedInUserType = _loggedInUser?.userType;
        _getDivisionListForAdmin();
      }
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
      _getAndSetListOfSupervisors();
    }
  }

  void sectionForward() {
    setState(() {
      if (widget.sectionIndex < widget.sections.length - 1) {
        widget.sectionIndex += 1;
      }
    });
  }

  void sectionBackward() {
    setState(() {
      if (widget.sectionIndex > 0) {
        widget.sectionIndex -= 1;
      }
    });
  }

  void showFilterForm(BuildContext cntxt) {
    List<UserModel> supervisorList = [];
    if (_listOfSupervisor != null && _listOfSupervisor!.isNotEmpty) {
      supervisorList = _listOfSupervisor ?? [];
    }
    showDialog(
      barrierDismissible: false,
      context: cntxt,
      builder: (BuildContext context) =>
          _showFilterPopup(cntxt, supervisorList),
    );
  }

  void hideUploadView(BuildContext cntxt) {
    Navigator.of(context).pop();
  }

  Widget _showFilterPopup(
      BuildContext context, List<UserModel> listOfSupervisor) {
    return AlertDialog(
      elevation: 5,
      insetPadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      content: FilterView(
          searchBtnClickedOnFilter,
          cancelBtnClickedOnFilter,
          listOfSupervisor,
          _loggedInUserType!,
          _loggedInUserType == 'admin' ? _loggedInUser : null),
    );
  }

  void searchBtnClickedOnFilter(
      String basedOnUserType,
      String? phoneNumber,
      String? selectedDivision,
      List<String>? divisions,
      DateTime startDateTime,
      DateTime endDateTime) {
    Common.customLog('Start date --' + startDateTime.toString());
    Common.customLog('End date --' + endDateTime.toString());
    Common.customLog('basedOnUserType--' + basedOnUserType);
    Common.customLog('phoneNumber--' + phoneNumber.toString());
    Common.customLog('selectedDivision--' + selectedDivision.toString());
    Common.customLog('divisions--' + divisions.toString());
    DateTime startDate = startDateTime;
    DateTime endDate =
        startDateTime.isSameDate(endDateTime) ? startDateTime : endDateTime;
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilteredReportList(basedOnUserType, phoneNumber,
            selectedDivision, divisions, startDate, endDate),
      ),
    );
  }

  void cancelBtnClickedOnFilter() {
    Navigator.of(context).pop();
  }

  Future _getAndSetListOfSupervisors() async {
    Common.customLog('User type ---->' + _loggedInUserType!);
    switch (_loggedInUserType) {
      case 'admin':
        final result = await Future.wait([
          _reportService.getTotalReportCountBasedOnDivision(_selectedDivision),
          userService.getAllSupervisorCount(_selectedDivision),
        ]);
        setState(() {
          _totalReportCount = result[0];
          _totalSupervisorCount = result[1];
        });
        break;
      case 'superadmin':
        final result = await Future.wait([
          _reportService.getTotalReportCount(),
          userService.getAllSupervisorCount(null)
        ]);
        setState(() {
          _totalReportCount = result[0];
          _totalSupervisorCount = result[1];
        });
        break;
      default:
    }
    prepareSupervisorList();
  }

  void prepareSupervisorList() async {
    switch (_loggedInUserType) {
      case 'admin':
        setState(() {
          _fetchingData = true;
        });
        var docs = await userService.getAllSupervisorsWithPagination(
            _pageLength,
            startAfter: lastDoc,
            division: _selectedDivision);
        _listOfSupervisor = _getSupervisorListFromDocumentSnapshots(docs);
        if (docs.length < _pageLength) {
          _lastPageReached = true;
        }
        lastDoc = docs.last;
        break;
      case 'superadmin':
        setState(() {
          _fetchingData = true;
        });

        var docs = await userService
            .getAllSupervisorsWithPagination(_pageLength, startAfter: lastDoc);
        _listOfSupervisor = _getSupervisorListFromDocumentSnapshots(docs);
        if (docs.length < _pageLength) {
          _lastPageReached = true;
        }
        lastDoc = docs.last;
        break;
      default:
    }

    if (_listOfSupervisor != null || _listOfSupervisor!.isNotEmpty) {
      List<Card> supervisorList = [];
      for (UserModel supervisor in _listOfSupervisor!) {
        int reportListLength = await _reportService
            .getReportListLengthBasedOnSupervisor(supervisor.id);
        List<UserModel>? agentList =
            await userService.getAllAgentBasedOnCreator(supervisor.id);
        int numberOfAgent;
        if (agentList == null) {
          numberOfAgent = 0;
        } else {
          numberOfAgent = agentList.length;
        }
        supervisorList.add(
          Card(
            child: ListTile(
              title: Text(supervisor.fullName),
              subtitle: Text(numberOfAgent.toString() +
                  ' Agents | ' +
                  reportListLength.toString() +
                  ' Reports '),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              leading: CustomCachedNetworkImage.showNetworkImage(
                supervisor.imageFilePath,
                60,
              ),
              selected: false,
              onTap: () {
                _displayAgentsUnderSupervisor(supervisor);
              },
            ),
          ),
        );
      }

      setState(() {
        _supervisorCardForReports.addAll(supervisorList);
      });
      Common.customLog('Supervisor list count..........' +
          _supervisorCardForReports.length.toString());
    }
    setState(() {
      _fetchingData = false;
    });
    Common.customLog(
        "_lastPageReached.........." + _lastPageReached.toString());
  }

  _getSupervisorListFromDocumentSnapshots(var docs) {
    List<UserModel> supervisorList = [];
    for (var doc in docs) {
      UserModel user = UserModel(
          id: doc.reference.id.toString(),
          fullName: doc.data().toString().contains("fullName")
              ? doc.get("fullName")
              : "",
          dateOfBirth: doc.data().toString().contains("dateOfBirth")
              ? doc.get("dateOfBirth")
              : "",
          email:
              doc.data().toString().contains("email") ? doc.get("email") : "",
          phoneNumber: doc.data().toString().contains("phoneNumber")
              ? doc.get("phoneNumber")
              : "",
          userType: doc.data().toString().contains("userType")
              ? doc.get("userType")
              : "",
          division: doc.data().toString().contains("division")
              ? doc.get("division")
              : "",
          area: doc.data().toString().contains("area") ? doc.get("area") : "",
          city: doc.data().toString().contains("city") ? doc.get("city") : "",
          pin: doc.data().toString().contains("pin") ? doc.get("pin") : "",
          state:
              doc.data().toString().contains("state") ? doc.get("state") : "",
          panNumber: doc.data().toString().contains("panNumber")
              ? doc.get("panNumber")
              : "",
          aadharNumber: doc.data().toString().contains("aadharNumber")
              ? doc.get("aadharNumber")
              : "",
          isApprovedByAdmin: doc.data().toString().contains("isApprovedByAdmin")
              ? doc.get("isApprovedByAdmin")
              : "",
          isRejectedByAdmin: doc.data().toString().contains("isRejectedByAdmin")
              ? doc.get("isRejectedByAdmin")
              : "",
          createdOn: doc.data().toString().contains("createdOn")
              ? doc.get("createdOn")
              : "",
          approvedOn: doc.data().toString().contains("approvedOn")
              ? doc.get("approvedOn")
              : "",
          imageFilePath: doc.data().toString().contains("imagePath")
              ? ((doc.get("imagePath") != null && doc.get("imagePath") != "")
                  ? doc.get("imagePath")
                  : "")
              : "");
      supervisorList.add(user);
    }
    return supervisorList;
  }

  void _displayAgentsUnderSupervisor(UserModel supervisor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgentListForReports(true, supervisor),
      ),
    ).then((value) {
      return value ? _getAndSetListOfSupervisors() : null;
    });
  }

  void _selectedDivisionChanged(String? division) {
    if (division != null) {
      _supervisorCardForReports.clear();
      _listOfSupervisor?.clear();
      setState(() {
        _supervisorCardForReports = [
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
        _totalReportCount = 0;
      });
      _getAndSetListOfSupervisors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      widthFactor: double.infinity,
      heightFactor: double.infinity,
      child: Column(
        children: [
          SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => showFilterForm(context),
                  icon: const Icon(Icons.filter_alt_rounded),
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
              ],
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          //   child: Text(
          //     _totalReportCount.toString() +
          //         ' Reports uploaded under ' +
          //         (_supervisorCardForReports.length == 1
          //                 ? 0
          //                 : _supervisorCardForReports.length)
          //             .toString() +
          //         ' supervisors',
          //     style: const TextStyle(
          //       fontSize: 18,
          //       fontWeight: FontWeight.bold,
          //     ),
          //     textAlign: TextAlign.center,
          //   ),
          // ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              _totalReportCount.toString() +
                  ' Reports uploaded under ' +
                  _totalSupervisorCount.toString() +
                  ' supervisors',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (_fetchingData) ...[
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
          ],
          if (_supervisorCardForReports.length == 0 &&
              _fetchingData == false) ...[
            Card(
              child: ListTile(
                title: const Text('No supervisors found'),
                subtitle: const Text(''),
                selected: false,
                onTap: () {},
              ),
            )
          ] else ...[
            Expanded(
              child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _supervisorCardForReports.length,
                  itemBuilder: (cntxt, index) {
                    return _supervisorCardForReports[index];
                  }),
            ),
          ],
        ],
      ),
    );
  }
  /*
  ListView(
              children: _supervisorCardForReports, //supervisorCardForReports
            ),
  */
//_scrollController
// void uploadSupervisors(BuildContext context) async {
//   late PlatformFile selectedFile;
//   FilePickerResult? result = await FilePicker.platform.pickFiles(
//       allowMultiple: false,
//       withData: true,
//       type: FileType.custom,
//       allowedExtensions: ['csv']);
//   try {
//     if (result != null) {
//       setState(() {
//         _selectedFileUploadStatus =
//             result.files.first.name + ' is now loading';
//       });
//       selectedFile = result.files.first;
//       String? resultString =
//           await userService.uploadSupervisorFromCSV(selectedFile);
//       if (resultString.contains('error__')) {
//         String errorMessege = resultString.split('error__').last;
//         switch (errorMessege) {
//           case 'email-is-not-formatted-properly':
//             setState(() {
//               _selectedFileUploadStatus =
//                   'One or more email id is not well formatted';
//             });
//             break;
//           case 'phonenumber-is-not-valid':
//             setState(() {
//               _selectedFileUploadStatus =
//                   'One or more phone number d is not well formatted';
//             });
//             break;
//           default:
//             setState(() {
//               _selectedFileUploadStatus = errorMessege;
//             });
//         }
//       } else {
//         setState(() {
//           _selectedFileUploadStatus = 'All supervisors loaded from the file';
//         });
//       }
//     } else {
//       setState(() {
//         _selectedFileUploadStatus = 'Unable to load file. Exiting---';
//       });
//     }
//   } catch (error) {
//     setState(() {
//       _selectedFileUploadStatus = 'Unable to load file. Exiting---';
//     });
//   }
//   hideUploader(context);
// }

// void hideUploader(BuildContext context) {
//   Future.delayed(const Duration(milliseconds: 5000), () {
//     setState(() {
//       _selectedFileUploadStatus = '';
//     });
//     hideUploadView(context);
//   });
// }
}
