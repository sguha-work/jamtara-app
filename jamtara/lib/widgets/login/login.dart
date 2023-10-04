import 'package:bentec/services/common.dart';
import 'package:bentec/widgets/consumers/consumer_caching.dart';
import 'package:bentec/widgets/main_tab_view/main_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bentec/utility/constants.dart';
import 'package:bentec/utility/constants.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';

class Login extends StatefulWidget {
  // final Function onLoginSuccessful;
  // Login(this.onLoginSuccessful);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String errorText = '';
  final UserService userService = UserService();
  bool showLoading = false;
  bool _validate() {
    if (phoneNumberController.text == '' ||
        phoneNumberController.text.length != 10) {
      return false;
    }
    if (passwordController.text == '') {
      return false;
    }
    return true;
  }

  void loginButtonClicked() async {
    Common.customLog("Phone number --- " + phoneNumberController.text);
    Common.customLog("Password --- " + passwordController.text);
    FocusScope.of(context).unfocus();
    _displayError('');
    if (_validate()) {
      // setState(() {
      showLoading = true;
      // });
      String phoneNumber = phoneNumberController.text;
      String password = passwordController.text;
      String? result = await userService.signinWithPhoneNumberAndPassword(
          phoneNumber, password);

      if (result == null) {
        setState(() {
          showLoading = false;
        });
        _displayError('Unable to login');
      } else {
        if (result.contains('error__')) {
          setState(() {
            showLoading = false;
          });
          _displayError(_parseError(result));
        } else {
          //widget.onLoginSuccessful();
          onSuccessfulLogin();
        }
      }
      //widget.onLoginSuccessful();
    } else {
      _displayError('Validation error');
    }
  }

  void onSuccessfulLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (BuildContext context) => ConsumerCaching(),
      ),
    );
  }

  String _parseError(String messege) {
    messege = messege.split('error__').last;
    switch (messege) {
      case 'phone-number-not-registered':
        return 'Phone number not registered';
      case 'wrong-password':
        return 'Phone number or password is wrong';
      case 'network-request-failed':
        return 'Unable to reach server due to internet issue';
      default:
        return messege;
    }
  }

  void _displayError(String message) {
    setState(() {
      errorText = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    return Scaffold(
      backgroundColor: Constants.color_1,
      body: SafeArea(
        // top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                ),
                child: Column(
                  children: const [
                    Text(
                      'BENTEC',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 65,
                        color: Colors.white,
                        fontFamily: Constants.SOURCE_SANS_PRO_FONT_FAMILY,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    Text(
                      'Mission : Meter lagao',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.yellow,
                        fontFamily: Constants.SOURCE_SANS_PRO_FONT_FAMILY,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
                child: Card(
                  elevation: 15,
                  child: TextField(
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                    controller: phoneNumberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    decoration: const InputDecoration(
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.all(
                        5,
                      ),
                      hintText: 'Mobile number',
                      // labelText: 'Mobile number',
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
                child: Card(
                  elevation: 15,
                  child: TextField(
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.all(
                        5,
                      ),
                      hintText: 'Password',
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                child: showLoading == false
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 30,
                        ),
                        child: SizedBox(
                          width: 200,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: loginButtonClicked,
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.yellow),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 20,
                                color: Constants.color_1,
                                fontFamily: Constants.SOURCE_SANS_PRO_BOLD,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 30,
                        ),
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.yellow,
                        ),
                      ),
                duration: const Duration(seconds: 2),
              ),
              Text(
                errorText,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//
