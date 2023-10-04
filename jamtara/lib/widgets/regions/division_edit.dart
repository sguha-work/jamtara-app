import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/common.dart';
import '../../models/division.dart';
import '../../services/division_service.dart';
import '../../services/user_service.dart';
import '../../services/dialogue.dart';
import 'dart:io';
import 'dart:io' as io;

class EditDivision extends StatefulWidget {
  //const AddRegion(DivisionModel? region);
  final DivisionModel? region;
  const EditDivision(this.region);
  @override
  State<EditDivision> createState() => _EditDivision();
}

class _EditDivision extends State<EditDivision> {
  bool isEdited = false;
  String editableDivisionDocId = '';
  final DivisionService divisionService = DivisionService();
  final UserService userService = UserService();
  String errorText = '';
  final divisionController = TextEditingController();
  _EditDivision() {
    //setState(() {

    //});
  }
  bool _validate() {
    if (divisionController.text.trim() == '') {
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
    divisionController.clear();
  }

  void updateRegion(BuildContext context) async {
    if (_validate()) {
      String? currentUserId = await userService.getCurrentUserId() ?? '';
      if (currentUserId != null) {
        DivisionModel region = DivisionModel(
            code: divisionController.text.trim(),
            createdOn: DateTime.now().millisecondsSinceEpoch.toString(),
            createdBy: currentUserId);

        CustomDialog.showLoadingDialogue(context);
        // adding user
        String result =
            await divisionService.update(editableDivisionDocId, region);
        if (result.contains('error__')) {
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
          isEdited = true;
          _displayError('');
          CustomDialog.hideLoadingDialogue(context);
          Future.delayed(const Duration(milliseconds: 1000), () {
            _clearAllInputFields();
            CustomDialog.showSnack(context, 'Division updated', () {
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

  _preparValueForEditForm(DivisionModel? division) {
    if (division != null) {
      divisionController.text = division.code;
      editableDivisionDocId = division.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    DivisionModel? data = widget.region;
    if (!isEdited) {
      _preparValueForEditForm(data);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit division',
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              child: TextField(
                controller: divisionController,
                textCapitalization: TextCapitalization.characters,
                readOnly: true,
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
              onPressed: () => updateRegion(context),
              child: const Text(
                'Update division',
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
