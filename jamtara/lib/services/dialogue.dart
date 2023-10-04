import 'package:flutter/material.dart';

class CustomDialog {
  static void showLoadingDialogue(context, {String message = 'Loading---'}) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          //title: const Text('Add expense'),
          content: SingleChildScrollView(
            child: Column(
              //shrinkWrap: true,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      backgroundColor: Colors.transparent),
                ),
              ],
            ),
          ),
          actions: [],
        );
      },
    );
  }

  static void hideLoadingDialogue(context) {
    Navigator.pop(context);
  }

  static void showSuccessMessege(context, String messege) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Success'),
          content: SingleChildScrollView(
            child: Column(
              //shrinkWrap: true,
              children: [
                Text(
                  messege,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      backgroundColor: Colors.transparent),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  static void showConfirmDialog(context, String messege, Function callback) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Confirm action'),
          content: SingleChildScrollView(
            child: Column(
              //shrinkWrap: true,
              children: [
                Text(
                  messege,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      backgroundColor: Colors.transparent),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
                callback();
              },
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  static void showSnack(context, message, Function callback) {
    final snackBar = SnackBar(
      duration: const Duration(milliseconds: 1500),
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    );

    // Find the ScaffoldMessenger in the widget tree
    // and use it to show a SnackBar.

    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((value) {
      ScaffoldMessenger.of(context).clearSnackBars();
      callback();
    });
  }

  static void openFullScreenLoaderDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Card(
            child: ListTile(
              title: const Text(
                  "Building cache please don't close or press back ..."),
              subtitle: const Text(''),
              selected: false,
              onTap: () {},
              leading: const CircularProgressIndicator(
                backgroundColor: Colors.yellow,
              ),
            ),
          ),
        );
      },
    );
  }
}
