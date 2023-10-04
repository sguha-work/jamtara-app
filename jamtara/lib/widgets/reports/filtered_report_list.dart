import 'package:bentec/models/report.dart';
import 'package:bentec/services/dialogue.dart';
import 'package:bentec/services/report_service.dart';
import 'package:bentec/widgets/reports/report_details.dart';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'package:bentec/models/user.dart';
import '../../services/common.dart';

class FilteredReportList extends StatefulWidget {
  // List<ReportModel> reportList;
  String? phoneNumber;
  String? selectedDivision;
  List<String>? divisions;
  String? basedOnUser;
  DateTime startDateTime;
  DateTime endDateTime;
  FilteredReportList(this.basedOnUser, this.phoneNumber, this.selectedDivision,
      this.divisions, this.startDateTime, this.endDateTime,
      {Key? key})
      : super(key: key);
  @override
  State<FilteredReportList> createState() {
    return _FilteredReportListState(
      basedOnUser: this.basedOnUser,
      phoneNumber: this.phoneNumber,
      selectedDivision: this.selectedDivision,
      divisions: this.divisions,
      startDateTime: this.startDateTime,
      endDateTime: this.endDateTime,
    );
  }
}

class _FilteredReportListState extends State<FilteredReportList> {
  String? phoneNumber;
  String? selectedDivision;
  List<String>? divisions;
  String? basedOnUser;
  DateTime startDateTime;
  DateTime endDateTime;
  final ReportService _reportService = ReportService();
  List<ReportModel> _reportList = [];
  bool isFetching = true;
  bool isReportFileReadyToDownload = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  _FilteredReportListState({
    this.basedOnUser,
    this.phoneNumber,
    this.selectedDivision,
    this.divisions,
    required this.startDateTime,
    required this.endDateTime,
  }) {
    prepareReportListBasedOnFilter();
  }

  void prepareReportListBasedOnFilter() async {
    if (basedOnUser != null) {
      Common.customLog('basedOnUserType--' + basedOnUser!);
      switch (basedOnUser) {
        case 'admin':
          if (divisions != null) {
            Common.customLog('divisions--' + divisions.toString());
            _reportList = await _reportService
                .getReportListBasedOnDivisionsFilteredByTime(
                    divisions!, startDateTime, endDateTime);
          }
          break;
        case 'division':
          if (selectedDivision != null) {
            Common.customLog(
                'selectedDivision--' + selectedDivision.toString());
            _reportList =
                await _reportService.getReportListBasedOnDivisionFilteredByTime(
                    selectedDivision!, startDateTime, endDateTime);
          }
          break;
        case 'supervisor':
          if (phoneNumber != null) {
            Common.customLog('phoneNumber--' + phoneNumber.toString());
            _reportList =
                await _reportService.getReportListBySupervisorPhoneNumber(
                    phoneNumber!, startDateTime, endDateTime);
          }
          break;
        case 'agent':
          if (phoneNumber != null) {
            Common.customLog('phoneNumber--' + phoneNumber.toString());
            _reportList = await _reportService.getReportListByAgentPhoneNumber(
                phoneNumber!, startDateTime, endDateTime);
          }
          break;
        default:
          _reportList = await _reportService.getReportListFilteredByTime(
              startDateTime, endDateTime);
          break;
      }
      setState(() {
        isFetching = false;
      });
    }
  }

  _downloadButtonClicked() {
    if (_reportList.isEmpty) {
      CustomDialog.showSnack(context, 'No report founds', () {});
    } else {
      setState(() {
        isReportFileReadyToDownload = false;
      });
      Common.customLog('START.....2');
      _reportService.downloadSpecificReportListAsCSV(_reportList, (status) {
        Common.customLog('END.....2');
        Common.customLog(status);
        setState(() {
          isReportFileReadyToDownload = true;
        });
      });
    }
  }

