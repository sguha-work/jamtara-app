import 'package:bentec/models/division.dart';
import 'package:bentec/models/report.dart';
import 'package:bentec/models/user.dart';
import 'package:bentec/services/common.dart';
import 'package:bentec/services/division_service.dart';
import 'package:bentec/services/report_service.dart';
import 'package:bentec/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'filtered_report_list.dart';

class FilterView extends StatefulWidget {
  final Function searchButtonClicked;
  final Function cancelButtonClicked;
  final String loggedInUserType;
  final UserModel? admin;
  List<UserModel> listOfSupervisor;
  FilterView(this.searchButtonClicked, this.cancelButtonClicked,
      this.listOfSupervisor, this.loggedInUserType, this.admin);
  @override
  State<FilterView> createState() => _FilterViewState();
}

class _FilterViewState extends State<FilterView> {
  final agentNameInputController = TextEditingController();
  // DateTime startDateTime = DateTime.utc(
  //   DateTime.now().year,
  //   DateTime.now().month,
  // ).subtract(const Duration(days: 30));
  DateTime startDateTime = DateTime.now();
  DateTime endDateTime = DateTime.now();
  final UserService _userService = UserService();
  DivisionService divisionService = DivisionService();
  final ReportService _reportService = ReportService();

  final String _adminSelectorDefaultString = 'Select admin';
  List<String> _adminNameList = [];
  String _selectedAdmin = '';
  bool _isAdminDropdownEnabled = false;

  final String _divisionSelectorDefaultString = 'Select division';
  List<String> _divisionNameList = [];
  String _selectedDivision = '';
  bool _isDivisionDropdownEnabled = false;

  final String _supervisorSelectorDefaultString = 'Select supervisor';
  List<String> _supervisorNameList = [];
  String _selectedSupervisor = '';
  bool _isSupervisorDropdownEnabled = false;

  final String _agentSelectorDefaultString = 'Select agent';
  List<String> _agentNameList = [];
  String _selectedAgent = '';
  bool _isAgentDropdownEnabled = false;
  bool _isFetchingData = true;
  bool isSearching = false;

  _FilterViewState() {
    _adminNameList = [_adminSelectorDefaultString];
    _selectedAdmin = _adminSelectorDefaultString;

    _supervisorNameList = [_supervisorSelectorDefaultString];
    _selectedSupervisor = _supervisorSelectorDefaultString;

    _divisionNameList = [_divisionSelectorDefaultString];
    _selectedDivision = _divisionSelectorDefaultString;

    _agentNameList = [_agentSelectorDefaultString];
    _selectedAgent = _agentSelectorDefaultString;
  }
  @override
  void initState() {
    if (widget.loggedInUserType == 'superadmin') {
      _isAdminDropdownEnabled = true;
      _prepareAdminNameList();
    } else if (widget.loggedInUserType == 'admin') {
      _isDivisionDropdownEnabled = true;
      _prepareDivisionList(widget.admin?.phoneNumber);
    }
    super.initState();
  }

  Future<void> _prepareAdminNameList() async {
    List<String> adminNameList = [_adminSelectorDefaultString];
    List<UserModel>? adminList = await _userService.getAllAdmins();
    for (UserModel admin in adminList ?? []) {
      adminNameList.add(admin.fullName + '\n(' + admin.phoneNumber + ')');
    }
    _adminNameList = adminNameList;
    if (_isFetchingData) {
      _isFetchingData = false;
    }
    setState(() {});
  }

  Future<void> _prepareAgentNameList(String? supervisorPhoneNumber) async {
    if (supervisorPhoneNumber != null) {
      UserModel? supervisor =
          await _userService.getUserByPhoneNumber(supervisorPhoneNumber);
      if (supervisor != null) {
        List<String> agentNameList = [_agentSelectorDefaultString];
        List<UserModel>? agentList =
            await _userService.getAllAgentBasedOnCreator(supervisor.id);
        for (UserModel agent in agentList ?? []) {
          agentNameList.add(agent.fullName + '\n(' + agent.phoneNumber + ')');
        }
        _agentNameList = agentNameList;
        if (_isFetchingData) {
          _isFetchingData = false;
        }
        setState(() {});
      } else {
        Common.customLog('Supervisor ----null');
      }
    }
  }

