import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:bentec/services/dialogue.dart';
import 'package:flutter/material.dart';
import 'package:bentec/models/report.dart';
//import 'package:jamtara/models/user.dart';
import 'package:bentec/services/common.dart';
import 'package:bentec/services/consumer_service.dart';
import 'package:bentec/services/report_service.dart';
import 'package:bentec/services/user_service.dart';
import 'package:bentec/widgets/reports/report_add.dart';
import 'package:bentec/widgets/reports/report_details.dart';
import 'package:bentec/widgets/app_theme.dart';

class AgentReportList extends StatefulWidget {
  AgentReportList({Key? key}) : super(key: key);
  @override
  State<AgentReportList> createState() => _AgentReportListState();
}

class _AgentReportListState extends State<AgentReportList> {
  var isFilterClicked = false;
  bool _fetchingData = true;
  List<ReportModel> _reportList = [];
  ReportService reportService = ReportService();
  UserService userService = UserService();
  final ConsumerService _consumerService = ConsumerService();
  static bool _isTimerSet = false;
  void _setTimer() {
    _isTimerSet = true;
    Timer.periodic(const Duration(seconds: 20), (Timer t) {
      Common.isOnline((isOnline) async {
        if (isOnline) {
          reportService.uploadLocalReportDataToDB((result) {
            _getAndSetAllReports();
          });
        } else {}
      });
    });
  }

  _AgentReportListState() {
    prepareConsumerList();
  }

  prepareConsumerList() {
    if (!_isTimerSet) {
      _setTimer();
    }
    Future.delayed(const Duration(milliseconds: 100), () {
      _updateCache();
      _getAndSetAllReports();
    });
  }

  _updateCache() {
    userService.buildAgentInfoCache();
  }

  void addReportButtonClicked() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddReport()),
    ).then((value) {
      return value ? prepareConsumerList() : null;
    });
  }

  void searchActionCallback() {
    setState(() {
      isFilterClicked = false;
    });
  }

  _getAndSetAllReports() async {
    if (!mounted) {
      return;
    }
    reportService.getReportListForAgent((List<ReportModel> reportList) {
      _reportList = reportList;
      _fetchingData = false; //Common.customLog(mounted.toString());
      setState(() {});
    });
  }

  _viewReportDetails(ReportModel report) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetails(report.id),
      ),
    ).then((value) {
      return value ? _getAndSetAllReports() : null;
    });
  }

  _refreshConsumerListCache() {
    Common.isOnline((bool isOnline) {
      if (isOnline) {
        CustomDialog.openFullScreenLoaderDialog(context);
        _consumerService.buildConsumerListCacheForAgent(() {
          Navigator.pop(context);
        }, forceRebuild: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No internet connection'),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: addReportButtonClicked,
            icon: const Icon(
              Icons.add,
            ),
            iconSize: 30,
          ),
          IconButton(
            onPressed: _refreshConsumerListCache,
            icon: const Icon(
              Icons.refresh,
            ),
            iconSize: 30,
          ),
        ],
      ),
      if (isFilterClicked == true) ...[
        //List<UserModel> listOfSupervisor = await userService.getAllSupervisor();
        //FilterView(searchActionCallback),
      ],
      _fetchingData
          ? const CircularProgressIndicator(
              backgroundColor: Colors.yellow,
            )
          : Expanded(
              child: _reportList.isNotEmpty
                  ? ListView.builder(
                      itemCount: _reportList.length,
                      itemBuilder: (cntxt, index) {
                        return SizedBox(
                          // height: 120,
                          width: MediaQuery.of(context).size.width,
                          child: InkWell(
                            onTap: () {
                              _viewReportDetails(_reportList[index]);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 10, right: 10, top: 10, bottom: 0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.white,
                                  borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8.0),
                                      bottomLeft: Radius.circular(8.0),
                                      bottomRight: Radius.circular(8.0),
                                      topRight: Radius.circular(8.0)),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                        color: AppTheme.grey.withOpacity(0.2),
                                        offset: const Offset(1.1, 1.1),
                                        blurRadius: 10.0),
                                  ],
                                ),
                                child: Column(
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 16, left: 16, right: 24),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 4, bottom: 8, top: 16),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  _reportList[index]
                                                      .consumerNumber,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      fontFamily:
                                                          AppTheme.fontName,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 16,
                                                      letterSpacing: -0.1,
                                                      color: AppTheme.darkText),
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      Common
                                                          .getOnlyDateFromTimeStamp(
                                                              _reportList[index]
                                                                  .createdOn),
                                                      style: const TextStyle(
                                                        fontFamily:
                                                            AppTheme.fontName,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 12,
                                                        letterSpacing: -0.2,
                                                        color:
                                                            AppTheme.darkText,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 10,
                                                    ),
                                                    const Icon(
                                                      Icons.date_range,
                                                      // color: Colors.blac,
                                                      size: 20.0,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 16, left: 16, right: 24),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 7,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 4, bottom: 3),
                                              child: Text(
                                                _reportList[index].consumerName,
                                                textAlign: TextAlign.start,
                                                style: const TextStyle(
                                                  fontFamily: AppTheme.fontName,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 20,
                                                  color:
                                                      AppTheme.nearlyDarkBlue,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Flexible(
                                            flex: 3,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: <Widget>[
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    Icon(
                                                      Icons.access_time,
                                                      // If the report is submitted then no clock icon will be shown else
                                                      // a clock icon will be displayed
                                                      color: ((_reportList[
                                                                      index]
                                                                  .isSubmitted ==
                                                              true)
                                                          ? Colors.transparent
                                                          : AppTheme.grey
                                                              .withOpacity(
                                                                  0.5)),
                                                      size: 16,
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 4.0),
                                                      child: Text(
                                                        '',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          fontFamily:
                                                              AppTheme.fontName,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 14,
                                                          letterSpacing: 0.0,
                                                          color: AppTheme.grey
                                                              .withOpacity(0.5),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      })
                  : const Text(
                      'No report to display (click + to add a report)'))
    ]);
  }
}