  _viewReportDetails(ReportModel report) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetails(report.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !isReportFileReadyToDownload,
      child: Container(
        color: AppTheme.nearlyWhite,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Report list',
            ),
          ),
          body: Center(
            widthFactor: double.infinity,
            // heightFactor: double.infinity,
            child: Column(
              children: [
                if (isFetching) ...[
                  Card(
                    child: ListTile(
                      title: const Text('Loading report list ...'),
                      subtitle: const Text(''),
                      selected: false,
                      onTap: () {},
                      leading: const CircularProgressIndicator(
                        backgroundColor: Colors.yellow,
                      ),
                    ),
                  ),
                ],
                if (_reportList.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _reportList.length.toString() + ' Reports',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed:
                            _downloadButtonClicked, //downloadButtonClicked,
                        icon: const Icon(
                          Icons.download_rounded,
                        ),
                        iconSize: 30,
                      ),
                    ],
                  ),
                  if (!isReportFileReadyToDownload) ...[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            backgroundColor: Colors.yellow,
                          ),
                        ),
                        Text(
                          'Preparing reports to download. Please wait.',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                  Expanded(
                    child: ListView.builder(
                        itemCount: _reportList.length,
                        itemBuilder: (cntxt, index) {
                          return SizedBox(
                              // height: 120,
                              width: double.infinity,
                              child: InkWell(
                                  onTap: () {
                                    _viewReportDetails(_reportList[index]);
                                  },
                                  child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 10,
                                          right: 10,
                                          top: 10,
                                          bottom: 0),
                                      child: Container(
                                          decoration: BoxDecoration(
                                            color: AppTheme.white,
                                            borderRadius:
                                                const BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(8.0),
                                                    bottomLeft:
                                                        Radius.circular(8.0),
                                                    bottomRight:
                                                        Radius.circular(8.0),
                                                    topRight:
                                                        Radius.circular(8.0)),
                                            boxShadow: <BoxShadow>[
                                              BoxShadow(
                                                  color: AppTheme.grey
                                                      .withOpacity(0.2),
                                                  offset:
                                                      const Offset(1.1, 1.1),
                                                  blurRadius: 10.0),
                                            ],
                                          ),
                                          child: Column(children: <Widget>[
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 16,
                                                    left: 16,
                                                    right: 16,
                                                    bottom: 16),
                                                child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: <Widget>[
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                left: 4,
                                                                bottom: 8,
                                                                top: 16),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Flexible(
                                                              flex: 1,
                                                              child: Text(
                                                                _reportList[
                                                                        index]
                                                                    .consumerName,
                                                                textAlign:
                                                                    TextAlign
                                                                        .start,
                                                                style: const TextStyle(
                                                                    fontFamily:
                                                                        AppTheme
                                                                            .fontName,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    fontSize:
                                                                        16,
                                                                    letterSpacing:
                                                                        -0.1,
                                                                    color: AppTheme
                                                                        .darkText),
                                                              ),
                                                            ),
                                                            Flexible(
                                                              flex: 1,
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .end,
                                                                children: [
                                                                  Text(
                                                                    Common.getOnlyDateFromTimeStamp(
                                                                        _reportList[index]
                                                                            .createdOn),
                                                                    style:
                                                                        const TextStyle(
                                                                      fontFamily:
                                                                          AppTheme
                                                                              .fontName,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      fontSize:
                                                                          12,
                                                                      letterSpacing:
                                                                          -0.2,
                                                                      color: AppTheme
                                                                          .darkText,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 10,
                                                                  ),
                                                                  const Icon(
                                                                    Icons
                                                                        .date_range,
                                                                    // color: Colors.blac,
                                                                    size: 20.0,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: <Widget>[
                                                            Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .end,
                                                                children: <
                                                                    Widget>[
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                            .only(
                                                                        left: 4,
                                                                        bottom:
                                                                            3),
                                                                    child: Text(
                                                                      _reportList[
                                                                              index]
                                                                          .consumerNumber,
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      style:
                                                                          const TextStyle(
                                                                        fontFamily:
                                                                            AppTheme.fontName,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        fontSize:
                                                                            20,
                                                                        color: AppTheme
                                                                            .nearlyDarkBlue,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ]),
                                                            Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .end,
                                                              children: <
                                                                  Widget>[
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: <
                                                                      Widget>[
                                                                    // No need to display clock icon for report list view of
                                                                    // admin and supervisor as they will only see the submitted
                                                                    // reports
                                                                    // Icon(
                                                                    //   Icons.access_time,
                                                                    //   color: AppTheme.grey
                                                                    //       .withOpacity(0.5),
                                                                    //   size: 16,
                                                                    // ),
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                              .only(
                                                                          left:
                                                                              4.0),
                                                                      child:
                                                                          Text(
                                                                        '',
                                                                        // Common
                                                                        //     .getDateTimeFromTimeStamp(
                                                                        //         _reportListFromDB[
                                                                        //                 index]
                                                                        //             .createdOn),
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                        style:
                                                                            TextStyle(
                                                                          fontFamily:
                                                                              AppTheme.fontName,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                          fontSize:
                                                                              14,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          color: AppTheme
                                                                              .grey
                                                                              .withOpacity(0.5),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            )
                                                          ])
                                                    ])),
                                          ])))));
                        }),
                  ),
                ],
                if (_reportList.isEmpty && !isFetching) ...[
                  const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Text('No report found'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
