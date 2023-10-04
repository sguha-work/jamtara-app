import 'dart:ffi';

import 'package:bentec/services/common.dart';
import 'package:bentec/services/consumer_service.dart';
import 'package:bentec/services/file_service.dart';
import 'package:bentec/services/report_service.dart';
import 'package:bentec/widgets/admins/admin_details.dart';
import 'package:bentec/widgets/settings/notification_list_supervisor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bentec/models/user.dart';
import 'package:bentec/widgets/agents/agent_profile.dart';
import 'package:bentec/widgets/settings/notification_list.dart';
import 'package:bentec/widgets/supervisors/supervisor_profile.dart';
import '../../services/user_service.dart';

class FancyFloatingMenu extends StatefulWidget {
  final Function() onPressed;
  final String tooltip;
  const FancyFloatingMenu(
    this.onPressed,
    this.tooltip,
  );

  @override
  State<FancyFloatingMenu> createState() => _FancyFloatingMenuState();
}

class _FancyFloatingMenuState extends State<FancyFloatingMenu>
    with SingleTickerProviderStateMixin {
  bool isOpened = false;
  ConsumerService consumerService = ConsumerService();
  bool isNewNotificationAvailable = true;
  UserService userService = UserService();
  ReportService reportService = ReportService();
  late AnimationController _animationController;
  late Animation<Color?> _buttonColor;
  late Animation<double> _animateIcon;
  late Animation<double> _translateButton;
  final Curve _curve = Curves.easeOut;
  final double _fabHeight = 56.0;
  bool isUserTypeSuperAdmin = false;

  void _goToUserProfile() async {
    String? currentUserId = await userService.getCurrentUserId() ?? '';
    Common.customLog('LOGGED IN USER ID ===' + currentUserId);
    if (currentUserId != null) {
      UserModel? user = await userService.getUserById(currentUserId);
      if (user != null) {
        String userType = user.userType;
        Common.customLog('LOGGED IN USER TYPE ===' + userType);
        switch (userType) {
          case 'admin':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AdminDetails(user, false, true, false, false),
              ),
            );
            break;
          case 'supervisor':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SupervisorProfile(user)),
            );
            break;
          case 'agent':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AgentProfile(user)),
            );
            break;
          default:
            // Do Nothing
            break;
        }
      } else {
        Common.customLog('LOGGED IN USER IS NULL.......');
      }
    }
  }

  void _showUserNotification() async {
    String? userType = await userService.getCurrentUserType();
    switch (userType) {
      case null:
        // do nothing
        break;
      case 'superadmin':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NotificationList()),
        );
        break;
      case 'admin':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NotificationList()),
        );
        break;
      case 'supervisor':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => NotificationListOfSupervisor()),
        );
        break;
      case 'agent':
        // ToDo
        break;
      default:
        // Do Nothing
        break;
    }
  }

  @override
  initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500))
          ..addListener(() {
            setState(() {});
          });
    _animateIcon =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _buttonColor = ColorTween(
      begin: Colors.blue,
      end: Colors.red,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(
          0.00,
          1.00,
          curve: Curves.linear,
        ),
      ),
    );
    _translateButton = Tween<double>(
      begin: _fabHeight,
      end: -14.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        0.0,
        0.75,
        curve: _curve,
      ),
    ));
    refreshMenuOptionsBasedOnUsertype();
  }

  void refreshMenuOptionsBasedOnUsertype() async {
    Common.customLog('called for user type');
    String? userType = await userService.getCurrentUserType();
    Common.customLog(userType);
    setState(() {
      isUserTypeSuperAdmin = (userType == 'superadmin') ? true : false;
    });
  }

  @override
  dispose() {
    _animationController.dispose();
    super.dispose();
  }

  animate() {
    if (!isOpened) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    isOpened = !isOpened;
  }

  Widget profile() {
    return FloatingActionButton(
      onPressed: () {
        animate();
        _goToUserProfile();
      },
      tooltip: 'Profile',
      child: const Icon(
        Icons.person,
        size: 30,
      ),
    );
  }

  Widget logout() {
    return FloatingActionButton(
      onPressed: () {
        animate();
        userService.signout();
        FileService.delete(consumerService.consumerCacheFileName);
        FileService.delete(userService.userInfoCacheFileName);
        FileService.delete(reportService.reportCacheFileName);
        SystemNavigator.pop();
      },
      tooltip: 'Logout',
      child: const Icon(
        Icons.logout,
        size: 30,
      ),
    );
  }

  Widget notification(BuildContext context) {
    return Container(
      child: FloatingActionButton(
        onPressed: () {
          animate();
          _showUserNotification();
        },
        tooltip: 'Notification',
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            const Icon(
              Icons.notifications,
              size: 30,
            ),
            if (isNewNotificationAvailable == true) ...[
              Container(
                height: 10,
                width: 10,
                margin: const EdgeInsets.all(4.0),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget toggle() {
    return FloatingActionButton(
      backgroundColor: _buttonColor.value,
      onPressed: animate,
      tooltip: 'Toggle',
      child: AnimatedIcon(
        icon: AnimatedIcons.menu_close,
        size: 30,
        progress: _animateIcon,
      ),
    );
  }

  List<Widget> prepareMenuOptions() {
    return [
      Transform(
        transform: Matrix4.translationValues(
          0.0,
          _translateButton.value * ((!isUserTypeSuperAdmin) ? 3.0 : 2.0),
          0.0,
        ),
        child: notification(context),
      ),
      if (!isUserTypeSuperAdmin) ...[
        Transform(
          transform: Matrix4.translationValues(
            0.0,
            _translateButton.value * 2.0,
            0.0,
          ),
          child: profile(),
        ),
      ],
      Transform(
        transform: Matrix4.translationValues(
          0.0,
          _translateButton.value * 1.0,
          0.0,
        ),
        child: logout(),
      ),
      toggle(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    Common.customLog("Load Menuitems -- $prepareMenuOptions()");
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: prepareMenuOptions(),
    );
  }
}
