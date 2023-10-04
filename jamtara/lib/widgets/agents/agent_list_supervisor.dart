import 'package:bentec/models/user.dart';
import 'package:bentec/services/common.dart';
import 'package:bentec/services/user_service.dart';
import 'package:bentec/utility/views/custom_cached_network_image.dart';
import 'package:flutter/material.dart';

import '../app_theme.dart';

class AgentList_Supervisor extends StatefulWidget {
  UserModel? supervisor;
  AgentList_Supervisor(this.supervisor);
  @override
  State<AgentList_Supervisor> createState() => _AgentList_SupervisorState();
}

class _AgentList_SupervisorState extends State<AgentList_Supervisor> {
  List<Card> card_agent = [
    Card(
      child: ListTile(
        title: const Text('Loading agent list ---'),
        isThreeLine: true,
        subtitle: const Text(''),
        trailing: const Icon(
          Icons.manage_accounts_outlined,
        ),
        selected: false,
        onTap: () {},
      ),
    )
  ];
  UserService userService = UserService();
  @override
  void initState() {
    // TODO: implement initState
    Common.customLog('1......');
    Common.customLog(widget.supervisor!.id);
    Common.customLog('2......');
    _getListOfAgents();
    Common.customLog('3......');
    super.initState();
  }

  _AgentList_SupervisorState() {}
  void _getListOfAgents() async {
    var supervisor = widget.supervisor;
    if (supervisor != null) {
      List<UserModel>? listOfAgents =
          await userService.getAllAgentBasedOnCreator(supervisor.id);
      Common.customLog('List of agents.....');
      Common.customLog(listOfAgents);
      if (listOfAgents == null || listOfAgents.isEmpty) {
        setState(() {
          card_agent = [
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
        });
      } else {
        List<Card> agentList = [];
        for (UserModel agent in listOfAgents) {
          agentList.add(Card(
            child: ListTile(
              title: Text(agent.fullName),
              isThreeLine: true,
              subtitle: Text('Contact number(+91) ' +
                  agent.phoneNumber +
                  '\nDivision : ' +
                  agent.division),
              leading: CustomCachedNetworkImage.showNetworkImage(
                agent.imageFilePath,
                60,
              ),
              selected: false,
              onTap: () {},
            ),
          ));
        }
        setState(() {
          card_agent = agentList;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.nearlyWhite,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Agent list',
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                children: card_agent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
