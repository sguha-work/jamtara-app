// import 'package:flutter/material.dart';
// import 'package:bentec/models/report.dart';
// import 'package:bentec/services/common.dart';
// import 'package:bentec/services/consumer_service.dart';
// import 'package:bentec/services/report_service.dart';
// import 'package:bentec/services/user_service.dart';
// import 'package:bentec/widgets/reports/filter_view.dart';
// import 'package:bentec/widgets/reports/report_details.dart';

// import '../app_theme.dart';

// class ReportList extends StatefulWidget {
//   @override
//   State<ReportList> createState() => _ReportListState();
// }

// class _ReportListState extends State<ReportList> {
//   var isFilterClicked = false;
//   UserService userService = UserService();
//   List<ReportModel> _reportListFromDB = [];
//   ReportService reportService = ReportService();
//   ConsumerService consumerService = ConsumerService();

//   _ReportListState() {
//     Future.delayed(const Duration(milliseconds: 1000), () {
//       _getAndSetAllReports();
//       reportService.uploadLocalReportDataToDB((result) {
//         _getAndSetAllReports();
//       });
//     });
//   }

//   void searchActionCallback() {
//     setState(() {
//       isFilterClicked = false;
//     });
//   }

//   _getAndSetAllReports() async {
//     String? currentUserType = await userService.getCurrentUserType();
//     if (currentUserType != null) {
//       switch (currentUserType) {
//         case 'admin':
//           _reportListFromDB = await reportService.getReportListForAdmin('');
//           break;
//       }
//       setState(() {});
//     }
//   }

//   _viewReportDetails(ReportModel report) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ReportDetails(report.id),
//       ),
//     ).then((value) {
//       return value ? _getAndSetAllReports() : null;
//     });
//   }

