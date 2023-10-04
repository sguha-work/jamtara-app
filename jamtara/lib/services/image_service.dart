import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path/path.dart';
import 'dart:io';
import 'dart:io' as io;
class ImageService {
  static Future<String> uploadImageToFirebase(
      File? imageFile, String newFileName, String folderName) async {
    String fileName = basename(imageFile!.path);
    firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
        .ref()
        .child(folderName)
        .child('/$newFileName');
    final metadata = firebase_storage.SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': fileName});
    firebase_storage.UploadTask uploadTask;
    uploadTask = ref.putFile(io.File(imageFile.path), metadata);
    firebase_storage.UploadTask task = await Future.value(uploadTask);
    String result = '';
    await Future.value(uploadTask).then((value) {
      result = "success__" + value.ref.fullPath;
    }).onError((error, stackTrace) {
      result = "error__" + error.toString();
    });
    await uploadTask.whenComplete(() async {
      try {
        result = await ref.getDownloadURL();
      } catch (onError) {
        result = "error__";
      }
    });
    return result;
  }

  static Future<String> uploadBase64ImageToFirebase(
      String imageString, String newFileName, String folderName) async {
    firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
        .ref()
        .child(folderName)
        .child('/$newFileName');
    final metadata = firebase_storage.SettableMetadata(
        contentType: 'image/jpeg');
    firebase_storage.UploadTask uploadTask;
    uploadTask = ref.putString(imageString, format: firebase_storage.PutStringFormat.base64, metadata: metadata);
    String result = '';
    await Future.value(uploadTask).then((value) async{
      result = "success__" + await value.ref.getDownloadURL();
    }).onError((error, stackTrace) {
      result = "error__" + error.toString();
    });
    return result;
  }
}