import 'package:bentec/models/report.dart';
import 'package:bentec/services/report_service.dart';
import 'package:bentec/widgets/reports/report_details.dart';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'package:bentec/models/user.dart';
import '../../services/common.dart';

class ConsolidateReportList extends StatefulWidget {
  UserModel agent;
  String supervisorName;
  ConsolidateReportList(this.agent, this.supervisorName, {Key? key})
      : super(key: key);
  @override
  State<ConsolidateReportList> createState() => _ConsolidateReportListState();
}

class _ConsolidateReportListState extends State<ConsolidateReportList> {
  final ReportService _reportService = ReportService();
  List<ReportModel> _reportList = [];
  bool isReportFileReadyToDownload = true;

  @override
  void initState() {
    // TODO: implement initState
    _getReportListForAgent();
    super.initState();
  }

  _getReportListForAgent() async {
    String agentId = widget.agent.id;
    List<ReportModel> reportList =
        await _reportService.getReportListByAgentIdFromDB(agentId);
    setState(() {
      _reportList = reportList;
    });
  }

  _downloadButtonClicked() {
    setState(() {
      isReportFileReadyToDownload = false;
    });
    Common.customLog('START.....1');
    _reportService.downloadSpecificReportListAsCSV(_reportList, (status) {
      Common.customLog('END.....1');
      Common.customLog(status);
      setState(() {
        isReportFileReadyToDownload = true;
      });
    });
  }

  _viewReportDetails(ReportModel report) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetails(report.id),
      ),
    ).then((value) {
      return value ? _getReportListForAgent() : null;
    });
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
            heightFactor: double.infinity,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'Agents under ' +
                        widget.supervisorName +
                        '\n Reports from ' +
                        widget.agent.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
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
                                          borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(8.0),
                                              bottomLeft: Radius.circular(8.0),
                                              bottomRight: Radius.circular(8.0),
                                              topRight: Radius.circular(8.0)),
                                          boxShadow: <BoxShadow>[
                                            BoxShadow(
                                                color: AppTheme.grey
                                                    .withOpacity(0.2),
                                                offset: const Offset(1.1, 1.1),
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
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
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
                                                              _reportList[index]
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
                                                                  fontSize: 16,
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
                                                                      _reportList[
                                                                              index]
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
                                                                          AppTheme
                                                                              .fontName,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
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
                                                            children: <Widget>[
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
                                                                    child: Text(
                                                                      '',
                                                                      // Common
                                                                      //     .getDateTimeFromTimeStamp(
                                                                      //         _reportListFromDB[
                                                                      //                 index]
                                                                      //             .createdOn),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
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
            ),
          ),
        ),
      ),
    );
  }
}
