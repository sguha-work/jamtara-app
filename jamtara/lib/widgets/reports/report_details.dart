import 'dart:convert';

import 'package:bentec/services/dialogue.dart';
import 'package:bentec/services/report_service.dart';
import 'package:bentec/widgets/reports/edit_report_details.dart';
import 'package:flutter/material.dart';
import 'package:bentec/models/report.dart';
import 'package:bentec/models/user.dart';
import 'package:bentec/services/user_service.dart';
import 'package:bentec/utility/views/custom_cached_network_image.dart';
import '../../main.dart';
import '../../services/common.dart';

import '../app_theme.dart';

// This screen will be seen by agent
class ReportDetails extends StatefulWidget {
  final String reportId;
  const ReportDetails(this.reportId);
  @override
  State<ReportDetails> createState() => _ReportDetailsState();
}

class _ReportDetailsState extends State<ReportDetails> {
  int _imageIndex = 0;
  bool _userIsAgent = true;
  UserService userService = UserService();
  ReportService reportService = ReportService();
  UserModel _agent = UserModel();
  double opacity3 = 0.0;
  bool displaySyncIcon = false;
  bool nextImageAvailable = false;
  bool prevImageAvailable = false;
  String? userType = '';
  ReportModel? report;

  _ReportDetailsState() {
    _getCurrentUserType();
  }

  _getCurrentUserType() async {
    String? getUserType = await userService.getCurrentUserType();
    setState(() {
      userType = getUserType;
    });
    _getReportDetails();
  }

  _getReportDetails() async {
    ReportModel? reportObj =
        await reportService.getReportDetails(widget.reportId);
    if (reportObj != null) {
      setState(() {
        report = reportObj;
      });
      _getAgentInformation();
    }
  }

  _getAgentInformation() async {
    _agent = await userService.getAgentInfoFromCache();
    if (_agent.fullName != '') {
      // setState(() {});
    } else {
      _userIsAgent = false;
      _fetchSupervisorInformation();
    }

    if (_userIsAgent) {
      if (report!.isSubmitted) {
        displaySyncIcon = false;
      } else {
        displaySyncIcon = true;
      }
    } else {
      // For admin and supervisor the sync button will not be visible
      displaySyncIcon = false;
    }
  }

  _fetchSupervisorInformation() async {
    String agentId = report!.createdBy;
    if (agentId != '') {
      UserModel? agent = await userService.getUserById(agentId);
      if (agent != null) {
        _agent = agent;
        String? supervisorName =
            await userService.getUserNameById(agent.createdByUserId);
        if (supervisorName != null) {
          _agent.createdByName = supervisorName;
        }
        setState(() {});
      }
    }
  }

