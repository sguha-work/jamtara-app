import 'package:bentec/models/user.dart';
import 'package:bentec/services/common.dart';
import 'package:bentec/services/user_service.dart';
import 'package:bentec/utility/views/custom_cached_network_image.dart';
import 'package:bentec/widgets/admins/admin_details.dart';
import 'package:flutter/material.dart';

class AdminList extends StatefulWidget {
  @override
  State<AdminList> createState() => _AdminListState();
}

class _AdminListState extends State<AdminList> {
  UserService userService = UserService();
  List<Card> adminList = [
    Card(
      child: ListTile(
        title: const Text('Loading admin list ...'),
        subtitle: const Text(''),
        onTap: () {},
        leading: const CircularProgressIndicator(
          backgroundColor: Colors.yellow,
        ),
      ),
    )
  ];

  _AdminListState() {
    _fetchAllAdminList();
  }

  Future<void> _fetchAllAdminList() async {
    List<UserModel>? listOfAdmins =
        await userService.getAllAdminsCreatedBySuperAdmin();
    Common.customLog(
        'listOfAdmins --- ' + (listOfAdmins?.length.toString() ?? ''));
    if (listOfAdmins == null || listOfAdmins.isEmpty) {
      setState(() {
        adminList = [
          Card(
            child: ListTile(
              title: const Text('No admins found'),
              isThreeLine: true,
              subtitle: const Text(''),
              selected: false,
              onTap: () {},
            ),
          )
        ];
      });
    } else {
      List<Card> admins = [];
      for (UserModel admin in listOfAdmins) {
        admins.add(
          Card(
            child: ListTile(
              title: Text(admin.fullName),
              isThreeLine: true,
              subtitle: Text('Contact number(+91) ' + admin.phoneNumber),
              trailing: const Icon(
                Icons.manage_accounts_outlined,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              leading: CustomCachedNetworkImage.showNetworkImage(
                admin.imageFilePath,
                60,
              ),
              selected: false,
              onTap: () {
                _navigateToAdminDetails(admin);
              },
            ),
          ),
        );
      }
      setState(() {
        adminList = admins;
      });
    }
  }

  void _addAdmin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminDetails(null, false, false, true, false),
      ),
    ).then((value) {
      _fetchAllAdminList();
    });
  }

  void _navigateToAdminDetails(UserModel adminModel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AdminDetails(adminModel, true, false, false, true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        widthFactor: double.infinity,
        heightFactor: double.infinity,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _addAdmin(context),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                children: adminList,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
