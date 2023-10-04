import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/notifications.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'common.dart';

class CustomNotificationService {
  static bool _isListenerAdded = false;
  final String notificationsCollectionName = 'collections_notification';
  CustomNotificationService() {
    //_initializeCustomNotification();
  }
  _initializeCustomNotification() {
    AwesomeNotifications().initialize(
        // set the icon to null if you want to use the default app icon
        null,
        [
          NotificationChannel(
              channelKey: 'bentec_channel',
              channelName: 'Bentec notifications',
              channelDescription: 'Notification channel for Bentec',
              defaultColor: const Color(0xFF9D50DD),
              ledColor: Colors.white)
        ]);
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        // Insert here your friendly dialog box before call the request method
        // This is very important to not harm the user experience
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  void _showNotification(CustomNotificationModel notification) {
    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: Random().nextInt(1234567890),
            channelKey: 'bentec_channel',
            title: notification.title,
            notificationLayout: NotificationLayout.BigText,
            body: notification.body));
  }

  Future<void> makeNotificationEntryToDB(String type, String title, String body,
      String data, Function? callback) async {
    CustomNotificationModel notification = CustomNotificationModel(
        type: type,
        title: title,
        body: body,
        data: data,
        time: DateTime.now().millisecondsSinceEpoch.toString());
    CollectionReference notificationCollectionReference =
        FirebaseFirestore.instance.collection(notificationsCollectionName);
    DocumentReference notificationDocumentReference =
    notificationCollectionReference.doc(Common.getUniqueId());
    notificationDocumentReference.set({
      "type": notification.type,
      "title": notification.title,
      "body": notification.body,
      "data": notification.data,
      "time": notification.time
    }).then((value) {
      if (callback != null) {
        callback('success');
      }
    }).catchError((error) {
      if (callback != null) {
        callback('error');
      }
    });
  }

  void addListner() {
    if (CustomNotificationService._isListenerAdded == false) {
      _initializeCustomNotification();
      CollectionReference notificationCollectionReference =
          FirebaseFirestore.instance.collection(notificationsCollectionName);
      notificationCollectionReference.snapshots().listen((querySnapshot) {
        if (CustomNotificationService._isListenerAdded) {
          for (var change in querySnapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              dynamic data = change.doc.data();
              if (data != null) {
                // show notification here
                CustomNotificationModel notification = CustomNotificationModel(
                    type: data['type'],
                    title: data['title'],
                    body: data['body'],
                    data: data['data'],
                    time: data['time']);
                _showNotification(notification);
              }
            }
          }
        } else {
          CustomNotificationService._isListenerAdded = true;
        }
      });
    }
  }
}
