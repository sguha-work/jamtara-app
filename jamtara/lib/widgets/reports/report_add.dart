import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:bentec/models/consumer.dart';
import 'package:bentec/models/report.dart';
import 'package:bentec/services/common.dart';
import 'package:bentec/services/permission_service.dart';
import 'package:bentec/services/report_service.dart';
import '../../services/user_service.dart';
import '../../services/division_service.dart';
import '../../services/dialogue.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:io' as io;
import '../../services/consumer_service.dart';

class AddReport extends StatefulWidget {
  const AddReport();

  @override
  State<AddReport> createState() => _AddReport();
}

class _AddReport extends State<AddReport> {
  Widget? _dataTableView;
  List<Widget> _imageWidgetList = [];
  List<String> _imageBase64StringList = [];
  final ConsumerService consumerService = ConsumerService();
  final UserService userService = UserService();
  final DivisionService regionService = DivisionService();
  final ReportService reportService = ReportService();
  List<ConsumerModel>? _consumersListFromCacheFile = [];
  List<String> _consumerStringFromCacheFile = [];
  final picker = ImagePicker();
  ConsumerModel _selectedConsumer = ConsumerModel();
  String errorText = '';
  final meterNumberController = TextEditingController();
  final aadharNumberController = TextEditingController();
  final mobileNumberController = TextEditingController();
  final sealingPageNumberController = TextEditingController();
  bool isLoading = false;
  bool isFetching = true;

  @override
  initState() {
    _askForNecessaryPermissions();
    _getAllConsumers();
  }

