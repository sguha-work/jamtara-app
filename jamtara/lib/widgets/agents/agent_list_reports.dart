import 'package:bentec/models/report.dart';
import 'package:bentec/services/common.dart';
import 'package:bentec/services/report_service.dart';
import 'package:bentec/widgets/reports/consolidated_report_list.dart';
import 'package:bentec/widgets/reports/report_list.dart';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'package:bentec/models/user.dart';
import 'package:bentec/services/user_service.dart';
import 'package:bentec/utility/views/custom_cached_network_image.dart';
import 'package:bentec/utility/views/progress_view.dart';
import 'package:bentec/widgets/agents/agent_add.dart';

import 'agent_edit.dart';

class AgentListForReports extends StatefulWidget {
  bool? shouldShowAppBar;
  UserModel? supervisor;
  AgentListForReports(this.shouldShowAppBar, this.supervisor, {Key? key})
      : super(key: key);
  @override
  State<AgentListForReports> createState() => _AgentListForReportsState();
}

class _AgentListForReportsState extends State<AgentListForReports> {
  UserService userService = UserService();
  final ReportService _reportService = ReportService();
  List<Widget> _agentCardList = [
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
  @override
  void initState() {
    // TODO: implement initState
    _getAgentList();
    super.initState();
  }

  _AgentListForReportsState() {}
  _getAgentList() async {
    var supervisor = widget.supervisor;
    if (supervisor != null) {
      List<UserModel>? agentList =
          await userService.getAllAgentBasedOnCreator(supervisor.id);
      List<Widget> cardList = [];
      for (UserModel agent in agentList!) {
        int reportCount =
            await _reportService.getReportListCountByAgentIdFromDB(agent.id);
        cardList.add(Card(
          child: ListTile(
            title: Text(
              agent.fullName,
            ),
            subtitle: Text(
              reportCount.toString() + ' reports',
            ),
            leading: CustomCachedNetworkImage.showNetworkImage(
              agent.imageFilePath,
              60,
            ),
            selected: false,
            onTap: () {
              _loadReportListOfAgent(agent, supervisor.fullName);
            },
          ),
        ));
      }
      setState(() {
        _agentCardList = cardList;
      });
    }
  }

  void _loadReportListOfAgent(UserModel agent, String supervisorName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsolidateReportList(agent, supervisorName),
      ),
    ).then((value) {
      return; // value ? _getAgentList() : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    Common.customLog("BUILD........" + widget.supervisor!.id);
    return Container(
      color: AppTheme.nearlyWhite,
      child: Scaffold(
        appBar: ((widget.shouldShowAppBar ?? false) == true)
            ? AppBar(
                title: const Text(
                  'Agent list',
                ),
              )
            : null,
        body: Center(
          widthFactor: double.infinity,
          heightFactor: double.infinity,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  'Agents under ' + widget.supervisor!.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: _agentCardList,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
