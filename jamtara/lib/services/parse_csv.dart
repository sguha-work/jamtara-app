import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

import 'common.dart';

class ParseCSV {
  static final instance = ParseCSV();

  String _getCharecterCode(selectedFile) {
    try {
      String charecterCodeString = String.fromCharCodes(selectedFile.bytes);
      return charecterCodeString;
    } catch (e) {
      return 'error' + e.toString();
    }
  }

  static String getCSVDataAsString(PlatformFile selectedFile) {
    String s = instance._getCharecterCode(selectedFile.bytes);
    if (s == 'error') {
      return s;
    }
    var outputAsUint8List = Uint8List.fromList(s.codeUnits);
    return utf8.decode(outputAsUint8List);
  }

  static List<dynamic> getCSVLines(PlatformFile selectedFile) {
    List csvFileContentList = [];
    String s = instance._getCharecterCode(selectedFile);
    if (s == 'error') {
      Common.customLog("ERROR........" + s);
      return [s];
    }
    var outputAsUint8List = Uint8List.fromList(s.codeUnits);
    csvFileContentList = utf8.decode(outputAsUint8List).split('\n');
    return csvFileContentList;
  }

  static String getJSONFromCSV(PlatformFile selectedFile) {
    List lines = getCSVLines(selectedFile);
    String outputJSON = '';
    List<String> headers = lines[0].split(',');
    List<Map<String, dynamic>> listOfObject = [];
    for (int index1 = 1; index1 < lines.length; index1++) {
      final chunks = lines[index1].split(',');
      Map<String, dynamic> objectData = {};
      chunks.asMap().forEach((index, element) {
        objectData[headers[index]] = element;
        listOfObject.add(objectData);
      });
    }
    outputJSON = jsonEncode(listOfObject);
    return outputJSON;
  }
}
