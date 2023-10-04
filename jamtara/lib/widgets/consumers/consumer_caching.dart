import 'package:bentec/services/common.dart';
import 'package:bentec/services/consumer_service.dart';
import 'package:bentec/services/user_service.dart';
import 'package:bentec/widgets/main_tab_view/main_tab_view.dart';
import 'package:flutter/material.dart';

class ConsumerCaching extends StatefulWidget {
  @override
  State<ConsumerCaching> createState() => _ConsumerCachingState();
}

class _ConsumerCachingState extends State<ConsumerCaching> {
  UserService userService = UserService();
  final ConsumerService _consumerService = ConsumerService();
  bool isCachingInProgress = true;

  _ConsumerCachingState() {
    buildConsumerCachBasedOnUserType();
  }

  void buildConsumerCachBasedOnUserType() async {
    Common.customLog('CONSUMER CACHING START>>>>>>>>>');
    String? userType = await userService.getCurrentUserType();
    Common.customLog('USER TYPE ---' + userType.toString());
    switch (userType) {
      case 'admin':
        buildConsumerCacheForAdmin();
        break;
      case 'agent':
        buildConsumerCacheForAgent();
        break;
      case 'superadmin':
        buildConsumerCacheForSuperAdmin();
        break;
      case 'supervisor':
        buildConsumerCacheForSupervisor();
        break;
      default:
    }
  }

  void buildConsumerCacheForAgent() {
    _consumerService.buildConsumerListCacheForAgent(() {
      Common.customLog('CONSUMER CACHING COMPLETED>>>>>>>>>');
      setState(() {
        isCachingInProgress = false;
      });
      navigateToTabBarController();
    });
  }

  void buildConsumerCacheForSuperAdmin() {
    // _consumerService.buildConsumerListCacheForSuperAdmin(() {
    //   Common.customLog('CONSUMER CACHING COMPLETED>>>>>>>>>');
    //   setState(() {
    //     isCachingInProgress = false;
    //   });
    // });
    navigateToTabBarController();
  }

  void buildConsumerCacheForAdmin() {
    // _consumerService.buildConsumerListCacheForSuperAdmin(() {
    //   Common.customLog('CONSUMER CACHING COMPLETED>>>>>>>>>');
    //   setState(() {
    //     isCachingInProgress = false;
    //   });
    //   navigateToTabBarController();
    // });
    navigateToTabBarController();
  }

  void buildConsumerCacheForSupervisor() {
    // _consumerService.buildConsumerListCacheForSuperAdmin(() {
    //   Common.customLog('CONSUMER CACHING COMPLETED>>>>>>>>>');
    //   setState(() {
    //     isCachingInProgress = false;
    //   });
    //   navigateToTabBarController();
    // });
    navigateToTabBarController();
  }

  void navigateToTabBarController() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (BuildContext context) => const MainTabView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isCachingInProgress == true
          ? Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(
                        backgroundColor: Colors.yellow,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        "Consumer data is being cached. Please don't close the application",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const Center(
              child: Text(
                'Consumer data caching is completed',
              ),
            ),
    );
  }
}
