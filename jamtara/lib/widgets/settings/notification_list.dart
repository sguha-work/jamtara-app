import 'package:bentec/services/common.dart';
import 'package:bentec/services/consumer_service.dart';
import 'package:bentec/widgets/supervisors/supervisor_edit.dart';
import 'package:flutter/material.dart';

import 'package:bentec/models/user.dart';
import 'package:bentec/utility/views/custom_cached_network_image.dart';
import 'package:bentec/widgets/agents/agent_details.dart';
import '../../services/user_service.dart';
import '../../services/dialogue.dart';

class NotificationList extends StatefulWidget {
  const NotificationList({Key? key}) : super(key: key);

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  UserModel? _loggedInUser;
  UserService _userService = UserService();
  ConsumerService _consumerService = ConsumerService();
  List<Widget> _notificationLayoutList = [
    Card(
      child: ListTile(
        title: const Text('Loading agent list ...'),
        subtitle: const Text(''),
        selected: false,
        onTap: () {},
        leading: const CircularProgressIndicator(
          backgroundColor: Colors.yellow,
        ),
      ),
    )
  ];
  _NotificationListState() {
    setLoggedInUser((UserModel? _user) {
      _loggedInUser = _user;
      if (_loggedInUser != null) {
        switch (_loggedInUser?.userType) {
          case 'superadmin':
            fetchNotificationListForSuperAdmin();
            break;
          case 'admin':
            fetchNotificationListForAdmin();
            break;
          default:
            break;
        }
      }
    });
  }
  void setLoggedInUser(Function callback) async {
    String? _loggedInUserId = await _userService.getCurrentUserId();
    if (_loggedInUserId != null) {
      UserModel? _loggedInUser =
          await _userService.getUserById(_loggedInUserId);
      callback(_loggedInUser);
    }
  }

