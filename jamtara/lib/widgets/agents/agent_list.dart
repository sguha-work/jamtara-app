import 'package:bentec/services/common.dart';
import 'package:flutter/material.dart';
import 'package:bentec/models/user.dart';
import 'package:bentec/services/user_service.dart';
import 'package:bentec/utility/views/custom_cached_network_image.dart';
import 'package:bentec/utility/views/progress_view.dart';
import 'package:bentec/widgets/agents/agent_add.dart';

import 'agent_edit.dart';

class AgentList extends StatefulWidget {
  final bool shouldActionViewVisible;
  final String? supervisorId;
  AgentList(this.shouldActionViewVisible, this.supervisorId);
  @override
  State<AgentList> createState() => _AgentListState();
}

class _AgentListState extends State<AgentList> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Common.customLog('_AgentListState............init');
  }

  var _isUploadButtonTapped = false;
  int groupValue = 1;
  String txt = '';
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
  _AgentListState() {
    _getAndSetListOfAgents();
  }
  void addAgent(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddAgent()),
    ).then((value) {
      return value ? _getAndSetListOfAgents() : null;
    });
  }

  void showUploadView() {
    setState(() {
      _isUploadButtonTapped = !_isUploadButtonTapped;
    });
  }

  void uploadSupervisors(BuildContext context) {
    setState(() {
      _isUploadButtonTapped = false;
    });
  }

  void _getAndSetListOfAgents() async {
    String? currentLoggedInUserId = await userService.getCurrentUserId() ?? '';
    List<UserModel>? listOfAgents =
        await userService.getAllAgent(currentLoggedInUserId);
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
                ' Division : ' +
                agent.division),
            trailing: const Icon(
              Icons.manage_accounts_outlined,
            ),
            leading: CustomCachedNetworkImage.showNetworkImage(
              agent.imageFilePath,
              60,
            ),
            selected: false,
            onTap: () {
              _editAgent(agent);
            },
          ),
        ));
      }
      setState(() {
        card_agent = agentList;
      });
    }
  }

  void _editAgent(UserModel agent) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAgent(agent),
      ),
    ).then((value) {
      return value ? _getAndSetListOfAgents() : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      widthFactor: double.infinity,
      heightFactor: double.infinity,
      child: Column(
        children: [
          if (widget.shouldActionViewVisible) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => addAgent(context),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
          Expanded(
            child: ListView(
              children: card_agent,
            ),
          ),
        ],
      ),
    );
  }
}