  void _prepareSupervisorNameList() async {
    if (widget.listOfSupervisor.isNotEmpty) {
      List<String> nameList = [_supervisorSelectorDefaultString];
      List<UserModel>? supervisorList =
          await _userService.getAllUserBasedOnDivision(
              userType: 'supervisor', division: _selectedDivision);
      if (supervisorList != null) {
        for (UserModel supervisor in supervisorList) {
          nameList
              .add(supervisor.fullName + '\n(' + supervisor.phoneNumber + ')');
        }
        _supervisorNameList = nameList;
        if (_isFetchingData) {
          _isFetchingData = false;
        }
      }
    }
    setState(() {});
  }

  Future<void> _prepareDivisionList(String? adminPhoneNumber) async {
    if (adminPhoneNumber != null) {
      UserModel? admin =
          await _userService.getUserWithPhoneNumber(adminPhoneNumber);
      if (admin != null) {
        List<String> divisionNameList = [_divisionSelectorDefaultString];
        divisionNameList.addAll(admin.divisions);
        _divisionNameList = divisionNameList;
        if (_isFetchingData) {
          _isFetchingData = false;
        }
        setState(() {});
      }
    } else {
      Common.customLog('admin phone number----null');
    }
  }

  void _adminChanged(String value) {
    _selectedAdmin = value;
    if (value != _adminSelectorDefaultString) {
      String adminPhoneNumber =
          _selectedAdmin.split('\n(').last.split(')').first;
      _prepareDivisionList(adminPhoneNumber);
      setState(() {
        _isDivisionDropdownEnabled = true;
        _selectedDivision = _divisionSelectorDefaultString;
        _isSupervisorDropdownEnabled = false;
        _selectedSupervisor = _supervisorSelectorDefaultString;
        _isAgentDropdownEnabled = false;
        _selectedAgent = _agentSelectorDefaultString;
      });
    } else {
      setState(() {
        _isDivisionDropdownEnabled = false;
        _isSupervisorDropdownEnabled = false;
        _isAgentDropdownEnabled = false;
      });
    }
  }

  void _divisionChanged(String value) {
    setState(() {
      _selectedDivision = value;
      _prepareSupervisorNameList();
      if (value != _divisionSelectorDefaultString) {
        _isSupervisorDropdownEnabled = true;
        _selectedSupervisor = _supervisorSelectorDefaultString;
        _isAgentDropdownEnabled = false;
        _selectedAgent = _agentSelectorDefaultString;
      } else {
        _isSupervisorDropdownEnabled = true;
        _isAgentDropdownEnabled = true;
      }
    });
  }

  void _supervisorChanged(String value) {
    _selectedSupervisor = value;
    if (value != _supervisorSelectorDefaultString) {
      String supervisorPhoneNumber =
          _selectedSupervisor.split('\n(').last.split(')').first;
      _prepareAgentNameList(supervisorPhoneNumber);
      setState(() {
        _isAgentDropdownEnabled = true;
        _selectedAgent = _agentSelectorDefaultString;
      });
    } else {
      setState(() {
        _isAgentDropdownEnabled = true;
      });
    }
  }

  void _agentChanged(String value) {
    setState(() {
      _selectedAgent = value;
    });
  }

