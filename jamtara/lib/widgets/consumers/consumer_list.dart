import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:bentec/models/user.dart';
import 'package:bentec/services/common.dart';
import 'package:bentec/utility/views/progress_view.dart';
import 'package:bentec/widgets/consumers/consumer_add.dart';
import 'package:flutter/material.dart';
import 'package:bentec/models/consumer.dart';
import 'package:bentec/services/consumer_service.dart';
import 'package:bentec/services/user_service.dart';
import 'package:bentec/widgets/app_theme.dart';
import 'package:file_picker/file_picker.dart';

class Debouncer {
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    if (null != _timer) {
      _timer?.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class ConsumerList extends StatefulWidget {
  String? division;
  ConsumerList(this.division, {Key? key}) : super(key: key);
  @override
  State<ConsumerList> createState() => _ConsumerListState();
}

class _ConsumerListState extends State<ConsumerList> {
  bool _fetchingData = true;
  List<ConsumerModel> _consumerList = [];
  List<ConsumerModel> _mainConsumerList = [];
  final ConsumerService _consumerService = ConsumerService();
  UserService userService = UserService();
  final _debouncer = Debouncer(milliseconds: 2000);
  bool isSearchInProgress = false;
  bool isSearchingDone = true;
  late final ScrollController _scrollController = ScrollController();
  String? userType;
  final int _pageLength = 10;
  var lastDoc;
  bool _lastPageReached = false;
  TextEditingController searchController = TextEditingController();
  String _selectedFileUploadStatus = '';
  bool isUploadInProgress = false;
  double progressValue = 0.0;

  @override
  initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        isSearchInProgress = true;
      });
      _debouncer.run(() {
        searchDidChange(searchController.text);
      });
    });

    _fetchConsumerList();
    _scrollController.addListener(() {
      if (_scrollController.position.atEdge &&
          isSearchingDone &&
          userType != 'agent') {
        if (_scrollController.position.pixels == 0) {
          // You're at the top.
        } else {
          // You're at the bottom.
          Common.customLog('Fetch and set next bunch of data.......');
          _fetchAndSetNextData();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isUploadInProgress,
      child: Column(children: [
        if (userType == 'agent') ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: IconButton(
                  onPressed: _addConsumerButtonClicked,
                  icon: const Icon(
                    Icons.add,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (userType == 'superadmin') ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: IconButton(
                  onPressed: () => showUploadView(context),
                  icon: const Icon(
                    Icons.upload,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (userType == 'admin') ...[
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                  (widget.division ?? ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
        searchBarLayout(context),
        if (_consumerList.isEmpty && !_fetchingData) ...[
          const Card(
            child: ListTile(
              subtitle: Text('No consumer found.'),
            ),
          ),
        ],
        if (isSearchInProgress) ...[
          const CircularProgressIndicator(
            backgroundColor: Colors.yellow,
          ),
        ],
        if (isUploadInProgress) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: LinearProgressIndicator(
              value: progressValue,
              semanticsLabel:
                  "Consumer data is being uploaded. Please don't close the application",
            ),
          ),
          Column(
            children: [
              Text((progressValue * 100).round().toString() + " %"),
            ],
          ),
        ],
        if (_fetchingData) ...[
          loadingConsumerTextLayout(context),
        ] else ...[
          consumerListLayout(context),
        ],
      ]),
    );
  }

  void _addConsumerButtonClicked() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      currentFocus.focusedChild?.unfocus();
    }
    searchController.clear();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsumerAdd(),
      ),
    ).then((value) {
      _fetchingData = true;
      _consumerList.clear();
      _mainConsumerList.clear();
      isSearchInProgress = false;
      isSearchingDone = true;
      lastDoc = null;
      _lastPageReached = false;
      _fetchConsumerList();
    });
  }

  _fetchConsumerList() async {
    userType = await userService.getCurrentUserType();
    Common.customLog('USER TYPE IN CONSUMER LIST ----' + userType.toString());
    switch (userType) {
      case 'superadmin':
        fetchConsumersForSuperAdmin();
        break;
      case 'admin':
        fetchConsumersForAdmin();
        break;
      case 'supervisor':
        fetchConsumersForSupervisor();
        break;
      case 'agent':
        fetchConsumersForAgent();
        break;
      default:
    }
  }

  _fetchAndSetNextData() async {
    if (!_lastPageReached) {
      List<ConsumerModel> consumerList = [];
      var docs;
      Common.customLog('USER TYPE IN CONSUMER LIST ----' + userType.toString());
      switch (userType) {
        case 'superadmin':
          docs = await _consumerService
              .getConsumerListForSuperAdmin(_pageLength, startAfter: lastDoc);
          break;
        case 'supervisor':
          if (widget.division != null) {
            docs =
                await _consumerService.getConsumerListByPageFilteredByDivision(
                    _pageLength, widget.division!,
                    startAfter: lastDoc);
          }
          break;
        case 'admin':
          if (widget.division != null) {
            docs =
                await _consumerService.getConsumerListByPageFilteredByDivision(
                    _pageLength, widget.division!,
                    startAfter: lastDoc);
          }
          break;
        default:
      }
      consumerList = _getConsumerModeListFromDocumentSnapshots(docs);
      if (docs.length < _pageLength) {
        _lastPageReached = true;
      }
      lastDoc = docs.last;
      prepareLayoutWithData(consumerList);
    }
  }

  void prepareLayoutWithData(List<ConsumerModel>? consumerList) {
    if (consumerList != null) {
      setState(() {
        _consumerList.addAll(consumerList);
        _mainConsumerList.addAll(consumerList);
        _fetchingData = false;
      });
    } else {
      setState(() {
        _fetchingData = false;
      });
    }
    Common.customLog(
        'Consumer list fetched...1..' + _consumerList.length.toString());
    Common.customLog(
        'Consumer list fetched...2..' + _mainConsumerList.length.toString());
  }

  void fetchConsumersForSuperAdmin() async {
    var docs = await _consumerService.getConsumerListForSuperAdmin(_pageLength);
    List<ConsumerModel> consumerList =
        _getConsumerModeListFromDocumentSnapshots(docs);
    lastDoc = docs.last;
    prepareLayoutWithData(consumerList);
  }

  void fetchConsumersForAdmin() async {
    if (widget.division != null) {
      var docs = await _consumerService.getConsumerListByPageFilteredByDivision(
          _pageLength, widget.division!);
      List<ConsumerModel> consumerList =
          _getConsumerModeListFromDocumentSnapshots(docs);
      lastDoc = docs.last;
      prepareLayoutWithData(consumerList);
    }
  }

  void fetchConsumersForSupervisor() async {
    String? loggedInUserID = await userService.getCurrentUserId();
    if (loggedInUserID != null) {
      UserModel? supervisor = await userService.getUserById(loggedInUserID);
      if (supervisor != null && supervisor.division != null) {
        widget.division = supervisor.division;
        var docs =
            await _consumerService.getConsumerListByPageFilteredByDivision(
                _pageLength, widget.division!);
        List<ConsumerModel> consumerList =
            _getConsumerModeListFromDocumentSnapshots(docs);
        lastDoc = docs.last;
        prepareLayoutWithData(consumerList);
      }
    }
  }

  void fetchConsumersForAgent() async {
    _consumerService.getConsumerList((List<ConsumerModel> consumerList) {
      prepareLayoutWithData(consumerList);
    });
  }

  _getConsumerModeListFromDocumentSnapshots(var docs) {
    List<ConsumerModel> consumersList = [];
    for (var doc in docs) {
      consumersList.add(ConsumerModel(
        id: doc.reference.id.toString(),
        consumerId: doc.data().toString().contains("CONSUMER NO")
            ? doc.get("CONSUMER NO")
            : "",
        consumerNo: doc.data().toString().contains("CONSUMER NO")
            ? doc.get("CONSUMER NO")
            : "",
        address1: doc.data().toString().contains("ADDRESS1")
            ? doc.get("ADDRESS1")
            : "",
        address2: doc.data().toString().contains("ADDRESS2")
            ? doc.get("ADDRESS2")
            : "",
        address3: doc.data().toString().contains("ADDRESS3")
            ? doc.get("ADDRESS3")
            : "",
        address4: doc.data().toString().contains("ADDRESS4")
            ? doc.get("ADDRESS4")
            : "",
        currentstatus: doc.data().toString().contains("METER STATUS")
            ? doc.get("METER STATUS")
            : "",
        load: doc.data().toString().contains("LOAD") ? doc.get("LOAD") : "",
        meterSlno: doc.data().toString().contains("METER NUMBER")
            ? doc.get("METER NUMBER")
            : "",
        name: doc.data().toString().contains("NAME") ? doc.get("NAME") : "",
        subdivision: doc.data().toString().contains("SUB DIVISION")
            ? doc.get("SUB DIVISION")
            : "",
        isApprovedBySupervisor:
            doc.data().toString().contains("isApprovedBySupervisor")
                ? doc.get("isApprovedBySupervisor")
                : false,
        isRejectedBySupervisor: doc.data().toString().contains("CONSUMER NO")
            ? doc.get("isRejectedBySupervisor")
            : false,
      ));
    }
    return consumersList;
  }

  void searchDidChange(String searchedText) {
    if (searchedText.isNotEmpty) {
      List<ConsumerModel> filteredList = _mainConsumerList.where((i) {
        return i.name.toLowerCase().contains(searchedText.toLowerCase()) ||
            i.consumerId.toLowerCase().contains(searchedText.toLowerCase()) ||
            i.consumerNo.toLowerCase().contains(searchedText.toLowerCase());
      }).toList();
      setState(() {
        isSearchingDone = false;
        isSearchInProgress = false;
        _consumerList = filteredList;
      });
    } else {
      _consumerList.clear();
      setState(() {
        isSearchingDone = true;
        isSearchInProgress = false;
        _consumerList.addAll(_mainConsumerList);
      });
    }
    Common.customLog('Consumer list fetched..after search..1.' +
        _consumerList.length.toString());
    Common.customLog('Consumer list fetched..after search..2.' +
        _mainConsumerList.length.toString());
  }

  void uploadConsumers(BuildContext context) async {
    Common.customLog("UploadConsumers.......called");
    late PlatformFile selected_File;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['csv']);
    // Common.customLog("Result......." + result.toString());
    try {
      if (result != null) {
        Common.customLog("RESULT IS NOT NULL...");
        setState(() {
          _selectedFileUploadStatus =
              result.files.first.name + ' is now loading';
        });
        selected_File = result.files.first;
        setState(() {
          isUploadInProgress = true;
        });
        String? resultString = await _consumerService.uploadConsumersFromCSV(
            (int totalConsumersToBeAdded, int totalConsumersAdded) {
          setState(() {
            progressValue = totalConsumersAdded / totalConsumersToBeAdded;
            Common.customLog("Progress........" + progressValue.toString());
          });
        }, selectedFile: selected_File);
        setState(() {
          isUploadInProgress = false;
        });
        // Common.customLog("..............22");
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
            _selectedFileUploadStatus = 'All consumers loaded from the file';
          });
        }
      } else {
        Common.customLog("RESULT IS NULL...");
        setState(() {
          _selectedFileUploadStatus = 'Unable to load file. Exiting---';
        });
      }
    } catch (error) {
      setState(() {
        _selectedFileUploadStatus = 'Unable to load file. Exiting---';
      });
    }
  }

  void showUploadView(BuildContext cntxt) {
    Common.customLog('Show upload called...........');
    showDialog(
      barrierDismissible: false,
      context: cntxt,
      builder: (BuildContext context) => _showUploadPopup(cntxt),
    );
  }

  Widget _showUploadPopup(BuildContext context) {
    return AlertDialog(
      elevation: 5,
      content: SizedBox(
        height: 150,
        width: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => hideUploadView(context),
                  icon: const Icon(
                    Icons.cancel_rounded,
                    size: 35,
                  ),
                )
              ],
            ),
            ElevatedButton(
              child: const Text(
                'Select file to upload.',
              ),
              onPressed: () {
                hideUploadView(context);
                uploadConsumers(context);
              },
            ),
            Text(
              _selectedFileUploadStatus,
            ),
          ],
        ),
      ),
    );
  }

  void hideUploadView(BuildContext cntxt) {
    Navigator.of(context).pop();
  }

  void hideUploader(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 5000), () {
      setState(() {
        _selectedFileUploadStatus = '';
      });
      hideUploadView(context);
    });
  }

  Card loadingConsumerTextLayout(BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('Loading consumer list ...'),
        subtitle: const Text(''),
        selected: false,
        onTap: () {},
        leading: const CircularProgressIndicator(
          backgroundColor: Colors.yellow,
        ),
      ),
    );
  }

  Container searchBarLayout(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: searchController,
        // onChanged: (value) {
        //   setState(() {
        //     isSearchInProgress = true;
        //   });
        //   _debouncer.run(() {
        //     _searchedText = value;
        //     searchDidChange(value);
        //   });
        // },
        decoration: InputDecoration(
          fillColor: Colors.black.withOpacity(0.1),
          filled: true,
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search consumer',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Expanded consumerListLayout(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _consumerList.length,
        itemBuilder: (cntxt, index) {
          return SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 10, right: 10, top: 16, bottom: 0),
                child: Card(
                  elevation: 5.0,
                  child: Column(children: <Widget>[
                    Padding(
                        padding:
                            const EdgeInsets.only(top: 16, left: 16, right: 24),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 4, bottom: 8, top: 16),
                                    child: Text(
                                      _consumerList[index].consumerNo,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontFamily: AppTheme.fontName,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                          letterSpacing: -0.1,
                                          color: AppTheme.darkText),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 4, bottom: 8, top: 16),
                                    child: Text(
                                      _consumerList[index].name.substring(
                                            0,
                                            _consumerList[index].name.length >
                                                    25
                                                ? 25
                                                : _consumerList[index]
                                                    .name
                                                    .length,
                                          ),
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontName,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 20,
                                        color: AppTheme.nearlyDarkBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ])),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 24, right: 24, top: 8, bottom: 8),
                      child: Container(
                        height: 2,
                        decoration: const BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 24, right: 24, top: 8, bottom: 8),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _consumerList[index].subdivision,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontName,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    letterSpacing: -0.2,
                                    color: AppTheme.darkText,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Sub Devision',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontName,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: AppTheme.grey.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _consumerList[index].meterSlno,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.fontName,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    letterSpacing: -0.2,
                                    color: AppTheme.darkText,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 0),
                                  child: Text(
                                    'Meter No',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontName,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: AppTheme.grey.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ]),
                ),
              ));
        },
      ),
    );
  }
}
