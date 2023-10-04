import 'package:bentec/models/consumer.dart';
import 'package:bentec/services/common.dart';
import 'package:bentec/services/consumer_service.dart';
import 'package:bentec/widgets/consumers/consumer_list.dart';
import 'package:flutter/material.dart';

import 'package:bentec/models/user.dart';
import '../../services/user_service.dart';
import '../../services/dialogue.dart';

class NotificationListOfSupervisor extends StatefulWidget {
  const NotificationListOfSupervisor({Key? key}) : super(key: key);

  @override
  State<NotificationListOfSupervisor> createState() =>
      _NotificationListOfSupervisorState();
}

class _NotificationListOfSupervisorState
    extends State<NotificationListOfSupervisor> {
  UserModel? _loggedInUser;
  final UserService _userService = UserService();
  final ConsumerService _consumerService = ConsumerService();
  List<Widget> _notificationLayoutList = [];
  final int _pageLength = 10;
  var lastDoc;
  bool _lastPageReached = false;
  List<ConsumerModel> _consumerList = [];
  bool _fetchingData = true;
  bool _shouldShowLoadMore = false;

  @override
  init() {}

  _NotificationListOfSupervisorState() {
    setLoggedInUser((UserModel? _user) {
      _loggedInUser = _user;
      if (_loggedInUser != null) {
        fetchNotificationListForSupervisor(_loggedInUser!);
      }
    });
  }

  void setLoggedInUser(Function callback) async {
    Common.customLog('Called...............');
    String? _loggedInUserId = await _userService.getCurrentUserId();
    if (_loggedInUserId != null) {
      UserModel? _loggedInUser =
          await _userService.getUserById(_loggedInUserId);
      callback(_loggedInUser);
    }
  }

  _fetchAndSetNextData() async {
    if (!_lastPageReached) {
      setState(() {
        _fetchingData = true;
      });
      List<ConsumerModel> consumerList = [];
      var docs = await _consumerService.getConsumerListByPageFilteredByDivision(
          _pageLength, _loggedInUser!.division,
          startAfter: lastDoc);
      consumerList = _getConsumerModeListFromDocumentSnapshots(docs);
      if (docs.length < _pageLength) {
        _lastPageReached = true;
        setState(() {
          _shouldShowLoadMore = false;
        });
      } else {
        setState(() {
          _shouldShowLoadMore = true;
        });
      }

      lastDoc = docs.last;
      prepareLayoutWithData(consumerList);
    }
  }

  void fetchNotificationListForSupervisor(UserModel loggedInUser) async {
    if (loggedInUser.division != '') {
      var docs = await _consumerService.getConsumerListByPageFilteredByDivision(
          _pageLength, loggedInUser.division,
          isDescending: true);
      List<ConsumerModel> consumerList =
          _getConsumerModeListFromDocumentSnapshots(docs);
      if (docs.length < _pageLength) {
        _lastPageReached = true;
        setState(() {
          _shouldShowLoadMore = false;
        });
      } else {
        setState(() {
          _shouldShowLoadMore = true;
        });
      }

      lastDoc = docs.last;
      prepareLayoutWithData(consumerList);
    }
  }

  void prepareLayoutWithData(List<ConsumerModel>? consumerList) {
    Common.customLog('Called......prepareLayoutWithData');
    setState(() {
      _fetchingData = false;
    });
    List<Widget> createdLayoutList = [];
    if (consumerList == null || consumerList.isEmpty) {
      createdLayoutList = [
        Card(
          child: ListTile(
            title: const Text('No agent found'),
            isThreeLine: true,
            subtitle: const Text(''),
            selected: false,
            onTap: () {},
          ),
        )
      ];
      setState(() {
        _notificationLayoutList = createdLayoutList;
      });
    } else {
      for (ConsumerModel consumer in consumerList) {
        String? supervisorName = _loggedInUser?.fullName;
        supervisorName ??= 'Anonymous';
        createdLayoutList.add(_getNotificationLayout(consumer, supervisorName));
      }
      setState(() {
        _consumerList.addAll(consumerList);
        _notificationLayoutList.addAll(createdLayoutList);
      });
    }

    Common.customLog(
        'Consumer list fetched.....' + _consumerList.length.toString());
    Common.customLog('Consumer list fetched.....' +
        _notificationLayoutList.length.toString());
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
              : false));
    }
    return consumersList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  if (_notificationLayoutList.isEmpty && _fetchingData) ...[
                    Card(
                      child: ListTile(
                        title: const Text('Loading consumer list ...'),
                        subtitle: const Text(''),
                        selected: false,
                        onTap: () {},
                        leading: const CircularProgressIndicator(
                          backgroundColor: Colors.yellow,
                        ),
                      ),
                    ),
                  ] else
                    ..._notificationLayoutList,
                ],
              ),
            ),
            if (_shouldShowLoadMore) ...[
              ElevatedButton(
                child: const Text('Load more.'),
                onPressed: () {
                  Common.customLog('Fetch and set next bunch of data.......');
                  _fetchAndSetNextData();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Padding _getNotificationLayout(
      ConsumerModel consumer, String supervisorName) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 10,
        child: Column(
          children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              title: Text(
                consumer.name,
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Added by agent under " +
                        supervisorName +
                        '\nDivision ' +
                        _loggedInUser!.division,
                    style: const TextStyle(
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (!isActionTakenForApproval(consumer)) ...[
                        OutlinedButton(
                          onPressed: () {
                            consumer.isRejectedBySupervisor
                                ? null
                                : rejectConsumer(consumer);
                          },
                          child: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            consumer.isApprovedBySupervisor
                                ? null
                                : approveConsumer(consumer);
                          },
                          child: const Text('Approve'),
                          style: OutlinedButton.styleFrom(
                            shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                          ),
                        ),
                      ] else ...[
                        Text(
                          consumer.isApprovedBySupervisor
                              ? 'Approved'
                              : 'Rejected',
                          style: TextStyle(
                            color: consumer.isApprovedBySupervisor
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              // trailing: const SizedBox(
              //   height: double.infinity,
              //   child: Icon(Icons.keyboard_arrow_right,
              //       color: Colors.black, size: 30.0),
              // ),
              // onTap: () => displayConsumerDetails(user),
            ),
          ],
        ),
      ),
    );
  }

  void approveConsumer(ConsumerModel consumer) async {
    CustomDialog.showConfirmDialog(
        context, 'Do you want to approve the consumer?', () async {
      Common.customLog('approving consumer called');
      String result = await _consumerService.approveConsumer(consumer);
      Common.customLog('result ' + result);
      if (result.contains('success__')) {
        CustomDialog.showSnack(context, 'Consumer approved', () {
          // fetchNotificationListForSupervisor();
          updateConsumerStatus(consumer.id, true, false);
        });
      } else {
        CustomDialog.showSnack(
            context, 'Failed to proceed, network issue', () {});
      }
    });
  }

  void rejectConsumer(ConsumerModel consumer) {
    CustomDialog.showConfirmDialog(
        context, 'Do you want to reject the consumer?', () async {
      String result = await _consumerService.rejectSupervisor(consumer);
      if (result.contains('success')) {
        CustomDialog.showSnack(context, 'Consumer rejected', () {
          // fetchNotificationListForSupervisor();
          updateConsumerStatus(consumer.id, false, true);
        });
      } else {
        CustomDialog.showSnack(
            context, 'Failed to proceed, network issue', () {});
      }
    });
  }

  void updateConsumerStatus(
      String consumerId, bool isApproved, bool isRejected) {
    int index = _consumerList.indexWhere((element) => element.id == consumerId);
    ConsumerModel consumer = _consumerList.elementAt(index);
    consumer.isApprovedBySupervisor = isApproved;
    consumer.isRejectedBySupervisor = isRejected;
    _consumerList[index] = consumer;

    String? supervisorName = _loggedInUser?.fullName;
    supervisorName ??= 'Anonymous';
    setState(() {
      _notificationLayoutList[index] =
          _getNotificationLayout(consumer, supervisorName!);
    });
  }

  bool isActionTakenForApproval(ConsumerModel user) {
    Common.customLog('--------------');
    Common.customLog(user.name);
    Common.customLog(user.isApprovedBySupervisor);
    Common.customLog(user.isRejectedBySupervisor);
    Common.customLog('--------------');
    if (user.isApprovedBySupervisor == false &&
        user.isRejectedBySupervisor == false) {
      return false;
    } else {
      return true;
    }
  }
}