  void _onSearchButtonClick() async {
    String? phoneNumber;
    String? selectedDivision;
    List<String>? divisions;
    String basedOnUser;
    if (_selectedAgent != _agentSelectorDefaultString) {
      Common.customLog('Search.....1');
      String agentPhoneNumber = _selectedAgent.split('(').last.split(')').first;
      setState(() {
        isSearching = true;
      });
      phoneNumber = agentPhoneNumber;
      basedOnUser = 'agent';
    } else if (_selectedSupervisor != _supervisorSelectorDefaultString) {
      Common.customLog('Search.....2');
      String supervisorPhoneNumber =
          _selectedSupervisor.split('(').last.split(')').first;
      setState(() {
        isSearching = true;
      });
      phoneNumber = supervisorPhoneNumber;
      basedOnUser = 'supervisor';
    } else if (_selectedDivision != _divisionSelectorDefaultString) {
      Common.customLog('Search.....3');
      setState(() {
        isSearching = true;
      });
      selectedDivision = _selectedDivision;
      basedOnUser = 'division';
    } else if (_selectedAdmin != _adminSelectorDefaultString &&
        widget.loggedInUserType == 'superadmin' &&
        widget.admin != null) {
      Common.customLog('Search.....4');
      setState(() {
        isSearching = true;
      });
      String adminPhoneNumber =
          _selectedAdmin.split('\n(').last.split(')').first;
      UserModel? admin =
          await _userService.getUserWithPhoneNumber(adminPhoneNumber);
      divisions = admin?.divisions;
      basedOnUser = 'admin';
    } else {
      Common.customLog('Search.....5');
      setState(() {
        isSearching = true;
      });
      basedOnUser = '';
    }
    setState(() {
      isSearching = false;
    });
    Common.customLog('called.............widget.searchButtonClicked');
    widget.searchButtonClicked(basedOnUser, phoneNumber, selectedDivision,
        divisions, startDateTime, endDateTime);
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime initialDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != initialDate) {
      setState(() {
        switch (isStartDate) {
          case true:
            startDateTime = picked;
            break;
          default:
            endDateTime = picked;
            break;
        }
      });
    }
  }

  _getView() {
    List<Widget> view = [];
    if (_isFetchingData) {
      view = [
        Card(
          child: ListTile(
            title: const Text('Loading data for search form ...'),
            subtitle: const Text(''),
            selected: false,
            onTap: () {},
            leading: const CircularProgressIndicator(
              backgroundColor: Colors.yellow,
            ),
          ),
        )
      ];
    } else {
      view = [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              flex: 1,
              child: Text(
                'Start date : ',
              ),
            ),
            Flexible(
              flex: 2,
              child: Text(
                DateFormat("yyyy-MM-dd").format(startDateTime).toString(),
                textAlign: TextAlign.center,
              ),
            ),
            Flexible(
              flex: 1,
              child: IconButton(
                onPressed: () => _selectDate(context, true),
                icon: const Icon(
                  Icons.date_range,
                  size: 30.0,
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              flex: 1,
              child: Text(
                'End date : ',
              ),
            ),
            Flexible(
              flex: 2,
              child: Text(
                DateFormat("yyyy-MM-dd").format(endDateTime).toString(),
                textAlign: TextAlign.center,
              ),
            ),
            Flexible(
              flex: 1,
              child: IconButton(
                onPressed: () => _selectDate(context, false),
                icon: const Icon(
                  Icons.date_range,
                  size: 30.0,
                ),
              ),
            ),
          ],
        ),
        if (widget.loggedInUserType == 'superadmin') ...[
          Row(
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Card(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAdmin,
                      items: _adminNameList.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(value),
                          ),
                        );
                      }).toList(),
                      onChanged: _isAdminDropdownEnabled
                          ? (value) => _adminChanged(
                              value ?? _adminSelectorDefaultString)
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        Row(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Card(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDivision,
                    items: _divisionNameList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: _isDivisionDropdownEnabled
                        ? (value) => _divisionChanged(
                            value ?? _divisionSelectorDefaultString)
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Card(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSupervisor,
                    items: _supervisorNameList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: _isSupervisorDropdownEnabled
                        ? (value) => _supervisorChanged(
                            value ?? _supervisorSelectorDefaultString)
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Card(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAgent,
                    items: _agentNameList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: _isAgentDropdownEnabled
                        ? (value) =>
                            _agentChanged(value ?? _agentSelectorDefaultString)
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (isSearching) ...[
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: () {
                widget.cancelButtonClicked();
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _onSearchButtonClick();
              },
              child: const Text(
                'Search',
              ),
            ),
          ],
        ),
      ];
    }
    return view;
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return SizedBox(
      width: width - 20,
      height: 500,
      child: Card(
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _getView(),
          ),
        ),
      ),
    );
  }
}
