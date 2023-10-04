import 'package:bentec/models/user.dart';
import 'package:bentec/services/common.dart';
import 'package:bentec/services/consumer_service.dart';
import 'package:bentec/services/user_service.dart';
import 'package:bentec/widgets/consumers/consumer_list.dart';
import 'package:flutter/material.dart';
import 'package:bentec/widgets/regions/division_add.dart';
import 'package:bentec/widgets/regions/division_edit.dart';
import '../../models/division.dart';
import '../../services/division_service.dart';
import '../../services/dialogue.dart';

class DivisionList extends StatefulWidget {
  bool isForDivisionSelection;
  List<String>? alreadySelectedDivisions;
  DivisionList(this.isForDivisionSelection, this.alreadySelectedDivisions);
  @override
  State<DivisionList> createState() => _DivisionListState();
}

class _DivisionListState extends State<DivisionList> {
  List<String> selectedDivisions = [];
  List<DivisionModel> _listOfDivisions = [];
  List<DivisionSelectionModel> _listOfDivisionSelection = [];
  List<int> _listOfConsumersUnderDivisions = [];
  final DivisionService _divisionService = DivisionService();
  final ConsumerService _consumerService = ConsumerService();
  final UserService userService = UserService();
  String? _userType;
  @override
  void initState() {
    super.initState();
    widget.alreadySelectedDivisions?.forEach((element) {
      selectedDivisions.add(element);
    });
    _getAllDivisions();
  }

  void _getConsumerCount(List<DivisionModel> divisionsFromDB) async {
    for (DivisionModel division in divisionsFromDB) {
      int numberOfConsumers = await _consumerService
          .getNumberOfConsumersUnderDivision(division.code);
      _listOfConsumersUnderDivisions.add(numberOfConsumers);
      setState(() {});
    }
  }

  void _getAllDivisions() async {
    String? userType = await userService.getCurrentUserType();
    if (userType != null) {
      Common.customLog('User type------>' + userType);
      _userType = userType;
      switch (_userType) {
        case 'superadmin':
          _getAllDivisionsForSuperAdmin();
          break;
        case 'admin':
          _getAllDivisionsForAdmin();
          break;
        default:
      }
    } else {
      Common.customLog('User type------> null');
      _userType = null;
    }
  }

  Future<void> _getAllDivisionsForAdmin() async {
    String? currentLoggedInUserId = await userService.getCurrentUserId();

    if (currentLoggedInUserId != null) {
      UserModel? currentLoggedInUser =
          await userService.getUserById(currentLoggedInUserId);
      List<String>? assignedDivisionNames = currentLoggedInUser?.divisions;
      if (assignedDivisionNames != null) {
        assignedDivisionNames = assignedDivisionNames
            .map((division) => division.toLowerCase())
            .toList();

        _listOfDivisions = await getAllDivisions();
        List<DivisionModel> filteredDivision = _listOfDivisions.where((i) {
          return assignedDivisionNames?.contains(i.code.toLowerCase()) ?? false;
        }).toList();
        _listOfDivisions.clear();
        setState(() {
          _listOfDivisions = filteredDivision;
        });
      } else {
        setState(() {
          _listOfDivisions.clear();
        });
      }
    }
  }

  Future<void> _getAllDivisionsForSuperAdmin() async {
    List<DivisionModel> divisionsFromDB = await getAllDivisions();
    List<DivisionSelectionModel> divisionList = [];
    if (widget.isForDivisionSelection) {
      for (var element in divisionsFromDB) {
        divisionList.add(
          DivisionSelectionModel(
            division: element,
            isSelected: (widget.alreadySelectedDivisions!
                        .map((division) => division.toLowerCase())
                        .toList())
                    .contains(element.code.toLowerCase())
                ? true
                : false,
          ),
        );
      }
    }
    setState(() {
      if (widget.isForDivisionSelection) {
        _listOfDivisionSelection = divisionList;
      } else {
        _listOfDivisions = divisionsFromDB;
      }
    });
  }

