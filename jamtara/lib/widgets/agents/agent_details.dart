import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/common.dart';
import '../../models/user.dart';
import '../../models/division.dart';
import '../../services/user_service.dart';
import '../../services/division_service.dart';
import '../../services/dialogue.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:io' as io;
// This screen will be seen by admin
class AgentDetails extends StatefulWidget {
  final UserModel? agent;
  const AgentDetails(this.agent);
  @override
  State<AgentDetails> createState() => _AgentDetails();
}

class _AgentDetails extends State<AgentDetails> {
  bool isNewImagePicked = false;
  String userId = '';
  String imageFilePath = '';
  final UserService userService = UserService();
  final DivisionService divisionService = DivisionService();
  String errorText = '';
  String divisionValue = '-1';
  List<Map<String, String>> divisionsFromDB = [
    {'text': 'Select region code', 'value': '-1'}
  ];
  final nameController = TextEditingController();
  final dobController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final emailController = TextEditingController();
  final panNumberController = TextEditingController();
  final aadharController = TextEditingController();
  final areaController = TextEditingController();
  final cityController = TextEditingController();
  final pinController = TextEditingController();
  final stateController = TextEditingController();
  final picker = ImagePicker();
  File? _imageFile;
  Future pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery,
        imageQuality: 50
    );
    isNewImagePicked = true;
    setState(() {
      _imageFile = File(pickedFile!.path);
    });
  }

  _AgentDetails() {
    _getRegionCodesFromDB();
  }
  Future<void> _getRegionCodesFromDB() async {
    List<DivisionModel> regionList = await divisionService.getAllDivision();
    List<Map<String, String>> valuesForDropdown = [];
    valuesForDropdown.add({'text': 'Select region code', 'value': '-1'});
    for (var region in regionList) {
      valuesForDropdown.add({
        'text': region.code,
        'value': region.code
      });
    }
    setState(() {
      divisionsFromDB = valuesForDropdown;
    });
    UserModel? supervisor = widget.agent;
      userId = supervisor!.id;
      _prepareValueForEditForm(supervisor);
  }
  Future<void> _prepareValueForEditForm(UserModel? agent) async {
    if (agent != null) {
      setState(() {
        nameController.text = agent.fullName;
        dobController.text = agent.dateOfBirth;
        phoneNumberController.text = agent.phoneNumber;
        emailController.text = agent.email;
        panNumberController.text = agent.panNumber;
        aadharController.text = agent.aadharNumber;
        areaController.text = agent.area;
        cityController.text = agent.city;
        pinController.text = agent.pin;
        stateController.text = agent.state;
        divisionValue = agent.division;
      });
      File? imageFile;
      if (agent.imageFilePath != '') {
        // image path is the url of fire storage
        imageFilePath = agent.imageFilePath;
        imageFile = await Common.fileFromImageUrl(agent.imageFilePath);
        setState(() {
          _imageFile = imageFile;
        });
      } else {
        imageFile = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agent Details',
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(30.0),
                  child: _imageFile != null
                      ? Image.file(_imageFile!, height: 200)
                      : null),
            ),
            Card(
              child: TextButton(
                child: const Icon(
                  Icons.add_a_photo,
                  color: Colors.blue,
                  size: 50,
                ),
                onPressed: pickImage,
              ),
            ),
            Card(
              child: TextField(
                controller: nameController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Agent's name",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: dobController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Agent's date of birth dd-mm-yy",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: phoneNumberController,
                readOnly: true,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
                decoration: const InputDecoration(
                  labelText: "Agent's mobile no.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: emailController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Agen's email",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
                child: DropdownButton<String>(
                  value: divisionValue,
                  icon: const Icon(Icons.arrow_downward),
                  iconSize: 24,
                  elevation: 16,
                  isExpanded: true,
                  style: const TextStyle(color: Colors.black),
                  underline: Container(
                    height: 1,
                    color: Colors.black,
                  ),
                  onChanged: null,
                  items: divisionsFromDB.map((Map<String, String> data) {
                    return DropdownMenuItem<String>(
                      value: data['value'],
                      child: Text(data['text'].toString()),
                    );
                  }).toList(),
                )),
            Card(
              child: TextField(
                controller: panNumberController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Agent's PAN number.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: aadharController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Agent's Aadhar id.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: areaController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Agent's area.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: cityController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Agent's city.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: pinController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Agent's pin.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Card(
              child: TextField(
                controller: stateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Agent's state.",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }
}
