import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/common.dart';
import '../../models/division.dart';
import '../../services/division_service.dart';
import '../../services/user_service.dart';
import '../../services/dialogue.dart';
import 'dart:io';
import 'dart:io' as io;

class AddDivision extends StatefulWidget {
  const AddDivision();

  @override
  State<AddDivision> createState() => _AddDivision();
}

class _AddDivision extends State<AddDivision> {
  final DivisionService divisionService = DivisionService();
  final UserService userService = UserService();
  String errorText = '';
  final codeController = TextEditingController();
  bool _validate() {
    if (codeController.text.trim() == '') {
      _displayError('Division cannot be empty');
      return false;
    }
    return true;
  }

  void _displayError(String message) {
    setState(() {
      errorText = message;
    });
  }

  void _clearAllInputFields() {
    codeController.clear();
  }

  void addDivision(BuildContext context) async {
    if (_validate()) {
      String? currentUserId = await userService.getCurrentUserId() ?? '';
      if (currentUserId != null) {
        DivisionModel region = DivisionModel(
            code: codeController.text.trim(),
            createdOn: DateTime.now().millisecondsSinceEpoch.toString(),
            createdBy: currentUserId);

        CustomDialog.showLoadingDialogue(context);
        // adding user
        String result = await divisionService.add(region);
        if (result.contains('error__')) {
          CustomDialog.hideLoadingDialogue(context);
          String messege = result.split('error__').last;
          switch (messege) {
            case 'division-code-already-exists':
              _displayError('Provided division already registered');
              break;
            default:
              _displayError(messege);
          }
        }
        if (result.contains('success__')) {
          _displayError('');
          CustomDialog.hideLoadingDialogue(context);
          Future.delayed(const Duration(milliseconds: 1000), () {
            _clearAllInputFields();
            CustomDialog.showSnack(context, 'Division added', () {
              Navigator.pop(context, true);
            });
          });
        } else {
          CustomDialog.hideLoadingDialogue(context);
        }
      } else {
        //ToDo
        // user session expired
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Division',
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              child: TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: "Enter division",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Text(
              errorText,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(
              height: 30,
            ),
            ElevatedButton(
              onPressed: () => addDivision(context),
              child: const Text(
                'Add Division',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
