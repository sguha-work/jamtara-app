import 'package:bentec/splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings =
      const Settings(cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // final ThemeData theme = ThemeData(
  //   primarySwatch: Colors.blue,
  // );
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    //LocalNotificationService.initialize(context);

    ///gives you the message on which user taps
    ///and it opened the app from terminated state
    //FirebaseMessaging.instance.getInitialMessage().then((message) {
    // if(message != null){
    //   final routeFromMessage = message.data["route"];
    //   Navigator.of(context).pushNamed(routeFromMessage);
    // }
    //});

    ///forground work
    // FirebaseMessaging.onMessage.listen((message) {
    //   if(message.notification != null){
    //     Common.customLog(message.notification!.body);
    //     Common.customLog(message.notification!.title);
    //     Common.customLog('hello hello hello hello');
    //   }
    //
    //   //LocalNotificationService.display(message);
    // });

    ///When the app is in background but opened and user taps
    ///on the notification
    // FirebaseMessaging.onMessageOpenedApp.listen((message) {
    //   final routeFromMessage = message.data["route"];
    //
    //   Navigator.of(context).pushNamed(routeFromMessage);
    // });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BENTEC',
      // theme: theme.copyWith(
      //     colorScheme: theme.colorScheme.copyWith(
      //   secondary: Colors.amber,
      // )),
      home: Splash(),
    );
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
