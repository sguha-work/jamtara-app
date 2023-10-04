import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'dart:io';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:nanoid/nanoid.dart';
import 'package:intl/intl.dart';

class Common {
  static bool isNumeric(String result) {
    if (result == null) {
      return false;
    }
    return double.tryParse(result) != null;
  }

  static bool isValidEmail(String email) {
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(email);
  }

  static String getForMattedLinkForCSV(String link) {
    String output = '';
    if (link != null) {
      output = output + '=HYPERLINK("' + link + '","Image of report")';
    }
    return output;
  }

  static Future<File> fileFromImageUrl(String imageURL) async {
    final documentDirectory = await getApplicationDocumentsDirectory();
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final response = await http.get(Uri.parse(imageURL));

    final file = File(join(documentDirectory.path, fileName));
    file.writeAsBytesSync(response.bodyBytes);
    return file;
  }

  static bool isValidPANNumber(String panNo) {
    RegExp regExp = RegExp(
      r"[A-Z]{5}[0-9]{4}[A-Z]{1}",
      caseSensitive: false,
      multiLine: false,
    );
    return regExp.hasMatch(panNo);
  }

  static bool isValidAadharNumber(String aadharNo) {
    RegExp regExp = RegExp(
      r"[0-9]{12}",
      caseSensitive: false,
      multiLine: false,
    );
    return regExp.hasMatch(aadharNo);
  }

  static bool isValidMobileNumber(String phoneNumber) {
    String pattern = r'^(?:[+0][1-9])?[0-9]{10,12}$';
    RegExp regExp = new RegExp(pattern);
    return regExp.hasMatch(phoneNumber);
  }

  static getDateTimeFromTimeStamp(int timeStamp) {
    int timeStampNumber = timeStamp;
    return DateTime.fromMillisecondsSinceEpoch(timeStampNumber).toString();
  }

  static getOnlyDateFromTimeStamp(int timeStamp) {
    int timeStampNumber = timeStamp;
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timeStampNumber);
    return DateFormat("yyyy-MM-dd").format(dateTime).toString();
  }

  static String getFormattedDateTimeFromTimeStamp(int timeStamp) {
    List<String> monthName = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'Jun',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    int timeStampNumber = timeStamp;
    DateTime output = DateTime.fromMillisecondsSinceEpoch(timeStampNumber);
    //output.day

    return monthName[output.month - 1] +
        ' ' +
        output.day.toString() +
        ' ' +
        output.year.toString() +
        ' at ' +
        formatHourMinute(output.hour, output.minute);
  }

  static formatHourMinute(int hour, int minute) {
    String output = '';
    if (hour > 12) {
      output = (hour - 12).toString() + ':' + minute.toString() + ' PM';
    } else {
      output = (hour).toString() + ':' + minute.toString() + ' PM';
    }
    return output;
  }

  static isOnline(Function callback) async {
    try {
      final result = await InternetAddress.lookup('example.com');
      callback(result.isNotEmpty && result[0].rawAddress.isNotEmpty);
    } on SocketException catch (_) {
      callback(false);
    }
  }

  static String getUniqueId() {
    return nanoid(21);
  }

  static int getTimeStampFromDateTime(DateTime dt) {
    return dt.millisecondsSinceEpoch;
  }

  static customLog(Object? object) {
    // ignore: avoid_print
    // print(object);
  }
}
