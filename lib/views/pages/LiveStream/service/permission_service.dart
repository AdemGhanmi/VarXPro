// permission_service.dart - No changes.
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionService {
  Future<bool> requestPermissions() async {
    final permissions = [
      Permission.microphone,
      Permission.storage,
      if (Platform.isAndroid) Permission.manageExternalStorage,
      if (Platform.isAndroid) Permission.camera, // Always request for screen recording on new devices
    ];

    final results = await Future.wait(
      permissions.map((p) => p.request()),
    );

    return results.every((status) => status.isGranted);
  }
}
