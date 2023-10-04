import 'dart:convert';
import 'package:bentec/services/common.dart';
import 'package:bentec/services/consumer_service.dart';
import 'package:bentec/services/dialogue.dart';
import 'package:bentec/services/report_service.dart';
import 'package:bentec/utility/views/custom_cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:bentec/models/report.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:io' as io;

class EditReportDetails extends StatefulWidget {
  final ReportModel? report;
  const EditReportDetails(this.report);
  @override
  State<EditReportDetails> createState() => _EditReportDetailsState();
}

class _EditReportDetailsState extends State<EditReportDetails> {
  final reportService = ReportService();
  final consumerService = ConsumerService();
  final picker = ImagePicker();
  List<Widget> _imageWidgetList = [];
  List<String> _imageBase64StringList = [];
  List<String> _existingImageBase64StringList = [];
  List<Widget> _existingImageWidgetList = [];

  final _consumerNameController = TextEditingController();
  final _consumerNoController = TextEditingController();
  final _consumerMeterNoController = TextEditingController();
  final _consumerAadharController = TextEditingController();
  final _consumerDivisionController = TextEditingController();
  final _consumerSubDivisionController = TextEditingController();
  final _consumerMobileController = TextEditingController();

  String errorText = '';

  @override
  initState() {
    populateReportDetails();
  }

  void populateReportDetails() {
    ReportModel? report = widget.report;
    if (report != null) {
      setState(() {
        _consumerNameController.text = report.consumerName;
        _consumerNoController.text = report.consumerNumber;
        _consumerMeterNoController.text = report.consumerMeterNumber;
        _consumerAadharController.text = report.consumerAadharNumber;
        _consumerDivisionController.text = report.division;
        _consumerSubDivisionController.text = report.subdivision;
        _consumerMobileController.text = report.consumerMobileNumber;
      });
      if (report.imageLinks != null) {
        Common.customLog('Report image link count------');
        Common.customLog(report.imageLinks!.length);
      }
      populateAllExistingImages(report.imageLinks);
    }
  }

  void populateAllExistingImages(List<String>? imageLinks) {
    if (imageLinks != null) {
      imageLinks.forEach((element) {
        _convertNetworkImageToBase64(element);
      });
    }
  }

  _convertNetworkImageToBase64(String imageUrl) async {
    Uri imageUri = Uri.parse(imageUrl);
    http.Response? response = await http.get(imageUri);
    final bytes = response.bodyBytes;
    _existingImageBase64StringList.add(base64Encode(bytes));
    setState(() {
      _existingImageWidgetList.add(
        SizedBox(
          height: 40,
          width: 40,
          child: Card(
            child: AspectRatio(
              aspectRatio: 1.2,
              child: CustomCachedNetworkImage.showNetworkImageForReport(
                imageUrl,
                60,
              ),
            ),
          ),
        ),
      );
    });
  }

  bool _validate() {
    if (_imageWidgetList.isEmpty && _existingImageWidgetList.isEmpty) {
      _displayError('Please select one or multiple images to proceed.');
      return false;
    }
    if (_consumerNameController.text.trim() == '') {
      _displayError("Enter consumer's name.");
      return false;
    }
    if (_consumerNoController.text.trim() == '') {
      _displayError("Enter consumer number.");
      return false;
    }
    if (_consumerMeterNoController.text.trim() == '') {
      _displayError("Enter consumer's meter no.");
      return false;
    }
    if (_consumerAadharController.text.trim() == '' ||
        !Common.isValidAadharNumber(_consumerAadharController.text.trim())) {
      _displayError('Please enter a valid aadhar no.');
      return false;
    }
    if (_consumerMobileController.text.trim() == '') {
      _displayError("Consumer's mobile number cannot be empty");
      return false;
    }
    if (!Common.isValidMobileNumber(_consumerMobileController.text)) {
      _displayError("Consumer's mobile number is wrongly given");
      return false;
    }
    if (_consumerDivisionController.text.trim() == '') {
      _displayError("Enter division.");
      return false;
    }
    if (_consumerSubDivisionController.text.trim() == '') {
      _displayError("Enter sub-division.");
      return false;
    }
    return true;
  }