  void _askForNecessaryPermissions() {
    PermissionService.askCameraPermission();
    PermissionService.askLocationPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Report',
        ),
      ),
      body: isFetching
          ? SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Card(
                child: ListTile(
                  title: const Text('Fetching consumers. Please wait...'),
                  subtitle: const Text(''),
                  selected: false,
                  onTap: () {},
                  leading: const CircularProgressIndicator(
                    backgroundColor: Colors.yellow,
                  ),
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                addPhotos(context),
                viewAndDeletePhotos(context),
                addAndSelectConsumerDetails(context),
              ],
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

  Future<void> _getAllConsumers() async {
    setState(() {
      isFetching = true;
    });
    _consumersListFromCacheFile = await consumerService.getAllConsumersFromFile(
        filterBasedOnApprovalBySupervisor: true);

    if (_consumersListFromCacheFile != null) {
      if (_consumersListFromCacheFile!.isNotEmpty) {
        List<String> consumerString = [];
        for (ConsumerModel consumer in _consumersListFromCacheFile!) {
          consumerString
              .add(consumer.name + "(" + consumer.consumerNo.trim() + ")");
        }
        setState(() {
          _consumerStringFromCacheFile = consumerString;
        });
      }
      Common.customLog(
          "Not NULL....." + _consumerStringFromCacheFile.length.toString());
    } else {
      Common.customLog("NULL.....");
    }
    setState(() {
      isFetching = false;
    });
  }

  _prepareDataTableForConsumer(ConsumerModel consumer) {
    return DataTable(
      columns: const <DataColumn>[
        DataColumn(
          label: Text(
            'Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          label: Text(
            '',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ],
      rows: <DataRow>[
        DataRow(
          cells: <DataCell>[
            const DataCell(Text('Name')),
            DataCell(Text(consumer.name)),
          ],
        ),
        DataRow(
          cells: <DataCell>[
            const DataCell(Text('Consumer ID')),
            DataCell(Text(consumer.consumerId))
          ],
        ),
        DataRow(
          cells: <DataCell>[
            const DataCell(Text('Consumer NumberD')),
            DataCell(Text(consumer.consumerNo))
          ],
        ),
        DataRow(cells: <DataCell>[
          const DataCell(Text('Meter Slno')),
          DataCell(Text(consumer.meterSlno))
        ]),
        DataRow(cells: <DataCell>[
          const DataCell(Text('Subdivision')),
          DataCell(Text(consumer.subdivision))
        ]),
      ],
    );
  }

  void _displayConsumerDetails(String selectionText) {
    String consumerNumber = selectionText.split('(').last.split(')')[0].trim();
    for (ConsumerModel consumer in _consumersListFromCacheFile!) {
      if (consumer.consumerNo.trim() == consumerNumber) {
        Widget tableView = _prepareDataTableForConsumer(consumer);
        _selectedConsumer = consumer;
        setState(() {
          mobileNumberController.text = consumer.mobileNo;
          aadharNumberController.text = consumer.aadharNo;
          _dataTableView = tableView;
        });
        break;
      }
    }
  }

  bool _validate() {
    if (_imageWidgetList.isEmpty) {
      _displayError('Please select one or multiple images to proceed.');
      return false;
    }
    if (_selectedConsumer.consumerNo == '') {
      _displayError('Please add consumer to this report.');
      return false;
    }
    if (meterNumberController.text.trim() == '') {
      _displayError('Please add meter number of consumer.');
      return false;
    }
    if (mobileNumberController.text.trim() == '') {
      _displayError('Please add mobile number of consumer.');
      return false;
    }
    if (!Common.isValidMobileNumber(mobileNumberController.text.trim())) {
      _displayError('Please provide proper mobile number of consumer.');
      return false;
    }
    if (sealingPageNumberController.text.trim().length > 6 &&
        !Common.isNumeric(sealingPageNumberController.text.trim())) {
      _displayError(
          'Maximum length of the Sealing Page No should be 6 and type should be numeric');
      return false;
    }
    return true;
  }

  void _displayError(String message) {
    setState(() {
      errorText = message;
    });
  }

  _clearAllInputFields() {
    setState(() {
      _imageWidgetList = [];
      _imageBase64StringList = [];
      _selectedConsumer = ConsumerModel();
      _dataTableView = null;
    });
  }

  _submitReport(BuildContext context) async {
    if (_validate()) {
      CustomDialog.showConfirmDialog(context, 'Proceed with report submission?',
          () async {
        String? agentId = await userService.getCurrentUserId();
        agentId ??= '';
        ReportModel report = ReportModel(
            createdOn: DateTime.now().millisecondsSinceEpoch,
            createdBy: agentId,
            imageBase64StringList: _imageBase64StringList,
            consumerNumber: _selectedConsumer.consumerNo,
            subdivision: _selectedConsumer.subdivision,
            consumerAadharNumber: aadharNumberController.text.trim(),
            consumerMeterNumber: meterNumberController.text.trim(),
            consumerMobileNumber: mobileNumberController.text.trim(),
            sealingPageNo: sealingPageNumberController.text.trim(),
            consumerName: _selectedConsumer.name);
        CustomDialog.showLoadingDialogue(context);
        setState(() {
          isLoading = true;
        });
        reportService.saveReportToCache(report, (result) {
          CustomDialog.hideLoadingDialogue(context);
          if (result.contains('error__')) {
            String message = result.split('error__').last;
            switch (message) {
              case 'region-code-already-exists':
                _displayError('Provided region already registered');
                break;
              default:
                _displayError(message);
            }
            setState(() {
              isLoading = false;
            });
          }
          if (result.contains('success__')) {
            _displayError('');
            Future.delayed(const Duration(milliseconds: 1000), () {
              _clearAllInputFields();
              setState(() {
                isLoading = false;
              });
              CustomDialog.showSnack(context, 'Report saved', () {
                Navigator.pop(context, true);
              });
            });
          } else {
            setState(() {
              isLoading = false;
            });
          }
        });
      });
    }
  }

  SliverList addPhotos(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        add_or_view_photo(context),
      ]),
    );
  }

  SliverGrid viewAndDeletePhotos(BuildContext context) {
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

  SliverList addAndSelectConsumerDetails(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(
          height: 30,
        ),
        consumer_details_entry_section(context),
        Card(child: _dataTableView),
        Card(
          child: TextField(
            controller: meterNumberController,
            decoration: const InputDecoration(
              labelText: "Enter consumer's meter number*",
              contentPadding: EdgeInsets.all(5),
            ),
          ),
        ),
        Card(
          child: TextField(
            controller: aadharNumberController,
            decoration: const InputDecoration(
              labelText: "Enter consumer's aadhar number",
              contentPadding: EdgeInsets.all(5),
            ),
          ),
        ),
        Card(
          child: TextField(
            controller: mobileNumberController,
            decoration: const InputDecoration(
              labelText: "Enter consumer's mobile number*",
              contentPadding: EdgeInsets.all(5),
            ),
          ),
        ),
        Card(
          child: TextField(
            keyboardType: TextInputType.number,
            controller: sealingPageNumberController,
            decoration: const InputDecoration(
              labelText: "Enter Sealing Page Number*",
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
          height: 30,
        ),
        if (!isLoading) ...[
          FractionallySizedBox(
            widthFactor: 0.8,
            child: ElevatedButton(
              onPressed: () => _submitReport(context),
              child: const Text(
                'Submit Report',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.yellow,
                ),
              ),
            ],
          ),
        ],
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

  Column consumer_details_entry_section(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Type consumer name/number below and select from list',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        Card(
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<String>.empty();
              }
              return _consumerStringFromCacheFile.where((String option) {
                return option
                    .toUpperCase()
                    .contains(textEditingValue.text.toUpperCase());
              });
            },
            onSelected: (String selection) {
              _displayConsumerDetails(selection);
            },
          ),
        )
      ],
    );
  }
}
