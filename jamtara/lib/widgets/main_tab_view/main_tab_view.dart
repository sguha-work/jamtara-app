import 'package:bentec/models/user.dart';
import 'package:bentec/services/common.dart';
import 'package:bentec/services/consumer_service.dart';
import 'package:bentec/widgets/admins/admin_list.dart';
import 'package:bentec/widgets/agents/agent_list_reports.dart';
import 'package:bentec/widgets/supervisors/supervisor_list_reports.dart';
import 'package:flutter/material.dart';
import 'package:bentec/services/custom_notification.dart';
import 'package:bentec/utility/views/fancy_floating_menu.dart';
import 'package:bentec/widgets/consumers/consumer_list.dart';
import 'package:bentec/widgets/regions/division_list.dart';
import 'package:bentec/widgets/reports/agent_report_list.dart';
import 'package:bentec/widgets/reports/report_list.dart';
import 'package:bentec/widgets/supervisors/supervisor_list.dart';
import 'package:bentec/widgets/agents/agent_list.dart';
import '../../services/user_service.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({Key? key}) : super(key: key);
  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView>
    with TickerProviderStateMixin {
  int TAB_LENGTH = 0;
  bool isUserTypeAvailable = false;

  late TabController tabController;
  CustomNotificationService notification = CustomNotificationService();
  ConsumerService _consumerService = ConsumerService();
  // bool _isFetchingData = false;
  List<Tab> menuHeadings = [];
  List<Center> menuItems = [];
  UserService userService = UserService();

  void _setMenuForAdmin() {
    notification.addListner();
    setState(() {
      menuHeadings = const [
        Tab(
          text: 'Reports',
        ),
        Tab(
          text: 'Supervisors',
        ),
        Tab(
          text: 'Divisions',
        ),
      ];
      menuItems = [
        Center(
          child: SupervisorListForReports(),
        ),
        Center(
          child: SupervisorList(),
        ),
        Center(
          child: DivisionList(false, null),
        ),
      ];
    });
  }

  void _setMenuForSuperAdmin() async {
    setState(() {
      // _isFetchingData = true;
      menuHeadings = const [
        Tab(
          text: 'Admins',
        ),
        Tab(
          text: 'Reports',
        ),
        Tab(
          text: 'Supervisors',
        ),
        Tab(
          text: 'Divisions',
        ),
        Tab(
          text: 'Consumers',
        ),
      ];
      menuItems = [
        Center(
          child: AdminList(),
        ),
        Center(
          child: SupervisorListForReports(),
        ),
        Center(
          child: SupervisorList(),
        ),
        Center(
          child: DivisionList(false, null),
        ),
        Center(
          child: ConsumerList(null),
        ),
      ];
    });
    // buildConsumerCacheForSuperAdmin();
  }

  void _setMenuForSupervisor() async {
    String? currentUserId = await userService.getCurrentUserId();
    UserModel? supervisor = await userService.getUserById(currentUserId ?? '');
    if (supervisor != null) {
      setState(() {
        menuHeadings = const [
          Tab(
            text: 'Reports',
          ),
          Tab(
            text: 'Agents',
          ),
          Tab(
            text: 'Consumers',
          ),
        ];
        menuItems = [
          Center(
            child: AgentListForReports(false, supervisor),
          ),
          Center(
            child: AgentList(true, null),
          ),
          Center(
            child: ConsumerList(null),
          ),
        ];
      });
    }
  }

  // void buildConsumerCacheForAgent() {
  //   _consumerService.buildConsumerListCacheForAgent(() {
  //     Common.customLog('CONSUMER CACHING COMPLETED>>>>>>>>>');
  //     setState(() {
  //       _isFetchingData = false;
  //     });
  //   });
  // }
  //
  // void buildConsumerCacheForSuperAdmin() {
  //   _consumerService.buildConsumerListCacheForSuperAdmin(() {
  //     Common.customLog('CONSUMER CACHING COMPLETED>>>>>>>>>');
  //     setState(() {
  //       _isFetchingData = false;
  //     });
  //   });
  // }

  void _setMenuForAgent() {
    setState(() {
      // _isFetchingData = true;
      menuHeadings = const [
        Tab(
          text: 'Reports',
        ),
        Tab(
          text: 'Consumers',
        ),
      ];
      menuItems = [
        Center(
          child: AgentReportList(),
        ),
        Center(
          child: ConsumerList(null),
        ),
      ];
    });
    // buildConsumerCacheForAgent();
  }

  Future<void> _prepareMenu() async {
    isUserTypeAvailable = true;
    String? userType = await userService.getCurrentUserType();
    switch (userType) {
      case 'admin':
        _setMenuForAdmin();
        break;
      case 'supervisor':
        _setMenuForSupervisor();
        break;
      case 'agent':
        _setMenuForAgent();
        break;
      case 'superadmin':
        _setMenuForSuperAdmin();
        break;
      default:
    }
  }

  @override
  void initState() {
    super.initState();
    getTabLength();
  }

  Future<void> getTabLength() async {
    String? userType = await userService.getCurrentUserType();
    switch (userType) {
      case 'admin':
        TAB_LENGTH = 3;
        break;
      case 'superadmin':
        TAB_LENGTH = 5;
        break;
      case 'supervisor':
        TAB_LENGTH = 3;
        break;
      case 'agent':
        TAB_LENGTH = 2;
        break;
      default:
    }
    tabController = TabController(vsync: this, length: TAB_LENGTH);
    tabController.addListener(() {
      if (tabController.indexIsChanging) {
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
    _prepareMenu();
  }

  void settingsButtonClicked() {
    Common.customLog('Settings button clicked.....');
  }

  @override
  Widget build(BuildContext context) {
    return isUserTypeAvailable == false
        ? Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
            child: const Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.yellow,
              ),
            ),
          )
        : AbsorbPointer(
            absorbing: !isUserTypeAvailable,
            child: buildDefaultTabController(),
          );
  }

  DefaultTabController buildDefaultTabController() {
    return DefaultTabController(
      length: TAB_LENGTH,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'BENTEC',
          ),
          bottom: TabBar(
            isScrollable: TAB_LENGTH > 3,
            controller: tabController,
            tabs: menuHeadings,
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          controller: tabController,
          children: menuItems,
        ),
        floatingActionButton: FancyFloatingMenu(
          settingsButtonClicked,
          'Settings',
        ),
      ),
    );
  }
}

/*
DefaultTabController(
      length: TAB_LENGTH,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'BENTEC',
          ),
          bottom: TabBar(
            isScrollable: TAB_LENGTH > 3,
            controller: tabController,
            tabs: menuHeadings,
          ),
        ),
        body: _isFetchingData
            ? Card(
                child: ListTile(
                  title:
                      const Text("Building cache please don't close app ..."),
                  subtitle: const Text(''),
                  selected: false,
                  onTap: () {},
                  leading: const CircularProgressIndicator(
                    backgroundColor: Colors.yellow,
                  ),
                ),
              )
            : TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                controller: tabController,
                children: menuItems,
              ),
        floatingActionButton: FancyFloatingMenu(
          settingsButtonClicked,
          'Settings',
        ),
      ),
    );
 */