  void _displayError(String message) {
    setState(() {
      errorText = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit report details',
        ),
      ),
      body: CustomScrollView(
        slivers: [
          layoutForAddPhotos(context),
          layoutForExistingPhotos(context),
          layoutForViewAndDeletePhotos(context),
          layoutForUpdateConsumerDetails(context),
        ],
      ),
    );
  }

  SliverGrid layoutForExistingPhotos(BuildContext context) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(
                  20.0,
                ),
                child: _existingImageWidgetList[index],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  iconSize: 25,
                  onPressed: () => deleteExistingImage(index),
                  icon: const Icon(
                    Icons.cancel_outlined,
                  ),
                ),
              ),
            ],
          );
        },
        childCount: _existingImageWidgetList.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
    );
  }

  SliverList layoutForAddPhotos(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        add_or_view_photo(context),
      ]),
    );
  }

  Padding add_or_view_photo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 20,
      ),
      child: TextButton(
        child: const Icon(
          Icons.add_a_photo,
          color: Colors.blue,
          size: 50,
        ),
        onPressed: pickImage,
      ),
    );
  }

  Future pickImage() async {
    File? imageFile;
    final pickedFile =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    imageFile = File(pickedFile!.path);
    List<int> imageBytes = await imageFile.readAsBytes();
    String base64Image = base64Encode(imageBytes);
    setState(() {
      _imageBase64StringList.add(base64Image);
      _imageWidgetList.add(
        SizedBox(
          height: 40,
          width: 40,
          child: Card(
            child: ClipRRect(
                // borderRadius: BorderRadius.circular(30.0),
                child: imageFile != null
                    ? Image.file(imageFile, height: 50)
                    : null),
          ),
        ),
      );
    });
  }

  SliverGrid layoutForViewAndDeletePhotos(BuildContext context) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(
                  20.0,
                ),
                child: _imageWidgetList[index],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  iconSize: 25,
                  onPressed: () => deleteImage(index),
                  icon: const Icon(
                    Icons.cancel_outlined,
                  ),
                ),
              ),
            ],
          );
        },
        childCount: _imageWidgetList.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
    );
  }

  void deleteImage(int index) {
    setState(() {
      _imageBase64StringList.removeAt(index);
      _imageWidgetList.removeAt(index);
    });
  }

  void deleteExistingImage(int index) {
    setState(() {
      _existingImageBase64StringList.removeAt(index);
      _existingImageWidgetList.removeAt(index);
    });
  }

  SliverList layoutForUpdateConsumerDetails(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        Card(
          child: TextField(
            controller: _consumerNameController,
            decoration: const InputDecoration(
              labelText: "Consumer's name",
              contentPadding: EdgeInsets.all(5),
            ),
          ),
        ),
        Card(
          child: TextField(
            enabled: false,
            controller: _consumerNoController,
            decoration: const InputDecoration(
              labelText: "Consumer number (Read only)",
              contentPadding: EdgeInsets.all(5),
            ),
          ),
        ),
        Card(
          child: TextField(
            controller: _consumerMeterNoController,
            decoration: const InputDecoration(
              labelText: "Consumer's meter number",
              contentPadding: EdgeInsets.all(5),
            ),
          ),
        ),
        Card(
          child: TextField(
            controller: _consumerAadharController,
            decoration: const InputDecoration(
              labelText: "Consumer's aadhar number",
              contentPadding: EdgeInsets.all(5),
            ),
          ),
        ),
        Card(
          child: TextField(
            controller: _consumerMobileController,
            decoration: const InputDecoration(
              labelText: "Consumer's mobile number",
              contentPadding: EdgeInsets.all(5),
            ),
          ),
        ),
        Card(
          child: TextField(
            enabled: false,
            controller: _consumerDivisionController,
            decoration: const InputDecoration(
              labelText: "Division (Read only)",
              contentPadding: EdgeInsets.all(5),
            ),
          ),
        ),
        Card(
          child: TextField(
            controller: _consumerSubDivisionController,
            decoration: const InputDecoration(
              labelText: "Sub-division",
              contentPadding: EdgeInsets.all(5),
            ),
          ),
        ),
        Text(
          errorText,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        const SizedBox(
          height: 50,
        ),
        Center(
          child: ElevatedButton(
            child: const Text(
              'Update details',
            ),
            onPressed: _updateReport,
          ),
        ),
      ]),
    );
  }

  _clearAllInputFields() {
    _consumerDivisionController.clear();
    _consumerNameController.clear();
    _consumerMobileController.clear();
    _consumerMeterNoController.clear();
    _consumerAadharController.clear();
    _consumerSubDivisionController.clear();
    _consumerNoController.clear();
    _imageBase64StringList.clear();
    _imageWidgetList.clear();
    _existingImageBase64StringList.clear();
    _existingImageWidgetList.clear();
  }

  void _updateReport() {
    if (_validate()) {
      ReportModel? passedReport = widget.report;
      if (passedReport != null) {
        CustomDialog.showConfirmDialog(context, 'Update report details?',
            () async {
          _imageBase64StringList.addAll(_existingImageBase64StringList);
          ReportModel report = ReportModel(
              id: passedReport.id,
              createdOn: passedReport.createdOn,
              createdBy: passedReport.createdBy,
              imageBase64StringList: _imageBase64StringList,
              consumerNumber: _consumerNoController.text.trim(),
              subdivision: _consumerSubDivisionController.text.trim(),
              consumerAadharNumber: _consumerAadharController.text.trim(),
              consumerMeterNumber: _consumerMeterNoController.text.trim(),
              consumerMobileNumber: _consumerMobileController.text.trim(),
              consumerName: _consumerNameController.text.trim(),
              division: _consumerDivisionController.text.trim());
          Common.customLog(_imageBase64StringList);
          CustomDialog.showLoadingDialogue(context);
          String result = await reportService.updateReportToDB(report);
          CustomDialog.hideLoadingDialogue(context);
          if (result.contains('error__')) {
            String message = result.split('error__').last;
            switch (message) {
              default:
                _displayError(message);
            }
          }
          if (result.contains('success__')) {
            _displayError('');
            _updateConsumerDetails();
          }
        });
      }
    }
  }

  void _updateConsumerDetails() async {
    CustomDialog.showLoadingDialogue(context);
    String result = await consumerService.updateConsumer(
        _consumerNoController.text.trim(),
        _consumerMeterNoController.text.trim(),
        _consumerMobileController.text.trim(),
        _consumerAadharController.text.trim());
    CustomDialog.hideLoadingDialogue(context);
    if (result.contains('error__')) {
      String message = result.split('error__').last;
      switch (message) {
        default:
          _displayError(message);
      }
    }
    if (result.contains('success__')) {
      _displayError('');
      Future.delayed(const Duration(milliseconds: 1000), () {
        _clearAllInputFields();
        CustomDialog.showSnack(context, 'Consumer details Updated', () {
          Navigator.pop(context, true);
        });
      });
    } else {
      CustomDialog.hideLoadingDialogue(context);
    }
  }
}
