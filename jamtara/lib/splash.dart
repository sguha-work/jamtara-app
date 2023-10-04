import 'dart:async';

import 'package:bentec/services/user_service.dart';
import 'package:bentec/widgets/login/login.dart';
import 'package:bentec/widgets/main_tab_view/main_tab_view.dart';
import 'package:flutter/material.dart';

class Splash extends StatefulWidget {
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with TickerProviderStateMixin {
  bool _isLoggedin = true;
  UserService userService = UserService();

  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 3),
    vsync: this,
  )..repeat();
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.fastOutSlowIn,
  );

  _SplashState() {
    _checkStatus();
  }
  _checkStatus() async {
    String? userId = await userService.getCurrentUserId() ?? '';
    if (userId == '') {
      _isLoggedin = false;
    } else {
      _isLoggedin = true;
    }
    setState(() {});
    // _updateCache();
  }

  // _updateCache() {}

  void moveToNextScreenBasedOnUserType() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (BuildContext context) =>
            _isLoggedin == true ? const MainTabView() : Login(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 3),
      () => {
        _controller.stop(),
        moveToNextScreenBasedOnUserType(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizeTransition(
        sizeFactor: _animation,
        axis: Axis.horizontal,
        axisAlignment: -1,
        child: Center(
          child: Image.asset('assets/images/app_logo.png'),
        ),
      ),
    );
  }
}
