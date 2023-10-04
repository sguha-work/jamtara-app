import 'package:permission_handler/permission_handler.dart';
class PermissionService {
  static askStoragePermission() async{
    Map<Permission, PermissionStatus> statuses = await [
    Permission.storage,
    ].request();
  }
  static askCameraPermission() async{
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
    ].request();
  }
  static askLocationPermission() async{
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
    ].request();
  }
}