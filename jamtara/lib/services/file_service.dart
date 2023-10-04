import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
class FileService {
  static write(String data, String fileName, Function callback) async {
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final File file = File('${directory.path}/' + fileName);
      await file.writeAsString(data);
      callback('success__');
    } catch(error) {
      callback('error__'+error.toString());
    }
  }
  static Future<String> read(String fileName) async {
    String text='';
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final File file = File('${directory.path}/'+fileName);
      text = await file.readAsString();
    } catch (e) {
      text='';
    }
    return text;
  }
  static Future<void> delete(String fileName) async{
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final File file = File('${directory.path}/'+fileName);
      file.deleteSync();
    } catch (e) {
      //ToDo
    }
  }
}