  _showImage(int index) {
    if (index < 0) {
      return;
    }
    if (report!.imageLinks != null) {
      if (index > (report!.imageLinks!.length - 1)) {
        return;
      }
    }
    if (report!.imageBase64StringList != null) {
      if (index > (report!.imageBase64StringList!.length - 1)) {
        return;
      }
    }
    _imageIndex = index;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // final double tempHeight = MediaQuery.of(context).size.height -
    //     (MediaQuery.of(context).size.width / 1.2) +
    //     24.0;
    return Container(
      color: AppTheme.nearlyWhite,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Report Details',
          ),
        ),
        backgroundColor: Colors.white,
        body: report != null
            ? Column(
                children: [
                  if (userType == 'admin') ...[
                    getLayoutForEditOrDeleteReport(context, report!),
                  ],
                  getLayoutForImages(context, report!),
                  getLayoutForReportDetails(context, report!),
                ],
              )
            : null,
      ),
    );
  }

  Widget getLayoutForEditOrDeleteReport(
      BuildContext context, ReportModel report) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: IconButton(
            onPressed: () => editReport(context, report),
            icon: const Icon(Icons.edit, color: Colors.black, size: 30),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: IconButton(
            onPressed: () => deleteReport(context, report),
            icon: const Icon(Icons.delete, color: Colors.black, size: 30),
          ),
        ),
      ],
    );
  }

  void deleteReport(BuildContext context, ReportModel report) {
    CustomDialog.showConfirmDialog(context, 'Do you want to delete the report?',
        () async {
      String result = '';
      result = await reportService.deleteReport(report);
      if (result.contains('success__')) {
        CustomDialog.showSnack(context, 'Report deleted', () {
          Navigator.pop(context);
        });
      } else {
        CustomDialog.showSnack(context, "Report can't be deleted", () {});
      }
    });
  }

  void editReport(BuildContext context, ReportModel report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditReportDetails(report),
      ),
    ).then((value) {
      Common.customLog('On return ');
      _getCurrentUserType();
    });
  }

  Widget getLayoutForImages(BuildContext context, ReportModel report) {
    if (report.imageLinks != null) {
      return Flexible(
        flex: 1,
        fit: FlexFit.loose,
        child: Container(
          color: Colors.transparent,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: AspectRatio(
                    aspectRatio: 1.2,
                    child: CustomCachedNetworkImage.showNetworkImageForReport(
                      report.imageLinks![_imageIndex],
                      60,
                    )),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Color.fromRGBO(0, 0, 0, 0.5),
                      radius: 20,
                      child: IconButton(
                        onPressed: () {
                          _showImage(_imageIndex - 1);
                        },
                        icon: Icon(Icons.arrow_back),
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: Color.fromRGBO(0, 0, 0, 0.5),
                      radius: 20,
                      child: IconButton(
                        onPressed: () {
                          _showImage(_imageIndex + 1);
                        },
                        icon: Icon(Icons.arrow_forward),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Flexible(
        flex: 1,
        fit: FlexFit.loose,
        child: Container(
          color: Colors.transparent,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 1.2,
                child: Image.memory(
                  base64Decode(
                    report.imageBase64StringList![_imageIndex],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Color.fromRGBO(0, 0, 0, 0.5),
                      radius: 20,
                      child: IconButton(
                        onPressed: () {
                          _showImage(_imageIndex - 1);
                        },
                        icon: Icon(Icons.arrow_back),
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: Color.fromRGBO(0, 0, 0, 0.5),
                      radius: 20,
                      child: IconButton(
                        onPressed: () {
                          _showImage(_imageIndex + 1);
                        },
                        icon: Icon(Icons.arrow_forward),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget getLayoutForReportDetails(BuildContext context, ReportModel report) {
    return Flexible(
      flex: 1,
      child: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.grey.withOpacity(0.5),
                    offset: const Offset(1.1, 1.1),
                    blurRadius: 10.0,
                  ),
                ],
              ),
              child: ScrollConfiguration(
                behavior: MyBehavior(),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(30, 30, 20, 00),
                        child: Text(
                          report.consumerName +
                              ' ( ' +
                              report.consumerNumber +
                              ')',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            letterSpacing: 0.27,
                            color: AppTheme.darkerText,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Text(
                                Common.getFormattedDateTimeFromTimeStamp(
                                    report.createdOn),
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  letterSpacing: 0.27,
                                  color: AppTheme.grey,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.timelapse,
                              color: AppTheme.nearlyBlue,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                      getDetailSection('Agent name', _agent.fullName),
                      getDetailSection('Sub-division', report.subdivision),
                      getDetailSection('Division', report.division),
                      getDetailSection('Supervisor', _agent.createdByName),
                      getDetailSection(
                          'Meter number', report.consumerMeterNumber),
                      getDetailSection('Consumer mobile number',
                          report.consumerMobileNumber),
                      getDetailSection('Consumer aadhar number',
                          report.consumerAadharNumber),
                      getDetailSection(
                          'Sealing Page Number', report.sealingPageNo),
                      if (userType != null && userType == 'admin') ...[
                        getDetailSection('Location',
                            report.latitude + ', ' + report.longitude),
                      ],
                      // AnimatedOpacity(
                      //   duration: const Duration(milliseconds: 500),
                      //   opacity: opacity3,
                      //   child: Padding(
                      //     padding: const EdgeInsets.only(
                      //         left: 16, bottom: 0, right: 16),
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       crossAxisAlignment: CrossAxisAlignment.center,
                      //     ),
                      //   ),
                      // ),
                      // Positioned(
                      //   top: (MediaQuery.of(context).size.width / 1.2) -
                      //       24.0 -
                      //       35,
                      //   right: 35,
                      //   child: displaySyncIcon
                      //       ? Container(
                      //           alignment: Alignment.center,
                      //           child: Card(
                      //             color: AppTheme.nearlyBlue,
                      //             shape: RoundedRectangleBorder(
                      //                 borderRadius:
                      //                     BorderRadius.circular(50.0)),
                      //             elevation: 10.0,
                      //             child: const SizedBox(
                      //               width: 60,
                      //               height: 60,
                      //               child: Center(
                      //                 child: Icon(
                      //                   Icons.sync,
                      //                   color: AppTheme.nearlyWhite,
                      //                   size: 30,
                      //                 ),
                      //               ),
                      //             ),
                      //           ),
                      //         )
                      //       : Container(
                      //           alignment: Alignment.center,
                      //           child: Card(
                      //             color: AppTheme.nearlyBlue,
                      //             shape: RoundedRectangleBorder(
                      //                 borderRadius:
                      //                     BorderRadius.circular(50.0)),
                      //             elevation: 10.0,
                      //             child: const SizedBox(
                      //               width: 60,
                      //               height: 60,
                      //               child: Center(
                      //                 child: Icon(
                      //                   Icons.system_security_update_good,
                      //                   color: AppTheme.nearlyWhite,
                      //                   size: 30,
                      //                 ),
                      //               ),
                      //             ),
                      //           ),
                      //         ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getDetailSection(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            fit: FlexFit.tight,
            child: Text(
              key,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 18,
                letterSpacing: 0.27,
                color: AppTheme.nearlyBlue,
              ),
            ),
          ),
          const SizedBox(
            width: 30,
          ),
          Flexible(
            fit: FlexFit.tight,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 18,
                letterSpacing: 0.27,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