  Future<List<DivisionModel>> getAllDivisions() async {
    List<DivisionModel> divisionsFromDB =
        await _divisionService.getAllDivision();
    //_getConsumerCount(divisionsFromDB);
    Common.customLog(
        'DIVISIONS FROM DB---------> ' + divisionsFromDB.toString());
    return divisionsFromDB;
  }

  void addDivision(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddDivision()),
    ).then((value) {
      return value ? _getAllDivisions() : null;
    });
  }

  void _edit(DivisionModel region) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditDivision(region)),
    ).then((value) {
      return value ? _getAllDivisions() : null;
    });
  }

  void _delete(context, DivisionModel region) {
    CustomDialog.showConfirmDialog(context, 'Proceed with deletion?', () async {
      String result = '';
      result = await _divisionService.delete(region);
      if (result.contains('success__')) {
        CustomDialog.showSnack(context, 'Division deleted', () {
          _getAllDivisions();
        });
      } else {
        CustomDialog.showSnack(context, 'Division cant be deleted', () {});
      }
    });
  }

  _displayConsumerUnderDivision(String divisionName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text(
              'Consumer List',
            ),
          ),
          body: ConsumerList(divisionName),
        ),
      ),
    );
  }

  void addToSelectedDivisionList(String divisionCode) {
    selectedDivisions.add(divisionCode);
  }

  void removeFromSelectedDivisionList(String divisionCode) {
    if (selectedDivisions.isNotEmpty) {
      int? index = selectedDivisions.indexOf(divisionCode);
      if (index != null) {
        selectedDivisions.removeAt(index);
      }
    }
  }

  // Future<List<String>> _onBackPressed() {
  //   return selectedDivisions;
  // }
  @override
  Widget build(BuildContext context) {
    return Center(
      widthFactor: double.infinity,
      heightFactor: double.infinity,
      child: widget.isForDivisionSelection
          ? layoutForDivisionSelection(context)
          : layoutForDivisionListing(context),
    );
  }

  Widget layoutForDivisionListing(BuildContext context) {
    return Column(
      children: [
        if (_userType == 'superadmin') ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => addDivision(context),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
        _listOfDivisions.isNotEmpty
            ? Expanded(
                child: ListView.builder(
                  itemCount: _listOfDivisions.length,
                  itemBuilder: (ctxt, index) {
                    return ListTile(
                      isThreeLine: false,
                      onTap: () {
                        _displayConsumerUnderDivision(
                            _listOfDivisions[index].code);
                      },
                      subtitle: Text(
                        _listOfDivisions[index].code,
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      trailing: _userType == 'superadmin'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                GestureDetector(
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.black,
                                  ),
                                  onTap: () {
                                    _edit(_listOfDivisions[index]);
                                  },
                                ),
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                ),
                                GestureDetector(
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.black,
                                    size: 30,
                                  ),
                                  onTap: () {
                                    _delete(context, _listOfDivisions[index]);
                                  },
                                ),
                              ],
                            )
                          : null,
                    );
                  },
                ),
              )
            : Card(
                child: ListTile(
                  title: const Text('Loading division list ...'),
                  subtitle: const Text(''),
                  selected: false,
                  onTap: () {},
                  leading: const CircularProgressIndicator(
                    backgroundColor: Colors.yellow,
                  ),
                ),
              )
      ],
    );
  }

  Widget layoutForDivisionSelection(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: _listOfDivisionSelection.map(
              (selectedDivision) {
                return CheckboxListTile(
                  title: Text(selectedDivision.division.code),
                  value: selectedDivision.isSelected,
                  onChanged: (newValue) {
                    if (newValue == true) {
                      addToSelectedDivisionList(selectedDivision.division.code);
                    } else {
                      removeFromSelectedDivisionList(
                          selectedDivision.division.code);
                    }
                    setState(() {
                      selectedDivision.isSelected = newValue!;
                    });
                  },
                );
              },
            ).toList(),
          ),
        ),
        Center(
          child: ElevatedButton(
            onPressed: () {
              Common.customLog('---------------');
              Common.customLog(selectedDivisions);
              Navigator.pop(context, selectedDivisions);
            },
            child: const Text('Assign'),
          ),
        ),
      ],
    );
  }
}