//   void downloadButtonClicked() {
//     reportService.downloadReportListAsCSV();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             IconButton(
//               onPressed: () {},
//               icon: const Icon(
//                 Icons.filter_alt_rounded,
//               ),
//               iconSize: 30,
//             ),
//             IconButton(
//               onPressed: downloadButtonClicked,
//               icon: const Icon(
//                 Icons.download_rounded,
//               ),
//               iconSize: 30,
//             ),
//           ],
//         ),
//         if (isFilterClicked == true) ...[
//           //FilterView(searchActionCallback),
//         ],
//         Expanded(
//           child: ListView.builder(
//               itemCount: _reportListFromDB.length,
//               itemBuilder: (cntxt, index) {
//                 return SizedBox(
//                     height: 120,
//                     width: double.infinity,
//                     child: InkWell(
//                         onTap: () {
//                           _viewReportDetails(_reportListFromDB[index]);
//                         },
//                         child: Padding(
//                             padding: const EdgeInsets.only(
//                                 left: 10, right: 10, top: 10, bottom: 0),
//                             child: Container(
//                                 decoration: BoxDecoration(
//                                   color: AppTheme.white,
//                                   borderRadius: const BorderRadius.only(
//                                       topLeft: Radius.circular(8.0),
//                                       bottomLeft: Radius.circular(8.0),
//                                       bottomRight: Radius.circular(8.0),
//                                       topRight: Radius.circular(8.0)),
//                                   boxShadow: <BoxShadow>[
//                                     BoxShadow(
//                                         color: AppTheme.grey.withOpacity(0.2),
//                                         offset: const Offset(1.1, 1.1),
//                                         blurRadius: 10.0),
//                                   ],
//                                 ),
//                                 child: Column(children: <Widget>[
//                                   Padding(
//                                       padding: const EdgeInsets.only(
//                                           top: 16, left: 16, right: 16),
//                                       child: Column(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.center,
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: <Widget>[
//                                             Padding(
//                                               padding: const EdgeInsets.only(
//                                                   left: 4, bottom: 8, top: 16),
//                                               child: Row(
//                                                 mainAxisAlignment:
//                                                     MainAxisAlignment
//                                                         .spaceBetween,
//                                                 children: [
//                                                   Text(
//                                                     _reportListFromDB[index]
//                                                         .consumerNumber,
//                                                     textAlign: TextAlign.center,
//                                                     style: const TextStyle(
//                                                         fontFamily:
//                                                             AppTheme.fontName,
//                                                         fontWeight:
//                                                             FontWeight.w500,
//                                                         fontSize: 16,
//                                                         letterSpacing: -0.1,
//                                                         color:
//                                                             AppTheme.darkText),
//                                                   ),
//                                                   Row(
//                                                     mainAxisAlignment:
//                                                         MainAxisAlignment.end,
//                                                     children: [
//                                                       Text(
//                                                         Common.getOnlyDateFromTimeStamp(
//                                                             _reportListFromDB[
//                                                                     index]
//                                                                 .createdOn),
//                                                         style: const TextStyle(
//                                                           fontFamily:
//                                                               AppTheme.fontName,
//                                                           fontWeight:
//                                                               FontWeight.w500,
//                                                           fontSize: 12,
//                                                           letterSpacing: -0.2,
//                                                           color:
//                                                               AppTheme.darkText,
//                                                         ),
//                                                       ),
//                                                       const SizedBox(
//                                                         width: 10,
//                                                       ),
//                                                       const Icon(
//                                                         Icons.date_range,
//                                                         // color: Colors.blac,
//                                                         size: 20.0,
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                             Row(
//                                                 mainAxisAlignment:
//                                                     MainAxisAlignment
//                                                         .spaceBetween,
//                                                 crossAxisAlignment:
//                                                     CrossAxisAlignment.center,
//                                                 children: <Widget>[
//                                                   Row(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment
//                                                               .center,
//                                                       crossAxisAlignment:
//                                                           CrossAxisAlignment
//                                                               .end,
//                                                       children: <Widget>[
//                                                         Padding(
//                                                           padding:
//                                                               const EdgeInsets
//                                                                       .only(
//                                                                   left: 4,
//                                                                   bottom: 3),
//                                                           child: Text(
//                                                             _reportListFromDB[
//                                                                     index]
//                                                                 .consumerName,
//                                                             textAlign: TextAlign
//                                                                 .center,
//                                                             style:
//                                                                 const TextStyle(
//                                                               fontFamily:
//                                                                   AppTheme
//                                                                       .fontName,
//                                                               fontWeight:
//                                                                   FontWeight
//                                                                       .w600,
//                                                               fontSize: 20,
//                                                               color: AppTheme
//                                                                   .nearlyDarkBlue,
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       ]),
//                                                   Column(
//                                                     mainAxisAlignment:
//                                                         MainAxisAlignment
//                                                             .center,
//                                                     crossAxisAlignment:
//                                                         CrossAxisAlignment.end,
//                                                     children: <Widget>[
//                                                       Row(
//                                                         mainAxisAlignment:
//                                                             MainAxisAlignment
//                                                                 .center,
//                                                         children: <Widget>[
//                                                           // No need to display clock icon for report list view of
//                                                           // admin and supervisor as they will only see the submitted
//                                                           // reports
//                                                           // Icon(
//                                                           //   Icons.access_time,
//                                                           //   color: AppTheme.grey
//                                                           //       .withOpacity(0.5),
//                                                           //   size: 16,
//                                                           // ),
//                                                           Padding(
//                                                             padding:
//                                                                 const EdgeInsets
//                                                                         .only(
//                                                                     left: 4.0),
//                                                             child: Text(
//                                                               '',
//                                                               // Common
//                                                               //     .getDateTimeFromTimeStamp(
//                                                               //         _reportListFromDB[
//                                                               //                 index]
//                                                               //             .createdOn),
//                                                               textAlign:
//                                                                   TextAlign
//                                                                       .center,
//                                                               style: TextStyle(
//                                                                 fontFamily:
//                                                                     AppTheme
//                                                                         .fontName,
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .w500,
//                                                                 fontSize: 14,
//                                                                 letterSpacing:
//                                                                     0.0,
//                                                                 color: AppTheme
//                                                                     .grey
//                                                                     .withOpacity(
//                                                                         0.5),
//                                                               ),
//                                                             ),
//                                                           ),
//                                                         ],
//                                                       ),
//                                                     ],
//                                                   )
//                                                 ])
//                                           ])),
//                                 ])))));
//               }),
//         ),
//       ],
//     );
//   }
// }