  void displayUserDetails(UserModel user) {
    switch (user.userType) {
      case 'agent':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AgentDetails(user)),
        ).then((value) {
          return value ? fetchNotificationListForAdmin() : null;
        });
        break;
      case 'supervisor':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EditSupervisor(user)),
        ).then((value) {
          return value ? fetchNotificationListForAdmin() : null;
        });
        break;
      default:
        break;
    }
  }

  void fetchNotificationListForSuperAdmin() async {
    List<UserModel>? supervisorList = await _userService
        .getUserListForSuperAdminWithApprovalStatus('supervisor', []);
    List<Widget> createdLayoutList = [];
    if (supervisorList == null || supervisorList.isEmpty) {
      createdLayoutList = [
        Card(
          child: ListTile(
            title: const Text('No supervisor found'),
            isThreeLine: true,
            subtitle: const Text(''),
            selected: false,
            onTap: () {},
          ),
        )
      ];
    } else {
      for (UserModel supervisor in supervisorList) {
        String? adminName =
            await _userService.getUserNameById(supervisor.createdByUserId);
        adminName ??= 'Anonymous';
        createdLayoutList.add(_getNotificationLayout(supervisor, adminName));
      }
    }
    setState(() {
      _notificationLayoutList = createdLayoutList;
    });
  }

  void fetchNotificationListForAdmin() async {
    if (_loggedInUser!.divisions.isNotEmpty) {
      List<UserModel>? agentList =
          await _userService.getUserListForAdminWithApprovalStatus(
              'agent', _loggedInUser!.divisions);
      List<Widget> createdLayoutList = [];
      if (agentList == null || agentList.isEmpty) {
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
      } else {
        for (UserModel agent in agentList) {
          String? supervisorName =
              await _userService.getUserNameById(agent.createdByUserId);
          supervisorName ??= 'Anonymous';
          createdLayoutList.add(_getNotificationLayout(agent, supervisorName));
        }
      }
      setState(() {
        _notificationLayoutList = createdLayoutList;
      });
    }
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
                children: _notificationLayoutList,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Padding _getNotificationLayout(UserModel user, String supervisorName) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      child: Card(
        // shadowColor: agent.isRejectedByAdmin
        //     ? Colors.red
        //     : (agent.isApprovedByAdmin ? Colors.green : Colors.red),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 10,
        child: Column(
          children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              leading: CustomCachedNetworkImage.showNetworkImage(
                user.imageFilePath,
                60,
              ),
              title: Text(
                user.fullName,
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Added by " + supervisorName + ' Division ' + user.division,
                    style: const TextStyle(
                      color: Colors.black45,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (!isActionTakenForApproval(user)) ...[
                        OutlinedButton(
                          onPressed: () {
                            switch (user.userType) {
                              case 'agent':
                                user.isRejectedByAdmin
                                    ? null
                                    : rejectUser(user);
                                break;
                              case 'supervisor':
                                user.isRejectedBySuperAdmin
                                    ? null
                                    : rejectUser(user);
                                break;
                              default:
                                break;
                            }
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
                            switch (user.userType) {
                              case 'agent':
                                user.isApprovedByAdmin
                                    ? null
                                    : approveUser(user);
                                break;
                              case 'supervisor':
                                user.isApprovedBySuperAdmin
                                    ? null
                                    : approveUser(user);
                                break;
                              default:
                                break;
                            }
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
                          _whenActionIsAlreadyPerformed(user)
                              ? 'Approved'
                              : 'Rejected',
                          style: TextStyle(
                            color: user.isApprovedByAdmin
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
              trailing: const SizedBox(
                height: double.infinity,
                child: Icon(Icons.keyboard_arrow_right,
                    color: Colors.black, size: 30.0),
              ),
              onTap: () => displayUserDetails(user),
            ),
          ],
        ),
      ),
    );
  }

  bool _whenActionIsAlreadyPerformed(UserModel user) {
    switch (user.userType) {
      case 'agent':
        return user.isApprovedByAdmin;
      case 'supervisor':
        return user.isApprovedBySuperAdmin;
      default:
        break;
    }
    return false;
  }

  void approveUser(UserModel user) {
    switch (_loggedInUser?.userType) {
      case 'superadmin':
        approveSupervisor(user);
        break;
      case 'admin':
        approveAgent(user);
        break;
      default:
        break;
    }
  }

  void rejectUser(UserModel user) {
    Common.customLog('Reject user......' + user.userType);
    switch (_loggedInUser?.userType) {
      case 'superadmin':
        rejectSupervisor(user);
        break;
      case 'admin':
        rejectAgent(user);
        break;
      default:
        break;
    }
  }

  void approveSupervisor(UserModel supervisor) async {
    CustomDialog.showConfirmDialog(
        context, 'Do you want to approve the supervisor?', () async {
      Common.customLog('approving agent called');
      String result = await _userService.approveSupervisor(supervisor);
      Common.customLog('result ' + result);
      if (result.contains('success__')) {
        CustomDialog.showSnack(context, 'User approved', () {
          fetchNotificationListForSuperAdmin();
        });
      } else {
        CustomDialog.showSnack(
            context, 'Failed to proceed, network issue', () {});
      }
    });
  }

  void rejectSupervisor(UserModel supervisor) {
    CustomDialog.showConfirmDialog(
        context, 'Do you want to reject the supervisor?', () async {
      String result = await _userService.rejectSupervisor(supervisor);
      if (result.contains('success')) {
        CustomDialog.showSnack(context, 'User rejected', () {
          fetchNotificationListForSuperAdmin();
        });
      } else {
        CustomDialog.showSnack(
            context, 'Failed to proceed, network issue', () {});
      }
    });
  }

  void approveAgent(UserModel agent) async {
    CustomDialog.showConfirmDialog(context, 'Do you want to approve the Agent?',
        () async {
      Common.customLog('approving agent called');
      String result = await _userService.approveAgent(agent);
      Common.customLog('result ' + result);
      if (result.contains('success__')) {
        CustomDialog.showSnack(context, 'User approved', () {
          fetchNotificationListForAdmin();
        });
      } else {
        CustomDialog.showSnack(
            context, 'Failed to proceed, network issue', () {});
      }
    });
  }

  void rejectAgent(UserModel agent) {
    CustomDialog.showConfirmDialog(context, 'Do you want to reject the Agent?',
        () async {
      String result = await _userService.rejectAgent(agent);
      if (result.contains('success')) {
        CustomDialog.showSnack(context, 'User rejected', () {
          fetchNotificationListForAdmin();
        });
      } else {
        CustomDialog.showSnack(
            context, 'Failed to proceed, network issue', () {});
      }
    });
  }

  bool isActionTakenForApproval(UserModel user) {
    if (user.userType == 'agent') {
      Common.customLog('--------------');
      Common.customLog(user.fullName);
      Common.customLog(user.isApprovedByAdmin);
      Common.customLog(user.isRejectedByAdmin);
      Common.customLog('--------------');
      if (user.isApprovedByAdmin == false && user.isRejectedByAdmin == false) {
        return false;
      } else {
        return true;
      }
    } else if (user.userType == 'supervisor') {
      Common.customLog('--------------');
      Common.customLog(user.fullName);
      Common.customLog(user.isApprovedBySuperAdmin);
      Common.customLog(user.isRejectedBySuperAdmin);
      Common.customLog('--------------');
      if (user.isApprovedBySuperAdmin == false &&
          user.isRejectedBySuperAdmin == false) {
        return false;
      } else {
        return true;
      }
    }
    return false;
  }
}
